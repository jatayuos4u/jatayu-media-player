# Jatayu Media Player 1.0.0 — compliance sign-off record

**Status: OPEN — NOT CLEARED FOR PUBLICATION.**
Applies to corrected theme-fixed candidate, Debian revision **1.0.0-3**, application source revision `3d6ba15be78e4555d5f81267c92a21fe62caf702`.

## Confirmed from maintainer test reports

- Debian package checksum: `f6a763dcffac6376b47d8d69eefbfe319c35f91834843612284a1fd0ae6980ee`.
- Flatpak bundle checksum: `42b5139bd5aeb3e6a0096b1d9f60f4233d1be534a5ce8078e36ec6acd142490b`.
- Matching corresponding-source **REVIEW** archive checksum: `020b7acdca7ef58680cf595357020bdd11680b36464e0410b8c83a6e155ddbbf`.
- Source archive structure includes 23 entries. Verification establishes integrity and presence of expected paths, **not substantive completeness**.
- 72/72 scanned uchardet source/header files matched tri-license header patterns. File-level and build-link licensing still merit spot checks.
- mpv 0.39.0 upstream describes GPL-2.0-or-later default; Flatpak manifest does not set `-Dgpl=false`. Treat built binary as GPL for compatibility planning, but effective binary-specific Meson options are unconfirmed.
- libass ISC, LuaJIT MIT, libplacebo root LGPL-2.1 texts identified from pinned material; complete copyright and file-specific license review is outstanding.
- Separate Flatpak runtime/codec extension provides FFmpeg libraries in tested staging environment, rather than packaging FFmpeg in application files.
- Main logo was AI-generated for the project according to maintainer; uniqueness and other included artwork remain unchecked.

## Manual sign-off gates

- [ ] Compare Flatpak app deployment contents against **all** bundled executable/shared libraries, generated artifacts and source origins (including any transitively copied components).
- [ ] Review complete actual pinned-source copyright/license texts, per-file exceptions and local modifications; retain complete upstream notices.
- [ ] Confirm the corresponding-source package includes everything needed to rebuild and modify each GPL/LGPL-governed distributed component, scripts, patches and source links; define source-availability and support plan.
- [ ] Check shipped app icons, fonts, translations and screenshots for third-party restrictions. Independently assess marks if trademark clearance matters.
- [ ] Review the effective mpv build configuration or consciously document GPL-default with no LGPL-only claim. Verify compatibility of the applicable GPL/LGPL/permissive grants for the redistributed combination.
- [ ] Human reviewer records reviewer identity/date, scope, findings and explicit approval after examining the actual archive and binary inventory.

## Approved publication gate

**No-go** until the mandatory checks above have been completed with actual evidence. Project owner must explicitly approve any remaining acceptable risks. These steps do not require rebuilding verified binaries unless an actual defect is found.

## Publication boundary

No version tag, public release, binary upload, website merge or remote package update is authorized by this record.

## Flatpak application-library inventory result — 18 October 2026

- [x] Maintainer executed `scripts/audit-v1-flatpak-bundled-libraries.py` after pulling commit `5856f14`.
- [x] Five pinned upstream source modules reported present: libmpv, LuaJIT, libass, libplacebo, uchardet.
- [x] All 18 enumerated app-deployment library paths (`flatpak-build/files/lib`, including SONAME symlinks and debug companions) matched expected filename prefixes; **0 unmapped**.
- [ ] Important limitation: this is a **filename-based** staging-tree scan, not a cryptographic comparison of the exported Flatpak nor an exhaustive inventory of executable/plugin/data dependencies; source/license completeness and effective build flags are still unverified.

## GitHub release draft verified — 18 October 2026

- [x] GitHub REST API returned release ID `416409763`, `draft=true`, tag_name `v1.0.0`, target_commitish `3d6ba15be78e4555d5f81267c92a21fe62caf702`.
- [x] All nine expected assets are `uploaded` and have GitHub-reported SHA256 digests.
- [x] GitHub digests of Debian (`f6a763dc...`), Flatpak (`42b5139b...`) and corresponding-source REVIEW (`020b7acd...`) match maintainer's staged artifact hashes.
- [ ] **Do not publish** until remaining source/license sign-off. The draft release notes contain a pre-publication warning sentence that must be removed in final published notes.
- [ ] Website PR #4 remains separate/unpublished.

## Follow-up on release publication request — 18 October 2026

- [x] Removed internal draft-only warning from repository file `docs/V1-FINAL-RELEASE-NOTES.md` for use when publication is authorized.
- [ ] The *existing GitHub release draft body* was created before that edit and is **not automatically updated** by repository file changes. Replace release body with the revised notes before publishing.
- [ ] No new direct evidence or qualified review resolving the remaining license/corresponding-source gaps was provided. **Publication sign-off remains open.**
- [ ] Release should not be made public while bundled `corresponding-sources-REVIEW.tar.gz` remains uncertified as complete source. Verify notices and build-license conditions, then owner approves publication.
