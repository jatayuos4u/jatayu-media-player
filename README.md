# Jatayu Media Player

**Every Beat. Every Frame.**

Early development proof of concept for an independent Linux media player, built using C++20, Qt 6/QML and libmpv. Not yet a stable release, not preinstalled in JatayuOS.

## Current prototype

- Playback of locally selected media through libmpv
- Qt Quick video render surface using the OpenGL-based libmpv render API
- Play/pause, stop, relative seeking, timeline, volume, fullscreen
- External subtitle loading, keyboard shortcuts, opening a file via Ctrl+O
- Dark interface; no advertisement, analytics or telemetry dependencies

**Not yet implemented:** playlists, media library, MPRIS, persistence, comprehensive settings, light theme, localization, portable packages, and the full tested codec/support matrix. Real playback has not yet been verified on hardware.

## Build locally (Debian 13 / Ubuntu derivatives)

```bash
./scripts/setup-linux.sh
./scripts/build-local.sh
./build/jatayu-media-player ~/Videos/sample.mp4
```

Read [docs/BUILD.md](docs/BUILD.md) for environment requirements and diagnostics. The source archive is not a precompiled player. There are no GitHub Actions workflows or artifact uploads.

## Keyboard controls

| Key | Action |
|---|---|
| Ctrl+O | Open media |
| Space | Play / pause |
| Left / Right | Seek back / forward 5 seconds |
| F | Fullscreen toggle |
| Escape | Exit fullscreen |

## Privacy and licensing

Playback of local files does not require an account. The app contains no tracking SDKs or advertising code. libmpv and its dependencies may have their own behaviour; network traffic still needs verification in testing. Source code is provided under GPL-3.0-or-later, with third-party dependencies governed by their respective licenses. Complete redistribution compliance remains a release gate.
