# Lab 1 — Prueba de radio 802.15.4 con ESP32-C6

Este laboratorio mide, con datos reales, el canal más limpio y el alcance
confiable de la radio 802.15.4. Se usan **dos ESP32-C6**, cada una conectada a
su propio computador.

> Todo el firmware, la compilación y los monitores se ejecutan en WSL. Windows
> solo se usa para conectar cada USB a WSL con `usbipd`, si hace falta.

## 1. Qué se va a medir

Al terminar tendrás:

- El canal 802.15.4 con menor ruido.
- RSSI promedio en cada distancia.
- PER (pérdida de paquetes) en cada distancia.
- La distancia máxima con `PER < 1 %`.
- Un umbral de RSSI que sirva como referencia de confiabilidad.

No inventes resultados: las tablas se llenan con lo que muestre cada placa.

## 2. Materiales y preparación

Necesitas:

- Dos ESP32-C6-DevKitC-1.
- Dos cables USB-C.
- Dos computadores o dos sesiones WSL separadas.
- Una cinta métrica.
- Zephyr instalado en `~/zephyrproject` en cada WSL.

El firmware está en:

```text
lab1/firmware/lab1_radio
```

El proyecto oficial usa el puerto serial de la ESP32-C6. En este sistema WSL
aparecen como `/dev/ttyACM0` y `/dev/ttyACM1`; compruébalo con `ls /dev/ttyACM*`.

## 3. Conectar cada placa a WSL

### Windows — PowerShell como administrador

Repite esto para cada computador:

```powershell
usbipd list
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

Usa el `BUSID` real que muestre `usbipd list`. Si indica que ya estaba
compartido, continúa.

### WSL

```bash
ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
```

En este equipo las placas ESP32-C6 se reconocen como dispositivos CDC-ACM:
- Placa A: `/dev/ttyACM0`
- Placa B: `/dev/ttyACM1`

(En otros entornos con convertidores UART externos pueden aparecer como `/dev/ttyUSB0` y `/dev/ttyUSB1`). Usa el nombre de puerto correspondiente a cada placa.

## 4. Compilar y flashear

En cada WSL, desde el directorio del repositorio:

```bash
export IOT_LABS="$HOME/IoT-Labs-DHR"
export ZEPHYR="$HOME/zephyrproject"
cd "$ZEPHYR"
source .venv/bin/activate

.venv/bin/west build -p always \
  -b esp32c6_devkitc/esp32c6/hpcore \
  "$IOT_LABS/lab1/firmware/lab1_radio" \
  -d "$ZEPHYR/build/lab1_radio"
```

Flashea usando el puerto de la placa (por ejemplo `/dev/ttyACM0` para la placa A, o `/dev/ttyACM1` para la placa B):

```bash
.venv/bin/west flash \
  -d "$ZEPHYR/build/lab1_radio" \
  --runner esp32 \
  --esp-device /dev/ttyACM0
