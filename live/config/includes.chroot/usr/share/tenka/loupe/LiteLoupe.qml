// Tenka Lite's Loupe (Tianxia: The Mirror): the flagship's colour picker and screen ruler (/etc/xdg/quickshell/
// tenka/loupe/LoupeView.qml) over a frozen X11 screen, in a full-screen frameless Qt window. `tenka-loupe open`
// (Super+Shift+C) freezes the screen with xfce4-screenshooter first, then starts this; a copy goes back on stderr
// as one "TENKA-COPY <text>" line, which the helper puts on the clipboard and in LATELY. ESC closes.
// Arguments: <frozen screen.png> <lately.json> <shell-theme.json>.
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/loupe"

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string shotPath: args.length >= 3 ? args[args.length - 3] : ""
    readonly property string latelyPath: args.length >= 2 ? args[args.length - 2] : ""
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    x: Screen.virtualX; y: Screen.virtualY; width: Screen.width; height: Screen.height
    visibility: Window.FullScreen
    color: "black"
    visible: true
    title: "The Loupe"

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { lp.base = t.base; lp.text = t.text; lp.gold = t.gold }
        lp.xia = t.name === "xianxia"; lp.radius = lp.xia ? 12 : 6
        try { lp.lately = JSON.parse(read(latelyPath)) } catch (e) {}
        lp.shot = "file://" + shotPath
        w.requestActivate(); lp.focusPane()
    }

    LoupeView {
        id: lp
        anchors.fill: parent
        open: true
        face: "Marcellus"
        onCopyRequested: t => {
            console.info("TENKA-COPY " + t)
            if (/^#[0-9a-fA-F]{6}$/.test(t)) {            // LATELY shows it at once, as the flagship's does after its read
                var c = t.toLowerCase(); lp.lately = [c].concat(lp.lately.filter(function (x) { return x !== c })).slice(0, 12)
            }
        }
        onCloseRequested: Qt.quit()
    }
}
