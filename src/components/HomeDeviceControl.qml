import QtQuick

import "../state"

Rectangle {
    id: root

    required property string label
    required property string value
    property bool active: false
    property real progress: -1

    signal clicked

    height: 54
    radius: ShellTheme.controlRadius
    antialiasing: true
    color: "transparent"
    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: root.active ? ShellTheme.controlFillTopActive : ShellTheme.controlFillTop
        }
        GradientStop {
            position: 1.0
            color: root.active ? ShellTheme.controlFillBottomActive : ShellTheme.controlFillBottom
        }
    }
    border.width: ShellTheme.controlBorderWidth
    border.color: root.active ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 10
            rightMargin: 10
            bottomMargin: 8
        }
        height: 3
        radius: 2
        antialiasing: true
        color: ShellTheme.panelBorderShadow
        visible: root.progress >= 0

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: parent.radius
            antialiasing: true
            color: root.active ? ShellTheme.runningIndicatorActive : ShellTheme.runningIndicator
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 1

        Text {
            width: parent.width
            text: root.label
            color: ShellTheme.textSecondary
            elide: Text.ElideRight
            font.pixelSize: 10
            font.weight: Font.DemiBold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }

        Text {
            width: parent.width
            text: root.value
            color: ShellTheme.textPrimary
            elide: Text.ElideRight
            font.pixelSize: 15
            font.weight: Font.Bold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
