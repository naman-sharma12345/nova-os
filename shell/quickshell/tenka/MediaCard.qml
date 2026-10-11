// What is playing (any MPRIS player): a large cover, the title in Marcellus, the progress as a
// dry-brush stroke, and hand-drawn transport marks.
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Glass {
    id: m
    width: 360; height: 296; radius: 24; tint: 0.30; innerLine: 0.22; line: 0.16
    readonly property var p: Mpris.players.values.length ? Mpris.players.values[0] : null
    readonly property bool idle: !p
    readonly property real frac: !p || !p.lengthSupported || p.length <= 0 ? 0 : Math.min(1, p.position / p.length)
    function mmss(s) { s = Math.max(0, Math.floor(s || 0)); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2) }
    Timer { running: !!m.p && m.p.isPlaying; interval: 1000; repeat: true; onTriggered: if (m.p) m.p.positionChanged() }

    Item {
        id: cover
        x: 22; y: 22; width: 150; height: 150
        Image { id: art; anchors.fill: parent; visible: false; fillMode: Image.PreserveAspectCrop; sourceSize.height: 400
                source: m.p && m.p.trackArtUrl ? m.p.trackArtUrl : Theme.t.keyart }
        Rectangle { id: artMask; anchors.fill: parent; radius: 16; visible: false; layer.enabled: true }
        MultiEffect { anchors.fill: parent; source: art; maskEnabled: true; maskSource: artMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
        Rectangle { anchors.fill: parent; radius: 16; color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.t.gold, 0.35) }
    }
    Column {
        anchors.left: cover.right; anchors.leftMargin: 18; anchors.right: parent.right; anchors.rightMargin: 22
        anchors.bottom: cover.bottom
        spacing: 6
        Text { text: m.idle ? "THE QUIET HOUR" : (m.p.isPlaying ? "NOW PLAYING" : "PAUSED"); color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 5 }
        Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; color: Theme.t.text
               font.family: Theme.display; font.pixelSize: 21; lineHeight: 1.05
               text: m.idle ? "Nothing playing" : (m.p.trackTitle || "Untitled") }
        Text { width: parent.width; elide: Text.ElideRight; color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.ui; font.pixelSize: 12
               text: m.idle ? "Play anything; it lands here" : (m.p.trackArtist || m.p.identity) }
    }
    // progress: a faint stroke, and the played part as a full-strength brush stroke
    Item {
        id: prog
        x: 22; y: 192; width: parent.width - 44; height: 22
        Image { anchors.fill: parent; source: Theme.asset("brush.png"); opacity: 0.16; smooth: true }
        Item { width: parent.width * m.frac; height: parent.height; clip: true
               Image { width: prog.width; height: prog.height; source: Theme.asset("brush.png"); smooth: true } }
    }
    Text { x: 22; y: 218; text: m.idle ? "0:00" : m.mmss(m.p.position); color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 10 }
    Text { anchors.right: parent.right; anchors.rightMargin: 22; y: 218; text: m.idle ? "0:00" : m.mmss(m.p.length)
           color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 10 }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter; y: 236; spacing: 36
        Repeater {
            model: ["prev", m.p && m.p.isPlaying ? "pause" : "play", "next"]
            Item {
                required property string modelData; required property int index
                width: index === 1 ? 44 : 30; height: 44
                Rectangle { visible: parent.index === 1; anchors.fill: parent; radius: 22; color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.t.gold, 0.55) }
                Image { anchors.centerIn: parent; width: parent.index === 1 ? 20 : 18; height: width; smooth: true; source: Theme.icon(parent.modelData + "-light"); opacity: m.idle ? 0.4 : 0.9 }
                MouseArea { anchors.fill: parent; enabled: !m.idle
                            onClicked: parent.index === 0 ? m.p.previous() : parent.index === 1 ? m.p.togglePlaying() : m.p.next() }
            }
        }
    }
}
