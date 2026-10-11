// The on-screen display. With the notch (the default bar) the notch itself carries it: it widens into a
// hairline meter for a moment. With the line or frame bar: Tenka's one OSD card (osd/OsdCard.qml, the
// same card Tenka Lite shows), low in the middle.
// Volume follows PipeWire by itself; brightness keys call `qs -c tenka ipc call osd brightness <0-100>`.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "osd"

PanelWindow {
    id: osd
    anchors { bottom: true }
    margins { bottom: 110 }
    implicitWidth: 340; implicitHeight: 64
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-osd"
    visible: shown || pill.opacity > 0.01
    mask: Region {}
    property bool shown: false
    property real v: 0
    property string kind: "volume"
    property bool muted: false
    function pop(k, value, m) {
        const lock = k === "caps" || k === "num"      // a lock key has no meter for the notch to carry: always the card
        if (!lock && Theme.barStyle === "notch" && Quickshell.env("TENKA_OSD_CARD") !== "1") {   // the notch carries it: a hairline meter
            Theme.osdKind = k; Theme.osdValue = m ? 0 : value; Theme.osdTick += 1; return
        }
        kind = k; v = value; muted = !!m
        shown = true; hide.restart()
    }
    Timer { id: hide; interval: Number(Quickshell.env("TENKA_OSD_HOLD") || "1400"); onTriggered: osd.shown = false }
    // PipeWire reports the sink volume once at login; only real changes after that pop the OSD
    property bool armed: false
    Timer { interval: 5000; running: true; onTriggered: osd.armed = true }
    IpcHandler {
        target: "osd"
        function brightness(p: int): void { osd.pop("brightness", p / 100) }
        function volume(p: int): void { osd.pop("volume", p / 100) }
        function muted(p: int): void { osd.pop("volume", p / 100, true) }
        function lock(which: string, on: int): void { osd.pop(which === "num" ? "num" : "caps", on ? 1 : 0) }
    }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() { if (osd.armed) osd.pop("volume", Pipewire.defaultAudioSink.audio.volume, Pipewire.defaultAudioSink.audio.muted) }
        function onMutedChanged() { if (osd.armed) osd.pop("volume", Pipewire.defaultAudioSink.audio.volume, Pipewire.defaultAudioSink.audio.muted) }
        ignoreUnknownSignals: true
    }

    OsdCard {
        id: pill
        anchors.fill: parent
        shown: osd.shown
        kind: osd.kind; value: osd.v; muted: osd.muted
        base: Theme.t.base; text: Theme.t.text; sub: Theme.t.subtext; accent: Theme.accent; gold: Theme.gold
        radius: Theme.ledgerR; face: Theme.ui; motion: !Theme.perf
    }
}
