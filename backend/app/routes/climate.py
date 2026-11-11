from fastapi import APIRouter

from ..catalog import DEPARTMENTS, MAX_ALTITUDE, MIN_ALTITUDE, SOIL_TYPES, WATER_LEVELS
from ..schemas import CatalogResponse, ClimateResponse
from ..services.climate_service import get_climate
from ..services.recommendation_service import ALTITUDE_BANDS

router = APIRouter(tags=["Clima y catálogo"])


@router.get("/climate/{department}", response_model=ClimateResponse, summary="Clima referencial del departamento",
            responses={404: {"description": "Departamento no disponible"}})
def climate(department: str) -> dict:
    """Promedios climáticos referenciales (SENAMHI) del departamento. No son datos en tiempo real."""
    return get_climate(department)


@router.get("/catalog", response_model=CatalogResponse, summary="Opciones válidas del formulario")
def catalog() -> dict:
    return {
        "departments": list(DEPARTMENTS),
        "soil_types": list(SOIL_TYPES),
        "water_levels": list(WATER_LEVELS),
        "min_altitude": MIN_ALTITUDE,
        "max_altitude": MAX_ALTITUDE,
        "altitude_bands": ALTITUDE_BANDS,
    }
