from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Accion
from ..schemas import AccionResponse

router = APIRouter(
    prefix="/acciones",
    tags=["Acciones"]
)

@router.get("/", response_model=list[AccionResponse])
def obtener_acciones(
    db: Session = Depends(get_db)
):

    return (
        db.query(Accion)
        .order_by(Accion.fecha.desc())
        .all()
    )

@router.get("/incidencia/{incidencia_id}", response_model=list[AccionResponse])
def acciones_por_incidencia(
    incidencia_id: int,
    db: Session = Depends(get_db)
):

    return (
        db.query(Accion)
        .filter(
            Accion.incidencia_id == incidencia_id
        )
        .order_by(
            Accion.fecha.asc()
        )
        .all()
    )

@router.get("/{accion_id}", response_model=AccionResponse)
def obtener_accion(
    accion_id: int,
    db: Session = Depends(get_db)
):

    accion = (
        db.query(Accion)
        .filter(
            Accion.id == accion_id
        )
        .first()
    )

    if accion is None:

        raise HTTPException(
            status_code=404,
            detail="Acción no encontrada"
        )

    return accion