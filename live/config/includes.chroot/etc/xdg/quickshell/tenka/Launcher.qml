// The launcher: a centred glass card with the crest, one big search line, and apps as a list
// whose selection is the pack's own brush stroke. Super+Space, or click the crest.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: launcher
    property bool open: false
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.alpha(Qt.color(Theme.t.base), 0.28)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open = !launcher.open; if (launcher.open) { search.text = ""; list.currentIndex = 0; search.forceActiveFocus() } }
        function show(): void { launcher.open = true; search.forceActiveFocus() }
        function hide(): void { launcher.open = false }
    }

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay && a.name.toLowerCase().includes(search.text.toLowerCase()))
        .sort((a, b) => a.name.localeCompare(b.name))

    MouseArea { anchors.fill: parent; onClicked: launcher.open = false }

    Glass {
        id: card
        width: 780; height: 620; radius: 30; tint: 0.80; line: 0.34
        anchors.centerIn: parent
        MouseArea { anchors.fill: parent }   // swallow clicks

        Column {
            anchors.fill: parent; anchors.margins: 34; spacing: 18
            Row {
                spacing: 16
                Image { source: Theme.t.crest; width: 46; height: 46; smooth: true; mipmap: true; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: Theme.t.seekWord; color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 15; font.letterSpacing: 8 }
                    Text { text: launcher.apps.length + " paths open"; color: Theme.alpha(Qt.color(Theme.t.text), 0.55); font.family: Theme.ui; font.pixelSize: 12 }
                }
            }
            TextField {
                id: search
                width: parent.width; height: 62
                placeholderText: "Type to seek…"
                placeholderTextColor: Theme.alpha(Qt.color(Theme.t.text), 0.4)
                color: Theme.t.text; font.family: Theme.display; font.pixelSize: 26; leftPadding: 22
                background: Rectangle {
                    radius: 18; color: Theme.alpha(Qt.color(Theme.t.base), 0.55)
                    border.width: 1; border.color: Theme.alpha(Qt.color(Theme.t.gold), search.activeFocus ? 0.55 : 0.25)
                    Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 36; height: 2; radius: 1; color: Theme.t.accent; opacity: 0.85 }
                }
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onEscapePressed: launcher.open = false
                onAccepted: if (launcher.apps.length) { launcher.apps[list.currentIndex].execute(); launcher.open = false }
            }
            ListView {
                id: list
                width: parent.width; height: parent.height - 160
                clip: true; spacing: 4
                model: launcher.apps
                highlightMoveDuration: 140
                highlight: Item {
                    Image { anchors.fill: parent; anchors.rightMargin: parent.width * 0.25; source: Theme.t.stroke; smooth: true; opacity: 0.9 }
                }
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: list.width; height: 58
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 22; spacing: 16
                        IconImage { source: Quickshell.iconPath(modelData.icon, "application-x-executable"); implicitSize: 32; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData.name; color: index === list.currentIndex ? Theme.t.ink : Theme.t.text
                                   font.family: Theme.display; font.pixelSize: 19 }
                            Text { text: modelData.comment || modelData.genericName || ""; visible: text !== ""
                                   color: Theme.alpha(Qt.color(index === list.currentIndex ? Theme.t.ink : Theme.t.text), 0.55)
                                   font.family: Theme.ui; font.pixelSize: 12; width: 560; elide: Text.ElideRight }
                        }
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true
                                onEntered: list.currentIndex = index
                                onClicked: { modelData.execute(); launcher.open = false } }
                }
            }
        }
    }
}
