#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

nemo_ffmpeg_require_deps || exit 1

if [[ $# -lt 1 ]]; then
  nemo_ffmpeg_log "uso: $(basename "$0") ARCHIVO [ARCHIVO...]"
  exit 1
fi

nemo_ffmpeg_reset_counters

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    nemo_ffmpeg_log "no existe: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  ext=${input##*.}
  ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
  output="${input%.*}.mp3"

  if [[ "$ext" == "mp3" ]]; then
    nemo_ffmpeg_log "omitido (ya es MP3): ${input}"
    ((MENU_FFMPEG_SKIPPED++)) || true
    continue
  fi

  if [[ -e "$output" && "${MENU_FFMPEG_FORCE:-}" != "1" ]]; then
    nemo_ffmpeg_log "omitido (ya existe): ${output}"
    ((MENU_FFMPEG_SKIPPED++)) || true
    continue
  fi

  if ! nemo_ffmpeg_has_audio_stream "$input"; then
    nemo_ffmpeg_log "sin pista de audio: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  nemo_ffmpeg_log "convirtiendo: ${input} -> ${output}"
  ffmpeg_args=(-hide_banner -loglevel error -nostdin -i "$input" -vn -codec:a libmp3lame -qscale:a 2)
  if [[ "${MENU_FFMPEG_FORCE:-}" == "1" ]]; then
    ffmpeg_args+=(-y)
  fi
  if ffmpeg "${ffmpeg_args[@]}" "$output"; then
    ((MENU_FFMPEG_OK++)) || true
  else
    nemo_ffmpeg_log "error al convertir: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
  fi
done

nemo_ffmpeg_notify_summary
exit $(( MENU_FFMPEG_FAILED > 0 ? 1 : 0 ))
