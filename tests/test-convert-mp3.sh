#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FIXTURES="${SCRIPT_DIR}/tmp"
WORK="${FIXTURES}/work-mp3"
LIB="${ROOT_DIR}/lib/convert-to-mp3.sh"

rm -rf "$WORK"
mkdir -p "$WORK"
cp "${FIXTURES}/tone.wav" "${WORK}/tone.wav"
cp "${FIXTURES}/short.mp4" "${WORK}/short.mp4"
cp "${FIXTURES}/no-audio.mp4" "${WORK}/no-audio.mp4"

printf '== test-convert-mp3 ==\n'

export MENU_FFMPEG_TEST=1

assert_exit_code 0 bash "$LIB" "${WORK}/tone.wav"
assert_file_exists "${WORK}/tone.mp3"
assert_ffprobe_codec "${WORK}/tone.mp3" a mp3

assert_exit_code 0 bash "$LIB" "${WORK}/short.mp4"
assert_file_exists "${WORK}/short.mp3"

cp "${WORK}/tone.wav" "${WORK}/skip-me.wav"
touch "${WORK}/skip-me.mp3"
before_size=$(stat -c '%s' "${WORK}/skip-me.mp3")
assert_exit_code 0 bash "$LIB" "${WORK}/skip-me.wav"
after_size=$(stat -c '%s' "${WORK}/skip-me.mp3")
assert_equals "$before_size" "$after_size" "no sobrescribe mp3 existente"

cp "${WORK}/tone.mp3" "${WORK}/already.mp3"
assert_exit_code 0 bash "$LIB" "${WORK}/already.mp3"

assert_exit_code 1 bash "$LIB" "${WORK}/no-audio.mp4"

cp "${WORK}/tone.wav" "${WORK}/force-me.wav"
touch "${WORK}/force-me.mp3"
export MENU_FFMPEG_FORCE=1
assert_exit_code 0 bash "$LIB" "${WORK}/force-me.wav"
force_size=$(stat -c '%s' "${WORK}/force-me.mp3")
assert_gt "$force_size" 0 "MENU_FFMPEG_FORCE sobrescribe"
unset MENU_FFMPEG_FORCE

test_summary
