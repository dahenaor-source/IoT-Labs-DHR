# GET observado en video C/S

Origen: video aportado por el usuario, nombre original `2026-10-22 20-35-56.mp4`.
[Original conservado](../../Imagen/GET-video/GET-C-S-original.mp4).
SHA-256: `c6459afc756bd465f7d144529bdc50a6e3497872da0f4d0dd85dceaca1a20033`.
Resolución 1920×1080, 60 fps constantes, inicio PTS 0; duración del contenedor
15.552 s. El nombre del archivo no confirma por sí solo la fecha de toda la práctica.

## Método

En cada solicitud nueva se identifica el primer fotograma donde el cursor sale
de la línea del comando (salto de línea y/o Done) y el primero donde aparece
`coap response` con su payload. El Enter físico no es visible: el salto de línea
es su marcador visual, posterior al evento. Se mide la diferencia de índices
base cero / 60. El marcador inicial se usa consistentemente aunque el Done del
primer ensayo no queda visible hasta un fotograma después.

El recorte de análisis es x=0, y=720, ancho=960, alto=300 de la imagen original;
las imágenes adjuntas no añaden ni cambian texto, solo extraen esa región.
Se extrajeron fotogramas a resolución/frecuencia original, sin interpolación.

| Ensayo | Frame inicio/fin (base 0) | Tiempo video inicio/fin s | Intervalo visible | Payload |
|---|---|---|---|---|
| 1 | 395 / 398 | 6.583333 / 6.633333 | 50.000 ms | a16174f94e1b |
| 2 | 521 / 522 | 8.683333 / 8.700000 | 16.667 ms | a16174f94e1e |
| 3 | 672 / 676 | 11.200000 / 11.266667 | 66.667 ms | a16174f94e2b |

Promedio aritmético: 44.444 ms; mínimo 16.667 ms; máximo 66.667 ms.
Se presentan redondeados como ≈50/17/67 ms y promedio ≈44 ms.
Un fotograma representa 16.667 ms. Como margen de lectura conservador puede
considerarse ±2 fotogramas (≈33 ms) en una diferencia entre eventos, sin
incluir latencias sistemáticas del monitor, USB, terminal y captura.
El intervalo de un solo fotograma tiene resolución especialmente limitada.
No es una medición RF ni un RTT de red aislado. Las tres respuestas se reciben
antes de enviar el siguiente GET; no se usa el timeout previo como ensayo nuevo.

[CSV de tiempos](../GET-video-tiempos.csv).

## Correspondencia y transcripción normalizada

En C se ve el comando `ot coap get
fd2c:525a:8ff2:2258:9966:43d2:59a9:c435 env/temp`, seguido de Done y respuesta
desde S con los tres payloads de la tabla. Se omite el prefijo visual `uar`,
que no pertenece al CBOR. No se ha reconstruido texto ausente del video.

En S los tres GET nuevos se registran con código 2.05, request 15 B y response
CoAP 17 B, respectivamente a:

- 01:09:58.554, CBOR a16174f94e1b.
- 01:10:00.640, CBOR a16174f94e1e.
- 01:10:03.167, CBOR a16174f94e2b.

Los valores se transcriben de la consola derecha. Cada payload coincide con C,
por lo que no hace falta restar relojes de placas distintas.
En el historial inicial de C se ve `ResponseTimeout` de una solicitud anterior,
sin envío ni plazo completos en el video. Se conserva, pero no se asigna una
causa, duración ni correlación exacta a partir de este fragmento.

## Fotogramas de comprobación

- Ensayo 1: [envío](../../Imagen/GET-video/GET-1-envio-recorte.png), [respuesta](../../Imagen/GET-video/GET-1-respuesta-recorte.png).
- Ensayo 2: [envío](../../Imagen/GET-video/GET-2-envio-recorte.png), [respuesta](../../Imagen/GET-video/GET-2-respuesta-recorte.png).
- Ensayo 3: [envío](../../Imagen/GET-video/GET-3-envio-recorte.png), [respuesta](../../Imagen/GET-video/GET-3-respuesta-recorte.png).

[Recorte de los logs S al segundo 13 del video](../../Imagen/GET-video/GET-S-logs-recorte.png).
