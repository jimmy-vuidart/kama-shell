import QtQuick

import "../state"

Rectangle {
    id: root

    required property string label
    required property string value
    property bool active: false
    property real progress: -1
    property bool adjustable: false
    property string secondaryValue: ""

    signal clicked
    signal decremented
    signal incremented

    height: 66
    radius: ShellTheme.controlRadius
    antialiasing: true
    color: "transparent"
    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: root.active ? ShellTheme.controlFillTopActive : ShellTheme.controlFillTop
        }
        GradientStop {
            position: 1.0
            color: root.active ? ShellTheme.controlFillBottomActive : ShellTheme.controlFillBottom
        }
    }
    border.width: ShellTheme.controlBorderWidth
    border.color: root.active ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

    // Progress bar — non-adjustable mode only
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 10
            rightMargin: 10
            bottomMargin: 8
        }
        height: 3
        radius: 2
        antialiasing: true
        color: ShellTheme.panelBorderShadow
        visible: !root.adjustable && root.progress >= 0

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: parent.radius
            antialiasing: true
            color: root.active ? ShellTheme.runningIndicatorActive : ShellTheme.runningIndicator
        }
    }

    // Label + value column
    Column {
        anchors {
            left: parent.left
            right: root.adjustable ? adjustRow.left : parent.right
            top: parent.top
            topMargin: 10
            leftMargin: 10
            rightMargin: root.adjustable ? 4 : 10
        }
        spacing: 1

        Text {
            width: parent.width
            text: root.label
            color: ShellTheme.textSecondary
            elide: Text.ElideRight
            font.pixelSize: 10
            font.weight: Font.DemiBold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }

        Text {
            width: parent.width
            text: root.value
            color: ShellTheme.textPrimary
            elide: Text.ElideRight
            font.pixelSize: 15
            font.weight: Font.Bold
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }

        Text {
            width: parent.width
            text: root.secondaryValue
            color: ShellTheme.textSecondary
            elide: Text.ElideRight
            font.pixelSize: 10
            visible: root.secondaryValue.length > 0
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }
    }

    // +/- buttons — adjustable mode only
    Row {
        id: adjustRow
        visible: root.adjustable
        anchors {
            right: parent.right
            rightMargin: 8
            top: parent.top
            topMargin: 10
        }
        spacing: 4

        // Decrement button
        Rectangle {
            width: 20
            height: 20
            radius: 5
            antialiasing: true
            color: decrHover.hovered
                ? ShellTheme.controlFillTopActive
                : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: decrHover.hovered
                ? ShellTheme.controlBorderActive
                : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "−"
                color: ShellTheme.textPrimary
                font.pixelSize: 13
                font.weight: Font.Medium
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }

            HoverHandler {
                id: decrHover
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.decremented()
            }
        }

        // Increment button
        Rectangle {
            width: 20
            height: 20
            radius: 5
            antialiasing: true
            color: incrHover.hovered
                ? ShellTheme.controlFillTopActive
                : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: incrHover.hovered
                ? ShellTheme.controlBorderActive
                : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "+"
                color: ShellTheme.textPrimary
                font.pixelSize: 13
                font.weight: Font.Medium
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }

            HoverHandler {
                id: incrHover
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.incremented()
            }
        }
    }

    // Click area — non-adjustable mode only
    MouseArea {
        anchors.fill: parent
        enabled: !root.adjustable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
