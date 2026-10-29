# Recuperación de DATA y registro Observe posterior

Video original aportado: `2026-10-22 22-23-46.mp4`,
[conservado íntegro](../../Imagen/recuperacion-DATA/2026-10-22_22-23-46_original.mp4).
SHA-256: `dd4bab01d818d8f557708578109110e664b7d36a3c7328d58c23349204514e80`.
Resolución 1920×1080, 60 fps, duración del contenedor 38.485333 s según ffprobe.
Transcripción manual normalizada de texto legible; se unen líneas envueltas.
Los tiempos siguientes pertenecen al reloj de S, no al tiempo relativo del video.
No se ve una marca inequívoca de reconexión física de DATA.

## Líneas nuevas en S

```text
[01:01:37.224,000] <inf> reading: Sensor back after 193 failed reads
[01:01:37.224,000] <inf> reading: ds18b20: 22.00 C
[01:01:38.188,000] <inf> env_temp: Fresh readings again: GET answers 2.05; observers must register again
[01:01:39.224,000] <inf> reading: ds18b20: 22.06 C
[01:01:41.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:43.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:45.224,000] <inf> reading: ds18b20: 22.06 C
[01:01:47.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:48.927,000] <inf> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435: 2.05, 22.12 C, 1s old, Max-Age 59 (CBOR a16174f94d88)
[01:01:49.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:51.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:53.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:55.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:57.224,000] <inf> reading: ds18b20: 22.12 C
[01:01:58.841,000] <inf> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435 (observe): 2.05, 22.12 C, 1s old, Max-Age 59 (CBOR a16174f94d88)
[01:01:59.224,000] <inf> reading: ds18b20: 22.12 C
```

## Comandos y respuestas nuevas en C

```text
uart:~$ ot coap get fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b env/temp con
Done
coap response from fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b with payload: uart
a16174f94d88
uart:~$ ot coap observe fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b env/temp
Done
coap response from fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b OBS=33 with payload:
a16174f94d88
```

`uart` es un artefacto visual de la salida, no parte del payload.
El CBOR `a16174f94d88` decodifica {t:22.125 °C}. En S se imprime 22.12 °C.
OBS=33 es la respuesta inicial del registro nuevo, no una notificación periódica
posterior. El video termina sin documentar notificaciones posteriores a ese registro.
Las respuestas 5.03 y secuencias OBS=30..32 anteriores que siguen en pantalla
son historial del ensayo previo; no se vuelven a contar como eventos nuevos.

## Recuperación y tiempos

- Sensor back y primera lectura: 01:01:37.224.
- Anuncio de GET disponible con dato fresco: 01:01:38.188, diferencia **0.964 s**.
- GET 2.05 documentado: 01:01:48.927, **11.703 s** desde la lectura recuperada.
- Nuevo registro Observe: 01:01:58.841, **21.617 s** desde esa lectura.

Los 11.703 s incluyen cuándo el usuario decidió enviar el GET: no son RTT ni
retardo de recuperación del servicio. Tampoco 0.964 s mide desde reinsertar DATA:
es el intervalo entre la lectura y la siguiente evaluación de policy.
No se identifica el instante de reinserción, por lo que su latencia queda sin medir.

La secuencia continúa el mismo uptime del video anterior, sin arranque/reinicio
visible, y el sensor vuelve por los reintentos automáticos. En conjunto con la
caducidad previa, demuestra que la lectura se recuperó y GET volvió a 2.05;
Observe se restableció mediante un nuevo comando explícito de C.

[Sensor back, captura a 16 s](../../Imagen/recuperacion-DATA/16s-sensor-back.png).
[GET y registro Observe, captura a 35 s](../../Imagen/recuperacion-DATA/35s-GET-y-Observe.png).
