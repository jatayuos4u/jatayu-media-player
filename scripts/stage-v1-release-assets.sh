#!/usr/bin/env bash
# Collect verified release files locally. NO GitHub upload, tag or publish.
set -euo pipefail
cd "$(dirname "$0")/.."
DEB="dist/jatayu-media-player_1.0.0_x86_64.deb"
FLATPAK="dist/io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak"
EXPECTED_BUILD="cdccb895c3b80f9ecac8827cb115adc43bdaa731"
EXPECTED_DEB="0b40619a0ae1268dc18b6f35d961391d0bac8afe7eef47d776f9b51594d7d0dd"
EXPECTED_FLATPAK="0979e87c1c52b6caa0bdd903c48f03f598dde61deb3220bb91e3dd16db70895c"
for cmd in git sha256sum dpkg-deb tar; do command -v "$cmd" >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }; done
[[ -s "$DEB" && -s "$FLATPAK" ]] || { echo "Missing tested release binaries" >&2; exit 1; }
[[ "$(sha256sum "$DEB" | cut -d' ' -f1)" == "$EXPECTED_DEB" ]] || { echo "Debian binary differs from tested release candidate" >&2; exit 1; }
[[ "$(sha256sum "$FLATPAK" | cut -d' ' -f1)" == "$EXPECTED_FLATPAK" ]] || { echo "Flatpak binary differs from tested release candidate" >&2; exit 1; }
[[ "$(dpkg-deb -f "$DEB" Version)" == "1.0.0-2" ]] || { echo "Incorrect Debian revision" >&2; exit 1; }
git cat-file -e "$EXPECTED_BUILD^{commit}"
mkdir -p dist/release-candidate-1.0.0
OUT="$PWD/dist/release-candidate-1.0.0"
cp "$DEB" "$FLATPAK" "$OUT/"
printf '%s\n' "$EXPECTED_BUILD" > "$OUT/SOURCE-COMMIT.txt"
(cd "$OUT" && sha256sum "$(basename "$DEB")" "$(basename "$FLATPAK")" > SHA256SUMS && sha256sum -c SHA256SUMS)
git archive --format=tar.gz --prefix=jatayu-media-player-1.0.0/ -o "$OUT/jatayu-media-player-1.0.0-source.tar.gz" "$EXPECTED_BUILD"
cp docs/V1-RELEASE-NOTES-DRAFT.md "$OUT/RELEASE-NOTES-DRAFT.md"
cp docs/V1-BUNDLED-DEPENDENCY-INVENTORY.md "$OUT/DEPENDENCY-REVIEW-PENDING.md"
cp LICENSE "$OUT/LICENSE"
echo "Staged local files in $OUT; not published."
echo "NOTICE: Third-party corresponding sources and redistribution audit must be completed before release."
du -sh "$OUT"
