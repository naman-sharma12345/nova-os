// Seven Skies (Tianxia: The Heavens Ahead): the coming week's weather, the same card in both sessions, the flagship
// shell (SkyWeek.qml) and Tenka Lite (/usr/share/tenka/skyweek/LiteSkyWeek.qml). Each day: its name, a small sign
// drawn with a fine brush (a sun, a cloud, slanting rain, snow, mist, a strike of thunder), the day in the desk's own
// words, its chance of rain, and its low and high as a hairline on the week's scale. tenka-sky asks Open-Meteo in the
// same request it already makes for the desk (a rounded place, nothing else) and keeps the answer; `tenka-sky off`
// stops it, and then this card says so. Esc closes. Flat, no glow: ink, with gold for the warm end of each day.
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
    property var s: ({ title: "Seven Skies", place: "", days: [] })
    signal dismissed()
    readonly property var days: (s && s.days) ? s.days : []
    readonly property real wlo: days.length ? Math.min.apply(null, days.map(d => d.lo)) : 0
    readonly property real whi: days.length ? Math.max.apply(null, days.map(d => d.hi)) : 1
    width: 560
    height: 112 + Math.max(1, days.length) * 58 + 28

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function dayName(iso, i) {
        if (i === 0) return "Today"
        if (i === 1) return "Tomorrow"
        const p = String(iso).split("-"); const d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
        return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][d.getDay()]
    }

    focus: true
    Keys.onEscapePressed: card.dismissed()

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.base; border.width: 1; border.color: card.alpha(card.text, 0.12) }
    MouseArea { anchors.fill: parent; onClicked: card.forceActiveFocus() }

    Text { x: 34; y: 30; text: card.s.title || (card.xia ? "The Heavens Ahead" : "Seven Skies"); color: card.text; font.family: card.face; font.pixelSize: 26 }
    Text { x: 34; y: 68; color: card.gold; font.family: card.face; font.pixelSize: 11; font.letterSpacing: 3
           text: (card.s.off ? "THE SKY IS RESTING" : ((card.s.place ? card.s.place + "  \u00b7  " : "") + "THE NEXT SEVEN DAYS"
                  + (card.s.stale ? "  \u00b7  KEPT FROM EARLIER" : ""))).toUpperCase() }
    Rectangle { x: 34; y: 100; width: card.width - 68; height: 1; color: card.alpha(card.text, 0.12) }

    Text { visible: card.days.length === 0; x: 34; y: 124; width: card.width - 68; wrapMode: Text.WordWrap
           color: card.alpha(card.text, 0.6); font.family: card.face; font.pixelSize: 14; lineHeight: 1.3
           text: card.s.off ? "The sky is kept off this machine. `tenka-sky on` asks Open-Meteo again; it sends only a place rounded to about 10 km."
                            : "No word from the sky yet (offline, or no place set in ~/.config/tenka/place.json)." }

    Column {
        x: 34; y: 112; width: card.width - 68
        Repeater {
            model: card.days
            Item {
                id: row
                required property var modelData
                required property int index
                width: parent.width; height: 58
                readonly property var d: modelData
                Text { anchors.verticalCenter: parent.verticalCenter; width: 104; text: card.dayName(row.d.date, row.index)
                       color: card.alpha(card.text, row.index === 0 ? 0.95 : 0.75); font.family: card.face; font.pixelSize: 16 }
                // the sign: a fine brush, the theme's ink
                Canvas {
                    id: sign
                    x: 108; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30
                    renderTarget: Canvas.Image
                    property string kind: row.d.kind || "cloud"
                    onKindChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const T = card.text, G = card.gold
                        c.lineWidth = 1.3; c.lineCap = "round"; c.strokeStyle = Qt.rgba(T.r, T.g, T.b, 0.85)
                        function cloud(y) {      // three puffs on a flat foot: each circle inked, then the inside papered over
                            const P = [[10, y - 3.6, 3.6], [16, y - 6, 5.6], [21.4, y - 3.4, 3.4]], B = card.base
                            for (const p of P) { c.beginPath(); c.arc(p[0], p[1], p[2], 0, 2 * Math.PI); c.stroke() }
                            c.fillStyle = Qt.rgba(B.r, B.g, B.b, 1)
                            for (const p of P) { c.beginPath(); c.arc(p[0], p[1], p[2] - 0.7, 0, 2 * Math.PI); c.fill() }
                            c.fillRect(10, y - 4, 11.4, 3.3)
                            c.beginPath(); c.moveTo(10, y); c.lineTo(21.4, y); c.stroke()
                        }
                        if (kind === "clear") {
                            c.strokeStyle = Qt.rgba(G.r, G.g, G.b, 0.95); c.beginPath(); c.arc(15, 15, 6.5, 0, 2 * Math.PI); c.stroke()
                            for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4; c.beginPath()
                                c.moveTo(15 + 9.5 * Math.cos(a), 15 + 9.5 * Math.sin(a)); c.lineTo(15 + 12 * Math.cos(a), 15 + 12 * Math.sin(a)); c.stroke() }
                        } else if (kind === "cloud") { cloud(19)
                        } else if (kind === "mist") {
                            for (let i = 0; i < 3; i++) { c.beginPath(); c.moveTo(5 + (i % 2) * 3, 10 + i * 6); c.lineTo(25 - ((i + 1) % 2) * 3, 10 + i * 6); c.stroke() }
                        } else if (kind === "rain" || kind === "storm") { cloud(14)
                            if (kind === "rain") for (let i = 0; i < 3; i++) { c.beginPath(); c.moveTo(10 + i * 5, 18); c.lineTo(8 + i * 5, 25); c.stroke() }
                            else { c.strokeStyle = Qt.rgba(G.r, G.g, G.b, 0.95); c.beginPath(); c.moveTo(16, 17); c.lineTo(12, 22); c.lineTo(17, 22); c.lineTo(13, 28); c.stroke() }
                        } else if (kind === "snow") { cloud(14)
                            c.fillStyle = Qt.rgba(T.r, T.g, T.b, 0.85)
                            for (const p of [[10, 20], [15, 23], [20, 20], [12.5, 26.5], [17.5, 26.5]]) { c.beginPath(); c.arc(p[0], p[1], 1.2, 0, 2 * Math.PI); c.fill() }
                        }
                    }
                }
                Text { x: 152; anchors.verticalCenter: parent.verticalCenter; width: 170; elide: Text.ElideRight; text: row.d.word || ""
                       color: card.alpha(card.text, 0.88); font.family: card.face; font.pixelSize: 15 }
                Text { x: 322; anchors.verticalCenter: parent.verticalCenter; visible: (row.d.rain || 0) >= 20; text: row.d.rain + "%"
                       color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 11; font.letterSpacing: 1 }
                // low and high on the week's scale: a hairline track, the day's span inked, its warm end gold
                Item {
                    x: 366; width: parent.width - 366; height: parent.height
                    readonly property real span: Math.max(1, card.whi - card.wlo)
                    readonly property real tw: width - 64
                    Text { anchors.verticalCenter: parent.verticalCenter; width: 28; horizontalAlignment: Text.AlignRight; text: row.d.lo + "\u00b0"
                           color: card.alpha(card.text, 0.55); font.family: card.face; font.pixelSize: 13 }
                    Rectangle { x: 34; anchors.verticalCenter: parent.verticalCenter; width: parent.tw; height: 1; color: card.alpha(card.text, 0.14) }
                    Rectangle { x: 34 + parent.tw * (row.d.lo - card.wlo) / parent.span; anchors.verticalCenter: parent.verticalCenter; height: 2
                                width: Math.max(4, parent.tw * (row.d.hi - row.d.lo) / parent.span)
                                gradient: Gradient { orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: card.alpha(card.text, 0.6) }
                                    GradientStop { position: 1; color: card.gold } } }
                    Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: row.d.hi + "\u00b0"
                           color: card.text; font.family: card.face; font.pixelSize: 13 }
                }
                Rectangle { visible: row.index < card.days.length - 1; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: card.alpha(card.text, 0.07) }
            }
        }
    }
}
