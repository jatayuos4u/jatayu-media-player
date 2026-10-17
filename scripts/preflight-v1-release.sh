#!/usr/bin/env bash
# Read-only preflight for the 1.0 release candidate; does not install or publish.
set -euo pipefail
cd "$(dirname "$0")/.."
APP_ID=io.github.jatayuos4u.JatayuMediaPlayer
DEB=dist/jatayu-media-player_1.0.0_x86_64.deb
FLATPAK=dist/${APP_ID}-1.0.0-x86_64.flatpak
for tool in git dpkg-deb apt-cache sha256sum flatpak ostree gpg; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done
echo '== Source revision =='
git rev-parse HEAD
git status --short
echo '== Package metadata =='
[[ -s "$DEB" && -s "$FLATPAK" ]] || { echo 'Release artifacts missing' >&2; exit 1; }
dpkg-deb -f "$DEB" Package Version Architecture Depends
echo '== Local checksums =='
sha256sum "$DEB" "$FLATPAK"
if [[ -f dist/SHA256SUMS ]]; then (cd dist && sha256sum -c SHA256SUMS); fi
echo '== APT installed and candidate =='
apt-cache policy jatayu-media-player
echo '== Flatpak public remote =='
flatpak --installation=jatayu-test remote-info --show-commit jatayu-official "$APP_ID" || echo 'Flatpak test remote unavailable'
echo '== Locally staged OSTree commit signature =='
commit=$(ostree --repo=dist/flatpak-repo rev-parse "app/$APP_ID/x86_64/master")
echo "$commit"
ostree --repo=dist/flatpak-repo show --print-detached-metadata-key=ostree.gpgsigs "$commit" >/dev/null
echo 'OSTree commit signature metadata present'
echo '== License files in Debian package =='
dpkg-deb -c "$DEB" | grep -E '/share/doc/.*/copyright|/share/licenses/' || true
echo '== APT upgrade simulation (no changes) =='
apt-get -s install jatayu-media-player
echo '== Completed read-only checks. Independent clean install and licensing audit still required. =='
