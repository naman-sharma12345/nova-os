// The Garden (Tianxia: The Mountain Hall): sounds to work or rest by, Super + G. Rain, a stream, pines, embers,
// made by Tenka itself and looping without a seam; tenka-ambience plays them (closing this card or restarting the
// shell does not stop the sound). The card is garden/GardenCard.qml, shared with Tenka Lite.
// qs ipc call garden open|hide|toggle|play <name>|stop|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "garden"

PanelWindow {
    id: gd
    property bool open: false
    property string lastState: ""

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-garden"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "garden"
        function open(): void { gd.reveal() }
        function hide(): void { gd.open = false }
        function toggle(): void { gd.open ? (gd.open = false) : gd.reveal() }
        function play(name: string): void { gd.ask(["play", name]) }
        function stop(): void { gd.ask(["stop"]) }
        function state(): string { return (gd.open ? "open" : "closed") + " playing=" + card.s.playing + " name=" + card.s.name + " volume=" + card.s.volume }
    }
    GlobalShortcut { appid: "tenka"; name: "garden"; description: "The garden: rain, a stream, pines, embers"
                     onPressed: gd.open ? (gd.open = false) : gd.reveal() }
    onOpenChanged: Theme.hush = open

    Process {
        id: readP
        command: ["tenka-ambience", "state"]
        // only on a change: a new `s` resets the card's choice
        stdout: StdioCollector { onStreamFinished: { const k = text.trim(); if (k === gd.lastState) return
                                                     try { card.s = JSON.parse(k); gd.lastState = k } catch (e) {} } }
    }
    Process { id: askP; onExited: readP.running = true }
    function ask(a) { askP.command = ["tenka-ambience"].concat(a); askP.running = true }
    function reveal() { open = true; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, gd.open ? 0.45 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: gd.open; onClicked: gd.open = false }

    GardenCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (gd.open ? 0 : 16)
        opacity: gd.open ? 1 : 0
        focus: gd.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia
        onDismissed: gd.open = false
        onPlayAsked: n => gd.ask(["play", n])
        onStopAsked: gd.ask(["stop"])
        onVolumeAsked: v => gd.ask(["volume", String(v)])
    }
}
