#!/usr/bin/env bash
# Publish the already-tested theme-fixed release from the maintainer's laptop.
# Requires: gh CLI authenticated with repo release write access.
# Requires explicit CREATE_DRAFT=YES; this does not authorize public release.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "${RUN_RELEASE:-}" == YES ]] || { echo "STOP: set RUN_RELEASE=YES only after final compliance sign-off." >&2; exit 2; }
command -v gh >/dev/null || { echo "Install/authenticate GitHub CLI (gh)" >&2; exit 2; }
command -v sha256sum >/dev/null
STAGE="dist/release-candidate-1.0.0-theme-fixed"
[[ -d "$STAGE" ]] || { echo "Missing stage folder" >&2; exit 2; }
python3 scripts/check-v1-publish-assets.py
SOURCE="3d6ba15be78e4555d5f81267c92a21fe62caf702"
[[ "$(cat "$STAGE/SOURCE-COMMIT.txt")" == "$SOURCE" ]] || exit 2
git cat-file -e "$SOURCE^{commit}"
if gh release view v1.0.0 --repo jatayuos4u/jatayu-media-player >/dev/null 2>&1; then
  echo "STOP: tag/release v1.0.0 already exists; do not overwrite" >&2
  exit 2
fi
[[ "${COMPLIANCE_SIGNED_OFF:-}" == YES ]] || {
  echo "STOP: compliance approval not provided; record qualified review before publishing." >&2; exit 2;
}
echo "Creating release v1.0.0 targeting tested source revision: $SOURCE"
gh release create v1.0.0 \
  "$STAGE/jatayu-media-player_1.0.0_x86_64.deb" \
  "$STAGE/io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak" \
  "$STAGE/SHA256SUMS" \
  "$STAGE/SOURCE-COMMIT.txt" \
  "$STAGE/jatayu-media-player-1.0.0-source.tar.gz" \
  "$STAGE/LICENSE" \
  "$STAGE/THIRD_PARTY_NOTICES.md" \
  "$STAGE/jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz" \
  "$STAGE/SOURCE-REVIEW-SHA256SUMS" \
  --repo jatayuos4u/jatayu-media-player \
  --target "$SOURCE" \
  --title "Jatayu Media Player 1.0.0" \
  --notes-file docs/V1-FINAL-RELEASE-NOTES.md \
  --draft
echo "DRAFT created. Confirm asset checksums and third-party compliance BEFORE publishing the draft."
echo "Corresponding-source archive remains REVIEW; do not present it as legally complete without substantive clearance."
