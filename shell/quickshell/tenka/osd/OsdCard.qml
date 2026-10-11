// Tenka's one on-screen display, the same card in both sessions: the flagship shell (Osd.qml)
// and Tenka Lite (/usr/share/tenka/osd/LiteOsd.qml, a tiny Qt window on X11). Pure QtQuick, no
// Quickshell, so both can load it. The ledger language of the cards and notifications: ink, a gold
// top rule, a word, a 2 px hairline with a small gold diamond, the number. Calm: a short fade and
// a 6 px rise, no bounce, no glow.
import QtQuick

Item {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color sub: "#a89f90"
    property color accent: "#d8412f"
    property color gold: "#c9a35a"
    property real radius: 6
    property string face: "Marcellus"
    property bool motion: true
    property string kind: "volume"      // "volume" | "brightness"
    property real value: 0              // 0..1
    property bool muted: false
    property bool shown: false
    implicitWidth: 340; implicitHeight: 64
    readonly property real v: Math.max(0, Math.min(1, value))
    function al(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    opacity: shown ? 1 : 0
    Behavior on opacity { enabled: card.motion; NumberAnimation { duration: card.shown ? 180 : 260; easing.type: Easing.OutQuad } }
    transform: Translate { y: card.shown ? 0 : 6; Behavior on y { enabled: card.motion; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.al(card.base, 0.95)
                border.width: 1; border.color: card.al(card.gold, 0.22) }
    Rectangle { x: card.radius; width: parent.width - 2 * card.radius; height: 1; color: card.al(card.gold, 0.85) }

    Text {
        id: word
        x: 22; anchors.verticalCenter: parent.verticalCenter
        width: 84
        text: card.kind === "brightness" ? "LIGHT" : (card.muted || card.v <= 0.001 ? "MUTED" : "VOLUME")
        color: card.sub; font.family: card.face; font.pixelSize: 12; font.letterSpacing: 4
    }
    Item {
        id: track
        anchors.left: word.right; anchors.leftMargin: 10
        anchors.right: num.left; anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter; height: 8
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: card.al(card.text, 0.12) }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter; height: 2
            width: parent.width * card.v
            color: card.muted ? card.al(card.sub, 0.5) : card.accent
            Behavior on width { enabled: card.motion; NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        }
        Rectangle {
            width: 7; height: 7; rotation: 45; antialiasing: true
            x: track.width * card.v - width / 2; anchors.verticalCenter: parent.verticalCenter
            color: card.muted ? card.sub : card.gold
            Behavior on x { enabled: card.motion; NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        }
    }
    Text {
        id: num
        anchors.right: parent.right; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter
        width: 40; horizontalAlignment: Text.AlignRight
        text: Math.round(card.v * 100); color: card.muted ? card.sub : card.text
        font.family: card.face; font.pixelSize: 22
    }
}
