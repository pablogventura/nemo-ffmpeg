#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FIXTURES="${SCRIPT_DIR}/tmp"
WORK="${FIXTURES}/work-audio-doc"
LIB="${ROOT_DIR}/lib/audio-whatsapp-document.sh"
readonly MAX=$((2 * 1024 * 1024 * 1024))

rm -rf "$WORK"
mkdir -p "$WORK"
cp "${FIXTURES}/tone.wav" "${WORK}/tone.wav"
ffmpeg -hide_banner -loglevel error -y -f lavfi -i sine=frequency=440:duration=2 \
  -c:a libmp3lame -b:a 128k "${WORK}/small.mp3"

printf '== test-audio-whatsapp-document ==\n'

export MENU_FFMPEG_TEST=1

assert_exit_code 0 bash "$LIB" "${WORK}/tone.wav"
assert_file_exists "${WORK}/tone-whatsapp-doc.mp3"
assert_max_bytes "${WORK}/tone-whatsapp-doc.mp3" "$MAX"
assert_ffprobe_codec "${WORK}/tone-whatsapp-doc.mp3" a mp3

output_log=$(mktemp)
assert_exit_code 0 bash -c "bash '$LIB' '${WORK}/small.mp3' 2>\"$output_log\""
assert_contains "$(cat "$output_log")" "modo copia"
assert_file_exists "${WORK}/small-whatsapp-doc.mp3"
rm -f "$output_log"

rm -f "${WORK}/tone-whatsapp-doc.mp3"
touch "${WORK}/tone-whatsapp-doc.mp3"
assert_exit_code 0 bash "$LIB" "${WORK}/tone.wav"

test_summary
