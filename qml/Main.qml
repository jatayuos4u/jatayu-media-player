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
    property bool forceMusicMode: false
    readonly property bool audioTrack: /\\.(mp3|flac|wav|ogg|opus|m4a|aac|wma|alac)$/i.test(player.title)
    readonly property bool musicMode: audioTrack || forceMusicMode
    property var mediaQueue: []
    property bool restoredSettings: false
    property string repeatMode: "Off"
    property bool shuffleEnabled: false
    Settings {
        id: playlistSettings
        category: "Playlists"
        property string storedQueue: "[]"
        property string storedRepeat: "Off"
        property bool storedShuffle: false
    }
    Component.onCompleted: {
        try {
            const loaded = JSON.parse(playlistSettings.storedQueue)
            if (Array.isArray(loaded))
                mediaQueue = loaded.filter(item => item && typeof item.path === "string" && typeof item.name === "string").slice(0, 500)
        } catch (e) { mediaQueue = [] }
        repeatMode = ["Off", "All", "One"].includes(playlistSettings.storedRepeat) ? playlistSettings.storedRepeat : "Off"
        shuffleEnabled = playlistSettings.storedShuffle
        restoredSettings = true
    }
    onMediaQueueChanged: if (restoredSettings) playlistSettings.storedQueue = JSON.stringify(mediaQueue)
    onRepeatModeChanged: if (restoredSettings) playlistSettings.storedRepeat = repeatMode
    onShuffleEnabledChanged: if (restoredSettings) playlistSettings.storedShuffle = shuffleEnabled
    function advanceQueue() {
        if (queueIndex < 0 || mediaQueue.length === 0) return
        if (repeatMode === "One") { playQueueIndex(queueIndex); return }
        if (shuffleEnabled && mediaQueue.length > 1) {
            let next = Math.floor(Math.random() * (mediaQueue.length - 1))
            if (next >= queueIndex) next++
            playQueueIndex(next)
        } else if (queueIndex < mediaQueue.length - 1) playQueueIndex(queueIndex + 1)
        else if (repeatMode === "All") playQueueIndex(0)
    }
    property int queueIndex: -1
    function playQueueIndex(index) {
        if (index < 0 || index >= mediaQueue.length) return
        queueIndex = index
        player.openFile(mediaQueue[index].path)
    }
    function enqueue(path, name, playNow) {
        if (!path) return
        let items = mediaQueue.slice()
        let index = items.findIndex(entry => entry.path === path)
        if (index < 0) {
            items.push({path: path, name: name || path.split("/").pop()})
            index = items.length - 1
            mediaQueue = items
        }
        if (playNow || queueIndex < 0) playQueueIndex(index)
    }
    function skipQueue(delta) { playQueueIndex(queueIndex + delta) }
    function removeQueueIndex(index) {
        if (index < 0 || index >= mediaQueue.length) return
        let items = mediaQueue.slice()
        items.splice(index, 1)
        mediaQueue = items
        if (index < queueIndex) queueIndex--
        else if (index === queueIndex) queueIndex = -1
    }
    readonly property bool cinemaMode: visibility === Window.FullScreen
    property bool showCinemaControls: true
    function toggleCinema() { if (cinemaMode) showNormal(); else showFullScreen() }
    onCinemaModeChanged: {
        showCinemaControls = true
        if (cinemaMode && !player.paused) hideControls.restart()
        else hideControls.stop()
    }
    Timer {
        id: hideControls
        interval: 3000
        onTriggered: if (window.cinemaMode && !player.paused) window.showCinemaControls = false
    }
    Connections {
        target: player
        function onPlaybackFinished() {
            window.advanceQueue()
        }
        function onPausedChanged() {
            if (player.paused) { window.showCinemaControls = true; hideControls.stop() }
            else if (window.cinemaMode) hideControls.restart()
        }
    }
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
                                    window.enqueue(modelData.path, modelData.name, true)
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
                    text: "Add to queue"
                    enabled: mediaBrowser.selectedPath.length > 0 && !mediaBrowser.selectedFolder
                    onClicked: {
                        window.enqueue(mediaBrowser.selectedPath, mediaBrowser.selectedName, false)
                        mediaBrowser.close()
                    }
                }
                Button {
                    text: mediaBrowser.selectedFolder ? "Open folder" : "Play selected"
                    enabled: mediaBrowser.selectedPath.length > 0
                    onClicked: {
                        if (mediaBrowser.selectedFolder) mediaBrowser.navigate(mediaBrowser.selectedPath)
                        else {
                            window.enqueue(mediaBrowser.selectedPath, mediaBrowser.selectedName, true)
                            mediaBrowser.close()
                        }
                    }
                }
            }
        }
    }
    Dialog {
        id: queueDialog
        title: "Up next"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 600)
        height: Math.min(window.height - 24, 540)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent
            Label { text: mediaQueue.length + " items in queue"; color: window.textColor }
            ListView {
                id: queueList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: mediaQueue
                delegate: ItemDelegate {
                    required property var modelData
                    required property int index
                    width: queueList.width
                    contentItem: RowLayout {
                        Label { text: (index === queueIndex ? "▶ " : "") + modelData.name; color: window.textColor; Layout.fillWidth: true; elide: Text.ElideMiddle }
                        Button { text: "Play"; onClicked: window.playQueueIndex(index) }
                        Button { text: "Remove"; onClicked: window.removeQueueIndex(index) }
                    }
                }
            }
            RowLayout {
                Button { text: "Add media"; onClicked: { queueDialog.close(); mediaBrowser.open() } }
                ComboBox {
                    model: ["Off", "All", "One"]
                    currentIndex: model.indexOf(window.repeatMode)
                    onActivated: window.repeatMode = currentText
                }
                CheckBox { text: "Shuffle"; checked: window.shuffleEnabled; onToggled: window.shuffleEnabled = checked }
                Item { Layout.fillWidth: true }
                Button { text: "Clear queue"; enabled: mediaQueue.length > 0; onClicked: { mediaQueue = []; queueIndex = -1 } }
            }
        }
    }
    Dialog {
        id: captionTools
        title: "Subtitle controls"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 400)
        standardButtons: Dialog.Close
        property real delay: 0
        property int textSize: 48
        ColumnLayout {
            anchors.fill: parent
            Button { text: "Switch subtitle track"; Layout.fillWidth: true; onClicked: player.cycleSubtitleTrack() }
            Label { text: "Subtitle delay: " + captionTools.delay.toFixed(1) + " s"; color: "#E9F1F7" }
            Slider {
                Layout.fillWidth: true
                from: -10; to: 10; stepSize: 0.5
                value: captionTools.delay
                onMoved: { captionTools.delay = value; player.setSubtitleDelay(value) }
            }
            Button { text: "Reset delay"; onClicked: { captionTools.delay = 0; player.setSubtitleDelay(0) } }
            Label { text: "Subtitle size: " + captionTools.textSize; color: "#E9F1F7" }
            Slider {
                Layout.fillWidth: true
                from: 20; to: 90; stepSize: 2
                value: captionTools.textSize
                onMoved: { captionTools.textSize = Math.round(value); player.setSubtitleSize(captionTools.textSize) }
            }
        }
    }
    Dialog {
        id: subtitleDialog
        title: "Open subtitles"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 720)
        height: Math.min(window.height - 24, 540)
        padding: 16
        standardButtons: Dialog.Close
        property string folder: player.locationPath("Downloads")
        property var entries: []
        property string selectedFile: ""
        function navigate(path) {
            folder = path
            selectedFile = ""
            entries = player.browseSubtitles(folder)
        }
        onOpened: navigate(folder)
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Button { text: "Home"; onClicked: subtitleDialog.navigate(player.locationPath("Home")) }
                Button { text: "Downloads"; onClicked: subtitleDialog.navigate(player.locationPath("Downloads")) }
                Button { text: "Videos"; onClicked: subtitleDialog.navigate(player.locationPath("Videos")) }
                Button { text: "Up"; enabled: subtitleDialog.folder !== "/"; onClicked: subtitleDialog.navigate(subtitleDialog.folder.substring(0, subtitleDialog.folder.lastIndexOf("/")) || "/") }
            }
            Label {
                Layout.fillWidth: true
                text: subtitleDialog.folder
                color: "#C1D5E4"
                elide: Text.ElideMiddle
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#172532"
                radius: 7
                ListView {
                    id: subtitleFiles
                    anchors.fill: parent
                    anchors.margins: 5
                    model: subtitleDialog.entries
                    clip: true
                    delegate: ItemDelegate {
                        required property var modelData
                        width: subtitleFiles.width
                        highlighted: subtitleDialog.selectedFile === modelData.path
                        text: (modelData.directory ? "📁 " : "◧ ") + modelData.name
                        onClicked: {
                            if (modelData.directory) subtitleDialog.navigate(modelData.path)
                            else subtitleDialog.selectedFile = modelData.path
                        }
                        onDoubleClicked: {
                            if (modelData.directory) subtitleDialog.navigate(modelData.path)
                            else {
                                player.openSubtitle(modelData.path)
                                subtitleDialog.close()
                            }
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: subtitleFiles.count === 0
                    text: "No subtitle files in this folder"
                    color: "#A5BACB"
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: subtitleDialog.selectedFile.length ? subtitleDialog.selectedFile.split("/").pop() : "Choose a subtitle file (.srt, .ass, .ssa, .vtt)"
                    color: "#D9E7F3"
                    elide: Text.ElideMiddle
                }
                Button {
                    text: "Load subtitles"
                    enabled: subtitleDialog.selectedFile.length > 0
                    onClicked: {
                        player.openSubtitle(subtitleDialog.selectedFile)
                        subtitleDialog.close()
                    }
                }
            }
        }
    }
    Shortcut { sequence: "Ctrl+F"; onActivated: { mediaBrowser.open(); browserSearch.forceActiveFocus() } }
    Shortcut { sequence: "Space"; onActivated: player.togglePause() }
    Shortcut { sequence: "Left"; onActivated: player.seekRelative(-5) }
    Shortcut { sequence: "Right"; onActivated: player.seekRelative(5) }
    Shortcut { sequence: "Ctrl+O"; onActivated: mediaBrowser.open() }
    Shortcut { sequence: "F"; onActivated: window.toggleCinema() }
    Shortcut { sequence: "Escape"; onActivated: if (window.cinemaMode) window.showNormal() }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: window.cinemaMode ? 0 : 72
            visible: !window.cinemaMode
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
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const c = getContext("2d")
                            c.clearRect(0, 0, width, height)
                            c.fillStyle = "#39D9F2"
                            c.beginPath()
                            c.moveTo(11, 6)
                            c.quadraticCurveTo(29, 13, 34, 22)
                            c.quadraticCurveTo(25, 34, 12, 34)
                            c.lineTo(19, 22)
                            c.closePath()
                            c.fill()
                            c.fillStyle = "#1485E8"
                            c.beginPath()
                            c.moveTo(6, 9)
                            c.quadraticCurveTo(8, 24, 19, 30)
                            c.lineTo(11, 33)
                            c.quadraticCurveTo(4, 21, 6, 9)
                            c.fill()
                            c.fillStyle = "#D8F9FF"
                            c.beginPath()
                            c.arc(27, 19, 1.5, 0, 6.283)
                            c.fill()
                        }
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Label { text: "Jatayu Media Player"; color: "#E9F1F7"; font.bold: true; font.pixelSize: 19 }
                    Label { text: player.title === "No media selected" ? "Every Beat. Every Frame." : player.title; color: "#97ADBF"; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.maximumWidth: 350 }
                }
                Item { Layout.fillWidth: true }
                Button { text: "Browse media"; onClicked: mediaBrowser.open() }
                Button { text: "Queue (" + mediaQueue.length + ")"; onClicked: queueDialog.open() }
                Button { text: window.musicMode ? "Video view" : "Music view"; onClicked: window.forceMusicMode = !window.forceMusicMode }
                Button { text: "Recent"; onClicked: { mediaBrowser.open(); mediaBrowser.showRecent() } }
                Label { text: "Quality"; color: "#9BB0C1" }
                ComboBox {
                    id: videoQualityPicker
                    Layout.preferredWidth: 144
                    model: ["Performance", "Balanced"]
                    currentIndex: Math.max(0, model.indexOf(player.qualityProfile))
                    onActivated: player.setQualityProfile(currentText)
                    ToolTip.visible: hovered
                    ToolTip.text: "High Quality is temporarily disabled pending graphics stability testing."
                }
                Button { text: "Subtitles"; onClicked: subtitleDialog.open() }
                Button { text: "Caption tools"; onClicked: captionTools.open() }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#070B0F"
            MpvVideoItem { id: video; anchors.fill: parent; controller: player }
            Rectangle {
                anchors.fill: parent
                visible: window.musicMode
                color: "#101C2B"
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 570)
                    spacing: 16
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 160; height: 160; radius: 28
                        color: "#173D5B"
                        border.color: "#2778AD"
                        Label { anchors.centerIn: parent; text: "♫"; color: "#66E5FA"; font.pixelSize: 93 }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: player.title === "No media selected" ? "Your music, your way" : player.title
                        font.pixelSize: 25
                        font.bold: true
                        color: "#F0F8FF"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Local music • No accounts • No tracking"
                        font.pixelSize: 13
                        color: "#9AB6C9"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 14
                        Button { text: "Previous"; enabled: window.queueIndex > 0; onClicked: window.skipQueue(-1) }
                        Button { text: player.paused ? "Play" : "Pause"; onClicked: player.togglePause() }
                        Button {
                            text: "Next"
                            enabled: window.queueIndex >= 0 && window.queueIndex < window.mediaQueue.length - 1
                            onClicked: window.skipQueue(1)
                        }
                    }
                    Button { Layout.alignment: Qt.AlignHCenter; text: "Music queue"; onClicked: queueDialog.open() }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: window.cinemaMode
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onPositionChanged: {
                    window.showCinemaControls = true
                    if (!player.paused) hideControls.restart()
                }
            }
            Column {
                anchors.centerIn: parent
                visible: player.title === "No media selected" && !window.musicMode
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
            Layout.fillWidth: true; Layout.preferredHeight: window.cinemaMode ? 0 : 100
            visible: !window.cinemaMode
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
                    Button { text: "Previous"; enabled: queueIndex > 0; onClicked: skipQueue(-1) }
                    Button { text: "Next"; enabled: queueIndex >= 0 && queueIndex < mediaQueue.length - 1; onClicked: skipQueue(1) }
                    Button { text: "10 ↷"; onClicked: player.seekRelative(10) }
                    Label {
                        text: formatTime(player.position) + " / " + formatTime(player.duration)
                        color: window.textColor
                    }
                    Item { Layout.fillWidth: true }
                    Label { text: "Volume"; color: window.muted }
                    Slider { Layout.preferredWidth: 120; from: 0; to: 100; value: player.volume; onMoved: player.setVolume(value) }
                    Button { text: "⛶ Fullscreen"; onClicked: window.toggleCinema() }
                }
            }
        }
    }
    Rectangle {
        visible: window.cinemaMode && window.showCinemaControls
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 112
        z: 20
        color: "#E6172532"
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 3
            Label {
                text: player.title
                color: "#E9F1F7"
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
            Slider {
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, player.duration)
                value: pressed ? value : player.position
                enabled: player.duration > 0
                onMoved: player.seek(value)
            }
            RowLayout {
                Layout.fillWidth: true
                Button { text: "↶ 10"; onClicked: player.seekRelative(-10) }
                Button { text: player.paused ? "▶ Play" : "Ⅱ Pause"; onClicked: player.togglePause() }
                Button { text: "10 ↷"; onClicked: player.seekRelative(10) }
                Label { text: formatTime(player.position) + " / " + formatTime(player.duration); color: "#E9F1F7" }
                Item { Layout.fillWidth: true }
                Label { text: "Volume"; color: "#E9F1F7" }
                Slider { Layout.preferredWidth: 125; from: 0; to: 100; value: player.volume; onMoved: player.setVolume(value) }
                Button { text: "Exit fullscreen"; onClicked: window.showNormal() }
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
