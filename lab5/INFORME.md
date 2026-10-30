# Informe — Lab 5: integración Thread/Wi-Fi mediante Border Router

**Integrantes:** Ismael Cortes Ramirez y David Henao Rojas.  
**Estado:** finalizado por decisión del equipo, con los límites documentados abajo.

## Arquitectura y resultado

ESP32-C6 S con DS18B20 y cliente C forman una red Thread en canal 25. Una
ESP32-S3 N16R8 usa otra C6 como radio RCP por UART y conecta Thread al Wi-Fi.
Windows accede al recurso /env/temp por dirección OMR mediante ruta IPv6 manual;
el dashboard ofrece Observe y /act/valve, representado por LED. El usuario
confirmó acceso desde celular y potencia 0 dBm (sin desglose por placa).

## Resultados

| Prueba | Resultado |
|---|---|
| C→S ICMPv6 | 10/10; RTT medio 13,3 ms |
| PC→BR ICMPv6 | 10/10; RTT medio mostrado 8 ms |
| PC→S ICMPv6 | 10/10; RTT medio mostrado 32 ms |
| PC→S CoAP | 10/10 2.05; mediana 33 ms, mínimo 30 y máximo 49 ms |
| S→IPv4 NAT64 | 10/10; RTT medio 53 ms |
| Dashboard | Observe recibido; control LED y acceso móvil confirmados |
| Sin BR | PC: NetworkError; control C→S del LED confirmado |
| Retorno BR | GET PC 2.05, temperatura reportada 23,5 °C |

CoAP cumple el objetivo de mediana <200 ms. La diferencia de RTT medios entre
PC→S y PC→BR es aproximadamente 24 ms; no es tiempo puro de procesamiento.
NAT64 sintetiza el destino IPv4 en el prefijo /96 anunciado. El control interno
continúa sin BR: su pérdida afecta el acceso externo, no toda la comunicación
Thread. Restaurar BR requirió Wi-Fi y el mismo dataset, porque sus ajustes son RAM.

## Decisión de arquitectura — ADR-007

**Estado:** adoptada en el prototipo. Se conserva la numeración previa del informe
unificado; ADR-005 ya corresponde a frescura de lecturas.

Usar CoAP/CBOR sobre Thread para C/S y un BR S3+C6 RCP para acceso desde Wi-Fi,
manteniendo el control local independiente del BR. La evidencia son los GET de
Windows, Observe móvil y actuación interna confirmada durante el corte del BR.
Consecuencias: ruta IPv6 en el host, alimentación y enlace UART adicionales,
configuración manual tras reinicio del BR; no aporta por sí mismo seguridad de
aplicación ni recuperación autónoma.

## Alcance del cierre

Resultados originales del chat, muestras y procedencia en el
[registro experimental](evidencias/registro.md). Algunas actuaciones y la prueba
móvil tienen confirmación verbal; fotos y logs originales no se incorporaron.
No se midieron tiempos de recuperación ni consumo. No se confirmó wifi ps off,
por lo que no se atribuye causalidad a la mejora de RTT. La fecha exacta y
condiciones físicas del ensayo no se reconstruyen a partir de fechas de build.
No consta apagado físico final ni GET de cierre de válvula. La válvula es un LED;
no se declara actuación hidráulica real, DTLS o autorización de aplicación.
