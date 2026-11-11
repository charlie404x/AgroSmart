# AgroSMART Perú

Aplicación móvil de recomendación de cultivos para la sierra peruana. El usuario describe su terreno (departamento, altitud, tipo de suelo y agua disponible) y la app sugiere los cultivos andinos más adecuados, con justificación específica para sus condiciones, temporadas de siembra y cosecha, rendimiento, precio referencial e ingreso bruto estimado por hectárea. Las consultas se guardan en un historial por usuario y la app muestra el clima referencial de cada departamento.

Las recomendaciones se basan en **AgroSmartData**, un dataset propio con 8 departamentos (Apurímac, Ayacucho, Cajamarca, Cusco, Huancavelica, Junín, Pasco y Puno), **16 cultivos andinos** (papa, maíz amiláceo, quinua, cebada, trigo, avena, haba, arveja, lenteja, olluco, oca, mashua, tarwi, cañihua, kiwicha y maca), 6 tipos de suelo y 54 reglas (todas las combinaciones de banda de altitud × suelo × agua). Fuentes referenciadas: SENAMHI (clima) y MIDAGRI-SIEA (precios y rendimientos).

> **Sobre los datos.** El clima son promedios referenciales, no mediciones en tiempo real. Los precios por departamento se derivan de un precio base de la sierra ajustado por un factor fijo por departamento; **no son cotizaciones regionales verificadas**. El ingreso bruto estimado no descuenta costos y no es una ganancia garantizada. La app lo indica en cada pantalla donde aparecen estos valores.

## Arquitectura

```
Flutter (Dart)                                   FastAPI (Python)
screens → providers → services → ApiClient  ──HTTPS/JSON──▶  routes → services → SQLAlchemy (SQLite/PostgreSQL)
          (estado)    (API)      (Dio, 401)  ◀──JWT Bearer──            ↘ motor de recomendación (AgroSmartData)
```

| Capa | Tecnología |
|---|---|
| App | Flutter 3.44+, Dart 3.12+, Material 3, `provider`, `go_router`, `dio`, `flutter_secure_storage`, `shared_preferences`, `flutter_svg` |
| API | Python 3.12, FastAPI, Pydantic v2, SQLAlchemy 2, python-jose (JWT HS256), passlib/bcrypt, slowapi |
| Base de datos | SQLite en desarrollo; PostgreSQL recomendado en producción (`DATABASE_URL`) |

### Estructura

```
lib/
├── app.dart, main.dart       # Arranque, providers y router
├── config/                   # AppConfig (URL por --dart-define), sistema de diseño (tema claro/oscuro)
├── core/                     # ApiClient (Dio + detección de 401), ApiException, sesión cifrada, preferencias
├── models/                   # Modelos inmutables con lectura defensiva de JSON
├── services/                 # AuthService, AgroService (recomendación, historial, clima)
├── providers/                # Auth, Recommendation, History, Climate
├── routes/                   # go_router con redirección por estado de sesión
├── screens/                  # Splash, Login, Registro, Inicio, Formulario, Resultados, Historial, Detalle, Clima
├── utils/                    # Opciones agrícolas, validadores, formatos (S/, fechas), JWT
└── widgets/                  # Componentes del sistema de diseño y de resultados
backend/
├── app/
│   ├── config.py             # Configuración por variables de entorno (valida SECRET_KEY, CORS)
│   ├── database.py, db_models.py   # Sesión SQLAlchemy, tablas users y recommendation_queries
│   ├── schemas.py            # Validación Pydantic con mensajes en español
│   ├── security.py, errors.py      # JWT/bcrypt y manejo centralizado de errores
│   ├── services/             # Motor de recomendación, historial, clima, usuarios
│   ├── routes/               # auth, recommend, history, climate
│   └── utils/agrosmart_data.py     # Dataset AgroSmartData
├── scripts/create_env.py     # Genera .env con una SECRET_KEY nueva
└── tests/                    # pytest
test/                         # Pruebas Flutter (unitarias, providers, widgets) + fixtures de contrato
```

## Puesta en marcha

### 1. Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate            # Windows
# source .venv/bin/activate       # macOS/Linux
pip install -r requirements-dev.txt

python scripts/create_env.py      # crea .env con una SECRET_KEY nueva (no sobrescribe uno existente)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
```

Documentación interactiva en `http://127.0.0.1:8002/docs`. Para probar endpoints protegidos en Swagger usa **Authorize** con tu correo (campo *username*) y contraseña.

### 2. App Flutter

```bash
flutter pub get
dart run flutter_native_splash:create    # opcional: genera la pantalla nativa de arranque
flutter run                              # emulador Android → backend en http://10.0.2.2:8002
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8002   # teléfono físico en la misma red
```

### Variables de entorno (`backend/.env`)

