# Origen del Lab 4

Repositorio del curso: https://github.com/saacifuentesmu/4201327-iot_systems_design

Commit base: `ae16e74895e1375ad0ff54ef7f691c8c94ae58d1`.

- [Guía](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ae16e74895e1375ad0ff54ef7f691c8c94ae58d1/en/labs/lab4.md).
- [SOP-04](https://github.com/saacifuentesmu/4201327-iot_systems_design/blob/ae16e74895e1375ad0ff54ef7f691c8c94ae58d1/en/labs/sops/sop04_sensor_integration.md).
- Firmware base: `firmware/lab4_sensors/`.

Adaptaciones: overlay RGB/flash de 4 MB usado en Lab 3, FTD explícito, colores
ANSI desactivados, callback de rol independiente de disponibilidad del LED y
protección ante acceso a LED no disponible. Resta del ruido simulado con signo
explícito para C. Scripts de build/flash separados por placa, sensor y consola;
UART/CH343 predeterminado. Se mantienen los contratos, los filtros y los ensayos.

El firmware base sin sensor tiene una simulación para C. La imagen S se selecciona
explícitamente como DS18B20; una simulación no sirve como evidencia de sensor real.
Se conservan overlays de los otros tres sensores del curso, sin afirmar su
validación en estas placas. No se añade una política automática de cierre de
válvula: se documentará como diseño al completar el informe.

La guía principal resume el filtro como −40..85 °C y salto de 5 °C; el código
real admite **−40 ≤ T < 85** y solo aplica el salto contra una lectura aceptada
hace menos de 10 s. El registro e informe deben describir ese comportamiento.

Referencia del sensor: [DS18B20, Analog Devices](https://www.analog.com/en/products/DS18B20.html)
y [datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ds18b20.pdf).
La exactitud de ±0.5 °C corresponde al intervalo −10..85 °C según fabricante,
no a todo el rango del sensor. A 12 bits el paso nominal es 0.0625 °C;
esto no significa exactitud de 0.0625 °C. No confundir el sensor estándar con
DS18B20-PAR: aquí se utiliza alimentación de tres hilos, no parásita.
