import Quickshell
import Quickshell.Io
import QtQuick

Glass {
    id: card
    width: 420; height: 112; radius: 24
    property string mem: ""
    property real memFrac: 0
    property string up: ""
    Process {
        id: probe
        command: ["sh", "-c", "free -m | awk '/Mem:/ {print $3\" \"$2}'; uptime -p | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                const m = l[0].split(" ");
                card.mem = (Number(m[0]) / 1024).toFixed(1) + " / " + (Number(m[1]) / 1024).toFixed(1) + " GB";
                card.memFrac = Number(m[0]) / Number(m[1]);
                card.up = l.length > 1 ? l[1] : "";
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: probe.running = true }

    Row {
        anchors.fill: parent; anchors.margins: 18; spacing: 18
        Image { source: Theme.t.crest; width: 74; height: 74; smooth: true; mipmap: true; anchors.verticalCenter: parent.verticalCenter }
        Column {
            anchors.verticalCenter: parent.verticalCenter; spacing: 6; width: 280
            Text { text: Theme.t.display.toUpperCase() + "  ·  " + Theme.t.tagline; color: Theme.t.gold
                   font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 4 }
            Text { text: "Memory  " + card.mem; color: Theme.t.text; font.family: Theme.ui; font.pixelSize: 13 }
            Rectangle { width: 260; height: 3; radius: 2; color: Theme.alpha(Qt.color(Theme.t.text), 0.15)
                Rectangle { width: parent.width * card.memFrac; height: parent.height; radius: 2; color: Theme.t.accent } }
            Text { text: "Up " + card.up; color: Theme.alpha(Qt.color(Theme.t.text), 0.6); font.family: Theme.ui; font.pixelSize: 12 }
        }
    }
}
