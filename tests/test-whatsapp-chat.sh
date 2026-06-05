#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FIXTURES="${SCRIPT_DIR}/tmp"
WORK="${FIXTURES}/work-chat"
LIB="${ROOT_DIR}/lib/video-whatsapp-chat.sh"
readonly MAX=$((16 * 1024 * 1024))

rm -rf "$WORK"
mkdir -p "$WORK"
cp "${FIXTURES}/short.mp4" "${WORK}/short.mp4"
cp "${FIXTURES}/long-ish.mp4" "${WORK}/long-ish.mp4"

printf '== test-whatsapp-chat ==\n'

export MENU_FFMPEG_TEST=1

assert_exit_code 0 bash "$LIB" "${WORK}/short.mp4"
assert_file_exists "${WORK}/short-whatsapp.mp4"
assert_max_bytes "${WORK}/short-whatsapp.mp4" "$MAX"
assert_ffprobe_codec "${WORK}/short-whatsapp.mp4" v h264
assert_ffprobe_codec "${WORK}/short-whatsapp.mp4" a aac

touch "${WORK}/short-whatsapp.mp4"
assert_exit_code 0 bash "$LIB" "${WORK}/short.mp4"

assert_exit_code 0 bash "$LIB" "${WORK}/long-ish.mp4"
assert_file_exists "${WORK}/long-ish-whatsapp.mp4"
assert_max_bytes "${WORK}/long-ish-whatsapp.mp4" "$MAX"

test_summary
