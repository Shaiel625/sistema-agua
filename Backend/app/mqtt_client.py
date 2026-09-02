import json
import logging
import asyncio

import paho.mqtt.client as mqtt
import certifi
import ssl

from .database import SessionLocal

from .models import (
    Lectura,
    Tinaco,
    Dispositivo,
    Incidencia,
    Accion
)

from .websocket_manager import manager
from .config import (
    MQTT_HOST,
    MQTT_PORT,
    MQTT_USER,
    MQTT_PASSWORD,
    MQTT_TOPIC
)

logging.basicConfig(level=logging.INFO)



# =====================================
# MQTT CONNECT
# =====================================

def on_connect(client, userdata, flags, rc):

    logging.info("MQTT conectado")
    logging.info(f"RC: {rc}")
    if rc == 0:
        logging.info("Conexión exitosa a HiveMQ Cloud")
        client.subscribe(MQTT_TOPIC)
    else:
        logging.error(f"Error al conectar. Código: {rc}")

   # client.subscribe(
    #    "agua/lecturas"
    #)
    client.subscribe(MQTT_TOPIC)



# =====================================
# MQTT MESSAGE
# =====================================

def on_message(client, userdata, msg):

    db = None

    try:

        payload = json.loads(
            msg.payload.decode()
        )


        logging.info(
            f"DATA: {payload}"
        )


        db = SessionLocal()



        # Buscar dispositivo

        dispositivo = (
            db.query(Dispositivo)
            .filter(
                Dispositivo.esp32_id ==
                payload["esp32_id"]
            )
            .first()
        )


        if not dispositivo:

            raise Exception(
                "Dispositivo no encontrado"
            )



        # Buscar tinaco asociado

        tinaco = (
            db.query(Tinaco)
            .filter(
                Tinaco.dispositivo_id ==
                dispositivo.id
            )
            .first()
        )


        if not tinaco:

            raise Exception(
                "Tinaco no asociado"
            )



        # =====================================
        # Guardar lectura
        # =====================================

        lectura = Lectura(

            tinaco_id=tinaco.id,

            porcentaje=payload["porcentaje"],

            litros=payload["litros"]

        )


        db.add(lectura)

        db.commit()

        db.refresh(lectura)



        logging.info(
            "Lectura guardada correctamente"
        )



        # =====================================
        # Crear incidencia automática
        # =====================================

        if payload["porcentaje"] <= 20:


            incidencia_existente = (

                db.query(Incidencia)

                .filter(

                    Incidencia.tinaco_id == tinaco.id,

                    Incidencia.estado.in_(
                        [
                            "ABIERTA",
                            "EN_PROCESO"
                        ]
                    )

                )

                .first()

            )



            if incidencia_existente is None:


                incidencia = Incidencia(

                    tinaco_id=tinaco.id,

                    tipo="Nivel bajo de agua",

                    descripcion=(

                        f"El tinaco '{tinaco.nombre}' "

                        f"registró un nivel de "

                        f"{payload['porcentaje']}%."

                    ),

                    estado="ABIERTA"

                )


                db.add(incidencia)

                db.commit()

                db.refresh(incidencia)



                accion = Accion(

                    incidencia_id=incidencia.id,

                    usuario="Sistema",

                    accion="Incidencia automática",

                    descripcion=(

                        "Creada automáticamente "

                        "por nivel crítico."

                    )

                )


                db.add(accion)

                db.commit()



                logging.info(
                    "Incidencia creada automáticamente."
                )



                # Notificación incidencia

                asyncio.run(

                    manager.broadcast(

                        {

                            "tipo":
                            "incidencia",


                            "evento":
                            "creada",


                            "incidencia_id":
                            incidencia.id,


                            "tinaco_id":
                            tinaco.id,


                            "mensaje":
                            (
                                f"Nivel crítico en "
                                f"{tinaco.nombre}"
                            )

                        }

                    )

                )



        # =====================================
        # Notificación lectura tiempo real
        # =====================================


        asyncio.run(

            manager.broadcast(

                {

                    "tipo":
                    "lectura",


                    "tinaco_id":
                    tinaco.id,


                    "porcentaje":
                    payload["porcentaje"],


                    "litros":
                    payload["litros"]

                }

            )

        )



    except Exception as e:


        logging.error(

            f"Error MQTT: {e}"

        )



    finally:


        if db:

            db.close()




# =====================================
# MQTT CLIENT
# =====================================

#client = mqtt.Client()
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION1)

client.on_connect = on_connect

client.on_message = on_message




# =====================================
# START MQTT
# =====================================

def start_mqtt():

    logging.info("Intentando conectar MQTT...")

    try:

        if MQTT_USER and MQTT_PASSWORD:
            client.username_pw_set(
                MQTT_USER,
                MQTT_PASSWORD
            )
        client.tls_set(

         ca_certs=certifi.where(),
         tls_version=ssl.PROTOCOL_TLS_CLIENT
        )
        client.connect(
            MQTT_HOST,
            MQTT_PORT,
            60
        )

        client.loop_start()

        logging.info("MQTT iniciado correctamente.")

    except Exception as e:

        logging.warning(
            f"No fue posible conectar con MQTT: {e}"
        )

        logging.warning(
            "El backend continuará funcionando sin MQTT."
        )