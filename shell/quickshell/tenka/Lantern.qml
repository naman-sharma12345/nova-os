// The Lantern (Tianxia: The Ember): our own battery and power card, the flat ledger of The Air and The Bond.
// The charge as one large number and a flat line (the accent under 20 %), the time left or the time to full in
// plain words, then the ledger: the battery's health against its design, its cycles, the draw in watts, and any
// mouse, pad or headset that reports its own charge. Below, the power profile as three words: SAVER, BALANCED,
// PERFORMANCE (power-profiles-daemon); ← → or 1 2 3 choose, ESC closes. The facts come from tenka-lantern,
// which reads the kernel's power_supply ledger, so no daemon is needed for the charge.
// The card itself is lantern/LanternCard.qml, shared with Tenka Lite.
// qs ipc call lantern open|hide|toggle|state. Flat, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "lantern"

PanelWindow {
    id: lan
    property bool open: false

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-lantern"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "lantern"
        function open(): void { lan.reveal() }
        function hide(): void { lan.open = false }
        function toggle(): void { lan.open ? (lan.open = false) : lan.reveal() }
        function state(): string { return (lan.open ? "open" : "closed") + " ac=" + card.g.ac + (card.b ? " pct=" + card.b.pct + " state=" + card.b.state : " battery=none")
                                          + " profile=" + (card.g.profile || "none") + " word=" + Theme.powerWord }
    }
    Connections { target: Theme; function onAskPower() { lan.reveal() } }
    onOpenChanged: { Theme.hush = open; if (!open) card.note = "" }

    Process {
        id: readP
        command: ["tenka-lantern"]
        stdout: StdioCollector { onStreamFinished: {
            try { card.g = JSON.parse(text); Theme.powerWord = card.word() } catch (e) {}
        } }
    }
    Process {
        id: setP
        property string want: ""
        command: ["tenka-lantern", "profile", want]
        onExited: (code, status) => { card.note = code === 0 ? "" : "The profile did not change. Is power-profiles-daemon running?"; readP.running = true }
    }
    // every two seconds while open (the draw moves), once a minute for the ledger's word while closed
    Timer { interval: lan.open ? 2000 : 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!readP.running) readP.running = true }

    function reveal() { card.note = ""; open = true; readP.running = true; card.forceActiveFocus() }

    // the desk steps back: one flat wash
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, lan.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: lan.open; onClicked: lan.open = false }

    LanternCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, parent.height * 0.22) + (lan.open ? 0 : 16)
        opacity: lan.open ? 1 : 0
        focus: lan.open
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; uiFace: Theme.ui; xia: Theme.xia; motion: !Theme.perf
        onWant: p => { setP.want = p; setP.running = true }
        onDismissed: lan.open = false
    }
}
