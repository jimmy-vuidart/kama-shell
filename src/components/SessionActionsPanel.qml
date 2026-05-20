import QtQuick

import "../state"

ThemedPanelSurface {
    id: root

    readonly property int buttonWidth: 132
    readonly property int buttonHeight: 96
    readonly property int buttonGap: 10

    radius: ShellTheme.isFfxiv ? 8 : 22
    padding: 10
    implicitWidth: actionRow.implicitWidth + (padding * 2)
    implicitHeight: actionRow.implicitHeight + (padding * 2)
    width: implicitWidth
    height: implicitHeight

    Row {
        id: actionRow

        spacing: root.buttonGap

        SessionActionTile {
            width: root.buttonWidth
            height: root.buttonHeight
            label: "Déconnexion"
            iconSource: Qt.resolvedUrl("../assets/icons/fluent/fluent-sign-out-24-regular.svg").toString()
            enabled: SessionActionsState.canLogout && !SessionActionsState.busy
            busy: SessionActionsState.currentAction === SessionActionsState.logoutAction
            critical: false
            onClicked: SessionActionsState.trigger(SessionActionsState.logoutAction)
        }

        SessionActionTile {
            width: root.buttonWidth
            height: root.buttonHeight
            label: "Redémarrer"
            iconSource: Qt.resolvedUrl("../assets/icons/fluent/fluent-arrow-clockwise-24-regular.svg").toString()
            enabled: !SessionActionsState.busy
            busy: SessionActionsState.currentAction === SessionActionsState.rebootAction
            critical: true
            onClicked: SessionActionsState.trigger(SessionActionsState.rebootAction)
        }

        SessionActionTile {
            width: root.buttonWidth
            height: root.buttonHeight
            label: "Éteindre"
            iconSource: Qt.resolvedUrl("../assets/icons/fluent/fluent-power-24-regular.svg").toString()
            enabled: !SessionActionsState.busy
            busy: SessionActionsState.currentAction === SessionActionsState.poweroffAction
            critical: true
            onClicked: SessionActionsState.trigger(SessionActionsState.poweroffAction)
        }
    }

    component SessionActionTile: Rectangle {
        id: tile

        required property string label
        property string iconSource: ""
        property bool busy: false
        property bool critical: false
        signal clicked

        radius: ShellTheme.controlRadius
        antialiasing: true
        color: "transparent"
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: tile.critical ? ShellTheme.criticalControlFillTop : ShellTheme.controlFillTop
            }
            GradientStop {
                position: 1.0
                color: tile.critical ? ShellTheme.criticalControlFillBottom : ShellTheme.controlFillBottom
            }
        }
        border.width: ShellTheme.controlBorderWidth
        border.color: tile.critical ? ShellTheme.criticalControlBorder : ShellTheme.controlBorder
        opacity: enabled ? (busy ? 0.82 : 1) : 0.45

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: Math.min(12, tile.radius)
                rightMargin: Math.min(12, tile.radius)
                topMargin: 1
            }
            height: 1
            radius: 1
            antialiasing: true
            color: ShellTheme.controlTopHighlight
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 18
            spacing: 8

            Image {
                id: iconImage

                anchors.horizontalCenter: parent.horizontalCenter
                width: 30
                height: 30
                source: tile.iconSource
                sourceSize.width: 30
                sourceSize.height: 30
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: !tile.busy && source.toString().length > 0 && status === Image.Ready
            }

            Text {
                width: parent.width
                text: tile.busy ? "..." : tile.label
                color: ShellTheme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: ShellTheme.controlTextWeight
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: tile.enabled && !tile.busy
            onClicked: tile.clicked()
        }
    }
}
