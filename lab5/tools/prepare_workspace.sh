#!/usr/bin/env bash
# Creates a separate pinned workspace; never checks out or updates ~/zephyrproject.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -eq 0 ]] || fail "Uso: bash prepare_workspace.sh; opcional ZEPHYR_WORKSPACE=ruta_nueva."
if [[ -d "$ZEPHYR_WORKSPACE/zephyr/.git" ]]; then
    current_revision="$(git -C "$ZEPHYR_WORKSPACE/zephyr" rev-parse HEAD)"
    [[ "$current_revision" == "$ZEPHYR_REVISION" ]] || fail "Workspace existente con otra revisión. Usa una ruta nueva; no se hará checkout automático."
elif [[ -e "$ZEPHYR_WORKSPACE/.west" || -e "$ZEPHYR_WORKSPACE/zephyr" ]]; then
    fail "Workspace parcial en $ZEPHYR_WORKSPACE. Revisa su estado o usa otra ruta; no se elimina nada."
fi
command -v python3 >/dev/null || fail "Instala Python 3 y python3-venv."
mkdir -p "$ZEPHYR_WORKSPACE"
[[ -f "$ZEPHYR_WORKSPACE/.venv/bin/activate" ]] || python3 -m venv "$ZEPHYR_WORKSPACE/.venv"
source "$ZEPHYR_WORKSPACE/.venv/bin/activate"
python -m pip install --upgrade pip west
if [[ ! -d "$ZEPHYR_WORKSPACE/.west" ]]; then
    # git clone --branch cannot resolve a raw commit SHA. Fetch it explicitly,
    # then initialize west from the checked-out local manifest repository.
    if [[ ! -d "$ZEPHYR_WORKSPACE/zephyr/.git" ]]; then
        git init "$ZEPHYR_WORKSPACE/zephyr"
        git -C "$ZEPHYR_WORKSPACE/zephyr" remote add origin https://github.com/zephyrproject-rtos/zephyr
        git -C "$ZEPHYR_WORKSPACE/zephyr" fetch --depth 1 origin "$ZEPHYR_REVISION"
        git -C "$ZEPHYR_WORKSPACE/zephyr" checkout --detach FETCH_HEAD
    fi
    west init -l "$ZEPHYR_WORKSPACE/zephyr"
fi
cd -- "$ZEPHYR_WORKSPACE"
export ZEPHYR_BASE="$ZEPHYR_WORKSPACE/zephyr"
[[ "$(git -C zephyr rev-parse HEAD)" == "$ZEPHYR_REVISION" ]] || fail "El manifiesto no quedó en la revisión esperada."
west update
west packages pip --install
west zephyr-export
west blobs fetch hal_espressif
# Known CLI syntax from the course, one compiler target per invocation.
west sdk install -t riscv64-zephyr-elf
west sdk install -t xtensa-espressif_esp32s3_zephyr-elf
printf 'source %q\nsource %q\n' "$ZEPHYR_WORKSPACE/.venv/bin/activate" "$ZEPHYR_WORKSPACE/zephyr/zephyr-env.sh" > "$ZEPHYR_WORKSPACE/env.sh"
printf '\nWorkspace listo: %s\nZephyr: %s\n' "$ZEPHYR_WORKSPACE" "$ZEPHYR_REVISION"
printf 'La descarga puede ocupar varios GB; no modifica el workspace de Labs 0–4.\n'
