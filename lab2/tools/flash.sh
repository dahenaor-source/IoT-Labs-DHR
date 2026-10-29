#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -ge 2 && $# -le 3 ]] || fail "Uso: bash flash.sh A|B /dev/ttyACM0 [usb|uart]"
select_console "${3:-usb}"
setup_workspace
check_board_port "$1" "$2"
[[ -f "$BUILD_DIR/zephyr/zephyr.bin" ]] || fail "Primero ejecuta: bash $LAB2_DIR/tools/build.sh $CONSOLE"

printf 'Cargando la placa %s por %s (consola %s). Cierra su monitor serial.\n' "$BOARD_LABEL" "$PORT" "$CONSOLE"
mkdir -p "$LAB2_DIR/evidencias/archivos"
west flash -d "$BUILD_DIR" --esp-device "$PORT" --esp-flash-size 4MB \
    2>&1 | tee "$LAB2_DIR/evidencias/archivos/flash-$BOARD_LABEL-$CONSOLE.log"
printf 'La placa puede cambiar de puerto al reiniciarse. Vuelve a listar los puertos.\n'
