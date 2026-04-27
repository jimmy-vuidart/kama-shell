import QtQuick

import "../state"

Item {
    id: root

    required property var entry
    property bool selected: false
    readonly property bool hovered: pointerArea.containsMouse
    readonly property string appName: LauncherState.entryName(entry)
    readonly property string iconSource: LauncherState.iconSourceFor(entry)

    signal clicked
    signal pointerEntered

    Rectangle {
        anchors {
            fill: parent
            margins: 5
        }
        radius: ShellTheme.controlRadius
        antialiasing: true
        color: "transparent"
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.selected || root.hovered
                    ? ShellTheme.controlFillTopActive
                    : "transparent"
            }
            GradientStop {
                position: 1.0
                color: root.selected || root.hovered
                    ? ShellTheme.controlFillBottomActive
                    : "transparent"
            }
        }
        border.width: ShellTheme.controlBorderWidth
        border.color: root.selected
            ? ShellTheme.controlBorderActive
            : (root.hovered ? ShellTheme.controlBorder : "transparent")
    }

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 10
        }
        width: parent.width - 10
        spacing: 8

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 64
            radius: ShellTheme.controlRadius
            antialiasing: true
            color: Qt.rgba(1, 1, 1, ShellTheme.isFfxiv ? 0.06 : 0.1)
            border.width: 1
            border.color: ShellTheme.controlBorder

            Image {
                id: iconImage

                anchors.centerIn: parent
                width: 40
                height: 40
                source: root.iconSource
                sourceSize.width: 40
                sourceSize.height: 40
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: LauncherState.entryInitial(root.entry)
                color: ShellTheme.textPrimary
                font.pixelSize: 22
                font.weight: ShellTheme.controlTextWeight
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
                visible: root.iconSource.length === 0 || iconImage.status !== Image.Ready
            }
        }

        Text {
            width: parent.width
            text: root.appName
            color: ShellTheme.textPrimary
            font.pixelSize: 12
            font.weight: ShellTheme.controlTextWeight
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
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
