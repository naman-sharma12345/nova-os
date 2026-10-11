// The Loupe (Tianxia: The Mirror): our own colour picker and screen ruler, flat like The Air and The Lantern.
// Super+Shift+C freezes the screen (tenka-loupe shot, a private file) and lays it under a still pane, so every
// reading is the true pixel. A small flat card follows the pointer: the pixels around it enlarged with the one
// beneath marked in gold, the colour as HEX, RGB and HSL, and where it sits. Click copies the colour in the
// chosen format (TAB changes it); a drag measures instead, W x H in screen pixels, and copies "W×H". ← → ↑ ↓
// nudge one pixel (SHIFT ten), ENTER copies and closes, ESC closes. Picked colours wait in LATELY along the
// foot; a click on one copies it again. qs ipc call loupe open|hide|toggle|state|point X Y. Flat, no glow.
// The view itself (reading, enlarging, measuring, the keys) is loupe/LoupeView.qml, shared with Tenka Lite.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "loupe"

PanelWindow {
    id: lw
    property bool open: false

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-loupe"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "loupe"
        function open(): void { lw.reveal() }
        function hide(): void { lw.open = false }
        function toggle(): void { lw.open ? (lw.open = false) : lw.reveal() }
        function point(x: int, y: int): void { lp.pointAt(x, y) }
        function measure(x1: int, y1: int, x2: int, y2: int): void { lp.from = Qt.point(x1, y1); lp.to = Qt.point(x2, y2); lp.dragging = true; lp.pointAt(x2, y2) }
        function state(): string { return (lw.open ? "open" : "closed") + " at=" + Math.round(lp.px) + "," + Math.round(lp.py) + " hex=" + lp.hex
                                          + " hsl=" + lp.hsl.join(",") + " lately=" + lp.lately.length + (lp.dragging ? " measure=" + lp.mw + "x" + lp.mh : "") }
    }
    GlobalShortcut { appid: "tenka"; name: "loupe"; description: "The Loupe: pick a colour, measure the screen"
                     onPressed: lw.open ? (lw.open = false) : lw.reveal() }
    onOpenChanged: { Theme.hush = open; if (!open) lp.release() }

    Process {
        id: shotP
        command: ["tenka-loupe", "shot", lw.screen ? lw.screen.name : ""]
        stdout: StdioCollector { onStreamFinished: {
            const f = text.trim()
            if (f === "") { lw.open = false; return }
            lp.shot = ""; lp.shot = "file://" + f
            lw.open = true; lp.focusPane()
        } }
    }
    Process { id: lateP; command: ["tenka-loupe", "lately"]
              stdout: StdioCollector { onStreamFinished: { try { lp.lately = JSON.parse(text) } catch (e) {} } } }
    Process { id: copyP; property string t: ""; command: ["tenka-loupe", "copy", t]; onExited: lateP.running = true }

    function reveal() { if (!shotP.running) { lateP.running = true; shotP.running = true } }

    LoupeView {
        id: lp
        anchors.fill: parent
        open: lw.open
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold
        radius: Theme.ledgerR; face: Theme.display; xia: Theme.xia
        onCopyRequested: t => { copyP.t = t; copyP.running = true }
        onCloseRequested: lw.open = false
    }
}
