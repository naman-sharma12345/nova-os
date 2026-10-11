// The Drift's view (Tianxia: The Falling Blossoms), the same in both sessions: the flagship's idle overlay
// (Drift.qml, shown by hypridle before the lock) and Tenka Lite's (/usr/share/tenka/drift/LiteDrift.qml).
// The desk's own picture breathing very slowly, the season falling across it (plum and lotus petals, maple
// leaves, snow) and the hour with the day's proverb in the lower left. Flat shapes in the season's colours,
// no glow, no particles engine: every leaf is one animated number (its trip down the screen) and the rest is
// arithmetic on it. `still` stops all motion (performance mode). Pure QtQuick + QtQuick.Shapes, no Quickshell.
import QtQuick
import QtQuick.Shapes

Item {
    id: v
    property string wallpaper: ""
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color fall: "#c4532d"       // the season's colour (Theme.seasonLight)
    property string season: "maple"      // plum | lotus | maple | snow
    property string face: "Marcellus"
    property string proverb: ""
    property bool xia: false
    property bool still: false
    property int count: season === "snow" ? 46 : 30
    property date now: new Date()
    clip: true

    Timer { interval: 1000; running: v.visible; repeat: true; triggeredOnStart: true; onTriggered: v.now = new Date() }

    Rectangle { anchors.fill: parent; color: v.base }
    Image {
        id: pic
        anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
        source: v.wallpaper ? "file://" + v.wallpaper : ""; sourceSize.width: 2560
        transformOrigin: Item.Center
        // the picture breathes: 8 % closer over a minute and a half, then back
        SequentialAnimation on scale {
            running: !v.still && v.visible; loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.08; duration: 90000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.08; to: 1.0; duration: 90000; easing.type: Easing.InOutSine }
        }
    }
    // an ink falloff, darker toward the lower left where the words sit
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0)
        gradient: Gradient { orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(v.base.r, v.base.g, v.base.b, 0.18) }
            GradientStop { position: 1.0; color: Qt.rgba(v.base.r, v.base.g, v.base.b, 0.62) } } }

    // ---- the season, falling
    Repeater {
        model: v.count
        delegate: Item {
            id: leaf
            required property int index
            // a fixed scatter per leaf (no Math.random: the same leaves every time, and renders repeat)
            function h(k) { const s = Math.sin((index + 1) * 12.9898 + k * 78.233) * 43758.5453; return s - Math.floor(s) }
            readonly property real phase: h(1)
            readonly property real lane: h(2)
            readonly property real big: v.season === "snow" ? 5 + h(3) * 8 : v.season === "maple" ? 26 + h(3) * 34 : 18 + h(3) * 22
            readonly property real sway: 18 + h(4) * 46
            readonly property real spin: (h(5) - 0.5) * 2.2
            readonly property real depth: 0.45 + h(6) * 0.5          // nearer leaves are larger, brighter, faster
            property real t: 0
            readonly property real p: (t + phase) % 1
            width: big; height: big
            x: lane * (v.width + 80) - 40 + Math.sin(p * Math.PI * 2 * (1.2 + h(7))) * sway
            y: -60 + p * (v.height + 120)
            rotation: h(8) * 360 + p * 360 * spin
            opacity: depth
            transform: Rotation { origin.x: leaf.width / 2; origin.y: leaf.height / 2; axis { x: 1; y: 0.3; z: 0 }
                                  angle: v.season === "snow" ? 0 : Math.sin(leaf.p * Math.PI * 2 * 2.3 + leaf.phase * 6) * 62 }
            NumberAnimation on t { running: !v.still && v.visible; from: 0; to: 1; loops: Animation.Infinite
                                   duration: (v.season === "snow" ? 21000 : 17000) / (0.6 + leaf.depth) }
            // snow: a soft round flake
            Rectangle { visible: v.season === "snow"; anchors.fill: parent; radius: width / 2; color: v.fall }
            // a petal (plum, lotus) or a maple leaf, as one flat shape in a 24-unit box
            Shape {
                visible: v.season !== "snow"
                anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Qt.rgba(v.fall.r + (1 - v.fall.r) * (1 - leaf.depth) * 0.25, v.fall.g + (1 - v.fall.g) * (1 - leaf.depth) * 0.25,
                                       v.fall.b + (1 - v.fall.b) * (1 - leaf.depth) * 0.25, 1)
                    strokeWidth: -1
                    scale: Qt.size(leaf.width / 24, leaf.height / 24)
                    PathSvg {
                        path: v.season === "maple"
                              ? "M12 1 L13.6 6.4 L17.2 4.6 L16.2 9.6 L21.6 8.2 L19 12.4 L23 14.4 L17.2 15.6 L18 19.4 L13 17.4 L12.6 23 L11.4 23 L11 17.4 L6 19.4 L6.8 15.6 L1 14.4 L5 12.4 L2.4 8.2 L7.8 9.6 L6.8 4.6 L10.4 6.4 Z"
                              : "M12 2 C15.5 4.5 18.5 9.5 17 15 C15.8 19.5 13.5 22 12 22 C10.5 22 8.2 19.5 7 15 C5.5 9.5 8.5 4.5 10.6 3.4 L12 6 Z"
                    }
                }
            }
        }
    }

    // ---- the hour, the day and the proverb, lower left
    Column {
        x: Math.round(v.width * 0.065); anchors.bottom: parent.bottom; anchors.bottomMargin: Math.round(v.height * 0.10)
        spacing: 10
        Text { text: Qt.formatTime(v.now, "hh:mm"); color: v.text; font.family: v.face; font.pixelSize: Math.round(v.height * 0.105)
               font.letterSpacing: 4; lineHeight: 0.9 }
        Row {
            spacing: 14
            Text { text: Qt.formatDate(v.now, "dddd").toUpperCase() + "   ·   " + Qt.formatDate(v.now, "d MMMM").toUpperCase()
                   color: v.gold; font.family: v.face; font.pixelSize: 13; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 36; height: 1; color: Qt.rgba(v.gold.r, v.gold.g, v.gold.b, 0.6); anchors.verticalCenter: parent.verticalCenter }
            Text { text: ({ plum: "PLUM", lotus: "LOTUS", maple: "MAPLE", snow: "SNOW" })[v.season] || ""
                   color: v.fall; font.family: v.face; font.pixelSize: 13; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        }
        Item { width: 1; height: 8 }
        Text { text: v.proverb; color: Qt.rgba(v.text.r, v.text.g, v.text.b, 0.72); font.family: v.face; font.pixelSize: 17
               width: Math.min(implicitWidth, v.width * 0.5); wrapMode: Text.WordWrap }
    }
}
