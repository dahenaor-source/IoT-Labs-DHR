# Design & Decision Record (DDR) — Lab 5: Border Router (OTBR) y acceso desde el PC
**GreenField Technologies | IoT Systems Design — Proyecto SoilSense**

**Equipo:** Ismael Cortes Ramirez, David Henao Rojas  
**Evidencia base:** [INFORME.md](INFORME.md) · [registro](evidencias/registro.md)

---

## 1. System Overview

*   **System Type:** [ ] Component | [X] System (Lab 3-6) | [ ] Environment
*   **Description:** Se añade un OpenThread Border Router: ESP32-S3 N16R8 como BR con un ESP32-C6 como RCP por UART (GPIO5/4), Wi-Fi hacia el hotspot. S (sensor + válvula simulada) y C siguen en Thread (canal 25, TX 0 dBm). Un PC y un celular acceden a S por CoAP/IPv6 y a Internet vía NAT64.

---

## 2. Lab Log & Stakeholder Summaries

### Lab 5: Border Router

*   **Para Daniela (Cliente):** "Ya se ve el sensor desde el PC y el celular con un dashboard (Observe y LED como válvula). Mediana de 33 ms por CoAP (30–49 ms). Si el router de borde se apaga, el PC pierde acceso (NetworkError) pero el control local entre C y S sigue funcionando; al volver el BR, el GET devolvió 2.05 con 23.5 °C. Un solo BR es un punto único de falla para el acceso remoto."

---

## 3. Architecture Decision Records (ADRs)

**ADR-007 (ADR-005 en la plantilla del curso): Un solo OTBR para el piloto**
*   **Context:** Se necesita acceso desde PC/celular y a IPv4 sin cambiar el firmware de S.
*   **Decision:** Un OTBR (S3 + RCP C6) con prefijo OMR y NAT64.
*   **Rationale:** Conectividad medida PC→S 10/10 (32 ms), NAT64 10/10 (53 ms), mesh interno 10/10 (13.3 ms). El control interno sobrevive sin BR. Riesgos: punto único de falla para acceso externo; el BR usa ajustes RAM (tras reinicio hubo que restaurar Wi-Fi y dataset); el shell del BR no tiene autenticación.
*   **Status:** [ ] Accepted | [X] Proposed | [ ] Deprecated  
    *(La numeración ADR-007 evita chocar con el ADR-005 de frescura del Lab 4.)*

---

## 4. ISO/IEC 30141 Mapping

El OTBR es un **IoT gateway hospedado en SCD** (Tabla A.3, Figura A.5). No es RAID (eso llega en Labs 6–7).

### Scorecard de la Tabla A.3

| Función de gateway | ¿Lo hace hoy? | Evidencia |
|---|---|---|
| Conversión de protocolo | Sí | Thread/802.15.4 ↔ Wi-Fi/IP |
| Mapeo de direcciones | Sí | Prefijo OMR `fd8e:2e9b:4aee:1::/64`; NAT64 `fd8e:2e9b:4aee:2:0:0::/96` |
| Procesamiento de datos | No | Reenvía, no transforma |
| Fusión de información | No | — |
| Certificación (autenticación) | No | Shell sin autenticación; cualquiera en el hotspot accede → Lab 6 |
| Gestión de equipos | Parcial | `ot child table` / `ot router table` solo por consola |

### Las cuatro redes (Tabla A.4)

| Red | En SoilSense | Dirección vista |
|---|---|---|
| Proximity | Malla Thread (S, C, radio del BR) | mesh-local `fd…` y OMR `fd8e:2e9b:4aee:1:8aeb:e61e:3856:2f91` (S) |
| Access | Wi-Fi del BR y hotspot | IPv4 del BR 192.168.1.13; link-local IPv6 |
| Services | Laptop con dashboard / nube | IPv4 pública (p. ej. 8.8.8.8 vía NAT64 `…:2:0:0:808:808`) |
| User | Celular de Daniela | Asignada por la operadora/hotspot |

---

## 5. First Principles Reflections

1. **Prefijo + SLAAC:** el BR anuncia el prefijo OMR en el Network Data y cada nodo forma su dirección con SLAAC; así S obtiene una dirección alcanzable desde el PC sin configurarlo a mano. En Windows hizo falta una ruta manual (`New-NetRoute`, ActiveStore) hacia el BR.
2. **NAT64:** S solo habla IPv6; el BR sintetiza `…:808:808` para 8.8.8.8 y traduce a IPv4 (10/10, 53 ms).
3. **Bytes de `/env/temp`:** el payload CBOR (6 B) es el mismo en Thread y desde el PC; cambia el trayecto, no el contenido.
4. **Wi-Fi power save:** afecta la latencia del BR; se pidió `wifi ps off` pero no se confirmó su salida, así que queda sin verificar.

---

## 6. Performance Baselines

| Métrica | Meta | Medido | Estado |
|---|---|---|---|
| Lab 5: Latencia añadida por el OTBR | < 100 ms | PC→S 32.1 ms vs C→S 13.3 ms: diferencia ≈ 19 ms (recorridos distintos, no procesamiento exclusivo del BR) | [X] Pass |
| Lab 5: NAT64 RTT | < 200 ms | 53 ms medio (48–61), 10/10 | [X] Pass |

CoAP PC→S: 10/10 `2.05`, mediana 33 ms. Series iniciales de solo 4 muestras. No se midió consumo energético ni recuperación temporizada.

---

## 7. Ethics & Sustainability Checklist

*   [X] **Privacidad/seguridad:** cualquiera en el hotspot puede leer S y comandar la válvula; el shell del OTBR no tiene autenticación. Se aplaza a Lab 6 y no se debe exponer fuera del laboratorio.
*   [X] **Direcciones:** las OMR son ULA, no IPv6 públicas; no se atribuye conectividad IPv6 a WSL.

---

## 8. Viewpoint Analysis

| Viewpoint | Labs | Concerns |
|---|---|---|
| Functional / Enterprise system pattern (A.3, Fig. A.5) | 5 | Gateway en SCD |
| Networking (A.4, Fig. A.6) | 5 | Proximity–Access–Services–User; BR como punto único de falla |

---

## Límites de la evidencia

Faltan desglose de potencia por placa, confirmación de `wifi ps off`, medición del tiempo de recuperación del BR y PNG archivados del dashboard (capturas en el chat). Detalle en el [registro](evidencias/registro.md).
