# IoT-Labs-DHR

Talleres de implementación IoT mínima con ESP32-C6 y Zephyr RTOS.

## Talleres

- [Lab 0.2 — HTTP](lab0_2/README.md): comunicación request/response con
  `GET /api/sensor` y `POST /api/control`.
- [Lab 0.3 — MQTT](lab0_3/README.md): comunicación publish/subscribe mediante
  Mosquitto, con telemetría enviada por la ESP32 y comandos entregados por el
  broker.

Cada taller es independiente en su compilación y documentación. Las
credenciales Wi-Fi no se guardan en Git; se pasan como opciones a `west build`.
