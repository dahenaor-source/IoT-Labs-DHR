# Resumen general de los laboratorios

**Autor:** David Henao Rojas (labs 3–5 junto con Ismael Cortes Ramirez)  
**Curso:** IoT Systems Design — proyecto SoilSense (riego con sensor de temperatura y válvula)  
**Hardware:** ESP32-C6 (y ESP32-S3 como border router en el Lab 5) · Zephyr RTOS / OpenThread

## Evolución del proyecto

| Lab | Tema | Qué se construyó | Resultado clave | Estado de la evidencia |
|---|---|---|---|---|
| [0.2](../lab0_2/README.md) | HTTP | Servidor HTTP en la ESP32 (`GET /api/sensor`, `POST /api/control`), dashboard Python | Temperatura simulada 20.0–29.9 °C y control del LED WS2812 | Funcional |
| [0.3](../lab0_3/README.md) | MQTT | Telemetría `iot/sensor` y comandos `iot/control` vía Mosquitto | Publish/subscribe entre ESP32 y broker | Funcional |
| [1](../lab1/README.md) | Radio 802.15.4 | Escaneo de canales, red OpenThread, RSSI/PER entre dos placas | Canal 25, TX 20 dBm: 5 m PER 1 %, 15 m PER ≈97 %, ≥20 m se pierde la comunicación → "proceder con reservas" | Mediciones reales ([DDR](../lab1/Resultados/DDR_Lab1.md)) |
| [2](../lab2/README.md) | Malla Thread, IPv6 | Formación de red, direccionamiento, ping de un salto | Diseño y teoría de roles y direcciones | Sin mediciones: healing time pendiente ([DDR](../lab2/DDR_Lab2.md)) |
| [3](../lab3/README.md) | CoAP y CBOR | `/env/temp` (GET/Observe) y `/act/valve`; nodo dormido (SED) | Respuestas de ≈44 ms; Observe 29 avisos en 300 s; sondeo 5 s → RTT medio 2.1 s; ≈381 días estimados de batería | Real + estimaciones ([DDR](../lab3/DDR_Lab3.md)) |
| [4](../lab4/README.md) | Sensor real DS18B20 | Contrato de frescura (5.03, Max-Age), auditoría de trustworthiness | Ruido 0.12 °C; 0/78 y 0/93 lecturas fallidas; sensor perdido visto a ≈61.6 s | Real, con brechas ([DDR](../lab4/DDR_Lab4.md)) |
| [5](../lab5/README.md) | Border Router | OTBR (ESP32-S3 + C6 RCP), acceso desde PC y celular, NAT64 | CoAP PC→S mediana 33 ms; NAT64 53 ms; sin BR el control local sigue | Real, con límites ([DDR](../lab5/DDR_Lab5.md)) |

## Hilo conductor

1. **Lab 0.2 / 0.3:** comunicación sobre Wi-Fi con dos modelos (petición/respuesta y publicar/suscribir).
2. **Lab 1:** se pasa a radio 802.15.4 y se mide el alcance real, que resultó corto (~15–20 m).
3. **Lab 2:** una malla Thread con IPv6 compensa ese alcance con varios saltos.
4. **Lab 3:** se define el protocolo de aplicación (CoAP/CBOR) y cómo funciona con nodos a batería.
5. **Lab 4:** se reemplaza el dato simulado por un sensor real y se define cuándo un dato deja de ser confiable.
6. **Lab 5:** se conecta la malla al mundo IP con un border router; aparecen el punto único de falla y los riesgos de seguridad.

## Decisiones de arquitectura (ADR)

| ADR | Decisión | Estado |
|---|---|---|
| ADR-002 | Malla Thread en lugar de estrella tipo LoRaWAN | Propuesto (falta medir healing time) |
| ADR-003 | CoAP + CBOR sobre Thread | Aceptado |
| ADR-004 | Sondeo de 5 s para válvula a batería | Propuesto |
| ADR-005 | Contrato de frescura de `/env/temp` (Lab 4) | Aceptado |
| ADR-007 | Un solo OTBR para el piloto (ADR-005 en la plantilla del curso) | Propuesto |

## Pendientes y límites conocidos

- Lab 2: faltan el tercer nodo y las mediciones de healing time y costo por salto.
- Sin medición de consumo real: las autonomías son estimaciones con datasheet.
- La válvula es simulada (LED); el cierre local ante pérdida de red es una propuesta, no está implementado.
- Lab 4: el "sensor perdido ≤ 60 s" no está certificado (no se marcó el retiro físico).
- Lab 5: seguridad (OTBR sin autenticación, acceso abierto en el hotspot) queda para el Lab 6.
- El offset del sensor no se determinó por falta de referencia.

## Dónde está cada cosa

- Cada lab tiene su `README.md`, su guía y su registro en `evidencias/`.
- DDR: `lab1/Resultados/DDR_Lab1.md`, `lab2/DDR_Lab2.md`, `lab3/DDR_Lab3.md`, `lab4/DDR_Lab4.md`, `lab5/DDR_Lab5.md`.
- Los labs 2–5 vienen del trabajo conjunto en [sillHD/IoT](https://github.com/sillHD/IoT) (ver `ORIGEN.md` de cada uno).
