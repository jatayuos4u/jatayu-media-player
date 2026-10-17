# Flatpak bundled-source inventory — Jatayu Media Player 1.0.0

**Status:** Source manifest reviewed; full license-file and build-option audit **not yet complete**. This inventory is not a legal opinion or release approval.

The Flatpak manifest `flatpak/io.github.jatayuos4u.JatayuMediaPlayer.json` includes `flatpak/libmpv.json`; the following source modules are built as part of the libmpv dependency tree, in addition to the Jatayu player source.

| Bundled component | Manifest source/version | Outstanding license/provenance evidence |
| --- | --- | --- |
| mpv / libmpv | mpv v0.39.0 archive, hash pinned | Inspect project license and linked LGPL/GPL build configuration, FFmpeg dependency and generated binaries |
| LuaJIT | git revision `f73e649a954b599fc184726c376476e7a5c439ca` | Review license, notices and modifications (Makefile path patch) |
| libass | v0.16.0 archive, hash pinned | Review license and dynamic/runtime attribution |
| uchardet | v0.0.7 archive, hash pinned | Review library and bundled source licensing |
| libplacebo | v7.349.0, git revision `1fd3c7bde7b943fe8985c893310b5269a09b46c5` | Review license and local Vulkan/Python XML patch |
| Jatayu Media Player | local directory `..\` at build time | Confirm exact release commit, assets and GPL-3.0-or-later rights |
| KDE Platform | org.kde.Platform//6.10 runtime | Runtime is distributed separately; cite KDE/Qt license resources and check plugin licensing |

## Release-owner action required

1. Collect the LICENSE/COPYING files, attribution and source URLs for each component from the **exact pinned sources**. Avoid inferring permissibility solely from a project's name.
2. Review actual linked libraries and configured license options using Flatpak runtime inspection and build logs; the mpv/FFmpeg dependency situation may differ between Debian and Flatpak.
3. Retain corresponding source (including patches) for source-offer and GPL compliance.
4. Verify application icon/graphics are original or redistributable, and music/video test samples are not packaged.
5. Review distro-specific app integration and `--filesystem=home` permission; this is broad user-home access, so describe it accurately in release notes.
6. Obtain explicit maintainer sign-off; keep this audit open until documentary evidence is collected.

## Observed tests, separate from license clearance

Maintainer demonstrated signed Flatpak installation from GitHub Pages and update to commit `ce739b38472e4abce195c972db2ddee038fef6432ce991e7eddbc8d604be626d`. Debian `1.0.0-2` installed through GitHub Pages and played MP3/MP4. These tests establish functionality, not redistribution clearance.
