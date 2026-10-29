#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -le 1 ]] || fail "Uso: bash build.sh [usb|uart]"
select_console "${1:-usb}"
setup_workspace

cmake_args=("-DDTC_OVERLAY_FILE=$LAB3_DIR/firmware/boards/esp32c6_devkitc_hpcore.overlay")
if [[ "$CONSOLE" == usb ]]; then
    # Add USB routing to the explicitly selected board LED/flash overlay.
    cmake_args+=("-DEXTRA_CONF_FILE=$LAB3_DIR/firmware/usb_console.conf")
    cmake_args+=("-DEXTRA_DTC_OVERLAY_FILE=$LAB3_DIR/firmware/usb_console.overlay")
fi
mkdir -p "$LAB3_DIR/evidencias/archivos"
west build -p always \
    -b esp32c6_devkitc/esp32c6/hpcore \
    -s "$LAB3_DIR/firmware" -d "$BUILD_DIR" \
    -- "${cmake_args[@]}" 2>&1 | tee "$LAB3_DIR/evidencias/archivos/build-$CONSOLE.log"

grep -qx 'CONFIG_FLASH_SIZE=4096' "$BUILD_DIR/zephyr/.config" || \
    fail "El build no configura 4 MB de flash. Revisa el overlay antes de cargar."

printf '\nFirmware generado: %s/zephyr/zephyr.bin\n' "$BUILD_DIR"
printf 'Usa esta misma compilación para las dos placas C/S con consola %s.\n' "$CONSOLE"
