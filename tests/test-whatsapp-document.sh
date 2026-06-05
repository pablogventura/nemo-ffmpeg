#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FIXTURES="${SCRIPT_DIR}/tmp"
WORK="${FIXTURES}/work-doc"
LIB="${ROOT_DIR}/lib/video-whatsapp-document.sh"
readonly MAX=$((2 * 1024 * 1024 * 1024))

rm -rf "$WORK"
mkdir -p "$WORK"
cp "${FIXTURES}/short.mp4" "${WORK}/short.mp4"
cp "${FIXTURES}/compatible.mp4" "${WORK}/compatible.mp4"
cp "${FIXTURES}/sample.mkv" "${WORK}/sample.mkv"

printf '== test-whatsapp-document ==\n'

export MENU_FFMPEG_TEST=1

assert_exit_code 0 bash "$LIB" "${WORK}/short.mp4"
assert_file_exists "${WORK}/short-whatsapp-doc.mp4"
assert_max_bytes "${WORK}/short-whatsapp-doc.mp4" "$MAX"
assert_ffprobe_codec "${WORK}/short-whatsapp-doc.mp4" v h264
assert_ffprobe_codec "${WORK}/short-whatsapp-doc.mp4" a aac

output_log=$(mktemp)
assert_exit_code 0 bash -c "bash '$LIB' '${WORK}/compatible.mp4' 2>\"$output_log\""
assert_contains "$(cat "$output_log")" "modo copia"
assert_file_exists "${WORK}/compatible-whatsapp-doc.mp4"
rm -f "$output_log"

assert_exit_code 0 bash "$LIB" "${WORK}/sample.mkv"
assert_file_exists "${WORK}/sample-whatsapp-doc.mp4"
assert_ffprobe_codec "${WORK}/sample-whatsapp-doc.mp4" v h264
assert_ffprobe_codec "${WORK}/sample-whatsapp-doc.mp4" a aac

rm -f "${WORK}/short-whatsapp-doc.mp4"
touch "${WORK}/short-whatsapp-doc.mp4"
assert_exit_code 0 bash "$LIB" "${WORK}/short.mp4"

test_summary
