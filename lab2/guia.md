# Lab 2 — instrucciones para dos placas A y B

## Alcance

Se adapta [Lab 2 del curso](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/54ce49e5c0251dd3e7cc1300dbe6c96c28d55fd2/en/labs/lab2.md)
a las dos placas disponibles. Podemos formar la red, clasificar direcciones,
medir RTT/pérdida de un salto, observar contadores y registrar la reconexión de B.

Con dos nodos no se puede demostrar el reenvío A→B→C ni cambiar a una ruta
alternativa al retirar el intermediario. Esas partes del Lab 2 original quedan
pendientes; la reconexión descrita aquí es un ensayo distinto. El Lab 3 sí permite
dos placas, pero utiliza firmware CoAP y se prepara por separado.

## 1. Preparar los puertos

Etiqueta las placas A/B. Se usa ESP32-C6 DevKitC con RGB GPIO8 y flash de al menos
4 MB. Las placas de 8 MB usan los primeros 4 MB. Revisa el target y el RGB si tu
modelo es distinto. No hacen falta dos PCs: puedes abrir dos terminales en uno.
Tampoco hace falta que los PCs compartan Wi-Fi.

Compilación **usb**: conector ESP32C6/USB nativo. Compilación **uart**: conector
CH343/UART. Usa el conector que coincida con la consola compilada.

En PowerShell, consulta los BUSID reales:

```powershell
usbipd list
```

Para cada dispositivo que vas a usar desde WSL, ejecuta por separado (1-1 es
solo un ejemplo; bind requiere permisos de administrador):

```powershell
usbipd bind --busid 1-1
usbipd attach --wsl --busid 1-1
```

En WSL:

```bash
ls -l /dev/ttyACM* /dev/ttyUSB* /dev/serial/by-id/* 2>/dev/null
```

Identifica A/B conectando una a la vez. Los puertos pueden cambiar al reiniciar.
Si hay permiso denegado:

```bash
sudo usermod -aG dialout "$USER"
```

Cierra la sesión de WSL y vuelve a abrirla para aplicar el grupo.

## 2. Compilar el firmware común

