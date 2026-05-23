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
    property bool reorderable: false
    property string dragDesktopId: ""
    property real dragVisualOffsetX: 0
    readonly property bool dragging: _dragging
    property bool _dragging: false
    property bool _pressedForDrag: false
    property bool _dragWasActive: false
    property bool _suppressClick: false
    property real _pressPointerX: 0
    property real _pressOffsetX: 0
    signal clicked
    signal secondaryClicked(real x, real y)
    signal dragStarted
    signal dragMoved
    signal dragFinished
    signal dragCanceled

    width: 48
    height: 48
    z: dragging ? 100 : 0

    function pointerXInParent(mouse) {
        if (!root.parent) {
            return mouse.x
        }

        return root.mapToItem(root.parent, mouse.x, mouse.y).x
    }

    function beginPress(mouse) {
        if (!root.reorderable) {
            return
        }

        root._pressedForDrag = true
        root._dragWasActive = false
        root._pressPointerX = root.pointerXInParent(mouse)
        root._pressOffsetX = root.dragVisualOffsetX
    }

    function updatePress(mouse) {
        if (!root._pressedForDrag) {
            return
        }

        const dx = root.pointerXInParent(mouse) - root._pressPointerX

        if (!root._dragging && Math.abs(dx) >= 8) {
            root._dragging = true
            root._dragWasActive = true
            root.dragStarted()
        }

        if (root._dragging) {
            root.dragVisualOffsetX = root._pressOffsetX + dx
            root.dragMoved()
        }
    }

    function endPress(wasCanceled) {
        const finishedDrag = root._dragging

        if (finishedDrag) {
            if (wasCanceled) {
                root.dragCanceled()
            } else {
                root.dragFinished()
            }
        }

        root._pressedForDrag = false
        root._dragging = false
        root.dragVisualOffsetX = 0

        if (finishedDrag) {
            root._suppressClick = true
            Qt.callLater(function() {
                root._suppressClick = false
                root._dragWasActive = false
            })
        }
    }

    Item {
        id: visualContent

        x: root.dragVisualOffsetX
        y: 0
        width: parent.width
        height: parent.height
        scale: root.dragging ? 1.08 : 1.0
        opacity: root.dragging ? 0.86 : 1.0
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

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
    }

    MouseArea {
        id: dragMouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        preventStealing: root.reorderable

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.beginPress(mouse)
            }
        }

        onPositionChanged: function(mouse) {
            root.updatePress(mouse)
        }

        onReleased: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.secondaryClicked(mouse.x, mouse.y)
                return
            }

            const wasDragging = root.dragging
            root.endPress(false)

            if (wasDragging || root._dragWasActive || root._suppressClick) {
                return
            }

            root.clicked()
        }

        onCanceled: {
            root.endPress(true)
        }
    }
}
