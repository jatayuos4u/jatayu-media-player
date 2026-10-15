#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/check_project.py
if [[ -d build ]]; then ctest --test-dir build --output-on-failure; fi
