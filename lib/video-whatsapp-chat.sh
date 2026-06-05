#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

readonly WHATSAPP_CHAT_MAX_BYTES=$((16 * 1024 * 1024))
readonly WHATSAPP_CHAT_AUDIO_KBPS=128

nemo_ffmpeg_require_deps || exit 1

if [[ $# -lt 1 ]]; then
  nemo_ffmpeg_log "uso: $(basename "$0") VIDEO [VIDEO...]"
  exit 1
fi

nemo_ffmpeg_reset_counters

nemo_ffmpeg_encode_chat() {
  local input=$1
  local output=$2
  local video_kbps=$3

  local -a ffmpeg_args=(
    -hide_banner -loglevel error -nostdin -i "$input"
    -vf "$(nemo_ffmpeg_scale_filter_720)"
    -c:v libx264 -profile:v main -level 3.1
    -b:v "${video_kbps}k" -maxrate "$((video_kbps * 12 / 10))k"
    -bufsize "$((video_kbps * 2))k"
    -c:a aac -b:a "${WHATSAPP_CHAT_AUDIO_KBPS}k" -ac 2
    -movflags +faststart
  )
  if [[ "${MENU_FFMPEG_FORCE:-}" == "1" ]]; then
    ffmpeg_args+=(-y)
  fi
  ffmpeg "${ffmpeg_args[@]}" "$output"
}

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    nemo_ffmpeg_log "no existe: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  output="${input%.*}-whatsapp.mp4"

  if [[ -e "$output" && "${MENU_FFMPEG_FORCE:-}" != "1" ]]; then
    nemo_ffmpeg_log "omitido (ya existe): ${output}"
    ((MENU_FFMPEG_SKIPPED++)) || true
    continue
  fi

  if ! nemo_ffmpeg_has_video_stream "$input"; then
    nemo_ffmpeg_log "sin pista de vídeo: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  if ! nemo_ffmpeg_has_audio_stream "$input"; then
    nemo_ffmpeg_log "sin pista de audio: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  duration=$(nemo_ffmpeg_media_duration_seconds "$input")
  video_kbps=$(nemo_ffmpeg_calc_video_bitrate_kbps "$WHATSAPP_CHAT_MAX_BYTES" "$duration" "$WHATSAPP_CHAT_AUDIO_KBPS" 5)

  if [[ -z "$video_kbps" || "$video_kbps" -lt 100 ]]; then
    nemo_ffmpeg_log "vídeo demasiado largo para 16 MB: ${input} (usa modo documento o recorta)"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  nemo_ffmpeg_log "codificando (chat, ~${video_kbps}k vídeo): ${input} -> ${output}"

  if ! nemo_ffmpeg_encode_chat "$input" "$output" "$video_kbps"; then
    nemo_ffmpeg_log "error al codificar: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  size=$(nemo_ffmpeg_file_size_bytes "$output")
  if (( size > WHATSAPP_CHAT_MAX_BYTES )); then
    nemo_ffmpeg_log "supera 16 MB (${size} bytes), reintentando con menor bitrate..."
    rm -f "$output"
    video_kbps=$(( video_kbps * 75 / 100 ))
    if (( video_kbps < 100 )); then
      nemo_ffmpeg_log "imposible caber en 16 MB: ${input}"
      ((MENU_FFMPEG_FAILED++)) || true
      continue
    fi
    if ! nemo_ffmpeg_encode_chat "$input" "$output" "$video_kbps"; then
      nemo_ffmpeg_log "error en reintento: ${input}"
      ((MENU_FFMPEG_FAILED++)) || true
      continue
    fi
    size=$(nemo_ffmpeg_file_size_bytes "$output")
    if (( size > WHATSAPP_CHAT_MAX_BYTES )); then
      nemo_ffmpeg_log "sigue superando 16 MB tras reintento: ${input}"
      rm -f "$output"
      ((MENU_FFMPEG_FAILED++)) || true
      continue
    fi
  fi

  ((MENU_FFMPEG_OK++)) || true
done

nemo_ffmpeg_notify_summary
exit $(( MENU_FFMPEG_FAILED > 0 ? 1 : 0 ))
