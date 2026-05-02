import QtQuick

import "../state"

Item {
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

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: -4
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
        width: 42
        height: 42
        source: root.iconSource
        sourceSize.width: 42
        sourceSize.height: 42
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
