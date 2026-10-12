// The Breath (Tianxia: Gathering Qi): a breathing guide drawn as an enso, Super + O. The brush draws the circle as
// you breathe in, it rests while you hold, the ink dries as you breathe out; a sitting ends on the theme's soft bell.
// The card is breath/BreathCard.qml, shared with Tenka Lite; tenka-breath keeps the pace, the length and today's
// sittings. Closing the card ends the sitting. qs ipc call breath open|hide|toggle|begin|stop|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "breath"

PanelWindow {
    id: br
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-breath"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "breath"
        function open(): void { br.reveal() }
        function hide(): void { br.shut() }
        function toggle(): void { br.open ? br.shut() : br.reveal() }
        function begin(): void { br.reveal(); card.begin() }
        function stop(): void { card.stop() }
        function seek(seconds: real): void { card.seek(seconds) }
        function state(): string { return (br.open ? "open" : "closed") + " running=" + card.running + " pace=" + card.pace + " minutes=" + card.minutes
                                          + " phase=" + card.at.i + " round=" + card.round + "/" + card.rounds + " kept=" + card.kept + " sittings=" + (card.s.sittings || 0) }
    }
    GlobalShortcut { appid: "tenka"; name: "breath"; description: "The breath: a breathing guide drawn as an enso"
                     onPressed: br.open ? br.shut() : br.reveal() }
    onOpenChanged: Theme.hush = open

    Process {
        id: readP
        command: ["tenka-breath", "state"]
        stdout: StdioCollector { onStreamFinished: { try { card.s = JSON.parse(text) } catch (e) {} } }
    }
    Process { id: askP }
    function ask(a) { askP.command = ["tenka-breath"].concat(a); askP.running = true }
    function reveal() { open = true; if (!card.running) readP.running = true; card.forceActiveFocus() }
    function shut() { card.stop(); open = false }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, br.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 260 } } }
    MouseArea { anchors.fill: parent; enabled: br.open; onClicked: br.shut() }

    BreathCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (br.open ? 0 : 16)
        opacity: br.open ? 1 : 0
        focus: br.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia
        onDismissed: br.shut()
        onSetAsked: (p, m) => br.ask(["set", p, String(m)])
        onDoneAsked: m => br.ask(["done", String(m)])
    }
}
