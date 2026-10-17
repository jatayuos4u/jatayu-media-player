cmake_minimum_required(VERSION 3.21)
project(JatayuMediaPlayer VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
include(CTest)
if(BUILD_TESTING)
  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  add_test(NAME project_structure COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/check_project.py")
endif()
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
# Ensure QML resources are discoverable outside the build tree.
# Without QTP0001 NEW, the resources may live under /JatayuMediaPlayer,
# while QQmlApplicationEngine::loadFromModule searches /qt/qml imports.
qt_policy(SET QTP0001 NEW)
qt_add_qml_module(jatayu-media-player
  URI JatayuMediaPlayer
  VERSION 1.0
  RESOURCE_PREFIX "/qt/qml"
  QML_FILES qml/Main.qml
)
target_link_libraries(jatayu-media-player PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::QuickControls2 PkgConfig::MPV)
install(TARGETS jatayu-media-player RUNTIME DESTINATION bin)
install(FILES assets/jatayu-media-player.desktop DESTINATION share/applications)

set_source_files_properties(assets/jatayu-media-player.svg PROPERTIES QT_RESOURCE_ALIAS jatayu-media-player.svg)
qt_add_resources(jatayu-media-player "brand_icons" PREFIX "/icons" FILES assets/jatayu-media-player.svg)
install(FILES assets/jatayu-media-player.svg DESTINATION share/icons/hicolor/scalable/apps)
# Preserve the application license alongside the installed package.
install(FILES LICENSE DESTINATION share/doc/jatayu-media-player RENAME copyright)

# Opt-in local Debian packaging. No package or release is produced by default.
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "jatayu-media-player")
set(CPACK_PACKAGE_VENDOR "Jatayu Media Player Project")
set(CPACK_PACKAGE_CONTACT "https://github.com/jatayuos4u/jatayu-media-player/issues")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Privacy-focused Qt/libmpv media player for Linux")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_DEBIAN_PACKAGE_SECTION "video")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_RELEASE "2")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libmpv2 | libmpv1, ffmpeg, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-dialogs, qml6-module-qtcore")
set(CPACK_PACKAGE_FILE_NAME "jatayu-media-player_${PROJECT_VERSION}_${CMAKE_SYSTEM_PROCESSOR}")
include(CPack)
