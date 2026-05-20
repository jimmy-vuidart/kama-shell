import QtQuick

import "../state"

Item {
    id: root

    property string selectedSection: SettingsState.selectedSection

    implicitWidth: 240

    readonly property var sections: [
        { id: "appearance", label: "Apparence" },
        { id: "home", label: "Maison" }
    ]

    function iconSourceFor(sectionId) {
        if (sectionId === "home") {
            return Qt.resolvedUrl("../assets/icons/fluent/fluent-home-24-regular.svg").toString()
        }
        return Qt.resolvedUrl("../assets/icons/fluent/fluent-color-24-regular.svg").toString()
    }

    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 8
        }
        spacing: 2

        Repeater {
            model: root.sections

            delegate: Item {
                required property var modelData

                width: parent.width
                height: 44

                readonly property bool isActive: root.selectedSection === modelData.id

                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    radius: ShellTheme.controlRadius
                    antialiasing: true
                    color: parent.isActive
                        ? Qt.rgba(1, 1, 1, ShellTheme.isFfxiv ? 0.12 : 0.14)
                        : menuItemHover.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.06)
                            : "transparent"
                    border.width: parent.isActive ? 1 : 0
                    border.color: ShellTheme.controlBorder

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Item {
                    id: sectionIcon

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 20
                    }
                    width: 22
                    height: 22
                    opacity: parent.isActive ? 1 : 0.72

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        antialiasing: true
                        color: Qt.rgba(1, 1, 1, parent.parent.isActive ? 0.1 : 0.05)
                        border.width: 1
                        border.color: parent.parent.isActive
                            ? ShellTheme.controlBorderActive
                            : ShellTheme.controlBorder
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: root.iconSourceFor(modelData.id)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: parent.parent.isActive ? 0.96 : 0.74
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 80 }
                    }
                }

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 54
                    }
                    text: modelData.label
                    color: parent.isActive ? ShellTheme.textPrimary : ShellTheme.textSecondary
                    font.pixelSize: 14
                    font.weight: parent.isActive ? Font.DemiBold : Font.Normal

                    Behavior on color {
                        ColorAnimation { duration: 80 }
                    }
                }

                MouseArea {
                    id: menuItemHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SettingsState.selectedSection = modelData.id
                }
            }
        }
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: 1
        color: ShellTheme.separatorLine
    }
}
