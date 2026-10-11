// Tenka Lite's Almanac (Tianxia: The Heavenly Calendar): the flagship's card (/etc/xdg/quickshell/tenka/almanac/
// AlmanacCard.qml) in a small frameless Qt window on X11. `tenka-almanac open` writes the wheel facts to a file and
// starts it. ESC or a click elsewhere closes it, and nothing stays resident. Arguments: <wheel.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/almanac"

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
    title: "The Almanac"

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
        try { card.d = JSON.parse(read(factsPath)) } catch (e) {}
        w.title = card.xia ? "The Heavenly Calendar" : "The Almanac"
        w.requestActivate(); card.forceActiveFocus()
    }

    AlmanacCard {
        id: card
        x: 0; y: 0
        face: "Marcellus"; uiFace: "Marcellus"
        focus: true
        onDismissed: Qt.quit()
    }
}
