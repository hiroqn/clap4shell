#!/usr/bin/env bash
# Usage: tests/e2e/run.sh [bats options...]
# Runs the suite once per shell in $E2E_SHELLS (default: bash zsh dash).
# clap4shell is taken from $PATH.

set -eu

dir=$(cd "$(dirname "$0")" && pwd)
status=0

for shell in ${E2E_SHELLS:-bash zsh dash}; do
  echo "# E2E_SHELL=$shell"
  E2E_SHELL=$shell bats "$@" "$dir" || status=1
done

exit $status
