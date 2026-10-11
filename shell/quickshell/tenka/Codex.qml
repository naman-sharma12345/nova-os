// The Codex (Tianxia: The Scripture): every key this desk answers to, on one flat page. Super + / opens it.
// Not a printed cheat sheet: tenka-codex reads ~/.config/hypr/hyprland.lua (and user.lua) each time the page
// opens, so a rebound key reads as rebound. Type to find a key by its words; ESC clears, then closes.
// The card itself is codex/CodexCard.qml, shared with Tenka Lite.
// qs ipc call codex open|hide|toggle|find <words>|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "codex"

PanelWindow {
    id: cx
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-codex"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "codex"
        function open(): void { cx.reveal() }
        function hide(): void { cx.open = false }
        function toggle(): void { cx.open ? (cx.open = false) : cx.reveal() }
        function find(words: string): void { cx.reveal(); card.query = words }
        function state(): string { return (cx.open ? "open" : "closed") + " session=" + card.g.session + " groups=" + card.g.groups.length
                                          + " shown=" + card.shown + " query=" + card.query }
    }
    GlobalShortcut { appid: "tenka"; name: "codex"; description: "The Codex: every key this desk answers to"
                     onPressed: cx.open ? (cx.open = false) : cx.reveal() }
    onOpenChanged: { Theme.hush = open; if (!open) card.query = "" }

    Process {
        id: readP
        command: ["tenka-codex", "hyprland"]
        stdout: StdioCollector { onStreamFinished: { try { card.g = JSON.parse(text) } catch (e) {} } }
    }
    function reveal() { open = true; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, cx.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: cx.open; onClicked: cx.open = false }

    CodexCard {
        id: card
        width: Math.min(1120, cx.width - 80)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (cx.open ? 0 : 16)
        opacity: cx.open ? 1 : 0
        focus: cx.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia
        onDismissed: cx.open = false
    }
}
