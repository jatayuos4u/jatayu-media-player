# Jatayu Media Player

**Your Media. Your World.**

Jatayu Media Player is a free and open-source Linux music and video player built using C++20, Qt 6/QML and libmpv. It is an independent application, **not bundled with the JatayuOS ISO**.

## Version 1.0.0 — Released 18 October 2026

[**Download the official 1.0.0 release**](https://github.com/jatayuos4u/jatayu-media-player/releases/tag/v1.0.0) · [Jatayu Media Player website](https://jatayuos.in/apps/media-player/) · [Report an issue](https://github.com/jatayuos4u/jatayu-media-player/issues)

### Features

- Playback of common audio and video formats through libmpv
- Local media browser, queue, named playlists and music library
- Subtitles, audio-track selection, playback speed and fullscreen
- Media metadata, song information and music-mode interface
- Preferences, keyboard shortcuts, Help and troubleshooting
- No advertisements, built-in telemetry or required account

Support for particular formats and hardware acceleration varies with the installed codec, runtime and driver stack.

## Install

Choose the official download for your Linux setup:

- [**Debian-compatible amd64 package (.deb)**](https://github.com/jatayuos4u/jatayu-media-player/releases/download/v1.0.0/jatayu-media-player_1.0.0_x86_64.deb) — Debian package revision 1.0.0-3.
- [**Flatpak bundle (.flatpak)**](https://github.com/jatayuos4u/jatayu-media-player/releases/download/v1.0.0/io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak) — KDE Platform 6.10 runtime.
- [**SHA256 checksums**](https://github.com/jatayuos4u/jatayu-media-player/releases/download/v1.0.0/SHA256SUMS).

For a downloaded Debian package:

```bash
sudo apt install ./jatayu-media-player_1.0.0_x86_64.deb
```

For a downloaded Flatpak bundle:

```bash
flatpak install --user ./io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak
```

Downloading a standalone package does not automatically configure the project's update repository.

## Screenshots

Real application screenshots are available on the [website](https://jatayuos.in/apps/media-player/#screenshots). The website includes home, music, video playback and About screens.

## Build from source

See [docs/BUILD.md](docs/BUILD.md), the [release's matching source snapshot](https://github.com/jatayuos4u/jatayu-media-player/releases/tag/v1.0.0), and the Flatpak build manifests for development requirements. The tested version 1.0.0 was built from commit `3d6ba15be78e4555d5f81267c92a21fe62caf702`.

## Privacy and permissions

The player has no built-in advertising or telemetry and does not require an account for local playback. Its Flatpak requests access to home and removable-media directories so users can browse local media.

## Licensing and source notices

The original application code is licensed **GPL-3.0-or-later**. Third-party components retain their respective licenses. See [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and the upstream source-review materials attached to the release. Corresponding-source and third-party compliance review limitations are documented in the project; publication alone does not establish independent legal certification.

Created by **Anup Yadav**. [Project website](https://jatayuos.in/apps/media-player/).
