import QtQuick
import QtQuick.Layouts

import "../state"

ThemedPanelSurface {
    id: root

    implicitWidth: 320
    implicitHeight: 56
    radius: height / 2
    padding: 14

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Image {
            Layout.alignment: Qt.AlignVCenter
            width: 22
            height: 22
            source: OsdState.kind === OsdState.kindVolume
                ? "../assets/icons/status/" + StatusNotchState.audioIndicatorIconName
                : "../assets/icons/status/fluent-brightness-high-24-regular.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 6

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.12)
            }

            Rectangle {
                id: fillBar

                height: parent.height
                radius: height / 2
                width: parent.width * OsdState.level
                color: ShellTheme.runningIndicatorActive

                Behavior on width {
                    SmoothedAnimation {
                        velocity: 600
                    }
                }
            }
        }
    }
}
