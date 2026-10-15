# Design & Decision Record (DDR) — Lab 1: Caracterización de Radio 802.15.4
**GreenField Technologies | IoT Systems Design — Proyecto SoilSense**

**Equipo:** David Henao Rojas 
**Fase:** Estudio de Factibilidad (Feasibility Study)  
**Fecha:** 30 de Septiembre de 2026  

---

## 1. System Overview

*   **System Type:** [X] Component (Lab 1-2) | [ ] System (Lab 3-6) | [ ] Environment (Lab 7-8)
*   **Description:**
    Módulo sensor inalámbrico agrícola de bajo costo basado en el SoC Espressif ESP32-C6 (núcleo RISC-V a 160 MHz) operando sobre el estándar IEEE 802.15.4 en la banda ISM de 2.4 GHz mediante el stack OpenThread en Zephyr RTOS. El sistema está diseñado para monitoreo de humedad y temperatura de suelo en parcelas agrícolas, alimentado por 2 pilas AA con un presupuesto energético promedio inferior a 4.2 mW.

---

## 2. Lab Log & Stakeholder Summaries

### Lab 1: RF Characterization

*   **Para Samuel Cifuentes (Senior Architect):**
    "La caracterización empírica de la radio 802.15.4 en la ESP32-C6 muestra un enlace físico de alcance corto. El canal 25 (2475 MHz) comparte el menor piso de ruido (-104 dBm) y queda fuera de los canales Wi-Fi solapados. Con TX de 20 dBm (el máximo), el PER fue ≤ 1 % a **5 m**, hubo degradación a 10 m (RSSI -91 dBm, PER hasta 3 %), pérdida crítica a 15 m (PER ~97 %) y **desde 20 m la comunicación entre las placas se pierde**. Las pruebas no tuvieron línea de vista totalmente despejada, así que el alcance debe revalidarse. Recomendamos espaciamiento nominal de 5 m (máximo 10 m) en la malla Thread."

*   **Para Edwin (Operaciones / Técnico de Campo):**
    "El canal de operación es el 25, con piso de ruido de -104 dBm. No separes nodos más de 10 m; a 15 m casi no pasan paquetes y desde 20 m no hay enlace. Si hay caídas, revisa primero la distancia al vecino y el `Avg RSSI` en `ot neighbor table` (menor a -80 dBm es zona de riesgo); luego revisa si hay un router Wi-Fi nuevo cerca en el canal 11."

*   **Para Gustavo (Product Manager):**
    "Con un alcance confiable de ~5 m, cubrir una parcela de 10 hectáreas exige unos 4,096 nodos a 5 m de separación (**$163,840 USD** a $40 por nodo) o unos 1,089 nodos a 10 m (**$43,560 USD**). El veredicto técnico es **PROCEDER CON RESERVAS**: hay que repetir las pruebas con línea de vista despejada, evaluar antenas externas o instrumentar solo zonas de riego representativas."

---

## 3. Architecture Decision Records (ADRs)

### ADR-001: Selección de Canal RF 802.15.4 para la Red Agrícola SoilSense
*   **Context:**
    La banda de 2.4 GHz es de uso no licenciado (ISM) y sufre alta congestión por redes Wi-Fi (IEEE 802.11b/g/n), Bluetooth y hornos microondas. Los canales Wi-Fi estándar tienen un ancho de banda de 20 a 22 MHz, mientras que los canales 802.15.4 tienen un ancho de banda de solo 2 MHz con una separación intercanal de 5 MHz (canales 11 al 26). Es imperativo seleccionar un canal que minimice la interferencia destructiva de routers en fincas vecinas.
*   **Decision:**
    Operar la red de sensores SoilSense de forma fija en el **Canal 25 (frecuencia central 2475 MHz)**.
*   **Rationale:**
    1. El escaneo de energía (2026-10-02) arrojó **-104 dBm** en los canales 21, 24 y 25 (empate de menor energía), frente a -96 dBm en los canales 18 y 26.
    2. El canal 25 queda fuera de los canales Wi-Fi solapados (1, 6 y 11), a diferencia del 24, que solapa con Wi-Fi 11.
    3. Pertenece a la banda estándar 11–26, con soporte global.