```

Si vas a flashear la segunda placa, cambia a `--esp-device /dev/ttyACM1`.

Abre el monitor en una terminal separada:

```bash
.venv/bin/west espressif monitor -p /dev/ttyACM0
```

(Para la segunda placa, usa `-p /dev/ttyACM1` en otra terminal).

Presiona Enter. Debe aparecer:

```text
uart:~$
```

Todos los comandos de radio se escriben con el prefijo `ot`. Para verlos:

```text
uart:~$ ot help
```

Sal del monitor con `Ctrl-]`.

Si la placa fue usada por otro equipo, borra el dataset anterior una sola vez:

```text
uart:~$ ot factoryreset
```

Después reinicia la placa y vuelve a abrir el monitor.

## 5. Escanear canales 11–26

Haz esto en una sola placa y mantén la otra apagada o sin iniciar Thread. Así
la prueba mide el ruido del ambiente y no una red creada por el laboratorio.

En el monitor:

```text
uart:~$ ot ifconfig up
uart:~$ ot scan energy 500
```

El comando mide cada canal durante 500 ms. Un RSSI más negativo significa menos
energía/interferencia. Registra el canal con el valor más bajo:

| Canal | RSSI (dBm) | Observación |
|---:|---:|---|
| 11 | | |
| 12 | | |
| 13 | | |
| 14 | | |
| 15 | | |
| 16 | | |
| 17 | | |
| 18 | | |
| 19 | | |
| 20 | | |
| 21 | | |
| 22 | | |
| 23 | | |
| 24 | | |
| 25 | | |
| 26 | | |

Guarda como `CANAL_PRUEBA` el canal con menor RSSI. Los canales 15, 20, 25 y
26 suelen quedar entre canales Wi-Fi, pero usa tu medición, no una suposición.

## 6. Crear la red Thread

Configura la potencia en **las dos placas** antes de medir. Usa el valor que
indique el instructor; `0 dBm` sirve para una prueba corta en interiores:

```text
uart:~$ ot txpower 0
```

### Dispositivo A — líder

```text
uart:~$ ot dataset init new
uart:~$ ot dataset channel CANAL_PRUEBA
uart:~$ ot dataset commit active
uart:~$ ot ifconfig up
uart:~$ ot thread start
uart:~$ ot state
```

Espera hasta ver `leader`. Luego copia el dataset completo:

```text
uart:~$ ot dataset active -x
```

Envía a la otra persona toda la cadena hexadecimal mostrada. No la modifiques:
incluye canal, PAN ID y clave de red.

### Dispositivo B — integrante

```text
uart:~$ ot dataset set active DATASET_HEX_DE_A
uart:~$ ot ifconfig up
uart:~$ ot thread start
uart:~$ ot state
```

Primero puede mostrar `child`. Espera hasta que se convierta en `router`
(puede tardar hasta dos minutos).

## 7. Comprobar IPv6 con ping

En cada placa:

```text
uart:~$ ot ipaddr
```

Comparte la dirección RLOC, identificada porque contiene `:0:ff:fe00:`.

Desde A prueba a B:

```text
uart:~$ ot ping RLOC_DE_B 64 100 0.2
```

Después B prueba a A. Cerca de las placas se espera una pérdida de 0 %.
No hagan ping simultáneamente: eso agrega colisiones artificiales.

## 8. Medir RSSI y PER

Mide en línea de vista a 1, 5, 10, 20, 30 m y luego aumenta hasta que el enlace
deje de ser confiable. En cada distancia:

1. A ejecuta el ping a B y registra los paquetes perdidos.
2. B ejecuta el ping a A y registra sus paquetes perdidos.
3. En ambas placas ejecuta `ot neighbor table`.
4. Registra el `Avg RSSI` recibido por cada placa.
5. No cambies canal, potencia, tamaño ni cantidad de pings.

Usa siempre:

```text
ot ping RLOC_DEL_OTRO 64 100 0.2
ot neighbor table
```

`PER` es el porcentaje de paquetes perdidos:

```text
PER (%) = paquetes perdidos / 100 × 100
```

| Distancia (m) | RSSI A recibe de B (dBm) | RSSI B recibe de A (dBm) | PER A→B (%) | PER B→A (%) |
|---:|---:|---:|---:|---:|
| 1 | | | | |
| 5 | | | | |
| 10 | | | | |
| 20 | | | | |
| 30 | | | | |
| | | | | |

El alcance confiable es la mayor distancia donde el PER se mantiene por debajo
de 1 %. También anota el RSSI de esa medición: será tu umbral práctico.

## 9. Explicar los resultados

### ¿Por qué baja el RSSI con la distancia?

La señal se reparte sobre un área cada vez mayor. Por eso baja la densidad de
potencia y aumenta la pérdida de propagación. En espacio libre, duplicar la
distancia cuesta aproximadamente 6 dB.

### ¿Por qué no basta con detectar hasta −100 dBm?

Detectar una señal no significa recibirla sin errores. La señal puede sufrir
ruido, interferencia y fading. Se necesita margen sobre el ruido para mantener
un SNR suficiente. Por eso un enlace puede detectar una señal débil, pero tener
un PER alto.

### ¿Cómo ayuda 802.15.4 frente al Wi-Fi?

802.15.4 usa DSSS: distribuye la información en una secuencia de chips y obtiene
ganancia de procesamiento frente a parte de la interferencia. No elimina el
Wi-Fi, por eso el escaneo de canales sigue siendo necesario.

## 10. Mapeo ISO/IEC 30141

| Componente | Dominio | Justificación |
|---|---|---|
| ESP32-C6 | SCD | Dispositivo de sensado/control |
| Radio 802.15.4 y antena | SCD | Subsistema de comunicación |
| Aire/ondas RF | PED | Medio físico de propagación |
| Interferencia Wi-Fi | PED | Energía que afecta el medio RF |

La relación probada es **Proximity Networking** entre el radio/antena del SCD y
el medio físico del PED.

| Categoría | Capacidad | Estado |
|---|---|---|
| Transducer | LED de la placa | Activa |
| Data | RSSI, TX/RX 802.15.4 | Activa |
| Interface | OpenThread CLI y serial | Activa |
| Supporting | Sincronización y acelerador criptográfico | Latente |
| Latent | BLE, Wi-Fi y USB de depuración | Latente |

## 11. Entregables

### DDR

Incluye:

1. Descripción de las dos placas.
2. Resumen para el arquitecto: canal, RSSI umbral y alcance.
3. ADR-001: canal seleccionado, ruido y motivo.
4. Tabla ISO/IEC 30141 y capacidades.
5. Respuestas de la sección 9.
6. Tabla completa de distancia, RSSI y PER.

### Resumen de una página

```text
Alcance confiable: ___ m (PER < 1 % con RSSI > ___ dBm)
Separación recomendada: ___ m con margen por obstáculos
Mejor canal: ___ (ruido ___ dBm)
Canales a evitar: ___
Campo de 10 hectáreas: ___ nodos × $40 = $___
Veredicto: proceed / more testing / switch platform
```

### Checklist para campo

Documenta qué revisar si:

- No se une: canal/dataset distinto, antena o metal cerca.
- Hay pérdida intermitente: RSSI bajo, Wi-Fi cercano o vegetación.
- Se supera el alcance medido: reducir separación o agregar un nodo.

## 12. Comandos de Git

Desde WSL:

```bash
cd "$IOT_LABS"
git status
git add README.md lab1/README.md lab1/firmware/lab1_radio
git commit -m "feat: add lab 1 radio validation"
git push origin main
```

Si la variable `IOT_LABS` no existe:

```bash
cd ~/IoT-Labs-DHR
git add README.md lab1/README.md lab1/firmware/lab1_radio
git commit -m "feat: add lab 1 radio validation"
git push origin main
```
