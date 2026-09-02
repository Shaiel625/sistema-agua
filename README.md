# Sistema Inteligente de Agua (proyecto unificado)

Este proyecto combina:
- **Backend** (`Backend/`): tomado de la rama `main`, es la versión más completa
  (edificios, tinacos, dispositivos, lecturas, dashboard, **incidencias, acciones
  y materiales**, WebSocket en tiempo real, conexión a MQTT en la nube).
- **App móvil Flutter** (`lib/`): tomada de la rama `feature/cambios-gali`, es la
  versión más completa de pantallas (Panel de control, Dispositivos, Objetivos,
  Análisis, Nodos) — estas pantallas ya estaban programadas para consumir
  exactamente los endpoints de incidencias/acciones/materiales del backend de
  `main`, así que esta combinación es la que realmente encaja.

No se perdió ninguna función de ninguna de las dos ramas.

## Qué se ajustó al combinar
- Se agregó CORS al backend para que la app (sobre todo en modo Web) pueda
  llamarlo sin bloqueos.
- Se eliminó un archivo `lib/analisis_screen.zip` que era una copia de
  respaldo accidental (no se usaba en el código, Flutter no lo compila).
- Se creó `Backend/.env.example` con las variables que hacen falta.
- Se unificó `docker-compose.yml` para poder levantar todo en local
  (Postgres + Mosquitto + backend) sin depender de servicios en la nube
  mientras desarrollas.

## Pendiente que no estaba conectado en ninguna rama
`lib/websocket_service.dart` (recibe alertas del ESP32 en tiempo real y
muestra notificaciones push) está escrito pero **no se llama desde
ninguna pantalla todavía**. Si quieres que las notificaciones push
funcionen, dímelo y lo conecto en `main.dart`.

---

## 1. Crear las cuentas necesarias (gratis)

Necesitas 3 servicios en la nube:

1. **Base de datos — Neon (Postgres gratis)**
   - Crea cuenta en https://neon.tech
   - Crea un proyecto → copia el "Connection string" (se ve como
     `postgresql://usuario:password@host/db?sslmode=require`)

2. **Broker MQTT — HiveMQ Cloud (gratis, plan "Serverless")**
   - Crea cuenta en https://console.hivemq.cloud
   - Crea un cluster gratuito → en "Access Management" crea un usuario y
     contraseña para el ESP32 y el backend
   - Copia el "Host" (termina en `.hivemq.cloud`), el puerto TLS es `8883`

3. **Hosting del backend — Render (gratis, plan Free Web Service)**
   - Crea cuenta en https://render.com

## 2. Configurar el backend

```bash
cd Backend
cp .env.example .env
```
Edita `.env` y pon:
```
DATABASE_URL=<tu connection string de Neon>
MQTT_HOST=<tu host de HiveMQ>
MQTT_PORT=8883
MQTT_USER=<usuario que creaste en HiveMQ>
MQTT_PASSWORD=<password de ese usuario>
MQTT_TOPIC=agua/lecturas
```

### Probar en local (opcional, recomendado antes de desplegar)
```bash
docker compose up --build
```
Esto levanta un Postgres y un MQTT locales además del backend en
`http://localhost:8000`. (Si prefieres, puedes apuntar directo a Neon/HiveMQ
Cloud en el `.env` incluso en local y quitar los servicios `db`/`mqtt` del
`docker-compose.yml`.)

## 3. Desplegar el backend en Render

1. Sube este proyecto a un repositorio de GitHub tuyo.
2. En Render → "New +" → "Web Service" → conecta el repo.
3. Root Directory: `Backend`
4. Environment: **Docker** (usará el `Backend/Dockerfile` tal cual).
5. En "Environment Variables" agrega las mismas 6 variables del `.env`
   (DATABASE_URL, MQTT_HOST, MQTT_PORT, MQTT_USER, MQTT_PASSWORD, MQTT_TOPIC).
6. Deploy. Render te dará una URL tipo `https://sistema-xxxx.onrender.com`
   — **esa es la URL de tu backend**.

> Nota: el código ya traía escrita la URL `https://sistema-pchh.onrender.com`
> en `lib/api_service.dart`. Puede ser un servicio previo del equipo que ya
> no tenga las credenciales configuradas. Si no tienes acceso a ese servicio
> en tu cuenta de Render, despliega uno nuevo siguiendo estos pasos y
> reemplaza esa URL por la tuya (ver paso 4).

## 4. Conectar la app Flutter a tu backend

Edita `lib/api_service.dart`:
```dart
static const String baseUrl = 'https://TU-BACKEND.onrender.com';
```

## 5. ¿Cómo se conecta el ESP32?

El ESP32 **no habla con la URL de Render directamente**: se conecta al
**broker MQTT** (HiveMQ Cloud), y es el backend el que escucha ese broker
y guarda los datos.

Datos de conexión para el firmware del ESP32:
- **Host MQTT**: el mismo `MQTT_HOST` que pusiste en `Backend/.env`
  (ej. `xxxxx.s1.eu.hivemq.cloud`)
- **Puerto**: `8883` (TLS/SSL — HiveMQ Cloud lo exige)
- **Usuario / contraseña**: el mismo `MQTT_USER` / `MQTT_PASSWORD` del `.env`
  (puedes crear un usuario distinto solo para el ESP32 en HiveMQ si prefieres)
- **Topic al que debe PUBLICAR**: `agua/lecturas` (o el valor que pongas en
  `MQTT_TOPIC`)
- **Formato del mensaje (JSON)**:
```json
{
  "esp32_id": "ESP32-001",
  "porcentaje": 78,
  "litros": 450
}
```
  - `esp32_id` debe coincidir con el que registres en la app (pantalla
    "Nodos" / "Dispositivos").
  - El backend automáticamente crea una incidencia cuando `porcentaje <= 20`.

## 6. Generar el APK (instalación directa, sin Play Store)

Esto se hace en tu computadora (necesitas tener Flutter instalado:
https://docs.flutter.dev/get-started/install). Este entorno de Claude no
tiene el SDK de Flutter disponible para compilarlo por ti.

```bash
flutter pub get
flutter build apk --release
```
El archivo queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```
Cópialo a tu celular Android (por USB, Drive, WhatsApp, etc.) y ábrelo para
instalarlo. Puede que Android pida activar "Instalar apps de orígenes
desconocidos" la primera vez.

Si no tienes Flutter instalado localmente y no quieres instalarlo, puedes
compilar el APK gratis en la nube con **Codemagic** (https://codemagic.io)
o **GitHub Actions** (workflow de `flutter build apk`) conectando tu
repositorio — puedo darte ese workflow si lo prefieres.
