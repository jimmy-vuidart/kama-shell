import QtQuick

import "../state"

Item {
    id: root

    required property var screen

    readonly property int iconSize: ShellGeometry.statusNotchIconSize
    readonly property int itemGap: ShellGeometry.statusNotchItemGap

    implicitWidth: StatusNotchState.statusNotchImplicitWidth
    implicitHeight: ShellGeometry.statusNotchHeight
    clip: true

Row {
        id: row
        anchors {
            centerIn: parent
            horizontalCenterOffset: 0
            verticalCenterOffset: -4
        }
        height: root.iconSize
        spacing: root.itemGap

        Repeater {
            model: StatusNotchState.trayItems

            StatusTrayIcon {
                required property var modelData

                trayItem: modelData
                screen: root.screen
            }
        }

        SectionSeparator {
            visible: StatusNotchState.hasTraySection
        }

        CpuIndicator {}

        SectionSeparator {}

        StatusIndicatorIcon {
            kind: "volume"
            iconName: StatusNotchState.audioIndicatorIconName
            fallbackText: StatusNotchState.audioMuted ? "M" : "V"
        }

        StatusIndicatorIcon {
            kind: "network"
            iconName: StatusNotchState.networkIndicatorIconName
            fallbackText: StatusNotchState.networkConnected ? "N" : "X"
        }

        StatusIndicatorIcon {
            kind: "battery"
            iconName: StatusNotchState.batteryIndicatorIconName
            fallbackText: "B"
            visible: StatusNotchState.batteryVisible
        }
    }

    component StatusIndicatorIcon: Item {
        property string kind: ""
        property string iconName: ""
        property string fallbackText: "?"
        readonly property url iconSource: iconName.length > 0
            ? Qt.resolvedUrl("../assets/icons/status/" + iconName)
            : ""

        width: root.iconSize
        height: root.iconSize

        Image {
            id: iconImage

            anchors.fill: parent
            source: parent.iconSource
            sourceSize.width: root.iconSize
            sourceSize.height: root.iconSize
            asynchronous: true
            mipmap: true
            visible: source.toString().length > 0 && status === Image.Ready
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

    component CpuIndicator: Item {
        readonly property int iconGap: 4

        width: ShellGeometry.statusNotchCpuIndicatorWidth
        height: root.iconSize

        Text {
            id: cpuLabel

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: parent.width - root.iconSize - parent.iconGap
            text: StatusNotchState.cpuLoadText
            color: ShellTheme.textPrimary
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 10
            font.weight: Font.DemiBold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }

        StatusIndicatorIcon {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            iconName: "fluent-desktop-pulse-24-regular.svg"
            fallbackText: "C"
        }
    }

    component SectionSeparator: Item {
        width: ShellGeometry.statusNotchCpuTrailingGap
        height: root.iconSize

        Rectangle {
            anchors.centerIn: parent
            width: 1
            height: 10
            radius: 1
            color: ShellTheme.glyphColor
            opacity: 0.42
        }
    }
}
