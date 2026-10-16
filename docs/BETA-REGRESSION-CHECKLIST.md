# Jatayu Media Player v0.3.0 — Beta Regression Checklist

This is a **manual QA checklist**, not a certification. Perform it on a fresh build, record Pass / Fail / Not Tested, attach logs/screenshots for failures, and repeat on supported Linux desktops before release.

## Build and launch
- [ ] `./scripts/build-local.sh` completes without compile errors
- [ ] `./scripts/run-tests.sh` passes
- [ ] Application launches without QML errors; logo and title appear
- [ ] Window works in small and maximized sizes; no clipped controls

## Media playback
- [ ] MP4/H.264/AAC plays with video and sound
- [ ] MP3, FLAC, OGG, WAV play as expected
- [ ] Pause, seek, skip, stop and volume work
- [ ] Playback speed from 0.5× to 2× works and restores across restart
- [ ] Video quality Performance and Balanced are stable
- [ ] Fullscreen (F), Esc, mouse control overlay and aspect ratio work
- [ ] Multi-audio file allows switching between audio tracks
- [ ] External SRT/ASS/VTT subtitle opens; timing, size and track switching work

## Resume and preferences
- [ ] Video position resumes after closing and reopening midway
- [ ] Completed video does not resume at the end
- [ ] Disable Resume in Preferences; close and reopen: playback starts at beginning
- [ ] Volume, speed and quality preferences persist
- [ ] Preferences dialog opens and remains usable on smaller displays
- [ ] Help, About, Media Information, shortcut dialogs load cleanly

## Browser, library and playlists
- [ ] Browse folders and select media with mouse and arrows/Enter
- [ ] Scrollbars work in media browser and Places
- [ ] Search finds matching files
- [ ] Music Library Songs, Folders, Artists, Albums views populate correctly
- [ ] Album artwork appears when embedded; placeholder used when absent
- [ ] Edit song title, artist, album and cover to a *new* file without altering original
- [ ] Select multiple songs and add to a named playlist
- [ ] Named playlists survive restart; rename, remove tracks, delete
- [ ] Queue advances automatically, repeat and shuffle work

## Safety, performance and packaging
- [ ] Invalid, deleted and unsupported files produce clear errors, not crashes
- [ ] Scan large music folder without UI freezing unacceptably
- [ ] Watch CPU, memory, and audio/video sync for 1080p playback on low-end Intel hardware
- [ ] No unexpected network activity during local playback
- [ ] Clean Debian package install, launch, file association and uninstall
- [ ] Review license notices and third-party codec obligations
- [ ] Repeat the smoke test on at least one additional Linux distro/desktop

## Evidence
Record date, distro, desktop session (Wayland/X11), hardware, commit SHA, tested file, outcome, and any reproduction steps. Do not publish a stable release while critical items fail.