*   **Status:** [X] Accepted | [ ] Proposed | [ ] Deprecated

---

## 4. ISO/IEC 30141 Mapping

### Domain Mapping (Mapeo de Dominios Arquitectónicos)

```text
+-------------------------------------------------------------+
|                 PED (Physical Entity Domain)                |
|  - Aire / Medio de propagación electromagnética (2.4 GHz)   |
|  - Terreno agrícola, vegetación y humedad de suelo          |
|  - Ruido e interferencia de espectro Wi-Fi (Ch 1, 6 y 11)   |
+------------------------------+------------------------------+
                               ^  (Propagación RF)
                               v
+-------------------------------------------------------------+
|              SCD (Sensing & Controlling Domain)             |
|  - Antena PCB integrada ESP32-C6 (Acoplo radiante)          |
|  - Transceptor de Radio IEEE 802.15.4 (Capa PHY / MAC)      |
|  - Microcontrolador ESP32-C6 RISC-V (Stack OpenThread)      |
|  - Actuador LED integrado (WS2812 / GPIO de diagnóstico)    |
+-------------------------------------------------------------+
```

| Componente | Dominio ISO/IEC 30141 | Justificación Técnica |
|---|:---:|---|
| **SoC ESP32-C6 (MCU)** | **SCD** | Dispositivo sensor/controlador principal (§6.4–6.5) que ejecuta la lógica de aplicación y procesamiento. |
| **Radio 802.15.4 + Antena** | **SCD** | Subsistema de comunicación del dispositivo que traduce tramas binarias a ondas electromagnéticas. |
| **Aire / Medio RF (2.4 GHz)** | **PED** | Entidad física pasiva por donde viajan las ondas electromagnéticas, sujeta a pérdida de trayectoria. |
| **Interferencia Wi-Fi circundante**| **PED** | Fuentes electromagnéticas externas en el entorno físico que degradan la relación señal a ruido (SNR). |

*El enlace entre nodos evaluado corresponde al patrón **Proximity Networking** (Red de Proximidad) de la norma.*

### Component Capabilities (Capacidades del Componente — ISO/IEC 30141 §9)

| Categoría de Capacidad | Subcategoría | Componente / Característica | Estado en Lab 1 | Justificación de Estado |
|---|---|---|:---:|---|
| **Transducer** | Actuating | LED de estado en placa (WS2812) | **Activa** | Proporciona indicación visual del estado del nodo y pruebas de radio. |
| **Data** | Storage / Processing | Filtro de RSSI / Almacenamiento NVS | **Activa** | NVS guarda el dataset activo de Thread; la radio procesa métricas LQI y RSSI. |
| **Interface** | Network / UI | Red 802.15.4 / Shell CLI OpenThread | **Activa** | Permite control por línea de comandos y transmisión de paquetes IPv6/ICMPv6. |
| **Supporting** | Security / Clock | Acelerador criptográfico por HW (AES) | **Latente** | Soportado en silicio pero no explotado a nivel de aplicación en esta fase. |
| **Latent** | Alternative Radio | Radios Wi-Fi 6 (802.11ax) y BLE 5.3 | **Latente** | Presentes en el SoC pero deshabilitadas intencionalmente para conservar batería. |

---

## 5. First Principles Reflections (Preguntas Fundamentales de Diseño)

### 1. ¿Por qué el RSSI cae con la distancia?
El decaimiento de la potencia recibida con la distancia responde al principio de conservación de energía y la **Ley del Cuadrado Inverso**. Una antena isotrópica irradia energía en forma de esfera en expansión. A medida que la distancia $d$ se incrementa, el área superficial de la esfera de radiación crece proporcionalmente a $4\pi d^2$, por lo que la densidad de potencia del frente de onda electromagnético ($\text{W/m}^2$) disminuye a una tasa cuadrática.  
En escala logarítmica (dBm), la ecuación de transmisión de Friis en espacio libre establece:
$$\text{FSPL (dB)} = 20\log_{10}(d) + 20\log_{10}(f) + 32.45$$
Cada vez que se **duplica la distancia**, la potencia recibida cae aproximadamente **6 dB** en espacio libre (y entre 8 y 12 dB en entornos reales con absorción por follaje y rebote en el suelo).

