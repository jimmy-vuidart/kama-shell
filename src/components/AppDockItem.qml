import QtQuick

import "../state"

Item {
    id: root

    required property string label
    property string iconSource: ""
    property bool active: false
    property bool pinned: false
    property bool running: false
    property bool launching: false
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

    Canvas {
        id: spinnerCanvas

        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 10
        visible: root.launching && !root.running

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r = cx - 3
            ctx.beginPath()
            ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI)
            ctx.strokeStyle = ShellTheme.runningIndicatorActive
            ctx.lineWidth = 2.5
            ctx.lineCap = "round"
            ctx.stroke()
        }

        onVisibleChanged: requestPaint()
        Component.onCompleted: if (visible) requestPaint()

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: spinnerCanvas.visible
        }
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
        opacity: root.launching ? 0.55 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
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
