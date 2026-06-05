#!/usr/bin/env bash
# Funciones compartidas para nemo-ffmpeg.

MENU_FFMPEG_OK=0
MENU_FFMPEG_SKIPPED=0
MENU_FFMPEG_FAILED=0

nemo_ffmpeg_reset_counters() {
  MENU_FFMPEG_OK=0
  MENU_FFMPEG_SKIPPED=0
  MENU_FFMPEG_FAILED=0
}

nemo_ffmpeg_log() {
  printf 'nemo-ffmpeg: %s\n' "$*" >&2
}

nemo_ffmpeg_notify() {
  if [[ "${MENU_FFMPEG_TEST:-}" == "1" ]]; then
    return 0
  fi
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "nemo-ffmpeg" "$1"
  fi
}

nemo_ffmpeg_notify_summary() {
  local msg="Convertidos: ${MENU_FFMPEG_OK}, omitidos: ${MENU_FFMPEG_SKIPPED}, errores: ${MENU_FFMPEG_FAILED}"
  if (( MENU_FFMPEG_FAILED > 0 )); then
    nemo_ffmpeg_notify "${msg}"
    return 1
  fi
  nemo_ffmpeg_notify "${msg}"
  return 0
}

nemo_ffmpeg_require_deps() {
  local dep
  for dep in ffmpeg ffprobe; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      nemo_ffmpeg_log "falta ${dep} en PATH"
      return 1
    fi
  done
}

nemo_ffmpeg_has_audio_stream() {
  local path=$1
  ffprobe -v error -select_streams a:0 -show_entries stream=codec_type \
    -of csv=p=0 "$path" 2>/dev/null | grep -q .
}

nemo_ffmpeg_has_video_stream() {
  local path=$1
  ffprobe -v error -select_streams v:0 -show_entries stream=codec_type \
    -of csv=p=0 "$path" 2>/dev/null | grep -q .
}

nemo_ffmpeg_media_duration_seconds() {
  local path=$1
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$path" 2>/dev/null
}

nemo_ffmpeg_calc_audio_bitrate_kbps() {
  local target_bytes=$1
  local duration=$2
  local margin_pct=${3:-5}

  if [[ -z "$duration" || "$duration" == "N/A" ]]; then
    echo 0
    return 1
  fi

  awk -v target="$target_bytes" -v dur="$duration" -v margin="$margin_pct" '
    BEGIN {
      if (dur <= 0) { print 0; exit 1 }
      kbps = int((target * 8) / 1000 / dur * (100 - margin) / 100)
      if (kbps < 64) kbps = 64
      if (kbps > 320) kbps = 320
      print kbps
    }'
}

nemo_ffmpeg_is_mp3_file() {
  local path=$1
  local ext codec

  ext=${path##*.}
  ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
  [[ "$ext" == "mp3" ]] || return 1
  codec=$(nemo_ffmpeg_audio_codec "$path")
  [[ "$codec" == "mp3" ]]
}

nemo_ffmpeg_calc_video_bitrate_kbps() {
  local target_bytes=$1
  local duration=$2
  local audio_kbps=${3:-128}
  local margin_pct=${4:-5}

  if [[ -z "$duration" || "$duration" == "N/A" ]]; then
    echo 0
    return 1
  fi

  awk -v target="$target_bytes" -v dur="$duration" -v audio="$audio_kbps" -v margin="$margin_pct" '
    BEGIN {
      if (dur <= 0) { print 0; exit 1 }
      total_kbps = (target * 8) / 1000 / dur
      video_kbps = total_kbps - audio
      video_kbps = int(video_kbps * (100 - margin) / 100)
      if (video_kbps < 100) video_kbps = 100
      print video_kbps
    }'
}

nemo_ffmpeg_video_codec() {
  local path=$1
  ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
    -of csv=p=0 "$path" 2>/dev/null
}

nemo_ffmpeg_audio_codec() {
  local path=$1
  ffprobe -v error -select_streams a:0 -show_entries stream=codec_name \
    -of csv=p=0 "$path" 2>/dev/null
}

nemo_ffmpeg_is_h264_aac_mp4() {
  local path=$1
  local ext video_codec audio_codec

  ext=${path##*.}
  ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
  [[ "$ext" == "mp4" ]] || return 1

  video_codec=$(nemo_ffmpeg_video_codec "$path")
  audio_codec=$(nemo_ffmpeg_audio_codec "$path")

  [[ "$video_codec" == "h264" && "$audio_codec" == "aac" ]]
}

nemo_ffmpeg_file_size_bytes() {
  local path=$1
  stat -c '%s' "$path" 2>/dev/null || stat -f '%z' "$path" 2>/dev/null
}

nemo_ffmpeg_scale_filter_720() {
  echo "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2,format=yuv420p"
}

nemo_ffmpeg_scale_filter_1080() {
  echo "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2,format=yuv420p"
}
