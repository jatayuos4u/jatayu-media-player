from pathlib import Path
p = Path(__file__).resolve().parents[1]
required = ['CMakeLists.txt', 'src/main.cpp', 'src/player/PlaybackController.cpp', 'src/player/MpvVideoItem.cpp', 'qml/Main.qml', 'README.md', 'LICENSE', 'docs/BUILD.md']
for item in required:
    assert (p/item).is_file(), f'Missing: {item}'
cmake = (p/'CMakeLists.txt').read_text()
assert 'Qt6::Quick' in cmake and 'PkgConfig::MPV' in cmake
qml = (p/'qml/Main.qml').read_text()
for feature in ('MpvVideoItem', 'fileDialog', 'subtitleDialog', 'seekRelative', 'FullScreen'):
    assert feature in qml, f'Missing UI feature {feature}'
print('Project structure checks: OK (not runtime tests)')
