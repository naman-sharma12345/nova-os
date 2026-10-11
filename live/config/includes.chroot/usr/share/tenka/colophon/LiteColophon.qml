// Tenka Lite's Colophon (Tianxia: The Lineage): the flagship's card (/etc/xdg/quickshell/tenka/colophon/
// ColophonCard.qml) in a small frameless Qt window on X11. `tenka-colophon open` reads the machine into a facts
// file and starts it; a copy is asked for on stderr ("COPY", tenka-colophon puts the text on the clipboard).
// ESC or a click elsewhere closes it, and nothing stays resident. Arguments: <facts.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/colophon"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string factsPath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    property bool wasActive: false
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: card.width; height: card.height
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Math.max(40, (Screen.height - height) * 0.42)
    color: "transparent"
    visible: true
    title: "The Colophon"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    onActiveChanged: { if (active) wasActive = true; else if (wasActive && !quitting.running) quitting.start() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) Qt.quit() }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        try { card.d = JSON.parse(read(factsPath)) } catch (e) {}
        w.title = card.xia ? "The Lineage" : "The Colophon"
        w.requestActivate(); card.forceActiveFocus()
    }

    ColophonCard {
        id: card
        x: 0; y: 0
        width: Math.min(900, Screen.width - 80)
        face: "Marcellus"; uiFace: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
        onCopyAsked: console.log("COPY")
    }
}
