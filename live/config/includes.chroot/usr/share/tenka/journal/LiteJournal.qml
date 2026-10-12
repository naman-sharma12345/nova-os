// Tenka Lite's Pillow Book (Tianxia: The Jade Record): the flagship's card (/etc/xdg/quickshell/tenka/journal/
// JournalCard.qml) in a small frameless Qt window on X11. `tenka-journal open` writes the state file, starts this
// window and listens on stderr: the card asks "PUT <the page as a JSON string>" and tenka-journal writes it.
// Esc, Ctrl+Enter or a click elsewhere keeps the page and closes the window.
// Arguments: <state.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/journal"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string statePath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    property bool wasActive: false
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: card.width; height: card.height
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Math.max(40, (Screen.height - height) * 0.40)
    color: "transparent"
    visible: true
    title: "The Pillow Book"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function done() { card.keep(); Qt.quit() }
    onActiveChanged: { if (active) { wasActive = true; page() } else if (wasActive && !quitting.running) quitting.start() }
    function page() { card.forceActiveFocus(); card.begin() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) w.done() }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        try { card.s = JSON.parse(read(statePath)) } catch (e) {}
        w.title = card.s.title || (card.xia ? "The Jade Record" : "The Pillow Book")
        w.requestActivate(); page()
    }

    JournalCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"; uiFace: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
        onSaveAsked: p => console.log("PUT " + JSON.stringify(p))
    }
}
