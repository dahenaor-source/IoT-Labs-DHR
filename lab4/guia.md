# Lab 4 — Pasos con DS18B20

## 1. Cablear S con la alimentación desconectada

Usa tres hilos, sin alimentación parásita. Conecta según la función indicada
por el fabricante del sensor; los colores de una sonda genérica pueden variar.

| DS18B20 | Placa S |
|---|---|
| VDD, normalmente rojo en sonda impermeable | 3V3 |
| GND, normalmente negro | GND |
| DQ/DATA, normalmente amarillo | GPIO18 |

Para el encapsulado TO-92 estándar, consulta el pinout del datasheet; mirando
la cara plana con patas hacia abajo es GND, DQ, VDD de izquierda a derecha.
No deduzcas ese orden de los cables de una sonda impermeable.

Si tienes 4.7 kΩ, conecta una pata a DATA/GPIO18 y otra a 3V3. El SOP admite el
pull-up interno en una sola sonda de cable corto; si la lectura falla o el cable
es largo, usa la resistencia externa y revisa continuidad. No uses 5 V en DATA.
Lleva 3V3 y GND a los rieles de la protoboard si te facilita la conexión.

## 2. Compilar y flashear

Conecta cada placa mediante **CH343** y adjúntala a WSL como en Lab 3.
Identifica sus puertos; conectar una sola cada vez evita confundirlas.

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
source ~/zephyrproject/.venv/bin/activate
ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
bash lab4/tools/build.sh C none uart
bash lab4/tools/build.sh S ds18b20 uart
```

Si C=ACM0 y S=ACM1, con sus monitores cerrados:

```bash
bash ~/IoT-Labs-DHR/lab4/tools/flash.sh C none /dev/ttyACM0 uart
bash ~/IoT-Labs-DHR/lab4/tools/flash.sh S ds18b20 /dev/ttyACM1 uart
```

Si falla build/flash, conserva el primer error y el final del log; no continúes
con una imagen anterior. Los scripts guardan los logs en `evidencias/archivos/`.

Abre dos terminales WSL, una por monitor:

```bash
bash ~/IoT-Labs-DHR/lab4/tools/monitor.sh C /dev/ttyACM0
```

```bash
bash ~/IoT-Labs-DHR/lab4/tools/monitor.sh S /dev/ttyACM1
```

En S ejecuta `soilsense stats`. Espera una lectura aceptada. Debe identificar
DS18B20 y mostrar `last good`, contadores y tiempo de lectura. `simulated` es
incorrecto para S. `was not found at boot` requiere revisar cableado y reiniciar.

**Enviar primero:** logs de carga/arranque, foto del cableado y stats S.

## 3. Formar Thread

Si conservan el mismo dataset y logran C leader y S child/router, úsalo. Activa
en ambas `ot ifconfig up` y `ot thread start`, y verifica `ot state`.
Para formar una red nueva, con el sensor ya funcionando:

En C, un comando por línea:

```text
ot thread stop
ot ifconfig down
ot dataset init new
ot dataset channel 25
ot dataset commit active
ot ifconfig up
ot thread start
```

Espera hasta `ot state` → leader. Consulta localmente `ot dataset active -x`.
Copia ese valor a S, sin publicarlo en el repo ni enviarlo al chat:

```text
ot thread stop
ot ifconfig down
ot dataset set active <DATASET_DE_C>
ot ifconfig up
ot thread start
```

Espera S child/router. En ambas guarda `ot state`, `ot channel`, `ot txpower` y
`ot ipaddr mleid`. Mantén la misma potencia y condiciones durante las comparaciones.

Solo en C:

```text
ot coap start
```

En los comandos siguientes sustituye `<S>` por la ML-EID real del servidor.
No ejecutes `ot coap start` en S.

## 4. GET inicial, ruido y termómetro

En C: `ot coap get <S> env/temp con`. Guarda su respuesta y el log S de 2.05,
edad y Max-Age. CBOR sigue siendo {t:float16}; no es temperatura simulada en S.

En S:

```text
soilsense reset
soilsense log on
```

Déjalo estable **60 s**, sin tocar la sonda, soplar ni cambiar su posición.
Coloca la referencia junto a ella y deja estabilizar ambas. Anota modelo,
resolución y exactitud declarada del termómetro si están disponibles.

Al minuto:

```text
soilsense log off
soilsense stats
```

Guarda todas las muestras y varias lecturas contemporáneas del termómetro.
Calcularemos mínimo, máximo, amplitud de ruido y menor paso observado. Los logs
imprimen dos decimales, por lo que el paso observado puede aparecer como 0.06/0.07 °C
frente al nominal 0.0625 °C. Si todas las muestras son iguales, no se mide el paso.
Offset = DS18B20 − referencia; la incertidumbre de la referencia también importa.

## 5. Respuesta al estímulo y Observe

En S activa `soilsense log on`. En C:

```text
ot coap observe <S> env/temp
```

Registra una base estable, sopla hacia el sensor **3–5 s** y deja recuperar sin
tocarlo. Graba el inicio/fin del estímulo y las lecturas de S junto a las respuestas
C. La sonda metálica puede responder lentamente; conserva lo observado aunque
el aumento sea pequeño. No calientes la placa ni sumerjas conexiones eléctricas.

Enviar: temperatura base/pico, timestamps, recuperación y todas las notificaciones.
Se calculará la mitad de la subida observada; si no se distingue, se registra
como no resoluble con el ensayo. Comparación con otro sensor: datos reales de otra
pareja o tabla de clase; no sustituirlos por valores inventados.

## 6. Filtros de plausibilidad

En S consulta `soilsense stats` antes de cada inyección.

```text
soilsense inject 90
```

Debe rechazar por rango. Luego elige una inyección **dentro del rango** que difiera
más de 5 °C del último valor, por ejemplo 31.5 si la base está alrededor de 24 °C.
Hazla antes de 10 s desde una lectura aceptada. Guarda el rechazo.

Inyecta después un valor plausible a 1–2 °C de la lectura actual, dentro del rango.
Activa el log para ver aceptación y consulta inmediatamente stats/GET: una muestra
real puede reemplazarla a los 2 s. Documenta que es un dato **inyectado**, no una
lectura física. No uses inyecciones durante ruido, offset ni tasa de fallas.

## 7. Sensor desconectado con nodo accesible

Mantén Observe activo en C y log en S. Retira **solo DATA** del DS18B20 de la
conexión GPIO18 y anota/graba ese instante; conserva alimentación y GND.

- Conserva `Read failed`, `Sensor lost`, última lectura buena y sus tiempos.
- Cada 15 s, ejecuta en C `ot coap get <S> env/temp con`.
- Guarda edad/Max-Age decreciente en S y la respuesta de C.
- Cerca de 60 s desde la última lectura aceptada, S debe dejar de servirla,
  responder 5.03 y terminar Observe. Conserva el log y el payload.
- `6e6f2066726573682072656164696e67` es ASCII `no fresh reading`, no CBOR.

Distingue tiempo desde desconexión, última lectura buena y primera respuesta 5.03.
Con GET manual cada 15 s, la detección observada puede demorarse por ese muestreo;
no atribuyas esa demora al vencimiento interno. El objetivo del curso es ≤60 s.

Reconecta DATA y anota el instante. Guarda `Sensor back`, nueva lectura y GET 2.05.
Observa si llegan notificaciones sin intervenir; después registra de nuevo Observe.
Si el driver requiere reinicio, registra ese hecho; no lo presentes como recuperación
espontánea. No reinicies antes de documentar la prueba.

## 8. Nodo inaccesible

Con sensor recuperado y C observando otra vez, en S:

```text
ot thread stop
```

En C ejecuta y cronometra:

```text
ot coap get <S> env/temp con
```

Espera `ResponseTimeout` sin mandar otra solicitud. Conserva lo que ocurre con
Observe y el tiempo hasta el error. Después `ot thread start` en S, espera unión,
verifica GET y registra Observe si hace falta. Esto prueba pérdida de red del
nodo, no un corte eléctrico real.

## 9. Tasa de fallas en reposo y con tráfico

Con sensor conectado, S activa y sin inyecciones, desactiva el log por muestra.
Cancela Observe en C para tener una condición de reposo definida.

En S: `soilsense log off`, `soilsense reset`. Espera **120 s** y guarda stats.
Anota lecturas totales, fallidas, rechazadas y min/promedio/max de tiempo de lectura.

Reinicia contadores en S con `soilsense reset`. En C:

```text
ot ping <S> 64 1200 0.1
```

Al completar los aproximadamente 120 s, conserva resumen de ping y stats S.
Graba inicio/fin: los intervalos de los contadores deben coincidir aproximadamente
con los del tráfico. No cambies distancia, sensor ni potencia entre ensayos.
Tasa = 100×failed/reads; rejected se reporta aparte. Meta del curso: <5 % de
lecturas fallidas con radio ocupada. El resultado real puede cumplirla o no.

## 10. Reinicio y cierre

Con Observe registrado, presiona RESET en S y guarda ambos monitores antes y
después. Comprueba dataset/unión, primera lectura, contadores, GET y si Observe
requiere registro nuevo. No ejecutes factoryreset en este ensayo.
Con `CONFIG_OPENTHREAD_MANUAL_START=y`, es esperable que Thread quede disabled:
registra primero ese estado y luego ejecuta `ot ifconfig up`/`ot thread start`
sin copiar un dataset nuevo para comprobar persistencia y unión. No publiques
las claves ni el dataset en las evidencias.

Al terminar cancela Observe en C. Si se usó la válvula simulada, ciérrala y
consulta su estado. En ambas: `ot thread stop` y `ot ifconfig down`.

## 11. Informe

Completaremos la fila DS18B20 de la tabla de clase, contrato de exactitud/frescura,
mapeo PED/SCD/ASD, respuestas, auditoría Trustworthiness (disponibilidad, integridad,
fiabilidad y resiliencia), diseño ante 5.03/silencio y resumen para Edwin.
La comparación de clase requiere la tabla real; las filas ajenas no se fabrican.
