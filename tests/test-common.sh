#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"
# shellcheck source=../lib/common.sh
source "${ROOT_DIR}/lib/common.sh"

FIXTURES="${SCRIPT_DIR}/tmp"

printf '== test-common ==\n'

bitrate=$(nemo_ffmpeg_calc_video_bitrate_kbps $((16 * 1024 * 1024)) 60 128 5)
assert_gt "$bitrate" 100 "bitrate 60s"

bitrate_short=$(nemo_ffmpeg_calc_video_bitrate_kbps $((16 * 1024 * 1024)) 5 128 5)
assert_gt "$bitrate_short" "$bitrate" "bitrate corto mayor que largo"

assert_equals "0" "$(nemo_ffmpeg_calc_video_bitrate_kbps 1000 0 128 5 || true)" "duración cero"

assert_exit_code 0 nemo_ffmpeg_has_audio_stream "${FIXTURES}/tone.wav"
assert_exit_code 0 nemo_ffmpeg_has_audio_stream "${FIXTURES}/short.mp4"
assert_exit_code 1 bash -c "source '${ROOT_DIR}/lib/common.sh'; nemo_ffmpeg_has_audio_stream '${FIXTURES}/no-audio.mp4'"

assert_exit_code 0 nemo_ffmpeg_has_video_stream "${FIXTURES}/short.mp4"
assert_exit_code 1 bash -c "source '${ROOT_DIR}/lib/common.sh'; nemo_ffmpeg_has_video_stream '${FIXTURES}/tone.wav'"

duration=$(nemo_ffmpeg_media_duration_seconds "${FIXTURES}/short.mp4")
assert_gt "${duration%%.*}" 4 "duración short.mp4"

test_summary
