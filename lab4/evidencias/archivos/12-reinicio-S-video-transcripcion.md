# Reinicio de S — lectura, contadores y Thread

Video original: `2026-10-22 22-50-20.mp4`,
[conservado íntegro](../../Imagen/reinicio-S/2026-10-22_22-50-20_original.mp4).
SHA-256 del archivo conservado: `a4da3517efd2d2fccd1c90790b3f2dbb3abfde0f4e2a125b5886da9c84d06694`.
Resolución 1920×1080, 60 fps; duración del contenedor 46.850 s.
Las siguientes son transcripciones de líneas legibles; se unen las envueltas.
Los stats son instantáneas, no una medición sincronizada desde el botón RESET.

## Antes del reinicio

C registra Observe y recibe:

```text
uart:~$ ot coap observe fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b env/temp
Done
coap response from fd2c:525a:8ff2:2258:a81c:f3d:1e07:2a8b OBS=39 with payload:
a16174f94d94
```

En S:

```text
[01:27:31.864,000] <inf> env_temp: GET /env/temp from fd2c:525a:8ff2:2258:9966:43d2:59a9:c435 (observe): 2.05, 22.31 C, 0s old, Max-Age 60 (CBOR a16174f94d94)
uart:~$ soilsense stats
sensor:    ds18b20
last good: 22.31 C, 1 s ago
reads:     259 in 519 s: 0 failed (0.0 %), 0 rejected
read time: min 760500 us, avg 760735 us, max 764273 us
uart:~$ ot state
router
Done
```

El resumen del ping 1200/1199 visible en C es historial, ya documentado en el
ensayo con tráfico; no se cuenta como una segunda prueba.

## Arranque y primeras consultas

Se ve un arranque nuevo de Zephyr, flash configurada de 4 MB y driver de radio
inicializado. El aviso SHA-256 aparece antes de continuar el arranque; en esta
captura no impide que la aplicación y el sensor vuelvan a ejecutarse.

```text
*** Booting Zephyr OS build v4.4.0-13610-g4564d775ab0b ***
[00:00:00.559,000] <inf> lab4_sensors: C/S: run ot coap start only on C, never on S.
[00:00:00.559,000] <inf> lab4_sensors: SoilSense node ready: CoAP /env/temp (ds18b20) and /act/valve on UDP 5683. OpenThread commands start with "ot".
[00:00:00.559,000] <inf> reading: Reading ds18b20 every 2 s
uart:~$ soilsense stats
sensor:    ds18b20
last good: 22.31 C, 0 s ago
reads:     8 in 15 s: 0 failed (0.0 %), 0 rejected
read time: min 760647 us, avg 763006 us, max 779375 us
uart:~$ ot state
disabled
Done
```

Una segunda consulta confirma que siguen llegando muestras:

```text
uart:~$ soilsense stats
sensor:    ds18b20
last good: 22.31 C, 1 s ago
reads:     15 in 30 s: 0 failed (0.0 %), 0 rejected
read time: min 760647 us, avg 761917 us, max 779375 us
uart:~$ ot state
disabled
Done
```

## Interpretación y límites

- El uptime vuelve a cero y los contadores se reinician: de 259/519 s antes,
  a 8/15 s y 15/30 s después. No se conservan como histórico persistente.
- El sensor vuelve a adquirir valores sin intervención adicional visible. La
  igualdad del número 22.31 °C antes/después no prueba conservación de la lectura:
  hay muestras nuevas y edades recientes.
- Thread no se une automáticamente: permanece disabled. Esto es coherente con
  `CONFIG_OPENTHREAD_MANUAL_START=y` en el firmware preparado, no demuestra que
  se haya perdido el dataset.
- NVS se inicializa en el arranque, pero la persistencia de la red aún requiere
  verificar unión con `ot ifconfig up`/`ot thread start` sin copiar el dataset.
  No se pide mostrar el dataset ni sus claves en el chat.
- C conserva en pantalla OBS=39, pero S está fuera de Thread y no se ven nuevos
  mensajes Observe. El reinicio elimina registros de observadores en RAM según
  el código; la demostración del registro nuevo queda pendiente tras volver a unir S.
- No se observa en este video un GET posterior al nuevo arranque, ni una nueva
  inscripción Observe. No se atribuye a la prueba recuperación completa de red/API.

## Capturas

- [Antes del reset, estado router y stats](../../Imagen/reinicio-S/05s-antes-reset.png).
- [Nuevo arranque y primeras ocho lecturas](../../Imagen/reinicio-S/40s-arranque-y-stats.png).
- [Quince lecturas y Thread disabled](../../Imagen/reinicio-S/45s-contadores-y-disabled.png).
