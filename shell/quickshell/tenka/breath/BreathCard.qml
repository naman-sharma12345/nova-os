// The Breath's card (Tianxia: Gathering Qi), the same in both sessions: the flagship shell (Breath.qml) and Tenka
// Lite (/usr/share/tenka/breath/LiteBreath.qml). A breathing guide drawn as an enso: the brush draws the circle as
// you breathe in, the circle rests while you hold, and the ink dries back to a trace as you breathe out; the
// circle itself swells and settles with the breath. Three paces (EVEN 5-5, BOX 4-4-4-4, CALM 4-7-8) and a length.
// tenka-breath keeps the choice and counts the sittings; this card only asks (signals setAsked / doneAsked).
// Space begins or stops, P changes the pace, 1-4 the minutes, ESC closes. Pure QtQuick (Canvas). Flat, no glow:
// the ink is the theme's text colour, the only colour a small seal pressed when a sitting is kept.
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
    property var s: ({ pace: "even", minutes: 3, sittings: 0, paces: { even: [5, 0, 5, 0], box: [4, 4, 4, 4], calm: [4, 7, 8, 0] }, lengths: [1, 3, 5, 10] })
    readonly property var paceNames: ["even", "box", "calm"]
    property string pace: "even"
    property int minutes: 3
    property bool running: false
    property bool kept: false                 // a sitting just finished (the seal shows)
    property double t0: 0
    property double now: Date.now()
    width: 480; height: 610
    signal dismissed()
    signal setAsked(string pace, int minutes)
    signal doneAsked(int minutes)

    onSChanged: { if (s && s.pace) pace = s.pace; if (s && s.minutes) minutes = s.minutes }
    readonly property var ph: (s && s.paces && s.paces[pace]) ? s.paces[pace] : [5, 0, 5, 0]
    readonly property real cycle: ph[0] + ph[1] + ph[2] + ph[3]
    readonly property int rounds: Math.max(1, Math.ceil(minutes * 60 / cycle))
    readonly property real el: running ? Math.max(0, (now - t0) / 1000) : 0
    readonly property int round: Math.min(rounds, Math.floor(el / cycle) + 1)
    // which phase of the breath, and how far into it: 0 in, 1 hold, 2 out, 3 rest
    readonly property var at: {
        let r = el % cycle
        for (let i = 0; i < 4; i++) { if (ph[i] > 0 && r < ph[i]) return { i: i, f: r / ph[i], left: Math.ceil(ph[i] - r) }; r -= ph[i] }
        return { i: 3, f: 1, left: 0 }
    }
    function ease(f) { return 0.5 - 0.5 * Math.cos(Math.PI * Math.min(1, Math.max(0, f))) }
    readonly property real draw: !running ? 1 : at.i === 0 ? ease(at.f) : 1
    readonly property real ink: !running ? (kept ? 0.94 : 0.86) : at.i === 0 || at.i === 1 ? 0.94 : at.i === 2 ? 0.94 - 0.64 * ease(at.f) : 0.30
    readonly property real swell: !running ? 1 : at.i === 0 ? 0.86 + 0.14 * ease(at.f) : at.i === 1 ? 1 : at.i === 2 ? 1 - 0.14 * ease(at.f) : 0.86
    readonly property var words: xia ? ["Gather the qi", "Hold", "Let it flow out", "Be still"] : ["Breathe in", "Hold", "Breathe out", "Rest"]
    function label(p) { const a = (s && s.paces && s.paces[p]) || []; return p.toUpperCase() + "  " + a.filter(x => x > 0).join(" \u00b7 ") }
    function nth(n) { return ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth"][n] || (n + "th") }

    function begin() { kept = false; t0 = Date.now(); now = t0; running = true }
    function stop() { running = false }
    function seek(sec) { kept = false; now = Date.now(); t0 = now - sec * 1000; running = true }   // renders and tests
    function choose(p, m) { pace = p; minutes = m; if (running) stop(); kept = false; card.setAsked(p, m) }

    Timer { interval: 33; repeat: true; running: card.running && card.visible; triggeredOnStart: true
            onTriggered: { card.now = Date.now(); if (card.el >= card.rounds * card.cycle) {
                card.running = false; card.kept = true; card.s = Object.assign({}, card.s, { sittings: (card.s.sittings || 0) + 1 })
                card.doneAsked(card.minutes) } } }

    Keys.onPressed: e => {
        const m = s.lengths || [1, 3, 5, 10]
        if (e.key === Qt.Key_Escape) card.dismissed()
        else if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { running ? stop() : begin() }
        else if (e.key === Qt.Key_P) choose(paceNames[(paceNames.indexOf(pace) + 1) % 3], minutes)
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4) choose(pace, m[e.key - Qt.Key_1])
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    MouseArea { anchors.fill: parent; onClicked: card.forceActiveFocus() }

    Row {
        x: 32; y: 30; spacing: 14
        Text { text: card.xia ? "GATHERING QI" : "THE BREATH"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 40; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
    }
    Text { anchors.right: parent.right; anchors.rightMargin: 32; y: 30
           text: (card.s.sittings || 0) > 0 ? "TODAY  " + card.s.sittings : ""
           color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 11; font.letterSpacing: 3 }

    // ---- the enso: a faint trace of where the brush goes, and the stroke itself
    Item {
        id: ring
        width: 300; height: 300; x: (card.width - width) / 2; y: 62
        scale: card.swell
        Canvas {
            id: ghost; anchors.fill: parent; opacity: card.running ? 0.15 : 0
            onPaint: ring.paintStroke(getContext("2d"), 1, width, height)
            Component.onCompleted: requestPaint()
        }
        Canvas {
            id: stroke; anchors.fill: parent; opacity: card.ink
            property real p: card.draw
            onPChanged: requestPaint()
            onPaint: ring.paintStroke(getContext("2d"), p, width, height)
            Component.onCompleted: requestPaint()
        }
        Connections { target: card; function onTextChanged() { ghost.requestPaint(); stroke.requestPaint() } }
        // one brush stroke, from a pressed start to a dry, split tail; the same stroke every time (no randomness)
        function paintStroke(c, prog, w, h) {
            c.reset()
            c.fillStyle = card.text
            const N = 620, R = 116, W = 24, a0 = 2.2, sweep = 5.86, k = 9
            const n = Math.floor(N * Math.max(0, Math.min(1, prog)))
            for (let i = 0; i <= n; i++) {
                const t = i / N
                const ang = a0 + sweep * t
                const r = R * (1 + 0.016 * Math.sin(9.7 * t + 0.7) + 0.008 * Math.sin(23 * t + 2)) * (1 - 0.045 * t * t)
                const cx = w / 2 + r * Math.cos(ang), cy = h / 2 + r * Math.sin(ang)
                // pressed at the start, a swell through the first third, then lifting off
                const press = 0.66 + 0.34 * Math.min(1, t / 0.06) + 0.36 * Math.exp(-Math.pow(t / 0.022, 2)) + 0.16 * Math.exp(-Math.pow((t - 0.3) / 0.16, 2))
                const bw = W * press * (1 - 0.66 * Math.pow(t, 1.4)) * (1 + 0.05 * Math.sin(31 * t) + 0.035 * Math.sin(57 * t + 1))
                const dry = t < 0.42 ? 0 : (t - 0.42) / 0.58
                if (dry === 0) { c.beginPath(); c.arc(cx, cy, bw / 2, 0, Math.PI * 2); c.fill(); continue }
                // the dry tail: each hair runs out of ink on its own, so the stroke splits into long streaks
                const nx = Math.cos(ang), ny = Math.sin(ang)
                for (let j = 0; j < k; j++) {
                    const hj = (Math.sin(j * 12.9898 + 4.1) * 43758.5453) % 1
                    const inkj = 1.05 - dry * (0.9 + 1.1 * Math.abs(hj)) + 0.22 * Math.sin((2.5 + 1.9 * j) * t * 6.283 + j * 1.7)
                    if (inkj <= 0) continue
                    const o = (j / (k - 1) - 0.5) * bw * 0.9
                    c.beginPath(); c.arc(cx + nx * o, cy + ny * o, Math.max(0.55, bw / k * 0.8 * Math.min(1, 0.4 + inkj)), 0, Math.PI * 2); c.fill()
                }
            }
        }
        // the seconds left in this part of the breath, quiet in the middle of the circle
        Text { anchors.centerIn: parent; visible: card.running; text: card.at.left; color: card.alpha(card.text, 0.42)
               font.family: card.face; font.pixelSize: 40 }
        // the seal: pressed once a sitting is kept
        Rectangle {
            visible: card.kept; x: parent.width - 62; y: parent.height - 50; width: 16; height: 16; radius: card.xia ? 8 : 2
            color: card.accent
            Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: card.xia ? 3 : 1; color: card.alpha(card.base, 0.85) }
        }
    }

    // ---- the words
    Text {
        id: word; y: 382; anchors.horizontalCenter: parent.horizontalCenter
        text: card.running ? card.words[card.at.i] : card.kept ? (card.xia ? "The qi is gathered" : "Well breathed") : (card.xia ? "Sit, and gather" : "Sit, and breathe")
        color: card.running ? card.text : card.alpha(card.text, 0.8); font.family: card.face; font.pixelSize: 28
    }
    Text {
        id: sub; anchors.top: word.bottom; anchors.topMargin: 6; anchors.horizontalCenter: parent.horizontalCenter
        text: card.running ? "breath " + card.round + " of " + card.rounds
            : card.kept ? card.minutes + (card.minutes === 1 ? " minute" : " minutes") + "  \u00b7  " + card.rounds + " breaths  \u00b7  the " + card.nth(card.s.sittings || 1) + " sitting today"
            : card.minutes + (card.minutes === 1 ? " minute" : " minutes") + "  \u00b7  " + card.rounds + " breaths"
        color: card.alpha(card.text, 0.55); font.family: card.uiFace; font.pixelSize: 14
    }
    Rectangle { x: 32; y: 470; width: parent.width - 64; height: 1; color: card.alpha(card.gold, 0.25) }
    // the paces and the lengths, the chosen one underlined in the accent
    Row {
        y: 488; anchors.horizontalCenter: parent.horizontalCenter; spacing: 26
        Repeater {
            model: card.paceNames
            delegate: Item {
                required property string modelData
                width: pn.implicitWidth; height: 26
                Text { id: pn; text: card.label(modelData); color: modelData === card.pace ? card.text : card.alpha(card.text, 0.45)
                       font.family: card.face; font.pixelSize: 12; font.letterSpacing: 2 }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: card.accent; visible: modelData === card.pace }
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: card.choose(modelData, card.minutes) }
            }
        }
    }
    Row {
        y: 526; anchors.horizontalCenter: parent.horizontalCenter; spacing: 22
        Repeater {
            model: card.s.lengths || [1, 3, 5, 10]
            delegate: Item {
                required property int modelData
                width: ln.implicitWidth; height: 28
                Text { id: ln; text: modelData; anchors.horizontalCenter: parent.horizontalCenter
                       color: modelData === card.minutes ? card.text : card.alpha(card.text, 0.45); font.family: card.uiFace; font.pixelSize: 17 }
                Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width + 8; height: 1
                            color: card.accent; visible: modelData === card.minutes }
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: card.choose(card.pace, modelData) }
            }
        }
        Text { text: "min"; color: card.alpha(card.text, 0.35); font.family: card.uiFace; font.pixelSize: 12; y: 5 }
    }
    Text {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 20; anchors.horizontalCenter: parent.horizontalCenter
        text: (card.running ? "Space stops" : "Space begins") + "  \u00b7  P the pace  \u00b7  1 \u2013 4 minutes  \u00b7  ESC closes"
        color: card.alpha(card.text, 0.32); font.family: card.uiFace; font.pixelSize: 11
    }
}
