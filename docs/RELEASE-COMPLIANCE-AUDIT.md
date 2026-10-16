# v0.3.0 Redistribution and clean-install audit

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
sudo apt-get -s install ./dist/jatayu-media-player_0.3.0_x86_64.deb
dpkg-deb -c dist/jatayu-media-player_0.3.0_x86_64.deb
```
Confirm no unexpected removals. Then:
```bash
sudo apt install ./dist/jatayu-media-player_0.3.0_x86_64.deb
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
- [ ] No beta published until sign-off
