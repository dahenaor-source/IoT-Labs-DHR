# Lab 0.3 — Implementación IoT mínima con MQTT

Este taller reemplaza HTTP por MQTT. La ESP32-C6 y el dashboard Python ya no
se conectan directamente: ambos son clientes MQTT y se comunican a través de
Mosquitto, el broker.

## 1. Arquitectura y diferencia con Lab 0.2

| Función | Lab 0.2 HTTP | Lab 0.3 MQTT |
| --- | --- | --- |
| Telemetría | Dashboard hace `GET` cada 1.5 s | ESP32 publica cada 2 s |
| Control LED | Dashboard hace `POST` a la IP de ESP32 | Dashboard publica al broker |
| Dirección configurada | Dashboard necesita IP de la ESP32 | Firmware necesita IP del broker |
| Rol de la ESP32 | Servidor HTTP | Cliente MQTT |
| Rol del dashboard | Cliente HTTP | Cliente MQTT |
| Intermediario | Ninguno | Mosquitto |

Se usan estos topics:

```text
iot/sensor   ESP32 -> broker -> dashboard
iot/control  dashboard -> broker -> ESP32
```

La telemetría usa QoS 0 porque una lectura nueva reemplaza a la anterior. Los
comandos usan QoS 1 porque el firmware debe enviar `PUBACK` después de
procesarlos.

## 2. Requisitos

- ESP32-C6-DevKitC conectada por USB.
- Zephyr en `~/zephyrproject`.
- Target `esp32c6_devkitc/esp32c6/hpcore`.
- Python 3 con `venv`.
- Mosquitto y sus clientes.
- PC y ESP32 en la misma red Wi-Fi de 2.4 GHz.

Define rutas comunes:

```bash
export IOT_LABS="$HOME/IoT-Labs-DHR"
export ZEPHYR="$HOME/zephyrproject"
cd "$ZEPHYR"
source .venv/bin/activate
```

## 3. Instalar y configurar Mosquitto en Windows

