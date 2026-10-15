# Tablas de Mediciones de Radio — Lab 1: ESP32-C6 (802.15.4 / OpenThread)

**Proyecto:** SoilSense — GreenField Technologies  
**Hardware:** 2× ESP32-C6-DevKitC-1 (SoC RISC-V con radio IEEE 802.15.4)  
**Entorno de prueba:** WSL2 Ubuntu 24.04 + Zephyr RTOS v4.4.0 (OpenThread Shell)  
**Puertos seriales:**  
- **Dispositivo A (Líder / Leader):** `/dev/ttyACM0`  
- **Dispositivo B (Enrutador / Router):** `/dev/ttyACM1`  

---

## 1. Escaneo de Energía de Canales (Part 2 — Energy Scan)

Comando ejecutado en Dispositivo A con radio en escucha pasiva (500 ms por canal):
```text
ot ifconfig up
ot scan energy 500
```

### Resultados Empíricos Obtenidos (sesión del 2026-10-02):

| Canal 802.15.4 | Frecuencia Central (MHz) | RSSI Medido (dBm) | Observaciones |
|:---:|:---:|:---:|:---|
| 11 | 2405 | -102 | Solapa con Wi-Fi Ch 1 |
| 12 | 2410 | -101 | Solapa con Wi-Fi Ch 1 |
| 13 | 2415 | -102 | Solapa con Wi-Fi Ch 1 |
| 14 | 2420 | -102 | Solapa con Wi-Fi Ch 1 |
| 15 | 2425 | -103 | Hueco entre Wi-Fi Ch 1 y Ch 6 |
| 16 | 2430 | -103 | Solapa con Wi-Fi Ch 6 |
| 17 | 2435 | -99 | Solapa con Wi-Fi Ch 6 |
| 18 | 2440 | -96 | Centro de Wi-Fi Ch 6 (ruido leve) |
| 19 | 2445 | -103 | Solapa con Wi-Fi Ch 6 |
| 20 | 2450 | -101 | Hueco entre Wi-Fi Ch 6 y Ch 11 |
| 21 | 2455 | -104 | Empate de menor energía |
| 22 | 2460 | -103 | Centro de Wi-Fi Ch 11 |
| 23 | 2465 | -103 | Solapa con Wi-Fi Ch 11 |
| 24 | 2470 | -104 | Empate de menor energía; solapa Wi-Fi Ch 11 |
| **25** | 2475 | **-104** | **Empate de menor energía; canal elegido (hueco sobre Wi-Fi Ch 11)** |
| 26 | 2480 | -96 | Ruido leve |

**Conclusión de selección (ADR-001):**  
Se seleccionó el **Canal 25 (2475 MHz)**: comparte el menor nivel de energía (**-104 dBm**) con los canales 21 y 24, pero queda fuera de los canales Wi-Fi solapados. Los canales 18 (-96 dBm) y 26 (-96 dBm) mostraron el ruido más alto.

---

## 2. Parámetros de la Red Thread Formada

- **Canal operativo:** 25
- **Potencia de transmisión:** `0 dBm` en la referencia inicial a ~1 m; `20 dBm` en ambas placas para la serie de 5–15 m (`ot txpower`).
- **Roles:** Dispositivo A (`/dev/ttyACM0`) = `leader`; Dispositivo B (`/dev/ttyACM1`) = `router`.
- **Dataset / clave de red:** no se publican en este repositorio. Las direcciones RLOC cambian al reunirse a la red y se consultan con `ot ipaddr rloc` antes de cada prueba.

---

## 3. Pruebas de Ping y Calidad de Enlace (Línea Base Banco de Pruebas ~1m)

Comando: `ot ping <RLOC_DESTINO> 64 100 0.2` (100 paquetes ICMPv6 de 64 bytes enviados a 200 ms de intervalo).

### Resultados de Transmisión:
| Dirección del Tráfico | Paquetes Tx | Paquetes Rx | PER (% Pérdida) | RTT Mín (ms) | RTT Prom (ms) | RTT Máx (ms) |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **Dispositivo A → Dispositivo B** | 100 | 100 | **0.0%** | 14 ms | 14.31 ms | 20 ms |
| **Dispositivo B → Dispositivo A** | 100 | 100 | **0.0%** | 14 ms | 14.18 ms | 21 ms |

### Tabla de Vecinos (`ot neighbor table`):
| Lector de la Métrica | Vecino Evaluado | RLOC16 | Avg RSSI (dBm) | Last RSSI (dBm) | Link Quality In (LQ In) |
|:---|:---|:---:|:---:|:---:|:---:|
| **Dispositivo A (recibe de B)** | Dispositivo B | `0x4c00` | **-66 dBm** | -67 dBm | 3 (Excelente) |
| **Dispositivo B (recibe de A)** | Dispositivo A | `0xbc00` | **-67 dBm** | -66 dBm | 3 (Excelente) |

*Simetría de enlace: 1 dB de diferencia entre A y B (dentro de la tolerancia esperada para antenas PCB on-board).*

---

## 4. Caracterización de Alcance vs. Distancia (RSSI & Packet Error Rate - PER)

Mediciones reales (2026-10-13), canal 25, **TX = 20 dBm en ambas placas**, 100 pings de 64 bytes por dirección a 0.2 s, ejecutados de forma secuencial. La fila de 1 m es la referencia de la sesión inicial (0 dBm), no forma una serie de potencia constante con el resto.

| Distancia (m) | RSSI A→B (dBm) | RSSI B→A (dBm) | PER A→B (%) | PER B→A (%) | LQ In (A→B / B→A) | Estado del Enlace |
|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| **1** (0 dBm) | -66 | -67 | 0.0 | 0.0 | 3 | ✅ Enlace perfecto |
| **5** | -78 | -80 | 1.0 | 0.0 | 3 / 2 | ✅ Límite confiable (PER ≤ 1%) |
| **10** | -91 | -91 | 0.0 | 3.0 | 1 / 1 | 🟡 Degradación leve |
| **15** | -80 | -86 | 98.0 | 96.0 | 2 / 2 | ❌ Pérdida crítica |
| **≥ 20** | — | — | — | — | — | ❌ **Comunicación perdida** (sin enlace entre placas) |

Notas:
- La prueba se detuvo en 15 m por pérdida casi total de paquetes. A partir de **20 m** el equipo reporta que **la comunicación entre las placas se pierde por completo**; no hay mediciones numéricas en esa zona.
- A 15 m el RSSI promedio (-80 / -86 dBm) parece aceptable, pero el PER fue ~97 %: el RSSI promedio por sí solo no garantiza un enlace útil en esas condiciones.
- La línea de vista **no estuvo completamente despejada** durante las pruebas, lo que explica la variación anormal de RSSI y PER entre puntos (por ejemplo, 10 m con RSSI más bajo que 15 m).

---

## 5. Resumen de Umbrales Críticos

- **Sensibilidad del receptor ESP32-C6:** -100 dBm (teórica según datasheet).
- **Piso de ruido medido en el canal elegido (25):** -104 dBm.
- **Alcance confiable medido (PER ≤ 1 %), TX 20 dBm:** **5 metros**.
- **Alcance utilizable con degradación (PER ~3 %):** **10 metros**.
- **Pérdida crítica:** **15 metros** (PER ~97 %).
- **Comunicación perdida:** **20 metros en adelante**.
- **Nota operativa:** 20 dBm es la potencia máxima del hardware; no hay margen adicional de potencia para ganar alcance. El siguiente paso es repetir las pruebas con línea de vista despejada y antenas elevadas.
