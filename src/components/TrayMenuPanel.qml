import Quickshell
import Quickshell.Widgets
import QtQuick

import "../state"

ThemedPanelSurface {
    id: root

    required property var menu
    signal closeRequested()

    readonly property int itemHeight: 30
    readonly property int minPanelWidth: 220
    readonly property int maxPanelWidth: 360
    readonly property int maxPanelHeight: 520
    property var menuStack: menu ? [menu] : []
    readonly property var currentMenu: menuStack.length > 0 ? menuStack[menuStack.length - 1] : null

    radius: ShellTheme.isFfxiv ? 8 : 18
    padding: 8
    clipContent: true
    implicitWidth: Math.min(
        maxPanelWidth,
        Math.max(minPanelWidth, menuColumn.implicitWidth + (padding * 2))
    )
    implicitHeight: Math.min(maxPanelHeight, menuColumn.implicitHeight + (padding * 2))
    width: implicitWidth
    height: implicitHeight

    onMenuChanged: menuStack = menu ? [menu] : []

    QsMenuOpener {
        id: menuOpener

        menu: root.currentMenu
    }

    Column {
        id: menuColumn

        width: Math.max(0, root.width - (root.padding * 2))
        spacing: 2

        TrayMenuRow {
            width: parent.width
            visible: root.menuStack.length > 1
            label: "Retour"
            iconText: "‹"
            enabled: true
            onTriggered: root.popMenu()
        }

        Repeater {
            model: menuOpener.children

            delegate: Item {
                required property var modelData

                width: menuColumn.width
                height: modelData.isSeparator ? 9 : root.itemHeight

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 8
                        rightMargin: 8
                    }
                    height: 1
                    color: ShellTheme.separatorLine
                    visible: parent.modelData.isSeparator
                }

                TrayMenuRow {
                    anchors.fill: parent
                    visible: !parent.modelData.isSeparator
                    entry: parent.modelData
                    onTriggered: root.activateEntry(parent.modelData)
                }
            }
        }
    }

    component TrayMenuRow: Item {
        id: rowRoot

        property var entry: null
        property string label: entry ? String(entry.text || "") : ""
        property string iconText: ""
        signal triggered()

        readonly property bool hasEntry: !!entry
        readonly property bool hasChildren: hasEntry && entry.hasChildren
        readonly property bool hasIcon: hasEntry && String(entry.icon || "").length > 0
        readonly property bool isCheckable: hasEntry && entry.buttonType !== QsMenuButtonType.None
        readonly property bool isChecked: hasEntry && entry.checkState === Qt.Checked

        implicitWidth: Math.max(160, labelText.implicitWidth + 92)
        height: root.itemHeight
        opacity: enabled ? 1 : 0.42
        enabled: !hasEntry || entry.enabled

        Rectangle {
            anchors.fill: parent
            radius: ShellTheme.isFfxiv ? 5 : 10
            color: hoverHandler.hovered && rowRoot.enabled
                ? ShellTheme.controlFillTopActive
                : "transparent"
            border.width: hoverHandler.hovered && rowRoot.enabled ? 1 : 0
            border.color: ShellTheme.controlBorderActive
        }

        Image {
            anchors {
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            width: 16
            height: 16
            source: rowRoot.hasIcon ? rowRoot.entry.icon : ""
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: rowRoot.hasIcon
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 16
            text: rowRoot.isCheckable ? (rowRoot.isChecked ? "✓" : "") : rowRoot.iconText
            color: ShellTheme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            font.weight: Font.Bold
            visible: !rowRoot.hasIcon
        }

        Text {
            id: labelText

            anchors {
                left: parent.left
                right: chevron.left
                leftMargin: 34
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            text: rowRoot.label
            color: ShellTheme.textPrimary
            elide: Text.ElideRight
            font.pixelSize: 13
            font.weight: ShellTheme.controlTextWeight
        }

        Text {
            id: chevron

            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 14
            text: rowRoot.hasChildren ? "›" : ""
            color: ShellTheme.textSecondary
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 16
            font.weight: Font.Bold
        }

        HoverHandler {
            id: hoverHandler
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            enabled: rowRoot.enabled
            onClicked: rowRoot.triggered()
        }
    }

    function activateEntry(entry) {
        if (!entry || !entry.enabled) {
            return
        }

        if (entry.hasChildren) {
            const nextStack = root.menuStack.slice()
            nextStack.push(entry)
            root.menuStack = nextStack
            return
        }

        entry.triggered()
        root.closeRequested()
    }

    function popMenu() {
        if (root.menuStack.length <= 1) {
            return
        }

        const nextStack = root.menuStack.slice(0, root.menuStack.length - 1)
        root.menuStack = nextStack
    }
}
