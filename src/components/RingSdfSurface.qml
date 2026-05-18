import QtQuick

import "../state"

ShaderEffect {
    id: root

    required property Item panels

    property vector2d surfaceSize: Qt.vector2d(Math.max(1, width), Math.max(1, height))
    property vector4d innerRect: Qt.vector4d(panels.innerLeft, panels.innerTop, panels.innerRight, panels.innerBottom)
    property vector4d clockRect: Qt.vector4d(panels.clockNotchLeft, panels.innerTop, panels.clockNotchRight, panels.clockNotchBottom)
    property vector4d homeRect: Qt.vector4d(panels.homePanelShapeLeft, panels.homePanelShapeTop, panels.homePanelShapeRight, panels.homePanelShapeBottom)
    property vector4d dockRect: Qt.vector4d(panels.dockTopFlatLeft, panels.dockPeakY, panels.dockTopFlatRight, panels.innerBottom)
    property real cornerRadius: ShellGeometry.cornerRadius
    property real clockRadius: panels.clockNotchRadius
    property real homeRadius: panels.homePanelShapeRadius
    property real dockCurveRun: panels.dockCurveRun
    property real supportWidth: ShellTheme.panelBorderSupportWidth + (panels.morphingIntensity * 0.8)
    property real borderWidth: ShellTheme.panelBorderWidth + (panels.morphingIntensity * 1.4)
    property real highlightWidth: ShellTheme.panelHighlightWidth
    property color fillTop: ShellTheme.panelFillTop
    property color fillUpper: ShellTheme.panelFillUpper
    property color fillMiddle: ShellTheme.panelFillMiddle
    property color fillBottom: ShellTheme.panelFillBottom
    property color supportColor: ShellTheme.panelBorderSupport
    property color borderColor: ShellTheme.panelBorder
    property color highlightColor: ShellTheme.panelBorderHighlight

    anchors.fill: parent

    fragmentShader: Qt.resolvedUrl("../shaders/ring_sdf.frag.qsb")
}
