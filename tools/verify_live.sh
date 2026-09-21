#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
BIN="$ROOT/export/linux/shadowfetch-roulette.x86_64"

echo "== automated rules tests =="
"$ROOT/tools/run_tests.sh"

echo "== headless menu boot =="
timeout 20s "$GODOT" --headless --path "$ROOT" --quit-after 2

echo "== headless self-test spin =="
timeout 25s "$GODOT" --headless --path "$ROOT" -- --self-test

if [[ -x "$BIN" ]]; then
	echo "== installed-style release self-test =="
	timeout 25s "$BIN" --headless -- --self-test
else
	echo "Release binary not built yet; skip binary self-test"
fi

echo "verify_live ok"
