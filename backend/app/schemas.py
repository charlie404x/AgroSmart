"""Esquemas Pydantic de entrada y salida de la API."""
from __future__ import annotations

import re
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from .catalog import DEPARTMENTS, MAX_ALTITUDE, MIN_ALTITUDE, SOIL_TYPES, WATER_LEVELS, normalize_choice

PASSWORD_MIN_LENGTH = 8


# ----- AUTENTICACIÓN -----
class UserCreate(BaseModel):
    full_name: str = Field(..., max_length=120)
    email: EmailStr
    password: str = Field(..., max_length=128)

    @field_validator("full_name")
    @classmethod
    def _validate_name(cls, value: str) -> str:
        value = " ".join(value.split())
        if len(value) < 2:
            raise ValueError("El nombre debe tener al menos 2 caracteres.")
        return value

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()

    @field_validator("password")
    @classmethod
    def _validate_password(cls, value: str) -> str:
        if len(value) < PASSWORD_MIN_LENGTH:
            raise ValueError(f"La contraseña debe tener al menos {PASSWORD_MIN_LENGTH} caracteres.")
        if not re.search(r"[A-Za-z]", value) or not re.search(r"\d", value):
            raise ValueError("La contraseña debe incluir letras y números.")
        return value


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    full_name: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Segundos de validez del token")
    user_email: str
    full_name: str | None = None


# ----- RECOMENDACIÓN -----
class RecommendRequest(BaseModel):
    department: str
    altitude: float = Field(..., description="Altitud del terreno en m s. n. m. (0 a 5000)")
    soil_type: str
    water_availability: str = Field(..., description="Baja, Media o Alta")

    @field_validator("department")
    @classmethod
    def _validate_department(cls, value: str) -> str:
        canonical = normalize_choice(value, DEPARTMENTS)
        if canonical is None:
            raise ValueError(f"Departamento no válido. Opciones: {', '.join(DEPARTMENTS)}.")
        return canonical

    @field_validator("soil_type")
    @classmethod
    def _validate_soil(cls, value: str) -> str:
        canonical = normalize_choice(value, SOIL_TYPES)
        if canonical is None:
            raise ValueError(f"Tipo de suelo no válido. Opciones: {', '.join(SOIL_TYPES)}.")
        return canonical

    @field_validator("water_availability")
    @classmethod
    def _validate_water(cls, value: str) -> str:
        canonical = normalize_choice(value, WATER_LEVELS)
        if canonical is None:
            raise ValueError(f"Disponibilidad hídrica no válida. Opciones: {', '.join(WATER_LEVELS)}.")
        return canonical

    @field_validator("altitude")
    @classmethod
    def _validate_altitude(cls, value: float) -> float:
        if value != value or value < MIN_ALTITUDE or value > MAX_ALTITUDE:  # value != value detecta NaN
            raise ValueError(f"La altitud debe estar entre {int(MIN_ALTITUDE)} y {int(MAX_ALTITUDE)} m.")
        return value


class CropRecommendation(BaseModel):
    crop_key: str
    name: str
    description: str
    price_per_kg: float = Field(..., description="Precio referencial en S/ por kg")
    estimated_income_per_ha: float | None = Field(
        None, description="Ingreso bruto estimado (S/ por ha) = rendimiento × 1000 × precio. No es ganancia."
    )
    justification: str
    reasons: list[str]
    warnings: list[str]
    suitability: str = Field(..., description="alta | media | baja")
    tag: str = Field(..., description="Etiqueta corta para la interfaz")
    is_fallback: bool = False
    soil_match: bool
    water_match: bool
    ideal_soils: list[str]
    water_need: str
    optimal_temperature: str
    sowing_season: str
    harvest_season: str
    yield_avg: float
    min_altitude: int
    max_altitude: int
    altitude_range: str


class RecommendResponse(BaseModel):
    id: int | None = Field(None, description="Id de la consulta en el historial")
    created_at: datetime | None = None
    department: str
    altitude: float
    altitude_band: str
    soil_type: str
    water_availability: str
    recommended_crops: list[CropRecommendation]
    used_fallback: bool
    notice: str | None = None
    price_disclaimer: str
    sort_criteria: str


# ----- HISTORIAL -----
class HistoryItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    department: str
    altitude: float
    soil_type: str
    water_availability: str
    altitude_band: str
    result_count: int
    used_fallback: bool
    top_crops: list[str]
    top_crop_keys: list[str] = []


class HistoryPage(BaseModel):
    items: list[HistoryItem]
    total: int
    limit: int
    offset: int


# ----- CLIMA -----
class ClimateResponse(BaseModel):
    department: str
    classification: str
    temperature_range: str
    precipitation: str
    humidity: str
    description: str
    typical_altitude_min: int
    typical_altitude_max: int
    common_soils: list[str]
    common_crops: list[str]
    data_type: str = Field(..., description="Tipo de dato: 'referencial' (promedio climático, no tiempo real)")
    source: str
    disclaimer: str


class CatalogResponse(BaseModel):
    departments: list[str]
    soil_types: list[str]
    water_levels: list[str]
    min_altitude: float
    max_altitude: float
    altitude_bands: dict[str, str]
