from fastapi import APIRouter, Depends, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from ..config import get_settings
from ..database import get_db
from ..db_models import User
from ..rate_limit import limiter
from ..schemas import TokenResponse, UserCreate, UserLogin, UserOut
from ..security import create_access_token, get_current_user
from ..services import user_service

router = APIRouter(prefix="/auth", tags=["Autenticación"])
_AUTH_LIMIT = get_settings().auth_rate_limit


def _token_for(user: User) -> TokenResponse:
    token, expires_in = create_access_token(user.email)
    return TokenResponse(access_token=token, expires_in=expires_in, user_email=user.email, full_name=user.full_name)


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED,
             summary="Crear cuenta", responses={409: {"description": "El correo ya está registrado"}})
@limiter.limit(_AUTH_LIMIT)
def register(request: Request, user_data: UserCreate, db: Session = Depends(get_db)) -> TokenResponse:
    """Crea una cuenta y devuelve un token de acceso JWT."""
    return _token_for(user_service.register_user(db, user_data))


@router.post("/login", response_model=TokenResponse, summary="Iniciar sesión",
             responses={401: {"description": "Credenciales incorrectas"}})
@limiter.limit(_AUTH_LIMIT)
def login(request: Request, user_data: UserLogin, db: Session = Depends(get_db)) -> TokenResponse:
    """Valida las credenciales (JSON) y devuelve un token de acceso JWT. Lo usa la app móvil."""
    return _token_for(user_service.authenticate(db, user_data.email, user_data.password))


@router.post("/token", response_model=TokenResponse, summary="Token OAuth2 (Swagger)", include_in_schema=True)
@limiter.limit(_AUTH_LIMIT)
def token(request: Request, form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)) -> TokenResponse:
    """Endpoint de formulario OAuth2 usado por el botón *Authorize* de Swagger. `username` = correo."""
    return _token_for(user_service.authenticate(db, form.username, form.password))


@router.get("/me", response_model=UserOut, summary="Usuario actual",
            responses={401: {"description": "Token ausente, inválido o expirado"}})
def me(current_user: User = Depends(get_current_user)) -> User:
    """Devuelve el usuario del token. La app lo usa para validar la sesión al abrirse."""
    return current_user
