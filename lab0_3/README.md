# Lab 0.3 — MQTT desde WSL con ESP32-C6

Esta guía sigue el taller MQTT del repositorio del curso y separa claramente
qué se ejecuta en **WSL** y qué se ejecuta en **Windows**.

## Resultado esperado

```text
ESP32-C6 -- PUBLISH iot/sensor --> Mosquitto -- entrega --> Dashboard
ESP32-C6 <-- SUBSCRIBE iot/control -- Mosquitto <-- publica -- Dashboard
```

- La ESP32 publica una temperatura cada dos segundos.
- La ESP32 se suscribe al topic `iot/control` para controlar el WS2812.
- Mosquitto es el broker MQTT y escucha en TCP `1883`.
- El dashboard Python recibe `iot/sensor` y publica `iot/control`.

En este taller no se usa `ESP32_IP`. La ESP32 necesita la IP del equipo donde
está Mosquitto.

## Direcciones que debes obtener tú

No se incluyen direcciones privadas reales en este repositorio. En PowerShell,
ejecuta `ipconfig` y guarda la IPv4 del adaptador Wi-Fi de Windows como
`<IP_WINDOWS_WIFI>`. Esa es la dirección del equipo donde se ejecuta Mosquitto.
La dirección de la ESP32 la asigna DHCP y puede cambiar; no necesitas
publicarla ni usarla como dirección del broker.

No uses `localhost`, `127.0.0.1` ni la IP de `vEthernet (WSL)` como dirección
del broker. En WSL puedes preparar una variable local:

```bash
export BROKER_IP="<IP_WINDOWS_WIFI>"
```

---

## Parte A — Windows (solo una vez)

### A1. Instalar Mosquitto en Windows

