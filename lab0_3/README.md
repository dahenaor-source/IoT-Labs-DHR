# Lab 0.3 — Implementación MQTT con ESP32-C6

Guía para ejecutar el laboratorio desde **WSL**, usando **Mosquitto en
Windows**. La ESP32 publica `iot/sensor` y recibe órdenes en `iot/control`.

```text
ESP32 -- iot/sensor --> Mosquitto <-- iot/control -- WSL/dashboard
```

## 0. Datos necesarios

Necesitas:

- Windows con Mosquitto instalado como servicio.
- Ubuntu/WSL con Zephyr instalado en `~/zephyrproject`.
- ESP32-C6 conectada por USB.
- SSID y contraseña de tu Wi-Fi.

No guardes IP, SSID ni contraseña en GitHub. En esta guía:

- `<IP_WINDOWS_WIFI>` es la IPv4 Wi-Fi de Windows.
- `<BUSID>` es el identificador USB de la ESP32.

La IP del broker es la de **Windows**, no la de la ESP32, `localhost` ni
`vEthernet (WSL)`.

---

## 1. Windows: preparar Mosquitto

Ejecuta estos comandos en **PowerShell como administrador**.

### 1.1 Configuración y servicio

El archivo `C:\Program Files\mosquitto\mosquitto.conf` debe contener:

```text
listener 1883
allow_anonymous true
```

Comprueba el servicio:

```powershell
Get-Service mosquitto
```

Si aparece detenido:

```powershell
net start mosquitto
```

Debe quedar en estado `Running`.

### 1.2 Firewall

Ejecuta esto una sola vez:

```powershell
New-NetFirewallRule `
  -DisplayName "Mosquitto MQTT 1883" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 1883 `
  -Action Allow
```

Si la regla ya existe, continúa.

### 1.3 Obtener la IP del broker

```powershell
ipconfig
```

Anota la IPv4 de **Adaptador de LAN inalámbrica Wi-Fi**. La usarás en WSL
como `<IP_WINDOWS_WIFI>`.

### 1.4 Conectar la ESP32 a WSL

```powershell
usbipd list
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

`bind` puede indicar que el dispositivo ya estaba compartido. Eso no es un
error.

---

## 2. WSL: preparar variables y herramientas

Ejecuta en Ubuntu/WSL:

```bash
export IOT_LABS="$HOME/IoT-Labs-DHR"
export ZEPHYR="$HOME/zephyrproject"
export BROKER_IP="<IP_WINDOWS_WIFI>"
```

Comprueba el proyecto y el USB:

```bash
test -f "$IOT_LABS/lab0_3/firmware/lab0_mqtt/src/main.c" \
  && echo "Firmware OK"
test -f "$IOT_LABS/lab0_3/tools/dashboard_mqtt.py" \
  && echo "Dashboard OK"
ls /dev/ttyACM*
```

Debe aparecer un puerto como `/dev/ttyACM0`. Si no aparece, repite
`usbipd attach` en PowerShell.

Activa Zephyr e instala los clientes MQTT:

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west --version
sudo apt update
sudo apt install -y mosquitto-clients netcat-openbsd
```

No ejecutes otro broker Mosquitto dentro de WSL.

---

## 3. WSL: probar la conexión MQTT

Primero verifica que WSL alcanza Windows:

```bash
nc -vz "$BROKER_IP" 1883
```

Debe mostrar `succeeded`.

Abre dos terminales WSL. Define `BROKER_IP` en cada una.

**Terminal 1 — suscriptor:**

```bash
export BROKER_IP="<IP_WINDOWS_WIFI>"
mosquitto_sub -h "$BROKER_IP" -p 1883 -t test/hello -v
```

**Terminal 2 — publicador:**

```bash
export BROKER_IP="<IP_WINDOWS_WIFI>"
mosquitto_pub -h "$BROKER_IP" -p 1883 \
  -t test/hello -m "Hello from WSL"
```

La Terminal 1 debe mostrar:

```text
test/hello Hello from WSL
```

No continúes hasta que esta prueba funcione.

---

## 4. Compilar el firmware

