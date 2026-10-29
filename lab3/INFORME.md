# Lab 3 — Informe y actualización del DDR

**Estado: finalizado por decisión de los integrantes.** El cierre conserva el
alcance, las estimaciones y las limitaciones de evidencia descritos aquí.

Este informe usa las pruebas de dos ESP32-C6, C (cliente/leader) y S
(servidor y posteriormente SED), en Thread, canal 25 y TX 0 dBm.
Las transcripciones y condiciones están en el [registro experimental](evidencias/registro.md).

**Integrantes:** Ismael Cortes Ramirez y David Henao Rojas.

**Fecha de sesión indicada:** 15 de octubre de 2026.

**Condiciones:** dos placas ESP32-C6, separadas aproximadamente 2 metros, sin obstáculos.
El lugar no fue informado. La fecha se registra por indicación de los integrantes;
el nombre original del video posterior es `2026-10-22 20-35-56.mp4` y se conserva
como procedencia de esa evidencia, sin atribuirle la fecha indicada de sesión.

La temperatura y la válvula son simuladas. Las corrientes y autonomías de este
informe son estimaciones; no se midió consumo eléctrico.

## 1. Resultados y alcance

| Ensayo | Resultado sustentado |
|---|---|
| GET temperatura | 2.05; CBOR `a16174f94e63`, 6 B, decodifica {t:25.546875 °C}; S imprime 25.54 °C antes de cuantizar |
| Observe, ventana 300 s | 29 notificaciones por umbral, 0 heartbeat; 551 B CoAP en notificaciones |
| Recepción Observe | Respuesta inicial OBS=2 y notificaciones OBS=3..40; cancelación confirmada posteriormente |
| Válvula | PUT abre/cierra con 2.04; GET verifica con 2.05; repetir OPEN deja OPEN; valor 7 rechazado con 4.00 |
| S ausente | CON termina en ResponseTimeout a ≈92 s, según cronometraje aproximado del usuario; NON solo imprime Done |
| Reconexión | S vuelve a child, conserva ML-EID y responde al PUT CON |
| SED | 10/10 pings recibidos en cada periodo 1/5/15 s; aumenta el RTT al aumentar el periodo |
| PUT a SED de 5 s | Dos entregas registradas con 131 ms de separación: OPEN y OPEN, no change |
| Cierre | Válvula CLOSED verificada, S restaurada a rdn y Thread/interfaz detenidos en ambas placas |

El GET inicial no fue cronometrado. Una grabación posterior de tres GET permite
estimar intervalos visibles de ≈50, 17 y 67 ms en C (promedio ≈44 ms). Se trata
del tiempo observado desde la consola, sin sustituirlo por el RTT ICMP ni
afirmar un RTT de red aislado. Véase el [método y video](evidencias/archivos/GET-video-metodo-y-transcripcion.md). No hay captura RF,
medición de batería ni comprobación del movimiento de una válvula real.
La espera NON fue confirmada sin mensajes adicionales, pero no se aportó una
medición propia de sus dos minutos de observación. Tampoco se conocen
el lugar ni el commit exacto cargado en las placas.

## 2. DDR §3 — Decisiones de arquitectura

### ADR-003 — CoAP y CBOR en el enlace Thread

**Estado:** adoptado para el prototipo de laboratorio.

**Problema.** El caso SoilSense requiere actualizar lecturas cuando cambian y
conocer el resultado de las órdenes, con mensajes pequeños sobre 802.15.4.

**Decisión.** Usar CoAP/UDP para los recursos y CBOR para sus representaciones.
Usar Observe con NON para cambios de temperatura y CON para heartbeat;
usar PUT CON para fijar el estado de válvula y GET para consultar el estado.
Conservar los contratos descritos en la sección 3.

**Evidencia.** El GET utiliza 15 B de solicitud y 17 B de respuesta CoAP;
una notificación usa 19 B; el PUT probado desde la CLI usa 18/13 B.
El contenido CBOR es de 6 B para temperatura y 4 B para válvula. El ensayo
confirma respuesta al mando, rechazo del inválido y timeout ante indisponibilidad.

