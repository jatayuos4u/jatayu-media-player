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
mkdir -p dist
flatpak-builder --force-clean --repo=dist/flatpak-repo flatpak-build "$MANIFEST"
flatpak build-bundle dist/flatpak-repo "dist/${APP_ID}-1.0.0-x86_64.flatpak" "$APP_ID" master
sha256sum "dist/${APP_ID}-1.0.0-x86_64.flatpak"
echo "Local Flatpak bundle built. Install for testing with:"
echo "flatpak install --user ./dist/${APP_ID}-1.0.0-x86_64.flatpak"
echo "Run with: flatpak run ${APP_ID}"
