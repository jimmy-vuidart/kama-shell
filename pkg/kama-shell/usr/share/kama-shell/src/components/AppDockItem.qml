import QtQuick

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
    radius: 24
    color: active ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.11)
    border.width: 1
    border.color: active ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.18)

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 4
        }
        width: root.running ? (root.active ? 18 : 10) : 0
        height: 3
        radius: 2
        color: root.active ? Qt.rgba(0.86, 0.95, 1, 0.95) : Qt.rgba(0.86, 0.95, 1, 0.5)
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
        color: Qt.rgba(0.95, 0.98, 1, 0.96)
        font.pixelSize: 18
        font.weight: 700
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
