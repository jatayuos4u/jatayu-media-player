# Jatayu Media Player 1.0.0 — publication handoff (18 October 2026)

**Requested release date:** 18 October 2026. **Current status: NOT PUBLISHED / COMPLIANCE SIGN-OFF PENDING.**

The application passed maintainer-reported Debian 13 VM installation and local Debian/Flatpak testing. This handoff does not certify third-party licensing or authorize a release before remaining blockers are closed.

## Exact tested binaries and source provenance

| Asset | SHA256 |
| --- | --- |
| `jatayu-media-player_1.0.0_x86_64.deb` (Debian package version 1.0.0-2) | `0b40619a0ae1268dc18b6f35d961391d0bac8afe7eef47d776f9b51594d7d0dd` |
| `io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak` | `0979e87c1c52b6caa0bdd903c48f03f598dde61deb3220bb91e3dd16db70895c` |
| `jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz` | `cc7efee35ed7f201fc8a0a06a9d29c48cde4dd928617cee818b65f4964d0720f` (maintainer-reported; *not yet independently reviewed*) |

Built application source revision: `cdccb895c3b80f9ecac8827cb115adc43bdaa731`. Later documentation commits are **not** the build revision. The source archive created by `git archive` reflects the build revision; a current documentation snapshot can be separately linked if desired.

## Local files

`dist/release-candidate-1.0.0/` contains tested binaries, `SHA256SUMS`, `SOURCE-COMMIT.txt`, `LICENSE`, release notes draft, application source archive, and locally generated corresponding-source *review* archive. The archive is not yet cleared as complete.

## Outstanding mandatory validation

1. Inspect the entire corresponding-source review archive and verify that every bundled Flatpak binary has corresponding source (including patches and build procedures), and preserve every relevant copyright/license notice.
2. Examine per-file license choices for compiled uchardet and mpv; check linked FFmpeg codecs-extension provenance and mpv GPL build expectations, ensuring distribution claims are accurate.
3. Confirm the application artwork/logo/icon rights for redistribution, including any third-party contributions.
4. Confirm archive signatures, hashes, source offers and both binaries after uploading, before sharing downloads.
5. Approve deployment of `jatayuos4u/jatayuos-website` PR #4 only once authentic release links exist.

## Publication sequence *after clearance*

1. Inspect the staging folder and rerun `(cd dist/release-candidate-1.0.0 && sha256sum -c SHA256SUMS)`.
2. On GitHub, create stable release tag `v1.0.0` **targeting the exact app source commit**, not the later documentation HEAD, unless deliberately generating a separately identified documentation tag.
3. Attach tested `.deb`, `.flatpak`, checksum list, source revision file, corresponding sources/notices and release notes; do not upload a file labelled REVIEW as a final compliant artifact.
4. Verify every downloadable file's SHA256 against the verified source files and check GitHub source-code tag consistency.
5. Add verified URLs to the website draft, then merge/deploy PR #4 with approval.
6. Announce release.

**No tag, GitHub Release, binary uploads, or website deployment were made by this handoff.**
