#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -eq 2 ]] || fail "Uso: bash monitor.sh C|S /dev/ttyACM0"
setup_workspace
check_board_port "$1" "$2"
printf 'Monitor de %s en %s, 115200 baudios. Salir: Ctrl+]\n' "$BOARD_LABEL" "$PORT"
west espressif monitor -p "$PORT"
