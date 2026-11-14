#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$(command -v godot || printf '%s' "$HOME/.local/bin/godot")}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot not found. Install it on PATH or set GODOT to its executable." >&2
  exit 127
fi
# Register global classes and import assets before testing a fresh clone.
"$GODOT" --headless --path "$ROOT" --import --quit || exit $?
exec "$GODOT" --headless --path "$ROOT" --script res://tests/test_runner.gd
