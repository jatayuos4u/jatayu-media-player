#!/usr/bin/env bash
# Stage the tested fixed-theme 1.0.0-3 .deb and Flatpak WITHOUT publishing.
set -euo pipefail
cd "$(dirname "$0")/.."
DEB="dist/theme-fix-test/jatayu-media-player_1.0.0_x86_64.deb"
FLATPAK="dist/theme-fix-test/io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak"
OUT="$PWD/dist/release-candidate-1.0.0-theme-fixed"
DEB_SHA="f6a763dcffac6376b47d8d69eefbfe319c35f91834843612284a1fd0ae6980ee"
FLATPAK_SHA="42b5139bd5aeb3e6a0096b1d9f60f4233d1be534a5ce8078e36ec6acd142490b"
for tool in git sha256sum dpkg-deb python3 tar; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }; done
[[ -s "$DEB" && -s "$FLATPAK" ]] || { echo "Missing tested fixed-theme binaries" >&2; exit 1; }
[[ "$(sha256sum "$DEB" | cut -d' ' -f1)" == "$DEB_SHA" ]] || { echo "DEB SHA256 does not match tested candidate" >&2; exit 1; }
[[ "$(sha256sum "$FLATPAK" | cut -d' ' -f1)" == "$FLATPAK_SHA" ]] || { echo "Flatpak SHA256 does not match tested candidate" >&2; exit 1; }
[[ "$(dpkg-deb -f "$DEB" Version)" == "1.0.0-3" ]] || { echo "Expected Debian revision 1.0.0-3" >&2; exit 1; }
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "Tracked source changes are uncommitted. Commit/review them before staging." >&2
  exit 1
fi
# Application sources are required to contain both the theme fix and the tested DEB packaging revision.
git show HEAD:qml/Main.qml | grep -Fq 'Explicit title color: some Qt themes' || { echo "Missing dialog title fix" >&2; exit 1; }
git show HEAD:CMakeLists.txt | grep -Fq 'set(CPACK_DEBIAN_PACKAGE_RELEASE "3")' || { echo "Missing 1.0.0-3 package revision" >&2; exit 1; }
mkdir -p "$OUT"
cp "$DEB" "$FLATPAK" "$OUT/"
git rev-parse HEAD > "$OUT/SOURCE-COMMIT.txt"
git archive --format=tar.gz --prefix=jatayu-media-player-1.0.0/ -o "$OUT/jatayu-media-player-1.0.0-source.tar.gz" HEAD
cp LICENSE THIRD_PARTY_NOTICES.md docs/V1-RELEASE-NOTES-DRAFT.md "$OUT/"
(cd "$OUT" && sha256sum "$(basename "$DEB")" "$(basename "$FLATPAK")" jatayu-media-player-1.0.0-source.tar.gz LICENSE THIRD_PARTY_NOTICES.md > SHA256SUMS && sha256sum -c SHA256SUMS)
JATAYU_RELEASE_REVIEW_DIR="$OUT" python3 scripts/package-v1-corresponding-sources.py
(cd "$OUT" && sha256sum jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz > SOURCE-REVIEW-SHA256SUMS && sha256sum -c SOURCE-REVIEW-SHA256SUMS)
cat <<EOF
Release candidate locally staged: $OUT
Source revision: $(cat "$OUT/SOURCE-COMMIT.txt")
DO NOT publish yet: third-party corresponding-source bundle remains REVIEW, not legally signed off.
Updated binaries are test candidates; do not use old release checksums/commit.
EOF
