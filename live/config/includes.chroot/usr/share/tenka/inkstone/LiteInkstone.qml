// Tenka Lite's Inkstone (Tianxia: The Brush): the flagship's glyph card (/etc/xdg/quickshell/tenka/inkstone/
// InkCard.qml) in a small frameless Qt window on X11, so Super+. finds a glyph by name in both sessions.
// `tenka-glyphs open` writes the shelves to a file and starts it; the chosen glyph goes back on stderr as one
// "TENKA-GLYPH <glyph>" line and the window quits, so the helper can type it into the window that had the
// keyboard. Nothing stays resident. Arguments: <shelves.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/inkstone"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string shelfPath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    property bool wasActive: false
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: 700; height: 646
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Math.max(40, Screen.height * 0.18)
    color: "transparent"
    visible: true
    title: "The Inkstone"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function bye(g) {
        if (g) console.info("TENKA-GLYPH " + g)
        Qt.quit()
    }
    // a click elsewhere hands the keyboard away: the Inkstone closes, like the flagship's wash
    onActiveChanged: { if (active) wasActive = true; else if (wasActive && !quitting.running) quitting.start() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) w.bye("") }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        var d = {}; try { d = JSON.parse(read(shelfPath)) } catch (e) {}
        card.reset(d.simQuery || "")
        card.load(d, d.simShelf || "", d.simSel || "")
        w.requestActivate(); card.focusField()
    }

    InkCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"; uiFace: "Marcellus"
        onPlaced: g => w.bye(g)
        onDismissed: w.bye("")
    }
}
