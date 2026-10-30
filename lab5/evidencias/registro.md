# Registro experimental — Lab 5 Border Router

Estado: evidencias cerradas por solicitud del equipo. Cuatro firmwares cargados;
conectividad, CoAP, NAT64, dashboard y continuidad interna probados. Acceso PC
recuperado tras restaurar BR. Las limitaciones de documentación se conservan.

## Procedencia

Transcripción y resumen de salidas proporcionadas en el chat. Las confirmaciones
verbales se distinguen de logs. No son archivos de captura descargados de las
placas. Fecha exacta de ejecución y condiciones físicas por confirmar; las
fechas de compilación no se usan como fecha del ensayo. No se guardan claves,
dataset, SSID ni BSSID. Integrantes del proyecto: Ismael Cortes Ramirez y David
Henao Rojas.

## Montaje y firmware verificados

- Zephyr: `2f0bc11264a8`; workspace WSL `~/zephyrproject-lab5`.
- S: ESP32-C6, DS18B20 DATA GPIO18, 3V3, resistencia pull-up 4,7 kΩ.
  Arranque real DS18B20; primer ensayo 25,44 °C, 4/4 lecturas correctas.
  Posteriormente 980 lecturas, 2 fallidas (0,2 % mostrado), 0 rechazadas,
  última 22,56 °C, conversión min/media/max 760203/760702/779665 µs.
- C: ESP32-C6 sin sensor; compilación inicial UART y posterior preparación de
  consola USB. Log inicial `simulated`; rol child y luego router. Modalidad
  final de consola no comprobada mediante .config recibido.
- RCP: tercera ESP32-C6; escritura verificada por esptool. Sin shell propia.
- BR: ESP32-S3 N16R8; flash física 16 MB, imagen/mapa 8 MB;
  arranque `Found 8MB PSRAM device`, octal 40 MHz.
- UART Spinel: S3 GPIO5 TX → C6 GPIO4 RX, S3 GPIO4 RX ← C6 GPIO5 TX,
  GND común, alimentaciones USB separadas. Comunicación confirmada por CLI.
- `ot rcp version`: `OPENTHREAD/e4d97681c; Zephyr; Oct 29 2026 18:44:09`.
- `ot version`: `OPENTHREAD/e4d97681c; Zephyr; Oct 29 2026 19:19:31`.
- Canal Thread 25 confirmado; potencia 0 dBm confirmada por el usuario al cierre.
  No se recibió la salida de txpower ni desglose por placa.
- Errores iniciales: sensor no conectado, puertos incorrectos/USB no adjunto,
  comprobación FLASH_SIZE S3 corregida. Carga S3 final verificada por hash.
  Aviso SHA-256 del arranque presente; no se declara solucionado.

## Red y ruta del PC

BR inicialmente leader; tras reinicio y restauración del mismo dataset, router.
`ot br state`: running. `ot nat64 state`: PrefixManager Active, Translator Active.
S y C conservan comunicación durante la ausencia del BR.

| Identificador | Valor observado |
|---|---|
| BR IPv4 Wi-Fi | 192.168.1.13 |
| BR link-local Wi-Fi | fe80::e272:a1ff:fef3:d56c |
| Prefijo OMR Local/Favored | fd8e:2e9b:4aee:1::/64 |
| Prefijo NAT64 | fd8e:2e9b:4aee:2:0:0::/96 |
| S ML-EID | fd75:5f32:e98c:5fb6:a81c:f3d:1e07:2a8b |
| S OMR | fd8e:2e9b:4aee:1:8aeb:e61e:3856:2f91 |
| C ML-EID | fd75:5f32:e98c:5fb6:9966:43d2:59a9:c435 |

Host de medición: Windows, Python 3.11.9; WSL utilizado para firmware.
Wi-Fi 2,4 GHz WPA2, canal 6; interfaz Windows Wi-Fi índice 3.
Ruta manual temporal ActiveStore confirmada:

```powershell
New-NetRoute -DestinationPrefix "fd8e:2e9b:4aee:1::/64" -InterfaceIndex 3 -NextHop "fe80::e272:a1ff:fef3:d56c" -PolicyStore ActiveStore
```

El primer ping OMR daba error general; tras verificar la ruta respondió 4/4.
No se atribuye conectividad IPv6 a WSL. Direcciones OMR ULA, no IPv6 públicas.

## Mediciones recibidas

Todos los pings de la tabla usan payload solicitado de 32 B. Windows muestra
32 B; OpenThread muestra 40 B incluyendo la cabecera ICMPv6. Predicciones previas
no aportadas; no se reconstruyen después de medir.

| Trayecto | N enviados/recibidos | Pérdida | RTT mín./medio/máx. (ms) |
|---|---:|---:|---|
| PC → BR, IPv6 link-local, inicial | 4/4 | 0 % | 28 / 214 / 437 |
| PC → S OMR, inicial | 4/4 | 0 % | 60 / 248 / 517 |
| PC → BR, IPv6 link-local, posterior | 10/10 | 0 % | 4 / 8 / 17 |
| PC → S OMR, posterior | 10/10 | 0 % | 28 / 32 / 39 |
| C → S ML-EID | 10/10 | 0 % | 13 / 13,300 / 14 |
| S → 8.8.8.8 mediante NAT64 | 10/10 | 0 % | 48 / 53,000 / 61 |

