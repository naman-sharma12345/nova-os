// The Seal's card (Tianxia: The Talisman), the same in both sessions: the flagship shell (Seal.qml, a layer-shell
// overlay) and Tenka Lite (/usr/share/tenka/seal-lite, Quickshell's polkit agent in a small X11 window).
// What is asked in Marcellus, the account, one ruled field. ENTER seals (`give`), ESC refuses (`refuse`).
// A wrong word says so in the accent, plainly. Pure QtQuick + Controls, no Quickshell. Flat: one gold rule, no glow.
import QtQuick
import QtQuick.Controls

Item {
    id: card
    width: 620; height: 352
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#b5452f"
    property real radius: 6
    property string face: "Marcellus"
    property bool xia: false
    property url sealImage: ""
    property string message: ""
    property string who: "you"
    property string prompt: "Password:"
    property string note: ""
    property bool noteIsError: false
    property bool echo: false
    property string preset: ""                 // the renders' stand-in word
    signal give(string word)
    signal refuse()
    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function focusField() { field.text = card.preset; field.forceActiveFocus() }
    function clear() { field.text = "" }

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.94)
                border.width: 1; border.color: card.alpha(card.gold, 0.45) }

    Row {
        x: 34; y: 30; spacing: 14
        Image { width: 22; height: 26; source: card.sealImage; smooth: true; anchors.verticalCenter: parent.verticalCenter; visible: card.sealImage != "" }
        Text { text: card.xia ? "THE TALISMAN IS ASKED" : "THE SEAL IS ASKED"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
    }
    Rectangle { x: 30; y: 74; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.35) }

    Text { x: 34; y: 96; width: parent.width - 68; text: card.message; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
           color: card.text; font.family: card.face; font.pixelSize: 21; lineHeight: 1.15 }
    Text { x: 34; y: 176; text: "AS  " + card.who.toUpperCase(); color: card.alpha(card.gold, 0.75)
           font.family: card.face; font.pixelSize: 11; font.letterSpacing: 4 }

    TextField {
        id: field
        x: 30; y: 200; width: parent.width - 60; height: 52
        background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                           color: field.activeFocus ? card.accent : card.alpha(card.gold, 0.4) } }
        placeholderText: card.prompt.replace(/:\s*$/, "").toLowerCase()
        placeholderTextColor: card.alpha(card.text, 0.38)
        echoMode: card.echo ? TextInput.Normal : TextInput.Password
        passwordCharacter: "•"
        color: card.text; font.family: card.face; font.pixelSize: 22; leftPadding: 4
        selectionColor: card.alpha(card.accent, 0.5)
        text: card.preset
        Keys.onEscapePressed: card.refuse()
        onAccepted: { card.give(field.text); field.text = "" }
    }
    Text { x: 34; y: 266; width: parent.width - 68; visible: card.note !== ""; text: card.note; elide: Text.ElideRight
           color: card.noteIsError ? card.accent : card.alpha(card.text, 0.6); font.family: card.face; font.pixelSize: 14 }

    Text {
        x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        text: "ENTER  to seal      ESC  to refuse"
        color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 12; font.letterSpacing: 2
    }
}
