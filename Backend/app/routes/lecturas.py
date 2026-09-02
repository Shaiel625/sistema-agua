from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models

from .. import schemas

router = APIRouter(
    prefix="/lecturas",
    tags=["Lecturas"]
)


@router.post("/")
def crear_lectura(
    lectura: schemas.LecturaCreate,
    db: Session = Depends(get_db)
):

    nueva = models.Lectura(
        tinaco_id=lectura.tinaco_id,
        porcentaje=lectura.porcentaje,
        litros=lectura.litros
    )

    db.add(nueva)
    db.commit()
    db.refresh(nueva)

    return nueva


@router.get("/")
def listar_lecturas(
    db: Session = Depends(get_db)
):

    return db.query(models.Lectura).all()