**Alternativas.** HTTP/JSON conserva una interfaz conocida pero añade cabeceras
textuales y el costo de mantener o establecer TCP en su uso del Lab 0.
MQTT/JSON sigue siendo útil entre gateway y servicios, pero en el tramo radio
ensayado requeriría un broker accesible y gestionar una conexión TCP; confirmar
publicación al broker tampoco confirma por sí solo el estado de la válvula.
Los tamaños HTTP/MQTT de la sección 5 son referencias de la guía, no capturas
comparativas de esta sesión. HTTP/3 usa QUIC: la comparación aquí se limita al
HTTP/TCP de la práctica.

**Consecuencias.** Se evita necesitar un broker en este enlace y se selecciona
confirmación por mensaje. Hay que gestionar expiración, pérdida de notificaciones,
reintentos, idempotencia y autenticación en un despliegue real. Una respuesta de
aplicación confirma el estado software; la instalación real necesita realimentación
física para afirmar que la válvula se movió.

### ADR-004 — Sondeo de 5 s para la válvula a batería

**Estado:** propuesta de diseño basada en la práctica; pendiente de aceptación
por operación. La prueba terminó restaurando S a `rdn`, no dejándola como SED.

**Necesidad.** Edwin requiere saber si una orden llegó y evitar esperas de minutos.
Para concretar esa necesidad se propone como objetivo de diseño recibir respuesta
en aproximadamente 5 s en condiciones normales. Ese umbral es una hipótesis del
informe, no un requisito numérico entregado por Edwin ni una garantía validada.

**Decisión propuesta.** Sondeo de 5000 ms, con PUT idempotente CON, comprobación del
estado y cierre local temporizado. La tabla experimental arroja RTT promedio
2.119 s y máximo 4.039 s en diez pings. Ofrece menor espera que 15 s y una
fracción ideal de sondeo cinco veces menor que 1 s. La estimación de corriente
baja de 0.9182 a 0.32764 mA bajo las hipótesis de la sección 6.

**Alternativas y consecuencias.** Un segundo reduce la latencia observada, a costa
de más sondeos. Quince segundos reduce la corriente estimada, pero el RTT máximo
observado fue 14.461 s. Con 5 s puede comenzar un reintento CoAP antes del siguiente
sondeo; se observaron dos entregas a la aplicación. Diez pings no establecen un
límite de latencia del servicio, y un timeout CON puede tardar ≈92 s. Para aceptar
el objetivo de 5 s deben medirse también tiempos de órdenes CoAP en más condiciones
y acordar el tiempo requerido con operación.

## 3. DDR §4 — Contratos de aplicación e ISO/IEC 30141

| Propiedad | Temperatura | Válvula |
|---|---|---|
| URI | `/env/temp` | `/act/valve` |
| Métodos | GET y GET con Observe | PUT para fijar; GET para consultar |
| Solicitud | Sin payload | CBOR {v:0/1} con Content-Format 60; CLI permite texto 0/1 sin Content-Format |
| Respuesta | {t:float16}, °C; 6 B | {v:0/1}, 0=cerrada y 1=abierta; 4 B |
| Content-Format de respuesta | 60, application/cbor | 60, application/cbor |
| Códigos | 2.05 | 2.04 en PUT válido; 2.05 en GET; 4.00 en inválido |
| Política | Max-Age 60 s; cambio >0.5 °C notifica NON; tras 45 s sin notificar, heartbeat CON | PUT idempotente; repetir el valor no invierte el estado |

```cddl
env-reading = { t: float16 }
valve-state = { v: 0 / 1 }
```

`a1` declara un mapa de una pareja; `61 74` es la clave t; `f9 4e 63` es
el float16. `a1 61 76 00` representa {v:0} y `a1 61 76 01`, {v:1}.
El prefijo visual `uar` de algunas salidas no pertenece al CBOR.

Las URI, métodos, contratos y patrones Observe/CON forman la interfaz del
**ASD (Application & Service Domain)**. Thread, IPv6/UDP y el mecanismo de
sondeo al padre forman el subsistema de comunicación de los dispositivos del
**SCD (Sensing & Controlling Domain)**, según el mapeo del curso. La aplicación
CoAP está en el plano funcional; MLE mantiene la red y el parentesco en el plano
de gestión. Cambiar el sondeo no cambia la semántica de {v:0/1}.

## 4. DDR §5 — Respuestas de principios

