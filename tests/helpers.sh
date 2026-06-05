#!/usr/bin/env bash

TESTS_RUN=0
TESTS_FAILED=0

assert_equals() {
  local expected=$1
  local actual=$2
  local label=${3:-}
  ((TESTS_RUN++)) || true
  if [[ "$expected" == "$actual" ]]; then
    return 0
  fi
  printf 'FAIL%s: esperado %q, obtuvo %q\n' "${label:+ [$label]}" "$expected" "$actual" >&2
  ((TESTS_FAILED++)) || true
  return 1
}

assert_file_exists() {
  local path=$1
  ((TESTS_RUN++)) || true
  if [[ -f "$path" ]]; then
    return 0
  fi
  printf 'FAIL: archivo no existe: %s\n' "$path" >&2
  ((TESTS_FAILED++)) || true
  return 1
}

assert_max_bytes() {
  local path=$1
  local max=$2
  local size
  ((TESTS_RUN++)) || true
  size=$(stat -c '%s' "$path" 2>/dev/null || stat -f '%z' "$path")
  if (( size <= max )); then
    return 0
  fi
  printf 'FAIL: %s tiene %s bytes (máx %s)\n' "$path" "$size" "$max" >&2
  ((TESTS_FAILED++)) || true
  return 1
}

assert_exit_code() {
  local expected=$1
  shift
  local code
  set +e
  "$@"
  code=$?
  set -e
  assert_equals "$expected" "$code" "$(printf '%q ' "$@")"
}

assert_contains() {
  local haystack=$1
  local needle=$2
  ((TESTS_RUN++)) || true
  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  fi
  printf 'FAIL: %q no contiene %q\n' "$haystack" "$needle" >&2
  ((TESTS_FAILED++)) || true
  return 1
}

assert_ffprobe_codec() {
  local path=$1
  local stream=$2
  local expected_codec=$3
  local actual
  ((TESTS_RUN++)) || true
  actual=$(ffprobe -v error -select_streams "${stream}:0" -show_entries stream=codec_name \
    -of csv=p=0 "$path" 2>/dev/null)
  if [[ "$actual" == "$expected_codec" ]]; then
    return 0
  fi
  printf 'FAIL: %s stream %s codec %q (esperado %q)\n' "$path" "$stream" "$actual" "$expected_codec" >&2
  ((TESTS_FAILED++)) || true
  return 1
}

assert_gt() {
  local a=$1
  local b=$2
  local label=${3:-}
  ((TESTS_RUN++)) || true
  if (( a > b )); then
    return 0
  fi
  printf 'FAIL%s: %s no es mayor que %s\n' "${label:+ [$label]}" "$a" "$b" >&2
  ((TESTS_FAILED++)) || true
  return 1
}

test_summary() {
  printf '\n=== Resumen: %d pruebas, %d fallos ===\n' "$TESTS_RUN" "$TESTS_FAILED"
  if (( TESTS_FAILED > 0 )); then
    return 1
  fi
  return 0
}
