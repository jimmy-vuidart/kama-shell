import QtQuick

import "../state"

Rectangle {
    id: root

    required property string label
    required property string value
    property bool active: false
    property real progress: -1
    property bool adjustable: false
    property bool coverControl: false

    signal clicked
    signal decremented
    signal incremented
    signal upActivated
    signal stopActivated
    signal downActivated

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

    // Progress bar — standard mode only
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
        visible: !root.adjustable && !root.coverControl && root.progress >= 0

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progress))
            height: parent.height
            radius: parent.radius
            antialiasing: true
            color: root.active ? ShellTheme.runningIndicatorActive : ShellTheme.runningIndicator
        }
    }

    // Label + value column (full width — buttons are always at the bottom now)
    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 10
            leftMargin: 10
            rightMargin: 10
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
            font.pixelSize: 14
            font.weight: Font.Bold
            visible: root.value.length > 0
            style: ShellTheme.controlTextStyle
            styleColor: ShellTheme.textShadow
        }
    }

    // +/- buttons — adjustable mode, horizontal row at the bottom
    Row {
        id: adjustRow
        visible: root.adjustable
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 8
            rightMargin: 8
            bottomMargin: 6
        }
        height: 16
        spacing: 4

        Rectangle {
            width: Math.floor((adjustRow.width - adjustRow.spacing) / 2)
            height: adjustRow.height
            radius: 4
            antialiasing: true
            color: decrHover.hovered ? ShellTheme.controlFillTopActive : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: decrHover.hovered ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "−"
                color: ShellTheme.textPrimary
                font.pixelSize: 11
                font.weight: Font.Medium
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
            HoverHandler { id: decrHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.decremented()
            }
        }

        Rectangle {
            width: adjustRow.width - Math.floor((adjustRow.width - adjustRow.spacing) / 2) - adjustRow.spacing
            height: adjustRow.height
            radius: 4
            antialiasing: true
            color: incrHover.hovered ? ShellTheme.controlFillTopActive : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: incrHover.hovered ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "+"
                color: ShellTheme.textPrimary
                font.pixelSize: 11
                font.weight: Font.Medium
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
            HoverHandler { id: incrHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.incremented()
            }
        }
    }

    // ▲ ■ ▼ buttons — cover mode, horizontal row at the bottom
    Row {
        id: coverRow
        visible: root.coverControl
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 8
            rightMargin: 8
            bottomMargin: 6
        }
        height: 16
        spacing: 4

        readonly property real btnW: Math.floor((width - spacing * 2) / 3)

        Rectangle {
            width: coverRow.btnW
            height: coverRow.height
            radius: 4
            antialiasing: true
            color: upHover.hovered ? ShellTheme.controlFillTopActive : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: upHover.hovered ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "▲"
                color: ShellTheme.textPrimary
                font.pixelSize: 9
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
            HoverHandler { id: upHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.upActivated()
            }
        }

        Rectangle {
            width: coverRow.btnW
            height: coverRow.height
            radius: 4
            antialiasing: true
            color: stopHover.hovered ? ShellTheme.controlFillTopActive : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: stopHover.hovered ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "■"
                color: ShellTheme.textPrimary
                font.pixelSize: 9
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
            HoverHandler { id: stopHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stopActivated()
            }
        }

        Rectangle {
            width: coverRow.width - coverRow.btnW * 2 - coverRow.spacing * 2
            height: coverRow.height
            radius: 4
            antialiasing: true
            color: downHover.hovered ? ShellTheme.controlFillTopActive : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: downHover.hovered ? ShellTheme.controlBorderActive : ShellTheme.controlBorder

            Text {
                anchors.centerIn: parent
                text: "▼"
                color: ShellTheme.textPrimary
                font.pixelSize: 9
                style: ShellTheme.controlTextStyle
                styleColor: ShellTheme.textShadow
            }
            HoverHandler { id: downHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.downActivated()
            }
        }
    }

    // Click area — standard mode only
    MouseArea {
        anchors.fill: parent
        enabled: !root.adjustable && !root.coverControl
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
