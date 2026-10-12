// Under Heaven (Tianxia: The Four Seas): the hour in the places you keep, the same card in both sessions, the
// flagship shell (Clocks.qml) and Tenka Lite (/usr/share/tenka/clocks/LiteClocks.qml). Each place: its time, how
// far from here, its old double-hour, and its own day as one hairline (the daylight gold, the twilight fainter, a
// mark for now). tenka-clocks works out the offsets and the sun on this machine; this card ticks the minutes and
// only asks (signals addAsked / removeAsked). A adds a place (type, Enter), Up/Down choose, Delete lets one go,
// Esc closes. Flat, no glow: the ink is the theme's text, gold only for the daylight.
import QtQuick

Item {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#d8412f"
    property real radius: 6
    property string face: "Marcellus"
    property bool xia: false
    property var s: ({ title: "Under Heaven", here: null, cities: [], max: 6 })
    property var zones: []
    property double now: Date.now()
    property double nowOverride: 0           // renders: a fixed moment (ms)
    property int sel: -1                     // the chosen place (keyboard), for Delete
    property bool adding: false
    signal dismissed()
    signal addAsked(string zone)
    signal removeAsked(string zone)

    readonly property var rows: s && s.here ? [s.here].concat(s.cities || []) : (s && s.cities ? s.cities : [])
    readonly property double t: nowOverride > 0 ? nowOverride : now
    readonly property var animals: ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
    width: 520
    height: col.height + 56

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function local(c) { return new Date(t + c.offset * 1000) }        // read with the UTC getters
    function mins(c) { const d = local(c); return d.getUTCHours() * 60 + d.getUTCMinutes() }
    function hm(m) { return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0") }
    function ymd(d) { return d.getUTCFullYear() * 10000 + (d.getUTCMonth() + 1) * 100 + d.getUTCDate() }
    function dayWord(c) {
        if (!s.here || c.here) return ""
        const a = ymd(local(c)), b = ymd(local(s.here))
        return a > b ? "Tomorrow" : a < b ? "Yesterday" : ""
    }
    function rel(c) {
        if (c.here) return "Here"
        let d = Math.round((c.offset - (s.here ? s.here.offset : 0)) / 60)
        if (d === 0) return "Same hour"
        const sg = d > 0 ? "+" : "\u2013"; d = Math.abs(d)
        return sg + Math.floor(d / 60) + (d % 60 ? ":" + String(d % 60).padStart(2, "0") : " h")
    }
    function phase(c) {
        const m = mins(c)
        if (c.rise === null || c.rise === undefined || c.set === null || c.set === undefined) return c.up ? "Day" : "Night"
        const lean = 45, dawn = c.dawn !== null ? c.dawn : c.rise - lean, dusk = c.dusk !== null ? c.dusk : c.set + lean
        return m >= dawn && m < c.rise + lean ? "Dawn" : m >= c.rise + lean && m < c.set - lean ? "Day"
             : m >= c.set - lean && m < dusk ? "Dusk" : "Night"
    }
    function hourName(c) { const h = Math.floor(mins(c) / 60); return "Hour of the " + animals[Math.floor((h + 1) / 2) % 12] }
    readonly property var hits: {
        const w = query.text.toLowerCase().replace(/ /g, "_")
        if (!adding || w.length < 2) return []
        const kept = rows.map(r => r.zone)
        let h = zones.filter(z => z.zone.toLowerCase().indexOf(w) >= 0 && kept.indexOf(z.zone) < 0)
        h.sort((a, b) => (a.name.toLowerCase().replace(/ /g, "_").startsWith(w) ? 0 : 1) - (b.name.toLowerCase().replace(/ /g, "_").startsWith(w) ? 0 : 1)
                         || a.zone.length - b.zone.length)
        return h.slice(0, 4)
    }
    function beginAdd() { if ((s.cities || []).length >= (s.max || 6)) return; adding = true; query.text = ""; query.forceActiveFocus() }
    function typed(w) { query.text = w }                                  // renders and tests
    function endAdd() { adding = false; query.text = ""; card.forceActiveFocus() }

    Timer { interval: 1000; repeat: true; running: card.visible && card.nowOverride <= 0; onTriggered: card.now = Date.now() }

    focus: true
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) { if (adding) endAdd(); else card.dismissed(); e.accepted = true }
        else if (adding) return
        else if (e.key === Qt.Key_A || e.key === Qt.Key_Plus) { beginAdd(); e.accepted = true }
        else if (e.key === Qt.Key_Down) { sel = Math.min(rows.length - 1, sel + 1); e.accepted = true }
        else if (e.key === Qt.Key_Up) { sel = Math.max(-1, sel - 1); e.accepted = true }
        else if ((e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) && sel >= 0 && rows[sel] && !rows[sel].here) {
            card.removeAsked(rows[sel].zone); sel = -1; e.accepted = true }
    }

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.base; border.width: 1; border.color: card.alpha(card.text, 0.12) }
    MouseArea { anchors.fill: parent; onClicked: card.forceActiveFocus() }   // a click on the card is not a click away

    Column {
        id: col
        x: 34; y: 30; width: card.width - 68; spacing: 0
        Text { text: card.s.title || (card.xia ? "The Four Seas" : "Under Heaven"); color: card.text; font.family: card.face; font.pixelSize: 26 }
        Item { width: 1; height: 6 }
        Text { text: card.xia ? "THE HOUR ACROSS THE FOUR SEAS" : "THE HOUR IN THE PLACES YOU KEEP"; color: card.gold
               font.family: card.face; font.pixelSize: 11; font.letterSpacing: 3 }
        Item { width: 1; height: 18 }
        Rectangle { width: parent.width; height: 1; color: card.alpha(card.text, 0.12) }

        Repeater {
            model: card.rows
            Item {
                id: row
                required property var modelData
                required property int index
                readonly property var c: modelData
                readonly property bool night: card.phase(c) === "Night"
                width: col.width; height: 92
                Rectangle { visible: card.sel === row.index; x: -18; y: 22; width: 2; height: 40; color: card.gold }
                Text { y: 18; text: row.c.name; color: card.text; font.family: card.face; font.pixelSize: 20 }
                Text {
                    y: 46
                    text: [card.dayWord(row.c), card.rel(row.c), card.phase(row.c), card.hourName(row.c)].filter(x => x).join("  \u00b7  ").toUpperCase()
                    color: card.alpha(card.text, row.c.here ? 0.7 : 0.5); font.family: card.face; font.pixelSize: 11; font.letterSpacing: 1.6
                }
                Text { anchors.right: parent.right; y: 12; text: card.hm(card.mins(row.c)); color: card.alpha(card.text, row.night ? 0.62 : 0.95)
                       font.family: card.face; font.pixelSize: 34 }
                // the day, midnight to midnight: twilight faint, daylight gold, a mark for now
                Item {
                    y: 72; width: parent.width; height: 9
                    readonly property real w: width
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: card.alpha(card.text, 0.16) }
                    Rectangle { visible: row.c.dawn !== null && row.c.dusk !== null && row.c.dawn !== undefined
                                anchors.verticalCenter: parent.verticalCenter; height: 2; color: card.alpha(card.gold, 0.35)
                                x: parent.w * (row.c.dawn || 0) / 1440; width: parent.w * ((row.c.dusk || 0) - (row.c.dawn || 0)) / 1440 }
                    Rectangle { visible: (row.c.rise !== null && row.c.rise !== undefined) || row.c.up === true
                                anchors.verticalCenter: parent.verticalCenter; height: 2; color: card.gold
                                x: row.c.rise !== null && row.c.rise !== undefined ? parent.w * row.c.rise / 1440 : 0
                                width: row.c.rise !== null && row.c.rise !== undefined ? parent.w * (row.c.set - row.c.rise) / 1440 : parent.w }
                    Rectangle { x: parent.w * card.mins(row.c) / 1440 - width / 2; anchors.verticalCenter: parent.verticalCenter
                                width: 7; height: 7; radius: card.xia ? 3.5 : 0; rotation: card.xia ? 0 : 45
                                color: card.base; border.width: 1.2; border.color: card.text }
                }
                Text { visible: hov.containsMouse && !row.c.here; anchors.right: parent.right; y: 54; text: "LET GO"
                       color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 2 }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true
                            onClicked: m => { if (!row.c.here && m.x > width - 70 && m.y > 46 && m.y < 70) card.removeAsked(row.c.zone)
                                              else { card.sel = row.index; card.forceActiveFocus() } } }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: card.alpha(card.text, 0.08) }
            }
        }

        // adding a place: a hairline field and the four nearest names
        Item {
            width: col.width; height: card.adding ? 44 + card.hits.length * 30 : 44
            Text { visible: !card.adding; y: 16
                   text: (card.s.cities || []).length >= (card.s.max || 6) ? "SIX PLACES KEPT  \u00b7  DELETE LETS ONE GO" : "A  ADD A PLACE      \u2191\u2193  CHOOSE      DELETE  LET GO"
                   color: card.alpha(card.text, 0.42); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 2
                   MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: card.beginAdd() } }
            TextInput {
                id: query
                visible: card.adding; y: 14; width: parent.width
                color: card.text; font.family: card.face; font.pixelSize: 16; selectionColor: card.alpha(card.gold, 0.4)
                Keys.onReturnPressed: { if (card.hits.length) { card.addAsked(card.hits[0].zone); card.endAdd() } }
                Keys.onEscapePressed: card.endAdd()
                Text { visible: !query.text; text: "A city, or a region: Paris, Lagos, Kyoto\u2026"; color: card.alpha(card.text, 0.35)
                       font.family: card.face; font.pixelSize: 16 }
                Rectangle { y: parent.height + 5; width: parent.width; height: 1; color: card.alpha(card.gold, 0.6) }
            }
            Column {
                visible: card.adding; y: 50; width: parent.width
                Repeater {
                    model: card.hits
                    Item {
                        required property var modelData
                        required property int index
                        width: parent.width; height: 30
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                               color: card.alpha(card.text, index === 0 ? 0.95 : 0.6); font.family: card.face; font.pixelSize: 15 }
                        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                               text: modelData.zone.split("/")[0].replace("_", " ").toUpperCase()
                               color: card.alpha(card.text, 0.38); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 2 }
                        MouseArea { anchors.fill: parent; onClicked: { card.addAsked(modelData.zone); card.endAdd() } }
                    }
                }
            }
        }
    }
}
