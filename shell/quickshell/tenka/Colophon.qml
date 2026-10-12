// The Colophon (Tianxia: The Lineage): our own "about this computer", on one flat card. Opened from the
// Control Center's TOOLS box, the launcher ("about") or `tenka-colophon open`. tenka-colophon reads the machine
// each time the card opens, so nothing is cached. The card itself is colophon/ColophonCard.qml, shared with Lite.
// qs ipc call colophon open|hide|toggle|copy|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "colophon"

PanelWindow {
    id: co
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-colophon"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "colophon"
        function open(): void { co.reveal() }
        function hide(): void { co.open = false }
        function toggle(): void { co.open ? (co.open = false) : co.reveal() }
        function copy(): void { card.copy() }
        function state(): string { return (co.open ? "open" : "closed") + " rows=" + card.d.rows.length + " name=" + card.d.name
                                          + " copied=" + card.copied }
    }
    onOpenChanged: Theme.hush = open

    Process {
        id: readP
        command: ["tenka-colophon", "hyprland"]
        stdout: StdioCollector { onStreamFinished: { try { card.d = JSON.parse(text) } catch (e) {} } }
    }
    Process { id: copyP; command: ["tenka-colophon", "copy", "hyprland"] }
    function reveal() { open = true; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, co.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: Theme.ms(220) } } }
    MouseArea { anchors.fill: parent; enabled: co.open; onClicked: co.open = false }

    ColophonCard {
        id: card
        width: Math.min(900, co.width - 80)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (co.open ? 0 : 16)
        opacity: co.open ? 1 : 0
        focus: co.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; brand: Theme.brand; xia: Theme.xia
        onDismissed: co.open = false
        onCopyAsked: copyP.running = true
    }
}
