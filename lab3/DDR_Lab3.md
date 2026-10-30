# Design & Decision Record (DDR) — Lab 3: CoAP y CBOR sobre Thread
**GreenField Technologies | IoT Systems Design — Proyecto SoilSense**

**Equipo:** Ismael Cortes Ramirez, David Henao Rojas  
**Fase:** Sistema (Lab 3)  
**Evidencia base:** [INFORME.md](INFORME.md) · [registro experimental](evidencias/registro.md)

> Resumen del DDR pedido por la guía del Lab 3. Las cifras vienen de las pruebas
> con dos ESP32-C6 (C = cliente/leader, S = servidor y luego SED) en Thread, canal 25, TX 0 dBm.
> La temperatura y la válvula son simuladas. Las corrientes y autonomías son **estimaciones**: no se midió consumo.

---

## 1. System Overview

*   **System Type:** [ ] Component (Lab 1-2) | [X] System (Lab 3-6) | [ ] Environment (Lab 7-8)
*   **Description:**
    Dos nodos ESP32-C6 en una red Thread. S expone dos recursos CoAP: `/env/temp` (lectura de temperatura, GET y Observe) y `/act/valve` (válvula simulada, PUT/GET). Las representaciones van en CBOR. C actúa como cliente y también como dashboard por consola.

---

## 2. Lab Log & Stakeholder Summaries

### Lab 3: Thread & CoAP

*   **Para Daniela (Cliente):**
    "Ahora la lectura llega cuando cambia, no cada vez que alguien pregunta. Con Observe, en 300 s hubo 29 avisos por cambio de más de 0.5 °C, en lugar de 300 consultas a 1 Hz. Eso reduce mensajes, y por tanto uso de radio, pero hay que decir que no medimos consumo: es una estimación. Si no cambia nada, el servidor manda un aviso de confirmación (heartbeat) cada 45 s para que sepas que el nodo sigue vivo."

*   **Para Edwin (Operaciones):**
    "Una orden a la válvula se confirma con el código de respuesta: 2.04 si se aplicó, 4.00 si el valor es inválido (el 7 se rechazó). Si el nodo S no está, el mensaje con confirmación (CON) termina en timeout a los ≈92 s; el mensaje sin confirmación (NON) solo imprime 'Done' y **no** prueba que llegó. Con el nodo dormido (SED) y sondeo de 5 s, el RTT medio fue 2.1 s y el máximo 4.0 s en 10 pings; cuenta con respuestas de unos segundos. En una válvula real hace falta realimentación física: aquí la válvula es solo estado software."

---

## 3. Architecture Decision Records (ADRs)

**ADR-003: CoAP y CBOR para subida y bajada en el enlace Thread**
*   **Context:**
    SoilSense necesita lecturas actualizadas cuando cambian y saber si una orden se ejecutó, con mensajes pequeños sobre 802.15.4 (trama de 127 B).
*   **Decision:**
    CoAP sobre UDP con representaciones CBOR. Observe con NON para cambios y CON para el heartbeat; PUT CON para fijar la válvula y GET para consultarla.
*   **Rationale:**
    1. Presupuesto de bytes medido: GET temperatura 15 B de solicitud + 17 B de respuesta; notificación Observe 19 B; PUT 18/13 B. El contenido CBOR es de 6 B (temperatura) y 4 B (válvula). Todo cabe holgadamente en un salto (68 B en el peor caso contra 81 B útiles).
    2. MQTT no se eligió para el tramo de radio: requiere un broker accesible y una conexión TCP, y publicar al broker no confirma por sí solo el estado de la válvula. HTTP/JSON añade cabeceras de texto y TCP (referencias de la guía: ≈150 B de solicitud, no medidas aquí).
    3. El ensayo mostró respuesta al mando, rechazo del valor inválido y timeout ante indisponibilidad.
*   **Status:** [X] Accepted | [ ] Proposed | [ ] Deprecated

**ADR-004: Periodo de sondeo de 5 s para la válvula a batería**
*   **Context:**
    Un nodo dormido (SED) pregunta a su padre cada T. Menor T baja la latencia pero sube el consumo.
*   **Decision:**
    Sondeo de 5000 ms, PUT idempotente CON, comprobación del estado con GET y cierre local temporizado.
*   **Rationale:**
    1. RTT ICMP medido (10/10 respuestas, 0 % de pérdida): sondeo 1 s → promedio 465.6 ms; 5 s → promedio 2119 ms, máx. 4039 ms; 15 s → promedio 8489 ms, máx. 14461 ms.
    2. Estimación de corriente media: 0.918 mA (1 s), **0.328 mA (5 s)**, 0.229 mA (15 s), con 10 ms de RX por sondeo. Autonomía ideal con 3000 mAh: 136 / **381.5** / 545 días.
    3. Con 5 s puede iniciar un reintento CoAP antes del siguiente sondeo; se observaron dos entregas del mismo PUT, inocuas por ser idempotente.
*   **Status:** [ ] Accepted | [X] Proposed | [ ] Deprecated  
    *(Pendiente de aceptación por operación: el objetivo de 5 s es una hipótesis del informe, no un requisito de Edwin.)*

---

## 4. ISO/IEC 30141 Mapping

### Domain Mapping

