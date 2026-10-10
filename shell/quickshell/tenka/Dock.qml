// The dock, auto-hiding: hidden it is a faint 40 px line at the bottom edge; touch the edge (or open
// the desk) and a long, low frosted shelf rises with hand-drawn gold line icons, no tiles. A small
// accent dot marks what is open. The crest stands apart on the left in a gold ring: the launcher.
// That is the "glass" face; the default "ledger" face is at the end of this file.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: dock
    // the dock shows by itself on an empty workspace and steps aside while you work (edge hover brings it back)
    readonly property bool shown: Theme.deskOpen || (!Theme.working && !Theme.hush)
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 120
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "tenka-dock"
    readonly property bool ledgerFace: Theme.dockStyle !== "glass"
    readonly property string peek: Quickshell.env("TENKA_DOCK_PEEK") || ""   // renders: show one name tag
    mask: Region { item: dock.shown ? (dock.ledgerFace ? lgroup : group) : edge }
    readonly property real oy: screen ? screen.height - implicitHeight : 0

    readonly property var apps: [
        { i: "terminal", n: "Terminal", id: "kitty", run: "kitty" },
        { i: "files", n: "Files", id: "thunar", run: "thunar" },
        { i: "browser", n: "Firefox", id: "firefox", run: "firefox-esr" },
        { i: "editor", n: "Notes", id: "mousepad", run: "mousepad" },
        { i: "music", n: "Music", id: "mpv", run: "mpv --player-operation-mode=pseudo-gui ~/Music" },
        { i: "store", n: "Get apps", id: "store", run: "xdg-open https://flathub.org" },
        { sep: true },
        { i: "settings", n: "Settings", id: "nwg-look", run: "nwg-look" },
        { i: "trash", n: "Trash", id: "trash", run: "thunar trash:///" }
    ]
    function running(id) {
        const tl = ToplevelManager.toplevels.values;
        for (let i = 0; i < tl.length; i++) if ((tl[i].appId || "").toLowerCase().indexOf(id) >= 0) return true;
        return false;
    }

    Timer { id: closeTimer; interval: 1600; onTriggered: if (!Theme.pinOpen) Theme.deskOpen = false }

    // hidden: the handle
    Item {
        id: edge
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        width: 260; height: 12
        Rectangle { anchors.centerIn: parent; width: 40; height: 3; radius: 2; color: Theme.alpha(Theme.t.text, 0.35)
                    opacity: dock.shown ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 200 } } }
        HoverHandler { onHoveredChanged: if (hovered) Theme.deskOpen = true }
    }

    Item {
        id: group
        visible: !dock.ledgerFace
        width: launcherBtn.width + 16 + shelf.width; height: 76
        anchors.horizontalCenter: parent.horizontalCenter
        y: dock.shown ? dock.height - height - 16 : dock.height + 10
        opacity: dock.shown ? 1 : 0
        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 240 } }
        onYChanged: { shelf.place(); launcherBtn.place() }
        HoverHandler { onHoveredChanged: if (!hovered) closeTimer.restart(); else closeTimer.stop() }

        Glass {   // the crest, apart, in a gold ring
            id: launcherBtn
            ox: 0; oy: dock.oy
            width: 64; height: 64; radius: 32; tint: 0.35; line: 0.85; y: 6
            Image { anchors.centerIn: parent; source: Theme.t.crest; width: 40; height: 40; mipmap: true
                    scale: lm.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } } }
            MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; onClicked: Theme.ipc("launcher", "toggle") }
        }
        Glass {
            id: shelf
            ox: 0; oy: dock.oy
            x: launcherBtn.width + 16; y: 6; height: 64; radius: 22; tint: 0.30; line: 0.22
            width: row.width + 36
            Row {
                id: row; anchors.centerIn: parent; spacing: 22
                Repeater {
                    model: dock.apps
                    Item {
                        id: it
                        required property var modelData
                        readonly property bool open: !modelData.sep && dock.running(modelData.id)
                        width: modelData.sep ? 1 : 46; height: 46
                        Rectangle { visible: !!it.modelData.sep; anchors.centerIn: parent; width: 1; height: 30; color: Theme.alpha(Theme.t.gold, 0.35) }
                        Image {
                            visible: !it.modelData.sep
                            anchors.centerIn: parent; width: 40; height: 40; smooth: true
                            sourceSize.width: 96; sourceSize.height: 96
                            source: it.modelData.sep ? "" : Theme.icon(it.modelData.i)
                            scale: ma.containsMouse ? 1.28 : 1
                            transformOrigin: Item.Bottom
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                        }
                        Rectangle { visible: it.open; width: 5; height: 5; radius: 2.5; color: Theme.t.accent
                                    anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: 1 }
                        Rectangle {
                            visible: ma.containsMouse
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 18
                            width: nm.width + 20; height: 24; radius: 12; color: Theme.alpha(Theme.t.base, 0.85)
                            border.width: 1; border.color: Theme.alpha(Theme.t.gold, 0.35)
                            Text { id: nm; anchors.centerIn: parent; text: it.modelData.n || ""; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 12 }
                        }
                        MouseArea { id: ma; anchors.fill: parent; enabled: !it.modelData.sep; hoverEnabled: true; onClicked: Theme.run(it.modelData.run) }
                    }
                }
            }
        }
    }

    // ======================================================== face "ledger" (Theme.dockStyle, default)
    // One low ink bar with a 1px gold rule. The crest sits inside it, plain (no ring), then a
    // hairline, then the apps as small line icons. Open apps get a short vermilion rule beneath;
    // the hovered one brightens and names itself in a small ruled tag. No bounce, no glow.
    Item {
        id: lgroup
        visible: dock.ledgerFace
        width: lbar.width; height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        y: dock.shown ? dock.height - height - 18 : dock.height + 10
        opacity: dock.shown ? 1 : 0
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onYChanged: lbar.place()
        HoverHandler { onHoveredChanged: if (!hovered) closeTimer.restart(); else closeTimer.stop() }

        Glass {
            id: lbar
            ox: 0; oy: dock.oy
            y: 4; height: 56; radius: Theme.ledgerR; tint: Theme.selfBlur ? 0.66 : 0.56; line: 0.42; sheen: false
            width: lrow.width + 44
            Row {
                id: lrow; anchors.centerIn: parent; spacing: 24
                Item {   // the crest: the launcher
                    width: 30; height: 40
                    Image { anchors.centerIn: parent; source: Theme.t.crest; width: 28; height: 28; mipmap: true
                            opacity: lcm.containsMouse ? 1 : 0.82 }
                    MouseArea { id: lcm; anchors.fill: parent; hoverEnabled: true; onClicked: Theme.ipc("launcher", "toggle") }
                }
                Rectangle { width: 1; height: 26; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.t.gold, 0.35) }
                Repeater {
                    model: dock.apps
                    Item {
                        id: li
                        required property var modelData
                        readonly property bool open: !modelData.sep && dock.running(modelData.id)
                        width: modelData.sep ? 1 : 32; height: 40
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        Rectangle { visible: !!li.modelData.sep; anchors.centerIn: parent; width: 1; height: 26; color: Theme.alpha(Theme.t.gold, 0.35) }
                        Image {
                            visible: !li.modelData.sep
                            anchors.centerIn: parent; width: 30; height: 30; smooth: true
                            sourceSize.width: 64; sourceSize.height: 64
                            source: li.modelData.sep ? "" : Theme.icon(li.modelData.i)
                            opacity: lma.containsMouse || li.open ? 1 : 0.72
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }
                        Rectangle { visible: li.open; width: 12; height: 2; color: Theme.t.accent
                                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: -4 }
                        Item {   // the name: a small ruled tag
                            visible: lma.containsMouse || (dock.peek !== "" && dock.peek === li.modelData.id)
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 22
                            width: lnm.width + 22; height: 24
                            Rectangle { anchors.fill: parent; radius: 3; color: Theme.alpha(Theme.t.base, 0.9); border.width: 1; border.color: Theme.alpha(Theme.t.gold, 0.45) }
                            Text { id: lnm; anchors.centerIn: parent; text: (li.modelData.n || "").toUpperCase(); color: Theme.t.text
                                   font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 3 }
                        }
                        MouseArea { id: lma; anchors.fill: parent; enabled: !li.modelData.sep; hoverEnabled: true; onClicked: Theme.run(li.modelData.run) }
                    }
                }
            }
        }
    }
}
