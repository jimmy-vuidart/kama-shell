import QtQuick

import "../state"

Rectangle {
    width: 1
    height: 34
    radius: 1
    color: ShellTheme.separatorLine

    Rectangle {
        anchors {
            fill: parent
            leftMargin: -1
            rightMargin: -1
            topMargin: 6
            bottomMargin: 6
        }
        radius: 2
        color: ShellTheme.separatorGlow
    }
}
