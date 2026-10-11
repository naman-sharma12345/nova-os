// Bar style "notch": no bar at all. One small ink pill hangs from the top centre: the workspace as a
// Roman numeral, a seal dot, the time. Touch it and it grows (one shared bezier) into the day: the
// date, the hour's name, the proverb and what is playing.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: notch
    visible: Theme.barStyle === "notch"
    anchors { top: true }
    implicitWidth: 760; implicitHeight: 200
    exclusiveZone: 26
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "tenka-notch"
    mask: Region { item: hit }
    property bool open: Quickshell.env("TENKA_NOTCH_OPEN") === "1"
    readonly property var roman: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var player: Mpris.players.values.length ? Mpris.players.values[0] : null
    readonly property var curve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var spring: [0.05, 0.7, 0.1, 1, 1, 1]   // no overshoot: the ink draws out, it does not bounce
    readonly property color ink: Theme.alpha(Theme.t.base, 0.95)

    Item {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: notch.open ? 660 : (notch.meter ? 400 : 236)
        height: notch.open ? 150 : 30
        Behavior on width { NumberAnimation { duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: notch.spring } }
        Behavior on height { NumberAnimation { duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: notch.curve } }

        // the body: square at the screen edge, round below; and two concave ears that melt it into the edge
        Rectangle {
            anchors.fill: parent
            color: notch.ink
            topLeftRadius: 0; topRightRadius: 0
            bottomLeftRadius: notch.open ? Theme.ledgerR + 4 : 15; bottomRightRadius: notch.open ? Theme.ledgerR + 4 : 15
            border.width: 0
        }
        Repeater {
            model: [-1, 1]
            Shape {
                required property int modelData
                width: 14; height: 14; y: 0
                x: modelData < 0 ? -14 : pill.width
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: notch.ink; strokeColor: "transparent"
                    PathSvg { path: modelData < 0 ? "M0 0 H14 V14 A14 14 0 0 0 0 0 Z" : "M0 0 H14 A14 14 0 0 0 0 14 Z" }
                }
            }
        }
        Rectangle {   // the gold hairline along the lower edge
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 34; height: 1
            color: Theme.alpha(Theme.t.gold, 0.4)
        }

        // the meter: VOLUME ────◆──── 64, for a breath after a key press
        Item {
            anchors.fill: parent; anchors.leftMargin: 26; anchors.rightMargin: 26
            opacity: notch.meter && !notch.open ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Text { id: mk; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1
                   text: Theme.osdKind === "brightness" ? "LIGHT" : (Theme.osdValue <= 0.001 ? "MUTED" : "VOLUME")
                   color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 4; width: 74 }
            Item {
                x: 82; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1
                width: parent.width - 82 - 44; height: 10
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.22) }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.min(1, Theme.osdValue); height: 2; color: Theme.t.gold
                            Behavior on width { NumberAnimation { duration: 120 } } }
                Rectangle { x: parent.width * Math.min(1, Theme.osdValue) - 4; anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; rotation: 45; color: Theme.t.gold
                            Behavior on x { NumberAnimation { duration: 120 } } }
            }
            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1
                   text: Math.round(Theme.osdValue * 100); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 14 }
        }

        // closed: II  ·  10:41 PM
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6; spacing: 12
            opacity: notch.open || notch.meter ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Text { text: notch.roman[Math.max(0, Math.min(9, notch.wsId - 1))]; color: Theme.t.gold
                   font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 2; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 6; height: 6; radius: 3; color: Theme.t.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Theme.hm(Theme.now) + " " + Theme.ap(Theme.now); color: Theme.t.text
                   font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 1.5; anchors.verticalCenter: parent.verticalCenter }
        }

        // open: the day
        Item {
            anchors.fill: parent; anchors.margins: 20; anchors.topMargin: 14
            opacity: notch.open ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 260 } }
            Text { id: big; text: Theme.hm(Theme.now); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 64; x: 6; y: -2 }
            Text { anchors.left: big.right; anchors.leftMargin: 8; anchors.baseline: big.baseline; text: Theme.ap(Theme.now)
                   color: Theme.alpha(Theme.t.text, 0.7); font.family: Theme.display; font.pixelSize: 16; font.letterSpacing: 4 }
            Text { x: 8; anchors.top: big.bottom; anchors.topMargin: 2
                   text: Qt.formatDate(Theme.now, "dddd d MMMM").toUpperCase() + "  ·  " + Theme.hourName(Theme.now).toUpperCase()
                   color: Theme.alpha(Theme.t.gold, 0.9); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3 }
            Rectangle { x: 336; y: 8; width: 1; height: parent.height - 16; color: Theme.alpha(Theme.t.gold, 0.25) }
            Column {
                x: 358; y: 10; width: parent.width - 366; spacing: 6
                Row {   // a numbered small-caps label, the ledger's way of naming a box
                    spacing: 8
                    Text { text: "02"; color: Theme.alpha(Theme.t.gold, 0.7); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { width: 18; height: 1; color: Theme.alpha(Theme.t.gold, 0.55); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: notch.player ? "NOW PLAYING" : "THE HOUR'S WORD"; color: Theme.alpha(Theme.t.text, 0.55)
                           font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 4 }
                }
                Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                       text: notch.player ? (notch.player.trackTitle || "") : Theme.t.proverbs[Theme.now.getHours() % Math.max(1, Theme.t.proverbs.length)]
                       color: Theme.t.text; font.family: Theme.display; font.pixelSize: 17; lineHeight: 1.15 }
                Text { visible: !!notch.player; text: notch.player ? (notch.player.trackArtist || "") : ""
                       color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 1 }
            }
        }
        MouseArea {
            id: hit; anchors.fill: parent; hoverEnabled: true
            onEntered: closeT.stop()
            onExited: if (!notch.pinned) closeT.restart()
            onClicked: { notch.pinned = !notch.open; notch.open = !notch.open }
        }
    }
    property bool pinned: false
    property bool meter: Quickshell.env("TENKA_NOTCH_METER") === "1"
    Timer { id: meterT; interval: 1500; onTriggered: notch.meter = false }
    Connections { target: Theme; function onOsdTickChanged() { notch.meter = true; meterT.restart() } }
    Timer { id: closeT; interval: 900; onTriggered: if (!notch.pinned) notch.open = false }
    IpcHandler { target: "notch"; function toggle(): void { notch.pinned = !notch.open; notch.open = !notch.open } }
}
