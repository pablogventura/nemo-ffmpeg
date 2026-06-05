#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FAKE_HOME=$(mktemp -d)
export HOME="$FAKE_HOME"

cleanup() {
  rm -rf "$FAKE_HOME"
}
trap cleanup EXIT

printf '== test-install ==\n'

assert_exit_code 0 bash "${ROOT_DIR}/install.sh" install

APP_DIR="${HOME}/.local/share/nemo-ffmpeg"
ACTIONS_DIR="${HOME}/.local/share/nemo/actions"

assert_file_exists "${APP_DIR}/lib/convert-to-mp3.sh"
assert_file_exists "${APP_DIR}/lib/audio-whatsapp-chat.sh"
assert_file_exists "${APP_DIR}/lib/audio-whatsapp-document.sh"
assert_file_exists "${APP_DIR}/lib/video-whatsapp-chat.sh"
assert_file_exists "${APP_DIR}/lib/video-whatsapp-document.sh"
assert_file_exists "${ACTIONS_DIR}/ffmpeg-convert-mp3.nemo_action"
assert_file_exists "${ACTIONS_DIR}/ffmpeg-audio-whatsapp-chat.nemo_action"
assert_file_exists "${ACTIONS_DIR}/ffmpeg-audio-whatsapp-document.nemo_action"
assert_file_exists "${ACTIONS_DIR}/ffmpeg-whatsapp-chat.nemo_action"
assert_file_exists "${ACTIONS_DIR}/ffmpeg-whatsapp-document.nemo_action"
assert_file_exists "${APP_DIR}/installed.json"

content=$(cat "${ACTIONS_DIR}/ffmpeg-convert-mp3.nemo_action")
assert_contains "$content" "FFmpeg: Convertir a MP3"
assert_contains "$content" "${APP_DIR}/lib/convert-to-mp3.sh"

content=$(cat "${ACTIONS_DIR}/ffmpeg-audio-whatsapp-chat.nemo_action")
assert_contains "$content" "FFmpeg: Audio WhatsApp (chat)"
assert_contains "$content" "${APP_DIR}/lib/audio-whatsapp-chat.sh"

content=$(cat "${ACTIONS_DIR}/ffmpeg-audio-whatsapp-document.nemo_action")
assert_contains "$content" "FFmpeg: Audio WhatsApp (documento)"
assert_contains "$content" "${APP_DIR}/lib/audio-whatsapp-document.sh"

content=$(cat "${ACTIONS_DIR}/ffmpeg-whatsapp-chat.nemo_action")
assert_contains "$content" "FFmpeg: Vídeo WhatsApp (chat)"
assert_contains "$content" "${APP_DIR}/lib/video-whatsapp-chat.sh"

content=$(cat "${ACTIONS_DIR}/ffmpeg-whatsapp-document.nemo_action")
assert_contains "$content" "FFmpeg: Vídeo WhatsApp (documento)"
assert_contains "$content" "${APP_DIR}/lib/video-whatsapp-document.sh"

assert_exit_code 0 bash "${ROOT_DIR}/install.sh" install
assert_file_exists "${APP_DIR}/installed.json"

assert_exit_code 0 bash "${ROOT_DIR}/install.sh" status

assert_exit_code 0 bash "${ROOT_DIR}/install.sh" uninstall
assert_exit_code 1 bash -c "test -d '${APP_DIR}'"
assert_exit_code 1 bash -c "test -f '${ACTIONS_DIR}/ffmpeg-convert-mp3.nemo_action'"

test_summary
