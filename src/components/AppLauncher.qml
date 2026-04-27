import Quickshell
import QtQuick
import QtQuick.Controls

import "../state"

Item {
    id: root

    property bool active: false

    implicitWidth: 720
    implicitHeight: 620

    function focusSearch() {
        if (!root.active) {
            return
        }

        Qt.callLater(function() {
            searchInput.forceActiveFocus()
            searchInput.selectAll()
        })
    }

    function activateSelection() {
        const entry = appModel.values[LauncherState.selectedIndex]

        if (entry) {
            LauncherState.launchEntry(entry)
        }
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            LauncherState.hide()
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Down) {
            LauncherState.moveSelection(1, appModel.values.length)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Up) {
            LauncherState.moveSelection(-1, appModel.values.length)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_PageDown) {
            LauncherState.moveSelection(6, appModel.values.length)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_PageUp) {
            LauncherState.moveSelection(-6, appModel.values.length)
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateSelection()
            event.accepted = true
        }
    }

    onActiveChanged: {
        if (active) {
            root.focusSearch()
        }
    }

    ScriptModel {
        id: appModel

        values: LauncherState.filteredApplications(
            [...DesktopEntries.applications.values],
            LauncherState.query
        )

        onValuesChanged: LauncherState.clampSelection(values.length)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons

        onClicked: function(mouse) {
            mouse.accepted = true
        }
    }

    ThemedPanelSurface {
        anchors.fill: parent
        radius: ShellTheme.isFfxiv ? 10 : 28
        padding: 20
        clipContent: false

        Rectangle {
            id: searchBox

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 56
            radius: ShellTheme.controlRadius
            antialiasing: true
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: ShellTheme.controlFillTopActive }
                GradientStop { position: 1.0; color: ShellTheme.controlFillBottomActive }
            }
            border.width: ShellTheme.controlBorderWidth
            border.color: searchInput.activeFocus ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 18
                }
                text: "Rechercher"
                color: ShellTheme.textSecondary
                font.pixelSize: 18
                visible: searchInput.text.length === 0
            }

            TextInput {
                id: searchInput

                anchors {
                    fill: parent
                    leftMargin: 18
                    rightMargin: 18
                }
                verticalAlignment: TextInput.AlignVCenter
                text: LauncherState.query
                color: ShellTheme.textPrimary
                selectedTextColor: ShellTheme.textPrimary
                selectionColor: ShellTheme.controlBorderActive
                font.pixelSize: 18
                font.weight: Font.DemiBold
                clip: true
                focus: root.active
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: root.handleKey(event)
                onTextEdited: LauncherState.query = text
            }
        }

        ListView {
            id: appList

            anchors {
                top: searchBox.bottom
                topMargin: 14
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: appModel
            currentIndex: LauncherState.selectedIndex
            highlightMoveDuration: 110
            highlightResizeDuration: 110

            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
            }

            delegate: AppLauncherItem {
                required property int index
                required property var modelData

                width: appList.width
                height: 64
                entry: modelData
                selected: index === LauncherState.selectedIndex

                onPointerEntered: LauncherState.selectIndex(index, appModel.values.length)
                onClicked: LauncherState.launchEntry(modelData)
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }

        Text {
            anchors.centerIn: appList
            width: appList.width
            horizontalAlignment: Text.AlignHCenter
            text: "Aucun résultat"
            color: ShellTheme.textSecondary
            font.pixelSize: 16
            visible: appModel.values.length === 0
        }
    }

    Connections {
        target: LauncherState

        function onVisibleChanged() {
            if (LauncherState.visible && root.active) {
                root.focusSearch()
            }
        }

        function onQueryChanged() {
            if (searchInput.text !== LauncherState.query) {
                searchInput.text = LauncherState.query
            }
        }
    }
}
