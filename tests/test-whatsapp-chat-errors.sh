#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

FIXTURES="${SCRIPT_DIR}/tmp"
WORK="${FIXTURES}/work-chat-errors"
LIB="${ROOT_DIR}/lib/video-whatsapp-chat.sh"

rm -rf "$WORK"
mkdir -p "$WORK"
cp "${FIXTURES}/no-audio.mp4" "${WORK}/no-audio.mp4"

printf '== test-whatsapp-chat-errors ==\n'

export MENU_FFMPEG_TEST=1

assert_exit_code 1 bash "$LIB" "${WORK}/no-audio.mp4"

test_summary