Esta parte debe hacerse en Windows porque la ESP32 está en la red Wi-Fi de
Windows. Descarga el instalador Win64 desde
[mosquitto.org/download](https://mosquitto.org/download/) y selecciona la
opción para instalar Mosquitto como servicio.

Abre como administrador:

```text
C:\Program Files\mosquitto\mosquitto.conf
```

Añade al final:

```text
listener 1883
allow_anonymous true
```

Reinicia el servicio en **PowerShell como administrador**:

```powershell
net stop mosquitto
net start mosquitto
```

Comprueba que el servicio esté iniciado:

```powershell
Get-Service mosquitto
```

Debe mostrar `Running`.

### A2. Abrir TCP 1883

Solo en **PowerShell como administrador**:

```powershell
New-NetFirewallRule `
  -DisplayName "Mosquitto MQTT 1883" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 1883 `
  -Action Allow
```

Si la regla ya existe, PowerShell puede avisarlo; no es necesario crear otra.

### A3. Obtener la IP del broker

En PowerShell:

```powershell
ipconfig
```

Usa la IPv4 de **Adaptador de LAN inalámbrica Wi-Fi**. En este equipo:

```text
<IP_WINDOWS_WIFI>
```

No uses:

```text
<IP_VETHERNET_WSL>  # vEthernet/WSL
localhost
127.0.0.1
```

### A4. Conectar la placa a WSL

Solo si `/dev/ttyACM0` no existe en WSL. En PowerShell como administrador:

```powershell
usbipd list
```

Busca la placa, por ejemplo:

```text
2-4  1a86:55d3  USB-Enhanced-SERIAL CH343 (COM5)
```

Conecta el BUSID real:

```powershell
usbipd bind --busid 2-4
usbipd attach --wsl --busid 2-4
```

`bind` puede indicar que el dispositivo ya estaba compartido; eso no es un
error. Después de `attach`, vuelve a WSL.

---

## Parte B — WSL: preparar el proyecto

Todas las instrucciones siguientes son para Ubuntu/WSL, no PowerShell.

### B1. Abrir WSL y definir rutas

```bash
export IOT_LABS="$HOME/IoT-Labs-DHR"
export ZEPHYR="$HOME/zephyrproject"
```

Verifica:

```bash
test -f "$IOT_LABS/lab0_3/firmware/lab0_mqtt/src/main.c" && echo "repo OK"
test -f "$IOT_LABS/lab0_3/tools/dashboard_mqtt.py" && echo "dashboard OK"
```

### B2. Activar Zephyr

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west --version
```

El prefijo `(.venv)` en la terminal confirma que activaste el entorno de
Zephyr. Este entorno es distinto de `.venv-dashboard`.

### B3. Instalar clientes MQTT en WSL

Para ejecutar `mosquitto_pub` y `mosquitto_sub` desde WSL:

```bash
sudo apt update
sudo apt install -y mosquitto-clients netcat-openbsd
```

No necesitas ejecutar otro broker Mosquitto dentro de WSL. El broker es el
servicio instalado en Windows.

### B4. Probar que WSL alcanza el broker de Windows

Primero verifica el puerto:

```bash
nc -vz "$BROKER_IP" 1883
```

Debe terminar con `succeeded`. Si falla, vuelve a la Parte A: Mosquitto debe
estar iniciado y Windows Firewall debe permitir TCP 1883.

Ahora abre dos terminales WSL.

**WSL Terminal 1 — suscriptor:**

```bash
mosquitto_sub -h "$BROKER_IP" -p 1883 -t test/hello -v
```

Déjala abierta. Que no muestre nada todavía es normal.

**WSL Terminal 2 — publicador:**

```bash
mosquitto_pub -h "$BROKER_IP" -p 1883 \
  -t test/hello -m "Hello from MQTT"
```

La Terminal 1 debe mostrar:

```text
test/hello Hello from MQTT
```

No continúes hasta que esta prueba funcione. El suscriptor solo muestra algo
cuando existe un publicador.

---

## Parte C — Tasks del firmware

### C1. Task 1: activar capacidades

Está implementada en:

```text
lab0_3/firmware/lab0_mqtt/prj.conf
```

Las cuatro opciones son:

```text
CONFIG_WIFI=y
CONFIG_MQTT_LIB=y
CONFIG_JSON_LIBRARY=y
CONFIG_LED_STRIP=y
```

`CONFIG_MQTT_LIB` reemplaza a `CONFIG_HTTP_SERVER` del taller `lab0_2`.

### C2. Task 2: declarar el broker

Está implementada en:

```text
lab0_3/firmware/lab0_mqtt/Kconfig
```

Declara `LAB_BROKER_ADDR` y `LAB_BROKER_PORT`. El valor que se utilizará al
compilar es:

```text
LAB_BROKER_ADDR="$BROKER_IP"
LAB_BROKER_PORT=1883
```

### C3. Compilar

En WSL:

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west build -p always \
  -b esp32c6_devkitc/esp32c6/hpcore \
  "$IOT_LABS/lab0_3/firmware/lab0_mqtt" \
  -d "$ZEPHYR/build/lab0_mqtt" \
  -- -DCONFIG_LAB_WIFI_SSID='"TU_SSID_WIFI"' \
     -DCONFIG_LAB_WIFI_PSK='"TU_CONTRASEÑA"' \
     -DCONFIG_LAB_BROKER_ADDR="\"$BROKER_IP\"" \
     -DCONFIG_LAB_BROKER_PORT=1883
```

Sustituye `TU_CONTRASEÑA` por la contraseña real. No guardes la contraseña en
Git.

La compilación correcta termina con `Generating files` y crea:

```text
~/zephyrproject/build/lab0_mqtt/zephyr/zephyr.bin
```

### C4. Verificar el puerto USB en WSL

En WSL:

```bash
ls /dev/ttyACM*
```

Debe aparecer:

```text
/dev/ttyACM0
```

Si no aparece, vuelve a la Parte A4 y ejecuta `usbipd attach` en PowerShell.
El comando `ls /dev/ttyACM*` no se ejecuta en PowerShell.

### C5. Flashear

En WSL:

```bash
.venv/bin/west flash \
  -d "$ZEPHYR/build/lab0_mqtt" \
  --runner esp32 \
  --esp-device /dev/ttyACM0
```

### C6. Abrir el monitor

En WSL, en una terminal separada:

```bash
cd "$ZEPHYR"
source .venv/bin/activate
.venv/bin/west espressif monitor -p /dev/ttyACM0
```

Presiona **EN/RESET**. La salida correcta contiene:

```text
Associated with "TU_SSID_WIFI"
IPv4 address: ...
Connecting to broker <IP_WINDOWS_WIFI>:1883
Connected to broker
Subscribed to iot/control
```

Si aparece `mqtt_connect failed (-116)`, la ESP32 sí tiene Wi-Fi pero no
alcanza `<IP_WINDOWS_WIFI>:1883`; repite B4 y revisa Mosquitto/Firewall en
Windows. No cambies `main.c`.

### C7. Task 5: comprobar telemetría

En otra terminal WSL:

```bash
mosquitto_sub -h "$BROKER_IP" -p 1883 -t iot/sensor -v
```

Después de `Connected to broker`, debe llegar un mensaje cada dos segundos:

```text
iot/sensor {"temperature": 24.7}
```

El monitor también muestra `Publishing to iot/sensor`.

### C8. Tasks 3 y 4: probar el LED y PUBACK

En otra terminal WSL, encender:

```bash
mosquitto_pub -h "$BROKER_IP" -p 1883 \
  -t iot/control -q 1 -m '{"state":1}'
```

El LED debe encenderse verde y el monitor debe mostrar:

```text
Actuating command received, LED state: 1
PUBACK sent for message ...
```

Apagar:

```bash
mosquitto_pub -h "$BROKER_IP" -p 1883 \
  -t iot/control -q 1 -m '{"state":0}'
```

`state:1` verifica Task 3 (`led_set`). El parseo JSON y `PUBACK` verifican
Task 4 (`handle_control_payload`).

---

## Parte D — Dashboard en WSL

### D1. Crear el entorno virtual

En WSL:

```bash
cd "$IOT_LABS"
python3 -m venv .venv-dashboard
.venv-dashboard/bin/python -m pip install flask paho-mqtt
```

Si `.venv-dashboard` ya existe, no lo crees de nuevo.

### D2. Arrancar el dashboard

En WSL:

```bash
cd "$IOT_LABS"
MQTT_BROKER="$BROKER_IP" \
  .venv-dashboard/bin/python lab0_3/tools/dashboard_mqtt.py
```

Debe mostrar:

```text
[*] MQTT Dashboard running.
[*] Broker: <IP_WINDOWS_WIFI>:1883
[MQTT] Subscribed to: iot/sensor
```

Abre desde Windows:

```text
http://localhost:5000
```

El navegador es Windows, pero el servidor Python está ejecutándose en WSL.
Los botones publican en `iot/control` y la gráfica recibe `iot/sensor`.

---

## Distribución final de terminales

| Terminal | Entorno | Comando |
| --- | --- | --- |
| A | WSL | `west espressif monitor -p /dev/ttyACM0` |
| B | WSL | `mosquitto_sub -h "$BROKER_IP" -t iot/sensor -v` |
| C | WSL | `mosquitto_pub -h "$BROKER_IP" -t iot/control -q 1 -m '{"state":1}'` |
| D | WSL | `MQTT_BROKER="$BROKER_IP" .venv-dashboard/bin/python lab0_3/tools/dashboard_mqtt.py` |
| E | PowerShell | Solo `usbipd` o firewall, si son necesarios |

## Checklist de entrega

- [ ] Mosquitto funciona en Windows y acepta TCP 1883.
- [ ] `mosquitto_sub/pub` funciona desde WSL usando `$BROKER_IP`.
- [ ] El firmware compila con `CONFIG_LAB_BROKER_ADDR=$BROKER_IP`.
- [ ] La ESP32 muestra `Connected to broker`.
- [ ] La ESP32 muestra `Subscribed to iot/control`.
- [ ] Llegan temperaturas por `iot/sensor`.
- [ ] El LED responde a `state:1` y `state:0`.
- [ ] El monitor muestra `PUBACK sent`.
- [ ] El dashboard muestra la gráfica y controla el LED.

## Errores frecuentes

| Error | Interpretación | Acción |
| --- | --- | --- |
| `No /dev/ttyACM0` | USB no está conectado a WSL | PowerShell: `usbipd attach --wsl --busid <BUSID>` |
| `mqtt_connect failed (-116)` | La ESP32 no alcanza el broker | Revisar Windows Mosquitto, IP Wi-Fi y TCP 1883 |
| `mosquitto_sub` silencioso | Aún no llegó ningún mensaje | Mantenerlo abierto y publicar desde otra terminal |
| `Connection refused` | Puerto cerrado o servicio detenido | Windows: `Get-Service mosquitto`; revisar Firewall |
| `externally-managed-environment` | Pip global bloqueado | Usar `.venv-dashboard/bin/python -m pip` |
| Dashboard sin datos | Broker equivocado | Ejecutar con `MQTT_BROKER="$BROKER_IP"` |
