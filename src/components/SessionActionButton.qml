import QtQuick

import "../state"

Rectangle {
    id: root

    required property string label
    property bool critical: false
    property bool busy: false
    signal clicked

    width: 68
    height: 48
    radius: ShellTheme.controlRadius
    antialiasing: true
    color: "transparent"
    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: root.critical ? ShellTheme.criticalControlFillTop : ShellTheme.controlFillTop
        }
        GradientStop {
            position: 1.0
            color: root.critical ? ShellTheme.criticalControlFillBottom : ShellTheme.controlFillBottom
        }
    }
    border.width: ShellTheme.controlBorderWidth
    border.color: critical ? ShellTheme.criticalControlBorder : ShellTheme.controlBorder
    opacity: enabled ? (busy ? 0.82 : 1) : 0.45

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: Math.min(10, root.radius)
            rightMargin: Math.min(10, root.radius)
            topMargin: 1
        }
        height: 1
        radius: 1
        antialiasing: true
        color: ShellTheme.controlTopHighlight
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Math.min(10, root.radius)
            rightMargin: Math.min(10, root.radius)
            bottomMargin: 1
        }
        height: 1
        radius: 1
        antialiasing: true
        color: ShellTheme.controlBottomShadow
    }

    Text {
        anchors.centerIn: parent
        text: root.busy ? "..." : root.label
        color: ShellTheme.textPrimary
        font.pixelSize: 13
        font.weight: ShellTheme.controlTextWeight
        style: ShellTheme.controlTextStyle
        styleColor: ShellTheme.textShadow
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && !root.busy

        onClicked: root.clicked()
    }
}
