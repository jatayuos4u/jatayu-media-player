# v0.3.0 Local Beta: performance and Debian package verification

**Status:** Development/testing only. No public beta has been released. Builds on the development branch may still fail or behave differently on other Linux systems.

## 1. Build and source checks

```bash
cd ~/jatayu-media-player
git switch feature/playback-v0.3
git pull origin feature/playback-v0.3
./scripts/build-local.sh
./scripts/run-tests.sh
```

If compilation fails, stop and share the first compiler error. The Python check is a structure/smoke test, **not** a substitute for application runtime testing.

## 2. Playback and resource measurements

In one terminal run:

```bash
./build/jatayu-media-player /home/anup/Downloads/video-testing.mp4
```

In another terminal, while the video plays:

```bash
pid=$(pgrep -n -x jatayu-media-pl || pgrep -nf '/build/jatayu-media-player')
ps -p "$pid" -o pid,etime,%cpu,%mem,rss,cmd
```

Record values after approximately 1 minute and 5 minutes. `rss` is in KiB. Observe freezes, video stutter, A/V synchronization and whether quality settings alter performance. Repeat with a local MP3 and an MP4 at normal speed. Avoid comparing CPU numbers gathered from different resolutions or decode settings.

## 3. Manual QA gate

Follow [BETA-REGRESSION-CHECKLIST.md](BETA-REGRESSION-CHECKLIST.md) and record Pass/Fail/Not Tested. Do not merge into main or tag a public beta while critical regressions exist. Test at least one other Linux distro/desktop before promising broad compatibility.

## 4. Build an experimental Debian .deb locally

Requires a working C++/Qt build environment, CPack, dpkg tools, and FFmpeg:

```bash
sudo apt install cmake ninja-build dpkg-dev ffmpeg
bash scripts/build-deb-beta.sh
```

The script runs source checks, builds the binary, invokes CPack, lists the package contents/control data, and prints SHA-256. It creates a package under `dist/`, but **does not install or publish** it.

Review package dependencies and perform a clean installation test before distribution. Initial CPack dependency lists are provisional and may need adjustments for Debian/Ubuntu versions. Dynamic linkage may not automatically pull every Qt QML runtime plugin; verify these by launching the installed package.

For local inspection:

```bash
dpkg-deb --info dist/*.deb
dpkg-deb --contents dist/*.deb
```

For an **isolated test system only**, installation can be attempted with `sudo apt install ./dist/<actual-package-name>.deb`; then check that the app appears in the launcher, opens local media, and uninstalls cleanly. Do not install an unverified beta package over an active OS image.

## 5. Release blockers to verify

- Compile and QML startup, including keyboard shortcuts and file-browser selection
- Audio, video, subtitles, fullscreen, high-DPI scaling, queues and resumes
- CPU/memory utilization and supported graphics hardware
- Packaging dependency correctness, icon and file-type associations
- Third-party licenses, provenance, redistribution obligations, release notes and integrity hashes
