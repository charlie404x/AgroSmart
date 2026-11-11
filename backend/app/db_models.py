"""Modelos ORM (tablas)."""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String, nullable=False)
    full_name: Mapped[str | None] = mapped_column(String, nullable=True)

    queries: Mapped[list["RecommendationQuery"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class RecommendationQuery(Base):
    """Consulta de recomendación guardada en el historial del usuario."""

    __tablename__ = "recommendation_queries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, nullable=False, index=True)

    department: Mapped[str] = mapped_column(String, nullable=False)
    altitude: Mapped[float] = mapped_column(Float, nullable=False)
    soil_type: Mapped[str] = mapped_column(String, nullable=False)
    water_availability: Mapped[str] = mapped_column(String, nullable=False)
    altitude_band: Mapped[str] = mapped_column(String, nullable=False)

    result_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    used_fallback: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    top_crops: Mapped[str] = mapped_column(String, nullable=False, default="")
    # Respuesta completa serializada (JSON) para poder mostrar el detalle tal como se entregó.
    result_json: Mapped[str] = mapped_column(Text, nullable=False)

    user: Mapped[User] = relationship(back_populates="queries")
