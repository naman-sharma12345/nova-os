// The Lantern (Tianxia: The Ember): our own battery and power card, the flat ledger of The Air and The Bond.
// The charge as one large number and a flat line (the accent under 20 %), the time left or the time to full in
// plain words, then the ledger: the battery's health against its design, its cycles, the draw in watts, and any
// mouse, pad or headset that reports its own charge. Below, the power profile as three words: SAVER, BALANCED,
// PERFORMANCE (power-profiles-daemon); ← → or 1 2 3 choose, ESC closes. The facts come from tenka-lantern,
// which reads the kernel's power_supply ledger, so no daemon is needed for the charge.
// qs ipc call lantern open|hide|toggle|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: lan
    property bool open: false
    property var g: ({ ac: false, batteries: [], devices: [], profile: "", profiles: [] })
    property string note: ""
    readonly property var b: g.batteries.length ? g.batteries[0] : null
    readonly property bool low: b !== null && b.pct >= 0 && b.pct < 20
    readonly property var order: ["power-saver", "balanced", "performance"]
    readonly property var names: ({ "power-saver": "SAVER", "balanced": "BALANCED", "performance": "PERFORMANCE" })
    readonly property var ledger: {
        const L = []
        if (b) {
            if (b.health >= 0) L.push({ k: "Health", v: b.health + "% of its design" })
            if (b.cycles >= 0) L.push({ k: "Cycles", v: String(b.cycles) })
            L.push({ k: b.state === "charging" ? "Taking" : "Drawing", v: b.watts > 0 ? b.watts.toFixed(1) + " W" : "nothing" })
            if (b.model !== "") L.push({ k: "Cell", v: b.model })
        }
        for (const d of g.devices) L.push({ k: d.name, v: d.pct + "%", pct: d.pct })
        return L
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-lantern"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "lantern"
        function open(): void { lan.reveal() }
        function hide(): void { lan.open = false }
        function toggle(): void { lan.open ? (lan.open = false) : lan.reveal() }
        function state(): string { return (lan.open ? "open" : "closed") + " ac=" + lan.g.ac + (lan.b ? " pct=" + lan.b.pct + " state=" + lan.b.state : " battery=none")
                                          + " profile=" + (lan.g.profile || "none") + " word=" + Theme.powerWord }
    }
    Connections { target: Theme; function onAskPower() { lan.reveal() } }
    onOpenChanged: { Theme.hush = open; if (!open) note = "" }

    Process {
        id: readP
        command: ["tenka-lantern"]
        stdout: StdioCollector { onStreamFinished: {
            try { lan.g = JSON.parse(text); Theme.powerWord = lan.word() } catch (e) {}
        } }
    }
    Process {
        id: setP
        property string want: ""
        command: ["tenka-lantern", "profile", want]
        onExited: (code, status) => { lan.note = code === 0 ? "" : "The profile did not change. Is power-profiles-daemon running?"; readP.running = true }
    }
    // every two seconds while open (the draw moves), once a minute for the ledger's word while closed
    Timer { interval: lan.open ? 2000 : 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!readP.running) readP.running = true }

    function span(s) { const m = Math.floor(Math.max(0, s) / 60); return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m + " min" }
    function word() {
        if (!b) return "On AC power"
        return b.pct + "%" + (b.left > 0 ? "  ·  " + span(b.left) : b.full > 0 ? "  ·  full in " + span(b.full) : g.ac ? "  ·  plugged in" : "")
    }
    function reveal() { note = ""; open = true; readP.running = true; card.forceActiveFocus() }
    function choose(p) {
        if (g.profiles.indexOf(p) < 0 || p === g.profile) return
        g = Object.assign({}, g, { profile: p })        // say it at once; the next read confirms it
        setP.want = p; setP.running = true
    }
    function step(d) {
        const have = order.filter(p => g.profiles.indexOf(p) >= 0)
        if (!have.length) return
        const i = Math.max(0, have.indexOf(g.profile))
        choose(have[Math.max(0, Math.min(have.length - 1, i + d))])
    }

    // the desk steps back: one flat wash
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, lan.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: lan.open; onClicked: lan.open = false }

    Item {
        id: card
        width: 560; height: 330 + lan.ledger.length * 40 + (lan.note !== "" ? 30 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, parent.height * 0.22) + (lan.open ? 0 : 16)
        opacity: lan.open ? 1 : 0
        focus: lan.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) lan.open = false
            else if (e.key === Qt.Key_Left) lan.step(-1)
            else if (e.key === Qt.Key_Right) lan.step(1)
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_3) lan.choose(lan.order[e.key - Qt.Key_1])
            else return
            e.accepted = true
        }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, 0.95)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.4) }
        MouseArea { anchors.fill: parent }

        Row {
            x: 34; y: 30; spacing: 14
            Text { text: Theme.xia ? "THE EMBER" : "THE LANTERN"; color: Theme.gold; font.family: Theme.display
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 64; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: !lan.b ? "on mains power" : lan.b.state === "charging" ? "charging" : lan.b.state === "discharging" ? "on battery"
                    : lan.b.state === "full" ? "full" : lan.g.ac ? "plugged in, resting" : lan.b.state
                color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
            }
        }
        Rectangle { x: 30; y: 70; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.35) }

        // the charge: one large number, the time in plain words beside it
        Row {
            x: 34; y: 86; spacing: 4
            Text { text: lan.b ? String(Math.max(0, lan.b.pct)) : "AC"; color: lan.low ? Theme.accent : Theme.t.text
                   font.family: Theme.display; font.pixelSize: 64 }
            Text { visible: lan.b !== null; text: "%"; color: Theme.alpha(Theme.t.text, 0.55); font.family: Theme.display
                   font.pixelSize: 24; anchors.baseline: parent.children[0].baseline }
        }
        Column {
            anchors.right: parent.right; anchors.rightMargin: 34; y: 104; spacing: 6
            Text { anchors.right: parent.right; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 20
                   text: !lan.b ? "No battery here" : lan.b.left > 0 ? lan.span(lan.b.left) : lan.b.full > 0 ? lan.span(lan.b.full)
                       : lan.b.state === "full" || lan.g.ac ? "Plugged in" : "Reading the draw …" }
            Text { anchors.right: parent.right; color: Theme.alpha(Theme.gold, 0.8); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3
                   text: !lan.b ? "ON MAINS" : lan.b.left > 0 ? "UNTIL EMPTY" : lan.b.full > 0 ? "UNTIL FULL" : lan.b.state === "full" ? "FULL" : "" }
        }
        Item {   // a flat line, a hairline tick at a fifth
            visible: lan.b !== null
            x: 34; y: 180; width: parent.width - 68; height: 4
            Rectangle { anchors.fill: parent; radius: 1; color: Theme.alpha(Theme.gold, 0.16) }
            Rectangle { height: parent.height; radius: 1; width: parent.width * Math.max(0, Math.min(1, (lan.b ? lan.b.pct : 0) / 100))
                        color: lan.low ? Theme.accent : Theme.gold
                        Behavior on width { enabled: !Theme.perf; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
            Rectangle { x: parent.width * 0.2; y: -3; width: 1; height: 10; color: Theme.alpha(Theme.t.text, 0.3) }
        }

        // the ledger: numbered in gold, the fact on the right
        Column {
            x: 30; y: 204; width: parent.width - 60
            Repeater {
                model: lan.ledger
                Item {
                    required property var modelData
                    required property int index
                    width: parent.width; height: 40
                    Text { x: 4; anchors.verticalCenter: parent.verticalCenter; text: (parent.index + 1 < 10 ? "0" : "") + (parent.index + 1)
                           color: Theme.gold; font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2 }
                    Text { x: 44; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.k; color: Theme.t.text
                           font.family: Theme.display; font.pixelSize: 16; width: 230; elide: Text.ElideRight }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Item {   // a device's own charge: the same flat line, small
                            visible: parent.parent.modelData.pct !== undefined
                            width: 54; height: 3; anchors.verticalCenter: parent.verticalCenter
                            Rectangle { anchors.fill: parent; radius: 1; color: Theme.alpha(Theme.gold, 0.16) }
                            Rectangle { height: parent.height; radius: 1; color: (parent.parent.parent.modelData.pct || 0) < 20 ? Theme.accent : Theme.gold
                                        width: parent.width * Math.max(0, Math.min(1, (parent.parent.parent.modelData.pct || 0) / 100)) }
                        }
                        Text { text: parent.parent.modelData.v; color: Theme.alpha(Theme.t.text, 0.62); font.family: Theme.display
                               font.pixelSize: 13; font.letterSpacing: 1 }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.08) }
                }
            }
        }

        // the power profile: three words, the chosen one in gold with a rule beneath
        Text { x: 34; y: 222 + lan.ledger.length * 40; text: "POWER"; color: Theme.alpha(Theme.gold, 0.8)
               font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3 }
        Row {
            x: 34; y: 248 + lan.ledger.length * 40; spacing: 30
            Repeater {
                model: lan.order
                Text {
                    required property string modelData
                    readonly property bool have: lan.g.profiles.indexOf(modelData) >= 0
                    readonly property bool on: lan.g.profile === modelData
                    text: lan.names[modelData]; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 3
                    color: on ? Theme.gold : Theme.alpha(Theme.t.text, have ? 0.6 : 0.22)
                    Rectangle { visible: parent.on; anchors.top: parent.bottom; anchors.topMargin: 6; width: parent.width - 3; height: 1; color: Theme.gold }
                    MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: parent.have; cursorShape: Qt.PointingHandCursor
                                onClicked: lan.choose(parent.modelData) }
                }
            }
        }
        Text {
            visible: lan.note !== "" || lan.g.profiles.length === 0
            x: 34; y: 284 + lan.ledger.length * 40; width: parent.width - 68; elide: Text.ElideRight
            text: lan.note !== "" ? lan.note : "Profiles appear when power-profiles-daemon runs."
            color: lan.note !== "" ? Theme.accent : Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 13
        }
        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 22
            text: "←  →  profile      1  2  3  choose      ESC  close"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
    }
}
