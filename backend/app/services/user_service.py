"""Lógica de negocio de usuarios."""
from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db_models import User
from ..schemas import UserCreate
from ..security import hash_password, verify_password

EMAIL_TAKEN = "Este correo ya está registrado. Inicia sesión o usa otro correo."
BAD_CREDENTIALS = "Correo o contraseña incorrectos."


def register_user(db: Session, data: UserCreate) -> User:
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=EMAIL_TAKEN)
    user = User(full_name=data.full_name, email=data.email, hashed_password=hash_password(data.password))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        # Dos registros simultáneos con el mismo correo: el índice único decide.
        db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=EMAIL_TAKEN)
    db.refresh(user)
    return user


def authenticate(db: Session, email: str, password: str) -> User:
    user = db.query(User).filter(User.email == email.strip().lower()).first()
    password_ok = verify_password(password, user.hashed_password if user else None)
    if user is None or not password_ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=BAD_CREDENTIALS,
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user
