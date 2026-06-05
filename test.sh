#!/usr/bin/env bash
exec "$(CDPATH= cd -- "$(dirname "$0")" && pwd)/tests/run-tests.sh" "$@"
