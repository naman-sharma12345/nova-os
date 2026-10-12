// Moon Viewing (Tianxia: The Moon Palace): tonight's moon, the same card in both sessions, the flagship shell
// (Moon.qml) and Tenka Lite (/usr/share/tenka/moon/LiteMoon.qml). The moon is drawn at its real phase, the lit side
// turned for your hemisphere, a few faint seas on its face; under it the night of the old lunar month, the month's
// nights as a row of points (this night ringed, the fifteenth in gold), moonrise, moonset and the next full moon.
// tenka-moon works everything out on this machine; the card only draws. Esc closes. Flat, no glow.
import QtQuick

Item {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#d8412f"
    property real radius: 6
    property string face: "Marcellus"
    readonly property url maria: Qt.resolvedUrl("../assets/maria.png")
    property bool xia: false
    property var s: ({ title: "Moon Viewing", phase: "", illumination: 0, age_days: 0, fraction: 0, waxing: true, south: false,
                       day: 1, month_name: "", night: "", rise: null, set: null, place: "", full: { date: "", name: "", in_days: 0 } })
    signal dismissed()
    width: 520; height: card.s.also ? 690 : 628

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    onSChanged: moon.requestPaint()
    onTextChanged: moon.requestPaint()
    onBaseChanged: moon.requestPaint()

    focus: true
    Keys.onEscapePressed: card.dismissed()

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.base; border.width: 1; border.color: card.alpha(card.text, 0.12) }
    MouseArea { anchors.fill: parent; onClicked: card.forceActiveFocus() }

    Text { x: 34; y: 30; text: card.s.title || (card.xia ? "The Moon Palace" : "Moon Viewing"); color: card.text; font.family: card.face; font.pixelSize: 26 }
    Text { x: 34; y: 68; text: (card.s.month_name || "").toUpperCase(); color: card.gold; font.family: card.face; font.pixelSize: 11; font.letterSpacing: 3 }

    Canvas {
        id: moon
        anchors.horizontalCenter: parent.horizontalCenter; y: 104
        width: 236; height: 236
        renderTarget: Canvas.Image
        Component.onCompleted: loadImage(card.maria)
        onImageLoaded: requestPaint()
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            const cx = width / 2, cy = height / 2, R = width / 2 - 4
            const f = card.s.fraction || 0, c = Math.cos(2 * Math.PI * f)
            // which side is lit: the right while waxing in the north; the left while waning; turned over in the south
            const side = ((card.s.waxing !== false) !== (card.s.south === true)) ? 1 : -1
            const T = card.text, B = card.base
            // the dark of the moon, a breath of earthshine
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI)
            ctx.fillStyle = Qt.rgba(T.r, T.g, T.b, 0.06); ctx.fill()
            // the lit part: the limb on one side, the terminator (a half ellipse) back on the other
            ctx.save()
            ctx.beginPath()
            const N = 64
            for (let i = 0; i <= N; i++) { const t = -Math.PI / 2 + Math.PI * i / N; const x = cx + side * R * Math.cos(t), y = cy + R * Math.sin(t)
                                           i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y) }
            for (let i = 0; i <= N; i++) { const t = Math.PI / 2 - Math.PI * i / N; ctx.lineTo(cx + side * R * c * Math.cos(t), cy + R * Math.sin(t)) }
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(T.r, T.g, T.b, 0.92); ctx.fill()
            ctx.clip()
            // the seas, where they really lie (assets/maria.png: the near side's maria, a flat mask made from NASA's
            // public-domain LRO map), over the lit part only; the south sees the face turned over
            if (isImageLoaded(card.maria)) {
                ctx.translate(cx, cy); if (card.s.south === true) ctx.rotate(Math.PI)
                ctx.globalAlpha = 0.17; ctx.drawImage(card.maria, -R, -R, 2 * R, 2 * R); ctx.globalAlpha = 1
            }
            ctx.restore()
            // the rim, a hairline
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI)
            ctx.lineWidth = 1; ctx.strokeStyle = Qt.rgba(T.r, T.g, T.b, 0.22); ctx.stroke()
        }
    }

    Column {
        x: 34; y: 364; width: card.width - 68; spacing: 0
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.s.night || ""; color: card.text; font.family: card.face; font.pixelSize: 21 }
        Item { width: 1; height: 8 }
        Text { anchors.horizontalCenter: parent.horizontalCenter
               text: ((card.s.phase || "") + "  \u00b7  " + Math.round((card.s.illumination || 0) * 100) + "% lit  \u00b7  "
                      + (card.s.age_days || 0).toFixed(1) + " days old").toUpperCase()
               color: card.alpha(card.text, 0.55); font.family: card.face; font.pixelSize: 11; font.letterSpacing: 1.6 }
        Item { width: 1; height: 22 }
        // the month's nights: this one ringed, the fifteenth gold
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
            Repeater {
                model: 30
                Item {
                    required property int index
                    width: 8; height: 12
                    readonly property int n: index + 1
                    Rectangle { anchors.centerIn: parent; width: n === card.s.day ? 8 : 4; height: width; radius: card.xia || n === card.s.day ? width / 2 : 0
                                rotation: card.xia || n === card.s.day ? 0 : 45
                                color: n === card.s.day ? "transparent" : n === 15 ? card.gold : card.alpha(card.text, n < card.s.day ? 0.5 : 0.2)
                                border.width: n === card.s.day ? 1.2 : 0; border.color: card.text }
                }
            }
        }
        Item { width: 1; height: 26 }
        Rectangle { width: parent.width; height: 1; color: card.alpha(card.text, 0.12) }
        Item { width: 1; height: 18 }
        Row {
            width: parent.width
            Repeater {
                model: [{ k: "MOONRISE", v: card.s.rise || "\u2014" }, { k: "MOONSET", v: card.s.set || "\u2014" }, { k: "FULL MOON", v: (card.s.full || {}).date || "" }]
                Column {
                    required property var modelData
                    width: parent.width / 3; spacing: 6
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.k; color: card.gold; font.family: card.face; font.pixelSize: 10; font.letterSpacing: 2.5 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: card.text; font.family: card.face; font.pixelSize: 20 }
                }
            }
        }
        Item { width: 1; height: 18 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
               text: ((card.s.full || {}).name || "") + (card.s.place ? "   \u00b7   over " + card.s.place : "")
               color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 12; font.letterSpacing: 0.5 }
        // what else is up tonight: the bright planets (with their old names on Tianxia) and a meteor shower near its peak
        Item { width: 1; height: 22; visible: !!card.s.also }
        Text { anchors.horizontalCenter: parent.horizontalCenter; visible: !!card.s.also
               text: card.xia ? "ALSO IN THE HEAVENS" : "ALSO TONIGHT"; color: card.gold; font.family: card.face; font.pixelSize: 10; font.letterSpacing: 2.5 }
        Item { width: 1; height: 8; visible: !!card.s.also }
        Text { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; visible: !!card.s.also
               horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
               // each sight keeps its words together: the line breaks only between them
               text: (card.s.also || "").split("  \u00b7  ").map(w => w.replace(/ /g, "\u00a0")).join("  \u00b7  "); color: card.alpha(card.text, 0.78); font.family: card.face; font.pixelSize: 14; lineHeight: 1.15 }
    }
}
