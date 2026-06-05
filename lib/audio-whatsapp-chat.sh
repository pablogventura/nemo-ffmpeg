#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

WHATSAPP_CHAT_MAX_BYTES=${MENU_FFMPEG_CHAT_MAX_BYTES:-$((16 * 1024 * 1024))}

nemo_ffmpeg_require_deps || exit 1

if [[ $# -lt 1 ]]; then
  nemo_ffmpeg_log "uso: $(basename "$0") AUDIO [AUDIO...]"
  exit 1
fi

nemo_ffmpeg_reset_counters

nemo_ffmpeg_encode_audio_chat() {
  local input=$1
  local output=$2
  local bitrate_kbps=$3
  local channels=$4

  local -a ffmpeg_args=(
    -hide_banner -loglevel error -nostdin -i "$input"
    -vn -c:a libmp3lame -b:a "${bitrate_kbps}k" -ac "$channels"
  )
  if [[ "${MENU_FFMPEG_FORCE:-}" == "1" ]]; then
    ffmpeg_args+=(-y)
  fi
  ffmpeg "${ffmpeg_args[@]}" "$output"
}

nemo_ffmpeg_try_audio_chat_encode() {
  local input=$1
  local output=$2
  local duration=$3
  local channels=$4
  local bitrate_kbps size

  bitrate_kbps=$(nemo_ffmpeg_calc_audio_bitrate_kbps "$WHATSAPP_CHAT_MAX_BYTES" "$duration" 5)
  if [[ -z "$bitrate_kbps" || "$bitrate_kbps" -lt 64 ]]; then
    return 2
  fi

  rm -f "$output"
  if ! nemo_ffmpeg_encode_audio_chat "$input" "$output" "$bitrate_kbps" "$channels"; then
    return 1
  fi

  size=$(nemo_ffmpeg_file_size_bytes "$output")
  if (( size <= WHATSAPP_CHAT_MAX_BYTES )); then
    return 0
  fi
  return 3
}

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    nemo_ffmpeg_log "no existe: ${input}"
    ((MENU_FFMPEG_FAILED++)) || true
    continue
  fi

  output="${input%.*}-whatsapp.mp3"

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

  input_size=$(nemo_ffmpeg_file_size_bytes "$input")
  if nemo_ffmpeg_is_mp3_file "$input" && (( input_size <= WHATSAPP_CHAT_MAX_BYTES )); then
    nemo_ffmpeg_log "modo copia (sin recodificar): ${input} -> ${output}"
    copy_args=(-hide_banner -loglevel error -nostdin -i "$input" -vn -c copy)
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

  duration=$(nemo_ffmpeg_media_duration_seconds "$input")
  nemo_ffmpeg_log "codificando (audio chat): ${input} -> ${output}"

  rc=0
  nemo_ffmpeg_try_audio_chat_encode "$input" "$output" "$duration" 2 || rc=$?

  if (( rc == 3 )); then
    nemo_ffmpeg_log "supera el límite, reintentando con menor bitrate (estéreo)..."
    bitrate_kbps=$(nemo_ffmpeg_calc_audio_bitrate_kbps "$WHATSAPP_CHAT_MAX_BYTES" "$duration" 5)
    bitrate_kbps=$(( bitrate_kbps * 75 / 100 ))
    if (( bitrate_kbps < 64 )); then
      bitrate_kbps=64
    fi
    rm -f "$output"
    if nemo_ffmpeg_encode_audio_chat "$input" "$output" "$bitrate_kbps" 2; then
      size=$(nemo_ffmpeg_file_size_bytes "$output")
      if (( size <= WHATSAPP_CHAT_MAX_BYTES )); then
        rc=0
      fi
    else
      rc=1
    fi
  fi

  if (( rc == 3 )); then
    nemo_ffmpeg_log "supera el límite, reintentando en mono..."
    rm -f "$output"
    bitrate_kbps=$(nemo_ffmpeg_calc_audio_bitrate_kbps "$WHATSAPP_CHAT_MAX_BYTES" "$duration" 10)
    if (( bitrate_kbps < 64 )); then
      bitrate_kbps=64
    fi
    if nemo_ffmpeg_encode_audio_chat "$input" "$output" "$bitrate_kbps" 1; then
      size=$(nemo_ffmpeg_file_size_bytes "$output")
      if (( size <= WHATSAPP_CHAT_MAX_BYTES )); then
        rc=0
      fi
    else
      rc=1
    fi
  fi

  if (( rc == 0 )); then
    ((MENU_FFMPEG_OK++)) || true
  elif (( rc == 2 )); then
    nemo_ffmpeg_log "audio demasiado largo para el límite: ${input} (usa documento o recorta)"
    rm -f "$output"
    ((MENU_FFMPEG_FAILED++)) || true
  else
    nemo_ffmpeg_log "imposible caber en el límite: ${input} (usa documento o recorta)"
    rm -f "$output"
    ((MENU_FFMPEG_FAILED++)) || true
  fi
done

nemo_ffmpeg_notify_summary
exit $(( MENU_FFMPEG_FAILED > 0 ? 1 : 0 ))
