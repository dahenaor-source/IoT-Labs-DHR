# Evidencia — Lab 3 CoAP, C/S

**Cierre:** laboratorio finalizado por decisión de los integrantes, con las
limitaciones de medición y trazabilidad documentadas.

**Resultados:** C y S operativos con consola UART/CH343; red formada y GET de
temperatura/CBOR validados. Ventana Observe de 300 s registrada en S y recepción
contrastada en C y cancelación confirmada. Válvula funcional y timeout CON
confirmados; timeout CON de aproximadamente 92 s y NON sin mensaje adicional
reportado. Reconexión de S, CON posterior y latencia SED a 1/5/15 s validados;
PUT con SED a 5 s documentado. Restauración rdn, válvula cerrada y apagado de Thread/interfaz en ambas placas confirmados. Análisis, ADR y estimación de energía completos en el [informe](../INFORME.md); GET temporizado mediante video; integrantes, fecha indicada y condiciones de separación registrados.

## Sesión

- Fecha de sesión indicada por los integrantes: **2026-10-15** (ocho días antes de 2026-10-23, según su instrucción).
- Integrantes: **Ismael Cortes Ramirez** y **David Henao Rojas**.
- Lugar: no informado.
- C y S: **ESP32-C6**, consola UART mediante CH343. La capacidad física de flash y la asignación definitiva de puertos no quedaron registradas; firmware configurado a 4 MB.
- Zephyr observado en los logs: **v4.4.0-13610-g4564d775ab0b**. Commit IoT exacto cargado: no registrado.
- Potencia/canal reales C/S: 0 dBm / canal 25, confirmados por las consolas.
- Separación aproximada entre placas: **2 metros**, **sin obstáculos**, según los integrantes. Orientación no registrada.
- El video aportado se llama `2026-10-22 20-35-56.mp4`; se conserva ese nombre de origen y se distingue de la fecha de sesión indicada, sin inferir que todas las evidencias se capturaron el mismo día.
- Dataset compartido solo localmente y excluido de evidencias.

## Build, carga y red

| Actividad | Archivo | Resultado |
|---|---|---|
| Build USB | [Registro recibido](archivos/flash-C-usb-arranque-pendiente.txt) | Imagen disponible y cargada; CONFIG_FLASH_SIZE=4096, consola y shell en usb_serial |
| Flash C USB | [Carga y arranque](archivos/flash-C-usb-arranque-pendiente.txt) | 602352 bytes en 0x00000000, hash de escritura verificado; sin salida Zephyr después de entry 0x40800294 |
| Flash S | [GET C/S](archivos/get-env-temp-C-S.txt) | Ejecución y comunicación verificadas; no se aportó log exitoso de flash S |

### Incidencia de arranque en C

El registro confirma escritura y verificación por esptool 5.3.1. Al reiniciar,
la ROM muestra un aviso SHA-256 y continúa hasta entry 0x40800294, sin salida
posterior de Zephyr. Este aviso también estuvo presente en arranques anteriores
que funcionaron; por sí solo no establece la causa del problema actual.
El usuario confirmó que observaba por CH343 mientras la imagen estaba configurada
para USB nativo. La versión UART posterior arrancó en C con Zephyr
v4.4.0-13610-g4564d775ab0b y los recursos CoAP listos. La comunicación C/S se
validó posteriormente con el [GET correcto](archivos/get-env-temp-C-S.txt).
El registro de la primera carga USB se conserva como historial de la incidencia.

| Placa | Rol inicial | ML-EID | Canal | TX (dBm) | Evidencia |
|---|---|---|---|---|---|
| C | leader | fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b | 25 | 0 | [Resumen](archivos/red-C-S-resumen.txt) |
| S | child, después router | fd2c:525a:8ff2:2258:9966:43d2:59a9:c435 | 25 | 0 | [Resumen](archivos/red-C-S-resumen.txt) |

## GET temporizado por video posterior

