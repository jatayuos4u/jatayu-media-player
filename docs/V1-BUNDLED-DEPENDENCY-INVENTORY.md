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

## Authoritative upstream source and license review locations

- mpv: https://github.com/mpv-player/mpv — review COPYING, build features and LGPL/GPL configuration for the exact pinned v0.39.0 build.
- LuaJIT: https://github.com/LuaJIT/LuaJIT — inspect COPYRIGHT and the exact pinned revision.
- libass: https://github.com/libass/libass — inspect COPYING in the pinned 0.16.0 source.
- uchardet: https://gitlab.freedesktop.org/uchardet/uchardet — inspect license notices of pinned v0.0.7 source.
- libplacebo: https://github.com/haasn/libplacebo — inspect COPYING/LICENSE and the exact pinned v7.349.0 tree and project patches.
- Qt/KDE runtime: https://www.qt.io/licensing/ and https://invent.kde.org/packaging/flatpak-kde-runtime — review distributed runtime components and Qt plugin terms.
- FFmpeg: https://ffmpeg.org/legal.html — check actual enabled libraries, nonfree/GPL flags and dependencies; do not assume the runtime's license configuration.

These are pointers for source inspection, **not findings of legal compatibility or proof that corresponding source is bundled**. Archive the relevant notices and source packages before a general public release.

## External licensing research — 17 October 2026 (not binary-specific clearance)

- **mpv v0.39.0:** upstream Copyright describes GPL-2.0-or-later default, with LGPL-2.1-or-later possible if built using `-Dgpl=false` and relevant sources omitted. Current local `flatpak/libmpv.json` passes only `-Dbuild-date=false` and `-Dlibmpv=true`; **it does not explicitly set `-Dgpl=false`**. Treat built libmpv as possibly GPL, subject to actual configuration; inspect linked FFmpeg as well. Upstream: https://github.com/mpv-player/mpv/blob/v0.39.0/Copyright
- **LuaJIT:** upstream COPYRIGHT documents MIT licensing and embedded portions; full notices should accompany redistribution. https://github.com/LuaJIT/LuaJIT/blob/v2.1/COPYRIGHT
- **uchardet:** upstream advertises MPL-1.1, GPL-2.0-or-later, LGPL-2.1-or-later for different contents. Do not label entire build under a single license until exact COPYING and source files inspected. https://gitlab.freedesktop.org/uchardet/uchardet
- **libass / libplacebo / FFmpeg / Qt:** exact pinned file licenses, linked dependency configurations and bundled-runtime boundary remain unverified.

**Important distinction:** public upstream licensing descriptions are informative but do not replace a report of actual binary configuration or complete corresponding-source availability. The application source tarball created from `git archive` is not a source bundle for all external Flatpak modules.
