# Fixtures de contrato

Estos JSON se generaron llamando al backend FastAPI real (`backend/app`) con `TestClient`,
para que las pruebas de Flutter verifiquen el mismo contrato que devuelve la API.
Si cambia un esquema del backend, vuelve a generarlos y ejecuta `flutter test`.
El token de `login_response.json` se reemplaza en las pruebas por uno sintético.
