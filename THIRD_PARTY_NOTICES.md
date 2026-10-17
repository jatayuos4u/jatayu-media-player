# Third-party software and redistribution review

Jatayu Media Player's original application source is offered under GPL-3.0-or-later where the copyright holders have authorized that license. The `LICENSE` file contains GPL v3. This document is a **preliminary inventory, not a complete notice bundle or legal clearance**.

## Debian package (system dependencies)

The Debian package dynamically uses system-provided Qt 6, libmpv and FFmpeg-related libraries. The actual library versions and licensing depend on the user's Debian installation and are not included as bundled source in the application-only source archive.

## Flatpak (bundled dependencies)

The Flatpak build manifest `flatpak/libmpv.json` explicitly builds and packages dependencies using these pinned upstream sources:

| Component | Pinned source | Review status |
| --- | --- | --- |
| mpv/libmpv | mpv 0.39.0 | Review actual build options, binary license and linked components |
| LuaJIT | commit `f73e649a954b599fc184726c376476e7a5c439ca` | Record copyright/LICENSE; local Makefile prefix change |
| libass | 0.16.0 | Collect exact COPYING/LICENSE |
| uchardet | 0.0.7 | Collect exact copyright and license |
| libplacebo | v7.349.0 / `1fd3c7bde7b943fe8985c893310b5269a09b46c5` | Collect exact license and source with `libplacebo-vulkan-python-xml.patch` applied |
| KDE/Qt runtime, FFmpeg and codecs | separately supplied runtime and dependencies | Inspect actual runtime contents and applicable notices |

The application source archive contains the manifest and project patch, but **does not contain the complete source of these pinned external projects**. Runtime dependencies are not the same as dependencies bundled in an app's Flatpak deployment.

## Required before official release

1. Obtain actual license and copyright notices from the exact pinned upstream source versions. Preserve notices in a distributable bundle.
2. Archive or provide reliable corresponding-source access for bundled components, preserving local patches and build scripts; check GPL/LGPL obligations for the specific build.
3. Inspect actual Flatpak and libmpv/FFmpeg linkage and feature configuration; confirm no incompatible/nonfree configuration.
4. Validate rights for logos and other bundled assets.
5. Check that public documentation does not promise a complete third-party license review prematurely.

See `docs/V1-BUNDLED-DEPENDENCY-INVENTORY.md` and `docs/RELEASE-COMPLIANCE-AUDIT.md`. This document must be expanded with confirmed source-specific notices prior to general release.
