"""Hash de contraseñas, emisión/validación de JWT y dependencia de usuario actual."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .config import get_settings
from .database import get_db
from .db_models import User

_settings = get_settings()
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# tokenUrl apunta al endpoint de formulario OAuth2 para que el botón "Authorize" de Swagger funcione.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

# Hash fijo para igualar el tiempo de respuesta cuando el correo no existe (evita enumerar usuarios).
_DUMMY_HASH = _pwd_context.hash("agrosmart-dummy-password")

CREDENTIALS_EXCEPTION = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Tu sesión expiró o no es válida. Inicia sesión nuevamente.",
    headers={"WWW-Authenticate": "Bearer"},
)


def hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str | None) -> bool:
    if not hashed_password:
        _pwd_context.verify(plain_password, _DUMMY_HASH)
        return False
    return _pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str, expires_delta: timedelta | None = None) -> tuple[str, int]:
    """Devuelve (token, segundos_de_validez)."""
    delta = expires_delta or timedelta(minutes=_settings.access_token_expire_minutes)
    now = datetime.now(timezone.utc)
    payload = {"sub": subject, "iat": now, "exp": now + delta, "type": "access"}
    token = jwt.encode(payload, _settings.secret_key, algorithm=_settings.jwt_algorithm)
    return token, int(delta.total_seconds())


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    try:
        payload = jwt.decode(token, _settings.secret_key, algorithms=[_settings.jwt_algorithm])
    except JWTError:
        raise CREDENTIALS_EXCEPTION
    email = payload.get("sub")
    if not isinstance(email, str) or payload.get("type") != "access":
        raise CREDENTIALS_EXCEPTION
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise CREDENTIALS_EXCEPTION
    return user
