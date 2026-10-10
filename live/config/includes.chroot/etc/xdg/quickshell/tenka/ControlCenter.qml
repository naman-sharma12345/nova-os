// The control center: a tall glass card under the time. Who and when, quick toggles,
// volume and brightness as brush lines, what's playing, the two paths, and the power words.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: cc
    property bool open: false
    visible: open
    anchors { top: true; right: true }
    margins { top: 70; right: 16 }
    implicitWidth: 440; implicitHeight: 700
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-control"

    IpcHandler {
        target: "control"
        function toggle(): void { cc.open = !cc.open }
        function show(): void { cc.open = true }
        function hide(): void { cc.open = false }
    }
    PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
    readonly property var sink: Pipewire.defaultAudioSink
    property real bright: 0.8
    property bool perf: false
    property bool quiet: false

    component Tile: Rectangle {
        id: tile
        property string glyph: ""
        property string label: ""
        property string sub: ""
        property bool on: false
        signal clicked()
        width: 182; height: 76; radius: 18
        color: on ? Theme.alpha(Qt.color(Theme.t.accent), 0.88) : Theme.alpha(Qt.color(Theme.t.text), 0.07)
        border.width: 1; border.color: Theme.alpha(Qt.color(Theme.t.gold), on ? 0.6 : 0.18)
        Behavior on color { ColorAnimation { duration: 200 } }
        Row {
            anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 12
            Text { text: tile.glyph; font.family: Theme.glyphs; font.pixelSize: 20; color: tile.on ? Theme.t.ink : Theme.t.gold; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: tile.label; color: tile.on ? Theme.t.ink : Theme.t.text; font.family: Theme.display; font.pixelSize: 16 }
                Text { text: tile.sub; color: Theme.alpha(Qt.color(tile.on ? Theme.t.ink : Theme.t.text), 0.6); font.family: Theme.ui; font.pixelSize: 11 }
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tile.clicked() }
    }

    component Line: Item {
        id: ln
        property string glyph: ""
        property real value: 0.5
        signal moved(real v)
        width: 384; height: 34
        Text { id: g; text: ln.glyph; font.family: Theme.glyphs; font.pixelSize: 17; color: Theme.t.gold; anchors.verticalCenter: parent.verticalCenter }
        Item {
            anchors.left: g.right; anchors.leftMargin: 16; anchors.right: pct.left; anchors.rightMargin: 14
            height: parent.height
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.alpha(Qt.color(Theme.t.text), 0.14) }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * ln.value; height: 6; radius: 3; color: Theme.t.accent
                Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: 8
                            color: Theme.t.text; border.width: 2; border.color: Theme.t.gold } }
            MouseArea { anchors.fill: parent
                onPressed: m => ln.moved(Math.max(0, Math.min(1, m.x / width)))
                onPositionChanged: m => ln.moved(Math.max(0, Math.min(1, m.x / width))) }
        }
        Text { id: pct; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 40; horizontalAlignment: Text.AlignRight
               text: Math.round(ln.value * 100); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 15 }
    }

    Glass {
        anchors.fill: parent; radius: 28; tint: 0.78; line: 0.32
        Column {
            anchors.fill: parent; anchors.margins: 28; spacing: 22

            // who and when
            Row {
                spacing: 16
                Image { source: Theme.t.crest; width: 58; height: 58; smooth: true; mipmap: true }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: Qt.formatTime(Theme.now, "HH:mm"); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 40 }
                    Text { text: Qt.formatDate(Theme.now, "dddd d MMMM") + "  ·  " + Theme.hourName(Theme.now)
                           color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 1 }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.alpha(Qt.color(Theme.t.gold), 0.25) }

            Grid {
                columns: 2; rowSpacing: 12; columnSpacing: 12
                Tile { glyph: "\uf1eb"; label: "Network"; sub: "Connected"; on: true }
                Tile { glyph: "\uf293"; label: "Bluetooth"; sub: "Off" }
                Tile { glyph: "\uf1f6"; label: "Stillness"; sub: cc.quiet ? "No alerts" : "Alerts on"; on: cc.quiet; onClicked: cc.quiet = !cc.quiet }
                Tile { glyph: "\uf0e7"; label: "Performance"; sub: cc.perf ? "Motion off" : "Full motion"; on: cc.perf
                       onClicked: { cc.perf = !cc.perf; Quickshell.execDetached(["tenka-perf", cc.perf ? "on" : "off"]) } }
            }

            Column {
                spacing: 8
                Line { glyph: "\uf028"; value: cc.sink && cc.sink.audio ? cc.sink.audio.volume : 0.62
                       onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v } }
                Line { glyph: "\uf185"; value: cc.bright
                       onMoved: v => { cc.bright = v; Quickshell.execDetached(["brightnessctl", "set", Math.round(v * 100) + "%"]) } }
            }

            // what's playing
            Glass {
                width: parent.width; height: 92; radius: 20; tint: 0.35; line: 0.18
                readonly property var player: Mpris.players.values.length ? Mpris.players.values[0] : null
                Row {
                    anchors.fill: parent; anchors.margins: 16; spacing: 14
                    Rectangle { width: 60; height: 60; radius: 14; color: Theme.alpha(Qt.color(Theme.t.accent), 0.25)
                        Text { anchors.centerIn: parent; text: "\uf001"; font.family: Theme.glyphs; font.pixelSize: 22; color: Theme.t.gold } }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 4; width: 200
                        Text { text: parent.parent.parent.player ? parent.parent.parent.player.trackTitle : "Silence"; color: Theme.t.text
                               font.family: Theme.display; font.pixelSize: 17; elide: Text.ElideRight; width: parent.width }
                        Text { text: parent.parent.parent.player ? parent.parent.parent.player.trackArtist : "Nothing is playing"; color: Theme.alpha(Qt.color(Theme.t.text), 0.55)
                               font.family: Theme.ui; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 16
                        Text { text: "\uf048"; font.family: Theme.glyphs; font.pixelSize: 16; color: Theme.t.text }
                        Text { text: "\uf04b"; font.family: Theme.glyphs; font.pixelSize: 18; color: Theme.t.accent }
                        Text { text: "\uf051"; font.family: Theme.glyphs; font.pixelSize: 16; color: Theme.t.text }
                    }
                }
            }

            // the two paths
            Row {
                spacing: 12
                Repeater {
                    model: [ { k: "samurai", n: "Tenka", s: "The way of the blade" }, { k: "xianxia", n: "Tianxia", s: "The path to immortality" } ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool cur: Theme.t.name === modelData.k
                        width: 186; height: 64; radius: 16
                        color: cur ? Theme.alpha(Qt.color(Theme.t.gold), 0.18) : Theme.alpha(Qt.color(Theme.t.text), 0.06)
                        border.width: 1; border.color: Theme.alpha(Qt.color(Theme.t.gold), cur ? 0.7 : 0.18)
                        Column { anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.n.toUpperCase(); color: Theme.t.text
                                   font.family: Theme.display; font.pixelSize: 15; font.letterSpacing: 5 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.s; color: Theme.alpha(Qt.color(Theme.t.text), 0.55)
                                   font.family: Theme.ui; font.pixelSize: 11 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["tenka-theme", modelData.k]) }
                    }
                }
            }

            // power, in the pack's words
            Row {
                spacing: 8
                Repeater {
                    model: [ { g: "\uf023", w: Theme.t.lockWord, c: ["tenka-lock"] },
                             { g: "\uf186", w: Theme.t.suspendWord, c: ["systemctl", "suspend"] },
                             { g: "\uf2f1", w: Theme.t.rebootWord, c: ["systemctl", "reboot"] },
                             { g: "\uf011", w: Theme.t.shutdownWord, c: ["systemctl", "poweroff"] } ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 90; height: 64; radius: 16
                        color: pm.containsMouse ? Theme.alpha(Qt.color(Theme.t.accent), 0.85) : Theme.alpha(Qt.color(Theme.t.text), 0.06)
                        Column { anchors.centerIn: parent; spacing: 4
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.g; font.family: Theme.glyphs; font.pixelSize: 17; color: Theme.t.gold }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.w; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 13 } }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(modelData.c) }
                    }
                }
            }
        }
    }
}
