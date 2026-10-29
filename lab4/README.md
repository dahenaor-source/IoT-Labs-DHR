# Lab 4 — DS18B20 real con dos ESP32-C6

**Estado: finalizado por decisión del usuario.** Se conservan las limitaciones
de medición y trazabilidad del informe; no se recibió confirmación de apagado
final de las placas.

DS18B20 reconocido en S: 24.00 °C, 9 lecturas sin fallas ni rechazos.
Red C leader/S router y GET 2.05 con Max-Age 59 validados. Ruido registrado:
21.50–21.62 °C (0.12 °C pico a pico), paso impreso 0.06 °C. Curva de respuesta
y seis notificaciones Observe documentadas. Sensor perdido, Max-Age decreciente
y GET 5.03 verificados en video; recuperación, GET 2.05 y nuevo Observe OBS=33
confirmados. Nodo fuera de Thread: timeout GET CON ≈74.1 s y retorno a router
documentados; GET tras retorno confirmado. Reposo: 0/78 fallidas en 155 s.
Tráfico: 0/93 lecturas fallidas en 186 s y 1199/1200 pings recibidos
(pérdida calculada 0.08333 %). Reset documentado: sensor vuelve a leer, contadores se reinician y Thread queda
en disabled por arranque manual. Tras activarlo, S vuelve a child con la misma
ML-EID sin copiar dataset; GET y nuevo Observe confirmados en C.
[Informe final](INFORME.md), con brechas de medición y apagado final no confirmado. [Primera evidencia](evidencias/archivos/01-stats-inicial-S.txt).

[Guía de ejecución](guia.md) · [Evidencias por enviar](EVIDENCIAS.md) ·
[Registro de resultados](evidencias/registro.md) · [Informe y DDR](INFORME.md) · [Origen](ORIGEN.md)

- **S:** DS18B20 en GPIO18; lectura cada 2 s, resolución configurada de 12 bits.
- **C:** cliente CoAP sin sensor; representa el gateway. Solo aquí se ejecuta `ot coap start`.
- Consola predeterminada **UART por CH343**, como en el Lab 3; flash de 4 MB.
- Se necesitan dos placas, DS18B20, cables, protoboard y termómetro de referencia.
  El usuario confirmó sensor, protoboards y termómetro. Resistencia externa de 4.7 kΩ recomendada.

## Compilar y cargar

Desde WSL, identifica primero qué puerto corresponde a cada placa. Los ejemplos
usan ACM0 para C y ACM1 para S; no son una asignación fija.

```bash
cd ~/IoT-Labs-DHR
git pull --ff-only
bash lab4/tools/build.sh C none uart
bash lab4/tools/build.sh S ds18b20 uart
```

Con los monitores cerrados:

```bash
bash ~/IoT-Labs-DHR/lab4/tools/flash.sh C none /dev/ttyACM0 uart
bash ~/IoT-Labs-DHR/lab4/tools/flash.sh S ds18b20 /dev/ttyACM1 uart
```

En dos ventanas distintas:

```bash
bash ~/IoT-Labs-DHR/lab4/tools/monitor.sh C /dev/ttyACM0
```

```bash
bash ~/IoT-Labs-DHR/lab4/tools/monitor.sh S /dev/ttyACM1
```

C y S usan directorios de build diferentes: **no se carga la misma imagen en ambas**.
El script impide preparar S sin seleccionar un sensor. USB nativo también está
soportado sustituyendo `uart` por `usb` en build/flash y conectando por ESP32C6;
no mezcles ese firmware con la consola CH343.

Primera salida a enviar: arranque de S y `soilsense stats`. Debe identificar
DS18B20; si muestra `simulated`, no es el firmware de S correcto.

## Qué se comprobará

1. Ruido y pasos de lectura durante 60 s; diferencia frente al termómetro.
2. Respuesta al estímulo y notificaciones Observe.
3. Rechazo de valores imposibles y aceptación de uno falso pero plausible.
4. Sensor desconectado: caducidad del dato, 5.03 y fin de Observe; reconexión.
5. Nodo fuera de red: timeout; fallas de lectura en reposo y con 1200 pings.
6. Recuperación tras reset y comparación con la tabla compartida de la clase.
7. Contrato actualizado, auditoría de Trustworthiness y diseño ante datos ausentes.

Los scripts se verifican aquí; este entorno no dispone de Zephyr/SDK ni USB.
No se presentan compilaciones ni resultados físicos como hechos antes de recibir sus logs.
