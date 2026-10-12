// The Pillow Book (Tianxia: The Jade Record): a few lines a day, Super + K. Today's page under the day's season,
// the earlier days down the side, a year ago today when it was written. tenka-journal keeps the pages as plain
// text in ~/.local/share/tenka/journal (one file a day); the card is journal/JournalCard.qml, shared with Tenka
// Lite. qs ipc call journal open|hide|toggle|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "journal"

PanelWindow {
    id: jr
    property bool open: false
    property var pending: null

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-journal"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "journal"
        function open(): void { jr.reveal() }
        function hide(): void { jr.shut() }
        function toggle(): void { jr.open ? jr.shut() : jr.reveal() }
        function state(): string { return (jr.open ? "open" : "closed") + " sel=" + card.sel + " dirty=" + card.dirty + " chars=" + card.s.text.length + " days=" + card.days.length }
    }
    GlobalShortcut { appid: "tenka"; name: "journal"; description: "The pillow book: a few lines a day"
                     onPressed: jr.open ? jr.shut() : jr.reveal() }
    onOpenChanged: Theme.hush = open

    Process {
        id: readP
        command: ["tenka-journal", "state"]
        stdout: StdioCollector { onStreamFinished: { try { card.s = JSON.parse(text); if (jr.open && !card.dirty) card.begin() } catch (e) {} } }
    }
    // one writer at a time: a page asked for while one is being written waits for it
    Process { id: putP; onExited: if (jr.pending !== null) { const p = jr.pending; jr.pending = null; jr.save(p) } }
    function save(p) {
        if (putP.running) { pending = p; return }
        putP.command = ["tenka-journal", "put", "--", p.length ? p : ""]; putP.running = true
    }
    function reveal() { open = true; card.begin(); readP.running = true }
    function shut() { card.keep(); open = false }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, jr.open ? 0.45 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: jr.open; onClicked: jr.shut() }

    JournalCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.40) + (jr.open ? 0 : 16)
        opacity: jr.open ? 1 : 0
        focus: jr.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia
        onDismissed: jr.open = false
        onSaveAsked: p => jr.save(p)
    }
}
