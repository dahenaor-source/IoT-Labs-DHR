# Lab 3 — CoAP con dos ESP32-C6

**Estado: finalizado por decisión de los integrantes.** Se conservan las
limitaciones de medición y trazabilidad descritas en el informe.

[Guía paso a paso](guia.md) · [Qué enviar de las consolas](EVIDENCIAS.md) ·
[Informe y DDR](INFORME.md) · [Registro](evidencias/registro.md) · [Firmware](firmware/) · [Origen](ORIGEN.md)

- **C**: cliente CoAP y líder de Thread, representa al gateway.
- **S**: servidor de temperatura simulada y válvula representada por el LED RGB.

Una imagen común se carga en ambas. La tercera placa es opcional en el Lab 3
original. No se necesitan sensor físico, válvula externa, Wi-Fi ni broker MQTT.
Target: ESP32-C6 DevKitC, RGB GPIO8, flash de al menos 4 MB; en una de 8 MB se
usan sus primeros 4 MB. Revisa target/LED si alguna placa es otro modelo.

## Preparación en el PC con Zephyr

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab3/tools/build.sh usb
```

Conecta C sola, adjúntala a WSL y verifica su puerto. Si es ttyACM0:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/flash.sh C /dev/ttyACM0 usb
```

Desconecta C, conecta S, verifica el puerto y ejecuta:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/flash.sh S /dev/ttyACM0 usb
```

Se compila una vez y se carga dos veces. Usa el conector ESP32C6/USB nativo.
Para CH343/UART compila con `build.sh uart` y carga con `flash.sh C PUERTO uart`.

Abre una terminal por placa. Ejemplo con ambas conectadas y puertos identificados:

```bash
bash ~/IoT-Labs-DHR/lab3/tools/monitor.sh C /dev/ttyACM0
```

```bash
bash ~/IoT-Labs-DHR/lab3/tools/monitor.sh S /dev/ttyACM1
```

Continúa con [guia.md](guia.md). **Ejecuta `ot coap start` solo en C.** En S el
servidor ya usa UDP 5683; iniciarle el cliente OpenThread interceptaría su tráfico.
No copies el dataset activo a las evidencias: contiene la clave de red.

## Estado

- [x] Firmware C/S, USB/UART, scripts y guía preparados.
- [x] Logs adicionales de tamaños CoAP para válvula y notificaciones.
- [x] Firmware ejecutado en ambas placas y comunicación C/S validada con logs del usuario.
- Log exitoso de carga S no aportado; ejecución posterior sí documentada.
- [x] GET de temperatura y CBOR validados en C/S.
- [x] Válvula: PUT/GET, apertura/cierre, idempotencia y payload inválido documentados.
- [x] Observe: recepción y cancelación documentadas.
- [x] CON/NON: timeout CON ≈92 s, NON sin mensaje adicional reportado y CON posterior a reconexión validado.
- [x] Latencia SED a 1/5/15 s: 10/10 pings en cada ensayo.
- [x] PUT con SED a 5 s: dos entregas, segunda no change.
- [x] Restaurar S a rdn y confirmar válvula cerrada mediante PUT/GET.
- [x] Apagado final de Thread/interfaz confirmado en ambas placas.
- [x] Análisis y estimación de energía con fuentes, hipótesis y cálculo reproducible.
- [x] ADR-003/004, respuestas, resumen y diseño de cierre local documentados.
- [x] Tiempo del GET estimado con tres repeticiones en video: ≈50/17/67 ms; promedio ≈44 ms.
- [x] Integrantes, fecha indicada (2026-10-15), ESP32-C6 y separación de ≈2 m sin obstáculos registrados.
- Lugar, orientación y commit cargado no informados.

La compilación/carga y las mediciones físicas se realizaron en el WSL del usuario;
aquí se verifican scripts, cálculos y documentación. El informe distingue esos
resultados de las estimaciones de energía y las propuestas de diseño.
