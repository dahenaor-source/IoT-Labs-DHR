# IoT-Labs-DHR

Talleres de implementación IoT mínima con ESP32-C6 y Zephyr RTOS.

## Talleres

- [Lab 0.2 — HTTP](lab0_2/README.md): comunicación request/response con
  `GET /api/sensor` y `POST /api/control`.
- [Lab 0.3 — MQTT](lab0_3/README.md): comunicación publish/subscribe mediante
  Mosquitto, con telemetría enviada por la ESP32 y comandos entregados por el
  broker.
- [Lab 1 — Radio 802.15.4](lab1/README.md): escaneo de canales, formación de
  una red OpenThread y medición de RSSI/PER entre dos ESP32-C6.

- [Lab 2 — Malla Thread](lab2/README.md): formación de red, direccionamiento
  IPv6 y reconexión. [DDR](lab2/DDR_Lab2.md) (mediciones pendientes).
- [Lab 3 — CoAP](lab3/README.md): `/env/temp` con Observe, `/act/valve` y CBOR,
  nodo dormido (SED). [DDR](lab3/DDR_Lab3.md).
- [Lab 4 — DS18B20 real](lab4/README.md): sensor físico, contrato de frescura y
  auditoría de trustworthiness. [DDR](lab4/DDR_Lab4.md).
- [Lab 5 — Border Router](lab5/README.md): OTBR con ESP32-S3 + C6 (RCP), acceso
  desde PC/celular y NAT64. [DDR](lab5/DDR_Lab5.md).

Los laboratorios 1 y 2–5 incluyen su DDR (en `lab1/Resultados/` el Lab 1; en la
carpeta de cada lab los demás). Los labs 2–5 se basan en el trabajo conjunto con
[sillHD/IoT](https://github.com/sillHD/IoT); cada uno tiene un `ORIGEN.md`.
Las rutas asumen WSL con el repositorio en `~/IoT-Labs-DHR`.

- [Resumen general](Resumen_General/README.md): visión de conjunto de todos los laboratorios.

Cada taller es independiente en su compilación y documentación. Las
credenciales Wi-Fi no se guardan en Git; se pasan como opciones a `west build`.
