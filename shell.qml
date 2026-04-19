// shell.qml
import Quickshell
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            mask: Region {
                item: frame

                Region {
                    item: frame.centerCutoutItem
                    intersection: Intersection.Subtract
                }
            }

            Frame {
                id: frame
                anchors.fill: parent
            }
        }
    }
}