// The Bond: our own Bluetooth card (Tianxia: The Thread), in place of a stock manager window. Same flat
// ledger as The Air: every device the radio knows or hears, joined first, then paired, then near, numbered in
// gold, the name in Marcellus, small caps for the kind and JOINED / PAIRED / NEAR, a flat battery line when the
// device reports one. ENTER joins (pairs first if needed, then trusts and connects) or parts a joined device,
// F forgets, R looks again, ESC closes. The radio listens only while the card is open. Talks to BlueZ through
// Quickshell.Bluetooth. qs ipc call bluetooth open|hide|toggle|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: bond
    property bool open: false
    property int sel: 0
    property int tick: 0
    property string note: ""
    property bool noteErr: false
    property string pendAddr: ""      // the device an action is waiting on
    property string pendAct: ""       // "pair" | "connect" | "part"
    property int pendAge: 0
    property bool pendSeenPairing: false
    // a question from the pairing agent (tenka-bond-agent): {id, kind, name, address, code, service, entered}
    // kind: pin | passkey | confirm | authorize | service | display-pin | display-passkey
    property var q: null
    readonly property bool typing: q !== null && (q.kind === "pin" || q.kind === "passkey")
    readonly property bool shows: q !== null && (q.kind === "confirm" || q.kind === "display-pin" || q.kind === "display-passkey")
    // sim (renders only): TENKA_BT_SIM=1 gives a made-up radio and devices
    readonly property string sim: Quickshell.env("TENKA_BT_SIM") || ""
    property bool simRadio: true
    property var simDevs: [
        { name: "Sora Headphones", address: "A0:01", icon: "audio-headset", connected: true, paired: true, pairing: false, batteryAvailable: true, battery: 0.72 },
        { name: "Keychron K3", address: "A0:02", icon: "input-keyboard", connected: false, paired: true, pairing: false, batteryAvailable: true, battery: 0.31 },
        { name: "MX Anywhere 3", address: "A0:03", icon: "input-mouse", connected: false, paired: true, pairing: false, batteryAvailable: false, battery: 0 },
        { name: "Pixel 9", address: "A0:04", icon: "phone", connected: false, paired: false, pairing: false, batteryAvailable: false, battery: 0 },
        { name: "Living Room Speaker", address: "A0:05", icon: "audio-card", connected: false, paired: false, pairing: false, batteryAvailable: false, battery: 0 }
    ]
    readonly property var adapter: sim !== "" ? null : Bluetooth.defaultAdapter
    readonly property bool hasRadio: sim !== "" || adapter !== null
    readonly property bool radio: sim !== "" ? simRadio : (adapter !== null && adapter.enabled)
    readonly property bool looking: sim !== "" ? false : (adapter !== null && adapter.discovering)
    readonly property var devs: {
        tick
        if (!radio) return []
        const src = sim !== "" ? simDevs : (adapter ? adapter.devices.values : [])
        // a device heard only by address is noise; keep it if it is ours (paired)
        const named = src.filter(d => d.paired || (d.name && d.name !== d.address && d.name.replace(/[-:]/g, "") !== d.address.replace(/[-:]/g, "")))
        const rank = d => d.connected ? 0 : d.paired ? 1 : 2
        return named.slice().sort((a, b) => rank(a) - rank(b) || (a.name || "").localeCompare(b.name || ""))
    }
    readonly property var cur: devs.length ? devs[Math.min(sel, devs.length - 1)] : null
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-bond"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "bluetooth"
        function open(): void { bond.reveal() }
        function hide(): void { bond.open = false }
        function toggle(): void { bond.open ? (bond.open = false) : bond.reveal() }
        function ask(): void { askFile.reload() }
        function state(): string { return (bond.open ? "open" : "closed") + (bond.q ? " ask=" + bond.q.kind : "") + " radio=" + (bond.hasRadio ? (bond.radio ? "on" : "off") : "none") + " devs=" + bond.devs.length + " sel=" + bond.sel + (bond.note ? " note=" + bond.note : "") }
    }
    Connections { target: Theme; function onAskBluetooth() { bond.reveal() } }
    onOpenChanged: {
        Theme.hush = open
        if (sim === "" && adapter && adapter.enabled) adapter.discovering = open
        if (!open) { if (q) refuse(); note = ""; pendAddr = "" }
    }
    // the agent leaves its question in a private file and rings `qs ipc call bluetooth ask`
    FileView {
        id: askFile
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/tenka-bond/ask.json"
        printErrors: false
        onLoaded: bond.heard(text())
    }
    Process {
        id: answerP
        property string line: ""
        command: ["tenka-bond-agent", "answer"]
        stdinEnabled: true
        onStarted: { write(line + "\n"); line = "" }
    }
    function heard(t) {
        let o = null
        try { o = JSON.parse(t) } catch (e) { return }
        if (!o || o.kind === "none") { if (q && (!o || o.id === q.id)) q = null; return }
        const fresh = !q || q.id !== o.id
        if (!open) reveal()
        q = o
        if (fresh) { const i = devs.findIndex(d => d.address === o.address); if (i >= 0) sel = i }
        if (fresh) { pendAge = 0; field.text = "" }
        if (typing) field.forceActiveFocus(); else keys.forceActiveFocus()
    }
    function reply(v) {
        if (!q) return
        if (q.kind !== "display-pin" && q.kind !== "display-passkey" && sim === "") {
            answerP.line = q.id + " " + v; answerP.running = true
        }
        if (v === "no" || v === "cancel") say("Refused " + q.name + ".", true)
        q = null; field.text = ""; keys.forceActiveFocus()
    }
    function refuse() { reply(q && (q.kind === "confirm" || q.kind === "authorize" || q.kind === "service") ? "no" : "cancel") }
    function spaced(c) { return c.length === 6 ? c.slice(0, 3) + " " + c.slice(3) : c }
    Timer { interval: 1000; repeat: true; running: bond.open; onTriggered: { bond.tick++; bond.follow() } }

    function reveal() {
        open = true; sel = 0; note = ""; noteErr = false; tick++
        if (sim !== "" && Quickshell.env("TENKA_BT_SIM_NOTE")) { note = Quickshell.env("TENKA_BT_SIM_NOTE").replace(/_/g, " "); noteErr = true }
        if (sim !== "" && Quickshell.env("TENKA_BT_SIM_SEL")) sel = parseInt(Quickshell.env("TENKA_BT_SIM_SEL"))
        if (sim !== "" && Quickshell.env("TENKA_BT_SIM_OFF")) simRadio = false
        keys.forceActiveFocus()
        const sq = sim !== "" ? (Quickshell.env("TENKA_BT_SIM_ASK") || "") : ""
        if (sq !== "" && !q) {
            const d = devs[Math.min(sel, devs.length - 1)]
            q = { id: 1, kind: sq, name: d ? d.name : "a device", address: d ? d.address : "", code: Quickshell.env("TENKA_BT_SIM_CODE") || "",
                  service: "music", entered: parseInt(Quickshell.env("TENKA_BT_SIM_ENTERED") || "-1") }
            if (typing) { field.text = Quickshell.env("TENKA_BT_SIM_TYPED") || ""; field.forceActiveFocus() }
        }
    }
    function say(t, err) { note = t; noteErr = !!err }
    function kind(d) {
        const i = (d.icon || "")
        return /headset|headphone/.test(i) ? "HEADPHONES" : /keyboard/.test(i) ? "KEYBOARD" : /mouse/.test(i) ? "MOUSE"
             : /phone/.test(i) ? "PHONE" : /audio|speaker/.test(i) ? "SPEAKER" : /gaming|joystick/.test(i) ? "CONTROLLER"
             : /computer/.test(i) ? "COMPUTER" : ""
    }
    function setRadio(on) {
        if (sim !== "") { simRadio = on; tick++; return }
        if (!adapter) return
        adapter.enabled = on
        if (on && open) Qt.callLater(() => { if (bond.adapter) bond.adapter.discovering = true })
    }
    function look() { if (sim === "" && adapter && adapter.enabled) { adapter.discovering = false; adapter.discovering = true } tick++ }
    function choose() {
        const d = cur
        if (!d || pendAddr !== "") return
        if (sim !== "") { say((d.connected ? "Parted from " : "Joined ") + d.name + ".", false); return }
        pendAddr = d.address; pendAge = 0; pendSeenPairing = false
        if (d.connected) { pendAct = "part"; say("Parting from " + d.name + " …"); d.disconnect() }
        else if (d.paired) { pendAct = "connect"; say("Joining " + d.name + " …"); d.connect() }
        else { pendAct = "pair"; say("Pairing with " + d.name + " …"); d.pair() }
    }
    function forget() {
        const d = cur
        if (!d || !d.paired) return
        if (sim !== "") { say("Forgot " + d.name + ".", false); return }
        const n = d.name; d.forget(); say("Forgot " + n + ".", false); tick++
    }
    // one-second follow-through on the action in hand: pair -> trust -> connect, with a plain word at the end
    function follow() {
        if (pendAddr === "" || sim !== "") return
        const d = (adapter ? adapter.devices.values : []).find(x => x.address === pendAddr)
        if (!d) { say("The device went quiet.", true); pendAddr = ""; return }
        if (q !== null) return              // the clock waits while the device asks for its code
        pendAge++
        if (pendAct === "pair") {
            if (d.pairing) pendSeenPairing = true
            if (d.paired) { d.trusted = true; pendAct = "connect"; pendAge = 0; say("Paired. Joining " + d.name + " …"); d.connect() }
            else if ((pendSeenPairing && !d.pairing) || pendAge > 30) { say("Could not pair with " + d.name + ". Put it in pairing mode and try again.", true); pendAddr = "" }
        } else if (pendAct === "connect") {
            if (d.connected) { say("Joined " + d.name + ".", false); pendAddr = "" }
            else if (pendAge > 20) { say(d.name + " did not answer. Is it on and near?", true); pendAddr = "" }
        } else if (pendAct === "part") {
            if (!d.connected) { say("Parted from " + d.name + ".", false); pendAddr = "" }
            else if (pendAge > 10) { say(d.name + " would not let go.", true); pendAddr = "" }
        }
    }

    // the desk steps back: one flat wash
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, bond.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: bond.open; onClicked: bond.open = false }

    Item {
        id: card
        readonly property int rows: Math.max(3, Math.min(7, bond.devs.length))
        width: 620; height: 150 + rows * 50 + (bond.q ? 118 : 0) + (bond.note !== "" ? 30 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, parent.height * 0.22) + (bond.open ? 0 : 16)
        opacity: bond.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: !Theme.perf; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, 0.95)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.4) }
        MouseArea { anchors.fill: parent }

        Row {
            x: 34; y: 30; spacing: 14
            Text { text: Theme.xia ? "THE THREAD" : "THE BOND"; color: Theme.gold; font.family: Theme.display
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 64; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            Text {
                readonly property int mine: bond.devs.filter(d => d.paired).length
                text: !bond.hasRadio ? "no radio" : !bond.radio ? "radio off"
                    : mine + " paired  ·  " + (bond.devs.length - mine) + " near" + (bond.looking ? "  ·  listening" : "")
                color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            visible: bond.hasRadio
            anchors.right: parent.right; anchors.rightMargin: 34; y: 32
            text: bond.radio ? "RADIO  ON" : "RADIO  OFF"; color: bond.radio ? Theme.gold : Theme.alpha(Theme.t.text, 0.5)
            font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: bond.setRadio(!bond.radio) }
        }
        Rectangle { x: 30; y: 70; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.35) }

        Text {
            visible: bond.devs.length === 0
            x: 34; y: 96; width: parent.width - 68; wrapMode: Text.WordWrap
            text: !bond.hasRadio ? "No Bluetooth radio in this machine." : !bond.radio ? "The radio is off. Turn it on above."
                : "Nothing heard yet. Put the device in pairing mode; R looks again."
            color: Theme.alpha(Theme.t.text, 0.62); font.family: Theme.display; font.pixelSize: 17
        }
        ListView {
            id: list
            x: 22; y: 82; width: parent.width - 44; height: card.rows * 50
            clip: true; interactive: bond.devs.length > 7
            model: bond.devs
            currentIndex: bond.sel
            highlightMoveDuration: 0
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: index === bond.sel
                readonly property color ink: on ? "#fff8ec" : Theme.t.text
                width: list.width; height: 50
                Image { visible: row.on; source: Theme.t.stroke; width: parent.width / 0.81 * 0.98; height: 48; smooth: true; x: -6; y: 1 }
                Rectangle { visible: !row.on && row.index > 0; width: parent.width - 28; x: 14; height: 1; color: Theme.alpha(Theme.t.text, 0.07) }
                Text {
                    x: 14; width: 26; anchors.verticalCenter: parent.verticalCenter
                    text: String(row.index + 1); color: row.on ? "#fff8ec" : Theme.gold
                    font.family: Theme.display; font.pixelSize: 13
                }
                Column {
                    x: 46; width: parent.width - 170; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: row.modelData.name; color: row.ink
                        font.family: Theme.display; font.pixelSize: 17
                    }
                    Text {
                        readonly property var tags: [bond.kind(row.modelData),
                            row.modelData.pairing ? "PAIRING" : row.modelData.connected ? "JOINED" : row.modelData.paired ? "PAIRED" : "NEAR"].filter(s => s !== "")
                        text: tags.join("  ·  "); color: row.on ? Theme.alpha("#fff8ec", 0.8) : Theme.alpha(Theme.gold, 0.8)
                        font.family: Theme.display; font.pixelSize: 9; font.letterSpacing: 2.5
                    }
                }
                Row {   // battery: a flat line and the number, only when the device tells
                    visible: row.modelData.batteryAvailable
                    anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Item {
                        width: 54; height: 6; anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.fill: parent; radius: 1; color: Theme.alpha(row.ink, 0.18) }
                        Rectangle { height: parent.height; radius: 1; width: parent.width * Math.max(0, Math.min(1, row.modelData.battery))
                                    color: row.on ? "#fff8ec" : row.modelData.battery < 0.2 ? Theme.accent : Theme.gold }
                    }
                    Text { text: Math.round(row.modelData.battery * 100) + "%"; color: Theme.alpha(row.ink, 0.7)
                           font.family: Theme.display; font.pixelSize: 12; width: 34; horizontalAlignment: Text.AlignRight }
                }
                MouseArea { anchors.fill: parent; onClicked: { bond.sel = row.index; bond.choose() } }
            }
        }
        Item {
            id: quest
            visible: bond.q !== null
            readonly property string who: bond.q ? String(bond.q.name).toUpperCase() : ""
            x: 30; y: list.y + list.height + 14; width: parent.width - 60; height: 104
            Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.gold, 0.25) }
            Text {
                x: 4; y: 16; width: parent.width - 8; elide: Text.ElideRight
                color: Theme.alpha(Theme.gold, 0.85); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4
                text: !bond.q ? "" : bond.q.kind === "pin" ? "THE PIN FOR  " + quest.who
                    : bond.q.kind === "passkey" ? "THE PASSKEY FOR  " + quest.who
                    : bond.q.kind === "confirm" ? "DOES  " + quest.who + "  SHOW THIS NUMBER"
                    : bond.q.kind === "authorize" ? "LET  " + quest.who + "  PAIR"
                    : bond.q.kind === "service" ? "LET  " + quest.who + "  USE  " + String(bond.q.service).toUpperCase()
                    : "TYPE THIS ON  " + quest.who + ",  THEN ENTER THERE"
            }
            TextField {
                id: field
                visible: bond.typing
                y: 34; width: parent.width; height: 52
                background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                                   color: field.activeFocus ? Theme.accent : Theme.alpha(Theme.gold, 0.4) } }
                placeholderText: bond.q && bond.q.kind === "passkey" ? "six digits" : "the pin it asks for, often 0000"
                placeholderTextColor: Theme.alpha(Theme.t.text, 0.38)
                maximumLength: bond.q && bond.q.kind === "passkey" ? 6 : 16
                validator: RegularExpressionValidator { regularExpression: bond.q && bond.q.kind === "passkey" ? /[0-9]{0,6}/ : /[ -~]{0,16}/ }
                inputMethodHints: bond.q && bond.q.kind === "passkey" ? Qt.ImhDigitsOnly : Qt.ImhNone
                color: Theme.t.text; font.family: Theme.display; font.pixelSize: 24; font.letterSpacing: 6; leftPadding: 4
                selectionColor: Theme.alpha(Theme.accent, 0.5)
                Keys.onEscapePressed: bond.refuse()
                onAccepted: if (text !== "") bond.reply(text)
            }
            Row {
                visible: bond.shows
                x: 4; y: 38; spacing: 4
                Repeater {
                    model: bond.q && bond.shows ? bond.spaced(String(bond.q.code)).split("") : []
                    Text {
                        required property string modelData
                        required property int index
                        // digits already typed on the device turn gold (DisplayPasskey counts them)
                        readonly property int digit: index > 3 ? index - 1 : index
                        color: bond.q && bond.q.entered > digit && modelData !== " " ? Theme.gold : Theme.t.text
                        text: modelData; font.family: Theme.display; font.pixelSize: 36; width: modelData === " " ? 18 : implicitWidth
                    }
                }
            }
            Text {
                visible: bond.q !== null && !bond.typing && !bond.shows
                x: 4; y: 44; width: parent.width - 8; elide: Text.ElideRight
                text: bond.q ? String(bond.q.name) + (bond.q.address ? "   ·   " + bond.q.address : "") : ""
                color: Theme.t.text; font.family: Theme.display; font.pixelSize: 21
            }
        }
        Text {
            visible: bond.note !== ""
            x: 34; y: bond.q ? quest.y + quest.height + 2 : list.y + list.height + 10; width: parent.width - 68; elide: Text.ElideRight
            text: bond.note; color: bond.noteErr ? Theme.accent : Theme.alpha(Theme.t.text, 0.62)
            font.family: Theme.display; font.pixelSize: 14
        }
        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: bond.q ? (bond.typing ? "ENTER  to send      ESC  to refuse"
                          : bond.q.kind === "confirm" ? "ENTER  if it matches      ESC  if not"
                          : bond.shows ? "type it on the device      ESC  to hide"
                          : "ENTER  to allow      ESC  to refuse")
                : (bond.cur && bond.cur.connected ? "ENTER  to part" : "ENTER  to join") + (bond.cur && bond.cur.paired ? "      F  to forget" : "")
                + "      R  to look again      ESC  to close"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
    }

    Item {
        id: keys
        focus: bond.open && !bond.typing
        Keys.onPressed: e => {
            const n = bond.devs.length
            if (bond.q !== null) {
                if (e.key === Qt.Key_Escape) bond.shows && bond.q.kind !== "confirm" ? (bond.q = null) : bond.refuse()
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (!bond.typing && (bond.q.kind === "confirm" || !bond.shows)) bond.reply("yes") }
                else return
                e.accepted = true
                return
            }
            if (e.key === Qt.Key_Escape) bond.open = false
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) { if (n) bond.sel = (bond.sel + 1) % n }
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) { if (n) bond.sel = (bond.sel - 1 + n) % n }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) bond.choose()
            else if (e.key === Qt.Key_F || e.key === Qt.Key_Delete) bond.forget()
            else if (e.key === Qt.Key_R) bond.look()
            else return
            e.accepted = true
        }
    }
}
