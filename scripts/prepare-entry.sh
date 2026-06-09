#!/usr/bin/env bash
set -euo pipefail
if [[ "${CI:-}" == "true" ]]; then
  echo "[prepare-entry] skip pre.sh in CI"
  exit 0
fi
exec ./src/build/pre.sh
