#!/usr/bin/env bash
# Instala acciones Nemo de nemo-ffmpeg en el perfil del usuario.
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
APP_DIR="${HOME}/.local/share/nemo-ffmpeg"
NEMO_ACTIONS_DIR="${HOME}/.local/share/nemo/actions"
MANIFEST="${APP_DIR}/installed.json"
VERSION_FILE="${SCRIPT_DIR}/VERSION"

ACTIONS=(
  "ffmpeg-convert-mp3.nemo_action:convert-to-mp3.sh"
  "ffmpeg-whatsapp-chat.nemo_action:video-whatsapp-chat.sh"
  "ffmpeg-whatsapp-document.nemo_action:video-whatsapp-document.sh"
)

usage() {
  cat <<EOF
Uso: $(basename "$0") [install|uninstall|status]

  install    Instala o actualiza lib/ y acciones Nemo (por defecto)
  uninstall  Elimina lo instalado por este proyecto
  status     Muestra versión y rutas instaladas
EOF
}

read_version() {
  if [[ -f "$VERSION_FILE" ]]; then
    tr -d '[:space:]' < "$VERSION_FILE"
  else
    echo "unknown"
  fi
}

check_deps() {
  local missing=()
  for dep in ffmpeg ffprobe; do
    command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
  done
  if ((${#missing[@]} > 0)); then
    printf 'Faltan dependencias: %s\n' "${missing[*]}" >&2
    printf 'Instalación sugerida: sudo apt install ffmpeg libnotify-bin nemo\n' >&2
    return 1
  fi
}

write_manifest() {
  local version installed_at
  version=$(read_version)
  installed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$APP_DIR"
  {
    printf '{\n'
    printf '  "name": "nemo-ffmpeg",\n'
    printf '  "version": "%s",\n' "$version"
    printf '  "installed_at": "%s",\n' "$installed_at"
    printf '  "app_dir": "%s",\n' "$APP_DIR"
    printf '  "files": [\n'
    local first=1 entry action lib_script lib_path action_path
    for entry in "${ACTIONS[@]}"; do
      action=${entry%%:*}
      lib_script=${entry##*:}
      lib_path="${APP_DIR}/lib/${lib_script}"
      action_path="${NEMO_ACTIONS_DIR}/${action}"
      if (( first )); then first=0; else printf ',\n'; fi
      printf '    "%s"' "$lib_path"
      printf ',\n    "%s"' "$action_path"
    done
    printf ',\n    "%s"\n' "$MANIFEST"
    printf '  ]\n'
    printf '}\n'
  } > "$MANIFEST"
}

install_action() {
  local action_name=$1
  local lib_script=$2
  local template="${SCRIPT_DIR}/nemo/${action_name}.in"
  local lib_dest="${APP_DIR}/lib/${lib_script}"
  local action_dest="${NEMO_ACTIONS_DIR}/${action_name}"

  if [[ ! -f "$template" ]]; then
    printf 'Plantilla no encontrada: %s\n' "$template" >&2
    return 1
  fi

  sed "s|@INSTALL_LIB@|${lib_dest}|g" "$template" > "$action_dest"
  chmod 644 "$action_dest"
}

do_install() {
  check_deps || exit 1

  mkdir -p "${APP_DIR}/lib" "$NEMO_ACTIONS_DIR"

  install -m 755 "${SCRIPT_DIR}/lib/common.sh" "${APP_DIR}/lib/common.sh"
  install -m 755 "${SCRIPT_DIR}/lib/convert-to-mp3.sh" "${APP_DIR}/lib/convert-to-mp3.sh"
  install -m 755 "${SCRIPT_DIR}/lib/video-whatsapp-chat.sh" "${APP_DIR}/lib/video-whatsapp-chat.sh"
  install -m 755 "${SCRIPT_DIR}/lib/video-whatsapp-document.sh" "${APP_DIR}/lib/video-whatsapp-document.sh"
  install -m 644 "$VERSION_FILE" "${APP_DIR}/VERSION"

  local entry action lib_script
  for entry in "${ACTIONS[@]}"; do
    action=${entry%%:*}
    lib_script=${entry##*:}
    install_action "$action" "$lib_script"
  done

  write_manifest

  version=$(read_version)
  printf 'nemo-ffmpeg %s instalado.\n' "$version"
  printf '  lib:     %s/lib/\n' "$APP_DIR"
  printf '  acciones: %s/ffmpeg-*.nemo_action\n' "$NEMO_ACTIONS_DIR"
  printf '\nReinicia Nemo si no ves las acciones: nemo --quit\n'
}

do_uninstall() {
  if [[ -f "$MANIFEST" ]]; then
    python3 - <<'PY' "$MANIFEST" 2>/dev/null || true
import json, os, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
for item in data.get("files", []):
    if os.path.isfile(item):
        os.remove(item)
PY
  fi

  local entry action
  for entry in "${ACTIONS[@]}"; do
    action=${entry%%:*}
    rm -f "${NEMO_ACTIONS_DIR}/${action}"
  done

  rm -rf "$APP_DIR"
  printf 'nemo-ffmpeg desinstalado.\n'
}

do_status() {
  local version
  version=$(read_version)
  if [[ -f "$MANIFEST" ]]; then
    printf 'nemo-ffmpeg instalado (versión del paquete: %s)\n' "$version"
    if [[ -f "${APP_DIR}/VERSION" ]]; then
      printf '  versión instalada: %s\n' "$(tr -d '[:space:]' < "${APP_DIR}/VERSION")"
    fi
    printf '  app_dir: %s\n' "$APP_DIR"
    printf '  acciones:\n'
    local entry action
    for entry in "${ACTIONS[@]}"; do
      action=${entry%%:*}
      if [[ -f "${NEMO_ACTIONS_DIR}/${action}" ]]; then
        printf '    ✓ %s\n' "${NEMO_ACTIONS_DIR}/${action}"
      else
        printf '    ✗ %s (no encontrada)\n' "${NEMO_ACTIONS_DIR}/${action}"
      fi
    done
  else
    printf 'nemo-ffmpeg no instalado (versión del paquete: %s)\n' "$version"
    exit 1
  fi
}

main() {
  local cmd=${1:-install}
  case "$cmd" in
    install) do_install ;;
    uninstall) do_uninstall ;;
    status) do_status ;;
    -h|--help|help) usage ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
