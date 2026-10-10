// The control center: a frosted column under the bar's right island. Who and how long, the
// six toggles, volume and brightness as fat brush sliders, what is playing, the two paths
// (switch packs live), and the rites (lock, rest, return, sheathe).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: cc
    property bool open: false
    visible: open || panel.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-control"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "control"
        function toggle(): void { cc.open = !cc.open }
        function hide(): void { cc.open = false }
    }

    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    readonly property var sink: Pipewire.defaultAudioSink
    property real vol: sink && sink.audio ? sink.audio.volume : 0.64
    property real bright: 0.8
    property string user: Quickshell.env("USER") || "you"
    property string up: ""
    property string net: "Offline"
    property string netKind: "wifi"
    Process { running: cc.open; command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | grep -m1 ':connected:' || (ip route 2>/dev/null | grep -q '^default' && echo ethernet:connected:Wired)"]
              stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(":"); if (p.length > 2) { cc.netKind = p[0]; cc.net = p[2] } else cc.net = "Offline" } } }
    Process { id: upP; running: cc.open; command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
              stdout: StdioCollector { onStreamFinished: cc.up = text.trim() } }
    Process { id: brP; running: cc.open; command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %"]
              stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") cc.bright = Number(text.trim()) / 100 } }

    MouseArea { anchors.fill: parent; onClicked: cc.open = false }
    Rectangle { anchors.fill: parent; opacity: panel.opacity
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.t.base, 0.45) } } }

    Glass {
        id: panel
        width: 452; height: col.height + 48; radius: 28; tint: 0.46; line: 0.18; innerLine: 0.2
        y: 44
        x: parent.width - width - 14 + (cc.open ? 0 : 40)
        opacity: cc.open ? 1 : 0
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onXChanged: place()
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            x: 24; y: 24; width: parent.width - 48; spacing: 18

            // ---- who
            Row {
                width: parent.width; spacing: 14
                Item {
                    width: 58; height: 58
                    Rectangle { anchors.fill: parent; radius: 29; color: Theme.alpha(Theme.t.base, 0.6); border.width: 2; border.color: Theme.t.gold }
                    Image { source: Theme.t.crest; anchors.centerIn: parent; width: 44; height: 44; mipmap: true }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 3; width: parent.width - 58 - 14 - 100
                    Text { text: cc.user.charAt(0).toUpperCase() + cc.user.slice(1); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 22 }
                    Text { text: Theme.t.clan + "  ·  up " + cc.up.replace(" hours", "h").replace(" minutes", "m").replace(",", "")
                           color: Theme.alpha(Theme.t.text, 0.55); font.family: Theme.ui; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight }
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 8
                    Repeater {
                        model: [["\uf023", "loginctl lock-session"], ["\uf011", "qs -c tenka ipc call power toggle"]]
                        Rectangle { required property var modelData; required property int index
                            width: 42; height: 42; radius: 21
                            color: index === 1 ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.08)
                            border.width: index === 1 ? 0 : 1; border.color: Theme.alpha(Theme.t.text, 0.14)
                            Text { anchors.centerIn: parent; text: modelData[0]; font.family: Theme.glyphs; font.pixelSize: 15; color: index === 1 ? Theme.t.ink : Theme.t.text }
                            MouseArea { anchors.fill: parent; onClicked: { cc.open = false; Theme.run(modelData[1]) } } }
                    }
                }
            }

            // ---- toggles
            Grid {
                columns: 2; columnSpacing: 12; rowSpacing: 12
                Repeater {
                    model: [
                        { g: cc.netKind === "wifi" ? "\uf1eb" : "\udb80\ude00", n: cc.netKind === "wifi" ? "Wi-Fi" : "Network", s: cc.net, on: cc.net !== "Offline" },
                        { g: "\uf293", n: "Bluetooth", s: "Off", on: false },
                        { g: Theme.stillness ? "\uf1f6" : "\uf0f3", n: Theme.t.stillWord, s: Theme.stillness ? "On · silent" : "Off", on: Theme.stillness, act: "still" },
                        { g: "\uf186", n: "Night ink", s: Theme.nightInk ? "Warm" : "Off", on: Theme.nightInk, act: "night" },
                        { g: "\uf0e7", n: "Performance", s: "Balanced", on: false },
                        { g: "\udb81\ude80", n: "Path", s: Theme.t.display, on: true, gold: true }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 196; height: 70; radius: 22
                        color: modelData.on ? (modelData.gold ? Theme.alpha(Theme.t.gold, 0.22) : Theme.alpha(Theme.t.accent, 0.92)) : Theme.alpha(Theme.t.text, 0.07)
                        border.width: 1; border.color: modelData.on ? Theme.alpha(Theme.t.gold, 0.55) : Theme.alpha(Theme.t.text, 0.12)
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Rectangle {
                            x: 12; anchors.verticalCenter: parent.verticalCenter; width: 44; height: 44; radius: 22
                            color: parent.modelData.on && !parent.modelData.gold ? Theme.alpha(Theme.t.ink, Theme.xia ? 0.14 : 0.18) : Theme.alpha(Theme.t.text, 0.08)
                            Text { anchors.centerIn: parent; text: parent.parent.modelData.g; font.family: Theme.glyphs; font.pixelSize: 17
                                   color: parent.parent.modelData.on ? (parent.parent.modelData.gold ? Theme.t.gold : Theme.t.ink) : Theme.alpha(Theme.t.text, 0.8) }
                        }
                        Column {
                            x: 66; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text { text: parent.parent.modelData.n; font.family: Theme.display; font.pixelSize: 16
                                   color: parent.parent.modelData.on && !parent.parent.modelData.gold ? Theme.t.ink : Theme.t.text }
                            Text { text: parent.parent.modelData.s; font.family: Theme.ui; font.pixelSize: 11
                                   color: Theme.alpha(parent.parent.modelData.on && !parent.parent.modelData.gold ? Theme.t.ink : Theme.t.text, 0.7) }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { const a = parent.modelData.act;
                                    if (a === "still") Theme.stillness = !Theme.stillness;
                                    if (a === "night") { Theme.nightInk = !Theme.nightInk; Theme.run(Theme.nightInk ? "pkill hyprsunset; setsid hyprsunset -t 4200 >/dev/null 2>&1 &" : "pkill hyprsunset") } } }
                    }
                }
            }

            // ---- sliders
            component Slider: Item {
                id: sl
                property real v: 0.5; property string g: ""; property string label: ""
                signal moved(real v)
                width: parent.width; height: 58
                Text { text: sl.label; color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 4 }
                Text { anchors.right: parent.right; text: Math.round(sl.v * 100) + "%"; color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 1 }
                Rectangle {
                    id: track; y: 22; width: parent.width; height: 34; radius: 17; color: Theme.alpha(Theme.t.text, 0.09)
                    border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.10)
                    Rectangle {
                        height: parent.height; radius: 17; width: Math.max(height, parent.width * sl.v)
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.alpha(Theme.t.accent, 0.75) }
                            GradientStop { position: 1; color: Theme.t.accent } }
                        Behavior on width { NumberAnimation { duration: 160 } }
                        Rectangle { anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
                                    width: 24; height: 24; radius: 12; color: Theme.t.ink; border.width: 2; border.color: Theme.t.gold }
                    }
                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: sl.g; font.family: Theme.glyphs; font.pixelSize: 15; color: Theme.t.ink }
                    MouseArea { anchors.fill: parent; onPressed: m => sl.moved(Math.max(0, Math.min(1, m.x / width)))
                                onPositionChanged: m => sl.moved(Math.max(0, Math.min(1, m.x / width))) }
                }
            }
            Slider { label: "VOLUME"; g: "\uf028"; v: cc.vol
                     onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v; cc.vol = v } }
            Slider { label: "BRIGHTNESS"; g: "\uf185"; v: cc.bright
                     onMoved: v => { cc.bright = v; Theme.run("brightnessctl set " + Math.round(v * 100) + "%") } }

            // ---- playing
            MediaCard { width: parent.width; height: 296; tint: 0.18; shadow: false; frost: false; innerLine: 0; sheen: false }

            // ---- the two paths
            Row {
                spacing: 12
                Text { text: "THE TWO PATHS"; color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 6; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 150; height: 1; anchors.verticalCenter: parent.verticalCenter
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.alpha(Theme.t.gold, 0.6) }
                        GradientStop { position: 1; color: "transparent" } } }
            }
            Row {
                spacing: 12
                Repeater {
                    model: [["samurai", "Tenka", "The way of the sword"], ["xianxia", "Tianxia", "The way of the Dao"]]
                    Item {
                        required property var modelData
                        readonly property bool cur: Theme.t.name === modelData[0]
                        width: 196; height: 118
                        Image { id: ka; anchors.fill: parent; visible: false; fillMode: Image.PreserveAspectCrop; sourceSize.width: 520
                                source: "/usr/share/tenka/themes/" + parent.modelData[0] + "/keyart.jpg" }
                        Rectangle { id: kam; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
                        MultiEffect { anchors.fill: parent; source: ka; maskEnabled: true; maskSource: kam; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
                                      brightness: parent.cur ? 0 : -0.25; saturation: parent.cur ? 0.1 : -0.4 }
                        Rectangle { anchors.fill: parent; radius: 18
                            gradient: Gradient { GradientStop { position: 0.4; color: "transparent" } GradientStop { position: 1; color: Theme.alpha("#000000", 0.75) } } }
                        Rectangle { anchors.fill: parent; radius: 18; color: "transparent"; border.width: parent.cur ? 2 : 1
                                    border.color: parent.cur ? Theme.t.gold : Theme.alpha(Theme.t.text, 0.2) }
                        Column { x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                            Text { text: parent.parent.modelData[1].toUpperCase(); color: "#f4ede0"; font.family: Theme.display; font.pixelSize: 17; font.letterSpacing: 5 }
                            Text { text: parent.parent.modelData[2]; color: Theme.alpha("#f4ede0", 0.7); font.family: Theme.ui; font.pixelSize: 11 } }
                        Rectangle { visible: parent.cur; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                                    width: 22; height: 22; radius: 11; color: Theme.t.gold
                                    Text { anchors.centerIn: parent; text: "\uf00c"; font.family: Theme.glyphs; font.pixelSize: 11; color: "#1a1410" } }
                        MouseArea { anchors.fill: parent; onClicked: Theme.run("tenka-theme " + parent.modelData[0]) }
                    }
                }
            }
        }
    }
}
