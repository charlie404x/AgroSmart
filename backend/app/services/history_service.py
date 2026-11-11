"""Persistencia y consulta del historial de recomendaciones."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from ..db_models import RecommendationQuery, User

NOT_FOUND = "No encontramos esa consulta en tu historial."
TOP_CROPS_IN_SUMMARY = 3


def save_query(db: Session, user: User, result: dict[str, Any]) -> RecommendationQuery:
    crops = result["recommended_crops"]
    record = RecommendationQuery(
        user_id=user.id,
        department=result["department"],
        altitude=result["altitude"],
        soil_type=result["soil_type"],
        water_availability=result["water_availability"],
        altitude_band=result["altitude_band"],
        result_count=len(crops),
        used_fallback=result["used_fallback"],
        top_crops=json.dumps([c["name"] for c in crops[:TOP_CROPS_IN_SUMMARY]], ensure_ascii=False),
        result_json=json.dumps(result, ensure_ascii=False),
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def _as_utc(value: datetime) -> datetime:
    # SQLite no conserva la zona horaria; todas las fechas se guardan en UTC.
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def to_summary(record: RecommendationQuery) -> dict[str, Any]:
    return {
        "id": record.id,
        "created_at": _as_utc(record.created_at),
        "department": record.department,
        "altitude": record.altitude,
        "soil_type": record.soil_type,
        "water_availability": record.water_availability,
        "altitude_band": record.altitude_band,
        "result_count": record.result_count,
        "used_fallback": record.used_fallback,
        "top_crops": json.loads(record.top_crops or "[]"),
        "top_crop_keys": _top_keys(record),
    }


def _top_keys(record: RecommendationQuery) -> list[str]:
    try:
        crops = json.loads(record.result_json).get("recommended_crops", [])
    except (ValueError, AttributeError):
        return []
    return [c.get("crop_key", "") for c in crops[:TOP_CROPS_IN_SUMMARY]]


def list_queries(db: Session, user: User, limit: int, offset: int) -> dict[str, Any]:
    base = db.query(RecommendationQuery).filter(RecommendationQuery.user_id == user.id)
    total = base.with_entities(func.count(RecommendationQuery.id)).scalar() or 0
    records = (
        base.order_by(RecommendationQuery.created_at.desc(), RecommendationQuery.id.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return {"items": [to_summary(r) for r in records], "total": total, "limit": limit, "offset": offset}


def _get_owned(db: Session, user: User, query_id: int) -> RecommendationQuery:
    record = (
        db.query(RecommendationQuery)
        .filter(RecommendationQuery.id == query_id, RecommendationQuery.user_id == user.id)
        .first()
    )
    # Se responde 404 tanto si no existe como si pertenece a otro usuario (no se revela su existencia).
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=NOT_FOUND)
    return record


def get_query_detail(db: Session, user: User, query_id: int) -> dict[str, Any]:
    record = _get_owned(db, user, query_id)
    result = json.loads(record.result_json)
    result["id"] = record.id
    result["created_at"] = _as_utc(record.created_at)
    return result


def delete_query(db: Session, user: User, query_id: int) -> None:
    record = _get_owned(db, user, query_id)
    db.delete(record)
    db.commit()
