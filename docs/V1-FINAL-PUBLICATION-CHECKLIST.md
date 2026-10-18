# Jatayu Media Player 1.0.0 — final publication checklist

Status: **Prepared, not approved for publication**. Target 19 October 2026.

## Immutable tested build
- Built from source commit: `cdccb895c3b80f9ecac8827cb115adc43bdaa731` (as recorded by local build verification).
- Source repository documentation has advanced after the build; this must not be misrepresented as binary build provenance.
- Debian package: `jatayu-media-player_1.0.0_x86_64.deb`; internal version `1.0.0-2`; SHA256 `0b40619a0ae1268dc18b6f35d961391d0bac8afe7eef47d776f9b51594d7d0dd`.
- Flatpak bundle: `io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak`; SHA256 `0979e87c1c52b6caa0bdd903c48f03f598dde61deb3220bb91e3dd16db70895c`.
- Signed Flatpak repo commit: `ce739b38472e4abce195c972db2ddee038fef6432ce991e7eddbc8d604be626d`.
- Signing key fingerprint: `FCAD173B005222F8DCB16C691002D7BA2CD8EB09` (**PUBLIC fingerprint, never publish private key**).

These hashes were reported by maintainer after local verification. Recheck exactly against GitHub Release uploads when published.

## Tested and reported
- [x] Debian laptop installation, MP3/MP4 playback, remove and reinstall.
- [x] Debian 13 VM fresh install and working app **reported by maintainer**, detailed log not provided.
- [x] Signed Flatpak installation and update from older commit over HTTPS.
- [x] GPG metadata and package-file checksums checked locally.
- [x] App/About interface version and creator checked in screenshots.

## Release blockers
- [ ] **Third-party license and source audit:** collect licenses, configuration and corresponding sources (see `docs/V1-BUNDLED-DEPENDENCY-INVENTORY.md`). Validate Qt, mpv, FFmpeg, LuaJIT, libass, libplacebo, uchardet and any bundled assets/patches.
- [ ] Confirm original graphics, README attribution and rights for all distributed files.
- [ ] Review and approve source availability, release notes and optional complete notices bundle.
- [ ] Confirm user-side VM removal/desktop associations if those are release requirements.
- [x] Reviewed and documented broad Flatpak home-directory permission in dependency inventory; `--filesystem=home`, `/media`, and `/run/media` give extensive local file access required for media browsing. Narrowing would change tested release behavior; consider separate post-release permissions design after testing.

## Prepared assets and website review

- [x] Offline final-assets staging script added at `scripts/stage-v1-release-assets.sh`. It enforces both tested binary hashes, retains source-build commit `cdccb895...`, generates a source archive and places draft notices in `dist/release-candidate-1.0.0/`. **Not yet executed on maintainer's machine.**
- [x] Website content including installation guidance prepared in draft `jatayuos4u/jatayuos-website` PR #4. **Not merged and not live.**
- [x] Maintainer executed local staging and confirmed both binaries pass `sha256sum -c SHA256SUMS`; source archive and SOURCE-COMMIT.txt present (17 October 2026).
- [ ] Inspect application source archive contents and verify complete third-party corresponding-source availability; test hashes again after final upload.
- [ ] Test a clean build of the website preview and approve the site changes.
- [ ] Obtain documented third-party license and corresponding-source evidence. This cannot be certified from manifest names alone.

## Only after gates pass
1. Confirm final binaries remain byte-for-byte identical to checked hashes.
2. Approve GitHub normal **v1.0.0** release and attach `.deb`, `.flatpak`, `SHA256SUMS`, `SOURCE-COMMIT.txt`, rights/third-party notices, plus source links.
3. Publish release notes from `docs/V1-RELEASE-NOTES-DRAFT.md` **only after removing draft caveats and verifying claims**.
4. Review `jatayuos4u/jatayuos-website` draft PR #4, insert verified real download URLs, and merge only with approval.
5. Test external URLs, package hashes and installation instructions, and publicly announce through `jatayuos.in`.

No tag, release publication, website merge, or rebuild is authorized by this checklist.

## Local staging output received (17 October 2026)

- Local folder `dist/release-candidate-1.0.0/`: Debian binary (~205 KB), Flatpak bundle (~2.1 MB), application source archive (~58 KB), LICENSE, notes, SHA256SUMS, SOURCE-COMMIT.txt.
- SOURCE-COMMIT: `cdccb895c3b80f9ecac8827cb115adc43bdaa731`.
- `sha256sum -c SHA256SUMS` reported `OK` for both release binary files.
- Evidence folder `dist/v1-compliance-evidence/` generated; its local Flatpak info/permissions files are 88 bytes and require inspection (may be error output, **not** confirmed Flatpak installed metadata).
- Third-party license and complete corresponding-source obligations **remain unverified**. No publication authorized.

## Upstream source collection prepared — 17 October 2026

- [x] `scripts/collect-v1-upstream-sources.py` added for locally fetching pinned Flatpak libmpv dependency sources and project patches with commit/SHA256 verification. It **has not yet been run**; downloading may use substantial disk space and network traffic. It does not rebuild or publish binaries.
- [x] Maintainer ran `python3 scripts/collect-v1-upstream-sources.py` successfully on 17 October 2026. Script completed fetching pinned mpv, LuaJIT, libass, uchardet, and libplacebo sources and recorded their hashes/revisions locally (based on reported terminal output).
- [ ] Extract and inspect exact `COPYING`/`LICENSE`/`Copyright` files and check patched build configuration from locally downloaded sources.
- [ ] Evaluate mpv GPL mode (manifest does not pass `-Dgpl=false`), linked FFmpeg license/build options, possible runtime dependencies, and license compatibility before external distribution.
- [ ] Review complete corresponding-source and attribution bundle; no legal clearance implied by this script.

