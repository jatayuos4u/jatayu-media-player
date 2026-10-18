# Jatayu Media Player 1.0.0 — 3-day release gate

**Target:** 19 October 2026. **Decision:** no public beta. Two formats required on release day: Debian amd64 package and Flatpak. A target is not permission to publish an untested artifact.

## Day 1 — October 16
- [ ] Freeze features on feature/playback-v0.3; prioritize release blockers only.
- [ ] Select and build a compatible Flatpak runtime/SDK, with libmpv and codec dependencies isolated in the sandbox.
- [ ] Align Flatpak app ID, desktop file, icon and metadata; test permissions.
- [ ] Keep Debian package functioning unchanged.

## Day 2 — October 17
- [ ] Build Flatpak locally without GitHub Actions storage.
- [ ] Install from Flatpak test repository and test MP3, MP4, subtitle loading, Music Library, playlists, save operations and filesystem access.
- [ ] Build and test final Debian candidate, including command-line and Dolphin opening.
- [ ] Define update channels: signed Debian APT repo (requires hosting/signing) and Flatpak remote (requires hosted OSTree repo). Do not misrepresent a standalone .deb/.flatpak download as automatically updateable.
- [ ] Fix only blockers.

## Day 3 — October 18
- [ ] Run regressions on both installed package types and capture results.
- [ ] Check licenses, FFmpeg/libmpv configuration, redistributable assets and corresponding source.
- [ ] Verify install/removal, desktop identity, permissions, runtime dependencies and clean startup.
- [ ] Record Git commit, package SHA-256 for each final binary and release notes.
- [ ] Decide GO/NO-GO for October 19.

## October 19 — Conditional final release
- [ ] Only tag `v1.0.0` from a verified source commit.
- [ ] Upload validated .deb and .flatpak bundles, checksums, source and legal notices.
- [ ] Document minimum supported platforms and installation/update instructions accurately.
- [ ] If either format fails its release gate, postpone the final release rather than silently shipping an untested 1.0.

## Known blockers at plan creation
- No verified Flatpak build yet; libmpv and codec stack must be built/provided in Flatpak sandbox.
- No verified signed APT repository or Flatpak update remote.
- Full external license review and clean-install matrix incomplete.

No public release or tag should be created solely from this checklist.