Tres solicitudes nuevas en C presentan intervalos visibles de ≈50, 17 y 67 ms,
promedio ≈44 ms. Se mide desde el primer salto de línea visible tras el comando
hasta la respuesta/payload; resolución 60 fps (16.667 ms/fotograma), con margen
de lectura conservador ±2 fotogramas en la diferencia. Incluye efectos de
consola/USB/captura y no mide el RTT RF aislado ni el Enter físico.
[Video, fotogramas y método](archivos/GET-video-metodo-y-transcripcion.md),
[CSV](GET-video-tiempos.csv). Los payloads coinciden con los logs S de 2.05,
request 15 B y response CoAP 17 B. El timeout que ya figura en el historial
no se toma como una de estas tres repeticiones.

## Contratos de aplicación — ASD

| Recurso | Métodos | Request | Respuesta | Content-Format |
|---|---|---|---|---|
| /env/temp | GET, GET+Observe | Sin payload | CBOR {t: float16}, 6 B, 2.05 | 60 |
| /act/valve | PUT, GET | PUT CBOR {v:0/1}, o texto 0/1 sin Content-Format | CBOR {v:0/1}, 4 B; 2.04 PUT, 2.05 GET, 4.00 inválido | 60 en respuesta |

CDDL:

```text
env-reading = { t: float16 }
valve-state = { v: 0 / 1 }
```

Temperatura simulada; Max-Age 60 s; Observe con cambios >0.5 °C como NON y
heartbeat tras 45 s sin notificar como CON. Válvula simulada mediante LED blanco.

## GET y decodificación

- Hexadecimal recibido: `a16174f94e63` (6 bytes), confirmado en el log S; la salida C contenía un prefijo de consola no hexadecimal.
- Decodificación: A1 = mapa de un par; 61 74 = clave t; F9 4E 63 = float16 de 25.546875 °C. El helper confirmó el valor. El log S muestra 25.54 °C antes de cuantizar a float16.
- Tiempo GET ida/vuelta, método y resolución: pendiente.
- Request/response CoAP bytes del log S: 15 B / 17 B; código 2.05.
- Evidencias C/S: [GET y decodificación](archivos/get-env-temp-C-S.txt).

## Observe — cinco minutos

| Duración | Threshold inicio/fin/delta | Heartbeat inicio/fin/delta | Total notificaciones | GET a 1 Hz | Ratio 300/total |
|---|---|---|---|---|---|
| 300 s, ventana extraída del log S | 0/29/29 (inicio inferido del primer contador 1) | 0/0/0 | 29 generadas por S y registradas en C | 300 | ≈10.34 |

- Evidencia de S: [log original](archivos/observe-S-registro.txt), con 36 notificaciones completas y final truncado. No contiene cancelación ni la recepción en C.
- Suscripción aceptada en S a 00:11:34.006; ventana analizada hasta 00:16:34.006 (300 s).
- Las primeras 29 notificaciones caen en la ventana; la 29 aparece a 00:16:31.116 y la 30 a 00:16:36.122, fuera de ella.
- Todas son threshold/NON, de 19 B CoAP y 6 B CBOR incluidos en ese total. Total de notificaciones CoAP en la ventana: 551 B, sin sumar UDP/IPv6/MAC ni el registro inicial.
- Registro Observe inicial: request 16 B y response 19 B (incluye Observe); se distingue del GET normal de 15/17 B.
- Los 300 GET hipotéticos de polling son referencia; 300/29 ≈10.34 compara consultas con notificaciones, no consumo energético ni total de paquetes RF.
- Heartbeat 0 es coherente con cambios frecuentes; no hubo un intervalo de 45 s sin notificar dentro de la ventana.
- Recepción C: [transcripción estructurada](archivos/observe-C-recepcion.txt). OBS=2 es la respuesta inicial; OBS=3..40 son 38 notificaciones consecutivas. Las 29 de la ventana de 300 s corresponden a OBS=3..31; la correspondencia temporal se establece con el log S, porque C no incluye timestamps.
- No hay saltos en las secuencias aportadas; esto documenta la recepción de esa muestra, sin convertirla en una medición formal de PER ni de consumo.
- Cancelación posterior confirmada: C ejecutó `ot coap cancel` y S registró `(cancel)` con 2.05 a 00:29:47.864. [Evidencia](archivos/cancelacion-observe-y-timeout-CON.txt).

