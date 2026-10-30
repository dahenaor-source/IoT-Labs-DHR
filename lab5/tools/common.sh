#!/usr/bin/env bash
set -euo pipefail
LAB5_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ZEPHYR_WORKSPACE="${ZEPHYR_WORKSPACE:-$HOME/zephyrproject-lab5}"
ZEPHYR_REVISION=2f0bc11264a8e72e214f3db0a3fa221eb022453a
fail() { printf '%s\n' "$*" >&2; exit 1; }

select_target() {
    ROLE="${1:-}"
    PROFILE="${2:-}"
    case "$ROLE" in
        S|C)
            CONSOLE="${PROFILE:-uart}"
            case "$CONSOLE" in uart|usb) ;; *) fail "Uso: $ROLE [uart|usb]" ;; esac
            PROFILE="$([[ "$ROLE" == S ]] && printf ds18b20 || printf none)"
            SOURCE_DIR="$LAB5_DIR/firmware/nodes"
            BOARD=esp32c6_devkitc/esp32c6/hpcore
            FLASH_SIZE=4MB
            FLASH_KB=4096
            ;;
        RCP)
            [[ -z "$PROFILE" ]] || fail "RCP no acepta perfil ni consola: solo build.sh RCP."
            PROFILE=c6
            CONSOLE=spinel
            SOURCE_DIR="$LAB5_DIR/firmware/rcp"
            BOARD=esp32c6_devkitc/esp32c6/hpcore
            FLASH_SIZE=4MB
            FLASH_KB=4096
            ;;
        BR)
            case "$PROFILE" in N16R8|N8R8) ;; *) fail "Uso: BR N16R8 (confirmada) o BR N8R8. Requiere PSRAM octal de 8 MB." ;; esac
            CONSOLE=uart
            SOURCE_DIR="$LAB5_DIR/firmware/border_router"
            BOARD=esp32s3_devkitc/esp32s3/procpu
            # Both supported modules have at least 8 MB flash; map only that range.
            FLASH_SIZE=8MB
            FLASH_KB=8192
            ;;
        *) fail "Placa inválida: usa S, C, RCP o BR." ;;
    esac
    BUILD_DIR="$ZEPHYR_WORKSPACE/build-iot-lab5-$ROLE-$PROFILE-$CONSOLE"
    BUILD_LABEL="$ROLE-$PROFILE-$CONSOLE"
}

setup_workspace() {
    [[ -d "$ZEPHYR_WORKSPACE/.west" && -d "$ZEPHYR_WORKSPACE/zephyr" ]] || \
        fail "Prepara el workspace aislado: bash $LAB5_DIR/tools/prepare_workspace.sh"
    if [[ -f "$ZEPHYR_WORKSPACE/.venv/bin/activate" ]]; then
        source "$ZEPHYR_WORKSPACE/.venv/bin/activate"
    fi
    command -v west >/dev/null || fail "Falta west en el entorno del workspace."
    actual_revision="$(git -C "$ZEPHYR_WORKSPACE/zephyr" rev-parse HEAD)"
    [[ "$actual_revision" == "$ZEPHYR_REVISION" ]] || \
        fail "Zephyr $actual_revision no coincide con el pin del curso $ZEPHYR_REVISION. Usa el workspace aislado; no se cambia tu instalación anterior."
    export ZEPHYR_BASE="$ZEPHYR_WORKSPACE/zephyr"
    cd -- "$ZEPHYR_WORKSPACE"
}

check_port() {
    PORT="$1"
    [[ -c "$PORT" ]] || fail "No existe puerto $PORT. Identifica la placa y revisa usbipd attach."
    [[ -r "$PORT" && -w "$PORT" ]] || fail "Sin acceso a $PORT; comprueba dialout."
}

require_config() {
    grep -Fxq -- "$1" "$BUILD_DIR/zephyr/.config" || fail "Falta configuración esperada: $1"
}
