// Tenka Lite's OSD: the flagship's one OSD card (/etc/xdg/quickshell/tenka/osd/OsdCard.qml) in a
// tiny frameless Qt window on X11. `tenka-osd` starts it on the first key, writes each new level to
// a small state file it watches, and it quits two seconds after the last key, so nothing stays
// resident on a low-end machine. Arguments: <state file> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/osd"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string statePath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
    width: 340; height: 72
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Screen.height - height - 96
    color: "transparent"
    visible: true
    title: "tenka-osd"

    property string stamp: ""
    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function poll() {
        var s = read(statePath).trim().split(" ")
        if (s.length < 4 || s[3] === stamp) return false
        stamp = s[3]; card.kind = s[0]; card.value = Number(s[1]) / 100; card.muted = s[2] === "1"
        card.shown = true; hide.restart(); bye.stop()
        return true
    }
    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { card.base = t.base; card.text = t.text; card.sub = t.subtext; card.accent = t.accent; card.gold = t.gold }
        card.radius = t.name === "xianxia" ? 12 : 6
        poll()
    }
    Timer { interval: 60; repeat: true; running: true; onTriggered: w.poll() }
    Timer { id: hide; interval: 1400; onTriggered: { card.shown = false; bye.restart() } }
    Timer { id: bye; interval: 600; onTriggered: { if (!w.poll()) Qt.quit() } }

    OsdCard { id: card; x: 0; y: 0; width: 340; height: 64; face: "Marcellus" }
}