Conteo de notificaciones distinto de paquetes de radio: heartbeat CON puede
incluir ACK/reintentos. La suscripción completa duró 1093.858 s según los
timestamps de registro/cancelación en S; solo se usa la ventana inicial de 300 s
para la comparación.

## Válvula, idempotencia y rechazo

| Comando | Código/payload real | Log S | Estado LED | Evidencia |
|---|---|---|---|---|
| PUT CON 1 | 2.04; a1617601 = {v:1} | OPEN a 00:23:21.060 | No documentado | [C](archivos/valvula-C-apertura-repeticiones-rechazo.txt), [S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) |
| GET (dos consultas) | 2.05; a1617601 = {v:1} | OPEN a 00:24:00.447 y 00:25:01.146 | No documentado | [S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) |
| PUT CON 1 repetido (dos) | 2.04; a1617601 = {v:1} | OPEN, no change a 00:24:21.582 y 00:24:48.419 | No documentado | [S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) |
| PUT CON 0 + GET | 2.04 y 2.05; a1617600 = {v:0} | CLOSED a 00:27:11.060 (PUT) y 00:27:22.263 (GET) | No documentado | [C/S](archivos/valvula-C-S-cierre.txt) |
| PUT CON 7 | 4.00 según S; respuesta sin payload en C | Rechazo a 00:25:08.200 | No documentado | [C](archivos/valvula-C-apertura-repeticiones-rechazo.txt), [S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) |

- Cierre confirmado en la secuencia posterior: PUT 0 con 2.04 y GET cerrado con 2.05. Apertura/cierre, idempotencia y rechazo quedan documentados; no se aportó verificación visual del LED.
- Los comandos CoAP ejecutados localmente en S devolvieron InvalidState porque su cliente no está iniciado; los ensayos se ejecutan desde C. No iniciar el cliente en S para resolver ese error.
- Observe siguió activo durante la prueba de válvula y se canceló después, antes de detener Thread en S.

## CON/NON con servidor detenido

| Mensaje | Condición | Resultado | Tiempo/ventana observada | Evidencia |
|---|---|---|---|---|
| CON | S thread stop; rol disabled | Error 28: ResponseTimeout | ≈92 s (1:32), aclaración posterior del usuario | [C/S](archivos/cancelacion-observe-y-timeout-CON.txt) |
| NON | S detenida | Solo Done; sin respuesta ni error adicional reportado | Ventana solicitada 120 s; usuario confirmó ausencia de mensaje, sin timestamps propios | [C](archivos/NON-servidor-detenido.txt) |
| CON posterior | S reincorporada como child; misma ML-EID | 2.04, OPEN; a1617601 = {v:1} | RTT no medido | [C/S](archivos/reconexion-S-y-CON-posterior.txt) |

Con los parámetros por defecto descritos en la guía (espera inicial 2–3 s y cuatro retransmisiones), la suma de esperas es 31 veces la inicial: aproximadamente 62–93 s. El usuario reportó ≈92 s; es compatible con ese intervalo, sin verificar los intervalos internos mediante captura de paquetes.

## SED y latencia

- En la medición de 1000 ms, S confirmó mode `-`, pollperiod 1000 y state child después de una transición detached→child. Padre reportado: extaddr 52430823735468ed, RLOC a400, LQ In/Out 3/3. [C/S](archivos/SED-1000ms-C-S.txt).
- Comando: ot ping <S-mleid> 16 10 1.3 64 40.

| Poll period (ms) | Rol/padre verificados | Enviados/recibidos | Pérdida (%) | RTT min/avg/max (ms) | Fracción ideal de sondeo (10 ms/T) |
|---|---|---|---|---|---|
| 1000 | mode -; child; padre a400, LQ 3/3 | 10/10 | 0.0 | 16/465.600/916 | 1 % |
| 5000 | child; mismo padre a400, LQ 3/3 | 10/10 | 0.0 | 196/2119.000/4039 | 0.2 % |
| 15000 | child; mismo padre a400, LQ 3/3 | 10/10 | 0.0 | 757/8488.900/14461 | ≈0.0667 % |

