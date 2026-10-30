#!/usr/bin/env bash
set -euo pipefail
LAB5_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $# -eq 0 ]] || { printf 'Uso: bash setup_host.sh\n' >&2; exit 1; }
[[ -x "$LAB5_DIR/.venv/bin/python" ]] || python3 -m venv "$LAB5_DIR/.venv"
"$LAB5_DIR/.venv/bin/python" -m pip install -r "$LAB5_DIR/tools/requirements.txt"
printf '\nActiva el entorno de cliente: source %s/.venv/bin/activate\n' "$LAB5_DIR"
