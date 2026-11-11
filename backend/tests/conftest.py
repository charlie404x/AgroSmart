"""Configuración de pruebas: base de datos temporal y clave secreta efímera."""
import os
import secrets
import tempfile

_DB_DIR = tempfile.mkdtemp(prefix="agrosmart-test-")
os.environ["SECRET_KEY"] = secrets.token_hex(32)
os.environ["DATABASE_URL"] = f"sqlite:///{_DB_DIR}/test.db"
os.environ["ENVIRONMENT"] = "test"
os.environ["CORS_ORIGINS"] = "http://localhost"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.database import Base, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.rate_limit import limiter  # noqa: E402

PASSWORD = "Cultivo2026"


@pytest.fixture(autouse=True)
def _clean_db():
    limiter.enabled = False
    limiter.reset()
    from app import db_models  # noqa: F401

    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client


def register(client, email="ana@example.com", name="Ana Quispe", password=PASSWORD):
    return client.post("/auth/register", json={"full_name": name, "email": email, "password": password})


@pytest.fixture
def auth_headers(client):
    token = register(client).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


VALID_REQUEST = {"department": "Cusco", "altitude": 3200, "soil_type": "Andosol", "water_availability": "Media"}