Las fracciones son cálculos con la hipótesis de 10 ms por sondeo, no medidas de
radio/consumo. En los tres ensayos se recibieron 10/10 pings. Los RTT promedio
fueron 465.600, 2119.000 y 8488.900 ms al aumentar el periodo de sondeo; los
datos de padre y LQ permanecieron consistentes. Los resultados documentan la
latencia en estos ensayos, sin convertir las fracciones teóricas en consumo medido.

## PUT con SED a cinco segundos

- C envió una orden `PUT act/valve con 1` y recibió `a1617601` ({v:1}). [Evidencia C/S](archivos/PUT-SED-5000ms-C-S.txt).
- S confirmó pollperiod 5000 y child; recibió PUT a 00:47:57.877 (OPEN) y 00:47:58.008 (OPEN, no change), ambos 2.04. Diferencia: 131 ms. Cada intercambio reportó 18 B request y 13 B response CoAP.
- Dos entregas a la aplicación para una orden son compatibles con reintentos CON antes del siguiente sondeo de 5 s, frente a espera inicial CoAP de 2–3 s. La orden de fijar estado abierto es idempotente: la repetición no invierte la válvula. Un toggle repetido podría deshacer la acción. Los logs no incluyen Message ID/captura RF para contar retransmisiones físicas o deducir toda la política de deduplicación.

## Restauración y cierre final

S confirmó `ot mode rdn`; tras una transición detached→child volvió a atender
PUT y GET. El PUT final cerró la válvula (2.04) y el GET confirmó CLOSED (2.05),
ambos con CBOR `a1617600` = {v:0}. [Consolas C/S](archivos/restauracion-rdn-y-cierre-final-C-S.txt).

