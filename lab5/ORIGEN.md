# Origen y adaptaciones — Lab 5

Repositorio del curso: https://github.com/saacifuentesmu/4201327-iot_systems_design

Commit fuente: **ff6e6754d01e15bf405f0934d4a1100f007ead96**.
Revisión de Zephyr fijada por su setup: **2f0bc11264a8e72e214f3db0a3fa221eb022453a**.
La estructura actual usa `labs/` y `docs/`, no el antiguo directorio `en/`.

- `firmware/nodes/` proviene de `firmware/lab4_sensors/`, actualizado con SLAAC y TX 20 dBm.
- `firmware/rcp/` proviene de `firmware/lab5_rcp/`.
- `firmware/border_router/` proviene de `firmware/lab5_border_router/`.
- `tools/coap_client.py`, `dashboard_coap.py` y `coaps.py` se conservan del curso. La última es dependencia de sus modos DTLS futuros; aquí se usa CoAP sin `--psk`, no se declara Lab 6 implementado.
- [Guía original](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ff6e6754d01e15bf405f0934d4a1100f007ead96/labs/lab5.md).
- [SOP original](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ff6e6754d01e15bf405f0934d4a1100f007ead96/labs/sops/sop05_border_router.md).
- [Setup original](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ff6e6754d01e15bf405f0934d4a1100f007ead96/docs/setup.md).

Adaptaciones locales:

1. Firmware C/S separado del Lab 4 anterior; DS18B20 explícito para S y modo sin sensor para C. Flash C6 a 4 MB y LED GPIO8 del montaje usado antes.
2. Callback de rol independiente de LED listo y guarda antes de acceder al driver, como en Lab 4. Resta del ruido simulado con signo explícito.
3. Shell C/S sin colores. RCP sin shell, de acuerdo con el firmware del curso.
4. N16R8 confirmada por el usuario; PSRAM de 8 MB octal del perfil original. Se usa mapa de flash de 8 MB, compatible también con los 16 MB físicos de N16R8.
5. Scripts con builds separados por rol/perfil/consola; comprobación de revisión, configuración, marcador y hash de imagen antes de cargar.
6. Workspace aislado `~/zephyrproject-lab5`, sin checkout automático en `~/zephyrproject`; venv de host local ignorado por Git.
7. Guías en español para WSL, UART, rutas IPv6, evidencia y restauración después de reset.

Se conservan las tres correcciones originales del Border Router: elección de
siguiente salto OMR antes de tener SLAAC, delegación de seguridad TX al host y
salida con descubrimiento de vecinos en Wi-Fi. No se elimina cifrado Thread:
la corrección TX cambia qué componente hace el trabajo, según el código fuente.
Estas correcciones dependen de interfaces de Zephyr y motivan fijar su revisión.

El BR usa `CONFIG_OPENTHREAD_SETTINGS_RAM=y` para Lab 5. No se activa el perfil
de autostart del Lab 8: tras un reinicio hay que restaurar localmente el dataset
y reconectar Wi-Fi. No se incluye el dataset ni credenciales en este repo.

Este entorno de preparación no tiene SDK/USB para compilar y cargar el hardware.
Se verifican herramientas y documentación por separado de la validación física.
Los ejemplos numéricos de las guías del curso no se copian como resultados propios.
