# Jatayu Media Player 1.0.0 — release notes draft

**Status:** Final release candidate. **Not a published release.**
**Requested release date:** 18 October 2026 (advanced from 19 October at maintainer request), pending final compliance clearance and binary asset publication.

## Your Media. Your World.

Jatayu Media Player is a free, open-source music and video player for Linux created by **Anup Yadav**. It provides local playback without advertising, built-in telemetry or mandatory accounts.

### Highlights
- Audio and video playback powered by Qt 6 and libmpv
- Media browser, queues, named playlists, music library and recent files
- Playback speed, audio track selection, volume and fullscreen controls
- Local subtitle loading and subtitle controls
- Music tag and album-cover editing that preserves original files
- Preferences, detailed Help, keyboard shortcuts and troubleshooting
- Independent Linux app; it is **not preinstalled in JatayuOS**

### Packages
- Debian amd64 `.deb`, software version `1.0.0`, Debian revision `1.0.0-3`
- Flatpak bundle `io.github.jatayuos4u.JatayuMediaPlayer`, runtime `org.kde.Platform//6.10`

### Update channels
Both repositories are on GitHub Pages under `https://jatayuos4u.github.io/jatayu-packages/`. Signed Flatpak installation and commit upgrade have been tested over HTTPS. Signed APT package installation and Debian playback were tested; an actual future-version APT upgrade still needs explicit testing. Avoid promising across-distro compatibility until validated.

### Integrity and licensing
Final release assets must include SHA256 checksums and a source commit identifier that correspond to the *same final build*. Project source is GPL-3.0-or-later; bundled third-party components retain their own licenses. Complete compliance review is a release gate.

### Known limitations
- Hardware acceleration and codec support depend on available drivers and the respective dependency stack.
- Maintainer tested corrected Debian package on Debian 13 KDE, Kubuntu and Lubuntu; corrected Flatpak also locally installed and tested.
- Fresh Debian 13 VM installation and operation confirmed by maintainer; other Linux distributions and desktop environments remain unverified.

### Official links
- Website: https://jatayuos.in
- Project: https://github.com/jatayuos4u/jatayu-media-player
- Bugs: https://github.com/jatayuos4u/jatayu-media-player/issues

**Release gate:** Do not publish this draft, tag `v1.0.0` or claim automatic APT upgrades until remaining third-party licensing, corresponding-source review and package publication checks are approved.
