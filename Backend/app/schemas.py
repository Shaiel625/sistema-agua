from pydantic import BaseModel
from datetime import datetime

from typing import Optional

class EdificioCreate(BaseModel):
    nombre: str


class EdificioResponse(EdificioCreate):
    id: int

    class Config:
        from_attributes = True

class TinacoBase(BaseModel):

    nombre: str

    capacidad_litros: int

class TinacoCreate(TinacoBase):
    nombre: str
    capacidad_litros: int
    altura_cm: float
    edificio_id: int

class TinacoResponse(TinacoBase):

    id: int

    class Config:
        from_attributes = True

class LecturaCreate(BaseModel):
    tinaco_id: int
    porcentaje: float
    litros: float


class LecturaResponse(LecturaCreate):
    id: int

    class Config:
        from_attributes = True   

class LecturaDetalle(BaseModel):
    id: int
    tinaco_id: int
    porcentaje: float
    litros: float
    fecha: datetime

    class Config:
        from_attributes = True             

class DispositivoCreate(BaseModel):
    esp32_id: str
    estado: str = "activo"


class DispositivoResponse(DispositivoCreate):
    id: int

    class Config:
        from_attributes = True        


class DashboardItem(BaseModel):
    tinaco_id: int
    nombre: str
    capacidad_litros: int
    porcentaje: float
    litros: float

    class Config:
        from_attributes = True  

class IncidenciaCreate(BaseModel):

    tinaco_id: int

    tipo: str

    descripcion: Optional[str] = None

    prioridad: str = "MEDIA"

    tiempo_estimado_minutos: Optional[int] = None

class IncidenciaResponse(BaseModel):

    id: int

    tinaco_id: int

    tipo: str

    descripcion: Optional[str]

    estado: str

    prioridad: str

    tiempo_estimado_minutos: Optional[int]

    fecha_creacion: datetime

    fecha_inicio: Optional[datetime]

    fecha_fin: Optional[datetime]
    tiempo_real_minutos: Optional[int]

    class Config:
        from_attributes = True

class MaterialCreate(BaseModel):

    nombre: str

    descripcion: Optional[str] = None

    stock: int

class MaterialResponse(MaterialCreate):

    id: int

    class Config:
        from_attributes = True
class IncidenciaMaterialCreate(BaseModel):

    incidencia_id: int

    material_id: int

    cantidad: int

class IncidenciaMaterialResponse(IncidenciaMaterialCreate):

    id: int

    class Config:
        from_attributes = True

class AccionCreate(BaseModel):

    incidencia_id: int

    usuario: str

    accion: str

    descripcion: Optional[str] = None

class AccionResponse(AccionCreate):

    id: int

    fecha: datetime

    class Config:
        from_attributes = True       

class MaterialCreate(BaseModel):

    nombre: str

    descripcion: Optional[str] = None

    stock: int


class MaterialResponse(MaterialCreate):

    id: int

    class Config:
        from_attributes = True


class IncidenciaMaterialCreate(BaseModel):

    incidencia_id: int

    material_id: int

    cantidad: int


class IncidenciaMaterialResponse(IncidenciaMaterialCreate):

    id: int

    class Config:
        from_attributes = True                                                       