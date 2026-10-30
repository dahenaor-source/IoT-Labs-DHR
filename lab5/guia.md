# Lab 5 — Red, acceso desde el PC y ensayos

Primero completa [CARGA_FIRMWARE.md](CARGA_FIRMWARE.md): cuatro imágenes,
S3 N16R8 con PSRAM y RCP respondiendo a `ot rcp version`. Los valores numéricos
siguientes son objetivos del curso o ejemplos de comandos, no resultados obtenidos.

## 1. Preparar las mediciones

Anota fecha, integrantes, lugares/obstáculos, placas/puertos, revisión Zephyr,
commit IoT, canal y potencia. Completa antes de medir la columna Predicción del
[registro](evidencias/registro.md). Mantén posición, alimentación y carga comparables.

No registres contraseñas ni el dataset Thread: durante el aprovisionamiento
no grabes la consola ni hagas capturas que los incluyan. Guarda por separado
solo las salidas de verificación sin secretos.

## 2. BR: conectar Wi-Fi y crear la red

Hotspot **2.4 GHz y WPA2-Personal**. El portátil debe poder conectarse a él.
En la consola BR, introduciendo tus datos únicamente de forma local:

```text
wifi connect -s "SSID_LOCAL" -p "CLAVE_LOCAL" -k 1
wifi status
net iface
```

Conserva State COMPLETED, banda y direcciones del BR, omitiendo las credenciales.
Anota la IPv4 DHCP y la IPv6 link-local del interfaz **WiFi**, no la de Thread.

En BR crea la red (25 es el canal previsto; usa el asignado por el profesor si difiere):

```text
ot dataset init new
ot dataset channel 25
ot dataset networkname SoilSense-IC-DH
ot dataset commit active
ot ifconfig up
ot thread start
```

PAN ID/clave los genera el dataset nuevo; no se impone el mismo PAN a toda la clase.
Espera `ot state` → leader, que puede tardar. Después:

```text
ot br state
ot nat64 state
ot br omrprefix
ot netdata show
```

Esperado: BR running y NAT64 activo. Anota el prefijo OMR favorecido (`/64`) y
la ruta NAT64 (`/96`). El OMR puede ser ULA `fd...` en el hotspot: que sea
rutable entre Wi-Fi/Thread no lo convierte en una dirección pública de Internet.
No copies el prefijo de un ejemplo del curso.

Consulta `ot dataset active -x` **solo localmente** y guarda ese valor fuera de
Git. Debe estar disponible para unir S/C y restaurar el BR tras un reinicio.
El BR de Lab 5 guarda estos ajustes en RAM, no se ha activado autostart de Lab 8.

## 3. Unir S y C a BR

La guía actual pide olvidar la red anterior para no restaurar el rol/dataset de
Lab 4. En cada una, ejecuta `ot factoryreset` y espera el nuevo arranque antes
de seguir; con USB nativo puede cambiar el puerto. No ejecutes factoryreset en BR.

Después, por consola local de S y luego C:

```text
ot dataset set active <DATASET_BR>
ot ifconfig up
ot thread start
```

Espera child/router; convertirse en router puede tardar. En S/C guarda:

```text
ot state
ot channel
ot txpower
ot ipaddr
ot ipaddr mleid
```

En S añade `soilsense stats`. En BR añade `ot child table` y `ot router table`.
Debes distinguir en S: link-local, ML-EID, RLOC y **OMR** (prefijo publicado por BR).
La dirección OMR se usa desde el portátil; la ML-EID, desde C en la malla.

Si no hay OMR, comprueba que cargaste la nueva imagen con SLAAC y que BR anuncia
prefijo. Una dirección `fd...` no se clasifica solo por esos dos caracteres:
ML-EID y OMR pueden ser ULA con prefijos distintos.

## 4. Baseline dentro de Thread

En C, solo en C:

```text
ot coap start
ot ping <S_MLEID> 16 10 1
```

Guarda resumen completo de 10 pings, potencia/canal y roles. No reutilices como
valor actual un RTT de Lab 3. Usa el mismo tamaño para las comparaciones de ping
que pretendas restar; registra el payload de cada herramienta.

## 5. Cliente del PC: Linux/WSL y Windows

### Linux con ruta IPv6 al Wi-Fi

```bash
bash ~/IoT-Labs-DHR/lab5/tools/setup_host.sh
source ~/IoT-Labs-DHR/lab5/.venv/bin/activate
ip -6 address
ip -6 route
ip -6 route get <S_OMR>
```

El BR anuncia una ruta al OMR en Router Advertisements con RIO. Si no se instala,
puede añadirse manualmente con los valores reales de BR y del interfaz del PC:

```bash
sudo ip -6 route replace <OMR>/64 via <BR_WIFI_LINK_LOCAL> dev <INTERFAZ_WIFI>
```

No uses wlan0 por costumbre: identifica el interfaz efectivo. En WSL NAT suele
haber `eth0` virtual y no una interfaz Wi-Fi directa. Una ruta hacia una dirección
link-local que pertenece a otro enlace no resuelve ese aislamiento.

### Si trabajas con WSL2 en modo NAT

La conexión USB y las compilaciones pueden funcionar aunque WSL **no tenga ruta
IPv6** hacia OMR. Primero revisa `ip -6 route get`. Una ruta añadida en Windows
no garantiza que el proceso Python en WSL pueda utilizarla.

Opciones: ejecutar las herramientas de cliente/dashboard en Windows con Python,
en Linux con acceso al Wi-Fi, o en una configuración WSL que realmente tenga esa
conectividad IPv6. No cambies el modo de red ni reinicies todo WSL durante la
carga/monitorización de las placas. No se configura automáticamente aquí.

