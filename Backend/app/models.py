from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from sqlalchemy import Text

from .database import Base


class Edificio(Base):

    __tablename__ = "edificios"

    id = Column(Integer, primary_key=True)
    nombre = Column(String(100), nullable=False)

    tinacos = relationship("Tinaco", back_populates="edificio")


class Dispositivo(Base):

    __tablename__ = "dispositivos"

    id = Column(Integer, primary_key=True)

    esp32_id = Column(String(100), unique=True)

    estado = Column(String(50), default="activo")


class Tinaco(Base):

    __tablename__ = "tinacos"

    id = Column(Integer, primary_key=True)

    nombre = Column(String(100))

    capacidad_litros = Column(Integer)

    altura_cm = Column(Float)

    edificio_id = Column(Integer, ForeignKey("edificios.id"))

    dispositivo_id = Column(Integer, ForeignKey("dispositivos.id"))

    edificio = relationship("Edificio", back_populates="tinacos")

    lecturas = relationship("Lectura", back_populates="tinaco")
    incidencias = relationship("Incidencia", back_populates="tinaco")

class Lectura(Base):

    __tablename__ = "lecturas"

    id = Column(Integer, primary_key=True)

    tinaco_id = Column(Integer, ForeignKey("tinacos.id"))

    porcentaje = Column(Float)

    litros = Column(Float)

    fecha = Column(DateTime, default=datetime.utcnow)

    tinaco = relationship("Tinaco", back_populates="lecturas")

class Incidencia(Base):

    __tablename__ = "incidencias"

    id = Column(Integer, primary_key=True)

    tinaco_id = Column(Integer, ForeignKey("tinacos.id"), nullable=False)

    tipo = Column(String(100), nullable=False)

    descripcion = Column(Text)

    estado = Column(String(20), default="ABIERTA")

    prioridad = Column(String(20), default="MEDIA")

    tiempo_estimado_minutos = Column(Integer)

    fecha_creacion = Column(DateTime, default=datetime.utcnow)

    fecha_inicio = Column(DateTime, nullable=True)

    fecha_fin = Column(DateTime, nullable=True)
    tiempo_real_minutos = Column(Integer, nullable=True)

    tinaco = relationship("Tinaco", back_populates="incidencias")
    

class Material(Base):

    __tablename__ = "materiales"

    id = Column(Integer, primary_key=True)

    nombre = Column(String(100), nullable=False)

    descripcion = Column(Text)

    stock = Column(Integer, default=0)

class IncidenciaMaterial(Base):

    __tablename__ = "incidencia_material"

    id = Column(Integer, primary_key=True)

    incidencia_id = Column(Integer, ForeignKey("incidencias.id"))

    material_id = Column(Integer, ForeignKey("materiales.id"))

    cantidad = Column(Integer, default=1)

    incidencia = relationship("Incidencia")

    material = relationship("Material")

class Accion(Base):

    __tablename__ = "acciones"

    id = Column(Integer, primary_key=True)

    incidencia_id = Column(Integer, ForeignKey("incidencias.id"))

    usuario = Column(String(100))

    accion = Column(String(100))

    descripcion = Column(Text)

    fecha = Column(DateTime, default=datetime.utcnow)

    incidencia = relationship("Incidencia")