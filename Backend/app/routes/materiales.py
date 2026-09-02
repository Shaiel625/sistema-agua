from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import (
    Material,
    IncidenciaMaterial,
    Incidencia,
    Accion
)

from ..schemas import (
    MaterialCreate,
    MaterialResponse,
    IncidenciaMaterialCreate
)

router = APIRouter(
    prefix="/materiales",
    tags=["Materiales"]
)
# Rutas CRUD para Material
@router.get("/", response_model=list[MaterialResponse])
def obtener_materiales(
    db: Session = Depends(get_db)
):

    return db.query(Material).all()
# Obtener por ID
@router.get("/{material_id}", response_model=MaterialResponse)
def obtener_material(
    material_id: int,
    db: Session = Depends(get_db)
):

    material = (
        db.query(Material)
        .filter(Material.id == material_id)
        .first()
    )

    if material is None:

        raise HTTPException(
            status_code=404,
            detail="Material no encontrado"
        )

    return material
# Crear
@router.post(
    "/",
    response_model=MaterialResponse,
    status_code=status.HTTP_201_CREATED
)
def crear_material(
    datos: MaterialCreate,
    db: Session = Depends(get_db)
):

    material = Material(**datos.model_dump())

    db.add(material)

    db.commit()

    db.refresh(material)

    return material

# Actualizar
@router.put("/{material_id}", response_model=MaterialResponse)
def actualizar_material(
    material_id: int,
    datos: MaterialCreate,
    db: Session = Depends(get_db)
):

    material = (
        db.query(Material)
        .filter(Material.id == material_id)
        .first()
    )

    if material is None:

        raise HTTPException(
            status_code=404,
            detail="Material no encontrado"
        )

    for campo, valor in datos.model_dump().items():
        setattr(material, campo, valor)

    db.commit()

    db.refresh(material)

    return material
# Eliminar
@router.delete("/{material_id}")
def eliminar_material(
    material_id: int,
    db: Session = Depends(get_db)
):

    material = (
        db.query(Material)
        .filter(Material.id == material_id)
        .first()
    )

    if material is None:

        raise HTTPException(
            status_code=404,
            detail="Material no encontrado"
        )

    db.delete(material)

    db.commit()

    return {
        "mensaje":"Material eliminado correctamente"
    }


# Rutas para IncidenciaMaterial
@router.post("/asignar")
def asignar_material(
    datos: IncidenciaMaterialCreate,
    db: Session = Depends(get_db)
):

    incidencia = (
        db.query(Incidencia)
        .filter(
            Incidencia.id == datos.incidencia_id
        )
        .first()
    )

    if incidencia is None:

        raise HTTPException(
            status_code=404,
            detail="Incidencia no encontrada"
        )

    material = (
        db.query(Material)
        .filter(
            Material.id == datos.material_id
        )
        .first()
    )

    if material is None:

        raise HTTPException(
            status_code=404,
            detail="Material no encontrado"
        )

    if material.stock < datos.cantidad:

        raise HTTPException(
            status_code=400,
            detail="Stock insuficiente"
        )

    asignacion = IncidenciaMaterial(
        incidencia_id=datos.incidencia_id,
        material_id=datos.material_id,
        cantidad=datos.cantidad
    )

    material.stock -= datos.cantidad

    db.add(asignacion)

    db.commit()

    db.refresh(asignacion)

    accion = Accion(
        incidencia_id=datos.incidencia_id,
        usuario="Sistema",
        accion="Material asignado",
        descripcion=f"Se asignaron {datos.cantidad} unidad(es) del material '{material.nombre}'."
    )

    db.add(accion)

    db.commit()

    return {
        "mensaje":"Material asignado correctamente"
    }

