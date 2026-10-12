// The Season's Poem (Tianxia: The Verse of the Season): one classic poem for each solar term, drawn as a small
// hanging scroll: a gold rod above and below, the term, the poem centred, the poet, a vermilion seal. The same card in
// both sessions, the flagship shell (Poem.qml) and Tenka Lite (/usr/share/tenka/poem/LitePoem.qml). tenka-poem picks
// the poem on this machine; the card only draws. Esc closes. Flat, no glow.
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
    property var s: ({ title: "The Season's Poem", term: "", detail: "", lines: [], poet: "", era: "", next: "", note: "" })
    signal dismissed()
    width: card.xia ? 600 : 460
    height: col.implicitHeight + 112

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    focus: true
    Keys.onEscapePressed: card.dismissed()

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.base; border.width: 1; border.color: card.alpha(card.text, 0.12) }
    MouseArea { anchors.fill: parent; onClicked: card.forceActiveFocus() }

    // the scroll's rods: a gold hairline with a knob at each end
    component Rod: Item {
        width: card.width - 56; height: 9; x: 28
        Rectangle { anchors.verticalCenter: parent.verticalCenter; x: 6; width: parent.width - 12; height: 1.5; color: card.gold }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; x: 0; width: 6; height: 9; color: card.gold; radius: card.xia ? 3 : 0 }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; x: parent.width - 6; width: 6; height: 9; color: card.gold; radius: card.xia ? 3 : 0 }
    }
    Rod { y: 22 }
    Rod { y: card.height - 31 }

    Column {
        id: col
        x: 44; y: 56; width: card.width - 88; spacing: 0
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: (card.s.title || (card.xia ? "The Verse of the Season" : "The Season's Poem")).toUpperCase()
               color: card.gold; font.family: card.face; font.pixelSize: 11; font.letterSpacing: 3 }
        Item { width: 1; height: 10 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.s.term || ""; color: card.text; font.family: card.face; font.pixelSize: 26 }
        Item { width: 1; height: 6 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
               text: card.s.detail || ""; color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 12 }
        Item { width: 1; height: 26 }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 36; height: 1; color: card.alpha(card.text, 0.25) }
        Item { width: 1; height: 28 }
        // the poem: each line its own, centred; a long Tang line wraps under itself
        Repeater {
            model: card.s.lines || []
            Text {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter; width: col.width
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; lineHeight: 1.12
                text: modelData; color: card.text; font.family: card.face; font.pixelSize: card.xia ? 18 : 21
                bottomPadding: card.xia ? 9 : 11
            }
        }
        Item { width: 1; height: 16 }
        Item {
            anchors.horizontalCenter: parent.horizontalCenter; width: poet.implicitWidth + 30; height: 20
            Text { id: poet; anchors.verticalCenter: parent.verticalCenter; x: 0
                   text: "\u2014  " + (card.s.poet || "") + (card.s.era ? "   \u00b7   " + card.s.era : "")
                   color: card.gold; font.family: card.face; font.pixelSize: 13; font.letterSpacing: 0.8 }
            // the seal: a small vermilion stamp after the name, square on Tenka, round on Tianxia
            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: parent.width - 16; width: 16; height: 16
                        radius: card.xia ? 8 : 1.5; color: "transparent"; border.width: 1.4; border.color: card.accent
                        Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: card.xia ? 3 : 0; color: card.accent } }
        }
        Item { width: 1; height: 6; visible: !!card.s.note }
        Text { anchors.horizontalCenter: parent.horizontalCenter; visible: !!card.s.note; text: card.s.note || ""
               color: card.alpha(card.text, 0.4); font.family: card.face; font.pixelSize: 11 }
        Item { width: 1; height: 24 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.s.next ? ("NEXT  \u00b7  " + card.s.next).toUpperCase() : ""
               color: card.alpha(card.text, 0.42); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 2.2 }
    }
}
