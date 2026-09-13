# IoT-Labs-DHR — Taller 0_2: implementación IoT mínima por HTTP

Este repositorio contiene una implementación mínima de un sistema IoT con
ESP32-C6 y Zephyr RTOS. La placa funciona como el **Sensing and Controlling
Domain (SCD)** y expone una API HTTP. El dashboard Python funciona como el
**Application and Service Domain (ASD)**.

## 1. Qué se construyó

La solución implementa las dos capacidades físicas del taller:

| Task | Archivo | Qué hace | Cómo se verifica |
| --- | --- | --- | --- |
| Task 1 | `lab0_2/firmware/lab0_http/prj.conf` | Activa Wi-Fi, servidor HTTP, JSON y LED strip | El firmware debe compilar sin el error de `TASK 1` |
| Task 2 | `lab0_2/firmware/lab0_http/src/main.c` (`led_set`) | Controla el LED RGB WS2812 integrado en GPIO8 | `POST /api/control` cambia el LED |
| Task 3 | `lab0_2/firmware/lab0_http/src/main.c` (`sensor_handler`) | Genera una temperatura simulada entre 20.0 y 29.9 °C | `GET /api/sensor` devuelve JSON |
| Task 4 | `lab0_2/firmware/lab0_http/src/main.c` (`control_handler`) | Recibe JSON, interpreta `state` y acciona el LED | `POST /api/control` devuelve `{"status": "ok"}` |

El LED de esta placa no es un GPIO digital normal: es un WS2812 direccionable.
Por eso el proyecto usa `led_strip_update_rgb()` y el overlay de
`lab0_2/firmware/lab0_http/boards/esp32c6_devkitc_hpcore.overlay`.

## 2. Requisitos

- ESP32-C6-DevKitC conectada por USB.
- Zephyr instalado en `~/zephyrproject`.
- Target de Zephyr: `esp32c6_devkitc/esp32c6/hpcore`.
- Python 3 para el dashboard.
- Una red Wi-Fi de **2.4 GHz**. El ESP32-C6 no se conecta a una red que solo
  tenga 5 GHz.
- Linux o WSL2 con el dispositivo visible, normalmente como `/dev/ttyACM0`.

En WSL2, si la placa no aparece, primero hay que conectarla con `usbipd` desde
PowerShell:

```powershell
usbipd list
usbipd attach --wsl --busid <BUSID>
```

Después, en Ubuntu:

```bash
ls /dev/ttyACM*
```

## 3. Preparar el entorno

Cada terminal nueva debe activar el entorno de Zephyr:

```bash
cd ~/zephyrproject
source .venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
.venv/bin/west --version
```

Desde este punto, las rutas del ejemplo usan:

```bash
export IOT_LABS="$HOME/IoT-Labs-DHR"
export ZEPHYR="$HOME/zephyrproject"
```

No se deben guardar las credenciales Wi-Fi en archivos versionados. Se pasan
como parámetros al momento de configurar la compilación.

## 4. Compilar el firmware

Ejecutar desde el entorno de Zephyr:

```bash
cd "$ZEPHYR"
.venv/bin/west build -p always \
  -b esp32c6_devkitc/esp32c6/hpcore \
  "$IOT_LABS/lab0_2/firmware/lab0_http" \
  -d "$ZEPHYR/build/lab0_http" \
  -- -DCONFIG_LAB_WIFI_SSID='"NOMBRE_DE_TU_WIFI"' \
     -DCONFIG_LAB_WIFI_PSK='"CONTRASEÑA_DE_TU_WIFI"'
```

El uso de comillas dobles dentro de las comillas simples es intencional:
Kconfig necesita recibir una cadena.

Una compilación correcta genera:

```text
$ZEPHYR/build/lab0_http/zephyr/zephyr.bin
$ZEPHYR/build/lab0_http/zephyr/zephyr.elf
```

### Verificar el Task 1

Task 1 está terminado si la compilación no muestra:

```text
TASK 1 is not done yet
```

Las cuatro opciones que se activan en `prj.conf` son:

```text
CONFIG_WIFI=y           # Network Interface Capability
CONFIG_HTTP_SERVER=y    # Application Interface Capability
CONFIG_JSON_LIBRARY=y   # Data Capability
CONFIG_LED_STRIP=y      # Actuating Capability
```

