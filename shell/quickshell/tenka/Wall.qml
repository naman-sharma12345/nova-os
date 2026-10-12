// The wallpaper, drawn by the shell so every glass card can frost from the same picture.
// A change of picture or pack is an ink-wash wipe: one flat brush stroke in the pack's ink sweeps
// across the screen and the new picture is left behind it. No glow, no blur, under a second.
// Performance mode (tenka-perf) cuts straight to the new picture.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: wall
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "tenka-wall"
    color: Theme.t.base
    property string cur: Theme.t.wallpaper
    readonly property int wipeMs: parseInt(Quickshell.env("TENKA_WIPE_MS") || "900")
    readonly property int stroke: Math.round(width * 0.16)        // the brush's width
    property real edge: 0                                          // where the stroke's middle is, 0 .. width + stroke
    onCurChanged: {
        if (shown.source == "" || Theme.perf || wipeMs <= 0) { shown.source = cur; next.source = ""; edge = 0; return }
        sweep.stop(); next.source = cur; edge = 0
        if (next.status === Image.Ready) sweep.start()
    }
    Component.onCompleted: shown.source = cur
    // the picture on show; the incoming one waits behind the stroke until it has loaded
    Image { id: shown; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 3840; asynchronous: true }
    Item {
        id: reveal
        x: 0; y: 0; height: parent.height
        width: Math.max(0, Math.min(wall.width, wall.edge - wall.stroke * 0.25))
        clip: true
        visible: next.source != ""
        Image { id: next; width: wall.width; height: wall.height; fillMode: Image.PreserveAspectCrop; sourceSize.width: 3840; asynchronous: true
                onStatusChanged: if (status === Image.Ready && wall.edge === 0 && source != "" && !sweep.running) sweep.start() }
    }
    // the hour's veil (Theme.veil): a flat wash of dawn, dusk or night over the picture, a few percent,
    // eased in over half a minute so nobody sees it move
    Rectangle {
        anchors.fill: parent
        color: Theme.veil; opacity: Theme.veilAmount
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 30000; easing.type: Easing.InOutSine } }
        Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 30000 } }
    }
    // focus (tenka-focus): the desk sinks under a flat wash of the pack's ink; no blur, no vignette
    Rectangle {
        anchors.fill: parent
        color: Theme.t.base; opacity: Theme.focus ? 0.55 : 0
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(600); easing.type: Easing.InOutSine } }
    }
    // the stroke: a flat band of ink with dry-brush edges, painted once per pack
    Canvas {
        id: brush
        width: wall.stroke; height: wall.height
        x: wall.edge - width / 2
        visible: sweep.running
        property color ink: Theme.t.base
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"); g.reset()
            const w = width, h = height, mid = w / 2
            let s = 7                                                    // a fixed seed: the same stroke every time
            function rnd() { s = (s * 16807) % 2147483647; return s / 2147483647 }
            g.fillStyle = Qt.rgba(ink.r, ink.g, ink.b, 1)
            const core = w * 0.30
            let lw = 0, rw = 0
            for (let y = 0; y < h; y += 3) {
                lw = lw * 0.8 + (rnd() - 0.5) * w * 0.06; rw = rw * 0.8 + (rnd() - 0.5) * w * 0.06
                const l = mid - core + lw, r = mid + core + rw
                g.globalAlpha = 1; g.fillRect(l, y, r - l, 3)
                // bristles: thinner, lighter drags of ink trailing off both sides
                const tl = rnd() * w * 0.20, tr = rnd() * w * 0.20
                g.globalAlpha = 0.55; g.fillRect(l - tl, y, tl, rnd() < 0.7 ? 2 : 1)
                g.globalAlpha = 0.55; g.fillRect(r, y, tr, rnd() < 0.7 ? 2 : 1)
                if (rnd() < 0.08) { g.globalAlpha = 0.25; g.fillRect(l - tl - w * 0.08 * rnd(), y, w * 0.06, 1) }
            }
        }
    }
    NumberAnimation {
        id: sweep; target: wall; property: "edge"; from: 0; to: wall.width + wall.stroke
        duration: wall.wipeMs; easing.type: Easing.InOutSine
        onFinished: { shown.source = wall.cur; settle.restart() }
    }
    // hand the new picture to `shown` first, then drop the copy, so there is no blank frame between them
    Timer { id: settle; interval: 120; onTriggered: { if (!sweep.running) { next.source = ""; wall.edge = 0 } } }
}
