// Tenka Lite's Incense (Tianxia: The Joss Stick): the flagship's card (/etc/xdg/quickshell/tenka/incense/
// IncenseCard.qml) in a small frameless Qt window on X11. `tenka-incense open` starts it and listens on stderr:
// the card asks "LIGHT <min>" or "OUT", tenka-incense does it and rewrites incense.json, which this window reads
// every second. ESC or a click elsewhere closes the window; the stick burns on (tenka-incense keeps the time).
// Arguments: <incense.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/incense"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string statePath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    property bool wasActive: false
    property string lastState: ""
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: card.width; height: card.height
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Math.max(40, (Screen.height - height) * 0.42)
    color: "transparent"
    visible: true
    title: "The Incense"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    // incense.json holds start/until/total in ms; the card wants the shape `tenka-incense state` prints
    function load() {
        var d = {}; try { d = JSON.parse(read(statePath)) } catch (e) { return }
        var t = Date.now(), burning = !!d.until && d.until > t
        var s = { burning: burning, until: burning ? d.until : 0, total: Math.round((d.total || 0) / 1000),
                  minutes: d.minutes || 15, burned: d.burned || 0, garden: d.garden || "" }
        // only on a change: a new `s` resets the card's choice to the stored length, which would undo a key
        var k = JSON.stringify(s)
        if (k !== w.lastState) { w.lastState = k; card.s = s }
    }
    onActiveChanged: { if (active) { wasActive = true; card.forceActiveFocus() } else if (wasActive && !quitting.running) quitting.start() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) Qt.quit() }
    Timer { interval: 1000; repeat: true; running: true; onTriggered: w.load() }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        w.title = card.xia ? "The Joss Stick" : "The Incense"
        load()
        w.requestActivate(); card.forceActiveFocus()
    }

    IncenseCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"; uiFace: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
        onLightAsked: m => { console.log("LIGHT " + m); lightSoon.restart() }
        onOutAsked: { console.log("OUT"); lightSoon.restart() }
        onGardenAsked: n => { console.log("GARDEN " + (n || "off")); lightSoon.restart() }
    }
    Timer { id: lightSoon; interval: 300; onTriggered: w.load() }
}