## 5. Flashear la ESP32-C6

Con la placa conectada y `/dev/ttyACM0` confirmado:

```bash
cd "$ZEPHYR"
.venv/bin/west flash -d "$ZEPHYR/build/lab0_http"
```

Si `west flash` no detecta el puerto, se puede usar `esptool` directamente:

```bash
esptool -p /dev/ttyACM0 -b 460800 \
  --before default-reset --after hard-reset \
  write-flash 0x0 \
  "$ZEPHYR/build/lab0_http/zephyr/zephyr.bin"
```

## 6. Abrir el monitor serial

El monitor permite ver la asociación Wi-Fi, la dirección IP, las peticiones y
los comandos de actuación:

```bash
cd "$ZEPHYR"
.venv/bin/west espressif monitor -p /dev/ttyACM0
```

También se puede usar `miniterm`:

```bash
.venv/bin/python -m serial.tools.miniterm /dev/ttyACM0 115200
```

Presionar el botón **EN/RESET** después de abrir el monitor. La secuencia
esperada es parecida a:

```text
Connecting to "NOMBRE_DE_TU_WIFI"...
Associated with "NOMBRE_DE_TU_WIFI"
IPv4 address: 192.168.1.100
HTTP server listening on port 80
```

Anotar la dirección que aparece después de `IPv4 address`. En los comandos
siguientes se usa `192.168.1.100` como ejemplo:

```bash
export ESP32_IP="192.168.1.100"
```

`ESP32_IP` debe definirse en **cada terminal nueva** donde se ejecuten
comandos `curl`; las variables de una terminal no se transfieren a otra.
Compruébala antes de probar:

```bash
echo "$ESP32_IP"
```

Si no imprime la IP de la placa, vuelve a ejecutar el `export` con la dirección
mostrada por el monitor serial.

## 7. Verificar cada task desde la terminal

Las pruebas se deben ejecutar desde otra terminal, mientras el monitor serial
permanece abierto.

### Task 2: LED WS2812

Al arrancar, `main()` ejecuta `led_set(0)`, por lo que el LED debe quedar
apagado. Para encenderlo en verde:

```bash
curl -i -X POST "http://$ESP32_IP/api/control" \
  -H 'Content-Type: application/json' \
  -d '{"state": 1}'
```

Respuesta esperada:

```text
HTTP/1.1 200 OK
{"status": "ok"}
```

El LED integrado debe encenderse en verde y el monitor debe mostrar:

```text
Actuating command received, LED state: 1
```

Para apagarlo:

```bash
curl -i -X POST "http://$ESP32_IP/api/control" \
  -H 'Content-Type: application/json' \
  -d '{"state": 0}'
```

Debe aparecer `LED state: 0` y el LED debe apagarse.

### Task 3: sensor simulado

Solicitar una lectura:

```bash
curl -i "http://$ESP32_IP/api/sensor"
```

Respuesta esperada:

```json
{"temperature": 24.7}
```

El valor cambia en cada petición, pero siempre debe estar entre `20.0` y
`29.9`. En el monitor serial debe aparecer:

```text
Telemetry requested, sent: {"temperature": 24.7}
```

Para observar varias lecturas:

```bash
for i in $(seq 1 5); do
  curl -s "http://$ESP32_IP/api/sensor"
  printf '\n'
  sleep 1
done
```

### Task 4: recepción y parseo JSON

El siguiente comando prueba la recepción del cuerpo HTTP, el parseo mediante
`json_obj_parse()`, el uso de `state` y la respuesta de confirmación:

```bash
curl -i -X POST "http://$ESP32_IP/api/control" \
  -H 'Content-Type: application/json' \
  --data-binary '{"state":1}'
```

La respuesta debe ser HTTP 200 con `{"status": "ok"}` y el monitor debe
registrar el estado recibido. El firmware acumula el cuerpo antes de parsearlo,
por lo que también funciona aunque la red entregue el payload en más de una
parte.

Para probar un payload inválido:

```bash
curl -i -X POST "http://$ESP32_IP/api/control" \
  -H 'Content-Type: application/json' \
  -d '{"wrong_field": 1}'
```

El monitor debe mostrar una advertencia `Could not parse control payload`.

## 8. Ejecutar el dashboard Python

