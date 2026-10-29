# Evidencias del Lab 4

Envía cada bloque identificando C/S y el ensayo. Guarda fotos/videos en `Imagen/`
y texto en `evidencias/archivos/`. Los logs de build/flash se generan allí.
No subas dataset Thread, claves ni contraseñas. Conserva el texto original;
separaremos cualquier transcripción resumida de la evidencia cruda.

| Ensayo | Información necesaria |
|---|---|
| Montaje | Foto DATA/3V3/GND, tipo de DS18B20, cable y pull-up usado |
| Carga | build y flash C/S, versión Zephyr, commit IoT y puertos |
| Red | state/channel/txpower/mleid de cada placa, distancia y obstáculos |
| Sensor | Arranque y soilsense stats; confirmar que S no dice simulated |
| Ruido, 60 s | Todas las muestras estables y stats final |
| Referencia | Valores contemporáneos, modelo/resolución/exactitud del termómetro |
| Estímulo | Inicio/fin del soplido, base/pico, logs S y notificaciones C hasta recuperar |
| Plausibilidad | Lectura previa, comandos inject, aceptación/rechazo y GET si se obtiene |
| DATA desconectada | Instante, última lectura buena, fallas/lost, GET cada 15 s, Max-Age, primer 5.03 y fin de Observe |
| Reconexión | Instante, Sensor back, primer GET 2.05, Observe antes/después de registrar de nuevo |
| S fuera de red | thread stop S, GET CON C, tiempo de timeout y comportamiento Observe |
| Reposo, 120 s | Reset, intervalo, stats final |
| Tráfico, 120 s | Reset, 1200 pings a 0.1 s, resumen C y stats S |
| Reinicio S | Logs antes/después, unión, lecturas, contadores y Observe |
| Clase | Tabla compartida o datos comparables de otra pareja, con fuente |
| Cierre | Cancelación, Thread/interfaz apagados |

Fecha, integrantes, lugar, modelo de placa, sensor, distancia y condiciones se
registran para esta sesión; no se heredan automáticamente del Lab 3.

Nombres sugeridos: `01-arranque-S.txt`, `02-red-C.txt`, `02-red-S.txt`,
`03-ruido-60s-S.txt`, `04-estimulo-C.txt`, `04-estimulo-S.txt`,
`05-inject-S.txt`, `06-sensor-desconectado-C.txt`, `06-sensor-desconectado-S.txt`,
`07-nodo-fuera-C.txt`, `08-reposo-S.txt`, `08-trafico-C.txt`, `08-trafico-S.txt`,
`09-reinicio-C.txt`, `09-reinicio-S.txt`.