**1. UDP, CON y NON.** UDP entrega datagramas sin establecer un flujo fiable.
CoAP agrega correlación, detección de duplicados y, en CON, confirmación y
retransmisiones acotadas. NON evita esas confirmaciones y reintentos CoAP, aunque
sigue pudiendo recibir una respuesta de aplicación. El Done inmediato significa
que la CLI aceptó el envío, no que S ejecutó la orden. HTTP sobre TCP delega la
entrega ordenada del flujo al transporte; eso tampoco prueba ejecución física.

**2. Observe y batería.** S conoce cuándo cambia su lectura y puede notificar sin
que C envíe consultas repetitivas. En 300 s se generaron 29 notificaciones,
frente a 300 consultas de un lector a 1 Hz: razón 300/29 ≈10.34. No es una razón
de consumo ni de paquetes RF: faltan solicitudes de registro, respuestas, ACK,
reintentos y mantenimiento de red. Una comparación que incluya solo CoAP básico
arroja 300×(15+17)=9600 B de polling, frente a 16+19+29×19=586 B de registro y
notificaciones, antes de cancelación y capas inferiores; ambos son cálculos.

Frente a GET cada **60 s**, serían aproximadamente cinco consultas, por lo que
esta muestra de 29 notificaciones no demuestra menos tráfico ni ahorro energético.
Observe ofrece mayor frescura ante cambios. Incluso el heartbeat de 45 s puede
ser más frecuente que ese polling. El ahorro depende de la variación de la señal,
la frescura exigida y el costo de escuchar/transmitir en ambos extremos; no es
una propiedad incondicional de Observe.

**3. Dos PUT al SED.** El sondeo de 5 s supera la primera espera CON de 2–3 s,
por lo que puede haber reintentos mientras S duerme. S registró OPEN y OPEN,
no change, separados por 131 ms. Esto es compatible con reintentos; sin Message
ID ni captura no se puede reconstruir el número de transmisiones físicas o toda
la deduplicación. Fijar OPEN es idempotente. Un toggle repetido podría abrir y
volver a cerrar, deshaciendo la intención.

**4. CBOR frente a una estructura binaria propia.** CBOR identifica tipos y campos
sin depender de padding, alineación o representación nativa de un compilador.
CDDL explicita el contrato y permite validarlo. Para evolucionar deben definirse
versiones, campos opcionales y reglas de compatibilidad: el decodificador actual
espera estos mapas y no se supone que acepte automáticamente campos nuevos.
Float16 introduce cuantización: en la muestra el valor codificado es 25.546875 °C.
La precisión numérica no equivale a exactitud de un sensor real.

## 5. Presupuesto de bytes y trama

Los tamaños CoAP incluyen cabecera, opciones y CBOR. UDP añade 8 B por datagrama.

| Intercambio | Request CoAP B | Response/notificación CoAP B | Datagramas básicos | Total CoAP+UDP B |
|---|---:|---:|---:|---:|
| GET temperatura | 15 | 17 | 2 | 48 |
| Registro Observe | 16 | 19 | 2 | 51 |
| Notificación Observe NON | — | 19 | 1 | 27 |
| PUT válvula CON, texto CLI | 18 | 13 | 2 | 47 |
| GET válvula | 16 | 13 | 2 | 45 |

Los pares básicos corresponden a solicitud y respuesta con ACK piggyback cuando
procede; no incluyen retransmisiones, ACK MAC, sondeos ni tráfico MLE.
El presupuesto PUT medido usa el byte de texto 0/1, no la solicitud CBOR de 4 B.

La guía propone como referencia HTTP/JSON ≈150 B de solicitud y ≈120 B de
respuesta más TCP, y MQTT/JSON ≈40 B en una conexión ya establecida. Son valores
orientativos del curso, no mediciones locales ni conteos RF equivalentes.