El dashboard consulta el sensor cada 1.5 segundos y ofrece botones para
encender y apagar el LED.

Primero editar `lab0_2/tools/dashboard_http.py` y cambiar:

```python
ESP32_IP = "192.168.1.100"
```

por la IP real de la placa. Luego instalar las dependencias si no están
disponibles. Ubuntu/Debian puede bloquear `pip --user` por PEP 668, así que
se recomienda crear un entorno virtual separado para el dashboard:

```bash
cd "$IOT_LABS"
python3 -m venv .venv-dashboard
.venv-dashboard/bin/python -m pip install --upgrade pip
.venv-dashboard/bin/python -m pip install flask requests
```

Arrancar el servidor:

```bash
cd "$IOT_LABS"
.venv-dashboard/bin/python lab0_2/tools/dashboard_http.py
```

Si el entorno virtual ya existe, no hay que crearlo de nuevo; basta con
ejecutar el último comando. También se puede activarlo para usar `python3`
normalmente:

```bash
cd "$IOT_LABS"
source .venv-dashboard/bin/activate
python lab0_2/tools/dashboard_http.py
```

El directorio `.venv-dashboard/` es local y no debe subirse a GitHub. Si se
usa un archivo `.gitignore`, añadirlo allí.

Abrir en el navegador:

```text
http://localhost:5000
```

La gráfica debe mostrar puntos de temperatura y el estado debe cambiar a
`Connected. Live data stream active.`. Los botones **Turn ON** y **Turn OFF**
deben producir el mismo comportamiento que los comandos `curl`.

También se pueden verificar las rutas del dashboard:

```bash
curl -s http://localhost:5000/api/sensor
curl -s -X POST http://localhost:5000/api/control \
  -H 'Content-Type: application/json' \
  -d '{"state":1}'
```

## 9. Flujo completo de verificación

1. Conectar la placa y confirmar `/dev/ttyACM0`.
2. Compilar pasando SSID y contraseña por `west build`.
3. Confirmar que no aparece el error de Task 1.
4. Flashear con `west flash`.
5. Abrir el monitor serial a 115200 baudios.
6. Reiniciar con **EN/RESET** y anotar la IPv4.
7. Ejecutar `GET /api/sensor` y verificar Task 3.
8. Ejecutar `POST /api/control` con `state: 1` y verificar Tasks 2 y 4.
9. Ejecutar `POST /api/control` con `state: 0` y confirmar que el LED se apaga.
10. Configurar la misma IP en el dashboard y verificar la interfaz web.

## 10. Problemas frecuentes

| Síntoma | Causa probable | Acción |
| --- | --- | --- |
| `west: command not found` | No se activó el entorno | `source ~/zephyrproject/.venv/bin/activate` |
| No aparece `/dev/ttyACM0` | USB no está conectado a WSL2 | Revisar `usbipd list` y `usbipd attach --wsl` |
| `Wi-Fi association failed` | SSID o contraseña incorrectos | Recompilar con las credenciales correctas |
| No aparece `IPv4 address` | No hubo lease DHCP | Confirmar que la red sea 2.4 GHz y que el DHCP esté activo |
| `curl` queda esperando | La PC y la placa están en redes distintas | Conectarlas al mismo router/subred |
| El LED no cambia | Overlay o driver no incluidos | Confirmar el target y `CONFIG_LED_STRIP=y` |
| Dashboard muestra `Node Unreachable` | IP incorrecta o placa apagada | Usar la IP mostrada por el monitor y probar primero con `curl` |
| `HTTP 502` en dashboard | El POST del dashboard no llegó a la placa | Probar manualmente `curl /api/control` |
| `externally-managed-environment` al usar pip | PEP 668 protege el Python del sistema | Usar `.venv-dashboard/bin/python -m pip ...` como en la sección 8 |

## 11. Estructura del proyecto

```text
IoT-Labs-DHR/
├── README.md
├── firmware/
│   └── lab0_http/
│       ├── CMakeLists.txt
│       ├── Kconfig
│       ├── prj.conf
│       ├── sections-rom.ld
│       ├── boards/
│       │   └── esp32c6_devkitc_hpcore.overlay
│       └── src/
│           └── main.c
└── tools/
    └── dashboard_http.py
```

Las credenciales Wi-Fi se suministran durante la compilación y no forman parte
del repositorio.
