// The bar: one floating glass strip. Crest + wordmark (opens the launcher), workspaces as seals,
// the focused window's title, the tray, and the time with its old hour name (opens the control center).
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    margins { top: 12; left: 16; right: 16 }
    implicitHeight: 52
    exclusiveZone: 64
    color: "transparent"
    WlrLayershell.namespace: "tenka-bar"

    Glass {
        anchors.fill: parent
        radius: 18
        tint: 0.58

        // ---- left: crest, wordmark, seals
        Row {
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            MouseArea {
                width: crestRow.width; height: 36; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["qs", "-c", "tenka", "ipc", "call", "launcher", "toggle"])
                Row {
                    id: crestRow; spacing: 10; anchors.verticalCenter: parent.verticalCenter
                    Image { source: Theme.t.crest; width: 32; height: 32; smooth: true; mipmap: true; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Theme.t.word; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 16
                           font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Rectangle { width: 1; height: 20; color: Theme.alpha(Qt.color(Theme.t.gold), 0.35); anchors.verticalCenter: parent.verticalCenter }
            Row {
                spacing: 12; anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: 5
                    delegate: Item {
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool active: (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1) === wsId
                        readonly property bool used: Hyprland.workspaces.values.some(w => w.id === wsId)
                        width: active ? 26 : 10; height: 26
                        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Rectangle {   // the seal
                            anchors.centerIn: parent
                            width: parent.active ? 22 : (parent.used ? 8 : 6); height: width
                            radius: Theme.t.name === "xianxia" ? width / 2 : (parent.active ? 5 : 2)
                            rotation: Theme.t.name === "xianxia" && parent.active ? 45 : 0
                            color: parent.active ? Theme.t.accent : Theme.alpha(Qt.color(Theme.t.text), parent.used ? 0.75 : 0.3)
                            border.width: parent.active ? 1 : 0; border.color: Theme.t.gold
                            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Text { visible: parent.parent.active; anchors.centerIn: parent; rotation: -parent.rotation
                                   text: parent.parent.wsId; color: Theme.t.ink; font.family: Theme.display; font.pixelSize: 13 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("workspace " + parent.wsId) }
                    }
                }
            }
        }

        // ---- centre: the focused window
        Text {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width * 0.34); elide: Text.ElideRight
            text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : Theme.t.tagline
            color: Theme.alpha(Qt.color(Theme.t.text), 0.78)
            font.family: Theme.display; font.pixelSize: 15; font.letterSpacing: 2
        }

        // ---- right: tray, glyphs, time
        Row {
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            Repeater {
                model: SystemTray.items
                delegate: IconImage {
                    required property SystemTrayItem modelData
                    source: modelData.icon; implicitSize: 18; anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; onClicked: parent.modelData.activate() }
                }
            }
            Rectangle { width: 1; height: 20; color: Theme.alpha(Qt.color(Theme.t.gold), 0.35); anchors.verticalCenter: parent.verticalCenter }
            MouseArea {
                width: timeRow.width; height: 36; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["qs", "-c", "tenka", "ipc", "call", "control", "toggle"])
                Row {
                    id: timeRow; spacing: 12; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "\uf028"; color: Theme.t.text; font.family: Theme.glyphs; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "\uf1eb"; color: Theme.t.text; font.family: Theme.glyphs; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Qt.formatTime(Theme.now, "HH:mm"); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 18
                           font.letterSpacing: 2; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Theme.hourName(Theme.now); color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 13
                           font.letterSpacing: 1; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "\uf011"; color: Theme.t.accent; font.family: Theme.glyphs; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
