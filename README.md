# Jatayu Media Player

**Your Media. Your World.**

A privacy-focused, independent media player for Linux, built with C++20, Qt 6/QML and libmpv. This project is a standalone app and is **not** preinstalled in JatayuOS.

> **Status:** 1.0.0 release candidate, undergoing final compliance and clean-install verification. The official GitHub Release has not yet been published.

## Features

- Local audio and video playback, seeking, fullscreen, playback speed, volume and audio-track selection
- External subtitle loading and subtitle controls
- Media Browser with keyboard navigation, scrolling, file multi-selection and queue
- Music Library with Songs, Folders, Artists, Albums and local metadata scanning
- Saved named playlists, automatic queue progression, recent-file history
- Music information and cover-art editing (saves edited media to a new file)
- Resume playback, Media Information, Help/About and Preferences
- No built-in ads, telemetry or account requirement

Support for particular codecs and hardware acceleration varies with system libmpv/FFmpeg and drivers. Additional distributions and hardware remain to be tested.

## Build from source (Debian 13)

```bash
./scripts/setup-linux.sh
./scripts/build-local.sh
./scripts/run-tests.sh
./build/jatayu-media-player /path/to/video.mp4
```

For local Debian release-candidate package generation:

```bash
bash scripts/build-deb-beta.sh
```

The resulting package is in `dist/`. Do not publish it without the final release checks. See the [1.0 release plan](docs/V1-THREE-DAY-RELEASE-PLAN.md), [release verification script](scripts/verify-v1-release-artifacts.sh) and [distribution plan](docs/UPDATE-DISTRIBUTION-V1.md).

## Keyboard controls

| Key | Action |
|---|---|
| Ctrl+O | Browse media |
| Space | Play/Pause |
| Left / Right | Seek 5 seconds |
| Ctrl+Left / Ctrl+Right | Seek 30 seconds |
| Up / Down | Volume |
| F / Escape | Enter / leave fullscreen |
| Ctrl+L | Music Library |
| Ctrl+P | Named playlists |

Further shortcuts are listed within the application under Help.

## Privacy and license

Local files are played without an account. The app includes no advertising or telemetry SDK. Playlists, history, position bookmarks and preferences are stored locally; clear-history controls are available in Preferences. Any network-related behavior of third-party runtime components must be audited before release.

Application source is made available under **GPL-3.0-or-later**; dependencies and bundled resources may have different licenses. Final release approval requires a completed third-party license/provenance review. See [release compliance checklist](docs/RELEASE-COMPLIANCE-AUDIT.md).

## Distribution (release candidate)

The player is not bundled with the JatayuOS ISO. After final release approval, official Debian and Flatpak downloads will appear in [GitHub Releases](https://github.com/jatayuos4u/jatayu-media-player/releases). Do not download purported final binaries from an unverified source.

A signed APT repository and Flatpak OSTree remote are staged at `https://jatayuos4u.github.io/jatayu-packages/`. The Flatpak remote has passed a real signed upgrade test; the Debian package `1.0.0-2` was installed via APT and tested for MP3/MP4 playback on Debian 13. Future APT version-to-version upgrading and broader compatibility still require validation. These services may contain pre-release candidate builds, so installation instructions are withheld until final approval.

**Creator:** Anup Yadav · **Website:** https://jatayuos.in · **Source:** https://github.com/jatayuos4u/jatayu-media-player
