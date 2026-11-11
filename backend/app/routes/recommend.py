import logging

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..db_models import User
from ..schemas import RecommendRequest, RecommendResponse
from ..security import get_current_user
from ..services import history_service
from ..services.recommendation_service import get_recommendation

logger = logging.getLogger("agrosmart")
router = APIRouter(prefix="/recommend", tags=["Recomendación"])


@router.post("/", response_model=RecommendResponse, summary="Recomendar cultivos")
def recommend(
    payload: RecommendRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Calcula los cultivos recomendados para el terreno y guarda la consulta en el historial.

    Siempre responde 200: si no hay cultivos compatibles, `recommended_crops` viene vacío y
    `notice` explica el motivo.
    """
    result = get_recommendation(payload.department, payload.altitude, payload.soil_type, payload.water_availability)
    record = history_service.save_query(db, current_user, result)
    logger.info(
        "Recomendación user=%s dept=%s alt=%s soil=%s water=%s -> %d cultivos (fallback=%s)",
        current_user.id, payload.department, payload.altitude, payload.soil_type,
        payload.water_availability, len(result["recommended_crops"]), result["used_fallback"],
    )
    return {**result, "id": record.id, "created_at": history_service.to_summary(record)["created_at"]}