Para evaluar el ajuste a una trama de 127 B, se toma un ejemplo explícito:
25 B MAC + 21 B de seguridad, dejando 81 B para adaptación y red
([RFC 4944 §4](https://www.rfc-editor.org/rfc/rfc4944#section-4)).
Con una hipótesis de 12 B para IPv6/6LoWPAN comprimido y 8 B UDP sin comprimir,
el mensaje CoAP más grande registrado (19 B) ocupa 39 B en ese espacio.
Incluso usando 40 B IPv6, 1 B de dispatch y 8 B UDP, serían 68 B, menores que 81 B.
Así, los mensajes caben en ese presupuesto de un salto. La cabecera comprimida
real, las extensiones y el tráfico efectivo no fueron capturados; esto es una
comprobación de presupuesto, no evidencia RF de ausencia de fragmentación.

## 6. Energía y autonomía ideal estimada

Fuente: [ESP32-C6 Series Datasheet v1.5](https://documentation.espressif.com/esp32-c6_datasheet_en.html),
§5.6: tabla 5-9, p.67, RX 802.15.4 **74 mA**; tabla 5-11, p.68,
light-sleep **180 µA = 0.180 mA**. Las condiciones de consumo activo son
3.3 V y 25 °C. Se emplea light-sleep como escenario de reposo hipotético;
no se usa deep-sleep, ni se afirma que `ot mode -` active light-sleep del SoC.

Hipótesis del modelo: 10 ms activos por sondeo, corriente RX representativa de
ese intervalo, reposo light-sleep entre sondeos y capacidad útil supuesta de
3000 mAh para dos AA en serie. En serie se suma tensión, no capacidad en mAh.
Se idealiza la alimentación y su conversión; dos AA no son una fuente constante
de 3.3 V. No se ha seleccionado ni caracterizado una batería/regulador real.

```text
f = 0.010 / T_s
I_media_mA = f × 74 + (1 − f) × 0.180
vida_h = 3000 / I_media_mA
vida_días = vida_h / 24
```

| Sondeo T | Fracción activa supuesta | I media estimada (mA) | Autonomía ideal (h) | Autonomía ideal (días) |
|---|---:|---:|---:|---:|
| 1 s | 1 % | 0.918200 | 3267.26 | 136.14 |
| 5 s | 0.2 % | 0.327640 | 9156.39 | 381.52 |
| 15 s | 0.0667 % | 0.229213 | 13088.24 | 545.34 |

Para el periodo propuesto de **5 s**, la estimación es **0.328 mA y 381.5 días**.
Los resultados no predicen la autonomía de la DevKit usada: omiten TX, tiempo
CPU, sensor, válvula, Observe, reintentos, USB/CH343, LED, pérdidas del regulador,
autodescarga y capacidad dependiente de carga/temperatura. Además, la cifra RX de
la tabla es de pico y se usa aquí como aproximación del intervalo activo.
La autonomía real exige firmware con gestión de energía, electrónica apropiada
y medición de corriente. El cálculo se reproduce con
`python3 lab3/tools/estimate_energy.py` desde la raíz del repositorio.

## 7. DDR §6 — Tiempos experimentales

| Medición | Resultado | Alcance |
|---|---|---|
| GET CoAP, intervalo visible en C | ≈50 / 17 / 67 ms; promedio ≈44 ms | Tres repeticiones en video a 60 fps; marcador visual de envío y respuesta; no RTT RF aislado |
| CON con S detenida | ≈92 s | Duración aproximada reportada por el usuario |
| SED, sondeo 1 s | 16 / 465.600 / 916 ms | RTT ICMP min/promedio/máximo, 10/10 respuestas |
| SED, sondeo 5 s | 196 / 2119.000 / 4039 ms | RTT ICMP min/promedio/máximo, 10/10 respuestas |
| SED, sondeo 15 s | 757 / 8488.900 / 14461 ms | RTT ICMP min/promedio/máximo, 10/10 respuestas |

Comando de los tres ensayos: `ot ping <S-mleid> 16 10 1.3 64 40`.
Para GET, un fotograma equivale a 16.667 ms; los tres intervalos abarcan 3, 1 y
4 fotogramas. La lectura admite un margen conservador de ±2 fotogramas (≈33 ms)
en la diferencia, además de latencias sistemáticas de captura/terminal no
cuantificadas. El marcador es el salto de línea del comando, no el Enter físico.
[Fotogramas, transcripción y método](evidencias/archivos/GET-video-metodo-y-transcripcion.md),
[CSV](evidencias/GET-video-tiempos.csv). El ResponseTimeout previo visible en el
historial no se cuenta como uno de esos tres ensayos.

Los tres ensayos de ping registraron 0 % de pérdida; el padre reportó LQ de entrada/salida 3/3.
El aumento de RTT concuerda con esperar al sondeo del padre; ICMP mide ida y
vuelta, no tiempo exacto de ejecución de una orden CoAP. Los diez datos de cada
condición son una muestra, no percentiles ni garantías.

Para CON, la predicción con primera espera aleatoria de 2–3 s y cuatro
retransmisiones suma (1+2+4+8+16)×espera inicial = 62–93 s. Los ≈92 s
reportados son compatibles. No se midieron los intervalos internos de cada reintento.

## 8. DDR §7 — Diseño ante OPEN sin CLOSE

**Propuesta no implementada ni validada en este firmware.** La válvula debe cerrar
por una política local independiente de la red. Para el piloto se propone un
límite inicial de **60 s desde la primera apertura**, sujeto a aprobación y ajuste
con caudal, volumen admisible y necesidades del cultivo. Es una hipótesis de
seguridad operativa, no un tiempo agronómico demostrado por esta práctica.

Al vencer el plazo, cerrar aunque no llegue CLOSE y conservar el motivo para
reportarlo al reconectar. Un OPEN repetido por retransmisión no debe reiniciar
el plazo; para ampliar riego se necesitaría una renovación explícita, autenticada
y limitada. En arranque o reinicio, partir de CLOSED; un watchdog debe poder
recuperar un bloqueo. Un actuador real necesita estado seguro ante pérdida de
alimentación y realimentación de posición/caudal: el LED no demuestra esas propiedades.

La validación futura debe abrir, cortar comunicación antes de CLOSE y verificar
cierre físico a los 60 s, incluyendo duplicados, reinicios y falla de alimentación.
El prototipo actual conserva el estado software hasta otra orden o reinicio;
no debe atribuirse a sus logs este cierre autónomo.

## 9. Resumen para Edwin — tres líneas

1. PUT CON devuelve el estado aplicado; GET lo verifica en software, y una válvula real necesita sensor para confirmar movimiento físico.
2. Si S está inaccesible, CON avisa timeout (≈92 s en la prueba); NON no confirmó entrega y solo mostró Done.
3. Con sondeo de 5 s se midió RTT ICMP de 2.119 s promedio y 4.039 s máximo; falta medir el tiempo de mando CoAP y validar el objetivo operativo.

## 10. Conclusiones y pendientes concretos

Las pruebas validaron lectura CBOR, Observe, apertura/cierre software, rechazo de
órdenes inválidas y repetición idempotente. La falla de S produjo timeout CON,
y su reincorporación permitió volver a comandarla. Dormir la radio aumentó el
RTT observado; el sondeo debe acordarse con la latencia que operación admite.

CoAP/CBOR cumple el presupuesto pequeño de aplicación observado. La reducción
de tráfico frente a polling a 1 Hz y la autonomía del modelo son cálculos, no
mediciones de ahorro eléctrico. El cierre autónomo y la aceptación de 5 s son
propuestas documentadas, sin alterar el firmware ya ensayado.

El análisis y los documentos quedan completos con los datos disponibles. Para
completar los datos de contexto no informados quedan el lugar, la orientación
y el commit exacto cargado; si se requiere el registro de carga íntegro, falta
el log exitoso de flash S. El tiempo del GET queda documentado como estimación
visual; una medición instrumental más precisa del RTT de red requeriría otra
instrumentación. No es necesario repetir las pruebas ya documentadas.
La comprobación física del actuador y del consumo correspondería a validación
posterior del diseño real.

## Referencias

- [Guía del laboratorio, versión base](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/397b4f38435220e6a7ca6eee977f67a41f92d7f1/en/labs/lab3.md): tareas, políticas y referencias HTTP/MQTT.
- [Datasheet ESP32-C6 v1.5](https://documentation.espressif.com/esp32-c6_datasheet_en.html): corrientes del modelo, tablas 5-9 y 5-11.
- [RFC 7252](https://www.rfc-editor.org/rfc/rfc7252): CoAP, CON/NON y parámetros de retransmisión.
- [RFC 7641](https://www.rfc-editor.org/rfc/rfc7641): Observe.
- [RFC 8949](https://www.rfc-editor.org/rfc/rfc8949) y [RFC 8610](https://www.rfc-editor.org/rfc/rfc8610): CBOR y CDDL.
- [RFC 4944 §4](https://www.rfc-editor.org/rfc/rfc4944#section-4): presupuesto de trama; [RFC 6282](https://www.rfc-editor.org/rfc/rfc6282): compresión IPv6/UDP.
