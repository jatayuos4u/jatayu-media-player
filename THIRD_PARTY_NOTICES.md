# Third-party software notices and source availability — Jatayu Media Player 1.0.0

**Release candidate:** corrected 18 October 2026 build; this is a factual inventory, **not final legal clearance**.

Jatayu Media Player's original application source is licensed GPL-3.0-or-later, subject to the rights of relevant contributors. Third-party components retain their own copyright and license terms. Complete original license texts from pinned source versions have been collected into the separately prepared `jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz`. **Do not substitute this summary for their full notices.**

## Debian package

The Debian 1.0.0-3 package dynamically links to the operating system's Qt, libmpv and media-stack packages. They are separate system packages and should not be described as embedded in the small `.deb`.

## Application-bundled Flatpak sources

| Component | Exact pinned source | Evidenced license/conditions |
| --- | --- | --- |
| mpv/libmpv | 0.39.0, SHA256 pinned in `flatpak/libmpv.json` | Upstream Copyright: GPL-2.0-or-later default; LGPL-2.1-or-later is conditional on `-Dgpl=false`. Manifest does *not* specify `-Dgpl=false`; do not claim LGPL-only. Full exact-source Copyright and GPL/LGPL texts retained. |
| LuaJIT | `f73e649a954b599fc184726c376476e7a5c439ca` | MIT, with embedded Lua and further full COPYRIGHT notices. Manifest changes Makefile install prefix using `sed`. |
| libass | 0.16.0 | ISC copyright/attribution text in exact-source COPYING; preserve intact. |
| uchardet | 0.0.7 | Source headers provide MPL-1.1 / GPL-2.0-or-later / LGPL-2.1-or-later alternatives. Maintainer's scanner recognized these alternatives in 72/72 examined source/header files. This does not establish licensing of non-source assets. |
| libplacebo | `1fd3c7bde7b943fe8985c893310b5269a09b46c5` / v7.349.0 | Root LICENSE includes LGPL-2.1 license text. Additional per-file terms/exceptions require examination; demo license is CC0. Keep the supplied project patch. |

Sources: `flatpak/libmpv.json`, upstream archives at exact manifest hashes/revisions, and `docs/V1-BUNDLED-DEPENDENCY-INVENTORY.md`.

The application uses a separately installed `org.kde.Platform//6.10` runtime and codec extensions. In maintainer Flatpak staging tests, FFmpeg libraries resolved through the `codecs-extra` runtime extension (not files in the app staging tree). Distributors of these separate runtimes remain responsible for their own packages; this distinction does **not** eliminate obligations resulting from the player's dynamically linked libraries.

## Corresponding source and build inputs

The candidate review archive includes the application source snapshot, exact pinned upstream archives/commit exports, the original Flatpak manifests, project patches, source inventory and extracted full third-party license texts. The verified staged archive's digest is recorded separately in `dist/release-candidate-1.0.0-theme-fixed/SOURCE-REVIEW-SHA256SUMS`. Re-run the staging process whenever this notices file changes, because the archive embeds a copy of it. The previous archive SHA256 `cd9aaca96d5d1af7aeb4cfcd4430ee35981dd282ca67d9e70865019bcf51c180` describes the version **before this notice update** and must not be reused after regeneration.

The review archive is **not yet verified to be complete corresponding source for every binary component**; do not change its `REVIEW` label or advertise complete legal clearance until an appropriately qualified reviewer assesses the complete bundle.

## App permission disclosure

The Flatpak manifest requests `--filesystem=home`, `--filesystem=/media` and `--filesystem=/run/media` to browse and play users' local media. These are broad local filesystem permissions. The app does not include built-in telemetry or advertisements.

## Branding origin

The maintainer reports that the player logo/icon were AI-generated specifically for the project. No separately commissioned designer or external stock icon source was identified. This is **not** a trademark or similarity clearance for the mark, nor proof of rights for every other distributed asset.

## Open review items

1. Verify all compiled/embedded files' licensing, exceptions and copyright obligations against the delivered binary and full exact-source notices.
2. Confirm mpv effective build options and any license-relevant compile features or formally document the GPL-default inference.
3. Review full corresponding-source assembly, any embedded generated inputs, scripts and modifications.
4. Approve logo/icon and all other redistributed assets, and obtain maintainer redistribution sign-off.

Until closed, use `docs/V1-FINAL-PUBLICATION-CHECKLIST.md` and `docs/V1-PUBLICATION-HANDOFF-2026-10-18.md` to track publication readiness.
