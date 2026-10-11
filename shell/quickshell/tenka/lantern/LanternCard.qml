// The Lantern's card (Tianxia: The Ember), the same in both sessions: the flagship shell (Lantern.qml, a
// layer-shell overlay) and Tenka Lite (/usr/share/tenka/lantern/LiteLantern.qml, a small Qt window on X11).
// Pure QtQuick, no Quickshell, so both can load it. It shows the facts tenka-lantern reads (set `g`) and asks
// for a power profile through `want`; the window around it reads the facts and sets the profile.
import QtQuick

Item {
    id: card
    width: 560; height: 330 + ledger.length * 40 + (note !== "" ? 30 : 0)
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#b5452f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property bool xia: false
    property bool motion: true
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
    signal want(string profile)
    signal dismissed()

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function span(s) { const m = Math.floor(Math.max(0, s) / 60); return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m + " min" }
    function word() {
        if (!b) return "On AC power"
        return b.pct + "%" + (b.left > 0 ? "  ·  " + span(b.left) : b.full > 0 ? "  ·  full in " + span(b.full) : g.ac ? "  ·  plugged in" : "")
    }
    function choose(p) {
        if (g.profiles.indexOf(p) < 0 || p === g.profile) return
        g = Object.assign({}, g, { profile: p })        // say it at once; the next read confirms it
        card.want(p)
    }
    function step(d) {
        const have = order.filter(p => g.profiles.indexOf(p) >= 0)
        if (!have.length) return
        const i = Math.max(0, have.indexOf(g.profile))
        choose(have[Math.max(0, Math.min(have.length - 1, i + d))])
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) card.dismissed()
        else if (e.key === Qt.Key_Left) card.step(-1)
        else if (e.key === Qt.Key_Right) card.step(1)
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_3) card.choose(card.order[e.key - Qt.Key_1])
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    Row {
        x: 34; y: 30; spacing: 14
        Text { text: card.xia ? "THE EMBER" : "THE LANTERN"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 64; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: !card.b ? "on mains power" : card.b.state === "charging" ? "charging" : card.b.state === "discharging" ? "on battery"
                : card.b.state === "full" ? "full" : card.g.ac ? "plugged in, resting" : card.b.state
            color: card.alpha(card.text, 0.5); font.family: card.uiFace; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
        }
    }
    Rectangle { x: 30; y: 70; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.35) }

    // the charge: one large number, the time in plain words beside it
    Row {
        x: 34; y: 86; spacing: 4
        Text { text: card.b ? String(Math.max(0, card.b.pct)) : "AC"; color: card.low ? card.accent : card.text
               font.family: card.face; font.pixelSize: 64 }
        Text { visible: card.b !== null; text: "%"; color: card.alpha(card.text, 0.55); font.family: card.face
               font.pixelSize: 24; anchors.baseline: parent.children[0].baseline }
    }
    Column {
        anchors.right: parent.right; anchors.rightMargin: 34; y: 104; spacing: 6
        Text { anchors.right: parent.right; color: card.text; font.family: card.face; font.pixelSize: 20
               text: !card.b ? "No battery here" : card.b.left > 0 ? card.span(card.b.left) : card.b.full > 0 ? card.span(card.b.full)
                   : card.b.state === "full" || card.g.ac ? "Plugged in" : "Reading the draw …" }
        Text { anchors.right: parent.right; color: card.alpha(card.gold, 0.8); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 3
               text: !card.b ? "ON MAINS" : card.b.left > 0 ? "UNTIL EMPTY" : card.b.full > 0 ? "UNTIL FULL" : card.b.state === "full" ? "FULL" : "" }
    }
    Item {   // a flat line, a hairline tick at a fifth
        visible: card.b !== null
        x: 34; y: 180; width: parent.width - 68; height: 4
        Rectangle { anchors.fill: parent; radius: 1; color: card.alpha(card.gold, 0.16) }
        Rectangle { height: parent.height; radius: 1; width: parent.width * Math.max(0, Math.min(1, (card.b ? card.b.pct : 0) / 100))
                    color: card.low ? card.accent : card.gold
                    Behavior on width { enabled: card.motion; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
        Rectangle { x: parent.width * 0.2; y: -3; width: 1; height: 10; color: card.alpha(card.text, 0.3) }
    }

    // the ledger: numbered in gold, the fact on the right
    Column {
        x: 30; y: 204; width: parent.width - 60
        Repeater {
            model: card.ledger
            Item {
                required property var modelData
                required property int index
                width: parent.width; height: 40
                Text { x: 4; anchors.verticalCenter: parent.verticalCenter; text: (parent.index + 1 < 10 ? "0" : "") + (parent.index + 1)
                       color: card.gold; font.family: card.face; font.pixelSize: 12; font.letterSpacing: 2 }
                Text { x: 44; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.k; color: card.text
                       font.family: card.face; font.pixelSize: 16; width: 230; elide: Text.ElideRight }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Item {   // a device's own charge: the same flat line, small
                        visible: parent.parent.modelData.pct !== undefined
                        width: 54; height: 3; anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.fill: parent; radius: 1; color: card.alpha(card.gold, 0.16) }
                        Rectangle { height: parent.height; radius: 1; color: (parent.parent.parent.modelData.pct || 0) < 20 ? card.accent : card.gold
                                    width: parent.width * Math.max(0, Math.min(1, (parent.parent.parent.modelData.pct || 0) / 100)) }
                    }
                    Text { text: parent.parent.modelData.v; color: card.alpha(card.text, 0.62); font.family: card.face
                           font.pixelSize: 13; font.letterSpacing: 1 }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: card.alpha(card.text, 0.08) }
            }
        }
    }

    // the power profile: three words, the chosen one in gold with a rule beneath
    Text { x: 34; y: 222 + card.ledger.length * 40; text: "POWER"; color: card.alpha(card.gold, 0.8)
           font.family: card.face; font.pixelSize: 10; font.letterSpacing: 3 }
    Row {
        x: 34; y: 248 + card.ledger.length * 40; spacing: 30
        Repeater {
            model: card.order
            Text {
                required property string modelData
                readonly property bool have: card.g.profiles.indexOf(modelData) >= 0
                readonly property bool on: card.g.profile === modelData
                text: card.names[modelData]; font.family: card.face; font.pixelSize: 13; font.letterSpacing: 3
                color: on ? card.gold : card.alpha(card.text, have ? 0.6 : 0.22)
                Rectangle { visible: parent.on; anchors.top: parent.bottom; anchors.topMargin: 6; width: parent.width - 3; height: 1; color: card.gold }
                MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: parent.have; cursorShape: Qt.PointingHandCursor
                            onClicked: card.choose(parent.modelData) }
            }
        }
    }
    Text {
        visible: card.note !== "" || card.g.profiles.length === 0
        x: 34; y: 284 + card.ledger.length * 40; width: parent.width - 68; elide: Text.ElideRight
        text: card.note !== "" ? card.note : "Profiles appear when power-profiles-daemon runs."
        color: card.note !== "" ? card.accent : card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 13
    }
    Text {
        x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 22
        text: "←  →  profile      1  2  3  choose      ESC  close"
        color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 12; font.letterSpacing: 2
    }
}
