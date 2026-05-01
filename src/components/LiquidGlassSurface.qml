import QtQuick
import QtQuick.Effects
import QtQuick.Window

import "../state"

Item {
    id: root

    default property alias contentData: contentLayer.data
    property int radius: ShellTheme.panelRadius
    property int padding: ShellTheme.panelPadding
    property bool clipContent: false

    readonly property var hostWindow: Window.window
    readonly property real geometryRevision: root.x + root.y + root.width + root.height
        + (root.parent ? root.parent.width + root.parent.height : 0)
        + (hostWindow ? hostWindow.width + hostWindow.height : 0)
    readonly property point originInWindow: {
        const revision = root.geometryRevision
        return root.mapToItem(null, revision * 0, 0)
    }
    readonly property real screenWidth: Screen.width > 0 ? Screen.width : root.width
    readonly property real screenHeight: Screen.height > 0 ? Screen.height : root.height
    readonly property real backdropWidth: Math.max(1, root.width, screenWidth)
    readonly property real backdropHeight: Math.max(1, root.height, screenHeight)
    readonly property real cropX: Math.max(0, Math.min(backdropWidth - 1, originInWindow.x))
    readonly property real cropY: Math.max(0, Math.min(backdropHeight - 1, originInWindow.y))
    readonly property real cropWidth: Math.max(1, Math.min(root.width, backdropWidth - cropX))
    readonly property real cropHeight: Math.max(1, Math.min(root.height, backdropHeight - cropY))

    implicitWidth: 336
    implicitHeight: 170

    Rectangle {
        id: shadowShape

        anchors.fill: parent
        radius: root.radius
        antialiasing: true
        color: "black"
    }

    MultiEffect {
        anchors.fill: shadowShape
        source: shadowShape
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowBlur: 1.0
        shadowColor: Qt.rgba(0, 0, 0, 1)
        shadowOpacity: ShellTheme.liquidShadowAlpha
        shadowVerticalOffset: ShellTheme.liquidShadowOffsetY
        blurMax: ShellTheme.liquidShadowBlur
    }

    Item {
        id: backdropScene

        x: -root.cropX
        y: -root.cropY
        width: root.backdropWidth
        height: root.backdropHeight

        Rectangle {
            anchors.fill: parent
            color: WallpaperState.fallbackColor
        }

        Image {
            anchors.fill: parent
            source: WallpaperState.source
            visible: WallpaperState.hasWallpaper
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(backdropScene.width, backdropScene.height)
            cache: true
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    ShaderEffectSource {
        id: backdropSource

        width: root.width
        height: root.height
        sourceItem: backdropScene
        sourceRect: Qt.rect(root.cropX, root.cropY, root.cropWidth, root.cropHeight)
        textureSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
        hideSource: true
        live: true
        recursive: false
        mipmap: true
        visible: false
    }

    Rectangle {
        id: roundedMask

        anchors.fill: parent
        radius: root.radius
        antialiasing: true
        color: "white"
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: backdropSource
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: ShellTheme.liquidBlurMax
        blur: ShellTheme.liquidBlurAmount
        saturation: ShellTheme.liquidSaturation
        brightness: ShellTheme.liquidBrightness
        maskEnabled: true
        maskSource: roundedMask
        maskThresholdMin: 0.5
        maskThresholdMax: 1.0
        maskSpreadAtMin: 0.0
        maskSpreadAtMax: 0.0
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        antialiasing: true
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: ShellTheme.panelFillTop }
            GradientStop { position: 0.22; color: ShellTheme.panelFillUpper }
            GradientStop { position: 0.7; color: ShellTheme.panelFillMiddle }
            GradientStop { position: 1.0; color: ShellTheme.panelFillBottom }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        antialiasing: true
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0.02, 0.03, 0.05, ShellTheme.liquidEdgeShadowAlpha)
    }

    Rectangle {
        anchors {
            fill: parent
            margins: 1
        }
        radius: Math.max(0, root.radius - 1)
        antialiasing: true
        color: "transparent"
        border.width: 1
        border.color: ShellTheme.panelBorder
    }

    Rectangle {
        anchors {
            fill: parent
            margins: 2
        }
        radius: Math.max(0, root.radius - 2)
        antialiasing: true
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, ShellTheme.liquidEdgeHighlightAlpha)
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.radius + 4
            rightMargin: root.radius + 4
            topMargin: 2
        }
        height: 1
        radius: 1
        color: Qt.rgba(1, 1, 1, ShellTheme.liquidEdgeHighlightAlpha)
    }

    Item {
        id: contentLayer

        anchors {
            fill: parent
            margins: root.padding
        }
        clip: root.clipContent
    }
}
