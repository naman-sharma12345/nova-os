// The Almanac (Tianxia: The Heavenly Calendar) as a card: the wheel of the year and the moon. Opened from the
// desk's MONTH row, the menu ("The Almanac"), or `tenka-almanac open`. The card is almanac/AlmanacCard.qml,
// shared with Tenka Lite. qs ipc call almanac open|hide|toggle|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "almanac"

PanelWindow {
    id: am
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-almanac"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "almanac"
        function open(): void { am.reveal() }
        function hide(): void { am.open = false }
        function toggle(): void { am.open ? (am.open = false) : am.reveal() }
        function state(): string { return (am.open ? "open" : "closed") + (card.d ? " term=" + card.d.term + " moon=" + card.d.moon.phase : "") }
    }
    onOpenChanged: Theme.hush = open

    Process {
        id: readP
        command: ["tenka-almanac", "wheel"]
        stdout: StdioCollector { onStreamFinished: { try { card.d = JSON.parse(text) } catch (e) {} } }
    }
    function reveal() { open = true; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, am.open ? 0.45 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: Theme.ms(220) } } }
    MouseArea { anchors.fill: parent; enabled: am.open; onClicked: am.open = false }

    AlmanacCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (am.open ? 0 : 16)
        opacity: am.open ? 1 : 0
        focus: am.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia
        onDismissed: am.open = false
    }
}
