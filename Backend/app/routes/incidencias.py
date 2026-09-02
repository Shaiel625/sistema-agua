from datetime import datetime
import asyncio

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db

from ..models import (
    Incidencia,
    Accion
)

from ..schemas import (
    IncidenciaCreate,
    IncidenciaResponse
)

from ..websocket_manager import manager


router = APIRouter(
    prefix="/incidencias",
    tags=["Incidencias"]
)




# Obtener todas


@router.get("/", response_model=list[IncidenciaResponse])
def obtener_incidencias(
    db: Session = Depends(get_db)
):

    return db.query(Incidencia).all()




# Crear incidencia


@router.post(
    "/",
    response_model=IncidenciaResponse,
    status_code=status.HTTP_201_CREATED
)
def crear_incidencia(
    datos: IncidenciaCreate,
    db: Session = Depends(get_db)
):

    incidencia = Incidencia(
        **datos.model_dump()
    )


    db.add(incidencia)

    db.commit()

    db.refresh(incidencia)



    accion = Accion(

        incidencia_id=incidencia.id,

        usuario="Sistema",

        accion="Incidencia creada",

        descripcion="Se creó una nueva incidencia."

    )


    db.add(accion)

    db.commit()



    asyncio.run(
        manager.broadcast(
            {
                "tipo": "incidencia",

                "evento": "creada",

                "incidencia_id": incidencia.id,

                "mensaje":
                "Nueva incidencia creada."
            }
        )
    )


    return incidencia





# Historial


@router.get(
    "/historial",
    response_model=list[IncidenciaResponse]
)
def historial(
    db: Session = Depends(get_db)
):

    return (
        db.query(Incidencia)
        .order_by(
            Incidencia.fecha_creacion.desc()
        )
        .all()
    )





# Obtener una incidencia


@router.get(
    "/{incidencia_id}",
    response_model=IncidenciaResponse
)
def obtener_incidencia(
    incidencia_id: int,
    db: Session = Depends(get_db)
):

    incidencia = (
        db.query(Incidencia)
        .filter(
            Incidencia.id == incidencia_id
        )
        .first()
    )


    if incidencia is None:

        raise HTTPException(
            status_code=404,
            detail="Incidencia no encontrada"
        )


    return incidencia





# Actualizar


@router.put(
    "/{incidencia_id}",
    response_model=IncidenciaResponse
)
def actualizar_incidencia(
    incidencia_id: int,
    datos: IncidenciaCreate,
    db: Session = Depends(get_db)
):

    incidencia = (
        db.query(Incidencia)
        .filter(
            Incidencia.id == incidencia_id
        )
        .first()
    )


    if incidencia is None:

        raise HTTPException(
            status_code=404,
            detail="Incidencia no encontrada"
        )


    for campo, valor in datos.model_dump().items():

        setattr(
            incidencia,
            campo,
            valor
        )


    db.commit()

    db.refresh(incidencia)


    return incidencia






# Eliminar


@router.delete("/{incidencia_id}")
def eliminar_incidencia(
    incidencia_id: int,
    db: Session = Depends(get_db)
):

    incidencia = (
        db.query(Incidencia)
        .filter(
            Incidencia.id == incidencia_id
        )
        .first()
    )


    if incidencia is None:

        raise HTTPException(
            status_code=404,
            detail="Incidencia no encontrada"
        )


    db.delete(incidencia)

    db.commit()


    return {

        "mensaje":
        "Incidencia eliminada correctamente"

    }






# Iniciar atención


@router.post("/{incidencia_id}/iniciar")
def iniciar_atencion(
    incidencia_id: int,
    db: Session = Depends(get_db)
):

    incidencia = (
        db.query(Incidencia)
        .filter(
            Incidencia.id == incidencia_id
        )
        .first()
    )


    if incidencia is None:

        raise HTTPException(
            status_code=404,
            detail="Incidencia no encontrada"
        )



    if incidencia.estado != "ABIERTA":

        raise HTTPException(
            status_code=400,
            detail=
            "La incidencia ya fue iniciada o finalizada."
        )



    incidencia.estado = "EN_PROCESO"

    incidencia.fecha_inicio = datetime.utcnow()



    db.commit()

    db.refresh(incidencia)



    accion = Accion(

        incidencia_id=incidencia.id,

        usuario="Sistema",

        accion="Atención iniciada",

        descripcion=
        "Se inició la atención de la incidencia."

    )


    db.add(accion)

    db.commit()



    asyncio.run(
        manager.broadcast(
            {
                "tipo":"incidencia",

                "evento":"iniciada",

                "incidencia_id":
                    incidencia.id,

                "mensaje":
                    "La incidencia inició atención."
            }
        )
    )



    return {

        "mensaje":
        "Atención iniciada",

        "estado":
        incidencia.estado

    }






# Finalizar atención


@router.post("/{incidencia_id}/finalizar")
def finalizar_atencion(
    incidencia_id: int,
    db: Session = Depends(get_db)
):


    incidencia = (
        db.query(Incidencia)
        .filter(
            Incidencia.id == incidencia_id
        )
        .first()
    )



    if incidencia is None:

        raise HTTPException(
            status_code=404,
            detail="Incidencia no encontrada"
        )



    if incidencia.estado == "RESUELTA":

        raise HTTPException(
            status_code=400,
            detail="La incidencia ya fue finalizada."
        )



    if incidencia.fecha_inicio is None:

        raise HTTPException(
            status_code=400,
            detail=
            "La incidencia aún no ha sido iniciada."
        )



    incidencia.estado = "RESUELTA"

    incidencia.fecha_fin = datetime.utcnow()



    tiempo = (
        incidencia.fecha_fin
        -
        incidencia.fecha_inicio
    )



    incidencia.tiempo_real_minutos = int(
        tiempo.total_seconds() / 60
    )



    db.commit()

    db.refresh(incidencia)



    accion = Accion(

        incidencia_id=incidencia.id,

        usuario="Sistema",

        accion="Atención finalizada",

        descripcion=
        f"Tiempo total: {incidencia.tiempo_real_minutos} minutos."

    )


    db.add(accion)

    db.commit()




    asyncio.run(
        manager.broadcast(
            {
                "tipo":"incidencia",

                "evento":"finalizada",

                "incidencia_id":
                    incidencia.id,

                "tiempo_real_minutos":
                    incidencia.tiempo_real_minutos,

                "mensaje":
                    "La incidencia fue resuelta."
            }
        )
    )



    return {

        "mensaje":
        "Incidencia finalizada",

        "estado":
        incidencia.estado,

        "tiempo_real_minutos":
        incidencia.tiempo_real_minutos

    }