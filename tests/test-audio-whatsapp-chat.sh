#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FIXTURES="${SCRIPT_DIR}/tmp"
WORK="${FIXTURES}/work-audio-chat"
LIB="${ROOT_DIR}/lib/audio-whatsapp-chat.sh"
readonly MAX=$((16 * 1024 * 1024))

rm -rf "$WORK"
mkdir -p "$WORK"
cp "${FIXTURES}/tone.wav" "${WORK}/tone.wav"
cp "${FIXTURES}/long-audio.wav" "${WORK}/long-audio.wav"
ffmpeg -hide_banner -loglevel error -y -f lavfi -i sine=frequency=440:duration=2 \
  -c:a libmp3lame -b:a 128k "${WORK}/small.mp3"

printf '== test-audio-whatsapp-chat ==\n'

export MENU_FFMPEG_TEST=1

assert_exit_code 0 bash "$LIB" "${WORK}/tone.wav"
assert_file_exists "${WORK}/tone-whatsapp.mp3"
assert_max_bytes "${WORK}/tone-whatsapp.mp3" "$MAX"
assert_ffprobe_codec "${WORK}/tone-whatsapp.mp3" a mp3

assert_exit_code 0 bash "$LIB" "${WORK}/long-audio.wav"
assert_file_exists "${WORK}/long-audio-whatsapp.mp3"
assert_max_bytes "${WORK}/long-audio-whatsapp.mp3" "$MAX"

output_log=$(mktemp)
assert_exit_code 0 bash -c "bash '$LIB' '${WORK}/small.mp3' 2>\"$output_log\""
assert_contains "$(cat "$output_log")" "modo copia"
assert_file_exists "${WORK}/small-whatsapp.mp3"
rm -f "$output_log"

output_log=$(mktemp)
rm -f "${WORK}/tone-whatsapp.mp3"
export MENU_FFMPEG_CHAT_MAX_BYTES=20000
assert_exit_code 0 bash -c "bash '$LIB' '${WORK}/tone.wav' 2>\"$output_log\""
retry_log=$(cat "$output_log")
if [[ "$retry_log" != *"mono"* && "$retry_log" != *"menor bitrate (estéreo)"* ]]; then
  printf 'FAIL: se esperaba reintento (mono o estéreo) en: %s\n' "$retry_log" >&2
  ((TESTS_FAILED++)) || true
fi
unset MENU_FFMPEG_CHAT_MAX_BYTES
rm -f "$output_log"

rm -f "${WORK}/tone-whatsapp.mp3"
touch "${WORK}/tone-whatsapp.mp3"
assert_exit_code 0 bash "$LIB" "${WORK}/tone.wav"

test_summary
