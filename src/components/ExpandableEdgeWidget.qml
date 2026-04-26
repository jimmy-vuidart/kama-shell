import QtQuick

Item {
    id: root

    required property real compactWidth
    required property real compactHeight
    required property real expandedWidth
    required property real expandedHeight

    property real compactVisualWidth: compactWidth
    property real compactVisualHeight: compactHeight
    property real contentBottomMargin: 0
    property real compactBottomMargin: contentBottomMargin
    property real hoverBottomMargin: 0
    property real hoverWidth: Math.max(compactWidth, expandedWidth)
    property real hoverHeight: compactHeight
    property int animationDuration: 220
    property bool keepExpanded: false
    property Component compactContent
    property alias contentItem: contentContainer
    property alias hoverItem: hoverZone
    readonly property bool hovered: hoverArea.containsMouse
    property real revealProgress: (hovered || keepExpanded) ? 1 : 0
    readonly property real currentWidth: compactWidth + ((expandedWidth - compactWidth) * revealProgress)
    readonly property real currentHeight: compactHeight + ((expandedHeight - compactHeight) * revealProgress)

    default property alias contentData: contentContainer.data

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutCubic
        }
    }

    Item {
        id: contentContainer

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: root.contentBottomMargin
        }
        width: root.expandedWidth
        height: root.expandedHeight * root.revealProgress
        clip: true
    }

    Loader {
        id: compactLoader

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: root.compactBottomMargin
        }
        width: root.compactVisualWidth
        height: root.compactVisualHeight
        opacity: 1 - root.revealProgress
        visible: opacity > 0
        sourceComponent: root.compactContent
    }

    Item {
        id: hoverZone

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: root.hoverBottomMargin
        }
        width: root.hoverWidth
        height: root.hoverHeight

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }
}
