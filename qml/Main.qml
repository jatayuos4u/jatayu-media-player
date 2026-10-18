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
    // Keep dialog text, controls and backgrounds readable across distro Qt themes.
    palette.window: "#152330"
    palette.windowText: "#E9F1F7"
    palette.base: "#101820"
    palette.alternateBase: "#1B2836"
    palette.text: "#E9F1F7"
    palette.button: "#263B4B"
    palette.buttonText: "#E9F1F7"
    palette.highlight: "#1689E8"
    palette.highlightedText: "#FFFFFF"
    palette.placeholderText: "#9FC1D7"
    property color accent: "#1689E8"
    property color textColor: "#E9F1F7"
    property color muted: "#8496A8"
    property bool errorBannerDismissed: false
    Connections { target: player; function onErrorChanged() { window.errorBannerDismissed = false } }
    property bool forceMusicMode: false
    property bool forceVideoMode: false
    readonly property bool audioTrack: ["mp3", "flac", "wav", "ogg", "opus", "m4a", "aac", "wma", "alac"].includes(player.title.toLowerCase().split(".").pop())
    readonly property bool musicMode: !forceVideoMode && (audioTrack || forceMusicMode)
    property var mediaQueue: []
    property bool restoredSettings: false
    property var namedPlaylists: ({})
    property var pendingPlaylistEntry: null
    property var pendingPlaylistEntries: []
    property string activePlaylist: ""
    function saveNamedPlaylist(name, entries) {
        const key = name.trim()
        if (!key || key.length > 80) return
        const data = Object.assign({}, namedPlaylists)
        data[key] = entries.slice(0, 500).map(item => ({path: item.path, name: item.name}))
        namedPlaylists = data
        playlistSettings.namedCollections = JSON.stringify(data)
    }
    function deleteNamedPlaylist(name) {
        const data = Object.assign({}, namedPlaylists)
        delete data[name]
        namedPlaylists = data
        playlistSettings.namedCollections = JSON.stringify(data)
    }
    function loadNamedPlaylist(name, play) {
        const entries = namedPlaylists[name]
        if (!entries || !entries.length) return
        mediaQueue = entries.slice()
        queueIndex = -1
        if (play) playQueueIndex(0)
    }
    property string repeatMode: "Off"
    property bool shuffleEnabled: false
    Settings {
        id: playlistSettings
        category: "Playlists"
        property string storedQueue: "[]"
        property string namedCollections: "{}"
        property string storedRepeat: "Off"
        property bool storedShuffle: false
    }
    Component.onCompleted: {
        try {
            const loaded = JSON.parse(playlistSettings.storedQueue)
            if (Array.isArray(loaded) && playlistSettings.storedQueue !== "" && userPreferences.rememberQueue)
                mediaQueue = loaded.filter(item => item && typeof item.path === "string" && typeof item.name === "string").slice(0, 500)
        } catch (e) { mediaQueue = [] }
        repeatMode = ["Off", "All", "One"].includes(playlistSettings.storedRepeat) ? playlistSettings.storedRepeat : "Off"
        shuffleEnabled = playlistSettings.storedShuffle
        try {
            const stored = JSON.parse(playlistSettings.namedCollections)
            if (stored && typeof stored === "object" && !Array.isArray(stored)) namedPlaylists = stored
        } catch (e) { namedPlaylists = ({}) }
        restoredSettings = true
    }
    onMediaQueueChanged: if (restoredSettings && userPreferences.rememberQueue) playlistSettings.storedQueue = JSON.stringify(mediaQueue)
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
        property var selectedFiles: ({})
        property int selectionAnchor: -1
        readonly property int selectedFileCount: Object.keys(selectedFiles).length
        function selectFile(i, modifiers) {
            if (i < 0 || i >= entries.length) return
            const item = entries[i]
            chooseIndex(i)
            if (item.directory) {
                if (!(modifiers & (Qt.ControlModifier | Qt.ShiftModifier))) selectedFiles = ({})
                return
            }
            const selected = Object.assign({}, selectedFiles)
            if ((modifiers & Qt.ShiftModifier) && selectionAnchor >= 0) {
                for (let n = Math.min(i, selectionAnchor); n <= Math.max(i, selectionAnchor); n++) {
                    const candidate = entries[n]
                    if (!candidate.directory) selected[candidate.path] = {path:candidate.path, name:candidate.name}
                }
            } else if (modifiers & Qt.ControlModifier) {
                if (selected[item.path]) delete selected[item.path]
                else selected[item.path] = {path:item.path, name:item.name}
                selectionAnchor = i
            } else {
                selectedFiles = ({[item.path]: {path:item.path, name:item.name}})
                selectionAnchor = i
                return
            }
            selectedFiles = selected
        }
        function addSelectedToQueue() {
            const files = Object.values(selectedFiles)
            if (files.length === 0 && selectedPath && !selectedFolder)
                files.push({path:selectedPath, name:selectedName})
            for (const file of files) window.enqueue(file.path, file.name, false)
            if (files.length > 0) close()
        }
        property bool showingRecent: false
        property bool searchEverywhere: false
        function chooseIndex(i) {
            if (i < 0 || i >= entries.length) return
            browserList.currentIndex = i
            const item = entries[i]
            selectedPath = item.path
            selectedName = item.name
            selectedFolder = item.directory
            browserList.positionViewAtIndex(i, ListView.Contain)
        }
        function openSelected() {
            if (!selectedPath) return
            if (selectedFolder) navigate(selectedPath)
            else { window.enqueue(selectedPath, selectedName, true); close() }
        }
        Timer { id: searchDelay; interval: 350; onTriggered: mediaBrowser.refresh() }
        function showRecent() {
            showingRecent = true
            searchEverywhere = false
            currentPath = "Recent files"
            selectedPath = ""
            selectedName = ""
            selectedFiles = ({})
            selectionAnchor = -1
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
            selectedFiles = ({})
            selectionAnchor = -1
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
            browserList.forceActiveFocus()
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
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
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
                        focus: true
                        keyNavigationEnabled: false
                        currentIndex: -1
                        Keys.onDownPressed: function(event) { mediaBrowser.chooseIndex(Math.min(count - 1, currentIndex + 1)); event.accepted = true }
                        Keys.onUpPressed: function(event) { mediaBrowser.chooseIndex(currentIndex < 0 ? 0 : Math.max(0, currentIndex - 1)); event.accepted = true }
                        Keys.onReturnPressed: function(event) { mediaBrowser.openSelected(); event.accepted = true }
                        Keys.onEnterPressed: function(event) { mediaBrowser.openSelected(); event.accepted = true }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Home) {
                                mediaBrowser.chooseIndex(0)
                                event.accepted = true
                            } else if (event.key === Qt.Key_End) {
                                mediaBrowser.chooseIndex(browserList.count - 1)
                                event.accepted = true
                            }
                        }
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        anchors.rightMargin: 18
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOn
                            width: 12
                            contentItem: Rectangle { implicitWidth: 12; radius: 6; color: "#63B8E9" }
                            background: Rectangle { color: "#263B4B"; radius: 6 }
                        }
                        spacing: 3
                        model: mediaBrowser.entries
                        delegate: ItemDelegate {
                            required property int index
                            required property var modelData
                            width: browserList.width
                            height: 46
                            highlighted: !!mediaBrowser.selectedFiles[modelData.path] || mediaBrowser.selectedPath === modelData.path
                            onClicked: {
                                mediaBrowser.selectFile(index, Qt.NoModifier)
                                browserList.forceActiveFocus()
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
                                CheckBox {
                                    visible: !modelData.directory
                                    checked: !!mediaBrowser.selectedFiles[modelData.path]
                                    onClicked: {
                                        mediaBrowser.selectFile(index, Qt.ControlModifier)
                                        browserList.forceActiveFocus()
                                    }
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Select for bulk queue"
                                }
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
                    text: mediaBrowser.selectedFileCount > 1 ? mediaBrowser.selectedFileCount + " files selected" : (mediaBrowser.selectedName.length ? mediaBrowser.selectedName : "Select a media file or folder")
                    color: "#E9F1F7"
                    elide: Text.ElideMiddle
                }
                Button {
                    text: mediaBrowser.selectedFileCount > 1 ? "Add " + mediaBrowser.selectedFileCount + " to queue" : "Add to queue"
                    enabled: mediaBrowser.selectedFileCount > 0 || (mediaBrowser.selectedPath.length > 0 && !mediaBrowser.selectedFolder)
                    onClicked: mediaBrowser.addSelectedToQueue()
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
        id: libraryDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: libraryDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Music library"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 840)
        height: Math.min(window.height - 24, 590)
        standardButtons: Dialog.Close
        Settings {
            id: libraryPreferences
            category: "MusicLibrary"
            property string savedFolder: ""
        }
        property string folder: libraryPreferences.savedFolder.length > 0 ? libraryPreferences.savedFolder : player.locationPath("Music")
        property var songs: []
        property var checkedSongs: ({})
        readonly property int selectedCount: Object.keys(checkedSongs).length
        function setSongChecked(path, checked) {
            const updated = Object.assign({}, checkedSongs)
            if (checked) updated[path] = true
            else delete updated[path]
            checkedSongs = updated
        }
        function setAllVisible(checked) {
            const updated = Object.assign({}, checkedSongs)
            for (const song of visibleSongs) {
                if (checked) updated[song.path] = true
                else delete updated[song.path]
            }
            checkedSongs = updated
        }
        function selectedEntries() {
            return songs.filter(song => checkedSongs[song.path]).map(song => ({path:song.path, name:song.name}))
        }
        property string selectedArtist: ""
        property string selectedAlbum: ""
        Connections {
            target: player
            function onLibraryTagFound(path, artist, album, title) {
                let updated = libraryDialog.songs.slice()
                const i = updated.findIndex(song => song.path === path)
                if (i < 0) return
                updated[i] = Object.assign({}, updated[i], {
                    artist: artist.length ? artist : "Unknown Artist",
                    album: album.length ? album : "Unknown Album",
                    displayTitle: title.length ? title : updated[i].name
                })
                libraryDialog.songs = updated
            }
        }
        property string viewMode: "Songs"
        property string selectedFolder: ""
        property string sortMode: "Name"
        function setFolder(path) {
            folder = path
            libraryPreferences.savedFolder = path
            selectedFolder = ""
            refresh()
        }
        function refresh() {
            songs = player.scanMusicLibrary(folder, librarySearch.text)
            checkedSongs = ({})
            selectedArtist = ""
            selectedAlbum = ""
            player.inspectMusicTags(songs)
        }
        readonly property var folderNames: {
            let found = {}
            for (const song of songs) found[song.folder] = true
            return Object.keys(found).sort()
        }
        readonly property var artistNames: Object.keys(songs.reduce((out, song) => { out[song.artist || "Unknown Artist"] = true; return out }, {})).sort()
        readonly property var albumNames: Object.keys(songs.reduce((out, song) => { out[song.album || "Unknown Album"] = true; return out }, {})).sort()
        readonly property var visibleSongs: {
            let list = songs.filter(song =>
                (viewMode !== "Folders" || selectedFolder === "" || song.folder === selectedFolder) &&
                (viewMode !== "Artists" || selectedArtist === "" || (song.artist || "Unknown Artist") === selectedArtist) &&
                (viewMode !== "Albums" || selectedAlbum === "" || (song.album || "Unknown Album") === selectedAlbum))
            if (sortMode === "Name") return list.slice().sort((a,b) => a.name.localeCompare(b.name))
            return list.slice().sort((a,b) => a.folder.localeCompare(b.folder) || a.name.localeCompare(b.name))
        }
        onOpened: refresh()
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Button { text: "Music"; onClicked: libraryDialog.setFolder(player.locationPath("Music")) }
                Button { text: "Downloads"; onClicked: libraryDialog.setFolder(player.locationPath("Downloads")) }
                Button { text: "Home"; onClicked: libraryDialog.setFolder(player.locationPath("Home")) }
                Button {
                    text: "Up"
                    enabled: libraryDialog.folder !== "/"
                    onClicked: libraryDialog.setFolder(libraryDialog.folder.substring(0, libraryDialog.folder.lastIndexOf("/")) || "/")
                }
                Button { text: "Refresh"; onClicked: libraryDialog.refresh() }
            }
            Label { Layout.fillWidth: true; text: "Library folder: " + libraryDialog.folder; color: "#B7C8D8"; elide: Text.ElideMiddle }
            RowLayout {
                Layout.fillWidth: true
                Button { text: "Songs"; highlighted: libraryDialog.viewMode === "Songs"; onClicked: libraryDialog.viewMode = "Songs" }
                Button { text: "Folders"; highlighted: libraryDialog.viewMode === "Folders"; onClicked: libraryDialog.viewMode = "Folders" }
                Button { text: "Artists"; highlighted: libraryDialog.viewMode === "Artists"; onClicked: libraryDialog.viewMode = "Artists" }
                Button { text: "Albums"; highlighted: libraryDialog.viewMode === "Albums"; onClicked: libraryDialog.viewMode = "Albums" }
                Item { Layout.fillWidth: true }
                Label { text: "Sort"; color: "#B7C8D8" }
                ComboBox {
                    model: ["Name", "Folder"]
                    onActivated: libraryDialog.sortMode = currentText
                }
            }
            TextField {
                id: librarySearch
                Layout.fillWidth: true
                placeholderText: "Search songs in the selected folder…"
                onTextChanged: libraryRefreshDelay.restart()
            }
            Timer { id: libraryRefreshDelay; interval: 350; onTriggered: libraryDialog.refresh() }
            Label {
                color: "#9AB6C9"
                text: libraryDialog.songs.length + " songs indexed in this folder (up to 600)"
            }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: libraryDialog.viewMode === "Folders" ? Math.min(110, libraryDialog.folderNames.length * 40) : 0
                visible: libraryDialog.viewMode === "Folders"
                clip: true
                model: libraryDialog.folderNames
                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    text: modelData
                    highlighted: libraryDialog.selectedFolder === modelData
                    onClicked: libraryDialog.selectedFolder = libraryDialog.selectedFolder === modelData ? "" : modelData
                }
            }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: libraryDialog.viewMode === "Artists" || libraryDialog.viewMode === "Albums" ? 112 : 0
                visible: libraryDialog.viewMode === "Artists" || libraryDialog.viewMode === "Albums"
                clip: true
                model: libraryDialog.viewMode === "Artists" ? libraryDialog.artistNames : libraryDialog.albumNames
                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    text: modelData
                    highlighted: libraryDialog.viewMode === "Artists" ?
                                 libraryDialog.selectedArtist === modelData : libraryDialog.selectedAlbum === modelData
                    onClicked: {
                        if (libraryDialog.viewMode === "Artists")
                            libraryDialog.selectedArtist = libraryDialog.selectedArtist === modelData ? "" : modelData
                        else
                            libraryDialog.selectedAlbum = libraryDialog.selectedAlbum === modelData ? "" : modelData
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Select all shown"
                    enabled: libraryDialog.visibleSongs.length > 0
                    onClicked: libraryDialog.setAllVisible(true)
                }
                Button {
                    text: "Clear selection"
                    enabled: libraryDialog.selectedCount > 0
                    onClicked: libraryDialog.checkedSongs = ({})
                }
                Label {
                    text: libraryDialog.selectedCount + " selected"
                    color: "#B7C8D8"
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Add selected to queue"
                    enabled: libraryDialog.selectedCount > 0
                    onClicked: {
                        for (const entry of libraryDialog.selectedEntries())
                            window.enqueue(entry.path, entry.name, false)
                        libraryDialog.checkedSongs = ({})
                    }
                }
                Button {
                    text: "Add selected to playlist"
                    enabled: libraryDialog.selectedCount > 0
                    onClicked: {
                        window.pendingPlaylistEntries = libraryDialog.selectedEntries()
                        window.pendingPlaylistEntry = null
                        libraryDialog.close()
                        namedPlaylistsDialog.open()
                    }
                }
            }
            ListView {
                id: songsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: libraryDialog.visibleSongs
                delegate: ItemDelegate {
                    required property var modelData
                    width: songsList.width
                    contentItem: RowLayout {
                        CheckBox {
                            checked: !!libraryDialog.checkedSongs[modelData.path]
                            onToggled: libraryDialog.setSongChecked(modelData.path, checked)
                            ToolTip.visible: hovered
                            ToolTip.text: "Select this track for bulk actions"
                        }
                        Label { Layout.fillWidth: true; text: (modelData.displayTitle || modelData.name) + (modelData.artist ? "  ·  " + modelData.artist : ""); color: "#E9F1F7"; elide: Text.ElideMiddle }
                        Button { text: "Play"; onClicked: { window.enqueue(modelData.path, modelData.name, true); libraryDialog.close() } }
                        Button { text: "Add to queue"; onClicked: window.enqueue(modelData.path, modelData.name, false) }
                        Button {
                            text: "Playlist +"
                            onClicked: {
                                window.pendingPlaylistEntry = {path: modelData.path, name: modelData.name}
                                window.pendingPlaylistEntries = []
                                libraryDialog.close()
                                namedPlaylistsDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
    Dialog {
        id: namedPlaylistsDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: namedPlaylistsDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "My playlists"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 650)
        height: Math.min(window.height - 24, 530)
        standardButtons: Dialog.Close
        onClosed: {
            window.pendingPlaylistEntry = null
            window.pendingPlaylistEntries = []
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                TextField { id: newPlaylistName; Layout.fillWidth: true; placeholderText: "Playlist name"; maximumLength: 80 }
                Button {
                    text: "Create"
                    enabled: newPlaylistName.text.trim().length > 0
                    onClicked: {
                        const name = newPlaylistName.text.trim()
                        if (!Object.prototype.hasOwnProperty.call(window.namedPlaylists, name)) window.saveNamedPlaylist(name, [])
                        newPlaylistName.text = ""
                    }
                }
                Button {
                    text: "Save queue as"
                    enabled: newPlaylistName.text.trim().length > 0 && window.mediaQueue.length > 0
                    onClicked: { window.saveNamedPlaylist(newPlaylistName.text, window.mediaQueue); newPlaylistName.text = "" }
                }
            }
            Label {
                text: window.pendingPlaylistEntries.length > 0 ? "Add " + window.pendingPlaylistEntries.length + " selected songs to a playlist" : (window.pendingPlaylistEntry ? "Select a playlist for " + window.pendingPlaylistEntry.name : "Named playlists are saved locally.")
                color: "#B7C8D8"
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
            ListView {
                id: namedPlaylistList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: Object.keys(window.namedPlaylists).sort()
                delegate: ItemDelegate {
                    required property var modelData
                    width: namedPlaylistList.width
                    contentItem: RowLayout {
                        Label {
                            Layout.fillWidth: true
                            text: modelData + " (" + window.namedPlaylists[modelData].length + ")"
                            color: "#E9F1F7"
                            elide: Text.ElideMiddle
                        }
                        Button {
                            text: window.pendingPlaylistEntry || window.pendingPlaylistEntries.length > 0 ? "Add" : "Load"
                            onClicked: {
                                if (window.pendingPlaylistEntry || window.pendingPlaylistEntries.length > 0) {
                                    let entries = window.namedPlaylists[modelData].slice()
                                    const additions = window.pendingPlaylistEntries.length > 0 ?
                                                      window.pendingPlaylistEntries : [window.pendingPlaylistEntry]
                                    for (const song of additions) {
                                        if (song && !entries.some(e => e.path === song.path))
                                            entries.push(song)
                                    }
                                    window.saveNamedPlaylist(modelData, entries)
                                    window.pendingPlaylistEntry = null
                                    window.pendingPlaylistEntries = []
                                } else {
                                    window.loadNamedPlaylist(modelData, false)
                                    namedPlaylistsDialog.close()
                                }
                            }
                        }
                        Button {
                            text: "Play"
                            enabled: window.namedPlaylists[modelData].length > 0
                            onClicked: { window.pendingPlaylistEntry = null; window.loadNamedPlaylist(modelData, true); namedPlaylistsDialog.close() }
                        }
                        Button { text: "Edit"; onClicked: { window.activePlaylist = modelData; playlistEditor.open() } }
                        Button { text: "Delete"; onClicked: window.deleteNamedPlaylist(modelData) }
                    }
                }
            }
        }
    }
    Dialog {
        id: playlistEditor
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: playlistEditor.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Edit playlist: " + window.activePlaylist
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 590)
        height: Math.min(window.height - 24, 480)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent
            RowLayout {
                Layout.fillWidth: true
                TextField { id: renamePlaylistField; Layout.fillWidth: true; placeholderText: window.activePlaylist }
                Button {
                    text: "Rename"
                    onClicked: {
                        const oldName = window.activePlaylist
                        const newName = renamePlaylistField.text.trim()
                        if (newName && newName !== oldName && !Object.prototype.hasOwnProperty.call(window.namedPlaylists, newName)) {
                            window.saveNamedPlaylist(newName, window.namedPlaylists[oldName])
                            window.deleteNamedPlaylist(oldName)
                            window.activePlaylist = newName
                            renamePlaylistField.text = ""
                        }
                    }
                }
            }
            ListView {
                id: playlistTracks
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: window.namedPlaylists[window.activePlaylist] || []
                delegate: ItemDelegate {
                    required property var modelData
                    required property int index
                    width: playlistTracks.width
                    contentItem: RowLayout {
                        Label { Layout.fillWidth: true; text: modelData.name; color: "#E9F1F7"; elide: Text.ElideMiddle }
                        Button {
                            text: "Remove"
                            onClicked: {
                                const entries = window.namedPlaylists[window.activePlaylist].slice()
                                entries.splice(index, 1)
                                window.saveNamedPlaylist(window.activePlaylist, entries)
                            }
                        }
                    }
                }
            }
        }
    }
    Dialog {
        id: queueDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: queueDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
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
        id: coverChooser
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: coverChooser.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        title: "Choose album artwork"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 720)
        height: Math.min(window.height - 24, 540)
        padding: 16
        standardButtons: Dialog.Close
        property string folder: player.locationPath("Pictures")
        property var entries: []
        property string selectedPath: ""
        function navigate(path) {
            folder = path
            selectedPath = ""
            entries = player.browseCoverImages(path)
        }
        onOpened: navigate(folder)
        background: Rectangle { color: "#1B2836"; radius: 10; border.color: "#35475A" }
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Button { text: "Pictures"; onClicked: coverChooser.navigate(player.locationPath("Pictures")) }
                Button { text: "Downloads"; onClicked: coverChooser.navigate(player.locationPath("Downloads")) }
                Button { text: "Home"; onClicked: coverChooser.navigate(player.locationPath("Home")) }
                Button {
                    text: "Up"
                    enabled: coverChooser.folder !== "/"
                    onClicked: coverChooser.navigate(coverChooser.folder.substring(0, coverChooser.folder.lastIndexOf("/")) || "/")
                }
            }
            Label { text: coverChooser.folder; color: "#C1D5E4"; Layout.fillWidth: true; elide: Text.ElideMiddle }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#172532"
                radius: 7
                ListView {
                    id: coverFileList
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    model: coverChooser.entries
                    delegate: ItemDelegate {
                        required property var modelData
                        width: coverFileList.width
                        highlighted: coverChooser.selectedPath === modelData.path
                        text: (modelData.directory ? "📁 " : "▣ ") + modelData.name
                        onClicked: {
                            if (modelData.directory) coverChooser.navigate(modelData.path)
                            else coverChooser.selectedPath = modelData.path
                        }
                        onDoubleClicked: {
                            if (modelData.directory) coverChooser.navigate(modelData.path)
                            else { editTags.coverPath = "file://" + modelData.path; coverChooser.close() }
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: coverFileList.count === 0
                    color: "#9BB0C1"
                    text: "No JPG or PNG images in this folder"
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    color: "#D8E9F4"
                    elide: Text.ElideMiddle
                    text: coverChooser.selectedPath.length ? coverChooser.selectedPath.split("/").pop() : "Choose a JPG or PNG cover"
                }
                Button {
                    text: "Use this cover"
                    enabled: coverChooser.selectedPath.length > 0
                    onClicked: {
                        editTags.coverPath = "file://" + coverChooser.selectedPath
                        coverChooser.close()
                    }
                }
            }
        }
    }
    Dialog {
        id: editTags
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: editTags.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Edit music information"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 470)
        standardButtons: Dialog.Cancel
        property string feedback: ""
        property string coverPath: ""
        property bool saving: false
        onOpened: {
            titleField.text = player.songTitle
            artistField.text = player.artist
            albumField.text = player.album
            outputNameField.text = player.title.substring(0, player.title.lastIndexOf(".") >= 0 ? player.title.lastIndexOf(".") : player.title.length) + "-edited"
            feedback = ""
            coverPath = ""
            saving = false
        }
        Connections {
            target: player
            function onTagSaveFinished(success, message) {
                editTags.feedback = message
                editTags.saving = false
            }
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            Label { text: "Save a tagged copy; your original file stays unchanged."; color: "#B7C8D8"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Label { text: "Title"; color: "#E9F1F7" }
            TextField { id: titleField; Layout.fillWidth: true; selectByMouse: true }
            Label { text: "Artist"; color: "#E9F1F7" }
            TextField { id: artistField; Layout.fillWidth: true; selectByMouse: true }
            Label { text: "Album"; color: "#E9F1F7" }
            TextField { id: albumField; Layout.fillWidth: true; selectByMouse: true }
            Label { text: "Album artwork (optional, MP3 only)"; color: "#E9F1F7" }
            RowLayout {
                Layout.fillWidth: true
                Button { text: "Choose cover image"; onClicked: coverChooser.open() }
                Button { text: "Clear"; enabled: editTags.coverPath.length > 0; onClicked: editTags.coverPath = "" }
            }
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                source: editTags.coverPath.length ? editTags.coverPath : player.artworkUrl
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: source.toString().length > 0 && status === Image.Ready
            }
            Label { text: "Save As filename (same folder)"; color: "#E9F1F7" }
            TextField { id: outputNameField; Layout.fillWidth: true; placeholderText: "new-file-name"; selectByMouse: true }
            Button {
                text: editTags.saving ? "Saving…" : "Save edited copy"
                enabled: !editTags.saving
                Layout.alignment: Qt.AlignRight
                onClicked: { editTags.saving = true; player.saveMusicTags(titleField.text, artistField.text, albumField.text, editTags.coverPath, outputNameField.text) }
            }
            Label { text: editTags.feedback; color: "#B7C8D8"; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
        }
    }
    Dialog {
        id: aboutPlayerDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: aboutPlayerDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "About Jatayu Media Player"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 600)
        height: Math.min(window.height - 24, 590)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            Image { source: "qrc:/icons/jatayu-media-player.svg"; Layout.preferredWidth: 68; Layout.preferredHeight: 68; Layout.alignment: Qt.AlignHCenter; fillMode: Image.PreserveAspectFit }
            Label { text: "Jatayu Media Player"; font.pixelSize: 23; font.bold: true; color: "#E9F1F7"; Layout.alignment: Qt.AlignHCenter }
            Label { text: "Version 1.0.0  •  Your Media. Your World."; color: "#9FC1D7"; Layout.alignment: Qt.AlignHCenter }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ColumnLayout {
                    width: aboutPlayerDialog.availableWidth - 16
                    spacing: 10
                    Label { Layout.fillWidth: true; text: "A modern, privacy-focused Linux music and video player powered by Qt 6 and libmpv. Enjoy local playback without ads, built-in telemetry or mandatory accounts."; color: "#D3E2EF"; wrapMode: Text.WordWrap }
                    Label { Layout.fillWidth: true; text: "PROJECT INFORMATION"; font.bold: true; color: "#58CBEF" }
                    Label { Layout.fillWidth: true; text: "Creator: Anup Yadav\nPlatform: Linux (Debian package and Flatpak)\nLicense: GPL-3.0-or-later\nWebsite: jatayuos.in\nRepository: github.com/jatayuos4u/jatayu-media-player"; color: "#D3E2EF"; wrapMode: Text.WrapAnywhere }
                    Label { Layout.fillWidth: true; text: "OPEN SOURCE AND PRIVACY"; font.bold: true; color: "#58CBEF" }
                    Label { Layout.fillWidth: true; text: "Jatayu Media Player is an independent open-source project. Qt, libmpv and other third-party components retain their respective licenses. Files are played locally; the application does not include advertising or built-in telemetry."; color: "#D3E2EF"; wrapMode: Text.WordWrap }
                }
            }
            Flow {
                Layout.fillWidth: true; spacing: 8
                Button { text: "Website"; onClicked: Qt.openUrlExternally("https://jatayuos.in") }
                Button { text: "Source and license"; onClicked: Qt.openUrlExternally("https://github.com/jatayuos4u/jatayu-media-player") }
                Button { text: "Report an issue"; onClicked: Qt.openUrlExternally("https://github.com/jatayuos4u/jatayu-media-player/issues") }
            }
        }
    }
    Dialog {
        id: gettingStartedDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: gettingStartedDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Getting started"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 610)
        height: Math.min(window.height - 24, 540)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { text: "Make the most of your music and videos"; font.pixelSize: 16; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ColumnLayout {
                    width: gettingStartedDialog.availableWidth - 16; spacing: 12
                    Label { text: "1. Open and play"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Choose Browse media (Ctrl+O) to find your local video or audio files. Space pauses playback, arrow keys seek and F switches fullscreen."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "2. Organize your music"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Open More > Music library to browse tracks. Use Queue to manage upcoming songs and My playlists to save collections."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "3. Fine-tune playback"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Open More > Audio tracks and speed for track selection and playback speed. For slower computers, choose Quality: Performance."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "4. Subtitles and video"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Use More > Load subtitles for local subtitle files and Subtitle settings for caption controls."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "5. Edit music information"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Choose More > Edit music information for supported audio files. Save edits as a new copy so the original stays unchanged."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "6. Personalize and get help"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Open More > Preferences for playback and privacy settings. Use Help for keyboard shortcuts, troubleshooting and support."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
            Flow { Layout.fillWidth: true; spacing: 8
                Button { text: "Browse media"; onClicked: { gettingStartedDialog.close(); mediaBrowser.open() } }
                Button { text: "Music library"; onClicked: { gettingStartedDialog.close(); libraryDialog.open() } }
                Button { text: "Shortcuts"; onClicked: { gettingStartedDialog.close(); shortcutsHelp.open() } }
            }
        }
    }
    Dialog {
        id: troubleshootingDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: troubleshootingDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Troubleshooting and support"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 650)
        height: Math.min(window.height - 24, 560)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { text: "Practical fixes for common playback problems"; color: "#9FC1D7"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ColumnLayout {
                    width: troubleshootingDialog.availableWidth - 16; spacing: 12
                    Label { text: "Playback and sound"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "No sound: check the player mute and volume controls, then your system output device. Confirm that the correct audio track is selected in Audio tracks and speed. Try a second file to rule out damaged media."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "Black video or stuttering"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Try Performance quality under More, close demanding applications and play a file stored locally. Check whether the same file works with another player. On older graphics hardware, high-resolution or high-bitrate video may be too demanding."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "Files do not open"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Confirm the file exists and that you have permission to read it. Use Browse media rather than manually entering a path. In Flatpak, files outside the permitted home, /media and /run/media locations may not be accessible."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "Subtitles are missing"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Use More > Load subtitles and choose a matching .srt, .ass, .ssa or .vtt file. Check subtitle track selection, visibility and timing; the chosen subtitle may not match the video release."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "Library, playlists or cover art"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Refresh or revisit the music library and check your folder selection and search filters. Artwork is not embedded in every file. When editing music information, Jatayu Media Player writes a new copy to protect the original; reopen the edited copy to verify changes."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "Reporting an issue"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Include your Linux distribution, whether you installed the Debian package or Flatpak, the media format and the exact steps to reproduce. Launch the app from a terminal, capture relevant errors and remove personal paths or private data before sharing logs."; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
            Flow { Layout.fillWidth: true; spacing: 8
                Button { text: "Report an issue"; onClicked: Qt.openUrlExternally("https://github.com/jatayuos4u/jatayu-media-player/issues/new") }
                Button { text: "Documentation"; onClicked: Qt.openUrlExternally("https://github.com/jatayuos4u/jatayu-media-player#readme") }
                Button { text: "Website"; onClicked: Qt.openUrlExternally("https://jatayuos.in") }
            }
        }
    }
    Dialog {
        id: shortcutsHelp
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: shortcutsHelp.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Keyboard shortcuts"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 580)
        height: Math.min(window.height - 24, 500)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { text: "Quick controls for playback and navigation"; color: "#9FC1D7"; Layout.fillWidth: true }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ColumnLayout {
                    width: shortcutsHelp.availableWidth - 16; spacing: 12
                    Label { text: "PLAYBACK"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Space  Play / pause\\n← / →  Seek back / forward 5 seconds\\nCtrl+← / Ctrl+→  Seek 30 seconds\\n↑ / ↓  Adjust volume by 5%\\nCtrl+0  Reset speed\\nCtrl+Plus / Ctrl+Minus  Adjust speed"; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "MEDIA AND LIBRARY"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "Ctrl+O  Browse media\\nCtrl+F  Search media in the browser\\nCtrl+L  Music library\\nCtrl+P  My playlists\\nCtrl+Shift+P  Playback options"; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { text: "DISPLAY"; font.bold: true; color: "#E9F1F7"; Layout.fillWidth: true }
                    Label { text: "F  Toggle fullscreen\\nEscape  Exit fullscreen"; color: "#C1D3E2"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
            Button { text: "Getting started"; Layout.alignment: Qt.AlignRight; onClicked: { shortcutsHelp.close(); gettingStartedDialog.open() } }
        }
    }
    Dialog {
        id: mediaInfoDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: mediaInfoDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Media information"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 560)
        height: Math.min(window.height - 24, 450)
        standardButtons: Dialog.Close
        onOpened: mediaInfoText.text = player.mediaInformation()
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            Label { text: "Local file and stream details"; color: "#B7C8D8" }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                TextArea {
                    id: mediaInfoText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    color: "#E9F1F7"
                    background: Rectangle { color: "#172532"; radius: 6 }
                }
            }
            Button { text: "Refresh"; onClicked: mediaInfoText.text = player.mediaInformation() }
        }
    }
    Settings {
        id: userPreferences
        category: "UserPreferences"
        property bool resumeEnabled: true
        property bool rememberQueue: true
        property bool showHelpHints: true
    }
    Dialog {
        id: preferencesDialog
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: preferencesDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        title: "Preferences"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 800)
        height: Math.min(window.height - 24, 545)
        standardButtons: Dialog.Close
        property int section: 0
        readonly property var pages: ["General", "Playback", "Audio", "Video", "Subtitles", "Library", "Shortcuts", "Privacy"]
        background: Rectangle { color: "#151F2B"; border.color: "#35475A"; radius: 10 }
        RowLayout {
            anchors.fill: parent
            spacing: 12
            Rectangle {
                Layout.preferredWidth: Math.min(170, preferencesDialog.width * 0.28)
                Layout.fillHeight: true
                color: "#182A3C"
                radius: 7
                ListView {
                    id: preferencesNavigation
                    anchors.fill: parent
                    anchors.margins: 6
                    clip: true
                    model: preferencesDialog.pages
                    delegate: ItemDelegate {
                        required property int index
                        required property string modelData
                        width: preferencesNavigation.width
                        text: modelData
                        highlighted: preferencesDialog.section === index
                        onClicked: preferencesDialog.section = index
                    }
                }
            }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: preferencesDialog.section
                ColumnLayout {
                    spacing: 12
                    Label { text: "General"; font.pixelSize: 19; color: "#E9F1F7" }
                    CheckBox {
                        text: "Show helpful interface hints"
                        checked: userPreferences.showHelpHints
                        onToggled: userPreferences.showHelpHints = checked
                    }
                    Label { text: "Private local playback without an account."; color: "#C0D3DF" }
                    Button { text: "Restore playback and interface defaults"; onClicked: resetPreferencesConfirm.open() }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#9CB1C4"
                        text: "Resets volume, playback speed, video quality, resume and queue preferences, and interface hints. Your songs and saved playlists are not deleted."
                    }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Playback"; font.pixelSize: 19; color: "#E9F1F7" }
                    CheckBox {
                        text: "Resume longer media files"
                        checked: userPreferences.resumeEnabled
                        onToggled: userPreferences.resumeEnabled = checked
                    }
                    CheckBox {
                        text: "Remember playback queue"
                        checked: userPreferences.rememberQueue
                        onToggled: userPreferences.rememberQueue = checked
                    }
                    Label { text: "Speed: " + Number(player.playbackSpeed.toFixed(2)) + "×"; color: "#C0D3DF" }
                    RowLayout {
                        Layout.fillWidth: true
                        Button { text: "0.75×"; onClicked: player.setPlaybackSpeed(0.75) }
                        Button { text: "1×"; onClicked: player.setPlaybackSpeed(1) }
                        Button { text: "1.25×"; onClicked: player.setPlaybackSpeed(1.25) }
                        Button { text: "1.5×"; onClicked: player.setPlaybackSpeed(1.5) }
                    }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Audio"; font.pixelSize: 19; color: "#E9F1F7" }
                    Label { text: "Volume: " + Math.round(player.volume) + "%"; color: "#C0D3DF" }
                    Slider { Layout.fillWidth: true; from: 0; to: 100; value: player.volume; onMoved: player.setVolume(value) }
                    Label { text: "Audio tracks: " + player.audioTracks.length; color: "#C0D3DF" }
                    Button { text: "Open audio track selector"; onClicked: { preferencesDialog.close(); playbackOptions.open() } }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Video"; font.pixelSize: 19; color: "#E9F1F7" }
                    Label { text: "Video scaling quality"; color: "#C0D3DF" }
                    ComboBox {
                        Layout.fillWidth: true
                        model: ["Performance", "Balanced"]
                        currentIndex: player.qualityProfile === "Performance" ? 0 : 1
                        onActivated: player.setQualityProfile(currentText)
                    }
                    Label {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap
                        text: "Advanced GPU profiles are unavailable until tested on more hardware."
                        color: "#C0D3DF"
                    }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Subtitles"; font.pixelSize: 19; color: "#E9F1F7" }
                    Button { text: "Open subtitle appearance and delay"; onClicked: { preferencesDialog.close(); captionTools.open() } }
                    Button { text: "Load subtitle file"; onClicked: { preferencesDialog.close(); subtitleDialog.open() } }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Music library"; font.pixelSize: 19; color: "#E9F1F7" }
                    Button { text: "Browse library and refresh songs"; onClicked: { preferencesDialog.close(); libraryDialog.open() } }
                    Button { text: "Manage playlists"; onClicked: { preferencesDialog.close(); namedPlaylistsDialog.open() } }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Keyboard shortcuts"; font.pixelSize: 19; color: "#E9F1F7" }
                    Label { text: "Use Space for play/pause, F for fullscreen, and arrow keys to seek."; color: "#C0D3DF"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Button { text: "View all shortcuts"; onClicked: { preferencesDialog.close(); shortcutsHelp.open() } }
                    Item { Layout.fillHeight: true }
                }
                ColumnLayout {
                    spacing: 12
                    Label { text: "Privacy"; font.pixelSize: 19; color: "#E9F1F7" }
                    Label {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#C0D3DF"
                        text: "No built-in advertising or telemetry. Media history, playlists, and preferences remain on this computer."
                    }
                    Button { text: "View recent files"; onClicked: { preferencesDialog.close(); mediaBrowser.open(); mediaBrowser.showRecent() } }
                    Button { text: "Clear recent-file history…"; onClicked: clearRecentConfirm.open() }
                    Button { text: "Clear saved playback positions…"; onClicked: clearResumeConfirm.open() }
                    Label {
                        Layout.fillWidth: true
                        color: "#9CB1C4"
                        wrapMode: Text.WordWrap
                        text: "These actions only remove Jatayu Media Player's stored history. Original media files, album artwork and named playlists are not deleted."
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
    Dialog {
        id: clearRecentConfirm
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: clearRecentConfirm.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Clear recent files?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: player.clearRecentMedia()
        Label { text: "Remove the locally stored recent-file list?\nYour media files will remain untouched."; color: "#E9F1F7"; wrapMode: Text.WordWrap; width: 330 }
    }
    Dialog {
        id: clearResumeConfirm
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: clearResumeConfirm.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Clear resume positions?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: player.clearResumePositions()
        Label { text: "Forget all saved playback positions?\nYour songs, videos and playlists remain untouched."; color: "#E9F1F7"; wrapMode: Text.WordWrap; width: 330 }
    }
    Dialog {
        id: resetPreferencesConfirm
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: resetPreferencesConfirm.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Restore default preferences?"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Yes | Dialog.Cancel
        onAccepted: {
            userPreferences.resumeEnabled = true
            userPreferences.rememberQueue = true
            userPreferences.showHelpHints = true
            player.resetPlaybackPreferences()
        }
        Label { text: "Restore default playback settings and interface hints?\nThis does not remove media or named playlists."; color: "#E9F1F7"; wrapMode: Text.WordWrap; width: 350 }
    }
    Dialog {
        id: playbackOptions
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: playbackOptions.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
        title: "Playback options"
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(window.width - 24, 440)
        standardButtons: Dialog.Close
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            Label { text: "Playback speed"; color: "#E9F1F7" }
            RowLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: speedPicker
                    Layout.fillWidth: true
                    model: ["0.5×", "0.75×", "1×", "1.25×", "1.5×", "1.75×", "2×"]
                    currentIndex: {
                        const values = [0.5,0.75,1,1.25,1.5,1.75,2]
                        let closest = 0
                        for (let i = 1; i < values.length; ++i)
                            if (Math.abs(values[i] - player.playbackSpeed) < Math.abs(values[closest] - player.playbackSpeed)) closest = i
                        return closest
                    }
                    onActivated: player.setPlaybackSpeed([0.5,0.75,1,1.25,1.5,1.75,2][currentIndex])
                }
                Button { text: "Reset"; onClicked: player.setPlaybackSpeed(1.0) }
            }
            Label { text: "Audio track"; color: "#E9F1F7" }
            Label {
                Layout.fillWidth: true
                text: player.audioTracks.length === 0 ? "No audio tracks available" : player.audioTracks.length + " available audio tracks"
                color: "#B7C8D8"
            }
            Repeater {
                model: player.audioTracks
                Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: (player.selectedAudioTrack === modelData.id ? "✓  " : "") + modelData.label
                    onClicked: player.selectAudioTrack(modelData.id)
                }
            }
            Button {
                text: "Disable audio"
                enabled: player.audioTracks.length > 0
                onClicked: player.selectAudioTrack(-1)
            }
        }
    }
    Dialog {
        id: captionTools
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: captionTools.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
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
        // Explicit title color: some Qt themes otherwise draw dark text on dark dialogs.
        header: Label {
            text: subtitleDialog.title
            color: "#E9F1F7"
            font.bold: true
            font.pixelSize: 16
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            background: Rectangle { color: "transparent" }
        }
        // Do not inherit a light popup background from the host distribution.
        background: Rectangle { color: "#152330"; border.color: "#35475A"; radius: 10 }
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
    Shortcut { sequence: "Ctrl+L"; onActivated: libraryDialog.open() }
    Shortcut { sequence: "Ctrl+P"; onActivated: namedPlaylistsDialog.open() }
    Shortcut { sequence: "Ctrl+Shift+P"; onActivated: playbackOptions.open() }
    Shortcut { sequence: "Ctrl+Right"; onActivated: player.seekRelative(30) }
    Shortcut { sequence: "Ctrl+Left"; onActivated: player.seekRelative(-30) }
    Shortcut { sequence: "Up"; onActivated: player.setVolume(Math.min(100, player.volume + 5)) }
    Shortcut { sequence: "Down"; onActivated: player.setVolume(Math.max(0, player.volume - 5)) }
    Shortcut { sequence: "Ctrl+0"; onActivated: player.setPlaybackSpeed(1.0) }
    Shortcut { sequence: "Ctrl+Plus"; onActivated: player.setPlaybackSpeed(Math.min(2, player.playbackSpeed + 0.25)) }
    Shortcut { sequence: "Ctrl+Minus"; onActivated: player.setPlaybackSpeed(Math.max(0.5, player.playbackSpeed - 0.25)) }
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
                    Label { text: player.title === "No media selected" ? "Your Media. Your World." : player.title; color: "#97ADBF"; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.maximumWidth: 350 }
                }
                Item { Layout.fillWidth: true }
                Button { text: "Browse media"; onClicked: mediaBrowser.open() }
                Button { text: "Queue (" + mediaQueue.length + ")"; onClicked: queueDialog.open() }
                Button { text: window.musicMode ? "Video view" : "Music view"; onClicked: { window.forceVideoMode = window.musicMode; window.forceMusicMode = !window.forceVideoMode } }
                Button { text: "Recent"; visible: window.width >= 1450; onClicked: { mediaBrowser.open(); mediaBrowser.showRecent() } }
                Label { text: "Quality"; visible: window.width >= 1450; color: "#9BB0C1" }
                ComboBox {
                    id: videoQualityPicker
                    visible: window.width >= 1450
                    Layout.preferredWidth: 144
                    model: ["Performance", "Balanced"]
                    currentIndex: Math.max(0, model.indexOf(player.qualityProfile))
                    onActivated: player.setQualityProfile(currentText)
                    ToolTip.visible: hovered
                    ToolTip.text: "High Quality is temporarily disabled pending graphics stability testing."
                }
                Button { text: "Subtitles"; visible: window.width >= 1450; onClicked: subtitleDialog.open() }
                Button { text: "Caption tools"; visible: window.width >= 1450; onClicked: captionTools.open() }
                Button { text: "Help ▾"; onClicked: helpMenu.popup() }
                Menu {
                    id: helpMenu
                    MenuItem { text: "Getting started"; onTriggered: gettingStartedDialog.open() }
                    MenuItem { text: "Keyboard shortcuts"; onTriggered: shortcutsHelp.open() }
                    MenuItem { text: "Troubleshooting"; onTriggered: troubleshootingDialog.open() }
                    MenuSeparator {}
                    MenuItem { text: "Documentation"; onTriggered: Qt.openUrlExternally("https://github.com/jatayuos4u/jatayu-media-player#readme") }
                    MenuItem { text: "Report an issue"; onTriggered: Qt.openUrlExternally("https://github.com/jatayuos4u/jatayu-media-player/issues") }
                    MenuItem { text: "About Jatayu Media Player"; onTriggered: aboutPlayerDialog.open() }
                }
                Button { text: "More ▾"; onClicked: toolsMenu.popup() }
                Menu {
                    id: toolsMenu
                    MenuItem { text: "Music library"; onTriggered: libraryDialog.open() }
                    MenuItem { text: "My playlists"; onTriggered: namedPlaylistsDialog.open() }
                    MenuItem { text: "Recent files"; onTriggered: { mediaBrowser.open(); mediaBrowser.showRecent() } }
                    MenuItem { text: "Edit music information"; enabled: window.audioTrack; onTriggered: editTags.open() }
                    MenuItem { text: "Load subtitles"; onTriggered: subtitleDialog.open() }
                    MenuItem { text: "Subtitle settings"; onTriggered: captionTools.open() }
                    MenuItem { text: "Audio tracks and speed"; onTriggered: playbackOptions.open() }
                    MenuItem { text: "Preferences"; onTriggered: preferencesDialog.open() }
                    MenuItem { text: "Media information"; onTriggered: mediaInfoDialog.open() }
                    MenuItem { text: "Quality: Performance"; onTriggered: player.setQualityProfile("Performance") }
                    MenuItem { text: "Quality: Balanced"; onTriggered: player.setQualityProfile("Balanced") }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#070B0F"
            MpvVideoItem { id: video; anchors.fill: parent; controller: player }
            Rectangle {
                id: musicStage
                anchors.fill: parent
                visible: window.musicMode
                color: "#101C2B"
                property bool animating: visible && !player.paused && player.title !== "No media selected"
                // Decorative animation, not an audio spectrum analyzer.
                // Only six lightweight bars run; no render-loop timers or shaders.
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 560)
                    spacing: Math.max(9, Math.min(16, parent.height / 38))
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 190
                        Layout.preferredHeight: 190
                        Rectangle {
                            id: artworkHalo
                            anchors.centerIn: parent
                            width: 184; height: 184
                            radius: 92
                            color: "#113C5C"
                            border.color: "#246994"
                            border.width: 2
                            opacity: 0.7
                            scale: 1.0
                            SequentialAnimation on scale {
                                running: musicStage.animating
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.065; duration: 1800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                                onStopped: artworkHalo.scale = 1.0
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 160; height: 160
                            radius: 26
                            color: "#173D5B"
                            border.color: "#2B96CD"
                            border.width: 1
                            clip: true
                            Image {
                                id: embeddedCover
                                anchors.fill: parent
                                source: player.artworkUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                visible: status === Image.Ready && player.artworkUrl.length > 0
                            }
                            Label {
                                anchors.centerIn: parent
                                visible: !embeddedCover.visible
                                text: "♫"
                                color: "#66E5FA"
                                font.pixelSize: 91
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: player.title === "No media selected" ? "Your music, your way" : player.songTitle
                        font.pixelSize: 25
                        font.bold: true
                        color: "#F0F8FF"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: (player.artist.length ? player.artist : "Artist not tagged") + (player.album.length ? "  •  " + player.album : "")
                        font.pixelSize: 13
                        color: "#A7C4D6"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        height: 31
                        spacing: 7
                        Repeater {
                            model: 7
                            Rectangle {
                                required property int index
                                width: 6
                                height: musicStage.animating ? 10 + ((index * 11) % 18) : 5
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: index % 2 ? "#33B9EF" : "#5CE5F2"
                                opacity: musicStage.animating ? 0.95 : 0.45
                                SequentialAnimation on height {
                                    running: musicStage.animating
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 7 + ((index * 7) % 19)
                                        duration: 500 + index * 95
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 22 + ((index * 3) % 9)
                                        duration: 570 + index * 73
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }
                        }
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
            Layout.fillWidth: true; Layout.preferredHeight: player.error.length && !window.errorBannerDismissed ? 34 : 0
            color: "#6D2626"; visible: player.error.length > 0 && !window.errorBannerDismissed
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                Label {
                    Layout.fillWidth: true
                    text: player.error
                    color: "white"
                    elide: Text.ElideRight
                }
                Button { text: "Dismiss"; onClicked: errorBannerDismissed = true }
            }
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
                    spacing: window.width < 1200 ? 5 : 12
                    Button { text: "↶10"; onClicked: player.seekRelative(-10) }
                    Button { text: player.paused ? "▶ Play" : "Ⅱ Pause"; highlighted: true; onClicked: player.togglePause() }
                    Button { text: "Stop"; onClicked: player.stop() }
                    Button { text: window.width < 1200 ? "◀" : "Previous"; enabled: queueIndex > 0; onClicked: skipQueue(-1) }
                    Button { text: window.width < 1200 ? "▶" : "Next"; enabled: queueIndex >= 0 && queueIndex < mediaQueue.length - 1; onClicked: skipQueue(1) }
                    Button { text: "10↷"; onClicked: player.seekRelative(10) }
                    Label {
                        text: formatTime(player.position) + " / " + formatTime(player.duration)
                        color: window.textColor
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: Number(player.playbackSpeed.toFixed(2)).toString() + "×"
                        onClicked: playbackOptions.open()
                        ToolTip.visible: hovered
                        ToolTip.text: "Playback speed and audio tracks"
                    }
                    Label { text: "Volume"; visible: window.width >= 1200; color: window.muted }
                    Slider { Layout.preferredWidth: window.width < 1200 ? 75 : 120; from: 0; to: 100; value: player.volume; onMoved: player.setVolume(value) }
                    Button {
                        text: window.width < 1200 ? "⛶" : "⛶ Fullscreen"
                        Layout.minimumWidth: 40
                        onClicked: window.toggleCinema()
                        ToolTip.visible: hovered
                        ToolTip.text: "Toggle fullscreen (F)"
                    }
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
