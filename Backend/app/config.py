import os
from dotenv import load_dotenv

# Cargar variables desde el archivo .env
load_dotenv()

# ==========================
# Base de datos
# ==========================
DATABASE_URL = os.getenv("DATABASE_URL")

# ==========================
# MQTT
# ==========================
MQTT_HOST = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))
MQTT_USER = os.getenv("MQTT_USER", "")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD", "")
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "agua/lecturas")