from datetime import timedelta

from app.security import create_access_token
from tests.conftest import PASSWORD, register


def test_register_returns_token_and_name(client):
    res = register(client)
    assert res.status_code == 201
    body = res.json()
    assert body["access_token"] and body["token_type"] == "bearer"
    assert body["full_name"] == "Ana Quispe" and body["expires_in"] > 0


def test_register_normalizes_email_and_rejects_duplicates(client):
    assert register(client, email="Ana@Example.com").json()["user_email"] == "ana@example.com"
    dup = register(client, email="ana@example.com")
    assert dup.status_code == 409
    assert "ya está registrado" in dup.json()["detail"]


def test_register_password_policy_in_spanish(client):
    res = register(client, password="abc")
    assert res.status_code == 422
    assert "al menos 8 caracteres" in res.json()["detail"]
    res = register(client, password="soloLetras")
    assert "letras y números" in res.json()["detail"]


def test_register_invalid_email(client):
    res = register(client, email="no-es-correo")
    assert res.status_code == 422
    assert res.json()["detail"] == "Ingresa un correo electrónico válido."


def test_login_ok_returns_full_name(client):
    register(client)
    res = client.post("/auth/login", json={"email": "ANA@example.com", "password": PASSWORD})
    assert res.status_code == 200
    assert res.json()["full_name"] == "Ana Quispe"


def test_login_wrong_password_and_unknown_user_same_message(client):
    register(client)
    a = client.post("/auth/login", json={"email": "ana@example.com", "password": "Incorrecta1"})
    b = client.post("/auth/login", json={"email": "nadie@example.com", "password": "Incorrecta1"})
    assert a.status_code == b.status_code == 401
    assert a.json()["detail"] == b.json()["detail"] == "Correo o contraseña incorrectos."


def test_me_requires_valid_token(client, auth_headers):
    assert client.get("/auth/me", headers=auth_headers).json()["email"] == "ana@example.com"
    res = client.get("/auth/me")
    assert res.status_code == 401
    assert res.json()["detail"] == "Tu sesión expiró o no es válida. Inicia sesión nuevamente."
    res = client.get("/auth/me", headers={"Authorization": "Bearer basura"})
    assert res.status_code == 401
    assert "sesión" in res.json()["detail"]


def test_expired_token_is_rejected(client):
    register(client)
    token, _ = create_access_token("ana@example.com", expires_delta=timedelta(seconds=-1))
    res = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 401


def test_swagger_oauth2_token_endpoint(client):
    register(client)
    res = client.post("/auth/token", data={"username": "ana@example.com", "password": PASSWORD})
    assert res.status_code == 200 and res.json()["access_token"]
    schema = client.get("/openapi.json").json()
    flows = schema["components"]["securitySchemes"]["OAuth2PasswordBearer"]["flows"]
    assert flows["password"]["tokenUrl"] == "/auth/token"


def test_rate_limit_on_login(client):
    from app.rate_limit import limiter

    limiter.enabled = True
    try:
        codes = [
            client.post("/auth/login", json={"email": "x@example.com", "password": "Incorrecta1"}).status_code
            for _ in range(6)
        ]
    finally:
        limiter.enabled = False
    assert codes[:5] == [401] * 5
    assert codes[5] == 429
