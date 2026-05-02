pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string glassmorphismTheme: ShellConfig.glassmorphismTheme
    readonly property string ffxivTheme: ShellConfig.ffxivTheme
    readonly property string liquidGlassTheme: ShellConfig.liquidGlassTheme
    property string themeName: ShellConfig.visualTheme
    readonly property bool isGlassmorphism: themeName === glassmorphismTheme
    readonly property bool isFfxiv: themeName === ffxivTheme
    readonly property bool isLiquidGlass: themeName === liquidGlassTheme

    readonly property var themeValues: ({
        glassmorphism: {
            glassTintAlpha: 0.18,
            glassTopHighlightAlpha: 0.34,
            glassBottomShadeAlpha: 0.18,
            glassBorderAlpha: 0.52,
            glassInnerHighlightAlpha: 0.46
        },
        ffxiv: {
            glassTintAlpha: 0.92,
            glassTopHighlightAlpha: 0.18,
            glassBottomShadeAlpha: 0.72,
            glassBorderAlpha: 0.94,
            glassInnerHighlightAlpha: 0.72
        },
        "liquid-glass": {
            glassTintAlpha: 0.03,
            glassTopHighlightAlpha: 0.52,
            glassBottomShadeAlpha: 0.10,
            glassBorderAlpha: 0.40,
            glassInnerHighlightAlpha: 0.70
        }
    })

    readonly property real glassTintAlpha: themeValue(themeName, "glassTintAlpha")
    readonly property real glassTopHighlightAlpha: themeValue(themeName, "glassTopHighlightAlpha")
    readonly property real glassBottomShadeAlpha: themeValue(themeName, "glassBottomShadeAlpha")
    readonly property real glassBorderAlpha: themeValue(themeName, "glassBorderAlpha")
    readonly property real glassInnerHighlightAlpha: themeValue(themeName, "glassInnerHighlightAlpha")

    readonly property real liquidBlurAmount: 0.8
    readonly property int liquidBlurMax: 80
    readonly property real liquidSaturation: 0.04
    readonly property real liquidBrightness: 0.14
    readonly property real liquidEdgeHighlightAlpha: 0.72
    readonly property real liquidEdgeShadowAlpha: 0.14
    readonly property real liquidShadowBlur: 48
    readonly property real liquidShadowOffsetY: 14
    readonly property real liquidShadowAlpha: 0.36
    readonly property real liquidLensingStrength: 22
    readonly property real liquidEdgeWidth: 28
    readonly property real liquidAberrationStrength: 2.5

    readonly property color panelFillTop: isFfxiv
        ? Qt.rgba(63 / 255, 62 / 255, 58 / 255, 0.98)
        : Qt.rgba(1, 1, 1, glassTopHighlightAlpha)
    readonly property color panelFillUpper: isFfxiv
        ? Qt.rgba(46 / 255, 46 / 255, 43 / 255, 0.98)
        : Qt.rgba(0.92, 0.98, 1, glassTintAlpha)
    readonly property color panelFillMiddle: isFfxiv
        ? Qt.rgba(31 / 255, 32 / 255, 31 / 255, 0.98)
        : Qt.rgba(0.78, 0.86, 0.94, 0.13)
    readonly property color panelFillBottom: isFfxiv
        ? Qt.rgba(11 / 255, 12 / 255, 12 / 255, 0.99)
        : Qt.rgba(0.16, 0.19, 0.24, glassBottomShadeAlpha)

    readonly property color panelBorderOuter: isFfxiv
        ? Qt.rgba(18 / 255, 13 / 255, 8 / 255, 1)
        : Qt.rgba(7 / 255, 16 / 255, 24 / 255, 0.34)
    readonly property color panelBorderSupport: isFfxiv
        ? Qt.rgba(9 / 255, 7 / 255, 5 / 255, 0.78)
        : Qt.rgba(0.92, 0.97, 1, 0.18)
    readonly property color panelBorder: isFfxiv
        ? Qt.rgba(199 / 255, 159 / 255, 83 / 255, 0.97)
        : Qt.rgba(0.92, 0.97, 1, glassBorderAlpha)
    readonly property color panelBorderHighlight: isFfxiv
        ? Qt.rgba(242 / 255, 202 / 255, 116 / 255, 0.92)
        : Qt.rgba(1, 1, 1, glassInnerHighlightAlpha)
    readonly property color panelBorderShadow: isFfxiv
        ? Qt.rgba(0, 0, 0, 0.62)
        : Qt.rgba(0.05, 0.08, 0.12, 0.2)
    readonly property color panelInsetLine: isFfxiv
        ? Qt.rgba(77 / 255, 59 / 255, 31 / 255, 0.95)
        : Qt.rgba(1, 1, 1, glassInnerHighlightAlpha)
    readonly property color panelTopSheen: isFfxiv
        ? Qt.rgba(1, 1, 1, 0.12)
        : Qt.rgba(1, 1, 1, 0.2)
    readonly property color panelTextureLine: isFfxiv
        ? Qt.rgba(1, 1, 1, 0.035)
        : Qt.rgba(1, 1, 1, 0.06)

    readonly property real panelBorderSupportWidth: isFfxiv ? 3.4 : 2.8
    readonly property real panelBorderWidth: isFfxiv ? 2.1 : 1.8
    readonly property real panelHighlightWidth: isFfxiv ? 1.35 : 1.2
    readonly property int surfaceBorderWidth: 2
    readonly property int controlBorderWidth: 2
    readonly property int panelRadius: isFfxiv ? 7 : isLiquidGlass ? 32 : 24
    readonly property int panelPadding: isFfxiv ? 14 : 18

    readonly property color textPrimary: isFfxiv
        ? Qt.rgba(246 / 255, 243 / 255, 234 / 255, 0.98)
        : Qt.rgba(0.95, 0.98, 1, 0.96)
    readonly property color textSecondary: isFfxiv
        ? Qt.rgba(207 / 255, 201 / 255, 188 / 255, 0.86)
        : Qt.rgba(0.86, 0.95, 1, 0.78)
    readonly property color textShadow: isFfxiv
        ? Qt.rgba(0, 0, 0, 0.78)
        : Qt.rgba(0, 0, 0, 0.34)

    readonly property color controlFillTop: isFfxiv
        ? Qt.rgba(76 / 255, 76 / 255, 72 / 255, 0.98)
        : Qt.rgba(1, 1, 1, 0.15)
    readonly property color controlFillBottom: isFfxiv
        ? Qt.rgba(39 / 255, 40 / 255, 39 / 255, 0.98)
        : Qt.rgba(1, 1, 1, 0.08)
    readonly property color controlFillTopActive: isFfxiv
        ? Qt.rgba(93 / 255, 92 / 255, 86 / 255, 0.99)
        : Qt.rgba(1, 1, 1, 0.27)
    readonly property color controlFillBottomActive: isFfxiv
        ? Qt.rgba(45 / 255, 45 / 255, 43 / 255, 0.99)
        : Qt.rgba(1, 1, 1, 0.15)
    readonly property color controlBorder: isFfxiv
        ? Qt.rgba(111 / 255, 109 / 255, 101 / 255, 0.72)
        : Qt.rgba(1, 1, 1, 0.18)
    readonly property color controlBorderActive: isFfxiv
        ? Qt.rgba(219 / 255, 182 / 255, 103 / 255, 0.92)
        : Qt.rgba(1, 1, 1, 0.5)
    readonly property color controlTopHighlight: isFfxiv
        ? Qt.rgba(1, 1, 1, 0.18)
        : Qt.rgba(1, 1, 1, 0.16)
    readonly property color controlBottomShadow: isFfxiv
        ? Qt.rgba(0, 0, 0, 0.48)
        : Qt.rgba(0.05, 0.08, 0.12, 0.18)
    readonly property color criticalControlFillTop: isFfxiv
        ? Qt.rgba(117 / 255, 44 / 255, 42 / 255, 0.98)
        : Qt.rgba(0.72, 0.18, 0.24, 0.42)
    readonly property color criticalControlFillBottom: isFfxiv
        ? Qt.rgba(58 / 255, 24 / 255, 24 / 255, 0.98)
        : Qt.rgba(0.72, 0.18, 0.24, 0.26)
    readonly property color criticalControlBorder: isFfxiv
        ? Qt.rgba(226 / 255, 143 / 255, 121 / 255, 0.72)
        : Qt.rgba(1, 0.76, 0.8, 0.44)

    readonly property color runningIndicator: isFfxiv
        ? Qt.rgba(236 / 255, 190 / 255, 92 / 255, 0.9)
        : Qt.rgba(0.86, 0.95, 1, 0.5)
    readonly property color runningIndicatorActive: isFfxiv
        ? Qt.rgba(255 / 255, 214 / 255, 116 / 255, 0.98)
        : Qt.rgba(0.86, 0.95, 1, 0.95)
    readonly property color glyphColor: isFfxiv
        ? Qt.rgba(237 / 255, 194 / 255, 91 / 255, 0.92)
        : Qt.rgba(0.95, 0.98, 1, 0.88)
    readonly property color separatorLine: isFfxiv
        ? Qt.rgba(203 / 255, 159 / 255, 78 / 255, 0.38)
        : Qt.rgba(1, 1, 1, 0.18)
    readonly property color separatorGlow: isFfxiv
        ? Qt.rgba(0, 0, 0, 0.34)
        : Qt.rgba(1, 1, 1, 0.08)

    readonly property int controlRadius: isFfxiv ? 8 : 24
    readonly property int controlTextWeight: isFfxiv ? Font.DemiBold : Font.Bold
    readonly property int controlTextStyle: isFfxiv ? Text.Raised : Text.Normal

    function applyTheme(nextThemeName) {
        root.themeName = nextThemeName
    }

    function themeValue(sourceThemeName, key) {
        const currentValues = root.themeValues[sourceThemeName] || root.themeValues[root.glassmorphismTheme]
        const fallbackValues = root.themeValues[root.glassmorphismTheme]

        if (currentValues && Object.prototype.hasOwnProperty.call(currentValues, key)) {
            return currentValues[key]
        }

        return fallbackValues[key]
    }

    Component.onCompleted: root.applyTheme(ShellConfig.visualTheme)

    Connections {
        target: ShellConfig

        function onVisualThemeChanged() {
            root.applyTheme(ShellConfig.visualTheme)
        }
    }
}
