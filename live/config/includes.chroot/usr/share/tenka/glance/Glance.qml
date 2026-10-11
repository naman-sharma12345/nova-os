// The Glance (Tianxia: The Glimpse): a quick look at files from Thunar (Ctrl+Space, or the "Glance" action)
// without opening them, in both sessions. `tenka-glance FILE...` starts it and keeps its facts file fresh while
// the slow previews (a PDF's first page, a video's frame) are made. Arguments: <facts.json> <shell-theme.json>.
// Flat: one hairline frame, no glow.
import QtQuick
import QtQuick.Window
import "file:///usr/share/tenka/glance"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string factsPath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    flags: Qt.Dialog | Qt.FramelessWindowHint
    width: card.width; height: card.height
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + (Screen.height - height) / 2
    color: "transparent"
    visible: true
    title: "The Glance"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function fetch() {
        var g = null; try { g = JSON.parse(read(factsPath)) } catch (e) {}
        if (g) card.g = g
        pending = !!g && g.items.some(function (f) { return !f.ready })
    }
    property bool pending: true
    Timer { interval: 300; repeat: true; running: w.pending; onTriggered: w.fetch() }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.gold = t.gold; card.accent = t.accent }
        card.xia = t.name === "xianxia"; card.radius = card.xia ? 12 : 6
        fetch()
        w.requestActivate(); card.forceActiveFocus()
    }

    GlanceCard {
        id: card
        width: Math.min(980, Screen.width - 80); height: Math.min(700, Screen.height - 80)
        focus: true
        onDismissed: Qt.quit()
        onOpened: path => { Qt.openUrlExternally("file://" + path); Qt.quit() }
    }
}
