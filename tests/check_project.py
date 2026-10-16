from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
required = [
    "CMakeLists.txt", "src/main.cpp", "src/player/PlaybackController.cpp",
    "src/player/PlaybackController.h", "src/player/MpvVideoItem.cpp",
    "qml/Main.qml", "README.md", "LICENSE", "docs/BUILD.md",
    "docs/BETA-REGRESSION-CHECKLIST.md",
]
for item in required:
    assert (root / item).is_file(), f"Missing: {item}"

cmake = (root / "CMakeLists.txt").read_text()
assert "Qt6::Quick" in cmake and "PkgConfig::MPV" in cmake
qml = (root / "qml/Main.qml").read_text()
for feature in (
    "MpvVideoItem", "mediaBrowser", "subtitleDialog", "seekRelative",
    "toggleCinema", "libraryDialog", "namedPlaylistsDialog", "preferencesDialog",
    "mediaInfoDialog", "aboutPlayerDialog", "browserList",
):
    assert feature in qml, f"Missing UI feature {feature}"
assert "Keys.onEndPressed" not in qml and "Keys.onHomePressed" not in qml
assert not re.search(r"^\s*icon\s*:", qml, re.MULTILINE), "Unsupported ApplicationWindow icon property may be present"
desktop = (root / "assets/jatayu-media-player.desktop").read_text()
assert "Exec=jatayu-media-player" in desktop
print("Source/feature smoke checks: PASS (does not test compile or runtime)")