En WSL, desde una terminal con las variables definidas:

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west build -p always \
  -b esp32c6_devkitc/esp32c6/hpcore \
  "$IOT_LABS/lab0_3/firmware/lab0_mqtt" \
  -d "$ZEPHYR/build/lab0_mqtt" \
  -- \
  -DCONFIG_LAB_WIFI_SSID='"TU_SSID_WIFI"' \
  -DCONFIG_LAB_WIFI_PSK='"TU_CONTRASEÑA_WIFI"' \
  -DCONFIG_LAB_BROKER_ADDR="\"$BROKER_IP\"" \
  -DCONFIG_LAB_BROKER_PORT=1883
```

Sustituye el SSID y la contraseña solo en la terminal. No los guardes en
archivos versionados.

Comprueba el resultado:

```bash
test -f "$ZEPHYR/build/lab0_mqtt/zephyr/zephyr.bin" \
  && echo "Firmware compilado correctamente"
```

---

## 5. Flashear y monitorizar la ESP32

### 5.1 Flashear — WSL

Cierra otros monitores seriales y ejecuta:

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west flash \
  -d "$ZEPHYR/build/lab0_mqtt" \
  --runner esp32 \
  --esp-device /dev/ttyACM0
```

Si tu puerto es diferente, reemplaza `/dev/ttyACM0`.

### 5.2 Monitor — WSL

En otra terminal:

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west espressif monitor -p /dev/ttyACM0
```

Presiona `EN/RESET`. Debes ver:

```text
Connected to broker
Subscribed to iot/control
```

También debe aparecer la IP de la ESP32 y el broker en el log. Si aparece
`mqtt_connect failed (-116)`, revisa primero la prueba de la sección 3.

---

## 6. Verificar telemetría, control y PUBACK

Deja abierto el monitor serial.

### 6.1 Task 5: telemetría

En otra terminal WSL:

```bash
export BROKER_IP="<IP_WINDOWS_WIFI>"
mosquitto_sub -h "$BROKER_IP" -p 1883 -t iot/sensor -v
```

Debe llegar un mensaje aproximadamente cada dos segundos:

```text
iot/sensor {"temperature":24.7}
```

### 6.2 Tasks 3 y 4: LED, JSON y PUBACK

Encender:

```bash
mosquitto_pub -h "$BROKER_IP" -p 1883 \
  -t iot/control -q 1 -m '{"state":1}'
```

Apagar:

```bash
mosquitto_pub -h "$BROKER_IP" -p 1883 \
  -t iot/control -q 1 -m '{"state":0}'
```

El LED debe responder. El monitor debe mostrar el comando recibido y
`PUBACK sent`. Esto verifica el parseo JSON, el control WS2812 y la respuesta
QoS 1.

---

## 7. Ejecutar el dashboard MQTT

En WSL:

```bash
cd "$IOT_LABS"
python3 -m venv .venv-dashboard
.venv-dashboard/bin/python -m pip install flask paho-mqtt
```

Si el entorno ya existe, el comando puede omitirse.

Inicia el dashboard:

```bash
export BROKER_IP="<IP_WINDOWS_WIFI>"
cd "$IOT_LABS"
MQTT_BROKER="$BROKER_IP" \
  .venv-dashboard/bin/python lab0_3/tools/dashboard_mqtt.py
