// The Garden's card (Tianxia: The Mountain Hall), the same in both sessions: the flagship shell (Garden.qml) and
// Tenka Lite (/usr/share/tenka/garden/LiteGarden.qml). Four sounds Tenka makes itself, each with a small mark
// drawn in hairlines: rain, a stream, pines, embers. The one playing is underlined in the accent; a hairline
// track sets the volume. tenka-ambience keeps the state (set `s`); this card only asks (playAsked / stopAsked /
// volumeAsked). 1-4 or a click plays, Space or 0 stops, the arrows choose and set the volume, ESC closes (it plays on).
// Pure QtQuick + Canvas. Flat, no glow.
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
    property var s: ({ playing: false, name: "rain", volume: 60 })
    readonly property var names: ["rain", "stream", "pines", "embers"]
    readonly property var lines: xia ? ({ rain: "on the hall's tiles", stream: "down the mountain", pines: "on the ridge", embers: "in the brazier" })
                                     : ({ rain: "on the roof", stream: "over stones", pines: "in the wind", embers: "a low fire" })
    property int sel: Math.max(0, names.indexOf(s.name))
    width: 640; height: 330
    signal dismissed()
    signal playAsked(string name)
    signal stopAsked()
    signal volumeAsked(int v)
    onSChanged: sel = Math.max(0, names.indexOf(s.name))

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function vol(v) { card.volumeAsked(Math.max(0, Math.min(100, Math.round(v / 5) * 5))) }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) card.dismissed()
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4) card.playAsked(names[e.key - Qt.Key_1])
        else if (e.key === Qt.Key_Space || e.key === Qt.Key_0) card.stopAsked()
        else if (e.key === Qt.Key_Left) sel = Math.max(0, sel - 1)
        else if (e.key === Qt.Key_Right) sel = Math.min(3, sel + 1)
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (s.playing && s.name === names[sel]) card.stopAsked(); else card.playAsked(names[sel]) }
        else if (e.key === Qt.Key_Up) card.vol(s.volume + 5)
        else if (e.key === Qt.Key_Down) card.vol(s.volume - 5)
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    Row {
        x: 32; y: 30; spacing: 14
        Text { text: card.xia ? "THE MOUNTAIN HALL" : "THE GARDEN"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 40; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        Text { text: card.s.playing ? "playing" : "quiet"; color: card.alpha(card.text, 0.42); font.family: card.uiFace
               font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
        x: 32; y: 72; spacing: 0
        Repeater {
            model: card.names
            Item {
                id: tile
                required property string modelData; required property int index
                readonly property bool on: card.s.playing && card.s.name === modelData
                readonly property bool chosen: card.sel === index
                width: (card.width - 64) / 4; height: 176
                Rectangle { anchors.fill: parent; anchors.margins: 6; color: "transparent"; radius: card.xia ? 10 : 3
                            border.width: 1; border.color: card.alpha(tile.chosen ? card.gold : card.text, tile.chosen ? 0.45 : 0.10) }
                Canvas {
                    id: mark
                    anchors.horizontalCenter: parent.horizontalCenter; y: 26; width: 84; height: 64
                    antialiasing: true
                    property real t: 0
                    NumberAnimation on t { running: tile.on && card.visible; from: 0; to: 1; duration: 2400; loops: Animation.Infinite }
                    onTChanged: requestPaint()
                    Connections { target: tile; function onOnChanged() { mark.requestPaint() } function onChosenChanged() { mark.requestPaint() } }
                    onPaint: {
                        const c = getContext("2d"); c.reset();
                        c.strokeStyle = card.alpha(tile.on ? card.text : card.gold, tile.on ? 0.9 : 0.6);
                        c.fillStyle = c.strokeStyle; c.lineWidth = 1.2; c.lineCap = "round";
                        const w = width, h = height, k = t;
                        if (tile.modelData === "rain") {              // slanted strokes falling
                            for (let i = 0; i < 9; i++) {
                                const x = 8 + i * 8.5, y = ((i * 23 + k * h) % (h - 14));
                                c.beginPath(); c.moveTo(x + 3, y); c.lineTo(x, y + 12); c.stroke();
                            }
                        } else if (tile.modelData === "stream") {     // three lines of moving water
                            for (let j = 0; j < 3; j++) {
                                c.beginPath();
                                for (let x = 0; x <= w; x += 2) {
                                    const y = 18 + j * 14 + 3.2 * Math.sin((x / w) * Math.PI * 3 + k * Math.PI * 2 + j * 1.3);
                                    if (x === 0) c.moveTo(x, y); else c.lineTo(x, y);
                                }
                                c.stroke();
                            }
                        } else if (tile.modelData === "pines") {      // a pine: a trunk and five tiers of needles, leaning in the wind
                            const lean = tile.on ? 3 * Math.sin(k * Math.PI * 2) : 0;
                            c.beginPath(); c.moveTo(w / 2, h - 2); c.lineTo(w / 2 + lean * 0.4, 6); c.stroke();
                            for (let i = 0; i < 5; i++) {
                                const y = 12 + i * 10, sp = 8 + i * 5, dx = lean * (1 - i / 5);
                                c.beginPath(); c.moveTo(w / 2 - sp + dx, y + 6); c.lineTo(w / 2 + dx * 0.6, y); c.lineTo(w / 2 + sp + dx, y + 6); c.stroke();
                            }
                        } else {                                      // embers: a low arc of coals and sparks rising
                            c.beginPath(); c.moveTo(10, h - 10); c.quadraticCurveTo(w / 2, h - 26, w - 10, h - 10); c.stroke();
                            c.beginPath(); c.moveTo(18, h - 4); c.lineTo(w - 18, h - 4); c.stroke();
                            for (let i = 0; i < 6; i++) {
                                const ph = (k + i / 6) % 1, x = 20 + i * 9 + 4 * Math.sin(ph * 6 + i), y = h - 22 - ph * (h - 26);
                                c.globalAlpha = tile.on ? 1 - ph : 0.7;
                                c.fillStyle = i % 2 ? card.accent : c.strokeStyle;
                                c.beginPath(); c.arc(x, y, 1.6, 0, Math.PI * 2); c.fill();
                            }
                            c.globalAlpha = 1;
                        }
                    }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; y: 106; text: tile.modelData.toUpperCase()
                       color: tile.on ? card.text : card.alpha(card.text, 0.7); font.family: card.face; font.pixelSize: 13; font.letterSpacing: 4 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; y: 128; text: card.lines[tile.modelData]
                       color: card.alpha(card.text, 0.42); font.family: card.uiFace; font.pixelSize: 12 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 152; width: 28; height: 1; color: card.accent; visible: tile.on }
                Text { x: 14; y: 14; text: tile.index + 1; color: card.alpha(card.text, 0.28); font.family: card.uiFace; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { card.sel = tile.index; tile.on ? card.stopAsked() : card.playAsked(tile.modelData) } }
            }
        }
    }

    // the volume: a hairline with a gold mark; click or drag along it
    Item {
        x: 38; y: 266; width: card.width - 76; height: 24
        Text { id: vl; anchors.verticalCenter: parent.verticalCenter; text: "VOLUME"; color: card.alpha(card.gold, 0.85)
               font.family: card.face; font.pixelSize: 10; font.letterSpacing: 4 }
        Item {
            id: track
            anchors.left: vl.right; anchors.leftMargin: 18; anchors.right: vn.left; anchors.rightMargin: 16; height: parent.height
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: card.alpha(card.text, 0.18) }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * card.s.volume / 100; height: 1; color: card.alpha(card.gold, 0.8) }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: parent.width * card.s.volume / 100 - 1; width: 2; height: 12; color: card.gold }
            MouseArea { anchors.fill: parent; onPressed: m => card.vol(100 * m.x / width); onPositionChanged: m => { if (pressed) card.vol(100 * m.x / width) } }
        }
        Text { id: vn; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: card.s.volume
               color: card.alpha(card.text, 0.6); font.family: card.uiFace; font.pixelSize: 12 }
    }
    Text { x: 32; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
           text: "1 – 4 play  ·  Space stops  ·  arrows choose and set the volume  ·  ESC closes, it plays on"
           color: card.alpha(card.text, 0.3); font.family: card.uiFace; font.pixelSize: 11 }
}
