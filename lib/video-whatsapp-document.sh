#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

readonly WHATSAPP_DOC_MAX_BYTES=$((2 * 1024 * 1024 * 1024))

nemo_ffmpeg_require_deps || exit 1

if [[ $# -lt 1 ]]; then
  nemo_ffmpeg_log "uso: $(basename "$0") VIDEO [VIDEO...]"
  exit 1
fi

nemo_ffmpeg_reset_counters

nemo_ffmpeg_needs_scale_down() {
  local path=$1
  local width height

  width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$path" 2>/dev/null)
  height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$path" 2>/dev/null)

  [[ -n "$width" && -n "$height" && ( width -gt 1920 || height -gt 1080 ) ]]
}

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    nemo_ffmpeg_log "no existe: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  output="${input%.*}-whatsapp-doc.mp4"
  input_size=$(nemo_ffmpeg_file_size_bytes "$input")

  if (( input_size > WHATSAPP_DOC_MAX_BYTES )); then
    nemo_ffmpeg_log "origen mayor a 2 GB: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

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

  if nemo_ffmpeg_is_h264_aac_mp4 "$input" && (( input_size <= WHATSAPP_DOC_MAX_BYTES )); then
    nemo_ffmpeg_log "modo copia (sin recodificar): ${input} -> ${output}"
    copy_args=(-hide_banner -loglevel error -nostdin -i "$input" -c copy -movflags +faststart)
    if [[ "${MENU_FFMPEG_FORCE:-}" == "1" ]]; then
      copy_args+=(-y)
    fi
    if ffmpeg "${copy_args[@]}" "$output"; then
      ((MENU_FFMPEG_OK++)) || true
    else
      nemo_ffmpeg_log "error en copia: ${input}"
      ((MENU_FFMPEG_FAILED++)) || true
    fi
    continue
  fi

  nemo_ffmpeg_log "codificando (documento): ${input} -> ${output}"

  encode_args=(-hide_banner -loglevel error -nostdin -i "$input")
  if nemo_ffmpeg_needs_scale_down "$input"; then
    encode_args+=(-vf "$(nemo_ffmpeg_scale_filter_1080)")
  fi
  encode_args+=(
    -c:v libx264 -profile:v main -crf 20
    -c:a aac -b:a 192k -ac 2
    -movflags +faststart
  )
  if [[ "${MENU_FFMPEG_FORCE:-}" == "1" ]]; then
    encode_args+=(-y)
  fi
  if ffmpeg "${encode_args[@]}" "$output"; then
    out_size=$(nemo_ffmpeg_file_size_bytes "$output")
    if (( out_size > WHATSAPP_DOC_MAX_BYTES )); then
      nemo_ffmpeg_log "resultado mayor a 2 GB: ${output}"
      rm -f "$output"
      ((MENU_FFMPEG_FAILED++)) || true
    else
      ((MENU_FFMPEG_OK++)) || true
    fi
  else
    nemo_ffmpeg_log "error al codificar: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
  fi
done

nemo_ffmpeg_notify_summary
exit $(( MENU_FFMPEG_FAILED > 0 ? 1 : 0 ))
