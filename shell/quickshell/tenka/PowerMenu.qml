// The power menu: the whole screen frosts over, the crest, one line, and five seals:
// lock, rest (suspend), retreat (log out), return (reboot), sheathe (power off). Arrows + Enter, or click.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: pm
    property bool open: false
    property int sel: 4
    visible: open || veil.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-power"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    IpcHandler { target: "power"; function toggle(): void { pm.open = !pm.open; pm.sel = 4; if (pm.open) keys.forceActiveFocus() } }

    readonly property var rites: [
        ["\uf023", Theme.t.lockWord, "Lock the screen", "loginctl lock-session"],
        ["\uf186", Theme.t.suspendWord, "Suspend", "systemctl suspend"],
        ["\uf2f5", Theme.t.logoutWord, "Log out", "hyprctl dispatch exit || loginctl terminate-session $XDG_SESSION_ID"],
        ["\uf01e", Theme.t.rebootWord, "Restart", "systemctl reboot"],
        ["\uf011", Theme.t.shutdownWord, "Power off", "systemctl poweroff"]]
    onOpenChanged: Theme.hush = open
    function act(i) { open = false; Theme.run(rites[i][3]) }

    Glass {
        id: veil
        anchors.fill: parent; radius: 0; tint: 0.50; line: 0; shadow: false
        opacity: pm.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260 } }
        MouseArea { anchors.fill: parent; onClicked: pm.open = false }

        Item {
            id: keys; anchors.fill: parent; focus: true
            Keys.onLeftPressed: pm.sel = (pm.sel + 4) % 5
            Keys.onRightPressed: pm.sel = (pm.sel + 1) % 5
            Keys.onReturnPressed: pm.act(pm.sel)
            Keys.onEscapePressed: pm.open = false
        }

        Column {
            anchors.centerIn: parent; spacing: 26
            scale: pm.open ? 1 : 0.96
            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Image { source: Theme.t.crest; width: 112; height: 112; mipmap: true; anchors.horizontalCenter: parent.horizontalCenter }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: Theme.xia ? "Where does the path lead?" : "Where does the blade go?"
                   color: Theme.t.text; font.family: Theme.display; font.pixelSize: 46; font.letterSpacing: 1 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                Rectangle { width: 120; height: 1; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.t.gold, 0.6) }
                Rectangle { width: 8; height: 8; rotation: 45; color: Theme.t.gold; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 120; height: 1; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.t.gold, 0.6) }
            }
            Item { width: 1; height: 18 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 44
                Repeater {
                    model: pm.rites
                    Column {
                        required property var modelData; required property int index
                        readonly property bool on: pm.sel === index
                        spacing: 16
                        Rectangle {
                            width: 128; height: 128; radius: Theme.xia ? 64 : 34
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: parent.on ? Theme.t.accent : Theme.alpha(Theme.t.base, 0.45)
                            border.width: parent.on ? 2 : 1; border.color: parent.on ? Theme.t.gold : Theme.alpha(Theme.t.gold, 0.3)
                            scale: parent.on ? 1.06 : 1
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                            Text { anchors.centerIn: parent; text: parent.parent.modelData[0]; font.family: Theme.glyphs; font.pixelSize: 40
                                   color: parent.parent.on ? Theme.t.ink : Theme.t.text }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: pm.sel = parent.parent.index; onClicked: pm.act(parent.parent.index) }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData[1].toUpperCase()
                               color: parent.on ? Theme.t.gold : Theme.alpha(Theme.t.text, 0.85); font.family: Theme.display; font.pixelSize: 19; font.letterSpacing: 5 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData[2]
                               color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12 }
                    }
                }
            }
        }
        Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 60; anchors.horizontalCenter: parent.horizontalCenter
               text: "←  →  choose      ↵  confirm      Esc  stay"; color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.ui; font.pixelSize: 13; font.letterSpacing: 1 }
    }
}
