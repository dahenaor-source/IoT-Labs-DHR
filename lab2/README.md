# Lab 2 — adaptación para dos ESP32-C6

[Firmware](firmware/) · [Instrucciones A/B](guia.md) · [Registro](evidencias/registro.md) · [Origen](ORIGEN.md)

La misma imagen se carga en **A y B**. A crea la red y B se une usando su dataset.
Los roles los elige OpenThread; se espera A como líder y B como router.
El LED muestra azul (leader), verde (router), amarillo (child), rojo (detached)
y apagado (disabled); también se puede consultar `ot state`.

Esta adaptación del **Lab 2** permite formación de red, direccionamiento IPv6,
ping de un salto, contadores MAC y reconexión de B. El Lab 2 original requiere
un tercer nodo para dos saltos y recuperación mediante una ruta alternativa;
esas actividades quedan pendientes. La tercera placa opcional pertenece a los
requisitos del **Lab 3**, que usa otro firmware, de CoAP.

## Compilación y carga

Target: `esp32c6_devkitc/esp32c6/hpcore`, LED RGB GPIO8, flash de al menos 4 MB.
Una placa de 8 MB usa sus primeros 4 MB. Para otra placa hay que revisar target y LED.

En WSL, desde el PC con Zephyr:

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab2/tools/build.sh usb
```

Conecta A sola, adjúntala a WSL e identifica el puerto. Si aparece como ttyACM0:

```bash
bash ~/IoT-Labs-DHR/lab2/tools/flash.sh A /dev/ttyACM0 usb
```

Desconecta A, conecta B e identifica de nuevo el puerto:

```bash
bash ~/IoT-Labs-DHR/lab2/tools/flash.sh B /dev/ttyACM0 usb
```

Se compila una vez y se carga dos veces. La letra identifica el log; no fija el
rol en el firmware. Usa el conector ESP32C6/USB nativo para esta compilación.

Abre una terminal por placa con ambas conectadas. Solo si los puertos coinciden:

```bash
bash ~/IoT-Labs-DHR/lab2/tools/monitor.sh A /dev/ttyACM0
```

```bash
bash ~/IoT-Labs-DHR/lab2/tools/monitor.sh B /dev/ttyACM1
```

Para CH343/UART: `bash lab2/tools/build.sh uart`, luego `flash.sh A PUERTO uart`
y monitor por el mismo conector. El nombre ttyACM/ttyUSB no basta para identificar
el backend de consola. Sal del monitor con Ctrl+].

[La guía](guia.md) contiene USB/WSL, comandos separados de A/B, mediciones y
solución de problemas. Usa canal 25 y potencia 0 dBm en ambas placas; consulta las
ML-EID nuevas para los pings. No se necesita Wi-Fi, MQTT ni dashboard.

## Estado

- [x] Firmware común A/B y scripts adaptados.
- [x] Guía y plantilla para las mediciones posibles con dos placas.
- [ ] Compilar y cargar en el entorno Zephyr del usuario.
- [ ] Registrar red, direcciones, pings, contadores y reconexión.
- [ ] Completar las pruebas originales de dos saltos y rutas alternativas con una tercera placa.

La compilación Zephyr y la carga física todavía no se han ejecutado desde este chat.
