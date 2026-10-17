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
- [ ] Review security of broad Flatpak home-directory permission and document honestly.

## Only after gates pass
1. Confirm final binaries remain byte-for-byte identical to checked hashes.
2. Approve GitHub normal **v1.0.0** release and attach `.deb`, `.flatpak`, `SHA256SUMS`, `SOURCE-COMMIT.txt`, rights/third-party notices, plus source links.
3. Publish release notes from `docs/V1-RELEASE-NOTES-DRAFT.md` **only after removing draft caveats and verifying claims**.
4. Review `jatayuos4u/jatayuos-website` draft PR #4, insert verified real download URLs, and merge only with approval.
5. Test external URLs, package hashes and installation instructions, and publicly announce through `jatayuos.in`.

No tag, release publication, website merge, or rebuild is authorized by this checklist.