| Variable | Descripción |
|---|---|
| `ENVIRONMENT` | `development`, `production` o `test`. En producción se exige CORS con HTTPS y se ocultan `/docs`. |
| `SECRET_KEY` | **Obligatoria**, mínimo 32 caracteres, distinta por entorno. Nunca la publiques. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Validez del token (por defecto 30). Al vencer, la app cierra la sesión y vuelve al login con un aviso. |
| `DATABASE_URL` | Cadena SQLAlchemy (por defecto `sqlite:///./agrosmart.db`). |
| `CORS_ORIGINS` | Orígenes permitidos (sólo afecta a Flutter Web). |
| `RATE_LIMIT_ENABLED`, `AUTH_RATE_LIMIT` | Límite de intentos en login y registro (por defecto 5/minuto por IP). |
| `ENABLE_DOCS` | Expone `/docs` en producción si vale `true`. |

## API

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| POST | `/auth/register` | No | Crea una cuenta (201) y devuelve un JWT. 409 si el correo ya existe. |
| POST | `/auth/login` | No | Inicia sesión (JSON). |
| POST | `/auth/token` | No | Formulario OAuth2 para Swagger. |
| GET | `/auth/me` | Sí | Usuario actual; la app lo usa para validar la sesión al abrirse. |
| POST | `/recommend/` | Sí | Recomienda cultivos y guarda la consulta en el historial. |
| GET | `/history/?limit=&offset=` | Sí | Consultas del usuario, de la más reciente a la más antigua. |
| GET / DELETE | `/history/{id}` | Sí | Detalle o eliminación (404 si no existe o es de otro usuario). |
| GET | `/climate/{departamento}` | No | Clima referencial del departamento. |
| GET | `/catalog` | No | Valores válidos del formulario. |
| GET | `/health` | No | Estado del servicio. |

Todas las respuestas de error devuelven `{"detail": "<mensaje en español>"}`.

## Motor de recomendación

1. Clasifica la altitud: Baja (< 2 500 m), Media (2 500–3 500 m), Alta (> 3 500 m).
2. Busca la regla exacta banda + suelo + agua y conserva los cultivos cuyo rango de altitud incluye la altitud real.
3. Si no queda ninguno, ofrece **alternativas con reservas**: cultivos que toleran la altitud y el agua disponible, marcados como tales. Si tampoco hay, responde con una lista vacía y una explicación.
4. Evalúa cada cultivo contra el suelo, el agua y la altitud del usuario y genera razones y advertencias específicas.
5. Ordena por **ingreso bruto estimado por hectárea = rendimiento (t/ha) × 1000 × precio (S/ por kg)**.

La combinación *Alta + Fluvisol + agua baja* no tiene cultivo directo: ningún cultivo del dataset reúne Fluvisol como suelo ideal, baja demanda hídrica y adaptación a más de 3 500 m, así que se responde con alternativas con reservas en lugar de inventar una recomendación.

## Seguridad

- No se versionan ni distribuyen `.env`, bases de datos, `key.properties` ni keystores (ver `.gitignore`).
- El token se guarda cifrado (`flutter_secure_storage`: Keychain en iOS, Keystore en Android) y nunca se registra en los logs.
- Android: permiso `INTERNET` en todas las variantes; HTTP sin cifrar sólo en debug/profile; respaldo automático desactivado. Producción debe usar HTTPS.
- Contraseñas con bcrypt, política de 8+ caracteres con letras y números, límite de intentos, mismo mensaje para correo inexistente y contraseña incorrecta.

### Firma del APK de producción

```bash
keytool -genkey -v -keystore ~/agrosmart-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias agrosmart
cp android/key.properties.example android/key.properties   # y completa los valores
flutter build apk --release --dart-define=API_BASE_URL=https://api.tudominio.pe
```

Sin `android/key.properties` el build de release queda sin firmar: nunca se usa la clave de debug para producción.

## Pruebas

```bash
cd backend && pytest                 # API, motor, autenticación, historial, clima, validaciones
flutter analyze                      # análisis estático con reglas estrictas (analysis_options.yaml)
flutter test                         # unitarias, providers y widgets
```

Los JSON de `test/fixtures/` se generaron desde el backend real, de modo que las pruebas de Flutter verifican el mismo contrato de la API.

## Despliegue (guía)

- **Backend:** contenedor con `uvicorn`/`gunicorn` detrás de HTTPS, `ENVIRONMENT=production`, `DATABASE_URL` a PostgreSQL y secretos gestionados por la plataforma. Si hay proxy inverso, ejecuta uvicorn con `--proxy-headers` para que el límite de intentos use la IP real.
- **App:** `flutter build appbundle --release --dart-define=API_BASE_URL=https://...` para Play Store.

## Pendientes conocidos

- Precios regionales verificados: requieren una fuente oficial actualizada por departamento.
- Migraciones de base de datos (Alembic) antes de un despliegue con datos reales.
- Renovación de tokens (refresh tokens): no implementada; al vencer, el usuario vuelve a iniciar sesión.
- Capturas de pantalla para este README.
