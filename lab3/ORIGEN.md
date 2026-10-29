# Origen y adaptaciones

Repositorio del curso: https://github.com/saacifuentesmu/4201327-iot_systems_design

Commit base: `397b4f38435220e6a7ca6eee977f67a41f92d7f1`.
Guía: `en/labs/lab3.md`; firmware: `firmware/lab3_coap/`.

Se conservan los contratos CoAP/CBOR, el sensor simulado, Observe y la válvula
representada por LED. C y S ejecutan el mismo firmware; `ot coap start` se usa solo
en C. Los scripts distinguen las etiquetas C/S para los logs de carga.

Adaptaciones locales:

- Overlay RGB GPIO8 y flash limitada a 4 MB, igual que el entorno usado en Lab 2.
- Consola USB nativa o UART, con directorios de build separados.
- FTD explícito y colores ANSI desactivados para facilitar lectura de logs.
- Registro de rol independiente de la disponibilidad del LED; se evita acceder
  al driver si no está listo.
- Log de bytes de solicitud/respuesta de válvula y de notificación Observe,
  para la tabla de presupuesto de bytes del laboratorio.
- Cálculo del ruido simulado con resta con signo explícita.
- Guía en español, plantilla y lista de salidas necesarias; decodificador Python
  de los dos contratos CBOR, sin dependencias adicionales.

El código representa una simulación de válvula; la política ante pérdida de CLOSE
se documenta como diseño en el informe. No se añade un temporizador de cierre
que cambie los ensayos del laboratorio.

Validado mediante logs del usuario en WSL: arranque y comunicación C/S, Observe,
válvula simulada, CON/NON y latencia SED. Véanse el [registro](evidencias/registro.md)
y el [informe](INFORME.md). El tiempo del GET se estimó posteriormente con video a 60 fps, distinguiéndolo
del RTT de red aislado. No se aportó un registro exitoso completo de carga S;
la ejecución posterior está documentada. La estimación de
energía y la política de cierre autónomo son análisis, no pruebas experimentales.
