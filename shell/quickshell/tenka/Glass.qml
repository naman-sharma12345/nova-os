// A glass card. Off Hyprland it frosts itself from the pre-blurred wallpaper (ox/oy = where its
// window sits on the screen); on Hyprland the compositor blurs behind the tenka-* layers.
// Then an ink tint, a fine gold hairline, a sheen along the top and a soft shadow.
import QtQuick
import QtQuick.Effects

Item {
    id: g
    property real radius: Theme.r
    property real tint: 0.42
    property real line: 0.22
    property real ox: 0
    property real oy: 0
    property color tintColor: Theme.t.base
    property bool shadow: true
    property bool frost: Theme.selfBlur
    property bool sheen: true
    property real innerLine: 0
    default property alias content: inner.data

    // where this card sits on the screen; re-read whenever it or its parents move
    property point at: Qt.point(0, 0)
    property real k: 1      // on-screen pixels per item pixel (cards may be scaled)
    function place() { const p = g.mapToItem(null, 0, 0); const q = g.mapToItem(null, 100, 0);
                       g.k = Math.max(0.01, (q.x - p.x) / 100); g.at = Qt.point(p.x + ox, p.y + oy) }
    onXChanged: place(); onYChanged: place(); onWidthChanged: place(); onHeightChanged: place(); onVisibleChanged: place()
    Component.onCompleted: place()
    Connections { target: g.parent; function onXChanged() { g.place() } function onYChanged() { g.place() } ignoreUnknownSignals: true }

    // the shadow: soft rings of ink falling away below the card (the frost covers their middle)
    Repeater {
        model: g.shadow && g.frost ? 7 : 0
        Rectangle {
            required property int index
            x: -(index + 1) * 2.4; y: -(index + 1) * 2.4 + 8 + index * 0.8
            width: g.width + 2 * (index + 1) * 2.4; height: g.height + 2 * (index + 1) * 2.4
            radius: g.radius + (index + 1) * 2.4
            color: Theme.alpha("#000000", 0.085 - index * 0.010)
        }
    }
    Item {
        id: frostSrc
        anchors.fill: parent; visible: false
        Image {
            source: g.frost ? Theme.wallBlur : ""
            x: -g.at.x / g.k; y: -g.at.y / g.k; width: Theme.sw / g.k; height: Theme.sh / g.k
            fillMode: Image.PreserveAspectCrop; smooth: true; cache: true; asynchronous: false
        }
    }
    Rectangle { id: frostMask; anchors.fill: parent; radius: g.radius; visible: false; layer.enabled: true; layer.smooth: true }
    MultiEffect {
        visible: g.frost
        anchors.fill: parent; source: frostSrc
        maskEnabled: true; maskSource: frostMask
        maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
        saturation: 0.15; brightness: -0.04
    }

    Rectangle {   // the ink
        anchors.fill: parent; radius: g.radius
        color: Theme.alpha(g.tintColor, g.tint)
        border.width: 1; border.color: Theme.alpha(Theme.t.gold, g.line)
    }
    Rectangle {   // top sheen
        visible: g.sheen
        anchors.fill: parent; anchors.margins: 1; radius: g.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.t.text, 0.075) }
            GradientStop { position: 0.28; color: Theme.alpha(Theme.t.text, 0.0) }
        }
    }
    Rectangle {   // the inner gold hairline
        visible: g.innerLine > 0
        anchors.fill: parent; anchors.margins: 5; radius: Math.max(0, g.radius - 5)
        color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.t.gold, g.innerLine)
    }
    Item { id: inner; anchors.fill: parent }
}