La guía original instala Mosquitto en el equipo de trabajo, no dentro de
WSL2. Descarga el instalador Win64 desde
[mosquitto.org/download](https://mosquitto.org/download/) y selecciona la
opción para instalarlo como servicio.

Configura el broker para aceptar conexiones de la red local. Abre
`C:\Program Files\mosquitto\mosquitto.conf` como administrador y añade:

```text
listener 1883
allow_anonymous true
```

Reinicia el servicio desde PowerShell como administrador:

```powershell
net stop mosquitto
net start mosquitto
```

Prueba el broker en dos ventanas de Command Prompt de Windows:

Ventana A:

```powershell
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h localhost -t test/hello
```

Ventana B:

```powershell
& "C:\Program Files\mosquitto\mosquitto_pub.exe" -h localhost -t test/hello -m "Hello from MQTT!"
```

La ventana A debe mostrar `Hello from MQTT!`. Si no aparece, no continúes con
la ESP32: primero debe funcionar esta prueba local.

Permite TCP 1883 en Windows Defender Firewall: Advanced Settings → Inbound
Rules → New Rule → Port → TCP → `1883` → Allow.

## 4. Averiguar la IP Wi-Fi de Windows

En PowerShell de Windows ejecuta:

```powershell
ipconfig
```

Usa la dirección `IPv4` del adaptador **Wi-Fi**, por ejemplo `192.168.80.65`.
No uses la dirección del adaptador `vEthernet (WSL (Hyper-V firewall))` y no
uses `localhost`.

La ESP32 y Windows deben estar conectados al mismo router/red Wi-Fi. En esta
práctica no se necesita `portproxy`, `hostname -I`, `ufw` ni un segundo
Mosquitto dentro de WSL.

## 5. Task 1 — activar los subsistemas

En `firmware/lab0_mqtt/prj.conf` están activados:

```text
CONFIG_WIFI=y
CONFIG_MQTT_LIB=y
CONFIG_JSON_LIBRARY=y
CONFIG_LED_STRIP=y
```

La diferencia principal respecto a Lab 0.2 es `CONFIG_MQTT_LIB=y` en lugar de
`CONFIG_HTTP_SERVER=y`.

## 6. Task 2 — configurar el broker

En `firmware/lab0_mqtt/Kconfig` se declaran:

```text
CONFIG_LAB_BROKER_ADDR
CONFIG_LAB_BROKER_PORT
```

`LAB_BROKER_ADDR` debe ser la IP del PC, por ejemplo `192.168.1.50`. No uses
`localhost`: en la ESP32 significa la propia placa.

Compila pasando SSID, contraseña y dirección del broker:

```bash
cd "$ZEPHYR"
.venv/bin/west build -p always \
  -b esp32c6_devkitc/esp32c6/hpcore \
  "$IOT_LABS/lab0_3/firmware/lab0_mqtt" \
  -d "$ZEPHYR/build/lab0_mqtt" \
  -- -DCONFIG_LAB_WIFI_SSID='"NOMBRE_WIFI"' \
     -DCONFIG_LAB_WIFI_PSK='"CONTRASEÑA_WIFI"' \
     -DCONFIG_LAB_BROKER_ADDR='"192.168.1.50"' \
     -DCONFIG_LAB_BROKER_PORT=1883
```

Task 1 y Task 2 están correctas si no aparecen los errores que comienzan por
`TASK 1 is not done` o `TASK 2 is not done`.

## 7. Task 3 — controlar el LED

Task 3 reutiliza el WS2812 de Lab 0.2 mediante `led_set()`. Se prueba después
de que la ESP32 se conecte al broker y se suscriba a `iot/control`.

Flashea:

```bash
.venv/bin/west flash -d "$ZEPHYR/build/lab0_mqtt"
```

Abre el monitor:

```bash
.venv/bin/west espressif monitor -p /dev/ttyACM0
```

Reinicia con **EN/RESET**. Debes ver:

```text
IPv4 address: ...
Connecting to broker 192.168.1.50:1883
Connected to broker
Subscribed to iot/control
```

Desde otra terminal publica un comando:

```bash
mosquitto_pub -h 192.168.80.65 -t iot/control -q 1 -m '{"state":1}'
```

El LED debe encenderse verde. Para apagarlo:

```bash
mosquitto_pub -h 192.168.80.65 -t iot/control -q 1 -m '{"state":0}'
```

En el monitor debe aparecer `Actuating command received, LED state: 1` o
`LED state: 0`.

## 8. Task 4 — recibir, parsear y confirmar comandos

Task 4 está en `handle_control_payload()`. El evento MQTT no contiene
directamente los bytes del payload; el firmware los lee con
`mqtt_read_publish_payload_blocking()`, valida el JSON, acciona el LED y envía
`PUBACK` para QoS 1.

Observa los mensajes del broker:

Terminal A:

```bash
mosquitto_sub -h 192.168.80.65 -t '#' -v
```

Terminal B:

```bash
mosquitto_pub -h 192.168.80.65 -t iot/control -q 1 -m '{"state":1}'
```

La ESP32 debe mostrar:

```text
Actuating command received, LED state: 1
PUBACK sent for message ...
```

Un payload inválido debe generar una advertencia:

```bash
mosquitto_pub -h 192.168.80.65 -t iot/control -q 1 -m '{"wrong_field":1}'
```

## 9. Task 5 — publicar telemetría

Task 5 está en `publish_sensor()`. Cada dos segundos la ESP32 genera una
temperatura entre 20.0 y 29.9 y publica JSON en `iot/sensor` con QoS 0.

En otra terminal observa los mensajes:

```bash
mosquitto_sub -h 192.168.80.65 -t iot/sensor -v
```

Salida esperada cada aproximadamente dos segundos:

```text
iot/sensor {"temperature":24.7}
```

El monitor serial también debe mostrar:

```text
Publishing to iot/sensor: {"temperature": 24.7}
```

## 10. Dashboard MQTT

El dashboard no necesita la IP de la ESP32. Solo necesita acceder al broker.
Instala las dependencias en el entorno virtual del repositorio:

```bash
cd "$IOT_LABS"
python3 -m venv .venv-dashboard
.venv-dashboard/bin/python -m pip install --upgrade pip
.venv-dashboard/bin/python -m pip install flask paho-mqtt
```

Si ejecutas el dashboard en WSL y Mosquitto corre en Windows, define la IP del
broker antes de arrancarlo:

```bash
export MQTT_BROKER=192.168.80.65
```

Si ejecutas el dashboard directamente en Windows, `localhost` es correcto
cuando Mosquitto también está instalado en Windows.

Arranca el dashboard:

```bash
MQTT_BROKER=192.168.80.65 .venv-dashboard/bin/python lab0_3/tools/dashboard_mqtt.py
```

La salida debe incluir:

```text
[MQTT] Connected to broker (rc=Success)
[MQTT] Subscribed to: iot/sensor
[*] MQTT Dashboard running.
```

Abre `http://localhost:5000`. La gráfica se actualiza sin hacer GET a la
ESP32: Flask lee el último mensaje recibido por MQTT. Los botones publican
`{"state": 1}` o `{"state": 0}` en `iot/control`.

## 11. Verificación completa desde terminal

1. Inicia Mosquitto y prueba `test/hello`.
2. Identifica la IP del PC con `hostname -I`.
3. Compila pasando esa IP como `CONFIG_LAB_BROKER_ADDR`.
4. Flashea la ESP32 y abre el monitor serial.
5. Confirma Wi-Fi, conexión MQTT y suscripción a `iot/control`.
6. Ejecuta `mosquitto_sub -h 192.168.80.65 -t iot/sensor -v` y verifica Task 5.
7. Ejecuta `mosquitto_pub ... iot/control ...` y verifica Tasks 3 y 4.
8. Arranca el dashboard en `.venv-dashboard`.
9. Abre `http://localhost:5000` y verifica gráfica y botones.

## 12. Problemas frecuentes

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `Connection refused` en `mosquitto_pub` | Broker detenido o puerto bloqueado | Reiniciar Mosquitto en Windows y permitir TCP 1883 |
| ESP32 no conecta al broker | IP equivocada o firewall | Usar IP del PC, no `localhost`; abrir TCP 1883 |
| No aparece `Connected to broker` | Mosquitto solo escucha loopback | Revisar `listener 1883` y reiniciar servicio |
| No llegan lecturas | No hay suscriptor o MQTT se desconectó | Revisar `mqtt_input`, monitor serial y `mosquitto_sub` |
| LED no cambia | Topic o QoS incorrecto | Usar exactamente `iot/control` y `-q 1` |
| `externally-managed-environment` | PEP 668 bloquea pip global | Usar `.venv-dashboard/bin/python -m pip ...` |
| Dashboard sin datos | Dashboard apunta a otro broker | Revisar `MQTT_BROKER` y `MQTT_PORT` |

## 13. Estructura

```text
lab0_3/
├── README.md
├── firmware/
│   └── lab0_mqtt/
│       ├── CMakeLists.txt
│       ├── Kconfig
│       ├── prj.conf
│       ├── boards/esp32c6_devkitc_hpcore.overlay
│       └── src/main.c
└── tools/
    └── dashboard_mqtt.py
```
