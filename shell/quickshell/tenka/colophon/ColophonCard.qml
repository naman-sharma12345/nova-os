// The Colophon's card (Tianxia: The Lineage), the same in both sessions: the flagship shell (Colophon.qml, a
// layer-shell overlay) and Tenka Lite (/usr/share/tenka/colophon/LiteColophon.qml, a small Qt window on X11).
// Our own "about this computer": the pack's seal and wordmark on the left, and on the right what the desk is
// made of, read just now by tenka-colophon (set `d`). Like a book's colophon, a ruled list, no glow, no badges.
// Values are set in the system face (Inter): Marcellus draws 1 and 0 like I and O. C (or the line "C copies") asks for the record as text on the clipboard (signal copyAsked); ESC closes.
// Pure QtQuick, no Quickshell.
import QtQuick

Item {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#b5452f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property string brand: "Cinzel Decorative"
    property string sysFace: "Inter"
    property bool xia: false
    property var d: ({ name: "", tagline: "", crest: "", version: "", base: "", who: "", used: 0, rows: [] })
    property bool copied: false
    readonly property int rowH: 31
    width: 900
    height: Math.max(470, 96 + d.rows.length * rowH + 70)
    signal dismissed()
    signal copyAsked()

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function copy() { card.copyAsked(); card.copied = true; copiedT.restart() }
    Timer { id: copiedT; interval: 1800; onTriggered: card.copied = false }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape) card.dismissed()
        else if (e.key === Qt.Key_C && !(e.modifiers & Qt.AltModifier)) card.copy()
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    // ---- the left leaf: the seal, the name, the edition
    Item {
        id: leaf
        x: 0; y: 0; width: 300; height: parent.height
        Image {
            id: crest
            anchors.horizontalCenter: parent.horizontalCenter; y: 46
            width: 128; height: 128; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true
            source: card.d.crest ? "file://" + card.d.crest : ""
            sourceSize.width: 256; sourceSize.height: 256
        }
        Text {
            id: word
            anchors.horizontalCenter: parent.horizontalCenter; y: 194
            text: card.d.name; color: card.text; font.family: card.brand; font.pixelSize: 38
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: word.bottom; anchors.topMargin: 6
            text: card.d.tagline; color: card.gold; font.family: card.face; font.pixelSize: 10; font.letterSpacing: 4
        }
        Rectangle { id: lrule; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: word.bottom; anchors.topMargin: 34
                    width: 44; height: 1; color: card.alpha(card.gold, 0.55) }
        Text {
            id: ed
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: lrule.bottom; anchors.topMargin: 16
            text: card.d.version.replace(" (", "  ·  ").replace(")", ""); color: card.alpha(card.text, 0.85)
            font.family: card.sysFace; font.pixelSize: 14
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: ed.bottom; anchors.topMargin: 6
            text: card.d.base ? "on " + card.d.base : ""; color: card.alpha(card.text, 0.5); font.family: card.sysFace; font.pixelSize: 12
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            text: card.d.who; color: card.alpha(card.text, 0.32); font.family: card.sysFace; font.pixelSize: 11
        }
    }
    Rectangle { x: leaf.width; y: 30; width: 1; height: parent.height - 60; color: card.alpha(card.gold, 0.28) }

    // ---- the right leaf: the record
    Item {
        id: rec
        x: leaf.width + 34; y: 0; width: parent.width - leaf.width - 34 - 36; height: parent.height
        Row {
            y: 30; spacing: 14
            Text { text: card.xia ? "THE LINEAGE" : "THE COLOPHON"; color: card.gold; font.family: card.face
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 54; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            Text { text: card.xia ? "what this realm is made of" : "what this desk is made of"
                   color: card.alpha(card.text, 0.5); font.family: card.uiFace; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { y: 70; width: parent.width; height: 1; color: card.alpha(card.gold, 0.35) }
        Column {
            y: 84; width: parent.width
            Repeater {
                model: card.d.rows
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: rec.width; height: card.rowH
                    readonly property bool meter: modelData[0] === "Storage"
                    Text { anchors.verticalCenter: parent.verticalCenter; width: 118
                           text: modelData[0].toUpperCase(); color: card.gold; font.family: card.face
                           font.pixelSize: 10; font.letterSpacing: 3 }
                    Row {
                        x: 118; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Text { id: val; text: modelData[1]; color: card.alpha(card.text, 0.9)
                               font.family: card.sysFace; font.pixelSize: 14
                               elide: Text.ElideRight; width: Math.min(implicitWidth, rec.width - 118 - (more.visible ? more.implicitWidth + 12 : 0)) }
                        Text { id: more; visible: modelData.length > 2; text: visible ? modelData[2] : ""
                               color: card.alpha(card.text, 0.45); font.family: card.sysFace; font.pixelSize: 13 }
                    }
                    // the storage meter: a 1px track with a 2px filled part, the ledger's own meter
                    Item {
                        visible: row.meter; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 120; height: 3
                        Rectangle { y: 1; width: parent.width; height: 1; color: card.alpha(card.text, 0.18) }
                        Rectangle { width: Math.max(2, parent.width * Math.min(1, card.d.used || 0)); height: 3
                                    color: (card.d.used || 0) > 0.9 ? card.accent : card.gold }
                    }
                    Rectangle { visible: index < card.d.rows.length - 1; anchors.bottom: parent.bottom; width: parent.width
                                height: 1; color: card.alpha(card.text, 0.07) }
                }
            }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            text: card.copied ? "copied: the record is on the clipboard" : "C copies the record as text"
            color: card.copied ? card.accent : card.alpha(card.text, 0.32); font.family: card.uiFace; font.pixelSize: 11
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: card.copy() }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20; anchors.right: parent.right
            text: "ESC closes"; color: card.alpha(card.text, 0.32); font.family: card.uiFace; font.pixelSize: 11
        }
    }
}
