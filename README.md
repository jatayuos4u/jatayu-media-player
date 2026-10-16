# Jatayu Media Player

**Every Beat. Every Frame.**

A privacy-focused, independent media player for Linux, built with C++20, Qt 6/QML and libmpv. This project is a standalone app and is **not** preinstalled in JatayuOS.

> **Status:** v0.3.0 development / beta candidate testing. Not a stable release or a published beta.

## Features in the development build

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

For experimental local Debian package generation:

```bash
bash scripts/build-deb-beta.sh
```

The resulting package is in `dist/`. It has **not** been certified for general distribution. See [beta packaging and performance guide](docs/BETA-PACKAGING-AND-PERFORMANCE.md), [manual regression checklist](docs/BETA-REGRESSION-CHECKLIST.md) and [draft release notes](docs/BETA-RELEASE-NOTES-DRAFT.md).

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

Application source is made available under **GPL-3.0-or-later**; dependencies and bundled resources may have different licenses. Publication is blocked pending a complete third-party license/provenance review. See [release compliance checklist](docs/RELEASE-COMPLIANCE-AUDIT.md).
