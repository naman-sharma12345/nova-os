// tenka-shot's frame: the capture laid on the pack's ink with a gold hairline, the seal pressed into
// its lower-right corner, and one small-caps line beneath (the name, the date, the hour's old name).
// Rendered offscreen (QT_QPA_PLATFORM=offscreen) and saved as a PNG; no window ever shows.
// Arguments: <capture.png> <out.png> <shell-theme.json>.
import QtQuick
import QtQuick.Window

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string src: args[args.length - 3]
    readonly property string out: args[args.length - 2]
    readonly property string themePath: args[args.length - 1]
    property var t: ({ name: "samurai", base: "#0f0d0c", text: "#efe6d6", subtext: "#b8ab96", gold: "#c9a35a", display: "Tenka" })
    readonly property real m: Math.round(Math.max(48, Math.min(shot.sourceSize.width, shot.sourceSize.height) * 0.06))
    readonly property real band: Math.round(m * 0.95)
    readonly property real sealSize: Math.round(Math.min(150, Math.max(64, m * 1.35)))
    readonly property var hours: ["Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"]
    width: Math.max(1, shot.sourceSize.width + 2 * m)
    height: Math.max(1, shot.sourceSize.height + 2 * m + band)
    visible: true
    color: t.base

    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function al(c, a) { var q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    Component.onCompleted: { try { var j = JSON.parse(read(themePath)); if (j.base) t = j } catch (e) {} }

    Item {
        id: page
        width: w.width; height: w.height
        Rectangle { anchors.fill: parent; color: w.t.base }
        Image {
            id: shot
            x: w.m; y: w.m
            source: "file://" + w.src
            asynchronous: false; cache: false; smooth: true
        }
        Rectangle {   // the hairline: no shadow, no glow
            x: w.m - 1; y: w.m - 1; width: shot.width + 2; height: shot.height + 2
            color: "transparent"; border.width: 1; border.color: w.al(w.t.gold, 0.6)
        }
        Image {       // the seal of the splash and the login screen, pressed over the corner (its art has a margin)
            id: seal
            width: w.sealSize * 1.6; height: width
            x: w.m + shot.width - width * 0.56; y: w.m + shot.height - height * 0.46
            source: "file:///usr/share/sddm/themes/tenka-" + w.t.name + "/seal.png"
            onStatusChanged: if (status === Image.Error) source = "file:///etc/xdg/quickshell/tenka/assets/" + w.t.name + "/seal.png"
            asynchronous: false; rotation: -3; smooth: true; mipmap: true
        }
        Row {
            x: w.m; y: w.m + shot.height + (w.band - height) / 2 + w.m * 0.15
            spacing: Math.round(w.m * 0.3)
            Rectangle { width: Math.round(w.m * 0.12); height: width; rotation: 45; color: w.t.gold; anchors.verticalCenter: parent.verticalCenter }
            Text {
                readonly property date now: new Date()
                text: (w.t.display || "Tenka").toUpperCase() + "   ·   " + Qt.formatDate(now, "d MMMM yyyy").toUpperCase()
                      + "   ·   HOUR OF THE " + w.hours[Math.floor(((now.getHours() + 1) % 24) / 2)].toUpperCase()
                color: w.al(w.t.text, 0.78); font.family: "Marcellus"
                font.pixelSize: Math.round(Math.max(13, w.m * 0.3)); font.letterSpacing: Math.round(Math.max(3, w.m * 0.09))
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    property bool done: false
    function save() {
        if (done || shot.status !== Image.Ready || seal.status === Image.Loading) return
        done = true
        page.grabToImage(function (r) { r.saveToFile(w.out); Qt.quit() })
    }
    Timer { interval: 150; repeat: true; running: true; onTriggered: w.save() }
    Timer { interval: 15000; running: true; onTriggered: Qt.exit(1) }
}
