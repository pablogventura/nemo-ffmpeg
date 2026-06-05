#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
FIXTURES_DIR="${SCRIPT_DIR}/tmp"

mkdir -p "$FIXTURES_DIR"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg no encontrado" >&2
  exit 1
fi

make_wav() {
  ffmpeg -hide_banner -loglevel error -y -f lavfi -i sine=frequency=440:duration=2 \
    "${FIXTURES_DIR}/tone.wav"
}

make_short_mp4() {
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "testsrc=size=640x360:rate=25:duration=5" \
    -f lavfi -i "sine=frequency=880:duration=5" \
    -c:v libx264 -profile:v main -pix_fmt yuv420p -c:a aac -b:a 128k \
    "${FIXTURES_DIR}/short.mp4"
}

make_no_audio_mp4() {
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "testsrc=size=320x240:rate=25:duration=2" \
    -c:v libx264 -profile:v main -pix_fmt yuv420p -an \
    "${FIXTURES_DIR}/no-audio.mp4"
}

make_longish_mp4() {
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "testsrc=size=1280x720:rate=25:duration=45" \
    -f lavfi -i "sine=frequency=660:duration=45" \
    -c:v libx264 -profile:v main -pix_fmt yuv420p -b:v 2500k \
    -c:a aac -b:a 192k \
    "${FIXTURES_DIR}/long-ish.mp4"
}

make_compatible_mp4() {
  cp -f "${FIXTURES_DIR}/short.mp4" "${FIXTURES_DIR}/compatible.mp4"
}

make_wav
make_short_mp4
make_no_audio_mp4
make_longish_mp4
make_compatible_mp4

echo "Fixtures en ${FIXTURES_DIR}"
