# Jatayu Media Player 1.0 — updates and publication plan

**Status:** Planning and local packaging only. No signed update service is live.

## Distribution on the first public release
Upload the tested `.deb` and `.flatpak` bundles to an official GitHub **prerelease? No:** create a normal release **only after sign-off**, along with SHA256SUMS, source commit and notices. Do not advertise auto-updates for direct file downloads.

## Debian updates (APT)
For automatic package-manager updates, host an actual Debian repository with signed `InRelease` metadata and a persistent archive signing key.

Proposed distribution endpoint: `https://packages.jatayuos.in` (not configured or verified). Dedicated package name: `jatayu-media-player`; architecture amd64; distro suite e.g. `stable` (do not call this `trixie` unless matching a complete distro release policy).

Use `reprepro`, `aptly` or equivalent to generate indexed metadata and sign releases with a protected GPG key. Use **HTTPS plus signature verification**. Publish the *public* signing key and a fingerprint over the official website. Never ask users to set `trusted=yes` or disable apt-secure verification. Never commit signing keys to GitHub.

After this repository exists and the key is verified, an admin can provide the exact `Signed-By` setup instructions. Before it exists, the downloadable `.deb` receives no automatic upgrades from GitHub Releases alone.

## Flatpak updates
A `.flatpak` bundle is an installable snapshot. Automatic updates need a configured **Flatpak OSTree remote** or Flathub distribution. GitHub Releases hosting only a bundle does not provide a Flatpak update remote.

The local build already creates `dist/flatpak-repo/`. The Flatpak repo can be published by a capable static server (OSTree metadata, large object files, appropriate content types). It needs an accessible `summary` and objects, optional GPG signing for authenticity, `flatpak update` verification from a separate installation, and stable URLs. Proposed endpoint `https://flatpak.jatayuos.in/repo` is **not live**.

An alternative is Flathub, which has its own submission/review process and cannot be guaranteed ready by 19 October.


## Local repository staging commands (not deployment)

Install locally on a disposable development machine:
```bash
sudo apt install reprepro gnupg flatpak ostree
```
Use separate dedicated signing keys where possible; do **not** commit or paste private keys into GitHub or a chat. After producing and testing final packages, set the fingerprint of a *pre-existing* local signing key:
```bash
export APT_SIGNING_FINGERPRINT=YOUR_FULL_SIGNING_KEY_FINGERPRINT
bash scripts/prepare-apt-repository.sh
export FLATPAK_SIGNING_KEY=YOUR_FLATPAK_SIGNING_KEY_FINGERPRINT
bash scripts/prepare-flatpak-repository.sh
```
These commands stage repositories under `dist/apt-repo` and `dist/flatpak-repo`. The first generates signed Debian metadata and a public key export. The second signs the Flatpak repository summary and exports the public key. Both are **unverified until run locally** and perform no hosting or account configuration. Review the contents and publish only with explicit approval.

**Important:** Host names mentioned in this document are illustrative and are not live endpoints. The APT repo requires a stable HTTPS static host that serves the full `dists/` and `pool/` tree. The Flatpak repo must expose the entire OSTree repository with suitable MIME types and HTTPS. Do not provide update installation instructions pointing to URLs until remote installation and the update path have been tested.

## Privacy
No silent download/overwrite of the running executable and no update telemetry. Use APT and Flatpak's signed distribution mechanisms, letting users manage upgrades using their system tools.

## Before saying updates are supported
- [ ] Public endpoint accessible over HTTPS
- [ ] Repository signature / trust key documented and verified
- [ ] Install cleanly from remote (not just the standalone package)
- [ ] Publish a newer version and verify APT/Flatpak actually upgrades
- [ ] Rollback and recovery instructions
- [ ] Test a fresh Debian 13 machine and a second Linux environment
- [ ] Retain corresponding source and license notices for every distributed version

## Three-day fallback
Ship downloadable and independently verifiable packages only **if release gates pass**, and clearly say that automatic updates are not available yet. If user expectations require automatic updates on day one, defer public release until both repositories are operational.
