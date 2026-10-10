// Bar style "frame": an ink passe-partout round the whole screen, like a mounted scroll. Windows sit
// inside it (exclusive zones on every edge); its inner edge is rounded and drawn with a gold hairline;
// the bar lives in the top edge: workspace pips, the focused title, and the time.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes

Scope {
    id: fr
    property ShellScreen screen
    readonly property bool on: Theme.barStyle === "frame"
    readonly property int side: 10
    readonly property int top: 36
    readonly property int r: 22
    readonly property color ink: Theme.alpha(Theme.t.base, 0.94)

    // exclusive-zone holders for the sides and the bottom (the top one carries the bar)
    Variants {
        model: ["left", "right", "bottom"]
        PanelWindow {
            required property string modelData
            screen: fr.screen
            visible: fr.on
            anchors { left: modelData !== "right"; right: modelData !== "left"; bottom: true; top: modelData !== "bottom" }
            implicitWidth: fr.side; implicitHeight: fr.side
            exclusiveZone: fr.side
            color: "transparent"
            WlrLayershell.namespace: "tenka-frame"
            mask: Region {}
        }
    }

    // the frame itself, drawn once over everything, input passes through
    PanelWindow {
        screen: fr.screen
        visible: fr.on
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "tenka-frame"
        mask: Region {}
        Shape {
            id: fs
            anchors.fill: parent
            readonly property real ix: fr.side
            readonly property real iy: fr.top
            readonly property real iw: width - 2 * fr.side
            readonly property real ih: height - fr.top - fr.side
            readonly property string inner: {
                const x = ix, y = iy, w = iw, h = ih, q = fr.r;
                return "M" + (x + q) + " " + y + " H" + (x + w - q) + " A" + q + " " + q + " 0 0 1 " + (x + w) + " " + (y + q)
                     + " V" + (y + h - q) + " A" + q + " " + q + " 0 0 1 " + (x + w - q) + " " + (y + h)
                     + " H" + (x + q) + " A" + q + " " + q + " 0 0 1 " + x + " " + (y + h - q)
                     + " V" + (y + q) + " A" + q + " " + q + " 0 0 1 " + (x + q) + " " + y + " Z"
            }
            ShapePath {
                fillColor: fr.ink; strokeColor: "transparent"; fillRule: ShapePath.OddEvenFill
                PathSvg { path: "M0 0 H" + fs.width + " V" + fs.height + " H0 Z " + fs.inner }
            }
            ShapePath {
                fillColor: "transparent"; strokeColor: Theme.alpha(Theme.t.gold, 0.55); strokeWidth: 1
                PathSvg { path: fs.inner }
            }
        }
    }

    // the top edge: the bar
    PanelWindow {
        screen: fr.screen
        visible: fr.on
        anchors { top: true; left: true; right: true }
        implicitHeight: fr.top
        exclusiveZone: fr.top
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "tenka-frame-bar"
        Row {
            anchors.left: parent.left; anchors.leftMargin: 22; anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Image { source: Theme.t.crest; width: 18; height: 18; mipmap: true; anchors.verticalCenter: parent.verticalCenter; opacity: 0.9 }
            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 8
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        readonly property bool active: (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1) === index + 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: active ? 18 : 4; height: 4; radius: 2
                        color: active ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.4)
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Hyprland.dispatch("workspace " + (parent.index + 1)) }
                    }
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.title ? ToplevelManager.activeToplevel.title.toUpperCase() : Theme.t.word
            width: Math.min(implicitWidth, parent.width * 0.4); elide: Text.ElideRight
            color: Theme.alpha(Theme.t.text, 0.5)
            font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 5
        }
        MouseArea {
            anchors.right: parent.right; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter
            width: tr.width; height: parent.height; cursorShape: Qt.PointingHandCursor
            onClicked: Theme.ipc("control", "toggle")
            Row {
                id: tr; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                Text { text: Qt.formatDate(Theme.now, "ddd d").toUpperCase(); color: Theme.alpha(Theme.t.text, 0.55)
                       font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 1; height: 12; color: Theme.alpha(Theme.t.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
                Text { text: Theme.hm(Theme.now) + " " + Theme.ap(Theme.now); color: Theme.t.text
                       font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
