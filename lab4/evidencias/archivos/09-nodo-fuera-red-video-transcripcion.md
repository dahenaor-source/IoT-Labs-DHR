# Nodo fuera de Thread — GET CON y timeout

Original aportado: `2026-10-22 22-27-55.mp4`.
[Video íntegro](../../Imagen/nodo-fuera-red/2026-10-22_22-27-55_original.mp4).
SHA-256 del original: `3d2b36daa7825f675a21eb80f8df2af1c36871d294f75dae0923f362cee16195`.
1920×1080, 60 fps constantes; duración 111.066667 s según ffprobe.
Se transcriben líneas legibles; se unen las que la terminal envuelve.

## Estado y comandos S

```text
uart:~$ ot thread stop
Done
[01:05:41.224,000] <inf> reading: ds18b20: 22.12 C
[01:05:41.503,000] <inf> lab4_sensors: Thread role: disabled
[01:05:43.224,000] <inf> reading: ds18b20: 22.06 C
[01:05:44.438,000] <wrn> env_temp: Notification failed (-1)
[01:05:44.438,000] <inf> env_temp: notify (heartbeat, CON): T=22.06 C, delta=0.12 C, 45s since last, reading 1s old, CoAP 19 B [threshold 7, heartbeat 28]
```

Las lecturas siguen aproximadamente cada 2 s durante la interrupción. Más tarde:

```text
[01:06:29.483,000] <wrn> env_temp: Notification failed (-1)
[01:06:29.483,000] <inf> env_temp: notify (heartbeat, CON): T=22.06 C, delta=0.00 C, 45s since last, reading 0s old, CoAP 19 B [threshold 7, heartbeat 29]
```

Esos logs son intentos de notificar con error de envío, no prueba de recepción
ni de bytes transmitidos por radio. No se confunde el conteo de policy con
notificaciones efectivamente entregadas. La placa permanece alimentada y ejecutando
el programa; se prueba indisponibilidad de red, no apagado eléctrico.

## GET de C y medición del video

```text
uart:~$ ot coap get fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b env/temp con
Done
coap receive response error 28: ResponseTimeout
```

El comando se acepta visiblemente a **13.500 s** del video (frame 810, índice
base cero): salto de línea y Done. El error aparece por primera vez a
**87.600 s** (frame 5256). Diferencia: **74.100 s ≈ 1 min 14.1 s**.
El frame anterior de cada evento no contiene aún la salida correspondiente.
A 60 fps cada fotograma representa 16.667 ms; se admite un margen conservador
de lectura ±2 fotogramas (≈33 ms), además de retardos sistemáticos de
terminal/USB/captura no cuantificados. El Enter físico no es visible y se usa
su marcador en consola. No se mide RTT de red ni cada reintento individual.

[Inicio recortado](../../Imagen/nodo-fuera-red/GET-envio-13.500s-recorte.png),
[error recortado](../../Imagen/nodo-fuera-red/timeout-87.600s-recorte.png).
Recorte: x=0, y=820, ancho=960, alto=200 de la imagen original, sin modificar texto.

C conserva OBS=33..37 en el historial previo. Durante la solicitud nueva no
aparecen lecturas Observe nuevas ni una respuesta 5.03; al final aparece timeout.
Las respuestas antiguas `no fresh reading` visibles arriba pertenecen a la prueba
del sensor y no se vuelven a contar como respuestas del nodo aislado.

La primera espera CON predeterminada de 2–3 s y cuatro retransmisiones dan una
ventana teórica de 31×(2–3) = 62–93 s. Los ≈74.1 s observados están dentro de esa
ventana; no se atribuyen intervalos exactos a reintentos que no se capturaron.

## Regreso de S a Thread

```text
uart:~$ ot thread start
Done
[01:07:09.224,000] <inf> reading: ds18b20: 22.12 C
[01:07:09.552,000] <inf> lab4_sensors: Thread role: detached
[01:07:10.564,000] <inf> lab4_sensors: Thread role: router
```

De detached a router transcurren **1.012 s**, usando solo timestamps de S.
No es la duración desde Enter del comando start ni tiempo de ejecución de un GET.
La recuperación de rol no demuestra por sí sola que CoAP responda después:
ese GET posterior queda pendiente. Tampoco se afirma reanudación automática
de Observe tras la recuperación a partir de este video.

[Captura del estado disabled y sensor activo](../../Imagen/nodo-fuera-red/25s-disabled-lecturas.png).
[Captura de timeout y vuelta a router](../../Imagen/nodo-fuera-red/106s-router-restaurado.png).
