#!/usr/bin/env bash
# Signs Flatpak repo metadata in the local staging directory. Does not upload.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FLATPAK_SIGNING_KEY:?Set FLATPAK_SIGNING_KEY to a locally held GPG key ID or fingerprint}"
for cmd in flatpak gpg ostree; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
REPO="$PWD/dist/flatpak-repo"
[[ -d "$REPO/objects" ]] || { echo "Missing OSTree objects: run the Flatpak build first" >&2; exit 1; }
gpg --batch --with-colons --list-secret-keys "$FLATPAK_SIGNING_KEY" | grep -q "^sec:" || {
  echo "No matching secret GPG key in local keyring" >&2; exit 1;
}
flatpak build-update-repo --gpg-sign="$FLATPAK_SIGNING_KEY" "$REPO"
[[ -s "$REPO/summary" ]] || { echo "Flatpak summary missing" >&2; exit 1; }\n[[ -s "$REPO/summary.sig" ]] || { echo "Flatpak summary signature missing" >&2; exit 1; }
gpg --batch --armor --export "$FLATPAK_SIGNING_KEY" > "$PWD/dist/flatpak-repository-key.asc"
echo "Signed Flatpak repository staged at $REPO (LOCAL ONLY)."
echo "Verify a remote install and a real version-to-version update before publication."
