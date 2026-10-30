# Preparación y carga de las cuatro placas

## 1. Materiales e identificación

- S y C: las dos ESP32-C6 de prácticas anteriores.
- RCP: una **tercera ESP32-C6**.
- BR: **ESP32-S3 N16R8** con 8 MB de PSRAM octal, confirmada por el usuario.
- DS18B20, protoboard/cables y su pull-up, conservando montaje de Lab 4.
- Tres jumpers para el enlace S3↔RCP, cables USB de datos y puertos suficientes.

Etiqueta físicamente S, C, RCP y BR. Identifica los puertos conectando una placa
a la vez; su numeración puede cambiar después del reset o de usbipd attach.
Ni ttyACM ni ttyUSB identifican por sí solos qué placa o conector se usó.

En Windows, como antes:

```powershell
usbipd list
usbipd bind --busid <BUSID_DE_LA_PLACA>
usbipd attach --wsl --busid <BUSID_DE_LA_PLACA>
```

`bind` se ejecuta como administrador solo si el dispositivo aún no figura Shared;
si ya está compartido, pasa a attach. No reutilices el BUSID de otra placa.

En WSL:

```bash
ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
```

Anota los puertos reales en el registro. Cierra cualquier monitor que use un
puerto antes de flashear por él. Los ejemplos siguientes necesitan sustituir
`<PUERTO_...>`; los signos `< >` no forman parte del comando real.

## 2. Workspace aislado

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab5/tools/prepare_workspace.sh
```

El script prepara `~/zephyrproject-lab5`, con Zephyr fijado a
`2f0bc11264a8e72e214f3db0a3fa221eb022453a`, módulos, blobs Espressif y SDK para
RISC-V/ESP32-S3 Xtensa. No necesita borrar el Zephyr anterior.

Si te faltan paquetes del sistema, conserva el primer error. El curso requiere
CMake, Ninja, gperf, device-tree-compiler, compilador anfitrión, Python/venv y
herramientas de instalación SDK. La versión vieja de Zephyr no se sustituye
silenciosamente para resolver un error.

Cada terminal puede activar el nuevo entorno así:

```bash
source ~/zephyrproject-lab5/env.sh
```

Para seleccionar otra ruta aislada, exporta `ZEPHYR_WORKSPACE` con esa misma
ruta en **cada** terminal de preparación/build/flash/monitor. No selecciones
el workspace anterior si quieres mantenerlo intacto.

## 3. Compilar las imágenes

Desde `~/IoT-Labs-DHR`, una por una:

```bash
bash lab5/tools/build.sh S uart
bash lab5/tools/build.sh C uart
bash lab5/tools/build.sh RCP
bash lab5/tools/build.sh BR N16R8
```

| Build | Directorio generado en `~/zephyrproject-lab5` |
|---|---|
| S, DS18B20, UART | `build-iot-lab5-S-ds18b20-uart` |
| C, sin sensor, UART | `build-iot-lab5-C-none-uart` |
| RCP | `build-iot-lab5-RCP-c6-spinel` |
| S3 N16R8 | `build-iot-lab5-BR-N16R8-uart` |

No continúes si falla una compilación. Los scripts solo crean el marcador de
carga después de comprobar la configuración y el binario; guardan su SHA-256
para detectar cambios accidentales. Eso no sustituye una firma de firmware.

C/S incluyen SLAAC y TX predeterminada de +20 dBm del firmware actual del curso;
se deben consultar canal y `ot txpower` al ejecutar para documentar valores
reales. No se atribuye a Lab 4 esta configuración nueva ni se altera su evidencia.

## 4. Cargar S y C

Con S conectada por **CH343/UART** y el DS18B20 en GPIO18:

```bash
bash ~/IoT-Labs-DHR/lab5/tools/flash.sh S <PUERTO_S> uart
```

Con C por **CH343/UART**:

```bash
bash ~/IoT-Labs-DHR/lab5/tools/flash.sh C <PUERTO_C> uart
```

Puedes conectar una sola por vez para evitar confusiones. La imagen de S debe
reconocer `ds18b20`; C usa el modo sin sensor (simulado), como cliente. Cada una
recibe su propio binario, no una copia indiscriminada de la imagen S.

Después abre una ventana por consola:

```bash
bash ~/IoT-Labs-DHR/lab5/tools/monitor.sh S <PUERTO_S>
```

```bash
bash ~/IoT-Labs-DHR/lab5/tools/monitor.sh C <PUERTO_C>
```

En S: `soilsense stats`. Conserva la salida; deben existir lecturas aceptadas.
No crees una red independiente en C: este laboratorio la creará en BR.

USB nativo solo para S/C: sustituye uart por usb tanto en build como en flash
y usa el conector ESP32C6. No mezcles consola USB y conector CH343.

## 5. Cargar RCP

Antes de montar el enlace entre placas, con la tercera C6 conectada por USB:

```bash
bash ~/IoT-Labs-DHR/lab5/tools/flash.sh RCP <PUERTO_RCP>
```

**No tiene prompt `uart:~$`.** No cargues este firmware en la placa del sensor
ni en el cliente. El tráfico Spinel del RCP va por UART1 GPIO4/5, no por el
monitor de comandos. La verificación funcional se realiza desde BR.

## 6. Cargar la S3 N16R8

Conecta el puerto **UART** de la S3 al PC; no uses su USB nativo para esperar
la consola de este perfil:

```bash
bash ~/IoT-Labs-DHR/lab5/tools/flash.sh BR <PUERTO_BR> N16R8
```

La compilación está configurada para 8 MB de PSRAM octal y un mapa conservador
de los primeros 8 MB de flash (la N16R8 tiene 16 MB físicos). No se confunde
PSRAM con flash. No cargues este binario en una ESP32-C6.

## 7. Cablear BR↔RCP sin alimentación

Desconecta ambas placas de USB antes de poner los jumpers:

| ESP32-S3 BR | ESP32-C6 RCP |
|---|---|
| GPIO5, TX | GPIO4, RX |
| GPIO4, RX | GPIO5, TX |
| GND | GND |

No conectes 3V3 ni 5 V entre BR y RCP: cada una se alimenta por su propio USB.
La UART Spinel trabaja a **460800 baudios**; sus pines no son los de la consola
UART0 a 115200. Mantén cortos los tres cables.

Al encender, alimenta el **RCP antes o al mismo tiempo que BR**, como exige el
SOP: una S3 encendida con RCP sin alimentar puede provocar alimentación por el
pin de señal y brownout. Mantén S y C alimentadas independientemente.

## 8. Primera verificación del conjunto

Abre el monitor de BR:

```bash
bash ~/IoT-Labs-DHR/lab5/tools/monitor.sh BR <PUERTO_BR>
```

Busca `Found 8MB PSRAM device` en el arranque. Luego:

```text
ot rcp version
ot version
```

`ot rcp version` debe responder con la versión de OpenThread del RCP y Done.
Si hay `Wait for response timeout`, revisa TX/RX cruzados, GND, alimentación
RCP y que efectivamente cargaste su imagen. No intentes arreglarlo cambiando
el dataset o las credenciales Wi-Fi.

Si no aparece detección de PSRAM o el arranque falla, conserva el primer error
y el arranque completo. No se declara lista la S3 solo porque el flasheo pasó.

**Enviar primero:** logs de build/carga, arranque BR, `ot rcp version`, `ot version`,
`soilsense stats` de S y correspondencia de placas/puertos. Solo entonces sigue
la [guía de red y ensayos](guia.md).
