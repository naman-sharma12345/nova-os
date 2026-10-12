// Moon Viewing (Tianxia: The Moon Palace): tonight's moon, Super + M. The card is moon/MoonCard.qml, shared with
// Tenka Lite; tenka-moon works out the phase, the old lunar night, moonrise and moonset on this machine (nothing is
// fetched). qs ipc call moon open|hide|toggle|at DATE|state (DATE as YYYY-MM-DD or YYYY-MM-DDTHH:MM, for renders).
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "moon"

PanelWindow {
    id: mo
    property bool open: false
    property string at: ""

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-moon"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "moon"
        function open(): void { mo.reveal() }
        function hide(): void { mo.open = false }
        function toggle(): void { mo.open ? (mo.open = false) : mo.reveal() }
        function at(date: string): void { mo.at = date; readP.running = false; readP.running = true }
        function state(): string { return (mo.open ? "open" : "closed") + " day=" + card.s.day + " night=" + card.s.night + " rise=" + card.s.rise + " set=" + card.s.set }
    }
    GlobalShortcut { appid: "tenka"; name: "moon"; description: "Moon viewing: tonight's moon"
                     onPressed: mo.open ? (mo.open = false) : mo.reveal() }

    Process {
        id: readP
        command: ["tenka-moon", "state"].concat(mo.at ? [mo.at] : [])
        stdout: StdioCollector { onStreamFinished: { try { card.s = JSON.parse(text) } catch (e) {} } }
    }
    function reveal() { open = true; readP.running = false; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, mo.open ? 0.5 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 260 } } }
    MouseArea { anchors.fill: parent; enabled: mo.open; onClicked: mo.open = false }

    MoonCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (mo.open ? 0 : 16)
        opacity: mo.open ? 1 : 0
        focus: mo.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; xia: Theme.xia
        onDismissed: mo.open = false
    }
}