## Pinned upstream collection evidence (17 October 2026)

Maintainer terminal output reports successful collection of mpv v0.39.0, LuaJIT `f73e649a...`, libass 0.16.0, uchardet 0.0.7 and libplacebo `1fd3c7bd...`, including scripts' built-in SHA256 and pinned git revision checks. No licensing conclusion follows from downloading or verifying source files. Review exact source notices and any extra transitive dependencies before clearing the release.

## Exact upstream license file inventory — maintainer report 17 October 2026

- [x] Maintainer ran `scripts/inventory-v1-upstream-licenses.py` successfully; **11 file occurrences** identified (some repeated between source archives and checked-out trees), including mpv `Copyright`, `LICENSE.GPL`, `LICENSE.LGPL`; LuaJIT `COPYRIGHT`; libass `COPYING`; uchardet `COPYING`; libplacebo `LICENSE` and `demos/LICENSE`.
- [x] Added `scripts/extract-v1-upstream-licenses.py`; maintainer ran it successfully on 17 October 2026 and reported 11 license/notice file occurrences extracted to `dist/v1-upstream-source-review/license-review/`.
- [ ] Read actual license text, inspect files with nonstandard names, establish licensing and attribution of each built component, confirm binary-specific build configuration, and assess corresponding sources and patches.

## Licensing source-package work — 17 October 2026

- [x] Confirmed via maintainer ELF resolution that libmpv links FFmpeg libraries from separately mounted `codecs-extra` rather than from the application tree. Runtime licensing still applies to runtime distributor; avoid claiming bundled FFmpeg.
- [x] Confirmed uchardet main source `uchardet.cpp` explicitly allows GPL-2.0-or-later or LGPL-2.1-or-later as alternatives to MPL-1.1. Other compiled files still require review.
- [x] Created `scripts/package-v1-corresponding-sources.py` to assemble verified pinned sources, full extracted license texts, manifests, patches and application source into an **offline review archive**. Script has not yet run on maintainer's machine.
- [x] Maintainer executed corresponding-source review bundler successfully: archive generated with 23 top-level entries, reported SHA256 `cc7efee35ed7f201fc8a0a06a9d29c48cde4dd928617cee818b65f4964d0720f`.
- [ ] Inspect generated archive contents and nested sources, confirm all actual bundled code and notices are covered; generation success alone is not legal completeness.
- [x] Maintainer reports the Jatayu Media Player logo/icon was generated specifically for the project using ChatGPT image generation. No external commissioned designer or stock asset was identified for that logo/icon; record as AI-assisted original project branding, **not a guarantee of uniqueness, trademark clearance, or rights for every other included asset**.
- [ ] Check logo/icon distinctiveness against existing marks if intending trademark use; review any additional bundled artwork and third-party source assets.
- [ ] Maintainer sign-off on compliance before public release.

## Corresponding-source archive collection report (17 October 2026)

- File: `dist/release-candidate-1.0.0/jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz` (local; not published).
- Maintainer-provided SHA256: `cc7efee35ed7f201fc8a0a06a9d29c48cde4dd928617cee818b65f4964d0720f`.
- Packaging script reported 23 top-level source, manifest, patch and notice entries; nested upstream tarballs contain more files. No archive inspection or independent checksum verification has occurred in this assistant session.
- Keep the `-REVIEW` suffix until component and transitive-dependency source compliance is verified and release owner signs off.

## Maintainer source review scanner result — 18 October 2026

- [x] `scripts/audit-v1-source-review.py` ran successfully on maintainer system: 72 uchardet source/header files examined, 72 matched explicit tri-license patterns, zero unclassified by scanner. This is pattern recognition, **not** an exhaustive build-unit/license legal audit.
- [x] Corresponding-source REVIEW archive structural check passed, 23 file entries, reported SHA256 `cc7efee35ed7f201fc8a0a06a9d29c48cde4dd928617cee818b65f4964d0720f`, matching previously reported digest.
- [ ] Verify source archives/build configuration fully correspond to shipped binaries, third-party notices and asset rights; retain REVIEW status pending sign-off.

## Cross-distribution UI theme test build — 18 October 2026

- [x] Maintainer rebuilt the application after the Qt Quick dialog palette/background fix. CPack generated `dist/theme-fix-test/jatayu-media-player_1.0.0_x86_64.deb` successfully.
- [x] Package metadata reports Debian revision `1.0.0-3` (prior tested candidate was `1.0.0-2`).
- [x] Maintainer-reported SHA256: `c48d11ddbec8fd072aca86930b7353af7f1cf99d4fca523088181e173c339d74`.
- [ ] Install new package in the affected test distro and check About, Troubleshooting, Queue, Media Browser and other dialogs for contrast; test basic playback.
- [ ] If accepted, rebuild/retest Flatpak with same UI fix, update release package hashes, source build commit and corresponding-source archive. **Do not publish the earlier packages as if they contain this fix.**

## Revised dialog-heading test package — 18 October 2026

- [x] Maintainer compiled QML title-header fix at commit `3d6ba15be78e4555d5f81267c92a21fe62caf702`, linked executable successfully, and generated updated Debian package `dist/theme-fix-test/jatayu-media-player_1.0.0_x86_64.deb` (package revision 1.0.0-3).
- [x] Maintainer-reported SHA256 of newly regenerated test package: `f6a763dcffac6376b47d8d69eefbfe319c35f91834843612284a1fd0ae6980ee`. This supersedes earlier **test** hash `c48d11dd...`, not the older release candidate's separate hash.
- [ ] Install this exact package on affected VM and confirm title contrast, media browsing, and audio/video playback.
- [ ] Rebuild and retest Flatpak from matching source revision before publishing corrected 1.0.0 artifacts.
