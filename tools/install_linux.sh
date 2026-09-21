#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME}"
ICON_SRC="$ROOT/icon.svg"
HICOLOR="$HOME_DIR/.local/share/icons/hicolor"
APP_DIR="$HOME_DIR/.local/share/applications"
BIN_DIR="$HOME_DIR/.local/bin"
SIZES=(16 22 24 32 48 64 128 256 512)

mkdir -p "$HICOLOR/scalable/apps" "$APP_DIR" "$BIN_DIR" \
	"$ROOT/assets/icons/hicolor/scalable/apps"

cp "$ICON_SRC" "$HICOLOR/scalable/apps/shadowfetch-roulette.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/shadowfetch-roulette.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/hicolor/scalable/apps/shadowfetch-roulette.svg"

for sz in "${SIZES[@]}"; do
	mkdir -p "$HICOLOR/${sz}x${sz}/apps" "$ROOT/assets/icons/hicolor/${sz}x${sz}/apps"
	rsvg-convert -w "$sz" -h "$sz" "$ICON_SRC" -o "$HICOLOR/${sz}x${sz}/apps/shadowfetch-roulette.png"
	cp "$HICOLOR/${sz}x${sz}/apps/shadowfetch-roulette.png" \
		"$ROOT/assets/icons/hicolor/${sz}x${sz}/apps/shadowfetch-roulette.png"
done
cp "$HICOLOR/512x512/apps/shadowfetch-roulette.png" "$ROOT/assets/icons/shadowfetch-roulette.png"

cat > "$BIN_DIR/shadowfetch-roulette" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="\${SHADOWFETCH_ROULETTE_ROOT:-$ROOT}"
BIN="\$ROOT/export/linux/shadowfetch-roulette.x86_64"
if [[ -x "\$BIN" ]]; then
	exec "\$BIN" "\$@"
fi
echo "Shadowfetch Roulette: exported Linux build not found. Run tools/export_linux.sh" >&2
exit 1
EOF
chmod +x "$BIN_DIR/shadowfetch-roulette"

cat > "$APP_DIR/shadowfetch-roulette.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Shadowfetch Roulette
GenericName=Roulette
Comment=European single-zero roulette. Fictional bankroll. No real-money gambling.
Exec=$BIN_DIR/shadowfetch-roulette
TryExec=$BIN_DIR/shadowfetch-roulette
Icon=shadowfetch-roulette
Terminal=false
Categories=Game;
Keywords=roulette;casino;wheel;shadowfetch;
StartupNotify=true
StartupWMClass=Shadowfetch Roulette
EOF

desktop-file-validate "$APP_DIR/shadowfetch-roulette.desktop"
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
	gtk-update-icon-cache -f "$HICOLOR" >/dev/null 2>&1 || true
fi

echo "Installed Shadowfetch Roulette launcher:"
echo "  $BIN_DIR/shadowfetch-roulette"
echo "  $APP_DIR/shadowfetch-roulette.desktop"
echo "  $HICOLOR/scalable/apps/shadowfetch-roulette.svg"
