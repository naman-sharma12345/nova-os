// Tenka Lite's Season's Poem (Tianxia: The Verse of the Season): the flagship's card (/etc/xdg/quickshell/tenka/poem/
// PoemCard.qml) in a small frameless Qt window on X11. `tenka-poem open` writes this term's poem to a file and starts
// this window. Esc or a click elsewhere closes it. Arguments: <state.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/poem"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string statePath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    property bool wasActive: false
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: card.width; height: card.height
    color: "transparent"
    visible: false
    title: "The Season's Poem"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    onActiveChanged: { if (active) { wasActive = true; card.forceActiveFocus() } else if (wasActive && !quitting.running) quitting.start() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) Qt.quit() }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        try { card.s = JSON.parse(read(statePath)) } catch (e) {}
        w.title = card.s.title || (card.xia ? "The Verse of the Season" : "The Season's Poem")
        // placed once the screen is known (a binding made before it is read 0 and the window manager chose instead)
        w.x = Screen.virtualX + (Screen.width - w.width) / 2
        w.y = Screen.virtualY + Math.max(40, (Screen.height - w.height) * 0.42)
        w.visible = true
        w.requestActivate(); card.forceActiveFocus()
    }

    PoemCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
    }
}
