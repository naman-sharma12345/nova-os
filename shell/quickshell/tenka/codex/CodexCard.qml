// The Codex's card (Tianxia: The Scripture), the same in both sessions: the flagship shell (Codex.qml, a
// layer-shell overlay) and Tenka Lite (/usr/share/tenka/codex/LiteCodex.qml, a small Qt window on X11).
// Every key the desk answers to, read just now from the session's own config by tenka-codex (set `g`), so a
// key the user rebinds shows up here as rebound. Type to find a key by its words or its keys; ESC closes.
// Pure QtQuick, no Quickshell. Flat: one hairline, key caps as outlines, no glow.
import QtQuick

Item {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#b5452f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property string sysFace: "Inter"
    property bool xia: false
    property var g: ({ session: "", sources: [], groups: [] })
    property string query: ""
    property int columns: width > 1000 ? 3 : 2
    width: 1120
    height: 112 + body.height + 52
    signal dismissed()

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function hit(r) {
        const q = card.query.trim().toLowerCase()
        if (q === "") return true
        const hay = (r.what + " " + r.keys.join(" ") + " " + (r.also || []).map(a => a.join(" ")).join(" ")).toLowerCase()
        return q.split(/\s+/).every(w => hay.indexOf(w) >= 0)
    }
    // the groups after the filter, dealt into columns so the columns end level: the tallest group goes to the
    // shortest column first, then each column keeps the page's own order (Open, Windows, Desks, Tenka, ...)
    readonly property var dealt: {
        const gs = []
        g.groups.forEach((gr, i) => { const ks = gr.keys.filter(hit); if (ks.length) gs.push({ name: gr.name, keys: ks, at: i }) })
        const cols = []; const h = []
        for (let i = 0; i < columns; i++) { cols.push([]); h.push(0) }
        for (const gr of gs.slice().sort((a, b) => b.keys.length - a.keys.length)) {
            let best = 0
            for (let i = 1; i < columns; i++) if (h[i] < h[best]) best = i
            cols[best].push(gr); h[best] += gr.keys.length + 1.6
        }
        for (const c of cols) c.sort((a, b) => a.at - b.at)
        return cols.filter(c => c.length).sort((a, b) => a[0].at - b[0].at)
    }
    readonly property int shown: dealt.reduce((n, c) => n + c.reduce((m, gr) => m + gr.keys.length, 0), 0)
    readonly property string home: g.sources.length ? g.sources[0] : ""

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) { if (card.query !== "") card.query = ""; else card.dismissed() }
        else if (e.key === Qt.Key_Backspace) card.query = card.query.slice(0, -1)
        else if (e.text !== "" && e.text.charCodeAt(0) >= 32 && !(e.modifiers & (Qt.ControlModifier | Qt.MetaModifier))) card.query += e.text
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    Row {
        x: 34; y: 30; spacing: 14
        Text { text: card.xia ? "THE SCRIPTURE" : "THE CODEX"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 64; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        Text { text: card.xia ? "every seal this realm answers to" : "every key this desk answers to"
               color: card.alpha(card.text, 0.5); font.family: card.uiFace; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    // the finder: what you type, or a quiet hint
    Row {
        anchors.right: parent.right; anchors.rightMargin: 34; y: 26; spacing: 10
        Text { text: card.query === "" ? "type to find a key" : card.query; font.family: card.query === "" ? card.uiFace : card.sysFace
               color: card.query === "" ? card.alpha(card.text, 0.35) : card.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 1; height: 16; color: card.accent; visible: card.query !== ""; anchors.verticalCenter: parent.verticalCenter }
        Text { text: card.query === "" ? "" : card.shown + (card.shown === 1 ? " key" : " keys"); color: card.alpha(card.text, 0.4)
               font.family: card.uiFace; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    Rectangle { x: 30; y: 70; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.35) }

    Row {
        id: body
        x: 34; y: 96; spacing: 36
        readonly property real colW: (card.width - 68 - spacing * (card.columns - 1)) / card.columns
        Repeater {
            model: card.dealt
            delegate: Column {
                required property var modelData
                width: body.colW; spacing: 18
                Repeater {
                    model: parent.modelData
                    delegate: Column {
                        required property var modelData
                        width: body.colW; spacing: 2
                        Text { text: modelData.name.toUpperCase(); color: card.gold; font.family: card.face; font.pixelSize: 11
                               font.letterSpacing: 3; bottomPadding: 6 }
                        Repeater {
                            model: modelData.keys
                            delegate: Item {
                                required property var modelData
                                width: body.colW; height: 30
                                Row {
                                    id: caps; spacing: 4; anchors.verticalCenter: parent.verticalCenter
                                    Repeater {
                                        model: [modelData.keys].concat(modelData.also || [])
                                        delegate: Row {
                                            required property var modelData
                                            required property int index
                                            spacing: 4
                                            Text { visible: index > 0; text: "or"; color: card.alpha(card.text, 0.35); font.family: card.uiFace
                                                   font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; rightPadding: 2; leftPadding: 2 }
                                            Repeater {
                                                model: modelData
                                                delegate: Rectangle {
                                                    required property string modelData
                                                    height: 20; width: Math.max(20, cap.implicitWidth + 12); radius: 3; color: "transparent"
                                                    border.width: 1; border.color: card.alpha(card.text, 0.22)
                                                    Text { id: cap; anchors.centerIn: parent; text: modelData; color: card.alpha(card.text, 0.88)
                                                           font.family: card.sysFace; font.pixelSize: 11 }
                                                }
                                            }
                                        }
                                    }
                                }
                                Text {
                                    anchors.left: caps.right; anchors.leftMargin: 14; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight
                                    text: modelData.what; elide: Text.ElideRight; color: card.alpha(card.text, 0.8)
                                    font.family: card.uiFace; font.pixelSize: 13
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Text {
        visible: card.shown === 0 && card.query !== ""
        x: 34; y: 104; text: "No key does that. ESC clears the search."; color: card.alpha(card.text, 0.5)
        font.family: card.uiFace; font.pixelSize: 13
    }
    Text {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 20; x: 34
        text: card.home === "" ? "" : "read from " + card.home + " just now  ·  rebind a key there and it reads here"
        color: card.alpha(card.text, 0.32); font.family: card.uiFace; font.pixelSize: 11
    }
    Text {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 20; anchors.right: parent.right; anchors.rightMargin: 34
        text: "ESC closes"; color: card.alpha(card.text, 0.32); font.family: card.uiFace; font.pixelSize: 11
    }
}
