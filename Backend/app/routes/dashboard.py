from fastapi import APIRouter
from fastapi import Depends

from sqlalchemy.orm import Session

from sqlalchemy import func

from ..database import get_db
from ..models import Tinaco
from ..models import Lectura
from ..models import Incidencia

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)


@router.get("/")
def dashboard(
    db: Session = Depends(get_db)
):

    resultado = []

    tinacos = db.query(
        Tinaco
    ).all()

    for tinaco in tinacos:

        ultima_lectura = (
            db.query(Lectura)
            .filter(
                Lectura.tinaco_id == tinaco.id
            )
            .order_by(
                Lectura.fecha.desc()
            )
            .first()
        )

        resultado.append(
            {
                "tinaco_id": tinaco.id,
                "nombre": tinaco.nombre,
                "capacidad_litros": tinaco.capacidad_litros,
                "porcentaje":
                    ultima_lectura.porcentaje
                    if ultima_lectura else 0,
                "litros":
                    ultima_lectura.litros
                    if ultima_lectura else 0
            }
        )

    return resultado

@router.get("/estadisticas")
def estadisticas(
    db: Session = Depends(get_db)
):

    total_tinacos = db.query(Tinaco).count()

    incidencias_abiertas = (
        db.query(Incidencia)
        .filter(Incidencia.estado == "ABIERTA")
        .count()
    )

    incidencias_en_proceso = (
        db.query(Incidencia)
        .filter(Incidencia.estado == "EN_PROCESO")
        .count()
    )

    incidencias_resueltas = (
        db.query(Incidencia)
        .filter(Incidencia.estado == "RESUELTA")
        .count()
    )

    promedio_nivel = (
        db.query(func.avg(Lectura.porcentaje))
        .scalar()
    )

    promedio_tiempo = (
        db.query(func.avg(Incidencia.tiempo_real_minutos))
        .scalar()
    )

    return {
        "total_tinacos": total_tinacos,
        "incidencias_abiertas": incidencias_abiertas,
        "incidencias_en_proceso": incidencias_en_proceso,
        "incidencias_resueltas": incidencias_resueltas,
        "nivel_promedio": round(promedio_nivel or 0, 2),
        "tiempo_promedio_atencion": round(promedio_tiempo or 0, 2)
    }


@router.get("/incidencias")
def dashboard_incidencias(
    db: Session = Depends(get_db)
):

    return {
        "abiertas": db.query(Incidencia)
            .filter(Incidencia.estado == "ABIERTA")
            .count(),

        "en_proceso": db.query(Incidencia)
            .filter(Incidencia.estado == "EN_PROCESO")
            .count(),

        "resueltas": db.query(Incidencia)
            .filter(Incidencia.estado == "RESUELTA")
            .count()
    }


@router.get("/criticos")
def tinacos_criticos(
    db: Session = Depends(get_db)
):

    resultado = []

    tinacos = db.query(Tinaco).all()

    for tinaco in tinacos:

        ultima = (
            db.query(Lectura)
            .filter(Lectura.tinaco_id == tinaco.id)
            .order_by(Lectura.fecha.desc())
            .first()
        )

        if ultima and ultima.porcentaje <= 20:

            resultado.append({

                "tinaco_id": tinaco.id,

                "nombre": tinaco.nombre,

                "porcentaje": ultima.porcentaje,

                "litros": ultima.litros

            })

    return resultado