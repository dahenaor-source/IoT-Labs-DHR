# Resumen Ejecutivo de Desempeño de Radio — Proyecto SoilSense

**Para:** Gustavo (Product Manager / Negocio)  
**De:** David Henao Rojas
**Fase:** Estudio de Factibilidad de Radio — ESP32-C6 (IEEE 802.15.4 / OpenThread)  
**Fecha:** 30 de Septiembre de 2026  

---

### Métricas Clave de Radio y Enlace (TX = 20 dBm, medidas reales)

* **Alcance Máximo Confiable:** **5 metros** (PER ≤ 1 %, RSSI ≈ -78/-80 dBm).
* **Degradación:** a **10 metros** el enlace sigue vivo pero con RSSI de -91 dBm y hasta 3 % de pérdida.
* **Pérdida crítica:** a **15 metros** se pierde ~97 % de los paquetes. **Desde 20 metros la comunicación entre nodos se pierde por completo.**
* **Espaciamiento Recomendado entre Nodos en Campo:** **5 metros** (máximo absoluto 10 m con redundancia de rutas). Las pruebas no tuvieron línea de vista totalmente despejada; con antenas elevadas y LOS el alcance podría mejorar, pero debe confirmarse.
* **Mejor Canal Seleccionado:** **Canal 25 (2475 MHz)** con un piso de ruido empírico de **-104 dBm**.
* **Canales con más ruido:** **18 y 26** (-96 dBm).

---

### Estimación de Costos de Red en Campo (Terreno Agrícola de 10 Hectáreas)

* **Área del campo:** 10 hectáreas (100,000 m², ej. terreno de 316 m × 316 m).
* **Topología de red:** Malla Thread (*Mesh*) con nodos sensores router y end-devices.
* **Escenario conservador (separación de 5 m):** (316 / 5 + 1)² ≈ 64 × 64 ≈ **4,096 nodos**.  
  **4,096 nodos × $40 USD/nodo = $163,840 USD**
* **Escenario máximo tolerable (separación de 10 m):** (316 / 10 + 1)² ≈ 33 × 33 ≈ **1,089 nodos**.  
  **1,089 nodos × $40 USD/nodo = $43,560 USD**
* Con un alcance real tan corto, cubrir toda la parcela con malla uniforme es costoso. Una alternativa es instrumentar solo zonas de riego representativas.

---

### Veredicto Técnico y Recomendación de Producto

**Veredicto:** **⚠️ PROCEDER CON RESERVAS (PROCEED WITH CAUTION)**

**Justificación técnica:**
1. **Alcance limitado:** incluso a la potencia máxima (20 dBm) el enlace es confiable solo a ~5 m y se pierde desde 20 m. Esto encarece el despliegue por la densidad de nodos necesaria.
2. **Factibilidad energética:** el consumo de la radio 802.15.4 (~20 mA en TX vs. ~200 mA de Wi-Fi) sigue siendo favorable para baterías, pero 20 dBm consume más que 0 dBm y debe validarse la meta de 3 meses.
3. **Robustez espectral:** el canal 25 tiene el menor piso de ruido medido (-104 dBm) y queda fuera de los canales Wi-Fi solapados.
4. **Siguiente paso:** repetir las mediciones con línea de vista despejada y antenas elevadas, y evaluar otra radio o una antena externa si el alcance no mejora.
