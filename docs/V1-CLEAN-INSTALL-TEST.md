# Jatayu Media Player 1.0.0 — independent clean-install acceptance

**Status:** Awaiting execution. This is a test protocol, not evidence of a completed test.

## Scope and safety

Use a disposable **Debian 13 amd64 virtual machine** or spare computer, not the developer's daily-use machine. Take a VM snapshot first. Do not share personal media or credentials in issue reports. Use two small, rights-cleared MP3 and MP4 test files.

The repository signing fingerprint must match the independently recorded release key:
`FCAD173B005222F8DCB16C691002D7BA2CD8EB09`.

## Debian — clean APT install

1. Record `cat /etc/os-release`, `uname -m`, `apt-cache policy jatayu-media-player` and `dpkg-query -W jatayu-media-player` (the last command should initially report not installed).
2. Download the public repository key over HTTPS:
   ```bash
   curl -fsSLo /tmp/jatayu-media-player-key.asc https://jatayuos4u.github.io/jatayu-packages/apt/jatayu-media-player-archive-key.asc
   gpg --show-keys --with-fingerprint /tmp/jatayu-media-player-key.asc
   ```
   Confirm the full fingerprint *before* importing the key. Never bypass signature verification.
3. Configure the dedicated keyring and APT source:
   ```bash
   gpg --dearmor < /tmp/jatayu-media-player-key.asc | sudo tee /usr/share/keyrings/jatayu-media-player.gpg >/dev/null
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/jatayu-media-player.gpg] https://jatayuos4u.github.io/jatayu-packages/apt stable main" | sudo tee /etc/apt/sources.list.d/jatayu-media-player.list
   sudo apt update
   apt-cache policy jatayu-media-player
   sudo apt-get -s install jatayu-media-player
   ```
4. Check the simulated operation for unwanted package removals. Install:
   ```bash
   sudo apt install jatayu-media-player
   dpkg-query -W -f='\${Status} \${Version}\\n' jatayu-media-player
   sudo dpkg -V jatayu-media-player
   /usr/bin/jatayu-media-player
   ```
5. Manually test MP3, MP4, Browse Media, playlist creation, subtitles, volume, fullscreen, About version 1.0.0 and launch from the desktop entry.
6. In this disposable environment, test package removal:
   ```bash
   sudo apt remove jatayu-media-player
   test ! -e /usr/bin/jatayu-media-player
   ```
   Removal can leave user settings; do not delete unrelated files.
7. Mark outcome and record the VM distribution/build, test time, stdout/stderr and any failures.

## Flatpak — fresh remote install and update

The project's previously recorded Flatpak test used a separate named Flatpak installation with the signed official remote. Independently reproduce on a fresh Linux environment:

1. Confirm Flatpak and the KDE 6.10 runtime are available.
2. Download and independently verify the official public key; register remote with GPG verification enabled:
   ```bash
   curl -fsSLo /tmp/jatayu-flatpak-key.asc https://jatayuos4u.github.io/jatayu-packages/flatpak-repository-key.asc
   gpg --show-keys --with-fingerprint /tmp/jatayu-flatpak-key.asc
   flatpak remote-add --user --if-not-exists --gpg-import=/tmp/jatayu-flatpak-key.asc jatayu-official https://jatayuos4u.github.io/jatayu-packages/flatpak/
   flatpak install --user jatayu-official io.github.jatayuos4u.JatayuMediaPlayer
   flatpak info --user io.github.jatayuos4u.JatayuMediaPlayer
   ```
3. Test MP3/MP4 playback, file chooser access, desktop entry, sound, subtitles, Help, Preferences and album tagging on copies.
4. For real update validation, publish a **newer commit** to the same signed remote and test `flatpak update --user` followed by `flatpak info --show-commit`. A historical passing update test exists; do not claim an additional one without logs.
5. Remove only the test installation's app when finished.

## Required evidence and sign-off

| Test | Outcome | Evidence location |
|---|---|---|
| Fresh Debian 13 APT install | Pending | |
| Debian MP3/MP4 and UI on fresh machine | Pending | |
| Debian package remove | Pending | |
| Fresh Flatpak remote install on second environment | Pending | |
| Third-party copyright/license review | Pending | |
| Corresponding source and source commit match | Pending | |

Do not tag/publish version 1.0.0 solely because this test document exists.
