#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -ge 3 && $# -le 4 ]] || fail "Uso: bash flash.sh C none PUERTO [uart|usb] / S SENSOR PUERTO [uart|usb]"
select_console "${4:-uart}"
select_target "$1" "$2"
setup_workspace
check_board_port "$1" "$3"
[[ -f "$BUILD_DIR/zephyr/zephyr.bin" ]] || fail "Primero compila $BOARD_LABEL $SENSOR_KIND $CONSOLE."
[[ -f "$BUILD_DIR/iot-lab4-target.txt" ]] || fail "Falta marcador de build: vuelve a ejecutar build.sh."
[[ "$(cat "$BUILD_DIR/iot-lab4-target.txt")" == "$BOARD_LABEL $SENSOR_KIND $CONSOLE" ]] || fail "Build de otro target."
mkdir -p "$LAB4_DIR/evidencias/archivos"
printf 'Cierra el monitor de %s. Cargando por %s; consola %s, sensor %s.\n' "$BOARD_LABEL" "$PORT" "$CONSOLE" "$SENSOR_KIND"
west flash -d "$BUILD_DIR" --esp-device "$PORT" --esp-flash-size 4MB \
    2>&1 | tee "$LAB4_DIR/evidencias/archivos/flash-$BOARD_LABEL-$SENSOR_KIND-$CONSOLE.log"
