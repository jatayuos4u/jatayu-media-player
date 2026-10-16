#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for cmd in cmake cpack dpkg-deb sha256sum; do
  command -v "$cmd" >/dev/null || { echo "Missing required tool: $cmd" >&2; exit 1; }
done

echo "Running source smoke checks..."
python3 tests/check_project.py

echo "Building and running available checks..."
./scripts/build-local.sh
./scripts/run-tests.sh

echo "Packaging for local inspection (nothing will be installed)..."
mkdir -p dist
# Remove stale packages so an older build cannot be mistaken for the new beta.
find dist -maxdepth 1 -type f -name 'jatayu-media-player_*.deb' -delete
(
  cd build
  cpack -G DEB -B ../dist
)

shopt -s nullglob
packages=(dist/jatayu-media-player_*.deb)
if (( ${#packages[@]} != 1 )); then
  echo "Expected exactly one fresh Debian package; got ${#packages[@]}" >&2
  exit 1
fi
for pkg in "${packages[@]}"; do
  test -f "$pkg" || { echo "No .deb generated" >&2; exit 1; }
  echo "=== Package information: $pkg ==="
  dpkg-deb --info "$pkg"
  echo "=== Installed paths (preview) ==="
  dpkg-deb --contents "$pkg"
  echo "=== Runtime dependencies ==="
  dpkg-deb -f "$pkg" Depends
  echo "=== SHA-256 ==="
  sha256sum "$pkg"
done
echo "Beta package created in dist/. Do not publish before clean-machine install tests."
