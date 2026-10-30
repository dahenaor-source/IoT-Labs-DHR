#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -ge 2 && $# -le 3 ]] || fail "Uso: flash.sh S|C PUERTO [uart|usb]; RCP PUERTO; BR PUERTO N16R8"
role_arg="$1"; port_arg="$2"; profile_arg="${3:-}"
select_target "$role_arg" "$profile_arg"
setup_workspace
check_port "$port_arg"
marker="$BUILD_DIR/iot-lab5-target.txt"
[[ -f "$marker" && -f "$BUILD_DIR/zephyr/zephyr.bin" ]] || fail "Primero compila $BUILD_LABEL con build.sh."
mapfile -t marker_lines < "$marker"
[[ "${marker_lines[0]:-}" == "$BUILD_LABEL" ]] || fail "El marcador corresponde a otra placa."
artifact_sha="$(sha256sum "$BUILD_DIR/zephyr/zephyr.bin")"
[[ "${marker_lines[1]:-}" == "${artifact_sha%% *}" ]] || fail "La imagen cambió desde la compilación verificada; recompila antes de cargar."
mkdir -p "$LAB5_DIR/evidencias/archivos"
printf 'Cargando %s en %s, flash %s. Cierra su monitor y verifica la placa física.\n' "$BUILD_LABEL" "$PORT" "$FLASH_SIZE"
west flash -d "$BUILD_DIR" --esp-device "$PORT" --esp-flash-size "$FLASH_SIZE" \
    2>&1 | tee "$LAB5_DIR/evidencias/archivos/flash-$BUILD_LABEL.log"
