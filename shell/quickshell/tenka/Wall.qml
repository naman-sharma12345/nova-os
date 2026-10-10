// The wallpaper, drawn by the shell so every glass card can frost from the same picture,
// with a slow crossfade whenever the pack or the picture changes.
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
    property bool flip: false
    onCurChanged: { flip = !flip; (flip ? b : a).source = cur }
    Image { id: a; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; source: wall.cur; sourceSize.width: 3840
            opacity: wall.flip ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } } }
    Image { id: b; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 3840
            opacity: wall.flip ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } } }
}
