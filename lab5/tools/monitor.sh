#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -eq 2 ]] || fail "Uso: monitor.sh S|C|BR PUERTO"
case "$1" in S|C|BR) ;; RCP) fail "El RCP no tiene shell. Verifícalo desde BR con ot rcp version." ;; *) fail "Etiqueta inválida." ;; esac
setup_workspace
check_port "$2"
printf 'Monitor %s en %s a 115200 baudios. Salir Ctrl+]. No guardes credenciales ni datasets.\n' "$1" "$PORT"
# A serial console does not need a west build configuration.
python -m serial.tools.miniterm "$PORT" 115200 --raw
