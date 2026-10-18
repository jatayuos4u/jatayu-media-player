#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=1.0.0
APP_ID=io.github.jatayuos4u.JatayuMediaPlayer
DEB="dist/jatayu-media-player_${VERSION}_x86_64.deb"
FLATPAK="dist/${APP_ID}-${VERSION}-x86_64.flatpak"

for p in "$DEB" "$FLATPAK"; do
  [[ -s "$p" ]] || { echo "Missing release candidate: $p" >&2; exit 1; }
done
dpkg-deb --field "$DEB" Package Version Architecture
[[ "$(dpkg-deb --field "$DEB" Version)" == "$VERSION"* ]] || { echo "Debian version mismatch" >&2; exit 1; }
[[ "$(dpkg-deb --field "$DEB" Architecture)" == "amd64" ]] || { echo "Debian architecture mismatch" >&2; exit 1; }

python3 - "$FLATPAK" <<'PY'
import pathlib, sys
bundle = pathlib.Path(sys.argv[1])
if bundle.stat().st_size < 1024:
    raise SystemExit("Flatpak bundle suspiciously small")
print("Flatpak bundle exists:", bundle, bundle.stat().st_size, "bytes")
PY

git rev-parse HEAD > dist/SOURCE-COMMIT.txt
sha256sum "$DEB" "$FLATPAK" > dist/SHA256SUMS
sha256sum --check dist/SHA256SUMS
echo
echo "Release-candidate checksums created. Files were NOT published."
echo "Commit: $(cat dist/SOURCE-COMMIT.txt)"
cat dist/SHA256SUMS
echo
echo "Before publishing: complete docs/V1-THREE-DAY-RELEASE-PLAN.md checks,"
echo "test both packages after final build, and verify licensing and update channels."
