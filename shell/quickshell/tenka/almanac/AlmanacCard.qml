// The Almanac's card (Tianxia: The Heavenly Calendar), the same in both sessions: the flagship shell
// (Almanac.qml) and Tenka Lite (/usr/share/tenka/almanac/LiteAlmanac.qml). Left, the wheel of the year: the
// sun's path as one hairline ring with the 24 solar terms ticked on it (summer at the top, winter at the foot,
// spring on the left, autumn on the right), the sun as a gold dot, and the stretch of the term walked so far
// as a short arc; tonight's moon in the middle. Right, the words: the term, its micro-season (Tenka) or old
// saying (Tianxia), when the next term begins, and this month's four moons. `d` is `tenka-almanac wheel`.
// Pure QtQuick + Canvas. Flat: hairlines and dots, no glow. ESC closes.
import QtQuick

Item {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#d8412f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property bool xia: false
    property var d: null
    width: 860; height: 440
    signal dismissed()

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August",
                                   "September", "October", "November", "December"]
    function dayMonth(sec) { const x = new Date(sec * 1000); return x.getDate() + " " + months[x.getMonth()] }
    function shortDay(sec) { const x = new Date(sec * 1000); return x.getDate() + " " + months[x.getMonth()].slice(0, 3) }
    readonly property int ti: d ? d.term_index : 0
    readonly property var tStart: d && d.terms ? d.terms[ti].start : 0
    readonly property var tNext: d && d.terms ? (ti < 23 ? d.terms[ti + 1].start : tStart + 15.2 * 86400) : 0
    readonly property int dayOf: d ? Math.max(1, Math.floor((d.now - tStart) / 86400) + 1) : 0
    readonly property int termDays: d ? Math.round((tNext - tStart) / 86400) : 15

    Keys.onPressed: e => { if (e.key === Qt.Key_Escape) { card.dismissed(); e.accepted = true } }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    // ---- the wheel
    Canvas {
        id: wheel
        x: 24; y: 24; width: 392; height: 392
        antialiasing: true
        readonly property real lam: card.d ? card.d.sun_longitude : 0
        onLamChanged: requestPaint()
        Connections { target: card; function onDChanged() { wheel.requestPaint() } function onGoldChanged() { wheel.requestPaint() } }
        onPaint: {
            const ctx = getContext("2d"); ctx.reset();
            const cx = width / 2, cy = height / 2, R = 150;
            // screen angle: summer solstice (90 deg) at the top, the sun going clockwise
            const ang = l => (l - 180) * Math.PI / 180;
            const pt = (l, r) => [cx + r * Math.cos(ang(l)), cy + r * Math.sin(ang(l))];
            ctx.lineWidth = 1;
            ctx.strokeStyle = card.alpha(card.gold, 0.42);
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI); ctx.stroke();
            ctx.strokeStyle = card.alpha(card.text, 0.08);
            ctx.beginPath(); ctx.arc(cx, cy, R - 30, 0, 2 * Math.PI); ctx.stroke();
            // 72 micro-seasons (Tenka) as dots inside the ring; the terms as ticks across it
            if (!card.xia) {
                ctx.fillStyle = card.alpha(card.text, 0.22);
                for (let k = 0; k < 72; k++) { if (k % 3 === 0) continue; const p = pt(k * 5, R - 9); ctx.beginPath(); ctx.arc(p[0], p[1], 1, 0, 2 * Math.PI); ctx.fill() }
            }
            for (let i = 0; i < 24; i++) {
                const major = i % 6 === 0, start = i % 6 === 3;            // equinoxes/solstices; the four "Start of"s
                const a = pt(i * 15, R - (major ? 14 : start ? 10 : 6)), b = pt(i * 15, R + (major ? 14 : start ? 10 : 6));
                ctx.strokeStyle = card.alpha(i === card.ti ? card.text : card.gold, major ? 0.75 : start ? 0.6 : 0.4);
                ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(b[0], b[1]); ctx.stroke();
            }
            // the term walked so far: a short arc on the ring in the accent
            const t0 = card.ti * 15;
            ctx.strokeStyle = card.accent; ctx.lineWidth = 2;
            ctx.beginPath(); ctx.arc(cx, cy, R, ang(t0), ang(lam)); ctx.stroke();
            // the sun
            const s = pt(lam, R);
            ctx.fillStyle = card.base; ctx.beginPath(); ctx.arc(s[0], s[1], 7, 0, 2 * Math.PI); ctx.fill();
            ctx.fillStyle = card.gold; ctx.beginPath(); ctx.arc(s[0], s[1], 5, 0, 2 * Math.PI); ctx.fill();
        }
        // the four quarters of the year, set just outside the ring
        Repeater {
            model: [{ l: 90, w: "SUMMER" }, { l: 180, w: "AUTUMN" }, { l: 270, w: "WINTER" }, { l: 0, w: "SPRING" }]
            Text {
                required property var modelData
                readonly property real a: (modelData.l - 180) * Math.PI / 180
                x: wheel.width / 2 + 178 * Math.cos(a) - width / 2; y: wheel.height / 2 + 178 * Math.sin(a) - height / 2
                rotation: modelData.l === 0 ? -90 : modelData.l === 180 ? 90 : 0
                text: modelData.w; color: card.alpha(card.text, 0.42); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 4
            }
        }
        Column {
            anchors.centerIn: parent; spacing: 10
            MoonGlyph { anchors.horizontalCenter: parent.horizontalCenter; width: 74; height: 74
                        e: card.d ? card.d.moon.elongation : 0; lit: card.alpha(card.text, 0.88)
                        dark: card.alpha(card.text, 0.10); rim: card.alpha(card.gold, 0.5) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.d ? card.d.moon.phase.toUpperCase() : ""
                   color: card.alpha(card.text, 0.7); font.family: card.face; font.pixelSize: 11; font.letterSpacing: 3 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.d ? Math.round(card.d.moon.illumination * 100) + "% lit" : ""
                   color: card.alpha(card.text, 0.42); font.family: card.uiFace; font.pixelSize: 12 }
        }
    }
    Rectangle { x: 440; y: 34; width: 1; height: parent.height - 68; color: card.alpha(card.gold, 0.28) }

    // ---- the words
    Item {
        x: 470; y: 0; width: parent.width - 470 - 36; height: parent.height
        Row {
            y: 34; spacing: 14
            Text { text: card.xia ? "THE HEAVENLY CALENDAR" : "THE ALMANAC"; color: card.gold; font.family: card.face
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 40; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        }
        Text { id: term; y: 66; width: parent.width; text: card.d ? card.d.term : ""; color: card.text
               font.family: card.face; font.pixelSize: 38; elide: Text.ElideRight }
        Text { id: det; anchors.top: term.bottom; anchors.topMargin: 8; width: parent.width; wrapMode: Text.WordWrap
               text: card.d ? card.d.detail : ""; color: card.alpha(card.gold, 0.92); font.family: card.face; font.pixelSize: 17; lineHeight: 1.15 }
        Text { id: when; anchors.top: det.bottom; anchors.topMargin: 14; width: parent.width; wrapMode: Text.WordWrap
               text: card.d ? "Day " + card.dayOf + " of " + card.termDays + "  ·  " + card.d.next_term + " on " + card.dayMonth(card.tNext) : ""
               color: card.alpha(card.text, 0.6); font.family: card.uiFace; font.pixelSize: 14 }
        Rectangle { id: rule; anchors.top: when.bottom; anchors.topMargin: 26; width: parent.width; height: 1; color: card.alpha(card.text, 0.08) }
        Text { id: ml; anchors.top: rule.bottom; anchors.topMargin: 16; text: "THIS MONTH'S MOONS"; color: card.alpha(card.gold, 0.85)
               font.family: card.face; font.pixelSize: 10; font.letterSpacing: 4 }
        Row {
            anchors.top: ml.bottom; anchors.topMargin: 14; spacing: 0
            Repeater {
                model: card.d && card.d.moons ? card.d.moons.slice(1) : []
                Column {
                    required property var modelData; required property int index
                    width: (card.width - 470 - 36) / 4; spacing: 8
                    readonly property bool past: card.d && modelData.at < card.d.now
                    MoonGlyph { width: 20; height: 20; e: [90, 180, 270, 0][parent.index]
                                lit: card.alpha(card.text, parent.past ? 0.4 : 0.86); dark: card.alpha(card.text, 0.08); rim: card.alpha(card.gold, parent.past ? 0.25 : 0.45) }
                    Text { text: card.shortDay(modelData.at); color: card.alpha(card.text, parent.past ? 0.38 : 0.85); font.family: card.uiFace; font.pixelSize: 13 }
                    Text { text: ["First quarter", "Full", "Last quarter", "New"][parent.index]; color: card.alpha(card.text, 0.4)
                           font.family: card.uiFace; font.pixelSize: 11 }
                }
            }
        }
        Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 22; text: "Worked out on this machine  ·  ESC closes"
               color: card.alpha(card.text, 0.3); font.family: card.uiFace; font.pixelSize: 11 }
    }
}