### 2. El receptor detecta señales hasta -100 dBm; ¿por qué se requirió > -85 dBm para tener < 1% de pérdidas (PER)?
Existe una diferencia fundamental entre la **sensibilidad mínima de recepción** (umbral de detección de preámbulo) y la recepción de tramas complejas con **tasa de error de paquete despreciable**. Los ~15 dB de diferencia se deben a:
1. **Piso de ruido térmico y SNR requerido:** Para demodular la señal O-QPSK con un Bit Error Rate (BER) inferior a $10^{-5}$, se requiere una relación señal a ruido (SNR) mínima de aproximadamente 3 a 5 dB sobre el piso de ruido.
2. **Margen de desvanecimiento (*Fade Margin*):** Las ondas de radio rebotan en el suelo, tallos y cuerpos en movimiento, generando interferencia constructiva y destructiva (*desvanecimiento multicamino de Rayleigh/Rician*). Un margen de 10 a 15 dB garantiza que los valles de atenuación instantáneos no sumerjan la señal por debajo del umbral de detección del receptor.
3. **Pérdida por polarización y desalineación de antenas:** Variaciones angulares entre nodos en campo introducen pérdidas adicionales de 3 a 6 dB.

### 3. ¿Cómo sobrevive la radio 802.15.4 a la interferencia de Wi-Fi en la misma banda de 2.4 GHz?
La modulación IEEE 802.15.4 utiliza **DSSS (Direct Sequence Spread Spectrum)** combinada con **O-QPSK (Offset Quadrature Phase Shift Keying)**:
- Cada grupo de 4 bits de datos se mapea a un símbolo pseudo-aleatorio cuasi-ortogonal de **32 chips** (a una tasa de modulación de 2 Mchip/s para entregar 250 kbps de datos útiles).
- Al recibir la señal, el correlador del receptor multiplica la señal por la misma secuencia pseudo-aleatoria. Esto genera una **ganancia de procesamiento (*Processing Gain*)** teórica de:
  $$G_p = 10\log_{10}\left(\frac{32\text{ chips}}{4\text{ bits}}\right) \approx 9\text{ dB}$$
- Cualquier interferencia de banda ancha (como una portadora Wi-Fi) que no posea la secuencia de correlación específica es desparramada como ruido de fondo plano, permitiendo recuperar la trama incluso con una señal Wi-Fi superpuesta moderada.

---

## 6. Performance Baselines

| Métrica | Meta / Target | Medido Empíricamente | Estado |
|---|:---:|:---:|:---:|
| **Lab 1: Alcance Máximo Confiable (PER ≤ 1%)** | > 10 m (20 dBm) | **5 m** (15 m: PER ~97 %; ≥ 20 m: sin comunicación) | [ ] Fail |
| **Lab 1: Pérdida de paquetes en banco (~1m)** | < 1.0% | **0.0%** (100/100 pings) | [X] Pass |
| **Lab 1: RTT de Ping bidireccional (64 bytes)** | < 30 ms | **14.2 ms** (promedio) | [X] Pass |
| **Lab 1: Piso de ruido en canal óptimo (Ch 25)**| < -90 dBm | **-104 dBm** | [X] Pass |

---

## 7. Ethics & Sustainability Checklist

*   [X] **Lab 1 (Espectro responsable):** Se utilizó escaneo pasivo de energía antes de transmitir, sin generar interferencia perjudicial a redes circundantes ni emplear técnicas de emisión fuera de norma.
*   [X] **Lab 1 (Eficiencia energética):** Se validó la radio de 20 mA frente al uso de Wi-Fi de 200 mA, reduciendo el desecho de baterías en entornos agrícolas.
*   [X] **Lab 1 (Potencia mínima necesaria):** La referencia inicial se hizo a 0 dBm; la serie de alcance usó 20 dBm solo durante las pruebas, confinadas al área de prueba sin saturar el espectro del vecindario.
