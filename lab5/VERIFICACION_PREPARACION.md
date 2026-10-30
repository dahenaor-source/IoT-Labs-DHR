# Verificación de los preparativos — 29 de octubre de 2026

Estas son comprobaciones de **herramientas/documentación**, no mediciones físicas
del Lab 5. No sustituyen los builds en WSL ni las pruebas S3/RCP/Thread.

- Sintaxis Bash de seis scripts y análisis de sintaxis de los tres clientes Python.
- Prueba en carpeta temporal con west/git simulados: S UART, C UART, RCP, BR N16R8 y S USB seleccionan targets/overlays y directorios separados.
- C/S se verifican con mapa 4 MB; BR con 8 MB y PSRAM octal; RCP con su modo de coprocesador.
- La carga rechaza perfil inválido, revisión Zephyr diferente y binario alterado después del marcador. `monitor.sh RCP` explica que no existe shell.
- Preparación del workspace comprobada con comandos simulados, incluidos pin, compiladores RISC-V/Xtensa, rutas con espacios y rechazo de workspace existente con otra revisión.
- Cliente Python: dos GET por IPv6 loopback hacia un servidor CoAP de prueba, con decodificación CBOR correcta. No hubo hardware ni Border Router en ese ensayo.
- Dashboard: ayuda CLI y rutas HTTP de lectura comprobadas con una fuente inicializada, sin afirmar recepción de sensor real o actuación física.
- Enlaces relativos de las guías y registro comprobados.
- Perfil S3 contrastado con la definición UART de la placa y símbolo de shell contrastado con Kconfig de Zephyr en el commit fijado.

Entorno de host comprobado: Python 3.12, aiocoap 0.4.17, cbor2 6.1.5,
Flask 3.1.3, pyserial 3.5 y cryptography 50.0.0. Los requisitos directos quedan
fijados en `tools/requirements.txt`; la ruta Windows se documenta, no se afirma
que se probó en Windows desde este entorno.

**Pendiente de validación real:** descargar/preparar el SDK aislado en WSL,
compilar las cuatro imágenes, identificar/cargar cada placa, detección de PSRAM,
comunicación Spinel, Wi-Fi, rutas IPv6, OMR, NAT64, dashboard y ensayo de falla.
No se instalaron ni modificaron el Zephyr o los controladores USB del PC del usuario.
