# Lab 4 — Sensor real, frescura y Trustworthiness

**Estado: finalizado por decisión del usuario**, con el análisis y las evidencias
recibidas. No se recibió confirmación del apagado final de las placas. Offset,
tiempo desde inicio del estímulo y comparación de clase no determinados;
no se presentan como ensayos completos o resultados cero.

Dos ESP32-C6: C cliente, S servidor con DS18B20 en GPIO18, alimentación 3V3 y
consola UART/CH343. Se configuraron lecturas cada 2 s y resolución de 12 bits.
C fue leader; S pasó por child/router según la fase. Después del reset S volvió
a child al activar Thread manualmente. Fecha, integrantes, lugar, distancia,
pull-up y exactitud del termómetro de referencia no se documentaron específicamente
para esta sesión; no se heredan del Lab 3. Los nombres de los videos incluyen
2026-10-22 y se conservan como procedencia, no como declaración independiente
de las condiciones de todos los ensayos.

[Registro y evidencias](evidencias/registro.md) · [Origen del firmware](ORIGEN.md).

## DDR §4 — Contrato y ubicación funcional

| Propiedad | Contrato de `/env/temp` |
|---|---|
| Magnitud | Temperatura en °C del DS18B20 conectado a S |
| Métodos | GET y GET con Observe |
| Éxito | 2.05, Content-Format 60 (application/cbor), {t:float16}, 6 B |
| Exactitud nominal | ±0.5 °C entre −10 y 85 °C según fabricante; no calibrada en esta práctica |
| Resolución nominal | 0.0625 °C a 12 bits; diferente de exactitud y de formato impreso |
| Adquisición | Cada 2 s; conservar última lectura aceptada si falla la siguiente |
| Plausibilidad | −40 ≤ T < 85 °C; rechazar salto >5 °C respecto a lectura aceptada de edad <10 s |
| Frescura | Servir solo lectura aceptada con edad <60 s; Max-Age disminuye con la edad |
| Sin lectura fresca | 5.03, Max-Age 10 para reintento y texto `no fresh reading` |
| Observe | Cambio >0.5 °C: NON; tras 45 s sin notificar: heartbeat CON; dato vencido: error 5.03 y fin de observación |

```cddl
env-reading = { t: float16 }
```

