// One quiet line from the almanac: tonight's moon, drawn flat, and the season ("Cold Dew  ·  Wild geese return";
// on Tianxia the term's old saying). On a feast day (tenka-feasts) the feast leads by day ("Tanabata  ·  Minor Heat"). Theme-free like MoonGlyph: the owner sets the colours and the face.
// It asks tenka-almanac itself while `running`, then every 20 minutes (and tenka-moon, after dark). Used by the lock (LockFace.qml), which also
// hands it the sky outside ("Autumn rain 24°", tenka-sky) to end the line.
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
    property string sky: ""                     // the weather outside in words (Theme.sky), after the season
    property bool night: false                  // after dark the moon leads: tonight's old name takes the season's saying
    property var m: null                        //   ("The crescent of the third night  ·  Cold Dew  ·  A clear night 24°")
    property var a: null
    property var f: null                        // today's feast (tenka-feasts): by day it leads, before the term
    spacing: px * 0.7
    visible: a !== null

    onThemeChanged: if (running) { ask.running = true; feastAsk.running = true }
    onRunningChanged: if (running) ask.running = true
    Process {
        id: ask
        running: line.running
        command: ["tenka-almanac", "json"]
        stdout: StdioCollector { onStreamFinished: { try { line.a = JSON.parse(text) } catch (e) {} } }
    }
    Timer { interval: 20 * 60 * 1000; repeat: true; running: line.running; onTriggered: { ask.running = true; feastAsk.running = true; if (line.night) moonAsk.running = true } }
    Process {
        id: feastAsk
        running: line.running
        command: ["tenka-feasts", "state"]
        stdout: StdioCollector { onStreamFinished: { try { line.f = JSON.parse(text).today || null } catch (e) {} } }
    }
    onNightChanged: if (running && night) moonAsk.running = true
    Process {
        id: moonAsk
        running: line.running && line.night
        command: ["tenka-moon", "state"]
        stdout: StdioCollector { onStreamFinished: { try { const v = JSON.parse(text); if (v && v.night) line.m = v } catch (e) {} } }
    }

    MoonGlyph {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(line.px * 1.15); height: width
        e: line.a ? line.a.moon.elongation : 0
        lit: line.lit; dark: line.dark; rim: line.rim
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        readonly property bool moonFirst: line.night && line.m !== null && (line.m.illumination || 0) >= 0.02
        readonly property string words: line.a ? (moonFirst ? line.m.night + "  \u00b7  " + line.a.term
                                                 : line.f ? line.f.name + "  \u00b7  " + line.a.term : line.a.term + "  \u00b7  " + line.a.detail)
                                                 + (line.sky ? "  \u00b7  " + line.sky : "") : ""
        text: line.caps ? words.toUpperCase() : words
        color: line.textColor; font.family: line.face; font.pixelSize: line.px
        font.letterSpacing: line.caps ? line.px * 0.32 : 0.5
    }
}
