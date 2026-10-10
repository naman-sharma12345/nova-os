// The on-screen display: a small frosted pill low in the middle when the volume or brightness moves.
// Volume follows PipeWire by itself; brightness keys call `qs -c tenka ipc call osd brightness <0-100>`.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    id: osd
    anchors { bottom: true }
    margins { bottom: 110 }
    implicitWidth: 380; implicitHeight: 72
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-osd"
    visible: shown || pill.opacity > 0.01
    mask: Region {}
    property bool shown: false
    property real v: 0
    property string glyph: "\uf028"
    property string label: "VOLUME"
    function pop(kind, value) {
        v = value; label = kind === "volume" ? "VOLUME" : "BRIGHTNESS"
        glyph = kind === "volume" ? (value <= 0.001 ? "\uf026" : value < 0.5 ? "\uf027" : "\uf028") : "\uf185"
        shown = true; hide.restart()
    }
    Timer { id: hide; interval: 1400; onTriggered: osd.shown = false }
    IpcHandler {
        target: "osd"
        function brightness(p: int): void { osd.pop("brightness", p / 100) }
        function volume(p: int): void { osd.pop("volume", p / 100) }
    }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() { osd.pop("volume", Pipewire.defaultAudioSink.audio.volume) }
        ignoreUnknownSignals: true
    }

    Glass {
        id: pill
        ox: osd.screen ? (osd.screen.width - osd.implicitWidth) / 2 : 0
        oy: osd.screen ? osd.screen.height - 110 - osd.implicitHeight : 0
        anchors.fill: parent; radius: 36; tint: 0.55
        opacity: osd.shown ? 1 : 0
        scale: osd.shown ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        Rectangle { x: 14; anchors.verticalCenter: parent.verticalCenter; width: 44; height: 44; radius: 22; color: Theme.t.accent
            Text { anchors.centerIn: parent; text: osd.glyph; font.family: Theme.glyphs; font.pixelSize: 17; color: Theme.t.ink } }
        Column {
            x: 74; anchors.verticalCenter: parent.verticalCenter; spacing: 8; width: parent.width - 74 - 70
            Text { text: osd.label; color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
            Rectangle { width: parent.width; height: 6; radius: 3; color: Theme.alpha(Theme.t.text, 0.14)
                Rectangle { height: parent.height; radius: 3; width: parent.width * Math.min(1, osd.v); color: Theme.t.accent
                    Behavior on width { NumberAnimation { duration: 140 } } } }
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter
               text: Math.round(osd.v * 100); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 24 }
    }
}
