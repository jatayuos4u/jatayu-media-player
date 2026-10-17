#!/usr/bin/env bash
# Read-only evidence collection; does not certify license compliance.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="dist/v1-compliance-evidence"
mkdir -p "$OUT"
printf '%s\n' "Source revision: $(git rev-parse HEAD)" > "$OUT/README.txt"
printf '%s\n' "Tested release candidate source revision: cdccb895c3b80f9ecac8827cb115adc43bdaa731" >> "$OUT/README.txt"
cp LICENSE "$OUT/JATAYU-LICENSE.txt"
cp flatpak/io.github.jatayuos4u.JatayuMediaPlayer.json "$OUT/flatpak-manifest.json"
cp flatpak/libmpv.json "$OUT/libmpv-build-manifest.json"
cp docs/V1-BUNDLED-DEPENDENCY-INVENTORY.md "$OUT/PENDING-REVIEW.md"
if command -v dpkg-deb >/dev/null && [[ -f dist/jatayu-media-player_1.0.0_x86_64.deb ]]; then
  dpkg-deb -I dist/jatayu-media-player_1.0.0_x86_64.deb > "$OUT/debian-package-metadata.txt"
  dpkg-deb -c dist/jatayu-media-player_1.0.0_x86_64.deb > "$OUT/debian-package-files.txt"
fi
if command -v ldd >/dev/null && [[ -f build/jatayu-media-player ]]; then
  ldd build/jatayu-media-player > "$OUT/local-build-dynamic-libraries.txt" || true
fi
if command -v flatpak >/dev/null; then
  flatpak info --user io.github.jatayuos4u.JatayuMediaPlayer > "$OUT/local-flatpak-info.txt" 2>&1 || true
  flatpak info --show-permissions --user io.github.jatayuos4u.JatayuMediaPlayer > "$OUT/local-flatpak-permissions.txt" 2>&1 || true
fi
printf '%s\n' "Collected metadata under $OUT" "Inspect files before sharing: system paths or other local details may be included." "This does NOT collect all upstream license texts or clear redistribution."
