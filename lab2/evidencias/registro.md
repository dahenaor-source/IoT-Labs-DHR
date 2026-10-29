# Evidencia — Lab 2 adaptado a dos placas

**Estado:** firmware y procedimiento A/B preparados; ejecución física pendiente.
No hay resultados experimentales de Lab 2 registrados todavía.

## Alcance

Esta adaptación registra una red de dos nodos, direcciones IPv6, RTT de un salto,
contadores MAC de los extremos y, opcionalmente, reconexión manual de B.
Las pruebas del Lab 2 original que necesitan un tercer nodo quedan pendientes.
La reconexión manual no se considera recuperación mediante rutas alternativas.

## Sesión

- Fecha/lugar/integrantes: pendiente.
- Modelo/flash/puerto/conector de A: pendiente.
- Modelo/flash/puerto/conector de B: pendiente.
- Versión Zephyr y commit de IoT usado: pendiente.
- Canal previsto: 25; lecturas A/B: pendiente.
- Potencia prevista: 0 dBm; lecturas de ot txpower en A/B: pendiente.
- Posición, orientación y obstáculos: pendiente.
- Dataset compartido localmente; no guardar el hexadecimal ni claves en Git.

## Compilación y carga

| Actividad | Evidencia prevista | Resultado |
|---|---|---|
| Build USB/UART | archivos/build-usb.log o build-uart.log | Pendiente |
| Flash A | archivos/flash-A-usb.log o uart | Pendiente |
| Flash B | archivos/flash-B-usb.log o uart | Pendiente |
| Formación de red | ot state, ot router table | Pendiente |

## Direccionamiento

| Placa | Rol observado | ML-EID | RLOC | RLOC16 | Router ID | Extaddr | Link-local |
|---|---|---|---|---|---|---|---|
| A | Pendiente | | | | | | |
| B | Pendiente | | | | | | |

| Tipo | Identificación | Uso |
|---|---|---|
| Link-local | fe80::/64 | Comunicación en un enlace |
| RLOC | Prefijo mesh-local + 0:ff:fe00:RLOC16 | Localizador de encaminamiento |
| ALOC | Prefijo mesh-local + 0:ff:fe00:fcXX | Función/servicio; fc00 representa al líder |
| ML-EID | ot ipaddr mleid | Identidad del dispositivo dentro de la malla, usada en los pings |

- Derivación extaddr → link-local con los valores reales: pendiente;
  invertir bit U/L (0x02 del primer byte).
- Router ID = RLOC16 >> 10: pendiente de comprobar con las tablas.
- Grupos multicast y su alcance: pendiente de capturar ot ipmaddr.

## RTT y pérdida — un salto

| Trayecto | RTT min/avg/max (ms) | Enviados/recibidos | Pérdida (%) | Evidencia |
|---|---|---|---|---|
| A→B | Pendiente | | | |
| B→A | Pendiente | | | |

Parámetros: 64 bytes, 20 pings, intervalo 0.5 s, una dirección a la vez.

| Dirección de la señal | Tabla del receptor | Avg RSSI | Last RSSI | LQ In |
|---|---|---|---|---|
| A→B | B | Pendiente | | |
| B→A | A | Pendiente | | |

## Contadores MAC de los extremos

Resetear en A/B, hacer un ping A→B de 20 paquetes y capturar ambos contadores.

| Placa | TxUnicast | RxUnicast | Otras observaciones | Evidencia |
|---|---|---|---|---|
| A | Pendiente | | | |
| B | Pendiente | | | |

Los nodos son extremos; estos valores no demuestran reenvío por un intermediario.

## Reconexión manual de B — complementario

El tiempo se toma desde ot thread start en B hasta la primera respuesta de ping
correcta en A. No incluir la duración durante la que B estuvo detenida.

| Ensayo | Inicio de Thread en B | Primera respuesta en A | Tiempo (s) | Rol/dirección posterior | Evidencia |
|---|---|---|---|---|---|
| 1 | Pendiente | | | | |
| 2 | Pendiente | | | | |
| 3 | Pendiente | | | | |

No comparar estos tiempos con el criterio de recuperación de rutas alternativas
del Lab 2 original: son fenómenos distintos.

## Actividades originales pendientes por tercer nodo

- Red A/B/C de tres routers.
- Reenvío A→B→C comprobado con contadores de B.
- Comparación RTT de uno y dos saltos.
- Tres ensayos de pérdida de B y recuperación por el enlace A↔C de respaldo.
- Conclusiones de ADR-002 y resúmenes sobre latencia por salto/recuperación,
  respaldados por esas mediciones.

## Direcciones, roles e ISO/IEC 30141

Los enlaces y routers Thread forman el subsistema de comunicación del SCD.
La ML-EID permite identificar nodos a los servicios del ASD.

| Rol | Función | Implicación de energía |
|---|---|---|
| Leader | Router y coordinación de IDs/datos de red | Receptor activo |
| Router | Reenvío | Receptor activo |
| REED | Dispositivo elegible para router | Puede asumir el trabajo de router |
| End device | Hoja que usa un padre | No reenvía para otros nodos |
| Sleepy end device | Hoja que duerme y consulta al padre | Puede apagar el receptor entre consultas |

Análisis con lo observado en A/B: pendiente. Los experimentos multi-hop se mantienen
pendientes y no se sustituyen con resultados de esta adaptación.

## Índice de archivos y cierre

| Archivo | Qué demuestra |
|---|---|
| Pendiente | Vincular logs/capturas reales al ejecutar |

- [ ] Guardar logs y capturas sin dataset ni claves.
- [ ] Detener Thread y bajar interfaz en A/B al terminar.
- [ ] Completar tablas de A/B con datos reales.
