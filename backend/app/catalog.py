"""Valores permitidos derivados del dataset AgroSmartData (fuente única de verdad)."""
from __future__ import annotations

from .utils.agrosmart_data import AGROSMART_DATA

DEPARTMENTS: tuple[str, ...] = tuple(AGROSMART_DATA["departments"].keys())
SOIL_TYPES: tuple[str, ...] = tuple(AGROSMART_DATA["recommendation_rules"]["soil_types_considered"])
WATER_LEVELS: tuple[str, ...] = tuple(AGROSMART_DATA["recommendation_rules"]["water_availability_levels"])
MIN_ALTITUDE = 0.0
MAX_ALTITUDE = 5000.0


def normalize_choice(value: str, allowed: tuple[str, ...]) -> str | None:
    """Devuelve el valor canónico ignorando mayúsculas y tildes; None si no es válido."""
    import unicodedata

    def fold(text: str) -> str:
        return "".join(
            c for c in unicodedata.normalize("NFD", text.strip().lower()) if unicodedata.category(c) != "Mn"
        )

    target = fold(value)
    for option in allowed:
        if fold(option) == target:
            return option
    return None
