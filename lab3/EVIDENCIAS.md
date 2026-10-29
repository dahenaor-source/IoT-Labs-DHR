# Qué enviar de las consolas — Lab 3

Envía una prueba a la vez, identificando **C o S** y el número de prueba.
Puedes pegar texto o adjuntar un .txt; las capturas son complementarias.
Espera a que termine cada comando. Si envías primero una placa, esperaré la
otra antes de cerrar la fila de resultados correspondiente.

No incluyas `ot dataset active -x`, networkkey, contraseñas ni tokens. Puedes
compartir ML-EID, extaddr, tablas y resultados de aplicación. Revisa también las
capturas para excluir el dataset que se copió al configurar la red.

| Prueba | Consola C | Consola S | Dato adicional |
|---|---|---|---|
| Compilación/carga | Log build y flash-C | Log flash-S | Modelo/puerto/conector de cada placa |
| Red | Arranque, state, channel, txpower, mleid, router table | Las mismas salidas | Fecha/lugar, obstáculos/orientación |
| GET temperatura | Comando, respuesta hexadecimal y tiempo observado | Línea GET /env/temp con request/CoAP B | Payload decodificado, método de temporización |
| Observe 5 min | Observe, notificaciones y cancel | Todas las líneas notify y Observe notification de la ventana | Inicio/fin, duración, contadores iniciales/finales |
| Válvula | PUT1, GET, PUT1 repetido, PUT0, GET, PUT7 y respuestas | OPEN/CLOSED, no change, 4.00 y tamaños | Foto/video LED si disponible |
| CON sin S | Comando y ResponseTimeout | thread stop | Segundos hasta el error |
| NON sin S | Comando y resultado tras 120 s | Estado durante la prueba | Duración real de espera |
| Reconexión S | PUT CON correcto tras el retorno | thread start, state, mleid | Confirmar dirección actual |
| SED | — | mode, pollperiod, state, parent, mleid | Esperar a child antes de medir |
| Sondeo 1/5/15 s | Comando y resumen completo del ping por periodo | pollperiod/state/parent por periodo | Etiquetar cada bloque con 1000/5000/15000 ms |
| PUT con sondeo 5 s | Comando y respuesta | Todos los PUT y no change con tiempos | Contar entregas observadas, sin asumir cantidad |
| Cierre | PUT0/GET y respuesta | mode rdn, pollperiod 0 | Thread detenido al acabar |

## Formato para pegar datos

```text
Lab 3 - prueba: GET temperatura / Observe / válvula / CON / NON / SED
Placa: C o S
Fecha y hora:
Condición: normal / S detenida / SED, pollperiod = ... ms
Comando ejecutado:
Salida completa:
Tiempo medido y cómo se midió (si aplica):
Observaciones:
```

Para RTT de SED conserva exactamente la línea de enviados/recibidos, pérdida y
RTT min/avg/max. Para Observe conserva la ventana completa o los contadores de
inicio/fin; son acumulativos y no se deben mezclar sesiones.

## Archivos en el repo

- Los scripts crean build-usb.log, flash-C-usb.log y flash-S-usb.log en
  `evidencias/archivos/` (o sufijo uart).
- Texto de las pruebas: `01-red-C.txt`, `01-red-S.txt`, `02-get-C.txt`,
  `02-get-S.txt`, `03-observe-C.txt`, `03-observe-S.txt`, `04-valvula-C.txt`,
  `04-valvula-S.txt`, `05-con-non.txt`, `06-sed-1000.txt`, `06-sed-5000.txt`,
  `06-sed-15000.txt`, `07-put-sed-C.txt`, `07-put-sed-S.txt`.
- Fotos/videos en `Imagen/`, con nombres que indiquen la prueba.

Estos nombres son sugerencias, no archivos con resultados ya obtenidos. Con tus
salidas completaré las tablas y sus enlaces en el registro del repositorio.
