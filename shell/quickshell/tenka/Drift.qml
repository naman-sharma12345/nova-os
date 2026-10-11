// The Drift (Tianxia: The Falling Blossoms): our own idle screen. Hyprland has no screensaver at all; after
// three idle minutes hypridle shows this (two minutes before the lock): the desk's picture breathing, the
// season falling across it and the hour. Any key, touch or pointer move ends it (hypridle's on-resume, and the
// pointer here). The view is drift/DriftView.qml, shared with Tenka Lite.
// qs ipc call drift open|hide|toggle|state ("show" is a word of qs ipc itself, so the call is open). Flat, no glow; performance mode keeps it still.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "drift"

PanelWindow {
    id: dr
    property bool on: false
    property point first: Qt.point(-1, -1)

    visible: on || view.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-drift"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    IpcHandler {
        target: "drift"
        function open(): void { dr.first = Qt.point(-1, -1); dr.on = true }
        function hide(): void { dr.on = false }
        function toggle(): void { dr.on ? (dr.on = false) : open() }
        function state(): string { return (dr.on ? "on" : "off") + " season=" + view.season + " leaves=" + view.count + " still=" + view.still }
    }
    onOnChanged: Theme.hush = on

    DriftView {
        id: view
        anchors.fill: parent
        opacity: dr.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: dr.on ? 1800 : 350; easing.type: Easing.InOutQuad } }
        wallpaper: Theme.t.wallpaper; base: Theme.t.base; text: Theme.t.text; gold: Theme.gold
        fall: Theme.seasonLight[Theme.season] || Theme.gold; season: Theme.season
        face: Theme.display; proverb: Theme.proverb; xia: Theme.xia; still: Theme.perf
    }
    // a real move of the pointer wakes the desk (a few pixels of jitter do not)
    MouseArea {
        anchors.fill: parent; enabled: dr.on; hoverEnabled: true
        onPositionChanged: m => {
            if (dr.first.x < 0) { dr.first = Qt.point(m.x, m.y); return }
            if (Math.abs(m.x - dr.first.x) + Math.abs(m.y - dr.first.y) > 24) dr.on = false
        }
        onPressed: dr.on = false
        onWheel: dr.on = false
    }
}
