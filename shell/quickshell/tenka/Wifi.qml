// The Air: our own Wi-Fi picker, in place of the plain network editor Control Center used to open. One flat
// ledger card over a dimmed desk: every network heard, strongest first, numbered in gold, the name in
// Marcellus, small caps for IN USE / SEALED / KNOWN, four flat bars for the signal. ENTER joins (a known or
// open network at once; a sealed one asks for its word on one ruled field, like the Seal), R looks again,
// ESC closes. A wrong word says so in the accent. ALL SETTINGS still opens the full editor for wired, VPN and
// the rest. Talks to NetworkManager through nmcli. qs ipc call wifi open|hide|toggle|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: air
    property bool open: false
    property var nets: []
    property var saved: []
    property bool radio: true
    property bool looking: false
    property bool busy: false
    property string asking: ""        // the network whose word is being asked
    property string note: ""
    property bool noteErr: false
    property int sel: 0
    readonly property string sim: Quickshell.env("TENKA_WIFI_SIM") || ""
    readonly property var cur: nets.length ? nets[Math.min(sel, nets.length - 1)] : null
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-air"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "wifi"
        function open(): void { air.reveal() }
        function hide(): void { air.open = false }
        function toggle(): void { air.open ? (air.open = false) : air.reveal() }
        function state(): string { return (air.open ? "open" : "closed") + " nets=" + air.nets.length + " sel=" + air.sel + (air.asking ? " asking=" + air.asking : "") + (air.note ? " note=" + air.note : "") }
    }
    Connections { target: Theme; function onAskWifi() { air.reveal() } }
    onOpenChanged: { Theme.hush = open; if (!open) { asking = ""; note = ""; field.text = "" } }

    function reveal() {
        open = true; sel = 0; note = ""; noteErr = false
        asking = (Quickshell.env("TENKA_WIFI_SIM_ASK") || "").replace(/_/g, " ")   // sim only: _ for spaces
        if (sim !== "" && Quickshell.env("TENKA_WIFI_SIM_NOTE")) { note = Quickshell.env("TENKA_WIFI_SIM_NOTE").replace(/_/g, " "); noteErr = true }
        look("auto"); keys.forceActiveFocus()
        if (asking !== "") { field.text = "kept word"; field.forceActiveFocus() }
    }
    function look(how) { if (scanQ.running) return; looking = true; scanQ.how = how; scanQ.running = true }

    // nmcli -t escapes ':' and '\' inside fields
    function fields(line) {
        const out = []; let f = ""
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (ch === "\\" && i + 1 < line.length) { f += line[++i]; continue }
            if (ch === ":") { out.push(f); f = ""; continue }
            f += ch
        }
        out.push(f); return out
    }
    function parse(t) {
        const best = {}; const sv = []; let rad = true
        for (const raw of t.split("\n")) {
            const line = raw.replace(/\r$/, "")
            if (line.startsWith("@radio ")) { rad = line.slice(7).trim() !== "disabled"; continue }
            if (line.startsWith("@saved ")) { sv.push(line.slice(7)); continue }
            if (line === "") continue
            const p = fields(line)
            if (p.length < 4 || p[1] === "") continue
            const n = { ssid: p[1], signal: parseInt(p[2]) || 0, sec: (p[3] === "--" ? "" : p[3]), use: p[0].trim() === "*" }
            const o = best[n.ssid]
            if (!o || n.use || (!o.use && n.signal > o.signal)) best[n.ssid] = n
        }
        radio = rad; saved = sv
        nets = Object.values(best).sort((a, b) => (b.use - a.use) || (b.signal - a.signal)).slice(0, 24)
        if (asking !== "") { const i = nets.findIndex(n => n.ssid === asking); if (i >= 0) sel = i }
        if (sel >= nets.length) sel = Math.max(0, nets.length - 1)
        looking = false
    }
    Process {
        id: scanQ
        property string how: "auto"
        command: air.sim !== "" ? ["sh", "-c", "cat \"$1\"", "sh", air.sim]
               : ["sh", "-c", "echo \"@radio $(nmcli -t radio wifi 2>/dev/null)\"; "
                  + "nmcli -t -f NAME,TYPE con show 2>/dev/null | sed -n 's/^\\(.*\\):802-11-wireless$/@saved \\1/p' | sed 's/\\\\:/:/g'; "
                  + "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan \"$1\" 2>/dev/null", "sh", how]
        stdout: StdioCollector { onStreamFinished: air.parse(text) }
    }

    function known(n) { return n && saved.indexOf(n.ssid) >= 0 }
    function choose() {
        const n = cur
        if (!n || busy) return
        if (n.use) { note = "Already joined to " + n.ssid + "."; noteErr = false; return }
        if (n.sec !== "" && !known(n)) { asking = n.ssid; note = ""; field.text = ""; field.forceActiveFocus(); return }
        join(n.ssid, "")
    }
    function join(ssid, word) {
        if (sim !== "") return
        busy = true; noteErr = false; note = "Joining " + ssid + " …"
        joinQ.ssid = ssid
        // A password never rides a command line: tenka-air-join reads it from stdin and hands
        // nmcli a private 0600 file, so it never shows in the process table.
        const n = nets.find(x => x.ssid === ssid)
        joinQ.word = word
        joinQ.cmd = word !== "" ? ["tenka-air-join", ssid, n ? n.sec : ""]
            : known({ ssid: ssid }) ? ["sh", "-c", "nmcli con up id \"$1\" 2>&1; echo \"@rc $?\"", "sh", ssid]
            : ["sh", "-c", "nmcli dev wifi connect \"$1\" 2>&1; echo \"@rc $?\"", "sh", ssid]
        joinQ.running = true
    }
    Process {
        id: joinQ
        property string ssid: ""
        property string word: ""
        property var cmd: []
        command: cmd
        stdinEnabled: true
        onStarted: { if (word !== "") write(word + "\n"); word = "" }
        onExited: word = ""
        stdout: StdioCollector { onStreamFinished: air.joined(text) }
    }
    function joined(t) {
        busy = false
        const m = t.match(/@rc (\d+)/); const rc = m ? parseInt(m[1]) : 1
        if (rc === 0) { note = "Joined " + joinQ.ssid + "."; noteErr = false; asking = ""; field.text = ""; look("no"); closeT.start(); return }
        const lines = t.replace(/@rc \d+\s*$/, "").trim().split("\n").filter(s => s.trim() !== "")
        const last = (lines.length ? lines[lines.length - 1] : "").replace(/^Error:\s*/, "")
        noteErr = true
        if (/secrets were required|psk|password|802-1x|wrong/i.test(last)) {
            note = "That word was not right. Try again."; asking = joinQ.ssid; field.text = ""; field.forceActiveFocus()
        } else note = last !== "" ? last : "Could not join " + joinQ.ssid + "."
    }
    Timer { id: closeT; interval: 1200; onTriggered: air.open = false }
    function setRadio(on) {
        if (sim !== "") { radio = on; return }
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]); radio = on
        if (on) rescanT.start(); else nets = []
    }
    Timer { id: rescanT; interval: 2500; onTriggered: air.look("yes") }

    // the desk steps back: one flat wash
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, air.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: air.open; onClicked: air.open = false }

    Item {
        id: card
        readonly property int rows: Math.max(3, Math.min(7, air.nets.length))
        width: 620; height: 150 + rows * 50 + (air.asking !== "" ? 104 : 0) + (air.note !== "" ? 30 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, parent.height * 0.22) + (air.open ? 0 : 16)
        opacity: air.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: !Theme.perf; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, 0.95)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.4) }
        MouseArea { anchors.fill: parent }

        Row {
            x: 34; y: 30; spacing: 14
            Text { text: Theme.xia ? "THE WINDS" : "THE AIR"; color: Theme.gold; font.family: Theme.display
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 64; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            Text { text: air.looking ? "listening …" : !air.radio ? "radio off" : air.nets.length + (air.nets.length === 1 ? " network heard" : " networks heard")
                   color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 34; y: 32
            text: air.radio ? "RADIO  ON" : "RADIO  OFF"; color: air.radio ? Theme.gold : Theme.alpha(Theme.t.text, 0.5)
            font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: air.setRadio(!air.radio) }
        }
        Rectangle { x: 30; y: 70; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.35) }

        Text {
            visible: air.nets.length === 0 && !air.looking
            x: 34; y: 96; width: parent.width - 68; wrapMode: Text.WordWrap
            text: air.radio ? "No network heard. R looks again; ALL SETTINGS has wired and VPN." : "The radio is off. Turn it on above."
            color: Theme.alpha(Theme.t.text, 0.62); font.family: Theme.display; font.pixelSize: 17
        }
        ListView {
            id: list
            x: 22; y: 82; width: parent.width - 44; height: card.rows * 50
            clip: true; interactive: air.nets.length > 7
            model: air.nets
            currentIndex: air.sel
            highlightMoveDuration: 0
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: index === air.sel
                width: list.width; height: 50
                Image { visible: row.on; source: Theme.t.stroke; width: parent.width / 0.81 * 0.98; height: 48; smooth: true; x: -6; y: 1 }
                Rectangle { visible: !row.on && row.index > 0; width: parent.width - 28; x: 14; height: 1; color: Theme.alpha(Theme.t.text, 0.07) }
                Text {
                    x: 14; width: 26; anchors.verticalCenter: parent.verticalCenter
                    text: String(row.index + 1); color: row.on ? "#fff8ec" : Theme.gold
                    font.family: Theme.display; font.pixelSize: 13
                }
                Column {
                    x: 46; width: parent.width - 130; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: row.modelData.ssid; color: row.on ? "#fff8ec" : Theme.t.text
                        font.family: Theme.display; font.pixelSize: 17
                    }
                    Text {
                        readonly property var tags: [row.modelData.use ? "IN USE" : "", row.modelData.sec !== "" ? "SEALED" : "OPEN",
                                                     air.known(row.modelData) && !row.modelData.use ? "KNOWN" : ""].filter(s => s !== "")
                        text: tags.join("  ·  "); color: row.on ? Theme.alpha("#fff8ec", 0.8) : Theme.alpha(Theme.gold, 0.8)
                        font.family: Theme.display; font.pixelSize: 9; font.letterSpacing: 2.5
                    }
                }
                Row {   // four flat bars
                    anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            width: 4; height: 5 + index * 4; anchors.bottom: parent.bottom
                            color: (row.modelData.signal > index * 25) ? (row.on ? "#fff8ec" : Theme.gold) : Theme.alpha(row.on ? "#fff8ec" : Theme.t.text, 0.18)
                        }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: { air.sel = row.index; air.choose() } }
            }
        }

        Item {
            id: ask
            visible: air.asking !== ""
            x: 30; y: list.y + list.height + 14; width: parent.width - 60; height: 96
            Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.gold, 0.25) }
            Text { x: 4; y: 16; width: parent.width - 8; elide: Text.ElideRight
                   text: "THE WORD FOR  " + air.asking.toUpperCase(); color: Theme.alpha(Theme.gold, 0.85)
                   font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
            TextField {
                id: field
                y: 34; width: parent.width; height: 48
                background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                                   color: field.activeFocus ? Theme.accent : Theme.alpha(Theme.gold, 0.4) } }
                placeholderText: "password"
                placeholderTextColor: Theme.alpha(Theme.t.text, 0.38)
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: Theme.t.text; font.family: Theme.display; font.pixelSize: 21; leftPadding: 4
                selectionColor: Theme.alpha(Theme.accent, 0.5)
                Keys.onEscapePressed: { air.asking = ""; air.note = ""; keys.forceActiveFocus() }
                onAccepted: if (text !== "") air.join(air.asking, text)
            }
        }
        Text {
            visible: air.note !== ""
            x: 34; y: air.asking !== "" ? ask.y + ask.height + 2 : list.y + list.height + 10; width: parent.width - 68; elide: Text.ElideRight
            text: air.note; color: air.noteErr ? Theme.accent : Theme.alpha(Theme.t.text, 0.62)
            font.family: Theme.display; font.pixelSize: 14
        }

        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: air.asking !== "" ? "ENTER  to join      ESC  back" : "ENTER  to join      R  to look again      ESC  to close"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: "ALL SETTINGS"; color: Theme.alpha(Theme.gold, 0.8); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                        onClicked: { air.open = false; Theme.run("setsid nm-connection-editor >/dev/null 2>&1 &") } }
        }
    }

    Item {
        id: keys
        focus: air.open && air.asking === ""
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) air.open = false
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) { if (air.nets.length) air.sel = (air.sel + 1) % air.nets.length }
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) { if (air.nets.length) air.sel = (air.sel - 1 + air.nets.length) % air.nets.length }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) air.choose()
            else if (e.key === Qt.Key_R) air.look("yes")
            else return
            e.accepted = true
        }
    }
}
