# Jatayu Media Player v0.3.0 — beta release candidate notes (DRAFT)

**Status: not released.** For development testing on Debian 13 (amd64) only. Do not publish until test and legal gates are signed off.

## Highlights
- Local video and audio playback powered by Qt 6 and libmpv
- Fullscreen, playback-speed and audio-track selection, seeking and resume
- Subtitle loading and appearance adjustments
- Music library with Songs, Folders, Artists, and Albums browsing
- Persistent named playlists, queue and multi-file selection
- Music tags/artwork editing saved to a new media file
- Help/About, Media Information and Preferences
- No embedded ads or tracking SDKs

## Known limitations
- Only the Debian 13/JatayuOS test environment has been exercised extensively.
- Flatpak, cross-distro compatibility, MPRIS and user-defined shortcut editing are not complete.
- High-quality GPU scaling is deliberately disabled pending further graphics testing.
- Test coverage includes source smoke checks; extensive automated playback tests do not yet exist.
- Container/codec support depends on the system libmpv/FFmpeg build.
- Package compatibility and licensing review remain release gates.

## Draft installation procedure
After verifying provenance and SHA-256, inspect dependencies:
```bash
sudo apt-get -s install ./jatayu-media-player_0.3.0_x86_64.deb
```
If no unexpected removals/upgrades are proposed, install **only in a disposable test environment**:
```bash
sudo apt install ./jatayu-media-player_0.3.0_x86_64.deb
```

To remove:
```bash
sudo apt remove jatayu-media-player
```

## Release requirements (unchecked)
- [ ] Clean Debian 13 installation, MP4/MP3 launch and file associations
- [ ] Package file list includes executable, desktop entry, icon, and license
- [ ] Package installed from scratch and removed without leftover installed files
- [ ] Automated tests pass and manual regression checklist completed
- [ ] Package SHA-256 recorded from **final release artifact**
- [ ] Application source availability and third-party redistribution notices reviewed
- [ ] Release is explicitly marked *pre-release*, not stable

## Support
Report reproducible bugs at https://github.com/jatayuos4u/jatayu-media-player/issues
