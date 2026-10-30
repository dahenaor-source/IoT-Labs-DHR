# Design & Decision Record (DDR) — Lab 4: Sensor real y Trustworthiness
**GreenField Technologies | IoT Systems Design — Proyecto SoilSense**

**Equipo:** Ismael Cortes Ramirez, David Henao Rojas  
**Evidencia base:** [INFORME.md](INFORME.md) · [registro](evidencias/registro.md)

> Datos de pruebas reales con DS18B20 (GPIO18) en ESP32-C6 sobre Thread, canal 25. Lo no medido se declara como brecha.

---

## 1. System Overview

*   **System Type:** [ ] Component | [X] System (Lab 3-6) | [ ] Environment
*   **Description:** Nodo S con sensor DS18B20 real (lectura cada 2 s, 12 bits) que publica `/env/temp` por CoAP/CBOR con contrato de frescura. Si no hay lectura fresca responde 5.03 con Max-Age 10. La válvula sigue siendo simulada.

---

## 2. Lab Log & Stakeholder Summaries

### Lab 4: Sensor real

*   **Para Edwin (Operaciones):**
    1. Si falla el sensor pero el nodo responde, el dato envejece hasta devolver 5.03; el GET con 5.03 llegó a 61.577 s de la última lectura (sin marca de retirada física).
    2. Si el nodo pierde la red, hay silencio y el GET CON termina en timeout (≈74.1 s). Eso no prueba por sí solo que la placa esté apagada.
    3. El sensor recuperó lecturas al reconectar; tras reset hubo que activar Thread (`ot thread start`) y registrar Observe otra vez. El offset sigue pendiente de una referencia confiable.

---

## 3. Architecture Decision Records (ADRs)

**ADR-005: Contrato de frescura para `/env/temp`**
*   **Context:** Un valor viejo o inválido no debe parecer una lectura actual.
*   **Decision:** Plausibilidad −40 ≤ T < 85 °C; salto > 5 °C entre lecturas rechazado; frescura < 60 s; sin lectura fresca → 5.03 con Max-Age 10; nunca convertir error en 0 °C.
*   **Rationale:** Ruido medido 0.12 °C pico a pico (media 21.542 °C, desviación 0.0321 °C). El filtro no detecta un sesgo plausible inyectado: es un límite documentado.
*   **Status:** [X] Accepted | [ ] Proposed | [ ] Deprecated

---

## 4. ISO/IEC 30141 Mapping

| Componente | Dominio | Justificación |
|---|---|---|
| DS18B20 y temperatura | PED | Magnitud física medida |
| Firmware ESP32-C6 (lectura, validación, Thread) | SCD | Dispositivo de sensado y comunicación |
| Contrato `/env/temp` (5.03, Max-Age, CBOR) | ASD | Interfaz de servicio |

| Categoría | Componente | Activa/Latente |
|---|---|:---:|
| Transducer / Sensing | DS18B20 | Activa |
| Data / Processing | Validación de rango, salto y frescura | Activa |
| Interface / Network | CoAP/Thread, Observe | Activa |

---

## 5. First Principles Reflections

Las respuestas completas están en [INFORME.md](INFORME.md); resumen:
1. **Sensor muerto vs. nodo inaccesible:** el primero responde 5.03 (el nodo vive pero el dato caducó); el segundo produce silencio y timeout CON.
2. **Ruido y resolución:** 12 bits ≈ 0.0625 °C por paso; ruido observado 0.12 °C p-p.
3. **Por qué el filtro no basta:** un valor plausible pero sesgado pasa el rango y el salto.
4. **Por qué hay que re-registrar Observe tras reset:** los observadores no son persistentes.

---

## 6. Performance Baselines

| Métrica | Meta | Medido | Estado |
|---|---|---|---|
| Lab 4: Tiempo para ver un sensor perdido | ≤ 60 s | Caducidad anunciada a 60.636 s; GET 5.03 a 61.577 s | [ ] Pass  [ ] Fail — **no certificado** (no se marcó el retiro físico) |
| Lab 4: Fallas de lectura con radio ocupada | < 5 % | 0/78 en reposo; 0/93 con tráfico | [X] Pass (muestra limitada, ventanas desiguales) |

Extra: ping bajo tráfico 1200 enviados / 1199 recibidos (0.0833 % pérdida), RTT 15/16.098/41 ms. Reincorporación tras `ot thread start`: child en 15.048 s.

---

## 7. Ethics & Sustainability Checklist

*   [X] **Diseño ante dato ausente (propuesta, no implementada):** estado por defecto válvula cerrada / no autorizar nueva apertura con dato inválido. Plazo operativo propuesto de 5 s desde una consulta sin respuesta (hipótesis a acordar con operación). Cierre local independiente con concesión máxima inicial de 60 s desde la primera apertura, sin renovar por duplicados. Un actuador real necesita posición/caudal y estado seguro ante falla eléctrica; el LED solo es estado software.

---

## 8. Viewpoint Analysis

| Perspectiva | Dominios | Labs | Evidencia y brechas |
|---|---|---|---|
| Trustworthiness | PED, SCD, ASD | 4 | Contrato con frescura; ruido, inyecciones, dos modos de falla, tráfico y reset. Brechas: referencia, sincronización, comparación, seguridad desplegada |

---

## 9. Trustworthiness Audit

| Característica | Evidencia | Brecha |
|---|---|---|
| Disponibilidad | GET fresco; caducidad y 5.03; timeout si nodo aislado; GET vuelve al recuperar red | No certifica detección ≤ 60 s |
| Integridad frente a fallas | Ruido 0.12 °C; rango/salto rechazados | Offset sin referencia; sesgo plausible pasa |
| Fiabilidad | 0/78 y 0/93 lecturas fallidas | Muestra limitada, ventanas desiguales |
| Resiliencia | Reintentos recuperan el sensor; reset recupera lectura | Red de inicio manual; observadores no persistentes; reinserción no medida |
| Seguridad operativa | Diseño de estado cerrado y cierre local | No implementado ni probado en actuador físico |
| Confidencialidad / atacantes | Fuera de alcance | → Lab 6 |
| Cumplimiento | Contratos, CDDL, evidencias trazables | No se afirma certificación ISO |
