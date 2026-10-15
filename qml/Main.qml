import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Jatayu.Backend 1.0
ApplicationWindow {
    id: window
    visible: true
    width: 1100; height: 680
    minimumWidth: 650; minimumHeight: 430
    title: "Jatayu Media Player — " + player.title
    color: "#101820"
    property color accent: "#1689E8"
    property color textColor: "#E9F1F7"
    property color muted: "#8496A8"
    FileDialog {
        id: fileDialog
        title: "Open media"
        onAccepted: player.openFile(selectedFile.toString())
    }
    FileDialog {
        id: subtitleDialog
        title: "Open subtitles"
        nameFilters: ["Subtitle files (*.srt *.ass *.ssa)", "All files (*)"]
        onAccepted: player.openSubtitle(selectedFile.toString())
    }
    Shortcut { sequence: "Space"; onActivated: player.togglePause() }
    Shortcut { sequence: "Left"; onActivated: player.seekRelative(-5) }
    Shortcut { sequence: "Right"; onActivated: player.seekRelative(5) }
    Shortcut { sequence: "Ctrl+O"; onActivated: fileDialog.open() }
    Shortcut { sequence: "F"; onActivated: window.visibility = window.visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen }
    Shortcut { sequence: "Escape"; onActivated: if (window.visibility === Window.FullScreen) window.visibility = Window.Windowed }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 62
            color: "#1B2836"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24
                Label { text: "▶"; color: window.accent; font.pixelSize: 26 }
                ColumnLayout {
                    spacing: 0
                    Label { text: "Jatayu Media Player"; color: window.textColor; font.bold: true; font.pixelSize: 18 }
                    Label { text: "Every Beat. Every Frame."; color: window.muted; font.pixelSize: 11 }
                }
                Item { Layout.fillWidth: true }
                Button { text: "Open media"; onClicked: fileDialog.open() }
                Button { text: "Subtitles"; onClicked: subtitleDialog.open() }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#070B0F"
            MpvVideoItem { id: video; anchors.fill: parent; controller: player }
            Label {
                anchors.centerIn: parent
                visible: player.title === "No media selected"
                text: "Open a video or audio file to begin\nCtrl+O to open a file"
                color: "#8496A8"; horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: player.error.length ? 26 : 0
            color: "#6D2626"; visible: player.error.length > 0
            Label { anchors.centerIn: parent; text: player.error; color: "white" }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 102
            color: "#1B2836"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 4
                Slider {
                    id: progress
                    Layout.fillWidth: true
                    from: 0; to: Math.max(1, player.duration)
                    value: pressed ? value : player.position
                    onMoved: player.seek(value)
                }
                RowLayout {
                    spacing: 14
                    Button { text: "−5s"; onClicked: player.seekRelative(-5) }
                    Button { text: player.paused ? "▶ Play" : "Ⅱ Pause"; onClicked: player.togglePause() }
                    Button { text: "Stop"; onClicked: player.stop() }
                    Button { text: "+5s"; onClicked: player.seekRelative(5) }
                    Label {
                        text: formatTime(player.position) + " / " + formatTime(player.duration)
                        color: window.textColor
                    }
                    Item { Layout.fillWidth: true }
                    Label { text: "Volume"; color: window.muted }
                    Slider { Layout.preferredWidth: 120; from: 0; to: 100; value: player.volume; onMoved: player.setVolume(value) }
                    Button { text: "⛶ Fullscreen"; onClicked: window.visibility = window.visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen }
                }
            }
        }
    }
    function formatTime(s) {
        if (!isFinite(s) || s < 0) return "00:00"
        let n = Math.floor(s)
        let hours = Math.floor(n / 3600)
        let minutes = Math.floor(n % 3600 / 60)
        let seconds = n % 60
        return (hours ? hours + ":" : "") + String(minutes).padStart(2, "0") + ":" + String(seconds).padStart(2, "0")
    }
}
