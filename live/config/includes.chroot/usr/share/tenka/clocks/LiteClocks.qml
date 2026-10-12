// Tenka Lite's Under Heaven (Tianxia: The Four Seas): the flagship's card (/etc/xdg/quickshell/tenka/clocks/
// ClocksCard.qml) in a small frameless Qt window on X11. `tenka-clocks open` writes the places to a file, starts this
// window and listens on stderr: the card says "CLOCKS ADD <zone>" or "CLOCKS REMOVE <zone>", tenka-clocks keeps the
// list and rewrites the file, which this window reads again. Esc or a click elsewhere closes it.
// Arguments: <state.json> <zones.json> <shell-theme.json> [--at EPOCH] [--query WORDS]
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/clocks"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property int base: Math.max(0, args.indexOf("--") + 1)
    readonly property string statePath: args[base] || ""
    readonly property string zonesPath: args[base + 1] || ""
    readonly property string themePath: args[base + 2] || ""
    property bool wasActive: false
    property string last: ""
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: card.width; height: card.height
    color: "transparent"
    visible: false
    title: "Under Heaven"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function reload() { var t = read(statePath); if (t && t !== last) { last = t; try { card.s = JSON.parse(t) } catch (e) {} } }
    function opt(k) { var i = args.indexOf(k); return i >= 0 ? args[i + 1] : "" }
    onActiveChanged: { if (active) { wasActive = true; card.forceActiveFocus() } else if (wasActive && !quitting.running) quitting.start() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) Qt.quit() }
    Timer { interval: 700; repeat: true; running: true; onTriggered: w.reload() }   // tenka-clocks rewrites it after a change

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        reload()
        try { card.zones = JSON.parse(read(zonesPath)) } catch (e) {}
        w.title = card.s.title || (card.xia ? "The Four Seas" : "Under Heaven")
        if (opt("--at")) card.nowOverride = Number(opt("--at")) * 1000
        // placed once the screen is known (a binding made before it is read 0 and the window manager chose instead)
        w.x = Screen.virtualX + (Screen.width - w.width) / 2
        w.y = Screen.virtualY + Math.max(40, (Screen.height - w.height) * 0.4)
        w.visible = true
        w.requestActivate(); card.forceActiveFocus()
        if (opt("--query")) { card.beginAdd(); card.typed(opt("--query")) }
    }

    ClocksCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
        onAddAsked: z => console.log("CLOCKS ADD " + z)
        onRemoveAsked: z => console.log("CLOCKS REMOVE " + z)
    }
}
