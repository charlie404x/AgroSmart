"""Manejo centralizado de errores con mensajes en español."""
from __future__ import annotations

import logging

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("agrosmart")

_FIELD_LABELS = {
    "department": "Departamento",
    "altitude": "Altitud",
    "soil_type": "Tipo de suelo",
    "water_availability": "Disponibilidad hídrica",
    "email": "Correo",
    "password": "Contraseña",
    "full_name": "Nombre",
    "username": "Correo",
    "limit": "Límite",
    "offset": "Desplazamiento",
}

_TYPE_MESSAGES = {
    "missing": "es obligatorio.",
    "float_parsing": "debe ser un número.",
    "int_parsing": "debe ser un número entero.",
    "string_type": "debe ser texto.",
    "string_too_long": "es demasiado largo.",
    "string_too_short": "es demasiado corto.",
    "value_error": "no es válido.",
    "greater_than_equal": "es demasiado pequeño.",
    "less_than_equal": "es demasiado grande.",
    "json_invalid": "contiene JSON inválido.",
}

# Mensajes por defecto de FastAPI/Starlette que se reemplazan por su versión en español.
_ENGLISH_DEFAULTS = {"Not Found", "Method Not Allowed", "Unauthorized", "Not authenticated", "Forbidden"}

_STATUS_MESSAGES = {
    400: "Solicitud inválida.",
    401: "Tu sesión expiró o no es válida. Inicia sesión nuevamente.",
    403: "No tienes permiso para realizar esta acción.",
    404: "Recurso no encontrado.",
    405: "Método no permitido.",
}


def _format_error(error: dict) -> str:
    loc = [str(part) for part in error.get("loc", ()) if part not in ("body", "query", "path")]
    field = _FIELD_LABELS.get(loc[-1], loc[-1]) if loc else "Solicitud"
    err_type = error.get("type", "")
    if err_type == "value_error":
        message = str(error.get("msg", "")).removeprefix("Value error, ")
        if "email address" in message:
            return "Ingresa un correo electrónico válido."
        return message or f"{field} no es válido."
    return f"{field} {_TYPE_MESSAGES.get(err_type, 'no es válido.')}"


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(RequestValidationError)
    async def _validation_handler(_request: Request, exc: RequestValidationError) -> JSONResponse:
        messages = [_format_error(err) for err in exc.errors()]
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={"detail": messages[0] if messages else "Datos inválidos.", "errors": messages},
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http_handler(_request: Request, exc: StarletteHTTPException) -> JSONResponse:
        detail = exc.detail
        if not isinstance(detail, str) or detail in _ENGLISH_DEFAULTS:
            detail = _STATUS_MESSAGES.get(exc.status_code, "Error en la solicitud.")
        return JSONResponse(status_code=exc.status_code, content={"detail": detail}, headers=exc.headers)

    @app.exception_handler(RateLimitExceeded)
    async def _rate_limit_handler(_request: Request, _exc: RateLimitExceeded) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": "Demasiados intentos. Espera un minuto e inténtalo de nuevo."},
        )

    @app.exception_handler(Exception)
    async def _unhandled_handler(request: Request, _exc: Exception) -> JSONResponse:
        logger.exception("Error no controlado en %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "Ocurrió un error interno. Inténtalo más tarde."},
        )
