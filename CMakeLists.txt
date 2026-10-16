cmake_minimum_required(VERSION 3.21)
project(JatayuMediaPlayer VERSION 0.3.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Quick Qml QuickControls2)
find_package(PkgConfig REQUIRED)
pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)
qt_add_executable(jatayu-media-player
  src/main.cpp
  src/player/PlaybackController.h
  src/player/PlaybackController.cpp
  src/player/MpvVideoItem.h
  src/player/MpvVideoItem.cpp
)
set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
qt_add_qml_module(jatayu-media-player URI JatayuMediaPlayer VERSION 1.0 QML_FILES qml/Main.qml)
target_link_libraries(jatayu-media-player PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::QuickControls2 PkgConfig::MPV)
install(TARGETS jatayu-media-player RUNTIME DESTINATION bin)
install(FILES assets/jatayu-media-player.desktop DESTINATION share/applications)

set_source_files_properties(assets/jatayu-media-player.svg PROPERTIES QT_RESOURCE_ALIAS jatayu-media-player.svg)
qt_add_resources(jatayu-media-player "brand_icons" PREFIX "/icons" FILES assets/jatayu-media-player.svg)
install(FILES assets/jatayu-media-player.svg DESTINATION share/icons/hicolor/scalable/apps)
