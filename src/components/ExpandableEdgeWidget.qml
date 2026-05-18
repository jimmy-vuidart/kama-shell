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
    readonly property real revealTarget: (hovered || keepExpanded) ? 1 : 0
    property real revealProgress: 0
    // Proxy de vélocité: positif lors d'expansion, négatif lors de fermeture,
    // décay automatiquement à 0 quand le ressort se stabilise. Utilisé par
    // `Ring.qml` pour ajouter un bonus de squash à la silhouette.
    readonly property real revealVelocity: revealTarget - revealProgress
    readonly property real currentWidth: compactWidth + ((expandedWidth - compactWidth) * revealProgress)
    readonly property real currentHeight: compactHeight + ((expandedHeight - compactHeight) * revealProgress)

    default property alias contentData: contentContainer.data

    onRevealTargetChanged: revealProgress = revealTarget

    Behavior on revealProgress {
        SpringAnimation {
            spring: 3.2
            damping: 0.32
            mass: 1.0
            epsilon: 0.005
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
