#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -ge 2 && $# -le 3 ]] || fail "Uso: bash build.sh C none [uart|usb] / S SENSOR [uart|usb]"
select_console "${3:-uart}"
select_target "$1" "$2"
setup_workspace
cmake_args=("-DDTC_OVERLAY_FILE=$LAB4_DIR/firmware/boards/esp32c6_devkitc_hpcore.overlay")
overlays=()
if [[ "$BOARD_LABEL" == S ]]; then
    overlays+=("$LAB4_DIR/firmware/sensors/$SENSOR_KIND.overlay")
fi
if [[ "$CONSOLE" == usb ]]; then
    cmake_args+=("-DEXTRA_CONF_FILE=$LAB4_DIR/firmware/usb_console.conf")
    overlays+=("$LAB4_DIR/firmware/usb_console.overlay")
fi
if [[ ${#overlays[@]} -gt 0 ]]; then
    overlay_list="$(IFS=';'; printf '%s' "${overlays[*]}")"
    cmake_args+=("-DEXTRA_DTC_OVERLAY_FILE=$overlay_list")
fi
mkdir -p "$LAB4_DIR/evidencias/archivos"
west build -p always -b esp32c6_devkitc/esp32c6/hpcore \
    -s "$LAB4_DIR/firmware" -d "$BUILD_DIR" -- "${cmake_args[@]}" \
    2>&1 | tee "$LAB4_DIR/evidencias/archivos/build-$BOARD_LABEL-$SENSOR_KIND-$CONSOLE.log"
grep -qx 'CONFIG_FLASH_SIZE=4096' "$BUILD_DIR/zephyr/.config" || fail "El build no configura 4 MB."
# Marker only written after a successful build; flash.sh validates the same target.
printf '%s\n' "$BOARD_LABEL $SENSOR_KIND $CONSOLE" > "$BUILD_DIR/iot-lab4-target.txt"
printf '\nGenerado: %s/zephyr/zephyr.bin\n' "$BUILD_DIR"
