import Quickshell.Widgets
import QtQuick

import "../state"

Item {
    id: root

    readonly property int iconSize: ShellGeometry.statusNotchIconSize
    readonly property int itemGap: ShellGeometry.statusNotchItemGap

    implicitWidth: ShellGeometry.statusNotchWidth
    implicitHeight: ShellGeometry.statusNotchHeight
    clip: true

    Row {
        id: row

        anchors {
            centerIn: parent
            horizontalCenterOffset: 0
        }
        height: root.iconSize
        spacing: root.itemGap

        Repeater {
            model: StatusNotchState.visibleTrayItems

            StatusTrayIcon {
                required property var modelData

                trayItem: modelData
            }
        }

        Text {
            width: root.iconSize
            height: root.iconSize
            text: "+" + StatusNotchState.overflowTrayCount
            color: ShellTheme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 10
            font.weight: Font.Bold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
            visible: StatusNotchState.overflowTrayCount > 0
        }

        Item {
            width: StatusNotchState.visibleTrayItems.length > 0
                || StatusNotchState.overflowTrayCount > 0
                ? 4
                : 0
            height: root.iconSize
        }

        StatusIndicatorIcon {
            kind: "volume"
            iconSource: StatusNotchState.audioIconSource
            fallbackText: StatusNotchState.audioMuted ? "M" : "V"
        }

        StatusIndicatorIcon {
            kind: "network"
            iconSource: StatusNotchState.networkIconSource
            fallbackText: StatusNotchState.networkConnected ? "N" : "X"
        }

        StatusIndicatorIcon {
            kind: "battery"
            iconSource: StatusNotchState.batteryIconSource
            fallbackText: "B"
            visible: StatusNotchState.batteryVisible
        }
    }

    component StatusIndicatorIcon: Item {
        property string kind: ""
        property string iconSource: ""
        property string fallbackText: "?"

        width: root.iconSize
        height: root.iconSize

        IconImage {
            id: iconImage

            anchors.fill: parent
            source: parent.iconSource
            implicitSize: root.iconSize
            asynchronous: true
            mipmap: true
            visible: source.length > 0 && status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            text: parent.fallbackText
            color: ShellTheme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 10
            font.weight: Font.Bold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
            visible: false
        }

        Item {
            anchors.fill: parent
            visible: !iconImage.visible

            Rectangle {
                visible: parent.parent.kind === "volume"
                x: 3
                y: 7
                width: 4
                height: 5
                radius: 1
                color: ShellTheme.glyphColor
            }

            Rectangle {
                visible: parent.parent.kind === "volume"
                x: 7
                y: 5
                width: 5
                height: 9
                radius: 1
                color: ShellTheme.glyphColor
                transform: Rotation {
                    origin.x: 7
                    origin.y: 4.5
                    angle: 45
                }
            }

            Rectangle {
                visible: parent.parent.kind === "network"
                x: 3
                y: 11
                width: 2
                height: 3
                radius: 1
                color: ShellTheme.glyphColor
            }

            Rectangle {
                visible: parent.parent.kind === "network"
                x: 7
                y: 8
                width: 2
                height: 6
                radius: 1
                color: ShellTheme.glyphColor
            }

            Rectangle {
                visible: parent.parent.kind === "network"
                x: 11
                y: 5
                width: 2
                height: 9
                radius: 1
                color: ShellTheme.glyphColor
            }

            Rectangle {
                visible: parent.parent.kind === "battery"
                x: 2
                y: 5
                width: 11
                height: 7
                radius: 2
                color: "transparent"
                border.color: ShellTheme.glyphColor
                border.width: 1
            }

            Rectangle {
                visible: parent.parent.kind === "battery"
                x: 13
                y: 7
                width: 1
                height: 3
                radius: 1
                color: ShellTheme.glyphColor
            }

            Rectangle {
                visible: parent.parent.kind === "battery"
                x: 4
                y: 7
                width: Math.max(2, Math.round(StatusNotchState.batteryPercentage / 100 * 7))
                height: 3
                radius: 1
                color: ShellTheme.glyphColor
            }
        }
    }
}