| Componente | Dominio ISO | Justificación |
|---|---|---|
| Contrato `/env/temp` (URI, GET/Observe, CBOR, Max-Age) | ASD | Interfaz de servicio de la aplicación |
| Contrato `/act/valve` (PUT idempotente, `{v:0/1}`) | ASD | Interfaz de servicio de control |
| CDDL (`env-reading`, `valve-state`) | ASD | Define y valida el formato de intercambio |
| Thread, IPv6/UDP y sondeo al padre | SCD | Subsistema de comunicación del dispositivo |
| ESP32-C6 S y C | SCD | Dispositivos de sensado/control |
| Temperatura y estado físico de la válvula | PED | Magnitudes del entorno físico (simuladas en el laboratorio) |

```cddl
env-reading = { t: float16 }
valve-state = { v: 0 / 1 }
```

### Component Capabilities

| Categoría | Subcategoría | Componente / Característica | Activa/Latente | Lab |
|---|---|---|:---:|:---:|
| Data | Processing | Codificación/decodificación CBOR | Activa | 3 |
| Interface | Network | CoAP/UDP sobre Thread | Activa | 3 |
| Transducer | Actuating | Válvula simulada (`/act/valve`) | Activa | 3 |
| Supporting | Energy | Sondeo SED / light-sleep | Latente | 3 |

---

## 5. First Principles Reflections

**Lab 3:**
1. **¿Por qué CoAP usa UDP y HTTP necesita TCP? ¿Qué devuelve CON y qué cede NON?** CoAP agrega por sí mismo correlación, detección de duplicados y, en CON, confirmación y retransmisiones acotadas, así que no depende de una conexión. CON devuelve confirmación y reintentos; NON cede ambos. El "Done" inmediato significa que la CLI aceptó el envío, no que S ejecutó la orden.
2. **¿Por qué Observe ahorra batería frente a un GET cada 60 s?** S sabe cuándo cambia su lectura y avisa sin que C consulte. En 300 s hubo 29 notificaciones frente a 300 consultas a 1 Hz (≈10.3 veces menos), pero **frente a un GET cada 60 s serían solo ≈5 consultas**, así que esta muestra no demuestra ahorro. El ahorro depende de cuánto varíe la señal y de la frescura que se exija, no es automático.
3. **¿Por qué el SED recibió el mismo PUT dos veces y por qué fue inocuo?** El sondeo de 5 s supera la primera espera CON de 2–3 s, así que C reintentó mientras S dormía; S registró "OPEN" y "OPEN, no change" con 131 ms de diferencia. Fijar OPEN es idempotente. Un comando "toggle" habría abierto y vuelto a cerrar la válvula.
4. **¿Por qué CBOR y no una estructura binaria propia?** CBOR codifica tipos y campos sin depender de alineación ni del compilador, y CDDL deja el contrato explícito y validable. Para evolucionar hay que definir versiones y campos opcionales. Float16 cuantiza (25.546875 °C en la muestra).

---

## 6. Performance Baselines

| Métrica | Meta | Medido | Estado |
|---|---|---|---|
| Lab 3: CoAP Latency | < 200 ms | ≈44 ms promedio (50/17/67 ms en video a 60 fps, ±33 ms; tiempo visible en consola, no RTT RF) | [X] Pass |
| Lab 3: Poll Latency (periodo 5 s) | < 5 s | 2.119 s promedio; 4.039 s máx. (10 pings ICMP) | [X] Pass (muestra de 10, sin garantía) |

### Estimación de energía de una válvula SED

Fuente: ESP32-C6 Datasheet v1.5, §5.6: tabla 5-9 (RX 802.15.4: **74 mA**) y tabla 5-11 (light-sleep: **180 µA**). Modelo: `I_media = f·74 + (1−f)·0.180 mA`, con `f = 0.010 / T` (10 ms de radio por sondeo) y 2×AA ≈ 3000 mAh ideales.

| Sondeo T | I media (mA) | Autonomía ideal (días) |
|---|---:|---:|
| 1 s | 0.9182 | 136.1 |
| **5 s** | **0.3276** | **381.5** |
| 15 s | 0.2292 | 545.3 |

No incluye TX, CPU, sensor, reintentos, pérdidas del regulador ni autodescarga; no predice la batería real.

---

## 7. Ethics & Sustainability Checklist

*   [X] **Lab 3 (Seguridad):** si la válvula recibe OPEN y la red muere antes del CLOSE, debe cerrar sola por una política local independiente de la red. Propuesta: concesión máxima de **60 s** desde la primera apertura, sin que un OPEN repetido reinicie el plazo; al arrancar, partir de CLOSED. *Propuesta no implementada ni validada en el firmware.* El LED no demuestra cierre hidráulico real.
*   [X] **Lab 3 (Red propia):** solo se usó la red de laboratorio; al cerrar, S volvió a `rdn` y Thread/interfaz quedaron detenidos en ambas placas.

---

## 8. Viewpoint Analysis

| Viewpoint | Labs | Concerns documentados |
|---|---|---|
| Functional | 3 | Contratos de API como entradas ASD; Thread/UDP como SCD |
| Usage | 3 | Confirmación de órdenes, tiempos de respuesta esperados para operación |

---

## Límites de la evidencia

No hay captura RF, medición de consumo ni validación de una válvula real. El timeout de ≈92 s es un cronometraje aproximado del usuario. Faltan el lugar de la sesión y el commit exacto cargado en las placas. Estas limitaciones se conservan tal cual en el [informe](INFORME.md).
