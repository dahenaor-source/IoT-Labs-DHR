# Lab 3 — guía completa C/S

Usa [EVIDENCIAS.md](EVIDENCIAS.md) para saber exactamente qué copiar y
[evidencias/registro.md](evidencias/registro.md) para registrar los resultados.

## 1. Identificar y conectar las placas

Etiqueta una placa **C** y la otra **S**. C crea la red; S representa temperatura
simulada y válvula mediante el LED. Puedes usar un PC con dos terminales seriales,
o dos PCs; solo el que compila/carga necesita Zephyr. Los PCs no necesitan Wi-Fi
compartida. Mantén las placas cerca y con línea de visión despejada.

Usa el conector ESP32C6/USB nativo para los comandos `usb` siguientes.
Para CH343/UART cambia a `uart` al compilar y cargar, y abre el monitor en ese
conector. La consola es 115200, 8N1, sin control de flujo.

En PowerShell:

```powershell
usbipd list
```

Para cada placa que usarás desde WSL, sustituye el BUSID de ejemplo:

```powershell
usbipd bind --busid 1-1
usbipd attach --wsl --busid 1-1
```

Bind requiere administrador. En WSL, identifica los puertos conectando una placa
a la vez; el número puede cambiar después de un reset:

```bash
ls -l /dev/ttyACM* /dev/ttyUSB* /dev/serial/by-id/* 2>/dev/null
```

Si hay permiso denegado, agrega el usuario a dialout y vuelve a iniciar sesión:

```bash
sudo usermod -aG dialout "$USER"
```

## 2. Compilar una vez

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab3/tools/build.sh usb
```

El script activa `~/zephyrproject/.venv`, compila desde ese workspace y guarda
`lab3/evidencias/archivos/build-usb.log`. Usa `ZEPHYR_WORKSPACE=/otra/ruta` si tu
instalación es distinta. La imagen queda en
`~/zephyrproject/build-iot-lab3-usb/zephyr/zephyr.bin`.

El target es esp32c6_devkitc/esp32c6/hpcore. El overlay suministrado configura
flash de 4 MB y RGB GPIO8. La consola USB se añade con EXTRA_DTC_OVERLAY_FILE.
El script comprueba CONFIG_FLASH_SIZE=4096. Las placas deben tener al menos 4 MB.
Para UART: `bash lab3/tools/build.sh uart`.

**Guardar:** log completo de compilación; si falla, envía el primer error y las
últimas líneas. No continúes al flash si el build falló.

## 3. Cargar C y S

Cierra el monitor. Con C sola conectada y su puerto verificado:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/flash.sh C /dev/ttyACM0 usb
```

Desconecta C, conecta S, vuelve a adjuntarla a WSL e identifica su puerto:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/flash.sh S /dev/ttyACM0 usb
```

Cambia el puerto si difiere. La misma imagen sirve para ambas; las letras
identifican los logs, no fijan roles. Si no sincroniza: cierra monitores, mantén
BOOT, pulsa RESET, suelta BOOT y reintenta.

**Guardar:** logs de carga C/S. Los scripts los crean en evidencias/archivos.

## 4. Abrir una consola por placa

Con ambas conectadas y verificando la asociación de puertos:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/monitor.sh C /dev/ttyACM0
```

