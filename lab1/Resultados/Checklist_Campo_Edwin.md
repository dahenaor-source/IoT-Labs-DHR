# Tarjeta de Verificación y Diagnóstico en Campo — Proyecto SoilSense

**Destinatario:** Edwin (Operaciones / Técnico de Campo)  
**Equipo:** Nodos Sensores de Humedad y Temperatura SoilSense (ESP32-C6 OpenThread)  
**Herramienta de diagnóstico:** Consola Serial OpenThread (`uart:~$ ot ...`) / Medidor RSSI  

---

## 1. Pautas de Instalación y Alcance por Tipo de Terreno

> **Regla de oro:** Mantener la línea de vista lo más despejada posible y elevar los nodos al menos 50 cm del suelo para evitar atenuación por suelo húmedo.

| Entorno de Despliegue | Separación Máxima Recomendada | RSSI Mínimo Esperado | Observaciones de Instalación |
|:---|:---:|:---:|:---|
| **Línea de vista directa (LOS)** | **15 metros** (a 0 dBm) | > -80 dBm | Sin obstáculos entre antenas; postes elevados. |
| **Vegetación baja / Cultivo joven** | **12 metros** | > -84 dBm | Follaje ligero; revisar que la antena no toque hojas húmedas. |
| **Vegetación densa / Frutales adultos** | **8 a 10 metros** | > -85 dBm | Alto contenido de agua atenúa 2.4 GHz; intercalar nodos repetidores. |
| **Presencia de galpones / Metales** | **5 a 7 metros** | > -85 dBm | Evitar sombras metálicas o reubicar antena en la esquina exterior. |

---

## 2. Árbol de Solución de Problemas (Troubleshooting)

### A. El nodo no se une a la red Thread (`ot state` se queda en `detached`)
1. **Verificar canal operativo:**
   - Ejecutar `ot channel`. Debe coincidir exactamente con el canal de la red (**Canal 15**).
2. **Verificar Dataset y Clave de Red (Network Key):**
   - El dataset debe ser idéntico al del Líder. Si se ingresó a mano, ejecutar `ot factoryreset` y volver a aplicar el dataset activo completo (`ot dataset set active <hex>`).
3. **Obstáculo físico cercano:**
   - Asegurarse de que el nodo no esté dentro de una caja metálica sin antena externa ni adosado a cañerías o estructuras de zinc.
4. **Verificar estado de antena:**
   - Inspeccionar visualmente la antena PCB o conector U.FL para descartar fracturas o contacto con tierra.

---

### B. Pérdida intermitente de paquetes o desconexiones esporádicas
1. **Verificar nivel de señal en la tabla de vecinos:**
   - Ejecutar `ot neighbor table`.
   - Si el `Avg RSSI` es **menor a -85 dBm** (ej. -88 dBm, -92 dBm), el nodo está al límite de sensibilidad.
   - **Solución:** Acercar el nodo 2–3 metros al vecino más cercano o añadir un nodo enrutador intermedio.
2. **Revisar interferencia Wi-Fi en el área:**
   - Si se instaló un nuevo router o repetidor Wi-Fi en la casa de la finca, verificar su canal.
   - Si el router transmite en Wi-Fi 6 o Wi-Fi 11 con alta potencia, ejecutar un escaneo en el nodo:
     ```text
     ot scan energy 500
     ```
   - Si el canal 15 muestra un RSSI superior a -80 dBm de ruido constante, reportar a ingeniería para evaluar cambio coordinado de canal de red.
3. **Puntos ciegos por crecimiento de cultivo:**
   - La humedad en hojas adultas incrementa la atenuación RF. Elevar la altura de montaje del sensor 30–50 cm.

---

## 3. Comandos Rápidos de Verificación en Campo (CLI)

```text
ot state            -> Debe responder "router" o "child" (nunca "detached")
ot ipaddr           -> Muestra las IPs IPv6 activas (RLOC y Link-Local)
ot neighbor table   -> Muestra calidad de enlace con nodos vecinos (Avg RSSI, LQ In)
ot ping <IP_RLOC>   -> Prueba de eco bidireccional (verificar 0% Packet loss)
ot txpower          -> Consulta o ajusta potencia (por defecto: 0 dBm; máximo: 20 dBm)
```
