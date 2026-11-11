"""Configuración centralizada de la API.

Todos los valores sensibles o dependientes del entorno se leen de variables de
entorno (o de ``backend/.env`` en desarrollo). Ningún secreto se define en el
código fuente.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()

_INSECURE_PLACEHOLDERS = {"", "change-this-to-a-random-64-char-hex-string", "changeme", "secret"}


def _split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


@dataclass(frozen=True)
class Settings:
    environment: str = field(default_factory=lambda: os.getenv("ENVIRONMENT", "development").lower())
    secret_key: str = field(default_factory=lambda: os.getenv("SECRET_KEY", ""))
    access_token_expire_minutes: int = field(
        default_factory=lambda: int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    )
    database_url: str = field(default_factory=lambda: os.getenv("DATABASE_URL", "sqlite:///./agrosmart.db"))
    cors_origins: list[str] = field(
        default_factory=lambda: _split_csv(os.getenv("CORS_ORIGINS", "http://localhost"))
    )
    rate_limit_enabled: bool = field(
        default_factory=lambda: os.getenv("RATE_LIMIT_ENABLED", "true").lower() in {"1", "true", "yes"}
    )
    auth_rate_limit: str = field(default_factory=lambda: os.getenv("AUTH_RATE_LIMIT", "5/minute"))
    jwt_algorithm: str = "HS256"

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    @property
    def docs_enabled(self) -> bool:
        # En producción la documentación interactiva sólo se expone si se pide explícitamente.
        return not self.is_production or os.getenv("ENABLE_DOCS", "false").lower() == "true"

    def validate(self) -> None:
        if self.secret_key in _INSECURE_PLACEHOLDERS:
            raise RuntimeError(
                "SECRET_KEY no está configurada. Copia backend/.env.example a backend/.env "
                "y genera una clave con: python -c \"import secrets; print(secrets.token_hex(32))\""
            )
        if len(self.secret_key) < 32:
            raise RuntimeError("SECRET_KEY debe tener al menos 32 caracteres.")
        if self.is_production:
            if "*" in self.cors_origins:
                raise RuntimeError("En producción CORS_ORIGINS no puede contener '*'.")
            if any(origin.startswith("http://") for origin in self.cors_origins):
                raise RuntimeError("En producción todos los orígenes CORS deben usar HTTPS.")
        if self.access_token_expire_minutes <= 0:
            raise RuntimeError("ACCESS_TOKEN_EXPIRE_MINUTES debe ser mayor que 0.")


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.validate()
    return settings
