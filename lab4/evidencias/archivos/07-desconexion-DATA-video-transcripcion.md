# Desconexión DATA — transcripción y método del video

Video proporcionado por el usuario: `2026-10-22 22-17-09.mp4`, conservado
[íntegro](../../Imagen/desconexion-DATA/2026-10-22_22-17-09_original.mp4).
SHA-256 del archivo conservado: `63787a2f418dcdc1c5ab44b5709c4d60b79353a67d468192152b5781905baee2`.
1920×1080, 60 fps, duración 103.900 s según ffprobe. Las capturas se extrajeron
sin modificar texto. Los timestamps siguientes son uptime de **S**, no segundos
desde el inicio del video ni un reloj compartido con C.
El retiro físico de DATA no aparece marcado inequívocamente en la grabación.
No se calcula tiempo desde la desconexión manual usando un instante supuesto.

## Episodio principal: pérdida nueva durante la grabación

Transcripción normalizada de líneas legibles de S (se unen líneas envueltas):

```text
[00:55:09.224,000] <inf> reading: ds18b20: 22.00 C
[00:55:10.465,000] <err> reading: ds18b20 was not found at boot; fix the wiring, then reset the board
[00:55:12.464,000] <wrn> reading: Read failed (-19) after 972 us
[00:55:14.465,000] <err> reading: Sensor lost: 3 failed reads in a row; retrying every 2 s
[00:55:25.607,000] <inf> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435: 2.05, 22.00 C, 16s old, Max-Age 44 (CBOR a16174f94d80)
[00:55:40.580,000] <inf> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435: 2.05, 22.00 C, 31s old, Max-Age 29 (CBOR a16174f94d80)
[00:55:55.815,000] <inf> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435: 2.05, 22.00 C, 46s old, Max-Age 14 (CBOR a16174f94d80)
[00:56:09.860,000] <wrn> env_temp: No reading younger than 60 s: GET now answers 5.03; 0 observation(s) ended
[00:56:10.801,000] <wrn> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435: 5.03, no reading younger than 60 s, retry in 10 s
```

La frase `was not found at boot` es el mensaje que imprime la aplicación en
el primer fallo -ENODEV; no se interpreta como prueba de un reinicio. La consola
había mostrado lecturas válidas hasta el segundo anterior y conserva su uptime.

C ejecuta GET CON a `fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b` y recibe los
payloads `a16174f94d80` antes de caducar. Este CBOR es {t:22.0 °C}.
Al final recibe `6e6f2066726573682072656164696e67`, ASCII `no fresh reading`.
No se confunde el prefijo visual `uart` con payload ni el texto de error con CBOR.
La CLI no imprime el código 5.03: se acredita con el log de S.

## Intervalos calculados en un mismo reloj

- Última lectura visible → primer error: 1.241 s.
- Primer error → Sensor lost (tercer fallo): 4.000 s.
- Última lectura visible → Sensor lost: 5.241 s.
- Última lectura visible → anuncio de caducidad en policy: 60.636 s.
- Última lectura visible → primer GET 5.03 documentado: 61.577 s.
- Primer error → primer GET 5.03 documentado: 60.336 s.

El contrato de GET deja de aceptar la lectura a los 60 s según el código. El
anuncio del trabajo policy se evalúa aproximadamente cada segundo, por lo que
aparece después del umbral; los GET manuales se hacen aproximadamente cada 15 s.
La muestra verifica respuesta 5.03 en el GET posterior y rechazo de lectura
vencida, pero no demuestra detección del cliente ≤60.000 s desde la retirada
física de DATA ni mide un RTT. No se resta un reloj de C a uno de S.

## Historial anterior, ya presente al iniciar el video

En el [fotograma de 4 s](../../Imagen/desconexion-DATA/04s-historial-recuperacion.png)
se leen estas líneas de un episodio previo, separado del anterior:

```text
[00:53:14.683,000] <inf> env_temp: notify (heartbeat, CON): T=22.06 C, delta=0.00 C, 45s since last, reading 9s old, CoAP 19 B [threshold 7, heartbeat 22]
[00:53:59.729,000] <inf> env_temp: notify (heartbeat, CON): T=22.06 C, delta=0.00 C, 45s since last, reading 54s old, CoAP 19 B [threshold 7, heartbeat 23]
[00:54:05.736,000] <wrn> env_temp: No reading younger than 60 s: GET now answers 5.03; 2 observation(s) ended
[00:54:11.224,000] <inf> reading: Sensor back after 32 failed reads
[00:54:11.224,000] <inf> reading: ds18b20: 21.94 C
[00:54:11.742,000] <inf> env_temp: Fresh readings again: GET answers 2.05; observers must register again
```

C conserva dos respuestas de error con `no fresh reading`, y mensajes OBS=30,
31 y 32 repetidos en su historial. S registra dos observaciones terminadas;
no se atribuye la repetición a pérdida/retransmisión o error de radio sin más datos.
Ese historial confirma finalización de Observe y posterior recuperación de
lectura. El log de recuperación precede en 0.518 s al anuncio de disponibilidad
2.05 del trabajo policy. No muestra el instante de reconexión manual, así que
no mide tiempo desde reinsertar el cable. El primer GET recibido tras esa
reconexión tampoco queda correlacionado por timestamp en el historial S visible.

En el episodio principal `0 observation(s) ended` indica que no había registros
Observe activos cuando venció el dato. La observación que terminó en el episodio
previo no se reanudó sola según el estado registrado al siguiente vencimiento;
para continuar observando se debe registrar de nuevo. No se fusionan ambos episodios
para simular que hubo Observe activo durante toda la última desconexión.

## Capturas

- [Historial, cierre Observe y recuperación](../../Imagen/desconexion-DATA/04s-historial-recuperacion.png).
- [Edad y Max-Age](../../Imagen/desconexion-DATA/80s-edad-y-max-age.png).
- [GET 5.03 en C/S](../../Imagen/desconexion-DATA/96s-respuesta-503.png).