```

Abre en el navegador de Windows:

```text
http://localhost:5000
```

El dashboard debe mostrar la temperatura y permitir encender y apagar el LED.

---

## Resultado esperado

- Mosquitto está `Running` en Windows.
- `nc` y `mosquitto_pub/sub` funcionan desde WSL.
- La ESP32 muestra `Connected to broker`.
- Llegan mensajes por `iot/sensor`.
- El LED responde a `state:1` y `state:0`.
- El monitor muestra `PUBACK sent`.
- El dashboard recibe temperatura y controla el LED.

## Problemas frecuentes

| Mensaje | Solución |
| --- | --- |
| No existe `/dev/ttyACM0` | Ejecuta `usbipd attach --wsl --busid <BUSID>` en PowerShell. |
| `Connection refused` | Comprueba Mosquitto, firewall y el puerto `1883` en Windows. |
| `mqtt_connect failed (-116)` | La ESP32 tiene Wi-Fi, pero no alcanza `BROKER_IP`. Repite la prueba MQTT. |
| `mosquitto_sub` no muestra texto | Déjalo abierto y publica desde otra terminal. |
| Pip bloqueado por entorno gestionado | Usa `.venv-dashboard/bin/python -m pip`. |

---

## Discusión: HTTP vs MQTT

Esta comparación se basa en lo implementado en `lab0_2` (HTTP) y `lab0_3`
(MQTT).

### 1. Dirección del flujo de datos

En HTTP, el dashboard inicia todo. Hace `GET /api/sensor` a la IP de la
ESP32 y la placa responde con la temperatura. Para controlar el LED, el
dashboard hace `POST /api/control`.

En MQTT, la ESP32 publica la temperatura cada dos segundos en `iot/sensor`.
El dashboard se suscribe a ese topic. Para controlar el LED, publica en
`iot/control`.

Para telemetría MQTT es más natural: el sensor publica cuando tiene un dato,
sin que el dashboard tenga que estar preguntando todo el tiempo.

### 2. Acoplamiento

En HTTP, el dashboard necesita conocer la IP de la ESP32 y conectarse
directamente a su servidor HTTP.

En MQTT, la ESP32 y el dashboard solo necesitan conocer la dirección del
broker. No necesitan conocerse directamente.

Si agregamos otra ESP32, en HTTP habría que guardar y consultar otra IP. En
MQTT la nueva placa puede usar topics separados, por ejemplo:

```text
iot/node1/sensor
iot/node2/sensor
```

El dashboard puede suscribirse a varios nodos sin conectarse directamente a
cada dirección IP.

### 3. Escalabilidad

Con 100 nodos HTTP, el dashboard tendría que conocer 100 IP, hacer peticiones
periódicas a todas las placas y controlar 100 posibles errores o timeouts.

Con MQTT, las placas mantienen su conexión con el broker y el dashboard puede
usar una sola conexión MQTT para recibir los datos. Por eso MQTT escala mejor
para muchos sensores.

### 4. Fiabilidad

En HTTP, si el dashboard está apagado durante 30 segundos, no hace peticiones
y pierde las lecturas de ese periodo. Cuando vuelve, solo obtiene el dato
actual.

En este laboratorio MQTT, `iot/sensor` usa QoS 0. Si el dashboard se desconecta,
las lecturas publicadas durante ese tiempo se pierden. Cuando vuelve, recibe
las nuevas.

Para mejorar esto se puede usar QoS 1, sesiones persistentes y mensajes
retained. Un mensaje retained sirve para conservar el último estado, por
ejemplo el estado del LED, pero no guarda todo el historial de temperaturas.
Para eso haría falta almacenar los datos en una base de datos.

En `iot/control` usamos QoS 1 y la ESP32 responde con `PUBACK`, por lo que el
comando tiene una entrega más confiable que una publicación QoS 0.

### 5. Overhead

En HTTP, una lectura implica una petición `GET`, headers HTTP, una respuesta y
el JSON. Si la conexión se abre y cierra repetidamente, se añade más tráfico
TCP.

En MQTT, la conexión TCP queda abierta y cada lectura es un `PUBLISH` pequeño
con el topic `iot/sensor` y el JSON.

Para medirlo con Wireshark:

- HTTP: usar `tcp.port == 80` o el filtro `http`.
- MQTT: usar `tcp.port == 1883` o el filtro `mqtt`.

La comparación debe hacerse con una lectura de cada laboratorio. En general,
MQTT tiene menos overhead por mensaje porque no repite una petición HTTP
completa para cada dato.

### 6. Seguridad

Los dos laboratorios funcionan sin cifrado:

- HTTP usa HTTP normal en el puerto 80.
- MQTT usa MQTT sin TLS en el puerto 1883.

Para HTTP habría que usar HTTPS/TLS, normalmente en el puerto 443, instalar y
validar certificados y añadir autenticación para proteger el control del LED.

Para MQTT habría que usar MQTTS/TLS, normalmente en el puerto 8883, configurar
el certificado del broker y validarlo desde la ESP32. También conviene usar
usuarios, contraseñas o certificados de cliente, además de permisos por topic.

En ambos casos no basta con cifrar: también hay que controlar quién puede
leer datos y quién puede enviar órdenes.