Para Windows, copia `coap_client.py`, `dashboard_coap.py`, `coaps.py` y
`requirements.txt` desde `lab5/tools` a una carpeta local (por ejemplo
`C:\Users\TU_USUARIO\IoT-lab5-client`). En PowerShell dentro de esa carpeta:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Get-NetIPAddress -AddressFamily IPv6
Get-NetRoute -AddressFamily IPv6
```

Si falta la ruta, desde PowerShell/CMD administrador, sustituye los valores:

```text
netsh interface ipv6 add route <OMR>/64 "Wi-Fi" <BR_WIFI_LINK_LOCAL>
```

El nombre del adaptador puede ser distinto. Verifica primero conectividad IPv6
con `ping -6 <S_OMR>`. Las herramientas usan Python del PC: para las órdenes de
las secciones siguientes, Windows usa `.\.venv\Scripts\python.exe` y rutas de
archivos locales, no `~/IoT-Labs-DHR/...` ni `source` de Bash.

## 6. Medir acceso y costo del Border Router

Linux, desde el host que tenga la ruta correcta (Windows: `ping -n 10` en lugar
de `-c 10`; conserva los tamaños reales que utiliza cada implementación):

```bash
ping -c 10 <BR_IPV4>
```

Guarda esos resultados con power save en su estado inicial. En BR ejecuta:

```text
wifi ps off
```

Repite el ping IPv4 y luego:

```bash
ping -6 -c 10 <S_OMR>
python ~/IoT-Labs-DHR/lab5/tools/coap_client.py --host <S_OMR> --count 10 get /env/temp
```

Guarda 10 respuestas, códigos, CBOR y mediana del RTT CoAP. El objetivo del curso
es GET <200 ms y latencia añadida por BR <100 ms. El curso propone como indicador
`RTT portátil→S − RTT portátil→BR`; son recorridos distintos y no una medida pura
solo de procesamiento del BR. Documentaremos tamaños/condiciones antes de restar.

Las referencias de Lab 3 eran tiempos visuales de consola e ICMP: no son un
baseline idéntico a este cliente CoAP directo de PC. Usa mediciones de esta sesión.

## 7. Dashboard y teléfono

Desde el host con IPv6:

```bash
python ~/IoT-Labs-DHR/lab5/tools/dashboard_coap.py --host <S_OMR>
```

Abre `http://localhost:5000` en el PC. En el teléfono, usa
`http://<IPV4_DEL_PC_EN_WIFI>:5000`, no la IPv4 del BR ni la privada NAT de WSL.
El servidor escucha en 0.0.0.0; si el firewall lo bloquea, revisa el acceso TCP5000
en la red de ensayo sin deshabilitar todo el firewall.

Obtén foto/captura del teléfono, temperatura, OPEN/CLOSE y log PUT de S. El LED
blanco representa abierto; cierra al terminar y confirma con GET de `/act/valve`.
El dashboard obtiene datos mediante Observe. Un aviso de datos no frescos debe
mantenerse como tal, no sustituirse por una temperatura inventada.

## 8. NAT64

En S:

```text
ot ping 8.8.8.8
```

Guarda la dirección IPv6 sintetizada, el resumen y la ruta `/96` del BR.
El objetivo orientativo del curso es RTT <200 ms. La conectividad IPv4 de salida
del hotspot y el servicio externo son parte de esta prueba, no solo la malla.
No uses números de salida del ejemplo como resultados propios.

## 9. Falla del BR y restauración

Con C/S unidas y sensor funcionando, guarda los estados. Interrumpe el conjunto
Border Router como indica el SOP, conservando la alimentación de C/S. Anota el
instante de la interrupción; no confundas la duración sin energía con tiempo de
recuperación. Conserva las precauciones de alimentación del enlace UART del
[montaje](CARGA_FIRMWARE.md).

Desde C intenta:

```text
ot coap put <S_MLEID> act/valve con 1
ot coap get <S_MLEID> act/valve
```

Desde el PC intenta GET a `<S_OMR>`. Guarda lo que funciona y falla, sin asumir
que la malla o el acceso externo sobreviven. Cierra la válvula simulada desde C
cuando sea posible: PUT CON 0 y GET. Si C/S necesitan elegir roles al perder el
líder, registra sus transiciones y tiempos.

Restaura alimentación de RCP antes o junto a S3. En BR, usa el **mismo dataset
guardado localmente**, no `dataset init new`:

```text
ot dataset set active <DATASET_BR_GUARDADO>
ot ifconfig up
ot thread start
wifi connect -s "SSID_LOCAL" -p "CLAVE_LOCAL" -k 1
```

Comprueba state, br state, nat64 state, omrprefix, rutas del PC y GET. El rol
que retome BR se registra tal como aparezca, sin forzarlo a leader para la foto.
Un prefijo o una dirección puede cambiar: consulta de nuevo antes de usarlo.

## 10. Cierre e informe

Guarda evidencias sin secretos, cancela Observe del cliente activo, cierra y
consulta la válvula. En C/S: `ot thread stop`, `ot ifconfig down`. En BR detén
Thread y la conexión Wi-Fi al acabar; RCP no admite estos comandos.

El informe añadirá: ADR-005 del curso (función del BR y límite de red), paseo de
las redes y sus límites, RTT de sesión, NAT64, fallo/restauración y acceso desde
teléfono. El DDR existente ya asignó ADR-005 a frescura: conservaremos su historia
y evitaremos sobrescribirla al incorporar la decisión nueva del Lab 5.
No se declara cifrado DTLS ni Lab 6 completado en estas pruebas.
