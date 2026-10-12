// Tenka Lite's Garden (Tianxia: The Mountain Hall): the flagship's card (/etc/xdg/quickshell/tenka/garden/
// GardenCard.qml) in a small frameless Qt window on X11. `tenka-ambience open` starts it and listens on stderr:
// the card asks "PLAY <name>", "STOP" or "VOL <n>", tenka-ambience does it and rewrites ambience.json, which this
// window reads every second. ESC or a click elsewhere closes the window; the sound plays on.
// Arguments: <ambience.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/garden"

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
    title: "The Garden"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function load() {
        var d = {}; try { d = JSON.parse(read(statePath)) } catch (e) { return }
        var s = { playing: !!d.playing, name: d.name || "rain", volume: d.volume === undefined ? 60 : d.volume }
        // only on a change: a new `s` resets the card's choice, which would undo a key
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
        w.title = card.xia ? "The Mountain Hall" : "The Garden"
        load()
        w.requestActivate(); card.forceActiveFocus()
    }

    GardenCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"; uiFace: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
        onPlayAsked: n => { console.log("PLAY " + n); lightSoon.restart() }
        onStopAsked: { console.log("STOP"); lightSoon.restart() }
        onVolumeAsked: v => { console.log("VOL " + v); lightSoon.restart() }
    }
    Timer { id: lightSoon; interval: 1400; onTriggered: w.load() }
}
