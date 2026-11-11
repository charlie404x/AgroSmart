from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..db_models import User
from ..schemas import HistoryPage, RecommendResponse
from ..security import get_current_user
from ..services import history_service

router = APIRouter(prefix="/history", tags=["Historial"])


@router.get("/", response_model=HistoryPage, summary="Listar mis consultas")
def list_history(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Consultas del usuario autenticado, de la más reciente a la más antigua."""
    return history_service.list_queries(db, current_user, limit, offset)


@router.get("/{query_id}", response_model=RecommendResponse, summary="Detalle de una consulta",
            responses={404: {"description": "No existe o pertenece a otro usuario"}})
def history_detail(query_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    return history_service.get_query_detail(db, current_user, query_id)


@router.delete("/{query_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Eliminar una consulta",
               responses={404: {"description": "No existe o pertenece a otro usuario"}})
def delete_history(query_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> Response:
    history_service.delete_query(db, current_user, query_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
