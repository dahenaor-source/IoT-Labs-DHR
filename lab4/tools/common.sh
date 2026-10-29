#!/usr/bin/env bash
# Shared by build.sh, flash.sh and monitor.sh; scripts are invoked with bash.
set -euo pipefail

LAB4_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ZEPHYR_WORKSPACE="${ZEPHYR_WORKSPACE:-$HOME/zephyrproject}"

fail() { printf '%s\n' "$*" >&2; exit 1; }

setup_workspace() {
    [[ -d "$ZEPHYR_WORKSPACE/.west" ]] || fail "No existe .west en $ZEPHYR_WORKSPACE. Usa la PC con Zephyr instalado."
    if [[ -f "$ZEPHYR_WORKSPACE/.venv/bin/activate" ]]; then
        source "$ZEPHYR_WORKSPACE/.venv/bin/activate"
    fi
    command -v west >/dev/null || fail "Activa el entorno Python que contiene west."
    cd -- "$ZEPHYR_WORKSPACE"
}

select_console() {
    CONSOLE="${1:-uart}"
    case "$CONSOLE" in usb|uart) ;; *) fail "Consola inválida: usa usb o uart." ;; esac

}

check_board_port() {
    BOARD_LABEL="$1"
    PORT="$2"
    case "$BOARD_LABEL" in C|S) ;; *) fail "Esta adaptación usa dos placas: C o S." ;; esac
    [[ -c "$PORT" ]] || fail "No existe el puerto serial $PORT. Revisa el cable y usbipd attach."
    [[ -r "$PORT" && -w "$PORT" ]] || fail "No tienes acceso a $PORT. Comprueba el grupo dialout."
}

select_target() {
    BOARD_LABEL="$1"
    SENSOR_KIND="$2"
    case "$BOARD_LABEL:$SENSOR_KIND" in
        C:none|S:ds18b20|S:dht11|S:dht22|S:bmp280) ;;
        *) fail "Usa C none, o S ds18b20|dht11|dht22|bmp280. S requiere sensor real." ;;
    esac
    BUILD_DIR="$ZEPHYR_WORKSPACE/build-iot-lab4-$BOARD_LABEL-$SENSOR_KIND-$CONSOLE"
}
