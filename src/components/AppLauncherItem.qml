import QtQuick

import "../state"

Item {
    id: root

    required property var entry
    property bool selected: false
    readonly property bool hovered: pointerArea.containsMouse
    readonly property string appName: LauncherState.entryName(entry)
    readonly property string subtitle: LauncherState.entrySubtitle(entry)
    readonly property string iconSource: LauncherState.iconSourceFor(entry)

    signal clicked
    signal pointerEntered

    height: 64

    Rectangle {
        anchors.fill: parent
        radius: ShellTheme.controlRadius
        antialiasing: true
        color: "transparent"
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.selected || root.hovered
                    ? ShellTheme.controlFillTopActive
                    : ShellTheme.controlFillTop
            }
            GradientStop {
                position: 1.0
                color: root.selected || root.hovered
                    ? ShellTheme.controlFillBottomActive
                    : ShellTheme.controlFillBottom
            }
        }
        border.width: ShellTheme.controlBorderWidth
        border.color: root.selected ? ShellTheme.controlBorderActive : ShellTheme.controlBorder
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 8
        }
        width: 48
        radius: ShellTheme.controlRadius
        antialiasing: true
        color: Qt.rgba(1, 1, 1, ShellTheme.isFfxiv ? 0.06 : 0.1)
        border.width: 1
        border.color: ShellTheme.controlBorder

        Image {
            id: iconImage

            anchors.centerIn: parent
            width: 28
            height: 28
            source: root.iconSource
            sourceSize.width: 28
            sourceSize.height: 28
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            text: LauncherState.entryInitial(root.entry)
            color: ShellTheme.textPrimary
            font.pixelSize: 18
            font.weight: ShellTheme.controlTextWeight
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
            visible: root.iconSource.length === 0 || iconImage.status !== Image.Ready
        }
    }

    Column {
        anchors {
            left: parent.left
            leftMargin: 70
            right: parent.right
            rightMargin: 18
            verticalCenter: parent.verticalCenter
        }
        spacing: 3

        Text {
            width: parent.width
            text: root.appName
            color: ShellTheme.textPrimary
            font.pixelSize: 16
            font.weight: ShellTheme.controlTextWeight
            elide: Text.ElideRight
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: ShellTheme.textSecondary
            font.pixelSize: 12
            elide: Text.ElideRight
            visible: root.subtitle.length > 0
        }
    }

    MouseArea {
        id: pointerArea

        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.pointerEntered()
        onClicked: root.clicked()
    }
}
