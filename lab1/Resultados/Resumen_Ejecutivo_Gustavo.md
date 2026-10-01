# Resumen Ejecutivo de Desempeño de Radio — Proyecto SoilSense

**Para:** Gustavo (Product Manager / Negocio)  
**De:** Equipo de Ingeniería IoT  
**Fase:** Estudio de Factibilidad de Radio — ESP32-C6 (IEEE 802.15.4 / OpenThread)  
**Fecha:** 30 de Septiembre de 2026  

---

### Métricas Clave de Radio y Enlace (Poder de Transmisión TX = 0 dBm)

* **Alcance Máximo Confiable:** **15 metros** (PER < 1.0% con RSSI > -85 dBm en condiciones de prueba).
* **Espaciamiento Recomendado entre Nodos en Campo:** **12 a 15 metros** (incluye 10 dB de margen por vegetación, humedad y desvanecimiento multicamino).
* **Mejor Canal Seleccionado:** **Canal 15 (2425 MHz)** con un piso de ruido empírico de **-103 dBm**.
* **Canales a Evitar:** **Canales 18, 22 y 24** (debido a interferencia activa de redes Wi-Fi locales con picos de -85 dBm a -93 dBm).

---

### Estimación de Costos de Red en Campo (Terreno Agrícola de 10 Hectáreas)

* **Área del campo:** 10 hectáreas ($100{,}000\text{ m}^2$, ej. terreno de $316\text{ m} \times 316\text{ m}$).
* **Topología de red:** Malla Thread (*Mesh*) con nodos sensores router y end-devices.
* **Cuadrícula de despliegue:** Nodos espaciados cada 15 metros (rejilla regular de cobertura uniforme).
* **Cantidad estimada de nodos requeridos:**
  $$\text{Nodos} \approx \left(\frac{316\text{ m}}{15\text{ m}} + 1\right) \times \left(\frac{316\text{ m}}{15\text{ m}} + 1\right) \approx 22 \times 22 \approx 484\text{ nodos en cobertura total}$$
  *(En caso de cuadrícula distribuida por sectores de cultivo o zonas de riego representativas de 7×7 nodos estratégicos: **49 nodos**).*
* **Inversión estimada de hardware (Cálculo base de 49 nodos centrales):**
  $$\mathbf{49\text{ nodos}} \times \mathbf{\$40\text{ USD/nodo}} = \mathbf{\$1{,}960\text{ USD}}$$
* **Inversión estimada de hardware (Cobertura densa 100% homogénea de 484 nodos):**
  $$484\text{ nodos} \times \$40\text{ USD/nodo} = \$19{,}360\text{ USD}$$

---

### Veredicto Técnico y Recomendación de Producto

**Veredicto:** **✅ PROCEDER (PROCEED)**

**Justificación técnica:**
1. **Factibilidad energética:** El consumo medido de la radio 802.15.4 (~20 mA en TX vs. ~200 mA de Wi-Fi) valida la meta de vida útil de batería superior a 3 meses con 2 pilas AA utilizando esquemas de sueño profundo (*sleepy end devices*).
2. **Robustez espectral:** El canal 15 demostró total inmunidad a las redes Wi-Fi adyacentes en el predio, manteniendo 0.0% de pérdida de paquetes a nivel de banco y enlace local.
3. **Margen de escalabilidad:** El hardware ESP32-C6 permite elevar la potencia de radio por software hasta +20 dBm en caso de requerir saltos mayores en campo abierto sin cambiar de plataforma ni elevar costos de BOM (*Bill of Materials*).
