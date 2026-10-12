// Focus (tenka-focus): a 2px hairline in the accent holds the edge of the screen while you work, with one
// small-caps word set into its lower edge. Flat: no glow, no shadow. Click-through; motion rests in Performance mode.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: fv
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-focus"
    mask: Region {}
    visible: Theme.focus || frame.opacity > 0

    readonly property color line: Theme.alpha(Theme.accent, 0.9)
    readonly property int w: 2
    Item {
        id: frame
        anchors.fill: parent
        opacity: Theme.focus ? 1 : 0
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(600); easing.type: Easing.InOutSine } }
        Rectangle { x: 0; y: 0; width: parent.width; height: fv.w; color: fv.line }
        Rectangle { x: 0; y: 0; width: fv.w; height: parent.height; color: fv.line }
        Rectangle { x: parent.width - fv.w; y: 0; width: fv.w; height: parent.height; color: fv.line }
        // the lower edge opens around the word
        Rectangle { x: 0; y: parent.height - fv.w; width: Math.max(0, word.x - 14); height: fv.w; color: fv.line }
        Rectangle { x: word.x + word.width + 14; y: parent.height - fv.w; width: Math.max(0, parent.width - x); height: fv.w; color: fv.line }
        Text {
            id: word
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - 4
            text: "FOCUS" + (Theme.focusLeft >= 0 ? "   \u00b7   " + Theme.focusLeft + " MIN" : "")
            color: Theme.gold
            font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 5
        }
    }
}
