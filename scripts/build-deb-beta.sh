#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for cmd in cmake cpack dpkg-deb sha256sum; do
  command -v "$cmd" >/dev/null || { echo "Missing required tool: $cmd" >&2; exit 1; }
done

echo "Running source smoke checks..."
python3 tests/check_project.py

echo "Building..."
./scripts/build-local.sh

echo "Packaging for local inspection (nothing will be installed)..."
mkdir -p dist
(
  cd build
  cpack -G DEB -B ../dist
)

for pkg in dist/*.deb; do
  test -f "$pkg" || { echo "No .deb generated" >&2; exit 1; }
  echo "=== Package information: $pkg ==="
  dpkg-deb --info "$pkg"
  echo "=== Installed paths (preview) ==="
  dpkg-deb --contents "$pkg"
  sha256sum "$pkg"
done
echo "Beta package created in dist/. Do not publish before clean-machine install tests."
