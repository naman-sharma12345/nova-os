// The bar, as little as possible: no box, no labels. Left: five tiny workspace dots (the active one
// a short accent stroke). Centre: the focused window, dim. Right: three small line glyphs and the time.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 26; right: 26 }
    implicitHeight: 28
    exclusiveZone: 30
    color: "transparent"
    WlrLayershell.namespace: "tenka-bar"

    Row {
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        spacing: 9
        Repeater {
            model: 5
            delegate: Rectangle {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool active: (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1) === wsId
                readonly property bool used: Hyprland.workspaces.values.some(w => w.id === wsId)
                anchors.verticalCenter: parent.verticalCenter
                width: active ? 18 : 5; height: 5; radius: 2.5
                color: active ? Theme.t.accent : Theme.alpha(Theme.t.text, used ? 0.75 : 0.35)
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Hyprland.dispatch("workspace " + parent.wsId) }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width * 0.4); elide: Text.ElideRight
        text: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.title ? ToplevelManager.activeToplevel.title : ""
        color: Theme.alpha(Theme.t.text, 0.45)
        font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
    }

    MouseArea {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: rightRow.width; height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: Theme.ipc("control", "toggle")
        Row {
            id: rightRow; anchors.verticalCenter: parent.verticalCenter; spacing: 14
            Repeater {
                model: ["\udb81\udda9", "\udb81\udd7e", "\udb80\udc81"]
                Text { required property string modelData; text: modelData; color: Theme.alpha(Theme.t.text, 0.7)
                       font.family: Theme.glyphs; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            Text { text: Theme.hm(Theme.now) + "  " + Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.92)
                   font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
