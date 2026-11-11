"""Punto de entrada de la API AgroSMART Perú."""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.middleware import SlowAPIMiddleware

from .config import get_settings
from .database import init_db
from .errors import register_exception_handlers
from .rate_limit import limiter
from .routes import auth, climate, history, recommend

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("agrosmart")
settings = get_settings()


@asynccontextmanager
async def lifespan(_app: FastAPI):
    init_db()
    logger.info("Base de datos lista (entorno: %s).", settings.environment)
    yield


app = FastAPI(
    title="AgroSMART Perú API",
    description="Recomendación de cultivos andinos para la sierra peruana, con historial y clima referencial.",
    version="1.1.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.docs_enabled else None,
    redoc_url="/redoc" if settings.docs_enabled else None,
    openapi_url="/openapi.json" if settings.docs_enabled else None,
)

app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,  # La API usa Bearer tokens, no cookies.
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)
register_exception_handlers(app)

app.include_router(auth.router)
app.include_router(recommend.router)
app.include_router(history.router)
app.include_router(climate.router)


@app.get("/", tags=["Estado"], summary="Información de la API")
def root() -> dict:
    return {"name": "AgroSMART Perú API", "version": app.version, "status": "ok"}


@app.get("/health", tags=["Estado"], summary="Health check")
def health_check() -> dict:
    return {"status": "ok"}