Fuente de exactitud y resolución: [DS18B20, Analog Devices](https://www.analog.com/media/en/technical-documentation/data-sheets/ds18b20.pdf).
El rango del filtro de la aplicación es más estrecho que el rango físico total
del sensor. El límite superior excluye 85 °C, valor que el DS18B20 puede presentar
al encenderse antes de completar conversión. Los filtros no son una calibración.
El valor temporal se calcula en segundos enteros; esa granularidad y la evaluación
periódica deben distinguirse del instante físico exacto de vencimiento.

En el mapeo del curso, aire/suelo y su temperatura pertenecen al **PED**.
DS18B20, GPIO/1-Wire, adquisición y controles de plausibilidad son **SCD**.
URI, CBOR, códigos, frescura y Observe forman el contrato de servicio del **ASD**.
Trustworthiness es una perspectiva de auditoría sobre esos dominios, no un
sensor, protocolo o dominio adicional.

## Resultados de integridad y respuesta

| Medición | Resultado | Alcance |
|---|---|---|
| Registro estable | 30 muestras visibles, cada 2 s, 58 s entre primera y última | Stats: 32 lecturas en 64 s; no se reconstruyen las dos no impresas |
| Mínimo / máximo | 21.50 / 21.62 °C | Lecturas impresas a dos decimales |
| Ruido pico a pico | 0.12 °C | Variación observada, no incertidumbre absoluta |
| Promedio / desviación estándar muestral | 21.542 / 0.0321 °C | Calculados sobre los valores impresos |
| Menor cambio impreso | 0.06 °C | Compatible con cuantización de 0.0625 °C y redondeo de visualización |
| Primer pico del estímulo | 22.81 °C; subida ≈1.12 °C desde referencia inicial de 21.69 °C | El último mínimo previo fue 21.56 °C; otro criterio de base cambia la amplitud |
| Segundo pico | 22.50 °C | Usuario confirmó dos soplidos |
| Media subida con referencia inicial | 22.25 °C, primera muestra a 00:35:09.224 de S | Sin inicio físico del soplido, no se calcula tiempo de respuesta desde estímulo |
| Observe en ese registro | 6 notificaciones emparejadas: 5 NON por umbral y 1 CON heartbeat | OBS=2 inicial; OBS=3..8 posteriores; último renglón S truncado no se suma |
| Offset | No determinado | Termómetro de cocina no validado como referencia |

[Datos de ruido](evidencias/ruido-S-muestras.csv),
[estadísticos](evidencias/ruido-S-resumen.json),
[curva térmica](Imagen/estimulo-DS18B20.png) y
[Observe decodificado](evidencias/estimulo-observe-C-S.csv).

Se comunicaron ≈32 °C en el termómetro de cocina frente a ≈24 °C en DS18B20;
en otra comprobación, indicador del refrigerador 3 °C frente a termómetro 10 °C.
No se documentaron igualdad térmica, estabilización ni si el indicador era
consigna. Se preservan como [observaciones informales](evidencias/archivos/referencia-termometro-cocina-observaciones.txt),
sin atribuir el error ni aplicar una corrección de −7/−8 °C. No se utilizó la
temperatura corporal como patrón.

### Inyecciones y límite de plausibilidad

- 90 °C fue rechazado por rango.
- 31.5 °C fue rechazado por salto +9.6 °C frente a la lectura reciente.
- 23 °C artificial fue aceptado y S registró una notificación con ese valor;
  una lectura real de 21.88 °C lo reemplazó 689 ms después y generó otra notificación.

[Salto y aceptación](evidencias/archivos/06-inject-S-original.txt),
[rechazo por rango](evidencias/archivos/06-inject90-S-original.txt).
Estos ensayos verifican controles frente a ciertos errores, pero muestran que
una lectura falsa plausible puede pasar. No se cuenta 23 °C como temperatura física.

## DDR §5 — Respuestas de principios

**1. Por qué responder 5.03 y no seguir sirviendo el último número.** Una lectura
histórica no es una lectura actual. Max-Age indica cuánto tiempo puede conservarla
el cliente como fresca. Cuando vence, 5.03 evita que una avería parezca estabilidad
del ambiente. Usar indefinidamente un valor antiguo podría mantener una decisión
de riego basada en condiciones que ya cambiaron. Hasta vencer puede servirse el
valor con su tiempo restante explícito; después se informa indisponibilidad del dato.

**2. Sensor perdido frente a nodo inaccesible.** Con el sensor perdido, el nodo
sigue contestando y puede comunicar 5.03. Si S no tiene conectividad, C no recibe
esa explicación: el GET CON termina en timeout. Por sí solo, ese silencio no
distingue una placa apagada de un fallo de red. En la práctica se detuvo Thread,
no se cortó alimentación; S continuó adquiriendo temperaturas.

**3. Un valor falso plausible.** Un control local no dispone de una verdad
independiente: 23 °C es posible y puede pasar. Una referencia o sensores redundantes
permiten contrastar; aun así, pueden compartir sesgos o medir lugares diferentes.
Firmas/autenticación ayudan a comprobar origen e impedir alteraciones no autorizadas,
pero no hacen exacta una sonda defectuosa. La protección frente a atacantes y
confidencialidad se reserva para Lab 6.

**4. Radio ocupada y protocolos de sensor.** Una transacción cuyas duraciones de
pulso se miden por software puede sufrir al ser interrumpida por trabajo de radio.
Un periférico de bus dedicado reduce esa dependencia, aunque no elimina problemas
de programación o alimentación. Aquí se usa 1-Wire por GPIO: las transacciones
siguen teniendo temporización, pero el DS18B20 hace internamente su conversión y
el driver espera durante gran parte de los ≈760 ms de adquisición; ese tiempo
no equivale a CPU ocupada todo el intervalo. No se generaliza desde el DS18B20 a
DHT bit a bit ni a BMP280/I²C sin comparar datos de otras parejas.

## DDR §6 — Disponibilidad, fiabilidad y resiliencia

### Sensor desconectado

Última lectura buena a 00:55:09.224 de S. Primer fallo a 00:55:10.465 y
`Sensor lost` al tercero, a 00:55:14.465: 4.000 s entre primer y tercer fallo.
C obtuvo 22.00 °C con edad/Max-Age 16/44, 31/29 y 46/14 s. El GET registrado
a 00:56:10.801 devolvió 5.03 y `no fresh reading`.

La evaluación de policy anunció caducidad **60.636 s desde la última lectura**;
el GET 5.03 quedó documentado **61.577 s desde esa lectura**. La desconexión física
no aparece marcada, y el cliente consultaba cada ≈15 s: no se certifica la meta
≤60.000 s desde retiro de DATA ni se sustituye ese origen por otro. La comprobación
sí demuestra que un GET posterior al vencimiento deja de recibir una lectura antigua.

El historial previo visible en el mismo video termina dos observaciones con error.
En la última desconexión ya había cero observadores activos; ambos episodios
se distinguen en la [transcripción](evidencias/archivos/07-desconexion-DATA-video-transcripcion.md).
Al reconectar, S registra `Sensor back after 193 failed reads`, lee y vuelve a
anunciar dato fresco 0.964 s después. GET responde y el usuario registra Observe
nuevamente. No se conoce tiempo desde reinserción física.

### Nodo fuera de Thread

GET CON en C terminó en ResponseTimeout tras **≈74.1 s**, medidos mediante video
60 fps entre marcador visible de envío y error. Es tiempo observado de consola,
con margen de lectura conservador ≈33 ms más latencias de captura/terminal no
cuantificadas. No es RTT. El intervalo es compatible con las esperas por defecto
CON de 62–93 s, sin captura de reintentos individuales.

S siguió leyendo durante disabled y registró errores al intentar notificar.
Tras `ot thread start`, pasó de detached a router en 1.012 s según su reloj.
Después se documentó respuesta GET de nuevo. [Método y video](evidencias/archivos/09-nodo-fuera-red-video-transcripcion.md).

### Reposo frente a tráfico

| Condición | Duración stats | Lecturas | Fallidas | Tasa fallas sensor | Rechazadas | Tiempo adquisición min/avg/max µs |
|---|---:|---:|---:|---:|---:|---|
| Reposo sin pings deliberados | 155 s | 78 | 0 | 0.0 % | 0 | 760659 / 760679 / 760756 |
| Ensayo con tráfico | 186 s | 93 | 0 | 0.0 % | 0 | 760500 / 760815 / 764273 |

C reportó **1200 enviados / 1199 recibidos**, RTT **15/16.098/41 ms**.
Una petición sin respuesta implica pérdida calculada **0.08333 %**; el original
imprime 0.0 %, que se conserva como texto pero no reemplaza el cálculo de contadores.
La pérdida ICMP y el fallo de adquisición son métricas distintas.

La tasa observada del ensayo es inferior a la meta de 5 %. La ventana de stats
de 186 s supera los ≈120 s previstos de tráfico, por lo que no se atribuyen todas
las 93 lecturas a carga activa. No se conoce el solapamiento exacto de ventanas.
Cero fallas en estas muestras no demuestra probabilidad nula fuera de ellas.
[Comparación CSV](evidencias/fiabilidad-reposo-trafico.csv),
[ping original](evidencias/archivos/11-trafico-C-ping-original.txt).

### Reinicio y recuperación de aplicación

Antes del reset: router y 259 lecturas en 519 s; Observe registrado en C como
OBS=39. Después del arranque: 8 lecturas en 15 s y luego 15 en 30 s, sin fallas
ni rechazos. La lectura física se recupera y los contadores/uptime se reinician.
Thread permanece disabled, coherente con `CONFIG_OPENTHREAD_MANUAL_START=y`.

Sin copiar dataset, `ot ifconfig up` y `ot thread start` devolvieron S a child;
transición detached→child de 15.048 s y misma ML-EID. Esto respalda persistencia
operativa de configuración, con arranque de red manual.

C recibió posteriormente GET con `a16174f94d94` = {t:22.3125 °C} y registró
Observe de nuevo con **OBS=2**, `a16174f94d98` = {t:22.375 °C}.
OBS=39 es historial previo; OBS=2 es respuesta de la nueva inscripción, no una
notificación posterior. Las líneas S de ese último intercambio no se adjuntaron;
no se reconstruyen códigos o tiempos a partir de relojes distintos.

Se recuperaron sensor, red y respuesta de aplicación; el usuario debió iniciar
Thread y registrar Observe otra vez. Los registros de observadores del servidor
son RAM y se pierden en el reinicio según el firmware. No se atribuye recuperación
automática completa. [Reinicio](evidencias/archivos/12-reinicio-S-video-transcripcion.md),
[unión](evidencias/archivos/13-union-Thread-tras-reset-S.txt),
[GET y Observe C](evidencias/archivos/14-GET-Observe-tras-reset-C.txt).

## Tabla de clase — nuestra fila

| Sensor | Resolución observada | Ruido | Offset | Respuesta | Notificaciones | Adquisición | Fallas reposo/tráfico | Recuperación |
|---|---|---|---|---|---|---|---|---|
| DS18B20, 12 bits | 0.06 °C impreso; nominal 0.0625 °C | 0.12 °C pico a pico | No determinado | Primera subida ≈1.12 °C; tiempo de media subida sin origen físico medido | 6, cinco NON y un CON, dos soplidos | Reposo promedio 760679 µs; tráfico 760815 µs | 0/78 en 155 s; 0/93 en 186 s | Sí, lectura al reconectar; tras reset red manual y Observe nuevo |

La tabla compartida y mediciones de otra pareja no se han recibido. Se aporta
nuestra fila, sin fabricar comparaciones entre sensores ni concluir cuál es mejor.

## DDR §7 — Diseño ante dato ausente

**Propuesta, no implementada ni validada por el firmware de prácticas.** Estado
por defecto: **válvula cerrada / no autorizar una nueva apertura con dato inválido**.
Al recibir 5.03, marcar el dato no disponible de inmediato, generar aviso y retirar
la autorización de riego basada en esa temperatura. No convertir el error en 0 °C
ni prolongar artificialmente el último valor.

Si hay silencio, aplicar un plazo operativo propuesto de **5 s desde una consulta
sin respuesta** para pasar a estado no confirmado y retirar esa autorización, sin
esperar los ≈74.1 s del timeout CoAP. La validez de un dato ya recibido nunca se
extiende más allá de su Max-Age. El plazo de 5 s es una hipótesis que operación
debe acordar, no un tiempo requerido o probado por el laboratorio.

Si la válvula ya está abierta y se pierde la red, un CLOSE remoto puede no llegar.
Se propone un cierre local independiente, con concesión máxima inicial de **60 s
desde la primera apertura**, sin renovación por duplicados. Cualquier ampliación
requiere orden explícita y dato fresco. Esa duración debe ajustarse con caudal,
volumen seguro y cultivo; no está demostrada como adecuada para una instalación real.
Un actuador real necesita posición/caudal y un estado seguro ante falla eléctrica;
el LED solo representa estado software. La prueba futura debe cortar datos/red
y verificar cierre físico en el plazo local, incluyendo repetición de órdenes.

## DDR §8 — Fila de trazabilidad

| Perspectiva / característica | Dominios auditados | Labs Addressed | Evidencia y brechas |
|---|---|---|---|
| Trustworthiness | PED, SCD, ASD | Lab 4 | Contrato con frescura; ruido, inyecciones, dos modos de falla, tráfico y reset; brechas en referencia, sincronización, comparación y seguridad desplegada |

## DDR §9 — Auditoría Trustworthiness

| Característica | Evidencia | Brecha restante |
|---|---|---|
| Disponibilidad | GET fresco; caducidad y 5.03; nodo aislado produce timeout; GET vuelve tras recuperar red | Instante físico de retiro no marcado; no certifica detección ≤60 s desde desconexión |
| Integridad frente a fallas/ambiente | Ruido 0.12 °C; rango/salto rechazados; valor plausible inyectado muestra límite del filtro | Offset sin referencia válida; filtros no detectan todo sesgo o lectura falsa |
| Fiabilidad | 0/78 y 0/93 fallidas; tráfico ICMP documentado | Ventanas desiguales y solapamiento no delimitado; muestra limitada |
| Resiliencia | Reintentos recuperan sensor; reset recupera lectura; configuración permite unión sin copiar dataset; GET/Observe nuevos | Red requiere inicio manual; contadores y observadores no persistentes; tiempo de reinserción no medido |
| Seguridad operativa | Diseño de estado cerrado, dato inválido y cierre local con plazo | No implementado en firmware ni probado en actuador físico |
| Confidencialidad e integridad frente a atacantes | Fuera del alcance de estas pruebas | → Lab 6; checks de plausibilidad no sustituyen autenticación |
| Cumplimiento | Contratos, CDDL, origen de firmware y evidencias trazables con limitaciones | No se afirma certificación ISO; faltan metadatos específicos y comparación de clase |

## Resumen para Edwin — tres líneas

1. Si falla el sensor pero el nodo responde, el dato envejece hasta devolver 5.03; vimos ese GET a 61.577 s de la última lectura, sin marca de retirada física.
2. Si el nodo pierde la red, hay silencio y el GET CON termina en timeout: ≈74.1 s en esta prueba; no prueba por sí solo que la placa esté apagada.
3. El sensor recuperó lecturas al reconectar; tras reset hubo que activar Thread y registrar Observe otra vez. La estimación de offset sigue pendiente de una referencia confiable.

## Cierre y alcance

Los resultados documentan el comportamiento observado, no una calibración ni
una garantía de fiabilidad futura. La práctica distingue dato no disponible
de nodo inaccesible y demuestra recuperación con distintos grados de intervención.

Quedan como brechas: offset confiable, origen temporal de los soplidos, instante
físico de desconexión/reconexión, comparación de clase y metadatos específicos.
El laboratorio se cierra documentalmente por instrucción del usuario. No se
recibió confirmación de cancelación Observe y apagado Thread/interfaz al final
de esta sesión; no se registra como ejecutado. El cierre no convierte las
brechas en mediciones realizadas ni modifica los datos experimentales.

## Referencias

- [Guía Lab 4, versión base](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ae16e74895e1375ad0ff54ef7f691c8c94ae58d1/en/labs/lab4.md): tareas, objetivos y mapeo del curso.
- [SOP-04](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ae16e74895e1375ad0ff54ef7f691c8c94ae58d1/en/labs/sops/sop04_sensor_integration.md): arquitectura, buses y adquisición.
- [DS18B20, fabricante](https://www.analog.com/en/products/DS18B20.html) y [datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ds18b20.pdf): especificaciones nominales del sensor.
- [RFC 7252](https://www.rfc-editor.org/rfc/rfc7252): CoAP, Max-Age, 5.03 y confirmación; [RFC 7641](https://www.rfc-editor.org/rfc/rfc7641): Observe y terminación por error.
- [Código local de adquisición](firmware/src/reading.c), [frescura/Observe](firmware/src/env_temp.c) y [configuración](firmware/prj.conf).
