from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Lectura
from .. import models, schemas

router = APIRouter(
    prefix="/tinacos",
    tags=["Tinacos"]
)

@router.post("/")
def crear_tinaco(
    tinaco: schemas.TinacoCreate,
    db: Session = Depends(get_db)
):

    nuevo = models.Tinaco(
        nombre=tinaco.nombre,
        capacidad_litros=tinaco.capacidad_litros,
        altura_cm=tinaco.altura_cm,
        edificio_id=tinaco.edificio_id
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


@router.get("/")
def listar_tinacos(
    db: Session = Depends(get_db)
):

    return db.query(models.Tinaco).all()
@router.get("/{tinaco_id}/ultima-lectura")
def obtener_ultima_lectura(
    tinaco_id: int,
    db: Session = Depends(get_db)
):

    lectura = (
        db.query(Lectura)
        .filter(
            Lectura.tinaco_id == tinaco_id
        )
        .order_by(
            Lectura.fecha.desc()
        )
        .first()
    )

    if not lectura:

        return {
            "mensaje":
            "No existen lecturas"
        }

    return lectura
@router.get("/{tinaco_id}/historial")
def obtener_historial(
    tinaco_id: int,
    db: Session = Depends(get_db)
):

    lecturas = (
        db.query(Lectura)
        .filter(
            Lectura.tinaco_id == tinaco_id
        )
        .order_by(
            Lectura.fecha.asc()
        )
        .all()
    )

    return lecturas