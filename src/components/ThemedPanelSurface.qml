import QtQuick

import "../state"

Item {
    id: root

    default property alias contentData: contentLayer.data
    property int radius: ShellTheme.panelRadius
    property int padding: ShellTheme.panelPadding
    property bool clipContent: false

    implicitWidth: 336
    implicitHeight: 170

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: root.radius
        antialiasing: true
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: ShellTheme.panelFillTop }
            GradientStop { position: 0.18; color: ShellTheme.panelFillUpper }
            GradientStop { position: 0.58; color: ShellTheme.panelFillMiddle }
            GradientStop { position: 1.0; color: ShellTheme.panelFillBottom }
        }
        border.width: ShellTheme.surfaceBorderWidth
        border.color: ShellTheme.panelBorderOuter
    }

    Rectangle {
        anchors {
            fill: parent
            margins: 1
        }
        radius: Math.max(0, root.radius - 1)
        antialiasing: true
        color: "transparent"
        border.width: ShellTheme.surfaceBorderWidth
        border.color: ShellTheme.panelBorder
    }

    Rectangle {
        anchors {
            fill: parent
            margins: 2
        }
        radius: Math.max(0, root.radius - 2)
        antialiasing: true
        color: "transparent"
        border.width: 1
        border.color: ShellTheme.panelInsetLine
        opacity: ShellTheme.isFfxiv ? 1 : 0.36
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.radius + 2
            rightMargin: root.radius + 2
            topMargin: 2
        }
        height: 1
        radius: 1
        color: ShellTheme.panelTopSheen
    }

    Repeater {
        model: ShellTheme.isFfxiv ? 4 : 0

        delegate: Rectangle {
            required property int index

            x: root.radius + 8
            y: 24 + (index * 24)
            width: Math.max(0, root.width - ((root.radius + 8) * 2))
            height: 1
            color: ShellTheme.panelTextureLine
        }
    }

    Item {
        id: contentLayer

        anchors {
            fill: parent
            margins: root.padding
        }
        clip: root.clipContent
    }
}
