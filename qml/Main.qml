import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
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
    Dialog {
        id: mediaBrowser
        title: "Open media"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 960)
        height: Math.min(window.height - 24, 590)
        padding: 16
        standardButtons: Dialog.Close
        property string currentPath: player.locationPath("Videos")
        property var entries: []
        property string selectedPath: ""
        property string selectedName: ""
        property bool selectedFolder: false
        function navigate(path) {
            currentPath = path
            selectedPath = ""
            selectedName = ""
            browserSearch.text = ""
            refresh()
        }
        function refresh() {
            entries = player.browseFolder(currentPath, browserSearch.text)
        }
        onOpened: refresh()
        background: Rectangle { color: "#1B2836"; radius: 12; border.color: "#35475A" }
        header: Rectangle {
            implicitHeight: 52
            color: "#233446"
            Label { anchors.centerIn: parent; text: "Jatayu Media Browser"; color: "#E9F1F7"; font.bold: true; font.pixelSize: 17 }
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["Home", "Videos", "Music", "Downloads"]
                    Button {
                        required property string modelData
                        text: modelData
                        onClicked: mediaBrowser.navigate(player.locationPath(modelData))
                    }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "↑ Up"
                    onClicked: {
                        const path = mediaBrowser.currentPath
                        const parentPath = path.substring(0, path.lastIndexOf("/")) || "/"
                        mediaBrowser.navigate(parentPath)
                    }
                }
            }
            TextField {
                id: browserPath
                Layout.fillWidth: true
                text: mediaBrowser.currentPath
                selectByMouse: true
                color: "#E9F1F7"
                placeholderText: "Folder path"
                background: Rectangle { color: "#101820"; border.color: "#52697E"; radius: 5 }
                onAccepted: mediaBrowser.navigate(text)
            }
            TextField {
                id: browserSearch
                Layout.fillWidth: true
                placeholderText: "Filter files and folders in this location..."
                color: "#E9F1F7"
                selectByMouse: true
                background: Rectangle { color: "#101820"; border.color: "#52697E"; radius: 5 }
                onTextChanged: mediaBrowser.refresh()
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label {
                    text: mediaBrowser.entries.length + " items"
                    color: "#B7C8D8"
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: "Click to select · Double-click to open"
                    color: "#B7C8D8"
                    font.pixelSize: 12
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                Rectangle {
                    Layout.preferredWidth: 142
                    Layout.fillHeight: true
                    color: "#13212F"
                    radius: 7
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6
                        Label {
                            text: "PLACES"
                            color: "#8496A8"
                            font.bold: true
                            font.pixelSize: 11
                        }
                        Repeater {
                            model: ["Home", "Videos", "Music", "Downloads"]
                            Button {
                                required property string modelData
                                Layout.fillWidth: true
                                text: modelData
                                onClicked: mediaBrowser.navigate(player.locationPath(modelData))
                            }
                        }
                        Item { Layout.fillHeight: true }
                        Label {
                            text: "Local files only"
                            color: "#8496A8"
                            font.pixelSize: 11
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#101820"
                    radius: 7
                    ListView {
                        id: browserList
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        spacing: 3
                        model: mediaBrowser.entries
                        delegate: ItemDelegate {
                            required property var modelData
                            width: browserList.width
                            height: 46
                            highlighted: mediaBrowser.selectedPath === modelData.path
                            onClicked: {
                                mediaBrowser.selectedPath = modelData.path
                                mediaBrowser.selectedName = modelData.name
                                mediaBrowser.selectedFolder = modelData.directory
                            }
                            onDoubleClicked: {
                                if (modelData.directory) mediaBrowser.navigate(modelData.path)
                                else {
                                    player.openFile(modelData.path)
                                    mediaBrowser.close()
                                }
                            }
                            background: Rectangle {
                                radius: 5
                                color: parent.highlighted ? "#26547A" :
                                       parent.hovered ? "#243D53" : "#172431"
                            }
                            contentItem: RowLayout {
                                spacing: 10
                                Label {
                                    text: modelData.directory ? "▸" : "▶"
                                    color: "#59B8FF"
                                    font.pixelSize: 18
                                }
                                Label {
                                    text: modelData.name
                                    color: "#E9F1F7"
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }
                                Label {
                                    text: modelData.directory ? "Folder" : "Media"
                                    color: "#B7C8D8"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: mediaBrowser.entries.length === 0
                        text: "No supported files in this folder"
                        color: "#B7C8D8"
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    text: mediaBrowser.selectedName.length ? mediaBrowser.selectedName : "Select a media file or folder"
                    color: "#E9F1F7"
                    elide: Text.ElideMiddle
                }
                Button {
                    text: mediaBrowser.selectedFolder ? "Open folder" : "Play selected"
                    enabled: mediaBrowser.selectedPath.length > 0
                    onClicked: {
                        if (mediaBrowser.selectedFolder) mediaBrowser.navigate(mediaBrowser.selectedPath)
                        else {
                            player.openFile(mediaBrowser.selectedPath)
                            mediaBrowser.close()
                        }
                    }
                }
            }
        }
    }
    FileDialog {
        id: subtitleDialog
        title: "Open subtitles"
        nameFilters: ["Subtitle files (*.srt *.ass *.ssa)", "All files (*)"]
        onAccepted: player.openSubtitle(selectedFile.toString())
    }
    Dialog {
        id: searchDialog
        title: "Find local media"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 60, 720)
        height: Math.min(window.height - 70, 510)
        standardButtons: Dialog.Close
        property var results: []
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            Label {
                text: "Search file names in Videos, Music and Downloads (no background indexing)."
                color: window.textColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Enter at least two characters"
                    onAccepted: searchDialog.results = player.searchMedia(text)
                }
                Button {
                    text: "Search"
                    enabled: searchInput.text.trim().length >= 2
                    onClicked: searchDialog.results = player.searchMedia(searchInput.text)
                }
            }
            Label {
                text: searchDialog.results.length + " matches (first 100 max)"
                color: window.muted
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    id: searchResults
                    model: searchDialog.results
                    clip: true
                    spacing: 4
                    delegate: ItemDelegate {
                        required property var modelData
                        width: searchResults.width
                        height: 58
                        onClicked: {
                            player.openFile(modelData.path)
                            searchDialog.close()
                        }
                        contentItem: Column {
                            spacing: 3
                            Label {
                                width: parent.width
                                text: modelData.name
                                color: window.textColor
                                elide: Text.ElideMiddle
                            }
                            Label {
                                width: parent.width
                                text: modelData.folder
                                color: window.muted
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            }
        }
    }
    Shortcut { sequence: "Ctrl+F"; onActivated: searchDialog.open() }
    Shortcut { sequence: "Space"; onActivated: player.togglePause() }
    Shortcut { sequence: "Left"; onActivated: player.seekRelative(-5) }
    Shortcut { sequence: "Right"; onActivated: player.seekRelative(5) }
    Shortcut { sequence: "Ctrl+O"; onActivated: mediaBrowser.open() }
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
                Button { text: "Find media"; onClicked: searchDialog.open() }
                Button { text: "Open media"; onClicked: mediaBrowser.open() }
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