El script activa la venv existente y compila desde el workspace Zephyr:

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab2/tools/build.sh usb
```

La imagen queda en `~/zephyrproject/build-iot-lab2-usb/zephyr/zephyr.bin`.
El log se guarda en `lab2/evidencias/archivos/build-usb.log`.
El overlay de placa configura RGB y flash de 4 MB; se añade el overlay USB.
El script comprueba que CONFIG_FLASH_SIZE sea 4096 después de compilar.

Workspace en otra ruta:

```bash
ZEPHYR_WORKSPACE=/ruta/zephyrproject bash ~/IoT-Labs-DHR/lab2/tools/build.sh usb
```

Para usar el conector UART:

```bash
bash ~/IoT-Labs-DHR/lab2/tools/build.sh uart
```

No hay datasets o claves en la imagen. Ambas placas ejecutan el mismo código;
se configuran por CLI después de cargarlo.

## 3. Cargar A y B

Cierra el monitor. Con A sola conectada y adjuntada a WSL, si el puerto real es
/dev/ttyACM0:

```bash
bash ~/IoT-Labs-DHR/lab2/tools/flash.sh A /dev/ttyACM0 usb
```

Desconecta A, conecta y adjunta B, vuelve a listar los puertos y ejecuta:

```bash
bash ~/IoT-Labs-DHR/lab2/tools/flash.sh B /dev/ttyACM0 usb
```

Usa el puerto real si difiere. También puedes dejarlas conectadas simultáneamente
si identificas sus puertos correctamente. El script guarda un log por placa y
usa flash de 4 MB. Si no sincroniza: cierra los monitores, mantén BOOT, pulsa
RESET, suelta BOOT y reintenta.

## 4. Abrir ambas consolas

Con A/B conectadas y asociadas a sus puertos, abre una terminal para cada una.
Ejemplo (verifica la asociación antes):

```bash
bash ~/IoT-Labs-DHR/lab2/tools/monitor.sh A /dev/ttyACM0
```

```bash
bash ~/IoT-Labs-DHR/lab2/tools/monitor.sh B /dev/ttyACM1
```

Pulsa Enter para ver el prompt. Debe arrancar con `Lab 2 two-board node ready`.
Sal con Ctrl+]. No abras dos programas sobre el mismo puerto.

En un PC sin Zephyr basta PuTTY/Tera Term a 115200, 8N1, sin control de flujo,
y el COM del Administrador de dispositivos. La placa debe haberse cargado antes
en el PC con Zephyr. Si Windows abre el puerto, no lo dejes adjuntado a WSL:
`usbipd detach --busid BUSID_REAL`. El CH343 puede necesitar driver.

## 5. Inicialización de una red nueva

Al comenzar el laboratorio, ejecuta una vez en cada placa:

```text
ot factoryreset
```

Se reiniciará; vuelve a adjuntarla y abrir el monitor si el USB se reenumera.
No repitas factoryreset entre mediciones.

### Placa A

```text
ot txpower 0
ot txpower
ot dataset init new
ot dataset channel 25
ot dataset commit active
ot ifconfig up
ot thread start
```

Consulta `ot state` hasta ver leader. Luego obtén el dataset para B:

```text
ot dataset active -x
```

Copia la cadena hexadecimal completa directamente a B. Contiene la clave de la
red: no la incluyas en capturas ni en logs que vayas a subir.

### Placa B

Reemplaza el marcador completo, sin los signos < >:

```text
ot txpower 0
ot txpower
ot dataset set active <HEX_DE_A>
ot ifconfig up
ot thread start
```

Consulta `ot state`: primero puede ser child; espera aproximadamente dos minutos
para router. Si ambas persisten como leader, acércalas y revisa el dataset.

### En ambas placas

```text
ot state
ot txpower
ot channel
ot router table
ot neighbor table
```

Registra los valores reales; se prevé canal 25 y 0 dBm en las dos.

## 6. Direcciones de A y B

Ejecuta en cada placa:

```text
ot ipaddr
ot ipaddr mleid
ot ipaddr rloc
ot rloc16
ot extaddr
ot ipmaddr
```

Anota ML-EID, RLOC, RLOC16, extaddr y link-local. La dirección terminada en fc00
es el ALOC del líder; no la confundas con su RLOC individual. Usa las ML-EID para
los pings. Las direcciones del Lab 1 ya no son aplicables a esta red nueva.

Comprueba Router ID = RLOC16 >> 10 y la relación entre extaddr y link-local:
el bit U/L (0x02 del primer byte) se invierte al formar el IID. Clasifica los
grupos multicast que encuentres.

## 7. Medir RTT y pérdida de un salto

Mantén las placas cerca, con línea de visión despejada y posición/potencia
constantes. En A, reemplaza el marcador por la ML-EID actual de B:

```text
ot ping <ML_EID_B> 64 20 0.5
```

Cuando termine, desde B:

```text
ot ping <ML_EID_A> 64 20 0.5
```

Guarda enviados/recibidos, pérdida y RTT min/promedio/max. Ejecuta los pings de
forma secuencial. En ambas, guarda también `ot neighbor table`. El RSSI se mide
en el receptor: la tabla de B describe la señal A→B y viceversa.

El primer intercambio puede necesitar resolver la ML-EID; anota esa incidencia
sin atribuir automáticamente toda pérdida a resolución de direcciones.

## 8. Contadores MAC de los extremos

En ambas placas, antes de otro ping:

```text
ot counters mac reset
```

Desde A, repite el ping de 20 paquetes a B. Después, en ambas:

```text
ot counters mac
```

Registra TxUnicast, RxUnicast y otros contadores útiles. Aquí A y B son extremos
del intercambio: estos contadores no prueban que haya un router intermediario.
No se aplican filtros para fingir dos saltos.

## 9. Reconexión de B — ensayo complementario con dos placas

Opcional: mide tres veces la reincorporación manual de B a la misma red.
No es la prueba de recuperación de rutas alternativas del Lab 2 original.

Con ambas conectadas, registra en B `ot ipaddr mleid`. En B:

```text
ot thread stop
ot ifconfig down
```

Durante la interrupción el ping de A a B no tendrá destino alcanzable.
Cuando vayas a reanudar, inicia el cronómetro y ejecuta en B:

```text
ot txpower 0
ot ifconfig up
ot thread start
```

Desde A inicia un ping a la ML-EID de B para observar la primera respuesta:

```text
ot ping <ML_EID_B> 64 60 1
```

Registra el tiempo desde thread start hasta la primera respuesta, así como los
estados y dirección posteriores de B. Si la dirección cambió, regístralo antes
de repetir; no uses una dirección antigua. Para sincronizar mejor, graba ambas
terminales o usa un cronómetro compartido. No contabilices el tiempo que B se
mantuvo apagada/detenida como retardo de reconexión. Si no responde en la ventana,
registra el resultado sin inventar un tiempo.

Espera que B vuelva al rol previsto y que los pings funcionen antes del próximo
ensayo. Conserva el dataset durante los tres ensayos.

## 10. Evidencias e informe

Completa [registro.md](evidencias/registro.md) con las salidas reales. Guarda
logs en `evidencias/archivos/` e imágenes en `Imagen/`. Nombres sugeridos:
`direccionamiento-A.txt`, `direccionamiento-B.txt`, `rtt-A-B.txt`, `rtt-B-A.txt`,
`mac-A.txt`, `mac-B.txt`, `reconexion-1.txt`, `reconexion-2.txt`, `reconexion-3.txt`.
No publiques logs seriales completos que contengan el dataset.

En el informe original, la comparación RTT de uno/dos saltos, los contadores de
un relay y las tres recuperaciones de ruta alternativa deben figurar pendientes
por falta de un tercer nodo. Los datos de reconexión de esta adaptación se
registran aparte y no sustituyen esas mediciones. Completa clasificación de
direcciones y funciones de roles con lo observado; las conclusiones de ADR-002
sobre varios saltos/recuperación quedan pendientes de esas pruebas.

## 11. Finalizar

En ambas placas:

```text
ot thread stop
ot ifconfig down
```

## 12. Solución de problemas

| Problema | Acción |
|---|---|
| Falta west | Usa el PC con Zephyr y su venv; los scripts buscan ~/zephyrproject/.venv. |
| Falta SDK o blobs | Revisa west sdk list y west blobs fetch hal_espressif desde el workspace. |
| Puerto desaparece | Revisa cable/USB, usbipd list/attach y vuelve a listar los puertos. |
| Sin prompt | Comprueba conector USB/UART, build correspondiente y 115200; pulsa Enter/RESET. |
| Ambas leader | Revisa que B tenga el dataset de A, acércalas y espera convergencia. |
| B sigue child | Espera y comprueba el firmware FTD; el ping puede funcionar como child, registra el rol real. |
| No sincroniza al cargar | Cierra el monitor y usa BOOT/RESET antes de reintentar. |
| Flash de 8 MB frente a chip 4 MB | Recompila con el overlay proporcionado y verifica CONFIG_FLASH_SIZE=4096. |