Muestras RTT (ms), conservadas del chat:

- PC→BR posterior: 12, 5, 7, 17, 6, 9, 4, 4, 6, 10.
- PC→S posterior: 31, 38, 32, 39, 30, 28, 30, 32, 31, 30.
- C→S: 14, 14, 13, 13, 13, 13, 13, 13, 14, 13.
- NAT64: 53, 49, 48, 56, 48, 59, 59, 61, 49, 48.

La serie posterior se pidió después de `wifi ps off`, pero no se recibió la
salida ni confirmación explícita de ese comando: estado de ahorro pendiente de
verificar. Las series iniciales son de cuatro muestras, no diez. PC→BR se midió
en IPv6, no la serie IPv4 propuesta en la guía. Las medias de Windows están
truncadas; a partir de muestras, BR=8,0 ms y S=32,1 ms. Su diferencia es 24,1 ms
(24 ms usando resúmenes), indicador de recorridos distintos, no tiempo exclusivo
de procesamiento del BR. No equivale a medición de consumo energético.

NAT64 sintetizó `fd8e:2e9b:4aee:2:0:0:808:808`. El comando `ot nat64 state`
en S dio InvalidCommand; el traductor está en BR y el ping sí funcionó.

## CoAP PC → S

```powershell
.\.venv\Scripts\python.exe coap_client.py --host fd8e:2e9b:4aee:1:8aeb:e61e:3856:2f91 --count 10 get /env/temp
```

10/10 respuestas `2.05 Content`. RTT mostrados: 32, 30, 33, 43, 33, 49, 32,
34, 38, 31 ms. Cliente informa mediana 33 ms, mínimo 30 y máximo 49 ms.
Primer payload CBOR `a16174f94d98`, `{'t': 22.375}` °C, 6 B.
Cumple mediana <200 ms. Dentro de Thread también se recibió `a16174f94dac`
(22,6875 °C) desde C.

## Dashboard

Capturas aportadas en chat: una con `NetworkError` tras dos notificaciones y
otra posterior `Connected`, tres notificaciones, último CBOR `a16174f94d94`
(22,3125 °C), 6 B. Causa del error transitorio no identificada.
Usuario confirma funcionamiento de Open/Close y LED. No se aportaron logs de
PUT correspondientes. Al cierre, el usuario confirmó funcionamiento del
dashboard desde el celular; confirmación verbal, sin captura móvil original archivada.
Las capturas están en el chat; no se declara que sus PNG estén guardados en Git.

## BR apagado y retorno

- Usuario desconectó BR/RCP manteniendo S/C encendidos.
- PC ejecutó GET OMR y obtuvo `[1] Error: Network error: NetworkError`.
- Usuario confirmó que desde C el LED de S enciende y apaga sin BR.
  Salidas GET/PUT de C y tiempos de esta fase aún no recibidos; no se inventan
  códigos de respuesta ni GET exitoso interno en esa fase.
- Tras volver a conectar y resolver attach/puerto S3 (`/dev/ttyACM5` en ese
  momento), el usuario confirmó que vuelve el acceso del PC. No se recibió
  inicialmente salida del GET de retorno. Posteriormente aportó `2.05 Content`
  y `Payload: {"temperature": 23.5}`: [transcripción](archivos/10-recuperacion-PC.txt).
  Esta salida difiere del cliente anterior (que mostraba CBOR y RTT); no permite
  verificar el formato de transmisión ni la revisión del cliente utilizada.
  Temperatura reportada 23,5 °C; tiempo de recuperación no medido.
- BR usa ajustes RAM: reiniciar exigió restaurar Wi-Fi y el mismo dataset.
  No se afirma reconexión autónoma ni persistencia del dataset en BR.

## Cierre y límites de la evidencia

El usuario solicitó cerrar las evidencias y confirmó dashboard desde celular y
potencia 0 dBm. Esto cierra la documentación disponible; no certifica que se
haya ejecutado un apagado físico de las placas.

- CoAP directo, NAT64, ping y retorno PC: resultados recibidos y registrados.
- Actuación local sin BR y dashboard móvil: confirmados por el usuario.
- Foto de montaje, originales de capturas/videos y logs completos de build/flash:
  no incorporados; se conservan transcripciones/resúmenes del chat.
- Fecha exacta/condiciones físicas y desglose txpower por placa: no documentados.
- wifi ps off: sin salida o confirmación; series iniciales de cuatro muestras y
  posteriores de diez, sin afirmar comparación experimental homogénea.
- GET/PUT de C durante corte: sin transcripción; no se midió recuperación.
- Cierre final de válvula/GET y apagado físico: no confirmados.
- No se declara DTLS, autorización de actuadores ni válvula real: control probado
  mediante LED. La salida a Internet de NAT64 es una prueba adicional; el control
  interno C→S continúa sin BR y no necesita un servicio de nube.

Conclusión: la arquitectura conecta el sensor Thread a Windows y al dashboard
móvil mediante BR, y preserva actuación interna durante su ausencia. La
restauración del BR fue manual con el mismo dataset; no se probó recuperación
autónoma. Véase [informe](../INFORME.md).
