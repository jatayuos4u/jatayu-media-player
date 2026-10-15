#!/usr/bin/env bash
set -euo pipefail
if [[ ! -f /etc/debian_version ]]; then echo 'This setup script supports Debian/Ubuntu family only. See docs/BUILD.md for other distributions.'; exit 1; fi
sudo apt update
sudo apt install --no-install-recommends -y build-essential cmake ninja-build pkg-config qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-dialogs qml6-module-qtquick-window libmpv-dev libgl-dev
