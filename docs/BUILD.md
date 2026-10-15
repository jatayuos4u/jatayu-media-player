# Local Linux build instructions

Target: Debian 13 (Trixie), x86-64, with Qt 6 development tools and libmpv. Ubuntu derivatives may use different dependency versions. Needs a desktop graphics session; Wayland and X11 must both be verified.

## First run

```bash
chmod +x scripts/*.sh
./scripts/setup-linux.sh
./scripts/build-local.sh
./scripts/run-tests.sh
./build/jatayu-media-player /absolute/path/to/media.mp4
```

If Debian package names differ, install equivalent Qt6 base/declarative development packages, QtQuick/Controls/Dialogs QML runtime modules, `libmpv-dev`, `pkg-config`, Ninja and OpenGL headers. The shell script only handles Debian-like systems.

## Graphics architecture

The first prototype intentionally uses the Qt Quick `QQuickFramebufferObject` and the libmpv OpenGL render API. This requires Qt Quick OpenGL rendering (forced in `main.cpp`). This is a proof of concept: test graphics context lifecycle, resizing, driver recovery, frame updates and shutdown. Future phases may migrate to a more portable rendering integration for broader RHI support.

## Limitations and validation

- This archive was written and statically checked in an environment without Qt 6 Quick or libmpv development packages. **Compilation and actual playback are unverified.**
- No Flatpak, AppImage or .deb binary has been produced.
- This first stage handles only a single active file; playlists and metadata persistence are next.
- Qt window controls are intentionally simple; advanced accessibility and translation are pending.
- Network input is not accepted by the file opening function; only local existing readable files can be opened.
- OpenGL/libmpv updates are queued to the Qt GUI thread; test the callback/framebuffer lifecycle under graphics shutdown.
- If the player fails to create a video surface, run it from a terminal and collect Qt scene graph/libmpv diagnostics before changing render backends.

## Local build without GitHub Actions

Source commits and pull requests may be hosted on GitHub, but these scripts work on the developer computer. Do not enable GitHub Actions artifact uploads for this project. Use manual local builds and later upload fully validated release binaries to GitHub Releases.
