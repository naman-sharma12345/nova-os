// The Loupe (Tianxia: The Mirror): our own colour picker and screen ruler, flat like The Air and The Lantern.
// Super+Shift+C freezes the screen (tenka-loupe shot, a private file) and lays it under a still pane, so every
// reading is the true pixel. A small flat card follows the pointer: the pixels around it enlarged with the one
// beneath marked in gold, the colour as HEX, RGB and HSL, and where it sits. Click copies the colour in the
// chosen format (TAB changes it); a drag measures instead, W x H in screen pixels, and copies "W×H". ← → ↑ ↓
// nudge one pixel (SHIFT ten), ENTER copies and closes, ESC closes. Picked colours wait in LATELY along the
// foot; a click on one copies it again. qs ipc call loupe open|hide|toggle|state|point X Y. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: lp
    property bool open: false
    property string shot: ""                 // file:// of the frozen screen
    property real px: 0                      // the pixel read, in the shot's own pixels
    property real py: 0
    property var rgb: [0, 0, 0]
    property int fmt: 0                      // 0 HEX, 1 RGB, 2 HSL: what a click copies
    property var lately: []
    property string note: ""
    property bool dragging: false
    property point from: Qt.point(0, 0)      // a measure's first corner, in window coordinates
    property point to: Qt.point(0, 0)
    readonly property real k: shotImg.sourceSize.width > 0 ? shotImg.sourceSize.width / width : 1
    readonly property string hex: "#" + rgb.map(v => (v < 16 ? "0" : "") + v.toString(16)).join("")
    readonly property var hsl: {
        const r = rgb[0] / 255, g = rgb[1] / 255, b = rgb[2] / 255
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn
        let h = 0, s = 0
        if (d > 0) {
            s = d / (1 - Math.abs(2 * l - 1))
            h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4
            h = Math.round(h * 60); if (h < 0) h += 360
        }
        return [h, Math.round(s * 100), Math.round(l * 100)]
    }
    readonly property var words: [hex.toUpperCase(), "rgb(" + rgb.join(", ") + ")", "hsl(" + hsl[0] + ", " + hsl[1] + "%, " + hsl[2] + "%)"]
    readonly property int mw: Math.round(Math.abs(to.x - from.x) * k)
    readonly property int mh: Math.round(Math.abs(to.y - from.y) * k)

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-loupe"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "loupe"
        function open(): void { lp.reveal() }
        function hide(): void { lp.open = false }
        function toggle(): void { lp.open ? (lp.open = false) : lp.reveal() }
        function point(x: int, y: int): void { lp.pointAt(x, y) }
        function measure(x1: int, y1: int, x2: int, y2: int): void { lp.from = Qt.point(x1, y1); lp.to = Qt.point(x2, y2); lp.dragging = true; lp.pointAt(x2, y2) }
        function state(): string { return (lp.open ? "open" : "closed") + " at=" + Math.round(lp.px) + "," + Math.round(lp.py) + " hex=" + lp.hex
                                          + " hsl=" + lp.hsl.join(",") + " lately=" + lp.lately.length + (lp.dragging ? " measure=" + lp.mw + "x" + lp.mh : "") }
    }
    GlobalShortcut { appid: "tenka"; name: "loupe"; description: "The Loupe: pick a colour, measure the screen"
                     onPressed: lp.open ? (lp.open = false) : lp.reveal() }
    onOpenChanged: { Theme.hush = open; if (!open) { if (shot !== "") reader.unloadImage(shot); shot = ""; dragging = false; note = "" } }

    Process {
        id: shotP
        command: ["tenka-loupe", "shot", lp.screen ? lp.screen.name : ""]
        stdout: StdioCollector { onStreamFinished: {
            const f = text.trim()
            if (f === "") { lp.open = false; return }
            lp.shot = ""; lp.shot = "file://" + f
            lp.open = true; pane.forceActiveFocus()
        } }
    }
    Process { id: lateP; command: ["tenka-loupe", "lately"]
              stdout: StdioCollector { onStreamFinished: { try { lp.lately = JSON.parse(text) } catch (e) {} } } }
    Process { id: copyP; property string t: ""; command: ["tenka-loupe", "copy", t]; onExited: lateP.running = true }

    function reveal() { if (!shotP.running) { lateP.running = true; shotP.running = true } }
    function pointAt(x, y) {     // window coordinates
        px = Math.max(0, Math.min(shotImg.sourceSize.width - 1, Math.floor(x * k)))
        py = Math.max(0, Math.min(shotImg.sourceSize.height - 1, Math.floor(y * k)))
        reader.requestPaint()
    }
    function copy(t, word) { copyP.t = t; copyP.running = true; note = "COPIED  " + (word || t) }

    // the frozen screen, exactly as it was
    Image { id: shotImg; anchors.fill: parent; source: lp.shot; cache: false; smooth: false; fillMode: Image.Stretch
            onStatusChanged: if (status === Image.Ready) { reader.loadImage(source); lp.pointAt(lp.width / 2, lp.height / 2) } }

    // one pixel read through a 1x1 canvas
    Canvas {
        id: reader
        width: 1; height: 1; visible: false
        onImageLoaded: requestPaint()
        onPaint: {
            if (lp.shot === "" || !isImageLoaded(lp.shot)) return
            const c = getContext("2d")
            c.clearRect(0, 0, 1, 1)
            c.drawImage(lp.shot, lp.px, lp.py, 1, 1, 0, 0, 1, 1)
            const d = c.getImageData(0, 0, 1, 1).data
            lp.rgb = [d[0], d[1], d[2]]
        }
    }

    Item {
        id: pane
        anchors.fill: parent
        focus: lp.open
        Keys.onPressed: e => {
            const n = (e.modifiers & Qt.ShiftModifier) ? 10 : 1
            if (e.key === Qt.Key_Escape) lp.open = false
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { lp.copy(lp.words[lp.fmt]); lp.open = false }
            else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) lp.fmt = (lp.fmt + 1) % 3
            else if (e.key === Qt.Key_Left) lp.pointAt((lp.px - n + 0.5) / lp.k, (lp.py + 0.5) / lp.k)
            else if (e.key === Qt.Key_Right) lp.pointAt((lp.px + n + 0.5) / lp.k, (lp.py + 0.5) / lp.k)
            else if (e.key === Qt.Key_Up) lp.pointAt((lp.px + 0.5) / lp.k, (lp.py - n + 0.5) / lp.k)
            else if (e.key === Qt.Key_Down) lp.pointAt((lp.px + 0.5) / lp.k, (lp.py + n + 0.5) / lp.k)
            else return
            e.accepted = true
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.CrossCursor
            property point down: Qt.point(0, 0)
            onPositionChanged: m => {
                lp.pointAt(m.x, m.y)
                if (pressed && (Math.abs(m.x - down.x) > 3 || Math.abs(m.y - down.y) > 3)) { lp.dragging = true; lp.to = Qt.point(m.x, m.y) }
            }
            onPressed: m => { down = Qt.point(m.x, m.y); lp.from = down; lp.to = down; lp.dragging = false; lp.note = "" }
            onReleased: m => {
                if (lp.dragging) lp.copy(lp.mw + "×" + lp.mh, lp.mw + " × " + lp.mh + " PX")
                else lp.copy(lp.words[lp.fmt])
            }
        }
    }

    // the measure: a hairline box, its size beside it
    Rectangle {
        visible: lp.dragging
        x: Math.min(lp.from.x, lp.to.x); y: Math.min(lp.from.y, lp.to.y)
        width: Math.abs(lp.to.x - lp.from.x); height: Math.abs(lp.to.y - lp.from.y)
        color: Theme.alpha(Theme.gold, 0.08); border.width: 1; border.color: Theme.gold
        Rectangle {
            x: parent.width / 2 - width / 2; y: parent.height + 8
            width: mText.width + 20; height: 24; radius: 2; color: Theme.alpha(Theme.t.base, 0.92)
            Text { id: mText; anchors.centerIn: parent; text: lp.mw + "  ×  " + lp.mh; color: Theme.gold
                   font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 2 }
        }
    }

    // the card that follows: the enlarged pixels, the colour in three words
    Item {
        id: card
        readonly property real cx: lp.px / lp.k
        readonly property real cy: lp.py / lp.k
        width: 236; height: 352
        x: cx + 28 + width > lp.width ? cx - 28 - width : cx + 28
        y: Math.max(16, Math.min(lp.height - height - 150, cy + 28 + height > lp.height - 150 ? cy - 28 - height : cy + 28))   // clear of the foot
        visible: lp.open && shotImg.status === Image.Ready
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, 0.96)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.4) }
        Text { x: 18; y: 16; text: Theme.xia ? "THE MIRROR" : "THE LOUPE"; color: Theme.gold; font.family: Theme.display
               font.pixelSize: 11; font.letterSpacing: 4 }
        Item {   // 15 x 15 pixels at twelve times, the read one outlined
            id: zoom
            readonly property int zm: 12
            x: 18; y: 40; width: 200; height: 180; clip: true
            Image { source: lp.shot; smooth: false; cache: false
                    width: shotImg.sourceSize.width * zoom.zm; height: shotImg.sourceSize.height * zoom.zm
                    x: zoom.width / 2 - (lp.px + 0.5) * zoom.zm; y: zoom.height / 2 - (lp.py + 0.5) * zoom.zm }
            Rectangle { x: zoom.width / 2 - zoom.zm / 2 - 1; y: zoom.height / 2 - zoom.zm / 2 - 1; width: zoom.zm + 2; height: zoom.zm + 2
                        color: "transparent"; border.width: 1; border.color: Theme.gold }
            Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.12) }
        }
        Rectangle { x: 18; y: 234; width: 36; height: 36; radius: 2; color: Qt.rgba(lp.rgb[0] / 255, lp.rgb[1] / 255, lp.rgb[2] / 255, 1)
                    border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.25) }
        Text { x: 66; y: 236; text: lp.words[0]; color: lp.fmt === 0 ? Theme.gold : Theme.t.text; font.family: Theme.display
               font.pixelSize: 22; font.letterSpacing: 1 }
        Text { x: 66; y: 262; text: "x " + Math.round(lp.px) + "   y " + Math.round(lp.py); color: Theme.alpha(Theme.t.text, 0.5)
               font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 1 }
        Rectangle { x: 18; y: 282; width: parent.width - 36; height: 1; color: Theme.alpha(Theme.gold, 0.3) }
        Column {
            x: 18; y: 290; spacing: 2
            Repeater {
                model: [["RGB", lp.rgb.join("  ")], ["HSL", lp.hsl[0] + "°  " + lp.hsl[1] + "%  " + lp.hsl[2] + "%"]]
                Row {
                    required property var modelData
                    required property int index
                    spacing: 12
                    Text { width: 34; text: parent.modelData[0]; color: lp.fmt === parent.index + 1 ? Theme.gold : Theme.alpha(Theme.gold, 0.6)
                           font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: parent.modelData[1]; color: lp.fmt === parent.index + 1 ? Theme.gold : Theme.t.text
                           font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 1 }
                }
            }
        }
    }

    // the foot: what was copied, LATELY, and the keys
    Rectangle {
        visible: lp.open
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 36
        width: Math.max(560, foot.width + 48); height: 96; radius: Theme.ledgerR
        color: Theme.alpha(Theme.t.base, 0.94); border.width: 1; border.color: Theme.alpha(Theme.gold, 0.35)
        Column {
            id: foot
            anchors.centerIn: parent; spacing: 12
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                Text { text: lp.note !== "" ? lp.note : "LATELY"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 10
                       font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter; width: lp.note !== "" ? implicitWidth : 70 }
                Repeater {
                    model: lp.note !== "" ? [] : lp.lately.slice(0, 10)
                    Rectangle {
                        required property string modelData
                        width: 22; height: 22; radius: 2; color: modelData
                        border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.25)
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: lp.copy(parent.modelData.toUpperCase()) }
                    }
                }
                Text { visible: lp.note === "" && lp.lately.length === 0; text: "nothing picked yet"; color: Theme.alpha(Theme.t.text, 0.45)
                       font.family: Theme.display; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "CLICK  copy      DRAG  measure      TAB  " + ["hex", "rgb", "hsl"][lp.fmt] + "      ← → ↑ ↓  nudge      ESC  close"
                color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
            }
        }
    }
}
