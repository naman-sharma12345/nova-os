// Tenka Lite's Drift (Tianxia: The Falling Blossoms): the flagship's idle screen (/etc/xdg/quickshell/tenka/
// drift/DriftView.qml) as an xfce4-screensaver theme. tenka-drift (/usr/libexec/xfce4-screensaver) starts this and seats it in the
// screensaver's own window. Arguments: <shell-theme.json> <hour.json> <width> <height>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/drift"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    function arg(i, d) { return args.length > i ? args[args.length - 4 + i] : d }
    // seated in the screensaver's window (a size is given): born off screen and outside the window manager, so
    // the screensaver never sees itself covered (it stops its theme when it is) before tenka-drift (/usr/libexec/xfce4-screensaver) moves
    // this window inside its own
    readonly property bool seated: parseInt(arg(2, "")) > 0
    flags: seated ? (Qt.FramelessWindowHint | Qt.BypassWindowManagerHint) : Qt.FramelessWindowHint
    x: seated ? -30000 : 0; y: seated ? -30000 : 0
    width: parseInt(arg(2, "")) || Screen.width; height: parseInt(arg(3, "")) || Screen.height
    color: "#000000"
    visible: true
    title: "tenka-drift"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function dayOfYear(d) { return Math.floor((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 0)) / 86400000) }
    function seasonOf(d) { const m = d.getMonth() + 1; return m >= 3 && m <= 5 ? "plum" : m >= 6 && m <= 8 ? "lotus" : m >= 9 && m <= 11 ? "maple" : "snow" }

    Component.onCompleted: {
        var t = {}, hr = {}
        try { t = JSON.parse(read(arg(0, ""))) } catch (e) {}
        try { hr = JSON.parse(read(arg(1, ""))) } catch (e) {}
        var xia = t.name === "xianxia", now = new Date(), season = hr.season || seasonOf(now)
        var light = xia ? { plum: "#c97a9b", lotus: "#f0a3b8", maple: "#d9763a", snow: "#d8e2e6" }
                        : { plum: "#b8577a", lotus: "#e8a0b0", maple: "#c4532d", snow: "#dfe3e6" }
        if (t.base) { view.base = t.base; view.text = t.text; view.gold = t.gold }
        // Lite shows the 1080p copy of the desk's picture, as its desktop does
        if (t.wallpaper) view.wallpaper = w.height <= 1200 ? t.wallpaper.replace("/wallpapers/", "/wallpapers/1080/") : t.wallpaper
        view.xia = xia; view.season = season; view.fall = light[season] || view.gold
        var p = t.proverbs || []; view.proverb = p.length ? p[dayOfYear(now) % p.length] : ""
    }
    DriftView { id: view; anchors.fill: parent }
    // run by hand (not seated): any key or click ends it
    Item { anchors.fill: parent; focus: !w.seated; Keys.onPressed: Qt.quit() }
    MouseArea { anchors.fill: parent; enabled: !w.seated; onClicked: Qt.quit() }
}
