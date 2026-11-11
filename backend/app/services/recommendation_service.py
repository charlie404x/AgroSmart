"""Motor de recomendación de cultivos basado en reglas (AgroSmartData).

Flujo:
1. Clasifica la altitud en una banda (Baja / Media / Alta).
2. Busca la regla exacta banda + suelo + disponibilidad hídrica.
3. Conserva los cultivos de la regla cuya altitud mínima/máxima incluye la altitud real.
4. Si no queda ninguno, ofrece alternativas de respaldo: cultivos del dataset que toleran
   la altitud y el agua disponible, marcados como tales y con sus advertencias.
5. Evalúa cada cultivo contra las condiciones del usuario (suelo, agua, altitud) y
   construye una justificación específica.
6. Ordena por ingreso bruto estimado por hectárea (rendimiento × 1000 × precio).
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from ..utils.agrosmart_data import AGROSMART_DATA

DATA = AGROSMART_DATA
DEPARTMENTS: dict[str, Any] = DATA["departments"]
CROPS: dict[str, Any] = DATA["crops"]
RULES: list[dict[str, Any]] = DATA["recommendation_rules"]["rules"]
ALTITUDE_BANDS: dict[str, str] = DATA["recommendation_rules"]["altitude_bands"]

WATER_RANK = {"Baja": 0, "Media": 1, "Alta": 2}
EDGE_MARGIN_M = 150  # distancia al límite de altitud del cultivo que genera advertencia
SUITABILITY_RANK = {"alta": 0, "media": 1, "baja": 2}

PRICE_DISCLAIMER = (
    "Precios referenciales estimados (MIDAGRI-SIEA, promedio de la sierra). Las diferencias "
    "entre departamentos provienen de un factor de ajuste fijo y no son cotizaciones regionales "
    "verificadas. El ingreso bruto estimado no descuenta costos de producción ni es una ganancia garantizada."
)
SORT_CRITERIA = "Ingreso bruto estimado por hectárea (rendimiento × 1000 × precio por kg), de mayor a menor."
FALLBACK_NOTICE = (
    "Las reglas de AgroSmartData no tienen cultivos compatibles con esta combinación exacta. "
    "Se muestran alternativas que toleran tu altitud y el agua disponible; valídalas con un técnico agrario."
)
EMPTY_NOTICE = (
    "No encontramos cultivos del dataset adecuados para esta altitud y disponibilidad de agua. "
    "Te sugerimos consultar a la Agencia Agraria de tu zona."
)


def classify_altitude(altitude: float) -> str:
    """Clasifica la altitud: Baja (< 2500 m), Media (2500–3500 m) o Alta (> 3500 m)."""
    if altitude < 2500:
        return "Baja"
    if altitude <= 3500:
        return "Media"
    return "Alta"


def find_rule(band: str, soil_type: str, water: str) -> dict[str, Any] | None:
    for rule in RULES:
        if rule["altitud"] == band and rule["suelo"] == soil_type and rule["disponibilidad_hidrica"] == water:
            return rule
    return None


def _sentence(text: str) -> str:
    """Normaliza una oración: sin espacios sobrantes y con un único punto final."""
    text = " ".join(text.split()).rstrip(" .;,")
    return f"{text}." if text else ""


def _celsius(text: str) -> str:
    """'10 - 16 C' -> '10–16 °C'."""
    text = text.strip()
    if text.endswith(" C"):
        text = text[:-2].strip() + " °C"
    return text.replace(" - ", "–")


def estimated_income(yield_t_ha: float, price_per_kg: float) -> float | None:
    """Ingreso bruto estimado por hectárea en soles; None si los datos no son válidos."""
    if not yield_t_ha or not price_per_kg or yield_t_ha <= 0 or price_per_kg <= 0:
        return None
    return round(yield_t_ha * 1000 * price_per_kg, 2)


@dataclass(frozen=True)
class Conditions:
    department: str
    altitude: float
    soil_type: str
    water: str

    @property
    def band(self) -> str:
        return classify_altitude(self.altitude)


def _altitude_ok(crop: dict[str, Any], altitude: float) -> bool:
    return crop["min_altitude"] <= altitude <= crop["max_altitude"]


def _water_ok(crop: dict[str, Any], water: str) -> bool:
    return WATER_RANK[water] >= WATER_RANK.get(crop["water_need"], 1)


def _evaluate(key: str, cond: Conditions, *, is_fallback: bool) -> dict[str, Any]:
    crop = CROPS[key]
    soil_match = cond.soil_type in crop["ideal_soils"]
    water_match = _water_ok(crop, cond.water)
    reasons: list[str] = []
    warnings: list[str] = []

    if not is_fallback:
        reasons.append(
            f"Recomendado por las reglas AgroSmartData para altitud {cond.band.lower()}, "
            f"suelo {cond.soil_type} y disponibilidad de agua {cond.water.lower()}"
        )
    reasons.append(
        f"Tu altitud de {cond.altitude:,.0f} m está dentro de su rango de cultivo "
        f"({crop['min_altitude']:,}–{crop['max_altitude']:,} m)".replace(",", " ")
    )
    if cond.altitude - crop["min_altitude"] < EDGE_MARGIN_M:
        warnings.append("Tu altitud está cerca del límite inferior del cultivo; vigila las temperaturas altas")
    elif crop["max_altitude"] - cond.altitude < EDGE_MARGIN_M:
        warnings.append("Tu altitud está cerca del límite superior del cultivo; aumenta el riesgo de heladas")

    if soil_match:
        reasons.append(f"El suelo {cond.soil_type} es uno de sus suelos ideales")
    else:
        warnings.append(
            f"El suelo {cond.soil_type} no está entre sus suelos ideales ({', '.join(crop['ideal_soils'])}); "
            "conviene un análisis de suelo antes de sembrar"
        )

    need = crop["water_need"]
    if water_match:
        if need == "Baja":
            reasons.append("Tiene baja demanda de agua, por lo que tolera periodos secos")
        else:
            reasons.append(f"Su demanda de agua ({need.lower()}) se cubre con la disponibilidad {cond.water.lower()}")
    else:
        warnings.append(
            f"Necesita disponibilidad de agua {need.lower()}; con disponibilidad {cond.water.lower()} "
            "requerirá riego complementario"
        )

    climate = DEPARTMENTS.get(cond.department, {}).get("climate", {})
    if climate.get("temp_promedio"):
        reasons.append(
            f"Temperatura óptima del cultivo: {_celsius(crop['optimal_temperature'])}; "
            f"promedio referencial de {cond.department}: {_celsius(climate['temp_promedio'])}"
        )

    if is_fallback:
        suitability = "media" if soil_match and water_match else "baja"
        tag = "Alternativa" if suitability == "media" else "Alternativa con reservas"
    else:
        suitability = "alta" if soil_match and water_match else "media"
        tag = "Muy adecuado" if suitability == "alta" else "Adecuado con observaciones"

    price = float(crop["price_per_kg"].get(cond.department, 0.0))
    reasons = [_sentence(r) for r in reasons]
    warnings = [_sentence(w) for w in warnings]
    return {
        "crop_key": key,
        "name": crop["nombre"],
        "description": _sentence(crop.get("description", "")),
        "price_per_kg": price,
        "estimated_income_per_ha": estimated_income(crop["yield_avg_t_ha"], price),
        "justification": " ".join(reasons + warnings),
        "reasons": reasons,
        "warnings": warnings,
        "suitability": suitability,
        "tag": tag,
        "is_fallback": is_fallback,
        "soil_match": soil_match,
        "water_match": water_match,
        "ideal_soils": list(crop["ideal_soils"]),
        "water_need": need,
        "optimal_temperature": _celsius(crop["optimal_temperature"]),
        "sowing_season": crop["sowing_season"],
        "harvest_season": crop["harvest_season"],
        "yield_avg": crop["yield_avg_t_ha"],
        "min_altitude": crop["min_altitude"],
        "max_altitude": crop["max_altitude"],
        "altitude_range": f"{crop['min_altitude']}–{crop['max_altitude']} m",
    }


def _sort_key(item: dict[str, Any]) -> tuple:
    income = item["estimated_income_per_ha"]
    return (income is None, -(income or 0.0), SUITABILITY_RANK[item["suitability"]], item["name"])


def get_recommendation(department: str, altitude: float, soil_type: str, water_avail: str) -> dict[str, Any]:
    """Calcula la recomendación. Los parámetros ya deben venir validados por el esquema."""
    cond = Conditions(department, altitude, soil_type, water_avail)
    rule = find_rule(cond.band, soil_type, water_avail)
    rule_keys = [k for k in (rule or {}).get("cultivos_recomendados", []) if k in CROPS]

    crops = [_evaluate(k, cond, is_fallback=False) for k in rule_keys if _altitude_ok(CROPS[k], altitude)]
    used_fallback = False
    notice = None

    if not crops:
        used_fallback = True
        candidates = [
            k for k, c in CROPS.items() if _altitude_ok(c, altitude) and _water_ok(c, water_avail)
        ]
        crops = [_evaluate(k, cond, is_fallback=True) for k in candidates]
        notice = FALLBACK_NOTICE if crops else EMPTY_NOTICE

    crops.sort(key=_sort_key)
    return {
        "department": department,
        "altitude": altitude,
        "altitude_band": cond.band,
        "soil_type": soil_type,
        "water_availability": water_avail,
        "recommended_crops": crops,
        "used_fallback": used_fallback,
        "notice": notice,
        "price_disclaimer": PRICE_DISCLAIMER,
        "sort_criteria": SORT_CRITERIA,
    }
