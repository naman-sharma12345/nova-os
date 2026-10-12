// The control center. Two faces (Theme.ccStyle: env TENKA_CC, desk.json "cc"): "ledger" (default) and "glass".
// "glass": a frosted column under the bar's right island. Who and how long, the
// six toggles, volume and brightness as fat brush sliders, what is playing, the two paths
// (switch packs live), and the rites (lock, rest, return, sheathe).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
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

    onOpenChanged: if (Theme.ccStyle === "ledger") Theme.hush = open   // the panel carries the hour; the desk steps back
    IpcHandler {
        target: "control"
        function toggle(): void { cc.open = !cc.open }
        function hide(): void { cc.open = false }
    }

    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    readonly property var sink: Pipewire.defaultAudioSink
    property real vol: sink && sink.audio ? sink.audio.volume : 0.64
    property real bright: 0.8
    property bool hasBacklight: false
    property string user: Quickshell.env("USER") || "you"
    property string up: ""
    property string net: "Offline"
    property string netKind: "wifi"
    // Bluetooth, read live from BlueZ; TENKA_BT_SIM gives renders a made-up joined device
    readonly property var btA: Bluetooth.defaultAdapter
    readonly property var btJoined: btA ? btA.devices.values.filter(d => d.connected) : []
    readonly property bool btOn: Quickshell.env("TENKA_BT_SIM") ? true : (btA !== null && btA.enabled)
    readonly property string btWord: Quickshell.env("TENKA_BT_SIM") ? "Sora Headphones"
        : !btA ? "No radio" : !btA.enabled ? "Off" : btJoined.length === 1 ? btJoined[0].name
        : btJoined.length > 1 ? btJoined.length + " joined" : "On"
    Process { running: cc.open; command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | grep -m1 ':connected:' || (ip route 2>/dev/null | grep -q '^default' && echo ethernet:connected:Wired)"]
              stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(":"); if (p.length > 2) { cc.netKind = p[0]; cc.net = p[2] } else cc.net = "Offline" } } }
    // The Watch (tenka-watch): a bell at each double-hour, when kept
    property var watch: ({ on: false, next: "", next_at: "", title: "" })
    Process { id: watchP; running: cc.open; command: ["tenka-watch", "state"]
              stdout: StdioCollector { onStreamFinished: { try { cc.watch = JSON.parse(text) } catch (e) {} } } }
    Process { id: watchSet; onExited: { watchP.running = false; watchP.running = true } }
    // The Pause (tenka-breath pause): a quiet note after a long stretch at the desk, when kept
    property var pause: ({ on: false, every: 50, next_in: null })
    Process { id: pauseP; running: cc.open; command: ["tenka-breath", "pause"]
              stdout: StdioCollector { onStreamFinished: { try { cc.pause = JSON.parse(text) } catch (e) {} } } }
    Process { id: pauseSet; onExited: { pauseP.running = false; pauseP.running = true } }
    // Night ink (tenka-nightink): off, with the sun (warms over the twilight), or warm now
    property var ink: ({ mode: "off", kelvin: 6500, on: false })
    Process { id: inkP; running: cc.open; command: ["tenka-nightink", "state"]
              stdout: StdioCollector { onStreamFinished: { try { cc.ink = JSON.parse(text); Theme.nightInk = cc.ink.on } catch (e) {} } } }
    Process { id: inkSet; stdout: StdioCollector { onStreamFinished: { try { cc.ink = JSON.parse(text); Theme.nightInk = cc.ink.on } catch (e) {} } } }
    function inkCmd(a) { inkSet.command = ["tenka-nightink", a]; inkSet.running = true }
    readonly property string inkWord: cc.ink.mode === "on" ? "Warm" : cc.ink.mode === "sun" ? (cc.ink.kelvin < 6500 ? cc.ink.kelvin + " K" : "With the sun") : "Off"
    Process { id: upP; running: cc.open; command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
              stdout: StdioCollector { onStreamFinished: cc.up = text.trim() } }
    Process { id: brP; running: cc.open; command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -1 | cut -d, -f4 | tr -d %"]
              stdout: StdioCollector { onStreamFinished: { cc.hasBacklight = text.trim() !== ""; if (cc.hasBacklight) cc.bright = Number(text.trim()) / 100 } } }

    MouseArea { anchors.fill: parent; onClicked: cc.open = false }
    Rectangle { anchors.fill: parent; opacity: panel.opacity; visible: Theme.ccStyle === "glass"   // a scrim only for the glass face (Hyprland would blur it as a full-height strip)
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.t.base, 0.45) } } }

    Glass {
        id: panel
        visible: Theme.ccStyle === "glass"
        width: 452; height: Math.min(col.height + 48, cc.height - 58); radius: 28; tint: 0.46; line: 0.18; innerLine: 0.2
        y: 44
        x: parent.width - width - 14 + (cc.open ? 0 : 40)
        opacity: cc.open ? 1 : 0
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onXChanged: place()
        MouseArea { anchors.fill: parent }

        // a short screen: the panel stops 14 px above the edge and its rows scroll
        Flickable {
            id: gfl; anchors.fill: parent; contentHeight: col.height + 48; clip: true
            boundsBehavior: Flickable.StopAtBounds; interactive: contentHeight > height + 1
        Column {
            id: col
            x: 24; y: 24; width: parent.width - 48; spacing: 18

            // ---- who
            Row {
                width: parent.width; spacing: 14
                Item {
                    width: 58; height: 58
                    Rectangle { anchors.fill: parent; radius: 29; color: Theme.alpha(Theme.t.base, 0.6); border.width: 2; border.color: Theme.gold }
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
                            color: index === 1 ? Theme.accent : Theme.alpha(Theme.t.text, 0.08)
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
                        { g: cc.netKind === "wifi" ? "\uf1eb" : "\udb80\ude00", n: cc.netKind === "wifi" ? "Wi-Fi" : "Network", s: cc.net, on: cc.net !== "Offline", act: "net" },
                        { g: "\uf293", n: "Bluetooth", s: cc.btWord, on: cc.btOn, act: "bt" },
                        { g: Theme.stillness ? "\uf1f6" : "\uf0f3", n: Theme.t.stillWord, s: Theme.stillness ? "On · silent" : "Off", on: Theme.stillness, act: "still" },
                        { g: "\uf186", n: "Night ink", s: cc.inkWord, on: cc.ink.on, act: "night" },
                        { g: "\uf0e7", n: "Performance", s: Theme.perf ? "On · still" : "Off", on: Theme.perf, act: "perf" },
                        { g: "\udb81\ude80", n: "Path", s: Theme.t.display, on: true, gold: true }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 196; height: 70; radius: 22
                        color: modelData.on ? (modelData.gold ? Theme.alpha(Theme.gold, 0.22) : Theme.alpha(Theme.accent, 0.92)) : Theme.alpha(Theme.t.text, 0.07)
                        border.width: 1; border.color: modelData.on ? Theme.alpha(Theme.gold, 0.55) : Theme.alpha(Theme.t.text, 0.12)
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Rectangle {
                            x: 12; anchors.verticalCenter: parent.verticalCenter; width: 44; height: 44; radius: 22
                            color: parent.modelData.on && !parent.modelData.gold ? Theme.alpha(Theme.t.ink, Theme.xia ? 0.14 : 0.18) : Theme.alpha(Theme.t.text, 0.08)
                            Text { anchors.centerIn: parent; text: parent.parent.modelData.g; font.family: Theme.glyphs; font.pixelSize: 17
                                   color: parent.parent.modelData.on ? (parent.parent.modelData.gold ? Theme.gold : Theme.t.ink) : Theme.alpha(Theme.t.text, 0.8) }
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
                                    if (a === "night") cc.inkCmd("toggle")
                                    if (a === "perf") { Theme.perf = !Theme.perf; Theme.run("tenka-perf " + (Theme.perf ? "on" : "off")) }
                                    if (a === "net") { cc.open = false; Theme.askWifi() }
                                    if (a === "bt") { cc.open = false; Theme.askBluetooth() }
                                    if (a === "lock") { cc.open = false; Theme.run("loginctl lock-session") } } }
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
                Text { anchors.right: parent.right; text: Math.round(sl.v * 100) + "%"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 1 }
                Rectangle {
                    id: track; y: 22; width: parent.width; height: 34; radius: 17; color: Theme.alpha(Theme.t.text, 0.09)
                    border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.10)
                    Rectangle {
                        height: parent.height; radius: 17; width: Math.max(height, parent.width * sl.v)
                        color: Theme.alpha(Theme.gold, 0.85)   // flat: value fills are one colour, no gradient
                        Behavior on width { NumberAnimation { duration: 160 } }
                        Rectangle { anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
                                    width: 24; height: 24; radius: 12; color: Theme.t.ink; border.width: 2; border.color: Theme.gold }
                    }
                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: sl.g; font.family: Theme.glyphs; font.pixelSize: 15; color: Theme.t.ink }
                    MouseArea { anchors.fill: parent; onPressed: m => sl.moved(Math.max(0, Math.min(1, m.x / width)))
                                onPositionChanged: m => sl.moved(Math.max(0, Math.min(1, m.x / width))) }
                }
            }
            Slider { label: "VOLUME"; g: "\uf028"; v: cc.vol
                     onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v; cc.vol = v } }
            Slider { label: "BRIGHTNESS"; g: "\uf185"; v: cc.bright; visible: cc.hasBacklight
                     onMoved: v => { cc.bright = v; Theme.run("brightnessctl set " + Math.round(v * 100) + "%") } }

            // ---- playing
            MediaCard { width: parent.width; height: 296; tint: 0.18; shadow: false; frost: false; innerLine: 0; sheen: false }

            // ---- the two paths
            Row {
                spacing: 12
                Text { text: "THE TWO PATHS"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 6; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 150; height: 1; anchors.verticalCenter: parent.verticalCenter
                    color: Theme.alpha(Theme.gold, 0.35) }
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
                                    border.color: parent.cur ? Theme.gold : Theme.alpha(Theme.t.text, 0.2) }
                        Column { x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                            Text { text: parent.parent.modelData[1].toUpperCase(); color: "#f4ede0"; font.family: Theme.display; font.pixelSize: 17; font.letterSpacing: 5 }
                            Text { text: parent.parent.modelData[2]; color: Theme.alpha("#f4ede0", 0.7); font.family: Theme.ui; font.pixelSize: 11 } }
                        Rectangle { visible: parent.cur; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                                    width: 22; height: 22; radius: 11; color: Theme.gold
                                    Text { anchors.centerIn: parent; text: "\uf00c"; font.family: Theme.glyphs; font.pixelSize: 11; color: "#1a1410" } }
                        MouseArea { anchors.fill: parent; onClicked: Theme.run("tenka-theme " + parent.modelData[0]) }
                    }
                }
            }
        }
        }
        // more below: the ledger's own ink fades the last rows (no scrollbar, no glow); the wheel or a drag reads on
        Rectangle { x: 1; width: parent.width - 2; height: 36; anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    visible: gfl.contentHeight > gfl.height + 1 && !gfl.atYEnd; radius: Theme.ledgerR
                    gradient: Gradient { GradientStop { position: 0; color: "transparent" }
                                          GradientStop { position: 1; color: Theme.alpha(Theme.t.base, 0.92) } } }
    }

    // ======================================================================== face "ledger"
    // Lamp-style ruled boxes: 1px gold rules, a label set into each box's top edge, numbered
    // sections (Ryoku's "01 // POWER"), text rows instead of tiles, hairline sliders. No fills, no glow.
    component Box: Item {
        id: bx
        property string num: ""; property string label: ""
        default property alias content: inner.data
        width: parent ? parent.width : 0
        height: inner.childrenRect.height + 34
        readonly property color rc: Theme.alpha(Theme.gold, 0.38)
        // 1px rules with a gap where the label sits (nothing painted behind it, so it reads on glass)
        Rectangle { x: 0; y: 8; width: 1; height: bx.height - 8; color: bx.rc }
        Rectangle { x: bx.width - 1; y: 8; width: 1; height: bx.height - 8; color: bx.rc }
        Rectangle { x: 0; y: bx.height - 1; width: bx.width; height: 1; color: bx.rc }
        Rectangle { x: 0; y: 8; width: 8; height: 1; color: bx.rc }
        Rectangle { x: lbl.x + lbl.width + 8; y: 8; width: Math.max(0, bx.width - x); height: 1; color: bx.rc }
        Text { id: lbl; x: 16; y: 1; text: bx.num + "   " + bx.label
               color: Theme.gold; font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
        Column { id: inner; x: 18; y: 26; width: bx.width - 36; spacing: 0 }
    }
    component Row2: Item {
        id: r2
        property string k: ""; property string v: ""; property bool on: false; property bool toggle: false; property bool last: false
        signal hit()
        width: parent ? parent.width : 0; height: 38
        Text { anchors.verticalCenter: parent.verticalCenter; text: r2.k; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 16 }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 12
            Text { anchors.verticalCenter: parent.verticalCenter; text: r2.v; color: Theme.alpha(Theme.t.text, 0.55); font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 1 }
            Rectangle {   // the toggle: a small square, outlined when off, filled when on
                visible: r2.toggle; anchors.verticalCenter: parent.verticalCenter
                width: 11; height: 11; radius: Theme.xia ? 6 : 1; rotation: Theme.xia ? 0 : 45
                color: r2.on ? Theme.accent : "transparent"; border.width: 1
                border.color: r2.on ? Theme.accent : Theme.alpha(Theme.t.text, 0.45)
            }
        }
        Rectangle { visible: !r2.last; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.08) }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: r2.hit() }
    }
    component Hair: Item {
        id: hs
        property real v: 0.5; property string k: ""
        signal moved(real v)
        width: parent ? parent.width : 0; height: 46
        Text { y: 4; text: hs.k; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 16 }
        Text { y: 6; anchors.right: parent.right; text: Math.round(hs.v * 100); color: Theme.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 1 }
        Item {
            y: 32; width: parent.width; height: 12
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.2) }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * hs.v; height: 2; color: Theme.gold   // value fills are one colour (gold), as in Lite
                        Behavior on width { NumberAnimation { duration: 140 } } }
            Rectangle { x: parent.width * hs.v - width / 2; anchors.verticalCenter: parent.verticalCenter
                        width: 9; height: 9; rotation: 45; color: Theme.gold }
            MouseArea { anchors.fill: parent; anchors.margins: -10
                        onPressed: m => hs.moved(Math.max(0, Math.min(1, (m.x - 10) / (width - 20))))
                        onPositionChanged: m => hs.moved(Math.max(0, Math.min(1, (m.x - 10) / (width - 20)))) }
        }
    }

    Item {
        id: ledger
        visible: Theme.ccStyle === "ledger"
        readonly property color ink: Theme.alpha(Theme.t.base, 1)
        width: 420; height: Math.min(lcol.height + 52, cc.height - 58)
        y: 44
        x: parent.width - width - 14 + (cc.open ? 0 : 40)
        opacity: cc.open ? 1 : 0
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
        MouseArea { anchors.fill: parent }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, Theme.selfBlur ? 0.9 : 0.78)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.5) }

        // a short screen: the panel stops 14 px above the edge and its rows scroll
        Flickable {
            id: lfl; anchors.fill: parent; contentHeight: lcol.height + 52; clip: true
            boundsBehavior: Flickable.StopAtBounds; interactive: contentHeight > height + 1
        Column {
            id: lcol
            x: 26; y: 24; width: parent.width - 52; spacing: 16

            // the hour, large, and who keeps it
            Item {
                width: parent.width; height: 92
                Text { id: bigT; text: Theme.hm(Theme.now); color: Theme.t.text
                       font.family: Theme.display; font.pixelSize: 64; font.letterSpacing: 2 }
                Column {
                    anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 12; spacing: 4
                    Text { anchors.right: parent.right; text: Theme.ap(Theme.now) + "  ·  " + Qt.formatDate(Theme.now, "dddd").toUpperCase(); color: Theme.gold
                           font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 4 }
                    Text { anchors.right: parent.right; text: Qt.formatDate(Theme.now, "d MMMM"); color: Theme.alpha(Theme.t.text, 0.7)
                           font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 1 }
                }
                Text { anchors.bottom: parent.bottom; text: cc.user.charAt(0).toUpperCase() + cc.user.slice(1) + "  ·  " + Theme.t.clan
                       color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 1 }
            }

            Box {
                num: "01"; label: "SIGNAL"
                // the network row opens The Air (Wifi.qml), the Bluetooth row opens The Bond (Bond.qml)
                Row2 { k: cc.netKind === "wifi" ? "Wi-Fi" : "Network"; v: cc.net; on: cc.net !== "Offline"; toggle: true
                       onHit: { cc.open = false; Theme.askWifi() } }
                Row2 { k: "Bluetooth"; v: cc.btWord; on: cc.btOn; toggle: true
                       onHit: { cc.open = false; Theme.askBluetooth() } }
                // the power row opens The Lantern (Lantern.qml): the charge, the time left, the profile
                Row2 { k: "Power"; v: Theme.powerWord; on: Theme.powerWord !== "" && Theme.powerWord !== "On AC power"; last: true
                       onHit: { cc.open = false; Theme.askPower() } }
            }
            Box {
                num: "02"; label: "SOUND"
                Hair { k: "Volume"; v: cc.vol; onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v; cc.vol = v } }
                Hair { k: "Light"; v: cc.bright; visible: cc.hasBacklight; onMoved: v => { cc.bright = v; Theme.run("brightnessctl set " + Math.round(v * 100) + "%") } }
            }
            Box {
                num: "03"; label: "QUIET"
                // Focus (tenka-focus): 25 minutes, the desk dims, notes wait and come back as one card
                Row2 { k: "Focus"; v: Theme.focus ? (Theme.focusLeft >= 0 ? Theme.focusLeft + " min" : "on") : ""; on: Theme.focus; toggle: true
                       onHit: Theme.focusCmd(["toggle"]) }
                Row2 { k: Theme.t.stillWord; v: Theme.stillness ? "silent" : ""; on: Theme.stillness; toggle: true
                       // the flag file lets the bells outside the shell (tenka-watch) keep the stillness too
                       onHit: { Theme.stillness = !Theme.stillness; Theme.run(Theme.stillness ? "touch \"$XDG_RUNTIME_DIR/tenka-still\"" : "rm -f \"$XDG_RUNTIME_DIR/tenka-still\"") } }
                Row2 { k: Theme.xia ? "The Bell Tower" : "The Watch"; v: cc.watch.on ? cc.watch.next.replace("Hour of the ", "") + "  " + cc.watch.next_at : ""
                       on: cc.watch.on; toggle: true
                       onHit: { watchSet.command = ["tenka-watch", "toggle"]; watchSet.running = true } }
                Row2 { k: Theme.xia ? "Rest the qi" : "The pause"; v: cc.pause.on ? "every " + cc.pause.every + " min" : ""
                       on: cc.pause.on; toggle: true
                       onHit: { pauseSet.command = ["tenka-breath", "pause", "toggle", "--say"]; pauseSet.running = true } }
                // a tap goes off -> with the sun -> warm now -> off
                Row2 { k: "Night ink"; v: !cc.ink.on ? "" : cc.ink.mode === "sun" && cc.ink.kelvin < 6500 ? cc.ink.kelvin + " K" : cc.inkWord.toLowerCase(); on: cc.ink.on; toggle: true
                       onHit: cc.inkCmd("cycle") }
                // Performance mode (tenka-perf): motion, blur and shadows rest; the art stays
                Row2 { k: "Performance"; v: Theme.perf ? "still" : ""; on: Theme.perf; toggle: true; last: true
                       onHit: { Theme.perf = !Theme.perf; Theme.run("tenka-perf " + (Theme.perf ? "on" : "off")) } }
            }
            Box {
                num: "04"; label: Theme.xia ? "ARTS" : "TOOLS"
                // Tenka's own tools, one row each: the Loupe waits for this card to slide away before it freezes the screen
                Row2 { k: Theme.xia ? "The Mirror" : "The Loupe"; v: "colour  ·  ruler"
                       onHit: { cc.open = false; Theme.run("sleep 0.45; qs -c tenka ipc call loupe open") } }
                Row2 { k: Theme.xia ? "The Brush" : "The Inkstone"; v: "glyphs"
                       onHit: { cc.open = false; Theme.ipc("glyphs", "open") } }
                Row2 { k: Theme.xia ? "The Scripture" : "The Codex"; v: "every key"
                       onHit: { cc.open = false; Theme.ipc("codex", "open") } }
                Row2 { k: Theme.xia ? "The Joss Stick" : "The Incense"; v: "a timer"
                       onHit: { cc.open = false; Theme.ipc("incense", "open") } }
                Row2 { k: Theme.xia ? "The Mountain Hall" : "The Garden"; v: "rain  ·  stream  ·  pines"
                       onHit: { cc.open = false; Theme.ipc("garden", "open") } }
                Row2 { k: Theme.xia ? "The Jade Record" : "The Pillow Book"; v: "a few lines a day"
                       onHit: { cc.open = false; Theme.ipc("journal", "open") } }
                Row2 { k: Theme.xia ? "Gathering Qi" : "The Breath"; v: "a minute's breath"
                       onHit: { cc.open = false; Theme.ipc("breath", "open") } }
                Row2 { k: Theme.xia ? "The Lineage" : "The Colophon"; v: "this machine"; last: true
                       onHit: { cc.open = false; Theme.ipc("colophon", "open") } }
            }
            Box {
                num: "05"; label: "PATH"
                Item {
                    width: parent.width; height: 40
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 26
                        Repeater {
                            model: [["samurai", "Tenka"], ["xianxia", "Tianxia"]]
                            Row {
                                required property var modelData
                                readonly property bool cur: Theme.t.name === modelData[0]
                                spacing: 9
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; rotation: 45
                                            color: parent.cur ? Theme.gold : "transparent"; border.width: 1; border.color: Theme.gold }
                                Text { text: parent.modelData[1]; color: parent.cur ? Theme.t.text : Theme.alpha(Theme.t.text, 0.5)
                                       font.family: Theme.display; font.pixelSize: 16; font.letterSpacing: 1
                                       MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theme.run("tenka-theme " + parent.parent.modelData[0]) } }
                            }
                        }
                    }
                }
            }
            // the rites, as words on one line
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 30
                Repeater {
                    model: [[Theme.t.lockWord, "loginctl lock-session"], [Theme.t.suspendWord, "systemctl suspend"],
                            [Theme.t.rebootWord, "systemctl reboot"], [Theme.t.shutdownWord, "systemctl poweroff"]]
                    Text {
                        required property var modelData; required property int index
                        text: modelData[0].toUpperCase(); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 4
                        color: ra.containsMouse ? (index === 3 ? Theme.accent : Theme.gold) : Theme.alpha(Theme.t.text, 0.62)
                        MouseArea { id: ra; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { cc.open = false; Theme.run(parent.modelData[1]) } }
                    }
                }
            }
        }
        }
        // more below: the ledger's own ink fades the last rows (no scrollbar, no glow); the wheel or a drag reads on
        Rectangle { x: 1; width: parent.width - 2; height: 36; anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    visible: lfl.contentHeight > lfl.height + 1 && !lfl.atYEnd; radius: Theme.ledgerR
                    gradient: Gradient { GradientStop { position: 0; color: "transparent" }
                                          GradientStop { position: 1; color: Theme.alpha(Theme.t.base, 0.92) } } }
    }
}
