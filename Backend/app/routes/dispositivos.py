from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models
from .. import schemas

router = APIRouter(
    prefix="/dispositivos",
    tags=["Dispositivos"]
)


@router.post("/")
def crear_dispositivo(
    dispositivo: schemas.DispositivoCreate,
    db: Session = Depends(get_db)
):

    nuevo = models.Dispositivo(
        esp32_id=dispositivo.esp32_id,
        estado=dispositivo.estado
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


@router.get("/")
def listar_dispositivos(
    db: Session = Depends(get_db)
):

    return db.query(models.Dispositivo).all()