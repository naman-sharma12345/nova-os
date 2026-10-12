// The Incense (Tianxia: The Joss Stick): our own timer, Super + I. A stick burns down in its censer; when it is
// gone, the theme's soft bell and one note (tenka-incense keeps the time, so closing this card or restarting the
// shell does not put it out). The card is incense/IncenseCard.qml, shared with Tenka Lite.
// qs ipc call incense open|hide|toggle|light <min>|out|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "incense"

PanelWindow {
    id: ic
    property bool open: false
    property string lastState: ""

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-incense"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "incense"
        function open(): void { ic.reveal() }
        function hide(): void { ic.open = false }
        function toggle(): void { ic.open ? (ic.open = false) : ic.reveal() }
        function light(minutes: int): void { ic.ask(["light", String(minutes)]) }
        function out(): void { ic.ask(["out"]) }
        function garden(name: string): void { ic.ask(["garden", name]) }
        function state(): string { return (ic.open ? "open" : "closed") + " burning=" + card.burning + " left=" + Math.round(card.remain / 1000)
                                          + " minutes=" + card.s.minutes + " choice=" + card.choice }
    }
    GlobalShortcut { appid: "tenka"; name: "incense"; description: "The incense: a timer that burns down"
                     onPressed: ic.open ? (ic.open = false) : ic.reveal() }
    onOpenChanged: Theme.hush = open

    Process {
        id: readP
        command: ["tenka-incense", "state"]
        // only on a change: a new `s` resets the card's choice to the stored length, which would undo a key
        stdout: StdioCollector { onStreamFinished: { const k = text.trim(); const key = k.replace(/"left": *\d+, */, "")
                                                     if (key === ic.lastState) return
                                                     try { card.s = JSON.parse(k); ic.lastState = key } catch (e) {} } }
    }
    Process { id: askP; onExited: readP.running = true }
    function ask(a) { askP.command = ["tenka-incense"].concat(a); askP.running = true }
    function reveal() { open = true; readP.running = true; card.forceActiveFocus() }
    Timer { interval: 5000; repeat: true; running: ic.open; onTriggered: readP.running = true }   // a bell rung while open

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, ic.open ? 0.45 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: ic.open; onClicked: ic.open = false }

    IncenseCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (ic.open ? 0 : 16)
        opacity: ic.open ? 1 : 0
        focus: ic.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia
        onDismissed: ic.open = false
        onLightAsked: m => ic.ask(["light", String(m)])
        onOutAsked: ic.ask(["out"])
        onGardenAsked: n => ic.ask(["garden", n || "off"])
    }
}
