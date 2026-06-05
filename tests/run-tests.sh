#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
export MENU_FFMPEG_TEST=1

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "Se requieren ffmpeg y ffprobe para ejecutar los tests." >&2
  exit 1
fi

bash "${SCRIPT_DIR}/make-fixtures.sh"

failed=0
for test_script in \
  "${SCRIPT_DIR}/test-common.sh" \
  "${SCRIPT_DIR}/test-convert-mp3.sh" \
  "${SCRIPT_DIR}/test-whatsapp-chat.sh" \
  "${SCRIPT_DIR}/test-whatsapp-document.sh" \
  "${SCRIPT_DIR}/test-install.sh"
do
  if ! bash "$test_script"; then
    failed=1
  fi
done

if (( failed != 0 )); then
  echo "Algunos tests fallaron." >&2
  exit 1
fi

echo "Todos los tests pasaron."
