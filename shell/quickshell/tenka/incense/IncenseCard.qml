// The Incense's card (Tianxia: The Joss Stick), the same in both sessions: the flagship shell (Incense.qml) and
// Tenka Lite (/usr/share/tenka/incense/LiteIncense.qml). Our own timer, drawn as what it is named after: a stick
// standing in a shallow censer burns down with the time, one small ember at its tip and a thread of smoke above
// it. The time left in Marcellus beside it. tenka-incense keeps the state (set `s`); this card only asks
// (signals lightAsked / outAsked). 1-6 or the arrows choose, Enter lights, X puts it out, ESC closes (it burns on).
// Pure QtQuick + QtQuick.Shapes. Flat: the ember is a dot, the smoke a 1px line, no glow.
import QtQuick
import QtQuick.Shapes

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
    property var s: ({ burning: false, until: 0, total: 0, minutes: 15, burned: 0 })
    readonly property var lengths: [5, 10, 15, 25, 45, 60]
    property int choice: 15
    property double now: Date.now()
    width: 600; height: 380
    signal dismissed()
    signal lightAsked(int minutes)
    signal outAsked()
    signal gardenAsked(string name)
    readonly property var gardens: ["", "rain", "stream", "pines", "embers"]
    readonly property string garden: s && s.garden ? s.garden : ""
    function nextGarden() { return gardens[(gardens.indexOf(garden) + 1) % gardens.length] }

    onSChanged: if (s && s.minutes) choice = s.minutes
    readonly property bool burning: !!s.burning && s.until > now
    readonly property double remain: burning ? Math.max(0, s.until - now) : 0
    readonly property real burnt: burning && s.total > 0 ? Math.min(1, 1 - remain / (s.total * 1000)) : (justBurned ? 1 : 0)
    readonly property bool justBurned: !burning && s.burned > 0 && now - s.burned < 15 * 60000
    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function two(n) { return (n < 10 ? "0" : "") + n }
    function clock(ms) { const t = Math.ceil(ms / 1000); return Math.floor(t / 60) + ":" + two(t % 60) }
    function hm(ms) { const d = new Date(ms); return two(d.getHours()) + ":" + two(d.getMinutes()) }

    Timer { interval: 250; repeat: true; running: card.visible; triggeredOnStart: true; onTriggered: card.now = Date.now() }

    Keys.onPressed: e => {
        const i = lengths.indexOf(choice)
        if (e.key === Qt.Key_Escape) card.dismissed()
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_6) choice = lengths[e.key - Qt.Key_1]
        else if (e.key === Qt.Key_Left) choice = lengths[Math.max(0, i - 1)]
        else if (e.key === Qt.Key_Right) choice = lengths[Math.min(lengths.length - 1, i + 1)]
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) card.lightAsked(choice)
        else if (e.key === Qt.Key_X) { if (card.burning) card.outAsked() }
        else if (e.key === Qt.Key_G) card.gardenAsked(card.nextGarden())
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    // ---- the stick in its censer
    Item {
        id: scene
        x: 18; y: 18; width: 170; height: parent.height - 36
        readonly property real foot: height - 44            // where the stick stands in the ash
        readonly property real full: foot - 26               // an unburnt stick's length
        readonly property real h: full * (1 - card.burnt)
        readonly property real tipY: foot - h
        property real t: 0
        NumberAnimation on t { running: card.burning && card.visible; from: 0; to: Math.PI * 2; duration: 7000; loops: Animation.Infinite }
        // smoke: two threads that sway, the second fainter
        Shape {
            anchors.fill: parent; visible: card.burning; preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: card.alpha(card.text, 0.26); strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                startX: 85; startY: scene.tipY - 5
                PathCubic { x: 85 + 10 * Math.sin(scene.t * 0.7 + 2); y: Math.max(4, scene.tipY - 130)
                            control1X: 85 + 16 * Math.sin(scene.t); control1Y: scene.tipY - 45
                            control2X: 85 - 20 * Math.sin(scene.t * 1.3 + 1); control2Y: scene.tipY - 90 }
            }
            ShapePath {
                strokeColor: card.alpha(card.text, 0.12); strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                startX: 86; startY: scene.tipY - 8
                PathCubic { x: 92 - 14 * Math.sin(scene.t * 0.9); y: Math.max(4, scene.tipY - 110)
                            control1X: 86 - 12 * Math.sin(scene.t * 1.1 + 0.5); control1Y: scene.tipY - 40
                            control2X: 90 + 18 * Math.sin(scene.t * 0.8 + 2.4); control2Y: scene.tipY - 80 }
            }
        }
        // the stick: what is left of it, and a short grey ash end where it is burning
        Rectangle { x: 84; y: scene.tipY; width: 2; height: scene.h; radius: 1
                    color: card.alpha(card.gold, card.burning ? 0.9 : 0.6) }
        Rectangle { visible: card.burning && scene.h > 6; x: 84; y: scene.tipY - 4; width: 2; height: 4; color: card.alpha(card.text, 0.35) }
        Rectangle {   // the ember
            visible: card.burning; x: 82.5; y: scene.tipY - 6.5; width: 5; height: 5; radius: 2.5; color: card.accent
            SequentialAnimation on opacity { running: card.burning && card.visible; loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.7; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.7; to: 1; duration: 1600; easing.type: Easing.InOutSine } }
        }
        // the censer: a shallow bowl, its rim a hairline, the ash a flat band
        Shape {
            anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: card.alpha(card.gold, 0.75); strokeWidth: 1.2; fillColor: card.alpha(card.text, 0.04)
                startX: 22; startY: scene.foot + 2
                PathLine { x: 148; y: scene.foot + 2 }
                PathQuad { x: 22; y: scene.foot + 2; controlX: 85; controlY: scene.foot + 42 }
            }
            ShapePath {
                strokeColor: "transparent"; fillColor: card.alpha(card.text, 0.10)
                startX: 34; startY: scene.foot + 2
                PathLine { x: 136; y: scene.foot + 2 }
                PathQuad { x: 34; y: scene.foot + 2; controlX: 85; controlY: scene.foot + 12 }
            }
        }
        Rectangle { x: 70; y: scene.foot + 26; width: 30; height: 1; color: card.alpha(card.gold, 0.5) }   // the foot of the bowl
    }
    Rectangle { x: 206; y: 30; width: 1; height: parent.height - 60; color: card.alpha(card.gold, 0.28) }

    // ---- the time
    Item {
        id: right
        x: 236; y: 0; width: parent.width - 236 - 32; height: parent.height
        Row {
            y: 30; spacing: 14
            Text { text: card.xia ? "THE JOSS STICK" : "THE INCENSE"; color: card.gold; font.family: card.face
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 40; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            id: big; y: 64
            text: card.burning ? card.clock(card.remain) : card.choice + ":00"
            color: card.burning ? card.text : card.alpha(card.text, 0.55); font.family: card.face; font.pixelSize: 76
        }
        Text {
            anchors.top: big.bottom; anchors.topMargin: 2
            text: card.burning ? "of " + card.s.minutes + " minutes  ·  burns down at " + card.hm(card.s.until)
                 : card.justBurned ? "burned down at " + card.hm(card.s.burned) : "unlit"
            color: card.alpha(card.text, 0.55); font.family: card.uiFace; font.pixelSize: 14
        }
        // the lengths of stick: 1-6, the chosen one underlined in the accent
        Row {
            y: 212; spacing: 22
            Repeater {
                model: card.lengths
                delegate: Item {
                    required property int modelData
                    width: n.implicitWidth; height: 30
                    Text { id: n; text: modelData; anchors.horizontalCenter: parent.horizontalCenter
                           color: modelData === card.choice ? card.text : card.alpha(card.text, 0.45); font.family: card.uiFace; font.pixelSize: 18 }
                    Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width + 8; height: 1
                                color: card.accent; visible: modelData === card.choice }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: card.choice = modelData; onDoubleClicked: card.lightAsked(modelData) }
                }
            }
            Text { text: "min"; color: card.alpha(card.text, 0.35); font.family: card.uiFace; font.pixelSize: 12; y: 6 }
        }
        Text {
            y: 262
            text: card.burning ? (card.choice === card.s.minutes ? "Enter lights a fresh stick  ·  X puts it out" : "Enter lights " + card.choice + " minutes instead  ·  X puts it out")
                               : "Enter lights it"
            color: card.alpha(card.text, 0.7); font.family: card.uiFace; font.pixelSize: 13
        }
        // The Garden (Super+G's sounds) can play while the stick burns; G chooses which, or none
        Row {
            y: 292; spacing: 10
            Text { text: card.xia ? "THE MOUNTAIN HALL" : "THE GARDEN"; color: card.alpha(card.gold, 0.85); font.family: card.face
                   font.pixelSize: 10; font.letterSpacing: 4; anchors.verticalCenter: parent.verticalCenter }
            Text { text: card.garden ? card.garden.charAt(0).toUpperCase() + card.garden.slice(1) + (card.burning ? " plays while it burns" : " plays with the stick") : "silence"
                   color: card.garden ? card.text : card.alpha(card.text, 0.45); font.family: card.uiFace; font.pixelSize: 13
                   anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { y: 284; width: parent.width; height: 26; onClicked: card.gardenAsked(card.nextGarden()) }
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            text: "1 – 6 choose  ·  G the garden  ·  ESC closes, the stick burns on"
            color: card.alpha(card.text, 0.32); font.family: card.uiFace; font.pixelSize: 11
        }
    }
}
