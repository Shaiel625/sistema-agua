from fastapi import APIRouter
from sqlalchemy.orm import Session
from fastapi import Depends

from ..database import get_db
from .. import models
from .. import schemas

router = APIRouter(prefix="/edificios", tags=["Edificios"])


@router.post("/")
def crear_edificio(
    edificio: schemas.EdificioCreate,
    db: Session = Depends(get_db)
):

    nuevo = models.Edificio(
        nombre=edificio.nombre
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


@router.get("/")
def listar_edificios(
    db: Session = Depends(get_db)
):
    return db.query(models.Edificio).all()