`ot pollperiod 0` elimina el periodo manual; la consulta devolvió 236000 ms.
Este valor automático no indica que S siga como SED: `rdn` incluye receptor
activo en reposo (`r`). Referencia: [OpenThread, otLinkSetPollPeriod](https://openthread.io/reference/group/api-link-link#otlinksetpollperiod).
El apagado final quedó confirmado en ambos bloques: `ot thread stop` y
`ot ifconfig down` devolvieron Done, con rol disabled a 00:56:27.932 y
00:57:12.196, respectivamente. Los bloques recibidos no identifican C/S;
se conserva su orden sin asignación inferida. [Logs de apagado](archivos/apagado-final-ambas-placas.txt).

## Presupuesto de bytes

| Intercambio | Request CoAP B | Response/notify CoAP B | Paquetes básicos | Evidencia |
|---|---|---|---|---|
| GET /env/temp | 15 | 17 | 2 según intercambio de aplicación, sin captura RF | [GET](archivos/get-env-temp-C-S.txt) |
| Observe NON | — | 19 | 1 datagrama previsto, sin captura RF | [S](archivos/observe-S-registro.txt) |
| PUT /act/valve CON válido | 18 | 13 (incluye CBOR 4 B) | 2 con ACK piggyback, sin captura RF | [S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) |
| GET /act/valve | 16 | 13 (incluye CBOR 4 B) | 2 previstos, sin captura RF | [S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) |

Los totales CoAP incluyen el CBOR. El [informe, sección 5](../INFORME.md#5-presupuesto-de-bytes-y-trama)
añade UDP, compara las referencias HTTP/MQTT del curso y comprueba el ajuste a
trama bajo hipótesis explícitas, sin afirmar una captura RF.

## Energía — estimación

Modelo completo, fuentes y límites en el [informe, sección 6](../INFORME.md#6-energía-y-autonomía-ideal-estimada).
ESP32-C6 datasheet v1.5: RX 802.15.4 74 mA (tabla 5-9) y light-sleep
0.180 mA (tabla 5-11). Se supone 10 ms activos por sondeo y dos AA en serie
con capacidad útil ideal de 3000 mAh. No se midió ni verificó light-sleep del SoC.

| Periodo | Corriente estimada mA | Vida ideal días |
|---|---:|---:|
| 1 s | 0.918200 | 136.14 |
| 5 s | 0.327640 | 381.52 |
| 15 s | 0.229213 | 545.34 |

[Cálculo CSV](energia-estimada.csv), reproducible con
`python3 lab3/tools/estimate_energy.py`. No representa la autonomía de la DevKit
USB/LED, ni incluye consumo del actuador o pérdidas de alimentación.

## Decisiones, respuestas y seguridad

El [informe](../INFORME.md) completa ADR-003 (CoAP/CBOR), ADR-004 (sondeo de
5 s propuesto para respuesta de aproximadamente 5 s, pendiente de acuerdo
operativo), contratos/CDDL, preguntas de principios y mapeo ASD/SCD.

Distingue la reducción de mensajes respecto a polling a 1 Hz de una comparación
con GET cada 60 s: la segunda no demuestra ahorro en la muestra registrada.

Incluye diseño de cierre local a 60 s ante pérdida de CLOSE, como hipótesis
pendiente de ajuste con caudal/cultivo, y resumen de tres líneas para Edwin.
El cierre local propuesto no está implementado ni validado en este firmware.

## Índice y cierre

| Archivo | Qué demuestra |
|---|---|
| [GET C/S](archivos/get-env-temp-C-S.txt) | Primera lectura de temperatura, payload CBOR y tamaños |
| [Red C/S](archivos/red-C-S-resumen.txt) | Roles, ML-EID, canal y potencia, sin dataset |
| [Observe S](archivos/observe-S-registro.txt) | Notificaciones emitidas y ventana de 300 s |
| [Observe C](archivos/observe-C-recepcion.txt) | OBS=2 inicial y notificaciones OBS=3..40; cancelación documentada por separado |
| [Válvula C](archivos/valvula-C-apertura-repeticiones-rechazo.txt) | Apertura, repetición y respuesta al inválido; cierre documentado por separado |
| [Válvula S](archivos/valvula-S-apertura-repeticiones-rechazo.txt) | 2.04, 2.05, no change, 4.00 y bytes medidos |
| [Cierre C/S](archivos/valvula-C-S-cierre.txt) | PUT 0 y GET confirman CLOSED y CBOR {v:0} |
| [Cancelación y CON](archivos/cancelacion-observe-y-timeout-CON.txt) | Observe cancelado y timeout con S disabled; tiempo CON ≈92 s |
| [NON sin S](archivos/NON-servidor-detenido.txt) | Solicitud NON y confirmación del usuario de ausencia de mensaje adicional |
| [Reconexión y CON](archivos/reconexion-S-y-CON-posterior.txt) | S child con ML-EID conservada; PUT posterior confirmado con 2.04 |
| [SED 1000 ms](archivos/SED-1000ms-C-S.txt) | Modo, sondeo, padre y 10/10 pings; RTT 16/465.600/916 ms |
| [SED 5000 ms](archivos/SED-5000ms-C-S.txt) | Sondeo y padre confirmados; 10/10 pings, RTT 196/2119.000/4039 ms |
| [SED 15000 ms](archivos/SED-15000ms-C-S.txt) | Sondeo y padre confirmados; 10/10 pings, RTT 757/8488.900/14461 ms |
| [PUT SED 5 s](archivos/PUT-SED-5000ms-C-S.txt) | Una orden y dos entregas, segunda no change; separación de 131 ms |
| [Apagado final](archivos/apagado-final-ambas-placas.txt) | Thread disabled e interfaz apagada en ambos bloques recibidos |

- [x] Restaurar S: mode rdn y pollperiod 0.
- [x] Cerrar y consultar válvula.
- [x] Detener Thread y bajar interfaz en ambas.
- [x] Vincular las transcripciones y el informe; no se archiva el dataset compartido localmente.
- [x] Completar análisis, estimación, ADR y diseño de cierre local.
- [x] Documentar tiempo observado del GET mediante tres repeticiones en video, con límites de precisión.
- [x] Registrar integrantes, fecha indicada, modelo, distancia y ausencia de obstáculos.
- Lugar, orientación, capacidad física de flash y commit exacto cargado: no informados.
