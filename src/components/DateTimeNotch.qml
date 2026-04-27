import QtQuick

import "../state"

Item {
    id: root

    implicitWidth: ShellGeometry.clockNotchWidth
    implicitHeight: ShellGeometry.clockNotchDepth

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: ShellGeometry.clockNotchTextVerticalOffset
        width: Math.max(0, parent.width - (ShellGeometry.clockNotchHorizontalPadding * 2))
        height: parent.height
        text: ClockState.formattedDateTime
        color: ShellTheme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        font.pixelSize: ShellGeometry.clockNotchFontSize
        minimumPixelSize: 11
        fontSizeMode: Text.HorizontalFit
        font.weight: ShellTheme.isFfxiv ? Font.DemiBold : Font.Bold
        style: ShellTheme.controlTextStyle
        styleColor: ShellTheme.textShadow
    }
}
