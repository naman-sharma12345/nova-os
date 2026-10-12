// The Season's Poem (Tianxia: The Verse of the Season): one classic poem for each solar term, Super + Y. The card is
// poem/PoemCard.qml, shared with Tenka Lite; tenka-poem picks the poem for the term on this machine (nothing is
// fetched). qs ipc call poem open|hide|toggle|at DATE|state (DATE as YYYY-MM-DD, for renders).
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "poem"

PanelWindow {
    id: po
    property bool open: false
    property string at: ""

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-poem"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "poem"
        function open(): void { po.reveal() }
        function hide(): void { po.open = false }
        function toggle(): void { po.open ? (po.open = false) : po.reveal() }
        function at(date: string): void { po.at = date; readP.running = false; readP.running = true }
        function state(): string { return (po.open ? "open" : "closed") + " term=" + card.s.term + " poet=" + card.s.poet }
    }
    GlobalShortcut { appid: "tenka"; name: "poem"; description: "The season's poem"
                     onPressed: po.open ? (po.open = false) : po.reveal() }

    Process {
        id: readP
        command: ["tenka-poem", "state"].concat(po.at ? [po.at] : [])
        stdout: StdioCollector { onStreamFinished: { try { card.s = JSON.parse(text) } catch (e) {} } }
    }
    function reveal() { open = true; readP.running = false; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, po.open ? 0.5 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: Theme.ms(260) } } }
    MouseArea { anchors.fill: parent; enabled: po.open; onClicked: po.open = false }

    PoemCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (po.open ? 0 : 16)
        opacity: po.open ? 1 : 0
        focus: po.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; xia: Theme.xia
        onDismissed: po.open = false
    }
}
