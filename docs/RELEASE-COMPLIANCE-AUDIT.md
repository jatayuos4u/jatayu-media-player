# Jatayu Media Player 1.0.0 redistribution and clean-install audit

**Preliminary checklist — not a legal opinion or clearance.** Do not publish until evidence is collected and reviewed.

## Application and source
- Application states GPL-3.0-or-later; repository contains GNU GPL v3 text. Verify copyright-holder authorization for any third-party contributions and the intended "or later" designation in source headers/project metadata.
- The Debian package installs the license text in `/usr/share/doc/jatayu-media-player/copyright`; this is a preliminary convenience, **not** a complete Debian DEP-5 copyright inventory.
- Verify copyright ownership and permitted use of icons, branding, artwork, code, and test media. Test clips and music are **not** redistributed in this package.
- Confirm exact source revision used to build and provide the corresponding source code to recipients consistent with GPL obligations.

## Runtime dependencies
- Qt 6: verify licenses/terms for used modules and Qt plugin redistribution where relevant.
- libmpv: verify actual distro build/license configuration; libmpv and FFmpeg-related licenses can vary by build and linked components.
- FFmpeg and external tools: audit installed binaries and usage; dynamically resolved system dependencies are not automatically proof of broad distribution clearance.
- Debian/Ubuntu compatibility is **not** established merely by satisfying APT on one machine; current package depends on recent glibc and Qt.

## Clean installation
Use a disposable Debian 13 VM, live test installation or snapshot. Before install:
```bash
sudo apt-get -s install ./dist/jatayu-media-player_1.0.0_x86_64.deb
dpkg-deb -c dist/jatayu-media-player_1.0.0_x86_64.deb
```
Confirm no unexpected removals. Then:
```bash
sudo apt install ./dist/jatayu-media-player_1.0.0_x86_64.deb
/usr/bin/jatayu-media-player
dpkg -L jatayu-media-player
```
Check launcher icon, desktop-file associations, playback through Browse Media and command-line file path, Preferences, queue, subtitles and audio.

After documenting the results:
```bash
sudo apt remove jatayu-media-player
dpkg -l jatayu-media-player
test ! -e /usr/bin/jatayu-media-player
test ! -e /usr/share/applications/jatayu-media-player.desktop
```
APT remove does not necessarily purge personal settings (QSettings under user home). Do not delete user library, playlists or unrelated files as part of uninstallation verification.

## Packaging and release gate
- [ ] Package includes correct app icon, desktop file, executable and license
- [ ] Installed app starts outside build directory on clean Debian 13
- [ ] `./scripts/run-tests.sh` and manual regression checklist pass
- [ ] Confirm available QML runtime modules, distro runtime dependencies, and app icon/desktop matching
- [ ] Inspect LICENSE, all assets, source history, and all third-party licenses
- [ ] Capture exact final commit SHA and final built-package checksum
- [ ] Verify source release, notices and GPL redistributability
- [ ] No final 1.0.0 release published until sign-off

## Evidence logged on 17 October 2026

- [x] Debian package version `1.0.0-2` and amd64 architecture reported by `dpkg-deb`.
- [x] Debian package checksum verification passed against locally generated `SHA256SUMS`.
- [x] APT `InRelease` metadata signature verified using fingerprint `FCAD173B005222F8DCB16C691002D7BA2CD8EB09`.
- [x] Installed Debian package `1.0.0-2` recognized by `apt-cache policy` from GitHub Pages.
- [x] User confirmed Debian-installed application launches and plays MP3 and MP4 media.
- [x] `sudo dpkg -V jatayu-media-player` returned no differences on user's test machine.
- [x] Flatpak installed through the signed GitHub Pages remote; GPG verification remained enabled.
- [x] Flatpak updated from OSTree commit `50bf6e553b6f1d8f526b7e76a69f843c23f064b4d56fb415d1c1dac148160f12` to `ce739b38472e4abce195c972db2ddee038fef6432ce991e7eddbc8d604be626d`.
- [x] User screenshot shows updated About dialog with creator, license and version 1.0.0.
- [ ] Debian APT upgrade from an older installed revision to a newer one explicitly verified (APT source and installation were verified, but upgrade transaction history was not captured).
- [ ] Independent clean-machine and non-Debian-distribution compatibility verified.
- [ ] Complete review of bundled Flatpak source components, license configurations, branding and corresponding source for GPL obligations.
- [x] Application uninstall and reinstall on the existing Debian 13 test laptop confirmed by maintainer (not an independent clean OS test). Desktop-file association test remains pending.
- [ ] Final release notes and source archive reconciled against the exact published binaries.

- [x] On the existing development laptop, maintainer uninstalled Debian and Flatpak application installations, backed up player settings, confirmed no installed package/executable and no duplicate media-player desktop entries, then reinstalled the Debian package from the signed APT repository and confirmed launch and playback. This is a **fresh-application-state test**, not an independent clean Debian system test.
- [ ] Independently verify a fresh Debian 13 OS installation in a disposable VM or separate computer; verify supported desktop launch associations.
- [ ] Inspect full runtime/bundled-license notices before redistribution.

**Important:** The checks above reflect maintainer-supplied terminal output and screenshots. They are not a substitute for a legal review or reproducible third-party independent testing.

## Additional maintainer report — 17 October 2026

- [x] Maintainer reports successful installation and operation of Jatayu Media Player 1.0.0 from the .deb in a fresh Debian 13 virtual machine.
- [ ] Detailed VM test log, machine specifications, full feature checklist and VM uninstall/reinstall not supplied; these remain unverified.
- [ ] License provenance and complete corresponding-source distribution review remain open, independently of functional testing.
