#!/usr/bin/env bash
# Same as run_online_duel_dev.ps1 for macOS/Linux.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

command -v java >/dev/null 2>&1 || { echo "Java 17+ required"; exit 1; }
command -v npx >/dev/null 2>&1 || { echo "Node.js / npx required"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "flutter not in PATH"; exit 1; }

DEVICE_HOST="${1:-}"

npx --yes firebase-tools@14 emulators:start --only firestore --project demo-sudoku-duel &
EMU_PID=$!

cleanup() { kill "$EMU_PID" 2>/dev/null || true; }
trap cleanup EXIT

for i in $(seq 1 90); do
  if nc -z 127.0.0.1 8080 2>/dev/null; then
    break
  fi
  sleep 1
done

DEFINES="--dart-define=DUEL_USE_EMULATOR=true"
if [[ -n "$DEVICE_HOST" ]]; then
  DEFINES="$DEFINES --dart-define=DUEL_EMULATOR_HOST=$DEVICE_HOST"
fi

flutter run $DEFINES
