import QtQuick

Item {
    id: root

    property color titleColor: "#d8dbe6"
    property color textColor: "#a7adbf"
    property color secondaryTextColor: "#8f95a8"
    property color switchTrackColor: "#7c84d3"
    property color switchKnobColor: "#f1f2fb"

    property bool wirelessEnabled: true
    property bool discovering: true
    property int deviceCount: 0

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Bluetooth"
            color: root.titleColor
            font.pixelSize: 15
            font.bold: true
        }

        Row {
            width: parent.width
            spacing: 8

            Text {
                id: enabledLabel
                text: "Enabled"
                color: root.textColor
                font.pixelSize: 12
            }

            Item {
                width: Math.max(0, parent.width - enabledLabel.width - enabledSwitch.width - 16)
                height: 1
            }

            Rectangle {
                id: enabledSwitch
                width: 38
                height: 18
                radius: 9
                color: root.wirelessEnabled ? root.switchTrackColor : "#575a67"

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: root.wirelessEnabled ? parent.right : undefined
                    anchors.left: root.wirelessEnabled ? undefined : parent.left
                    anchors.rightMargin: root.wirelessEnabled ? 2 : 0
                    anchors.leftMargin: root.wirelessEnabled ? 0 : 2
                    color: root.switchKnobColor

                    Text {
                        anchors.centerIn: parent
                        text: root.wirelessEnabled ? "✓" : "✕"
                        color: "#7d81a0"
                        font.pixelSize: 10
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 8

            Text {
                id: discoveringLabel
                text: "Discovering"
                color: root.textColor
                font.pixelSize: 12
            }

            Item {
                width: Math.max(0, parent.width - discoveringLabel.width - discoveringSwitch.width - 16)
                height: 1
            }

            Rectangle {
                id: discoveringSwitch
                width: 38
                height: 18
                radius: 9
                color: root.discovering ? "#575b67" : "#4a4e5a"

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: root.discovering ? undefined : parent.right
                    anchors.left: root.discovering ? parent.left : undefined
                    anchors.rightMargin: root.discovering ? 0 : 2
                    anchors.leftMargin: root.discovering ? 2 : 0
                    color: "#9ea2ae"

                    Text {
                        anchors.centerIn: parent
                        text: root.discovering ? "✕" : "✓"
                        color: "#626673"
                        font.pixelSize: 10
                    }
                }
            }
        }

        Text {
            text: `${root.deviceCount} devices available`
            color: root.secondaryTextColor
            font.pixelSize: 11
        }

        Item {
            width: 1
            height: 2
        }

        Rectangle {
            width: parent.width
            height: 34
            radius: 17
            color: "#7f82b4"

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "⚙"
                    color: "#dfe2f5"
                    font.pixelSize: 14
                }

                Text {
                    text: "Open settings"
                    color: "#dfe2f5"
                    font.pixelSize: 12
                }
            }
        }
    }
}
