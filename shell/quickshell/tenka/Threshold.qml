// Arrival: the first frame of the desktop is the login screen's last one. When the session starts
// (and again just after an unlock) this overlay shows the gate, presses the seal, then lets the
// whole scene fall away over the desk in the login screen's own 1.4 s ease. It plays once per
// session start (a shell reload doesn't replay it), passes every click through, and in
// Performance mode it simply isn't drawn.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: th
    readonly property real k: Number(Quickshell.env("TENKA_MOTION_SCALE") || "1")   // renders slow it down
    property bool playing: true     // up from the first frame so the desk never shows before the gate
    visible: playing
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-threshold"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    mask: Region {}

    PersistentProperties { id: once; reloadableId: "tenka-threshold"; property bool arrived: false }

    Item {
        id: scene
        anchors.fill: parent
        Rectangle { id: veil; anchors.fill: parent; color: "black" }   // the black between the login screen and the session
        Gate { id: gate; anchors.fill: parent; opacity: 0 }
    }

    // from black (or from the lock) into the gate, the seal pressed, then the gate falls away
    SequentialAnimation {
        id: arrive
        ScriptAction { script: { gate.sealOpacity = 0; gate.ensoOpacity = 0.14; veil.visible = true; scene.opacity = 1; th.playing = true } }
        NumberAnimation { target: gate; property: "opacity"; from: 0; to: 1; duration: 320 * th.k; easing.type: Easing.OutQuad }
        ScriptAction { script: gate.stamp() }
        PauseAnimation { duration: 620 * th.k }
        NumberAnimation { target: scene; property: "opacity"; to: 0; duration: 1400 * th.k; easing.type: Easing.OutCubic }
        ScriptAction { script: th.playing = false }
    }
    // after an unlock the lock face has just shown the gate with its seal: only the falling away
    SequentialAnimation {
        id: release
        ScriptAction { script: { gate.sealOpacity = 1; gate.sealScale = 1; gate.ensoOpacity = 0.14; gate.opacity = 1; veil.visible = false; scene.opacity = 1; th.playing = true } }
        NumberAnimation { target: scene; property: "opacity"; to: 0; duration: 900 * th.k; easing.type: Easing.OutCubic }
        ScriptAction { script: th.playing = false }
    }
    function play(kind) {
        if (Theme.perf) { th.playing = false; return }
        if (kind === "unlock") release.restart(); else arrive.restart()
    }
    Connections { target: Theme; function onArrive(kind) { th.play(kind) } }
    // the session start: wait a beat for the perf flag to be read, then play once
    Timer {
        interval: 120; running: true
        onTriggered: {
            if (!once.arrived || Quickshell.env("TENKA_THRESHOLD_PREVIEW") === "1") { once.arrived = true; th.play("arrive") }
            else th.playing = false      // a reload: the desk is already there
        }
    }
}
