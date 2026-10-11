// Tenka Lite's Lantern (Tianxia: The Ember): the flagship's battery and power card (/etc/xdg/quickshell/tenka/
// lantern/LanternCard.qml) in a small frameless Qt window on X11, so Lite has the same card as the flagship.
// `tenka-lantern open` starts it and keeps its facts file fresh every two seconds; a profile the card asks for
// goes back on stderr as one "TENKA-POWER <profile>" line, which the helper sets. ESC or a click elsewhere
// closes it, and nothing stays resident. Arguments: <facts.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/lantern"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string factsPath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    property bool wasActive: false
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    width: card.width; height: card.height
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Math.max(40, Screen.height * 0.22)
    color: "transparent"
    visible: true
    title: "The Lantern"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function fetch() {
        var g = null; try { g = JSON.parse(read(factsPath)) } catch (e) {}
        if (!g) return
        // a profile just asked for shows at once; the helper's next read confirms it or brings the note
        if (asked !== "" && g.profile !== asked && g.note === "") g.profile = asked
        else asked = ""
        card.g = g; card.note = g.note || ""
    }
    property string asked: ""
    // a click elsewhere hands the keyboard away: the Lantern closes, like the flagship's wash
    onActiveChanged: { if (active) wasActive = true; else if (wasActive && !quitting.running) quitting.start() }
    Timer { id: quitting; interval: 120; onTriggered: if (!w.active) Qt.quit() }
    Timer { interval: 1000; repeat: true; running: true; onTriggered: w.fetch() }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        fetch()
        w.requestActivate(); card.forceActiveFocus()
    }

    LanternCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"; uiFace: "Marcellus"
        focus: true
        onWant: p => { w.asked = p; console.info("TENKA-POWER " + p) }
        onDismissed: Qt.quit()
    }
}
