// One quiet line from the almanac: tonight's moon, drawn flat, and the season ("Cold Dew  ·  Wild geese return";
// on Tianxia the term's old saying). Theme-free like MoonGlyph: the owner sets the colours and the face.
// It asks tenka-almanac itself while `running`, then every 20 minutes. Used by the lock (LockFace.qml).
import QtQuick
import Quickshell.Io

Row {
    id: line
    property bool running: true
    property color textColor: Qt.rgba(0.94, 0.90, 0.84, 0.62)
    property color lit: Qt.rgba(0.94, 0.90, 0.84, 0.86)
    property color dark: Qt.rgba(0.94, 0.90, 0.84, 0.10)
    property color rim: Qt.rgba(0.79, 0.64, 0.35, 0.45)
    property string face: "Marcellus"
    property real px: 17
    property bool caps: false
    property string theme: ""                   // re-ask when the pack changes
    property var a: null
    spacing: px * 0.7
    visible: a !== null

    onThemeChanged: if (running) ask.running = true
    onRunningChanged: if (running) ask.running = true
    Process {
        id: ask
        running: line.running
        command: ["tenka-almanac", "json"]
        stdout: StdioCollector { onStreamFinished: { try { line.a = JSON.parse(text) } catch (e) {} } }
    }
    Timer { interval: 20 * 60 * 1000; repeat: true; running: line.running; onTriggered: ask.running = true }

    MoonGlyph {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(line.px * 1.15); height: width
        e: line.a ? line.a.moon.elongation : 0
        lit: line.lit; dark: line.dark; rim: line.rim
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        readonly property string words: line.a ? line.a.term + "  \u00b7  " + line.a.detail : ""
        text: line.caps ? words.toUpperCase() : words
        color: line.textColor; font.family: line.face; font.pixelSize: line.px
        font.letterSpacing: line.caps ? line.px * 0.32 : 0.5
    }
}
