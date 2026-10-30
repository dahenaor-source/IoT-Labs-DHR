# Lab 5 — Border Router con ESP32-S3 N16R8 y ESP32-C6

**Estado:** laboratorio y evidencias cerrados por solicitud del equipo; cuatro imágenes cargadas; CoAP PC→S 10/10 (mediana 33 ms),
NAT64 10/10 y control C→S sin BR confirmados. Acceso PC recuperado tras restaurar
BR según confirmación del usuario. Dashboard móvil y potencia 0 dBm confirmados. Ver [informe](INFORME.md) y
[resultados y límites](evidencias/registro.md).

[Guía completa](guia.md) · [Carga por placa](CARGA_FIRMWARE.md) ·
[Evidencias](EVIDENCIAS.md) · [Registro](evidencias/registro.md) · [Origen](ORIGEN.md)

| Etiqueta física | Placa | Función | Imagen |
|---|---|---|---|
| S | ESP32-C6 + DS18B20 en GPIO18 | Sensor/servidor CoAP, obtiene dirección OMR | `firmware/nodes` + DS18B20 |
| C | ESP32-C6 | Cliente CoAP dentro de Thread, sin sensor | `firmware/nodes`, sin overlay de sensor |
| RCP | Tercera ESP32-C6 | Radio 802.15.4 controlada por Spinel/UART | `firmware/rcp` |
| BR | ESP32-S3 N16R8, confirmada por el usuario | Wi-Fi + Border Router + NAT64 | `firmware/border_router` |

Son **tres ESP32-C6 y una ESP32-S3**, cuatro placas en total. La disponibilidad
física de la tercera C6 se comprueba antes del montaje; no se reemplaza C o S
con el RCP durante los ensayos que requieren ambos extremos.

Se usa UART/CH343 para C6 y el conector UART de S3. El RCP no tiene shell.
La S3 usa PSRAM octal de 8 MB; la imagen usa los primeros 8 MB de flash de la
N16R8. Los C6 usan un mapa de 4 MB. Se conservan por separado los Labs 0–4.

## Primer paso en WSL

La revisión de Zephyr usada antes (`4564d775ab0b`) difiere de la fijada por el
curso actual (`2f0bc11264a8e72e214f3db0a3fa221eb022453a`). Para no cambiar el
workspace anterior, se prepara uno nuevo en **`~/zephyrproject-lab5`**:

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab5/tools/prepare_workspace.sh
```

Descarga Zephyr, módulos, blobs y compiladores RISC-V y Xtensa; puede tardar y
ocupar varios GB. Se necesitan las dependencias del sistema de Zephyr ya usadas
en WSL, conexión a Internet y Python con venv. No se ejecuta checkout en
`~/zephyrproject`. Si encuentra otra revisión en la ruta seleccionada, se detiene.

## Compilar las cuatro imágenes

```bash
cd ~/IoT-Labs-DHR
bash lab5/tools/build.sh S uart
bash lab5/tools/build.sh C uart
bash lab5/tools/build.sh RCP
bash lab5/tools/build.sh BR N16R8
```

Los builds y sus marcadores van a directorios distintos dentro del workspace
nuevo. Los logs se guardan en `lab5/evidencias/archivos/`.
Los scripts verifican revisión y configuración, pero no pueden demostrar la
capacidad física de PSRAM antes del arranque.

**No uses puertos de ejemplo sin identificar las placas.** La carga paso a paso,
el cableado UART, las verificaciones y la secuencia de alimentación están en
[CARGA_FIRMWARE.md](CARGA_FIRMWARE.md).

## Cliente y dashboard del PC

```bash
bash ~/IoT-Labs-DHR/lab5/tools/setup_host.sh
source ~/IoT-Labs-DHR/lab5/.venv/bin/activate
```

Tras obtener una dirección OMR de S y una ruta IPv6 válida desde el PC:

```bash
python ~/IoT-Labs-DHR/lab5/tools/coap_client.py --host <S_OMR> --count 10 get /env/temp
python ~/IoT-Labs-DHR/lab5/tools/dashboard_coap.py --host <S_OMR>
```

En Windows/WSL, que funcione la carga USB no implica que WSL tenga acceso IPv6
al Wi-Fi: revisa el apartado específico de la [guía](guia.md). No se usa la
ML-EID para sustituir la dirección OMR desde la red externa.

No guardes el dataset Thread ni contraseñas Wi-Fi en Git. La carpeta `.local/`
se ignora, si necesitas archivos temporales de configuración local.
