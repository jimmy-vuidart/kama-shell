import QtQuick

import "../state"

Rectangle {
    id: root

    required property string label
    property string iconSource: ""
    property bool active: false
    property bool pinned: false
    property bool running: false
    signal clicked
    signal secondaryClicked(real x, real y)

    width: 48
    height: 48
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
    border.color: active ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

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

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 4
        }
        width: root.running ? (root.active ? 18 : 10) : 0
        height: 3
        radius: 2
        antialiasing: true
        color: root.active ? ShellTheme.runningIndicatorActive : ShellTheme.runningIndicator
        visible: width > 0
    }

    Image {
        id: iconImage

        anchors.centerIn: parent
        width: 22
        height: 22
        source: root.iconSource
        sourceSize.width: 22
        sourceSize.height: 22
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: ShellTheme.textPrimary
        font.pixelSize: ShellTheme.isFfxiv ? 17 : 18
        font.weight: ShellTheme.controlTextWeight
        style: ShellTheme.controlTextStyle
        styleColor: ShellTheme.textShadow
        visible: root.iconSource.length === 0 || iconImage.status !== Image.Ready
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.secondaryClicked(mouse.x, mouse.y)
                return
            }

            root.clicked()
        }
    }
}
