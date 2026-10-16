#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP_ID=io.github.jatayuos4u.JatayuMediaPlayer
MANIFEST="flatpak/${APP_ID}.json"
for cmd in flatpak flatpak-builder; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd (install flatpak and flatpak-builder)" >&2; exit 1; }
done
echo "Checking KDE 6.10 runtime/SDK (install them from Flathub if missing)..."
flatpak info org.kde.Sdk//6.10 >/dev/null || {
  echo "Missing org.kde.Sdk 6.10; use: flatpak install flathub org.kde.Sdk//6.10 org.kde.Platform//6.10" >&2; exit 1;
}
echo "Generating AppStream-compatible PNG from the project SVG..."
if ! python3 -c 'import cairosvg' >/dev/null 2>&1; then
  echo "Missing Python CairoSVG. On Debian install: sudo apt install python3-cairosvg" >&2
  exit 1
fi
python3 - <<'PY'
from pathlib import Path
import cairosvg
source = Path("assets/jatayu-media-player.svg")
target = Path("flatpak/icon-128.png")
cairosvg.svg2png(url=str(source), write_to=str(target), output_width=128, output_height=128)
print("Created", target)
PY
mkdir -p dist
flatpak-builder --force-clean --repo=dist/flatpak-repo flatpak-build "$MANIFEST"
flatpak build-bundle dist/flatpak-repo "dist/${APP_ID}-1.0.0-x86_64.flatpak" "$APP_ID" master
sha256sum "dist/${APP_ID}-1.0.0-x86_64.flatpak"
echo "Local Flatpak bundle built. Install for testing with:"
echo "flatpak install --user ./dist/${APP_ID}-1.0.0-x86_64.flatpak"
echo "Run with: flatpak run ${APP_ID}"
