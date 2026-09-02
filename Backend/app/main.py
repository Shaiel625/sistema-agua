from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import Base
from .database import engine
import logging
from . import models
from .routes import edificios
from .routes import tinacos
from .routes import lecturas
from .routes import dispositivos
from .routes import websocket
from .routes import dashboard

from .routes import incidencias
from .routes import acciones
from .routes import materiales

from .mqtt_client import start_mqtt

app = FastAPI()

# Permite que la app Flutter (móvil, web y escritorio) consuma la API
# sin bloqueos de CORS. Se puede restringir a dominios específicos
# más adelante si se desea mayor seguridad.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

@app.on_event("startup")
def startup_event():
    print("===== INICIO DE FASTAPI =====")
    start_mqtt()

app.include_router(edificios.router)
app.include_router(tinacos.router)
app.include_router(lecturas.router)
app.include_router(dispositivos.router)
app.include_router( websocket.router)
app.include_router( dashboard.router)

app.include_router(incidencias.router)
app.include_router(acciones.router)
app.include_router(materiales.router)

@app.get("/")
def home():

    return {
        "mensaje": "Sistema Inteligente de Agua"
    }
   