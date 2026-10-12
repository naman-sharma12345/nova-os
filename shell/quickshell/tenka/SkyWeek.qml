// Seven Skies (Tianxia: The Heavens Ahead): the coming week's weather, Super + H. The card is skyweek/SkyWeekCard.qml,
// shared with Tenka Lite; tenka-sky keeps the week from the same request the desk's sky already makes (off with
// `tenka-sky off`). qs ipc call skyweek open|hide|toggle|state.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "skyweek"

PanelWindow {
    id: sw
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-skyweek"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "skyweek"
        function open(): void { sw.reveal() }
        function hide(): void { sw.open = false }
        function toggle(): void { sw.open ? (sw.open = false) : sw.reveal() }
        function state(): string { return (sw.open ? "open" : "closed") + " days=" + card.days.length + " " + card.days.map(d => d.word + " " + d.lo + "-" + d.hi).join("; ") }
    }
    GlobalShortcut { appid: "tenka"; name: "skyweek"; description: "Seven skies: the coming week's weather"
                     onPressed: sw.open ? (sw.open = false) : sw.reveal() }

    Process {
        id: readP
        command: ["tenka-sky", "week"]
        stdout: StdioCollector { onStreamFinished: { try { card.s = JSON.parse(text) } catch (e) {} } }
    }
    function reveal() { open = true; readP.running = false; readP.running = true; card.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, sw.open ? 0.5 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: Theme.ms(260) } } }
    MouseArea { anchors.fill: parent; enabled: sw.open; onClicked: sw.open = false }

    SkyWeekCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (parent.height - height) * 0.42) + (sw.open ? 0 : 16)
        opacity: sw.open ? 1 : 0
        focus: sw.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; xia: Theme.xia
        onDismissed: sw.open = false
    }
}
