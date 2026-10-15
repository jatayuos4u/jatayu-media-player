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
        property string currentPath: player.locationPath("Home")
        property var entries: []
        property string selectedPath: ""
        property string selectedName: ""
        property bool selectedFolder: false
        property bool showingRecent: false
        property bool searchEverywhere: false
        Timer { id: searchDelay; interval: 350; onTriggered: mediaBrowser.refresh() }
        function showRecent() {
            showingRecent = true
            searchEverywhere = false
            currentPath = "Recent files"
            selectedPath = ""
            selectedName = ""
            browserSearch.text = ""
            entries = player.recentMedia()
        }
        function navigate(path) {
            showingRecent = false
            searchEverywhere = false
            currentPath = path
            selectedPath = ""
            selectedName = ""
            browserSearch.text = ""
            refresh()
        }
        function refresh() {
            if (showingRecent) {
                let search = browserSearch.text.toLowerCase()
                entries = player.recentMedia().filter(item => item.name.toLowerCase().includes(search))
            } else if (searchEverywhere) {
                entries = browserSearch.text.trim().length < 2 ? [] : player.searchMedia(browserSearch.text)
            } else {
                entries = player.browseFolder(currentPath, browserSearch.text)
            }
        }
        onOpened: {
            if (currentPath.length === 0) currentPath = player.locationPath("Home")
            refresh()
        }
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
                Button {
                    text: "⌂ Home"
                    onClicked: mediaBrowser.navigate(player.locationPath("Home"))
                }
                Button {
                    text: "▣ Desktop"
                    onClicked: mediaBrowser.navigate(player.locationPath("Desktop"))
                }
                Button {
                    text: "◷ Recent"
                    onClicked: mediaBrowser.showRecent()
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
                readOnly: mediaBrowser.showingRecent || mediaBrowser.searchEverywhere
                onAccepted: if (!readOnly) mediaBrowser.navigate(text)
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: browserSearch
                    Layout.fillWidth: true
                    placeholderText: mediaBrowser.searchEverywhere ? "Search common media folders by filename…" : "Filter names in this folder…"
                    color: "#E9F1F7"
                    selectByMouse: true
                    background: Rectangle { color: "#101820"; border.color: "#52697E"; radius: 5 }
                    onTextChanged: searchDelay.restart()
                }
                Button {
                    text: mediaBrowser.searchEverywhere ? "Browse folders" : "Search all"
                    onClicked: {
                        if (mediaBrowser.searchEverywhere) {
                            mediaBrowser.navigate(player.locationPath("Home"))
                        } else {
                            mediaBrowser.showingRecent = false
                            mediaBrowser.searchEverywhere = true
                            mediaBrowser.currentPath = "Common media folders"
                            mediaBrowser.entries = []
                            searchDelay.restart()
                            browserSearch.forceActiveFocus()
                        }
                    }
                }
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
                    text: "Double-click folders to browse · Double-click media to play"
                    color: "#B7C8D8"
                    font.pixelSize: 12
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                spacing: 10
                Rectangle {
                    Layout.preferredWidth: 165
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    color: "#13212F"
                    radius: 7
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 7
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        Column {
                            width: 145
                            spacing: 5
                            Label {
                                width: parent.width
                                height: 26
                                text: "PLACES"
                                verticalAlignment: Text.AlignVCenter
                                color: "#8496A8"
                                font.bold: true
                                font.pixelSize: 11
                            }
                            Repeater {
                                model: ["Recent", "Home", "Desktop", "Documents", "Downloads", "Videos", "Music", "Pictures", "Computer"]
                                Button {
                                    required property string modelData
                                    width: 145
                                    height: 35
                                    text: modelData
                                    onClicked: {
                                        if (modelData === "Recent") mediaBrowser.showRecent()
                                        else mediaBrowser.navigate(player.locationPath(modelData))
                                    }
                                }
                            }
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
    Shortcut { sequence: "Ctrl+F"; onActivated: { mediaBrowser.open(); browserSearch.forceActiveFocus() } }
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
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: "#172532"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 11
                    color: "#163F63"
                    Label { anchors.centerIn: parent; text: "▶"; color: "#53B7FF"; font.pixelSize: 24 }
                }
                ColumnLayout {
                    spacing: 2
                    Label { text: "Jatayu Media Player"; color: "#E9F1F7"; font.bold: true; font.pixelSize: 19 }
                    Label { text: player.title === "No media selected" ? "Every Beat. Every Frame." : player.title; color: "#97ADBF"; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.maximumWidth: 350 }
                }
                Item { Layout.fillWidth: true }
                Button { text: "Browse media"; onClicked: mediaBrowser.open() }
                Button { text: "Recent"; onClicked: { mediaBrowser.open(); mediaBrowser.showRecent() } }
                Button { text: "Subtitles"; onClicked: subtitleDialog.open() }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#070B0F"
            MpvVideoItem { id: video; anchors.fill: parent; controller: player }
            Column {
                anchors.centerIn: parent
                visible: player.title === "No media selected"
                spacing: 15
                width: Math.min(parent.width - 44, 430)
                Rectangle {
                    width: 78
                    height: 78
                    radius: 24
                    color: "#19354A"
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label { anchors.centerIn: parent; text: "▶"; color: "#59B8FF"; font.pixelSize: 38 }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Your screen. Your sound."
                    color: "#F1F6FA"
                    font.pixelSize: 23
                    font.bold: true
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "Enjoy local music and videos without ads, accounts or tracking."
                    color: "#9BB0C1"
                    font.pixelSize: 14
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Open a video or song"
                    onClicked: mediaBrowser.open()
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Ctrl+O to browse    ·    Ctrl+F to find"
                    color: "#738B9E"
                    font.pixelSize: 11
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: player.error.length ? 26 : 0
            color: "#6D2626"; visible: player.error.length > 0
            Label { anchors.centerIn: parent; text: player.error; color: "white" }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 100
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
                    Button { text: "↶ 10"; onClicked: player.seekRelative(-10) }
                    Button { text: player.paused ? "▶ Play" : "Ⅱ Pause"; highlighted: true; onClicked: player.togglePause() }
                    Button { text: "Stop"; onClicked: player.stop() }
                    Button { text: "10 ↷"; onClicked: player.seekRelative(10) }
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
