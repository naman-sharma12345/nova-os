// The Inkstone (Tianxia: The Brush): our own glyph picker, Super+. , the thing Linux desktops lack and other
// systems keep behind a key: every emoji, the marks (arrows, maths, money, typographer's signs) and the ink
// shelf (CJK punctuation and a few seal characters with their readings), found by name as you type. One flat
// ledger card: shelves in small caps, a quiet grid, the chosen glyph large with its name in Marcellus. ENTER
// places it in the window behind (and on the clipboard), TAB walks the shelves, ESC closes. The shelves come
// from tenka-glyphs (Unicode's own names); the last thirty placed sit on LATELY.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "inkstone"

PanelWindow {
    id: ink
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-inkstone"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "glyphs"
        function open(): void { ink.reveal() }
        function hide(): void { ink.open = false }
        function toggle(): void { ink.open ? (ink.open = false) : ink.reveal() }
        function state(): string { return (ink.open ? "open" : "closed") + " glyphs=" + card.all.length + " shelf=" + card.shelves[card.shelf]
                                          + " shown=" + card.shown.length + (card.cur ? " sel=" + card.cur.n : "") }
    }
    GlobalShortcut { appid: "tenka"; name: "glyphs"; description: "The Inkstone: find and place a glyph"
                     onPressed: ink.open ? (ink.open = false) : ink.reveal() }
    onOpenChanged: Theme.hush = open

    Process {
        id: listP
        command: ["tenka-glyphs", "list"]
        stdout: StdioCollector { onStreamFinished: {
            try { card.load(JSON.parse(text), Quickshell.env("TENKA_GLYPH_SIM_SHELF"), Quickshell.env("TENKA_GLYPH_SIM_SEL")) } catch (e) {}
        } }
    }
    Process { id: placeP; property string g: ""; command: ["tenka-glyphs", "place", g] }

    function reveal() {
        card.reset(Quickshell.env("TENKA_GLYPH_SIM_QUERY") || "")
        open = true; listP.running = true
        card.focusField()
    }

    // the desk steps back: one flat wash
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, ink.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: ink.open; onClicked: ink.open = false }

    InkCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, parent.height * 0.18) + (ink.open ? 0 : 16)
        opacity: ink.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia; motion: !Theme.perf
        onPlaced: g => { placeP.g = g; ink.open = false; placeP.running = true }
        onDismissed: ink.open = false
    }
}
