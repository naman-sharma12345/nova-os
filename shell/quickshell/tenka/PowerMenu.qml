// The power menu: the whole screen frosts over, one line, and the five rites as the boot menu's own list
// (guard, rest, retreat, return, sheathe), the chosen one on the brush stroke. Arrows + Enter, or click.
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
        ["\uf2f5", Theme.t.logoutWord, "Log out", "hyprctl dispatch 'hl.dsp.exit()' | grep -qx ok || loginctl terminate-session \"$XDG_SESSION_ID\""],
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
            Keys.onUpPressed: pm.sel = (pm.sel + 4) % 5
            Keys.onDownPressed: pm.sel = (pm.sel + 1) % 5
            Keys.onLeftPressed: pm.sel = (pm.sel + 4) % 5
            Keys.onRightPressed: pm.sel = (pm.sel + 1) % 5
            Keys.onReturnPressed: pm.act(pm.sel)
            Keys.onEscapePressed: pm.open = false
        }

        Column {
            anchors.centerIn: parent; spacing: 26
            scale: pm.open ? 1 : 0.96
            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: Theme.xia ? "Where does the path lead?" : "Where does the blade go?"
                   color: Theme.t.text; font.family: Theme.display; font.pixelSize: 46; font.letterSpacing: 1 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                Rectangle { width: 120; height: 1; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.gold, 0.6) }
                Rectangle { width: 8; height: 8; rotation: 45; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 120; height: 1; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.gold, 0.6) }
            }
            Item { width: 1; height: 8 }
            // the rites as the boot menu's own list: words in Marcellus, the chosen one on the brush stroke
            Item {
                id: list
                anchors.horizontalCenter: parent.horizontalCenter
                width: 640; height: pm.rites.length * 66
                Image {
                    source: Theme.t.stroke; width: 520; height: 62; smooth: true
                    y: pm.sel * 66
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                Repeater {
                    model: pm.rites
                    Item {
                        required property var modelData; required property int index
                        readonly property bool on: pm.sel === index
                        y: index * 66; width: list.width; height: 62
                        Text { x: 36; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData[1]
                               color: parent.on ? "#fff8ec" : Theme.alpha(Theme.t.text, 0.56)   // the off rites in each pack's own text tone (the warm grey was Tenka-only); font.family: Theme.display; font.pixelSize: 34
                               Behavior on color { ColorAnimation { duration: 180 } } }
                        Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                               text: parent.modelData[2].toUpperCase(); color: Theme.alpha(Theme.t.text, parent.on ? 0.6 : 0.28)
                               font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: pm.sel = parent.index; onClicked: pm.act(parent.index) }
                    }
                }
            }
        }
        Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 60; anchors.horizontalCenter: parent.horizontalCenter
               text: "ENTER  to confirm      ↑ ↓  to choose      ESC  to stay"; color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 2.5 }
    }
}
