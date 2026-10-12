// Under Heaven (Tianxia: The Four Seas): the hour in the places you keep, Super + U. The card is
// clocks/ClocksCard.qml, shared with Tenka Lite; tenka-clocks keeps the places and works out each one's offset and
// sun on this machine (nothing is fetched). qs ipc call clocks open|hide|toggle|add ZONE|remove ZONE|at EPOCH|state.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "clocks"

PanelWindow {
    id: ck
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-clocks"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "clocks"
        function open(): void { ck.reveal() }
        function hide(): void { ck.open = false }
        function toggle(): void { ck.open ? (ck.open = false) : ck.reveal() }
        function add(zone: string): void { ck.ask(["add", zone]) }
        function remove(zone: string): void { ck.ask(["remove", zone]) }
        function at(epoch: real): void { card.nowOverride = epoch * 1000 }      // renders: a fixed moment
        function query(words: string): void { card.beginAdd(); card.typed(words) }
        function state(): string { return (ck.open ? "open" : "closed") + " places=" + card.rows.map(r => r.name + "@" + card.hm(card.mins(r))).join(",") }
    }
    GlobalShortcut { appid: "tenka"; name: "clocks"; description: "Under heaven: the hour in the places you keep"
                     onPressed: ck.open ? (ck.open = false) : ck.reveal() }

    Process {
        id: readP
        command: ["tenka-clocks", "state"]
        stdout: StdioCollector { onStreamFinished: { try { card.s = JSON.parse(text) } catch (e) {} } }
    }
    Process {
        id: zonesP
        command: ["tenka-clocks", "zones"]
        stdout: StdioCollector { onStreamFinished: { try { card.zones = JSON.parse(text) } catch (e) {} } }
    }
    Process { id: askP; onExited: { readP.running = false; readP.running = true } }
    function ask(a) { askP.command = ["tenka-clocks"].concat(a); askP.running = true }
    function reveal() { open = true; readP.running = true; if (!card.zones.length) zonesP.running = true; card.forceActiveFocus() }
    Timer { interval: 600000; repeat: true; running: ck.open; onTriggered: { readP.running = false; readP.running = true } }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, ck.open ? 0.45 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 260 } } }
    MouseArea { anchors.fill: parent; enabled: ck.open; onClicked: ck.open = false }

    ClocksCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.4) + (ck.open ? 0 : 16)
        opacity: ck.open ? 1 : 0
        focus: ck.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; xia: Theme.xia
        onDismissed: ck.open = false
        onAddAsked: z => ck.ask(["add", z])
        onRemoveAsked: z => ck.ask(["remove", z])
    }
}