En otra terminal:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/monitor.sh S /dev/ttyACM1
```

Pulsa Enter para el prompt. Sal con Ctrl+]. El arranque incluye `SoilSense node
ready` y los recursos /env/temp y /act/valve.

En otro PC sin Zephyr puedes usar PuTTY/Tera Term con el puerto COM, 115200,
8N1 y sin control de flujo. Si Windows abre el puerto, no debe estar adjuntado
a WSL (`usbipd detach --busid BUSID_REAL`).

## 5. Formar una red nueva

En ambas placas, una vez al comenzar:

```text
ot factoryreset
```

Se reinician; vuelve a abrir/adjuntar el USB si hace falta. No repitas este reset
entre pruebas: borra la red y puede cambiar las direcciones.

En **C**:

```text
ot txpower 0
ot txpower
ot dataset init new
ot dataset channel 25
ot dataset commit active
ot ifconfig up
ot thread start
ot state
```

Espera a leader. Obtén el dataset para S:

```text
ot dataset active -x
```

Copia el hexadecimal completo directamente a S. No lo incluyas en evidencias.
En **S**, reemplaza todo el marcador, sin < >:

```text
ot txpower 0
ot txpower
ot dataset set active <HEX_DE_C>
ot ifconfig up
ot thread start
ot state
```

Espera a que se una. Inicialmente puede ser child/router; documenta el estado.
En ambas:

```text
ot state
ot channel
ot txpower
ot ipaddr mleid
ot router table
```

Anota la ML-EID actual de S: será la dirección de todos los recursos. Si reinicias
la red, vuelve a obtenerla. En C:

```text
ot coap start
```

**Nunca ejecutes `ot coap start` en S:** su servidor Zephyr ya escucha en UDP5683.
Si lo ejecutaste por error, usa `ot coap stop` en S y vuelve a comprobar el GET.

**Enviar:** arranque y las salidas anteriores, identificadas C/S, sin dataset.

## 6. GET de temperatura y CBOR

Desde C:

```text
ot coap get <ML_EID_S> env/temp
```

El dato es simulado. Guarda la respuesta hexadecimal de C y en S la línea
`GET /env/temp ... CoAP ... B ... request ... B`. Mide además el tiempo desde
el envío hasta la respuesta con cronómetro/grabación; no supongas que la latencia
CoAP es el RTT del ping. Si la consola no imprime RTT CoAP, registra el método
y resolución de esa medición, sin inventar milisegundos.

En otra terminal WSL puedes comprobar la decodificación con el helper:

```bash
python3 ~/IoT-Labs-DHR/lab3/tools/decode_cbor.py a16174f94e20
```

Este ejemplo debe dar {"t": 24.5}; usa también tu payload real. El contrato tiene
seis bytes: A1 (mapa), 61 74 (clave t), F9 y dos bytes de float16. La válvula
responde con cuatro bytes A1 61 76 00/01. El helper acepta solo estos contratos.

**Enviar:** comando, respuesta C, log S, payload y resultado decodificado.

## 7. Observe durante cinco minutos

En C:

```text
ot coap observe <ML_EID_S> env/temp
```

Inicia un cronómetro y deja funcionar 300 s. Copia desde S todas las líneas
`notify (threshold, NON)` / `notify (heartbeat, CON)` y las líneas
`Observe notification: CoAP ... B` asociadas. Al terminar, en C:

```text
ot coap cancel
```

Los contadores threshold/heartbeat son acumulados desde el arranque: registra
valores iniciales y finales o conserva todas las líneas de la ventana. Si esta
no es la primera suscripción no asumas que empiezan en cero. Un heartbeat de
cero es un resultado válido si los cambios ya originaron notificaciones.

**Enviar:** hora/inicio/fin, duración, respuestas/notificaciones en C y logs S.
Calcularemos diferencias de contadores, total de notificaciones y comparación
con 300 GET de un poller a 1 Hz. La notificación NON es un datagrama; heartbeat
CON puede añadir ACK y reintentos: no confundas conteo de notificaciones con
conteo total de paquetes de radio.

## 8. Válvula: abrir, leer, cerrar y validar

Desde C, ejecuta una línea a la vez y espera respuesta:

```text
ot coap put <ML_EID_S> act/valve con 1
ot coap get <ML_EID_S> act/valve
ot coap put <ML_EID_S> act/valve con 1
ot coap put <ML_EID_S> act/valve con 0
ot coap get <ML_EID_S> act/valve
ot coap put <ML_EID_S> act/valve con 7
```

El segundo PUT 1, antes de cerrar, debe reportar `OPEN, no change` en S. El 7
es inválido y debe producir 4.00. El LED blanco representa abierto; no se acciona
una válvula física. Las respuestas correctas codifican {"v":1} o {"v":0}.

**Enviar:** toda la secuencia C y los logs S, incluidos OPEN/CLOSED, no change,
rechazo 4.00 y `/act/valve sizes: request ... response ... CBOR ...`.
Una foto o video del LED puede complementar las salidas.

## 9. CON frente a NON cuando S no está disponible

Asegúrate de cancelar Observe antes de esta prueba. En S:

```text
ot thread stop
```

Desde C inicia cronómetro y ejecuta:

```text
ot coap put <ML_EID_S> act/valve con 1
```

Espera a `ResponseTimeout` (error 28), sin iniciar otra solicitud mientras
está pendiente. Anota segundos desde el comando hasta el error. La guía propone
predecir el timeout: ventana inicial aleatoria 2–3 s y espera que se duplica con
cuatro retransmisiones; documenta la predicción y el valor observado.

Luego, en C:

```text
ot coap put <ML_EID_S> act/valve non-con 1
```

Espera 120 s y registra lo que ocurra, incluida la ausencia de respuesta/error.
En S vuelve a iniciar Thread:

```text
ot thread start
ot state
```

Espera la reincorporación, confirma su ML-EID y vuelve a probar desde C:

```text
ot coap put <ML_EID_S> act/valve con 1
ot coap put <ML_EID_S> act/valve con 0
```

**Enviar:** comandos, error y tiempo CON, resultado tras 120 s NON, estado S
y respuesta tras reconectarlo. Detener S intencionalmente no mide cobertura RF.

## 10. Convertir S en sleepy end device

En S:

```text
ot mode -
ot pollperiod 1000
ot mode
ot pollperiod
ot state
ot parent
ot ipaddr mleid
```

S debe quedar child y usar C como padre. Espera la transición y confirma el
estado antes de medir. La opción de radio rx-off-when-idle no demuestra por sí
sola corriente de sueño profundo de toda la placa: este firmware sigue ejecutando
sensor simulado, logs y LED.

## 11. RTT para periodos de 1, 5 y 15 s

Para cada periodo, primero configúralo en S y consulta el valor. Comienza con:

```text
ot pollperiod 1000
ot pollperiod
```

Desde C ejecuta el comando completo de la guía del curso:

```text
ot ping <ML_EID_S> 16 10 1.3 64 40
```

El timeout de 40 s supera el mayor periodo. Deja acabar el ping antes de seguir.
Repite cambiando en S el periodo a 5000, después a 15000 ms, y ejecutando el
mismo ping desde C cada vez.

**Enviar por cada periodo:** salida de pollperiod, state y parent en S; comando,
resumen de enviados/recibidos, pérdida y RTT min/avg/max en C. Identifica el
periodo junto al bloque para no mezclar resultados. Si pierde paquetes, guarda
la pérdida real.

## 12. PUT con S dormido a cinco segundos

En S:

```text
ot pollperiod 5000
```

Desde C:

```text
ot coap put <ML_EID_S> act/valve con 1
```

Copia todos los logs PUT de S hasta que C reciba la respuesta. Registra cuántos
PUT llegaron a la aplicación y cuáles dicen no change. No presupongas que serán
dos: la deduplicación CoAP y los tiempos pueden afectar lo observado.
Después envía CON 0 para cerrar y conserva sus logs.

**Enviar:** secuencia C, logs S con tiempos, cantidad de PUT observados y valor
de pollperiod. Analizaremos reintentos/idempotencia a partir de lo realmente visto.

## 13. Restaurar, cerrar y terminar

En S:

```text
ot mode rdn
ot pollperiod 0
```

`ot pollperiod 0` elimina el periodo manual. La consulta puede devolver un
periodo automático (en esta sesión, 236000 ms); con `rdn`, la `r` mantiene el
receptor activo en reposo.

Desde C confirma cerrado:

```text
ot coap put <ML_EID_S> act/valve con 0
ot coap get <ML_EID_S> act/valve
```

En ambas, después de guardar evidencias:

```text
ot thread stop
ot ifconfig down
```

## 14. Informe y presupuesto de bytes

Usaremos los logs de GET, Observe y PUT para completar solicitud/respuesta en
bytes de CoAP. Los bytes CBOR son la carga útil; no se suman otra vez a un total
CoAP que ya los incluye. UDP añade 8 bytes; el tamaño IPv6 comprimido depende del
contexto, y el ajuste a una trama debe distinguir la estimación de una captura RF.

Para energía se necesita citar corriente RX y sueño del ESP32-C6, capacidad AA
asumida y periodo elegido. Con tiempo de radio por sondeo de 10 ms:
fracción aproximada = 0.010 / periodo_en_segundos;
I_media = fracción*I_RX + (1-fracción)*I_sueño;
vida_horas = capacidad_mAh / I_media_mA, bajo esas hipótesis.
Es una estimación idealizada; no una medición de consumo de la DevKit con USB/LED.

Completar ADR-003 (CoAP/CBOR), ADR-004 (periodo), contratos/CDDL, preguntas,
resumen de Edwin y diseño de seguridad ante OPEN sin CLOSE. La política de
cierre autónomo se propone en el informe; el firmware de prácticas no incorpora
ese cierre automático.

## Problemas frecuentes

- No hay puerto: revisar cable, usbipd y enumeración tras reset.
- No hay prompt: comprobar build usb/uart y conector; Enter/RESET a 115200.
- No hay GET: verificar misma red, ML-EID actual de S y que solo C ejecutó coap start.
- CoAP no existe: confirmar que cargaste Lab 3, no Lab 2.
- SED sigue router: consultar mode/state y esperar la transición antes de medir.
- CBOR no decodifica: copiar solo el payload hexadecimal, sin prompt o texto adicional.
- Errores de build: enviar primer error y final del log, sin continuar al flash.
