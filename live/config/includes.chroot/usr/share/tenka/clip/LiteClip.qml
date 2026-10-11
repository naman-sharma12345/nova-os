// Tenka Lite's Recall: the flagship's clipboard card (shell/quickshell/tenka/Clipboard.qml) as a small
// frameless Qt window on X11. `tenka-clipboard` lists cliphist into a runtime dir, decodes each item
// once (pictures and full words), and starts this; ENTER writes "pick <id>", DEL queues "del <id>"
// to <dir>/act, and the script applies them after the window closes. Flat, no glow.
// Arguments: <dir> <shell-theme.json>.
import QtQuick
import QtQuick.Window

Window {
    id: w
    readonly property var args: Qt.application.arguments
    readonly property string dir: args.length >= 2 ? args[args.length - 2] : "/tmp"
    readonly property string themePath: args.length >= 1 ? args[args.length - 1] : ""
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Dialog
    width: 1040; height: 620
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + Math.round(Screen.height * 0.16)
    color: base
    visible: true
    title: "Recall"

    // the pack's colours (from shell-theme.json; Tenka's ink if it cannot be read)
    property color base: "#14100e"; property color ink: "#f3e9d8"; property color accent: "#c8102e"
    property color gold: "#c9a45c"; property string stroke: ""; property bool xia: false
    readonly property string face: "Marcellus"
    function a(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }

    property var items: []
    property var gone: []
    property int sel: 0
    property string full: ""
    function read(p) {
        try { var x = new XMLHttpRequest(); x.open("GET", "file://" + p, false); x.send(); return x.responseText || "" }
        catch (e) { return "" }
    }
    function write(p, t) {
        try { var x = new XMLHttpRequest(); x.open("PUT", "file://" + p, false); x.send(t) } catch (e) {}
    }
    function parse(t) {
        var out = []
        t.split("\n").forEach(function (line) {
            var k = line.indexOf("\t"); if (k < 1) return
            var id = line.slice(0, k), rest = line.slice(k + 1)
            if (/^\[\[ binary data /.test(rest)) {
                var f = rest.split(/\s+/), e = f[5]   // [[ binary data 344 KiB png 768x432 ]]
                out.push({ id: id, text: f.slice(5, -1).join(" "), kind: "image", file: "file://" + dir + "/" + id + "." + e })
            } else {
                out.push({ id: id, text: rest.replace(/\s+/g, " ").trim(), kind: /^(https?:\/\/|www\.)\S+$/.test(rest.trim()) ? "link" : "text", file: "" })
            }
        })
        items = out
    }
    readonly property string q: field.text.trim().toLowerCase()
    readonly property var shown: items.filter(function (i) {
        return gone.indexOf(i.id) < 0 && (q === "" || i.text.toLowerCase().indexOf(q) >= 0 || (q === "image" && i.kind === "image")) })
    readonly property var cur: shown.length ? shown[Math.min(sel, shown.length - 1)] : null
    onCurChanged: full = cur ? (cur.kind === "image" ? cur.text : (read(dir + "/" + cur.id + ".txt") || cur.text)) : ""
    function finish(pick) {
        var t = gone.map(function (id) { return "del " + id }).join("\n")
        if (pick) t += (t ? "\n" : "") + "pick " + pick.id
        if (t) write(dir + "/act", t + "\n")
        Qt.quit()
    }
    function forget(i) { if (!i) return; var g = gone.slice(); g.push(i.id); gone = g }

    Component.onCompleted: {
        var t = {}; try { t = JSON.parse(read(themePath)) } catch (e) {}
        if (t.base) { base = t.base; ink = t.text; accent = t.accent; gold = t.gold }
        stroke = t.stroke ? "file://" + t.stroke : ""; xia = t.name === "xianxia"
        parse(read(dir + "/list"))
        requestActivate(); field.forceActiveFocus()
    }
    property bool wasActive: false
    onActiveChanged: { if (active) wasActive = true; else if (wasActive) finish(null) }

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: w.a(w.gold, 0.45); radius: w.xia ? 12 : 6 }

    Text { x: 34; y: 34; text: "RECALL"; color: w.gold; font.family: w.face; font.pixelSize: 12; font.letterSpacing: 5 }
    TextInput {
        id: field
        x: 130; y: 26; width: 420; height: 36
        color: w.ink; font.family: w.face; font.pixelSize: 24
        selectionColor: w.a(w.accent, 0.5); selectByMouse: true
        onTextChanged: w.sel = 0
        Text { visible: !field.text; text: "something you kept"; color: w.a(w.ink, 0.38); font: field.font }
        Keys.onEscapePressed: w.finish(null)
        Keys.onDownPressed: w.sel = Math.min(w.shown.length - 1, w.sel + 1)
        Keys.onUpPressed: w.sel = Math.max(0, w.sel - 1)
        Keys.onDeletePressed: function (event) { if (field.text === "") w.forget(w.cur); else event.accepted = false }
        Keys.onReturnPressed: w.finish(w.cur)
        Keys.onEnterPressed: w.finish(w.cur)
    }
    Text { anchors.right: parent.right; anchors.rightMargin: 34; y: 34
           text: w.q === "" ? w.shown.length + " KEPT" : w.shown.length + " FOUND"
           color: w.a(w.gold, 0.7); font.family: w.face; font.pixelSize: 12; font.letterSpacing: 3 }
    Rectangle { x: 30; y: 78; width: parent.width - 60; height: 1; color: w.a(w.gold, 0.35) }

    ListView {
        id: list
        x: 22; y: 92; width: 500; height: 8 * 54
        clip: true
        model: w.shown
        currentIndex: w.sel
        highlightMoveDuration: 180
        highlight: Item { width: list.width; height: 54
            Image { source: w.stroke; width: 470; height: 54; smooth: true; anchors.verticalCenter: parent.verticalCenter; x: -4 } }
        delegate: Item {
            required property var modelData
            required property int index
            readonly property bool on: index === list.currentIndex
            width: list.width; height: 54
            Text { x: 22; anchors.verticalCenter: parent.verticalCenter; text: (index + 1 < 10 ? "0" : "") + (index + 1)
                   color: parent.on ? "#fff8ec" : w.a(w.gold, 0.7); font.family: w.face; font.pixelSize: 12; font.letterSpacing: 2 }
            Image { x: 62; anchors.verticalCenter: parent.verticalCenter; visible: modelData.kind === "image"; source: modelData.file
                    width: 52; height: 34; fillMode: Image.PreserveAspectCrop; sourceSize.width: 160; asynchronous: true }
            Text { x: modelData.kind === "image" ? 128 : 62; width: parent.width - x - 90; anchors.verticalCenter: parent.verticalCenter
                   text: modelData.kind === "image" ? "A picture  " + modelData.text : modelData.text; elide: Text.ElideRight
                   color: parent.on ? "#fff8ec" : w.a(w.ink, 0.75); font.family: w.face; font.pixelSize: 18 }
            Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                   text: modelData.kind.toUpperCase(); color: w.a(w.ink, parent.on ? 0.6 : 0.3)
                   font.family: w.face; font.pixelSize: 10; font.letterSpacing: 3 }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: w.sel = index; onClicked: w.finish(modelData) }
        }
    }
    Text { x: 56; y: 120; visible: w.items.length === 0; text: "Nothing kept yet. Copy something and it waits here."
           color: w.a(w.ink, 0.5); font.family: w.face; font.pixelSize: 17 }

    Rectangle { x: 540; y: 100; width: 1; height: 8 * 54 - 16; color: w.a(w.gold, 0.28) }
    Item {
        x: 570; y: 100; width: parent.width - 570 - 34; height: 8 * 54 - 16
        Text { text: w.cur ? (w.cur.kind === "image" ? "PICTURE   " + w.cur.text.toUpperCase()
                              : (w.cur.kind === "link" ? "LINK" : "WORDS") + "   " + w.full.length + " CHARACTERS") : ""
               color: w.a(w.gold, 0.85); font.family: w.face; font.pixelSize: 11; font.letterSpacing: 4 }
        Image { y: 30; width: parent.width; height: parent.height - 30; visible: !!w.cur && w.cur.kind === "image"
                source: w.cur && w.cur.kind === "image" ? w.cur.file : ""; fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft; verticalAlignment: Image.AlignTop; asynchronous: true; sourceSize.width: 1000 }
        Text { y: 30; width: parent.width; height: parent.height - 30; visible: !!w.cur && w.cur.kind !== "image"
               text: w.full; wrapMode: Text.WrapAnywhere; elide: Text.ElideRight; clip: true; textFormat: Text.PlainText
               color: w.cur && w.cur.kind === "link" ? w.accent : w.a(w.ink, 0.85)
               font.family: w.cur && w.cur.kind === "link" ? w.face : "Inter"; font.pixelSize: 15; lineHeight: 1.25 }
    }

    Rectangle { x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 58; width: parent.width - 60; height: 1; color: w.a(w.gold, 0.2) }
    Text {
        x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        text: "ENTER  to recall      DEL  to forget      ↑ ↓  to choose      ESC  to close"
        color: w.a(w.ink, 0.45); font.family: w.face; font.pixelSize: 12; font.letterSpacing: 2
    }
}
