"""Información climática referencial por departamento (AgroSmartData / SENAMHI)."""
from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status

from ..catalog import DEPARTMENTS, normalize_choice
from ..utils.agrosmart_data import AGROSMART_DATA

CLIMATE_DISCLAIMER = (
    "Promedios climáticos referenciales del departamento. No son mediciones ni pronósticos en tiempo real; "
    "las condiciones de tu parcela pueden variar según la altitud y la época del año."
)


def _celsius(text: str) -> str:
    text = text.strip()
    if text.endswith(" C"):
        text = text[:-2].strip() + " °C"
    return text.replace(" - ", "–")


def get_climate(department: str) -> dict[str, Any]:
    canonical = normalize_choice(department, DEPARTMENTS)
    if canonical is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay información climática para '{department}'. Departamentos disponibles: {', '.join(DEPARTMENTS)}.",
        )
    dept = AGROSMART_DATA["departments"][canonical]
    climate = dept["climate"]
    crops = AGROSMART_DATA["crops"]
    return {
        "department": canonical,
        "classification": climate["clasificacion"],
        "temperature_range": _celsius(climate["temp_promedio"]),
        "precipitation": climate["precipitacion"].replace("anio", "año").replace(" - ", "–"),
        "humidity": climate["humedad"].replace(" - ", "–"),
        "description": climate["descripcion"],
        "typical_altitude_min": dept["altitud_typical"]["min"],
        "typical_altitude_max": dept["altitud_typical"]["max"],
        "common_soils": list(dept["soil_types"]),
        "common_crops": [crops[k]["nombre"] for k in dept["common_crops"] if k in crops],
        "data_type": "referencial",
        "source": AGROSMART_DATA["metadata"]["climate_source"],
        "disclaimer": CLIMATE_DISCLAIMER,
    }
