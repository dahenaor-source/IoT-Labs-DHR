# Origen y adaptaciones

Guía y firmware base del curso:
https://github.com/saacifuentesmu/4201327-iot_systems_design

Commit consultado: `54ce49e5c0251dd3e7cc1300dbe6c96c28d55fd2`.

- Guía: `en/labs/lab2.md`.
- Firmware: `firmware/lab2_mesh/`.
- Adaptación en este repositorio: guía en español y herramientas para el entorno
  `~/zephyrproject` y las ESP32-C6 DevKitC utilizadas previamente.
- Una imagen común para A/B; el rol se determina por OpenThread y la configuración
  por CLI. No se compilan claves ni datasets en la imagen.
- Overlay del RGB en GPIO8 mediante I2S, basado en el empleado en Lab HTTP/MQTT.
- Flash limitada a los primeros 4 MB, compatible con las placas de 4 y 8 MB;
  se conserva el mapa de particiones de Zephyr para 4 MB.
- Consola USB nativa opcional; UART disponible con compilación independiente.
- El registro de cambios de rol funciona aunque el LED no esté listo.
- Comprobaciones realizadas aquí: sintaxis Bash, revisión de parámetros del runner
  ESP32 y de overlays contra Zephyr `4564d775ab0b`, revisión documental.
- La compilación Zephyr y la carga física requieren ejecutarse en el PC del usuario:
  este entorno no tiene Zephyr/SDK instalados ni acceso USB a las placas.

## Adaptación a dos placas

A petición del usuario, el procedimiento y las herramientas usan A/B. Se retira
el filtrado MAC de la configuración y se conservan Thread FTD, ping, shell, NVS
y LED de roles. La guía cubre los ensayos posibles con dos nodos y registra aparte
la reconexión manual. Dos saltos y recuperación por rutas alternativas del Lab 2
original requieren un tercer nodo y quedan pendientes. El Lab 3 sí declara una
tercera placa opcional, pero su firmware CoAP es distinto y no se incluye aquí.
