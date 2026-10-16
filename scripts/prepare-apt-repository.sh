#!/usr/bin/env bash
# Prepare a signed, local APT repository. Does not upload or publish it.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${APT_SIGNING_FINGERPRINT:?Set APT_SIGNING_FINGERPRINT to the full fingerprint of a dedicated, locally held signing key}"
for cmd in reprepro gpg dpkg-deb; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
DEB=dist/jatayu-media-player_1.0.0_x86_64.deb
[[ -s "$DEB" ]] || { echo "Build the 1.0.0 .deb first" >&2; exit 1; }
[[ "$(dpkg-deb -f "$DEB" Package)" == jatayu-media-player ]] || exit 1
[[ "$(dpkg-deb -f "$DEB" Architecture)" == amd64 ]] || exit 1
KEY="$APT_SIGNING_FINGERPRINT"
# Require a usable secret key, but never export it to the repository.
gpg --batch --with-colons --list-secret-keys "$KEY" | grep -q "^sec:" || {
  echo "No matching secret key in local GPG keyring" >&2; exit 1;
}
REPO="$PWD/dist/apt-repo"
mkdir -p "$REPO/conf"
cat > "$REPO/conf/distributions" <<EOF
Origin: Jatayu Media Player Project
Label: Jatayu Media Player
Suite: stable
Codename: stable
Architectures: amd64
Components: main
Description: Jatayu Media Player signed Debian packages
SignWith: $KEY
EOF
reprepro -b "$REPO" includedeb stable "$DEB"
[[ -s "$REPO/dists/stable/InRelease" ]] || { echo "Signed InRelease missing" >&2; exit 1; }
gpg --batch --armor --export "$KEY" > "$REPO/jatayu-media-player-archive-key.asc"
gpg --batch --verify "$REPO/dists/stable/InRelease"\ngpg --show-keys --with-fingerprint "$REPO/jatayu-media-player-archive-key.asc"
echo "Prepared signed APT repository in $REPO (LOCAL ONLY)."
echo "Do not upload until fingerprint, repository layout and installation are verified."
