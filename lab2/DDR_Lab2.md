# Design & Decision Record (DDR) — Lab 2: Malla Thread y direccionamiento IPv6
**GreenField Technologies | IoT Systems Design — Proyecto SoilSense**

**Equipo:** David Henao Rojas  
**Evidencia base:** [guía](guia.md) · [registro](evidencias/registro.md)

> **Estado:** el registro experimental del Lab 2 aún está en "Pendiente" (sin mediciones ni tercer nodo). Este DDR contiene el diseño y la teoría; **todo valor medido está marcado como pendiente y no se inventó ninguno.**

---

## 1. System Overview

*   **System Type:** [X] Component (Lab 1-2) | [ ] System | [ ] Environment
*   **Description:** Malla Thread de ESP32-C6 sobre 802.15.4 (canal 25) con direccionamiento IPv6 (6LoWPAN). Se estudia el autocurado de la malla y qué direcciones debe usar el firmware.

---

## 2. Lab Log & Stakeholder Summaries

### Lab 2: Malla Thread

*   **Para Edwin (Operaciones):**
    *Healing time:* **pendiente de medir** (meta < 120 s). Si un nodo se apaga, un técnico revisa: `ot state` (rol), `ot router table`, `ot neighbor table` y `ot ping` al ML-EID del nodo; si los vecinos lo marcan como caducado, el problema es del nodo o su enlace, no de la malla.
*   **Para Samuel (Finanzas):**
    Cada salto adicional agrega latencia y consumo de los routers, pero evita desplegar un gateway por zona. El **costo por salto** concreto queda pendiente de medir con ping a 1 y 2 saltos. El firmware debe usar la dirección **ML-EID**, estable aunque cambie la topología (no el RLOC ni la link-local).

---

## 3. Architecture Decision Records (ADRs)

**ADR-002: Malla Thread en lugar de estrella tipo LoRaWAN**
*   **Context:** Parcelas amplias, nodos a batería y enlaces ocasionales de baja calidad.
*   **Decision:** Malla Thread con routers y end devices.
*   **Rationale:** Sin punto único de falla en la radio local, rutas alternativas por autocurado, IPv6 nativo sin traducción. Lab 1 mostró alcance limitado (comunicación perdida desde ~20 m a 20 dBm), lo que favorece una malla de múltiples saltos.
*   **Status:** [ ] Accepted | [X] Proposed | [ ] Deprecated  
    *(Se acepta cuando se mida el healing time.)*

---

## 4. ISO/IEC 30141 Mapping

### Clasificación de direcciones

| Dirección | Alcance | Uso |
|---|---|---|
| Link-local `fe80::` | Un salto | Vecinos directos |
| ML-EID (mesh-local `fd…`) | Toda la malla | **La que usan las aplicaciones** (estable) |
| RLOC | Malla, ligada a la topología | Enrutamiento interno; cambia al reconfigurarse |
| Global/OMR | Fuera de la malla | Con border router (Lab 5) |

### Roles Thread

| Rol | Función | Dominio |
|---|---|---|
| Leader | Gestiona IDs de router y Network Data | SCD |
| Router | Reenvía tráfico | SCD |
| REED | Candidato a router | SCD |
| End device (FED/MED) | Hoja siempre despierta | SCD |
| Sleepy end device (SED) | Duerme y sondea al padre | SCD |

Sensores/actuadores conectados: PED; comunicación y firmware: SCD; consumo por ASD en labs posteriores.

---

## 5. First Principles Reflections

1. **Header IPv6 de 40 B en un frame de 127 B:** 6LoWPAN comprime la cabecera (IPHC) omitiendo prefijos y campos derivables del contexto y del MAC; el receptor reconstruye el interface ID a partir de la dirección corta/EUI-64 del frame.
2. **Por qué el healing tarda segundos y no minutos:** los routers intercambian anuncios MLE con periodos de segundos y reenvían por la ruta de menor coste; al caducar un vecino se recalcula sin intervención humana.
3. **Por qué el enlace A–C debe ser pobre y no inexistente:** si no existe, no hay ruta alternativa que recuperar; si es pobre, la malla lo usa solo cuando el camino bueno (vía B) cae.
4. **Por qué las aplicaciones usan ML-EID:** no cambia con la topología, a diferencia del RLOC.

---

## 6. Performance Baselines

| Métrica | Meta | Medido | Estado |
|---|---|---|---|
| Lab 2: Healing Time | < 120 s | **Pendiente** (sin medición) | [ ] Pass  [ ] Fail |

---

## 7. Ethics & Sustainability Checklist

*   [X] Se trabaja solo en la red propia de laboratorio (dataset propio, canal 25).
*   [X] Los routers siempre activos consumen más energía que los SED: la asignación de roles debe considerar la batería.
