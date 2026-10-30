# Evidencias para Lab 5

Envíalas por etapa, indicando etiqueta **BR / RCP / S / C / PC / teléfono**.
No publiques dataset Thread ni contraseñas. Durante Wi-Fi/dataset evita grabar
la consola; comienza la captura después de introducir esos valores localmente.

| Etapa | Evidencia requerida |
|---|---|
| Materiales | Modelo S3 N16R8, tercera C6, foto UART GPIO5↔4 y GND sin credenciales; sensor S |
| Build/carga | Cuatro logs de build/flash; revisión Zephyr y commit IoT; puertos/conector reales |
| BR↔RCP | Arranque PSRAM de 8 MB, `ot rcp version`, `ot version` |
| Wi-Fi/Thread | wifi status, direcciones BR sin contraseña, state, br state, nat64 state, omrprefix, netdata show |
| C/S | state, channel, txpower, ipaddr/mleid; stats S; tablas child/router BR |
| PC/rutas | Sistema/red usados (Windows, Linux o WSL), ruta IPv6 a OMR y adaptador real |
| Medidas | Predicciones previas; 10 pings internos, 10 BR con power save inicial y 10 sin él, 10 pings S desde PC, 10 GET directos |
| Dashboard | Pantalla del teléfono, OPEN/CLOSE y log S con código/payload |
| NAT64 | Ping IPv4 sintetizado, prefijo /96, resultado completo y disponibilidad upstream |
| BR fuera | Instante, rol C/S, PUT/GET interno y fallo de GET externo, tiempos reales |
| Retorno BR | Mismo dataset restaurado sin mostrarlo, rol/prefijo/ruta y GET posteriores |
| Cierre | Válvula cerrada/consultada y Thread/interfaz/Wi-Fi detenidos según placa |

Los scripts guardan logs de build/flash en `evidencias/archivos/`.
Para las pruebas usa nombres descriptivos como `01-boot-BR.txt`,
`02-rcp-version.txt`, `03-network-BR.txt`, `04-addresses-S.txt`,
`05-routes-PC.txt`, `06-ping-br-ps-on.txt`, `06-ping-br-ps-off.txt`,
`07-get10-PC.txt`, `08-nat64-S.txt`, `09-br-off-C.txt`, `09-br-off-PC.txt`.
Videos/fotos en `Imagen/`. En cada medición conserva enviados/recibidos, pérdida,
min/avg/max y unidades. Los tiempos de relojes de placas distintas no se restan
sin sincronización. Clasifica valores del SOP como ejemplos, no resultados.
