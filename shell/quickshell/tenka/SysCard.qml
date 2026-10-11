// The machine: three ink-brush enso arcs (CPU, memory, disk) with the numbers in Marcellus,
// and one quiet line for the weather (~/.config/tenka/desk.json "city") and the battery.
import Quickshell
import Quickshell.Io
import QtQuick

Glass {
    id: card
    width: 300; height: 296; radius: 24; tint: 0.30; innerLine: 0.22; line: 0.16
    property real cpu: 0; property real mem: 0; property real disk: 0
    property var lastCpu: null
    property string weather: ""; property string power: ""
    Process {
        id: probe
        command: ["sh", "-c", "head -1 /proc/stat; free -m | awk '/Mem:/ {print $3\" \"$2}'; df -P / | awk 'NR==2 {print $5}'; cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                const c = l[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = c[3] + c[4], tot = c.reduce((a, b) => a + b, 0);
                if (card.lastCpu) card.cpu = 1 - (idle - card.lastCpu[0]) / Math.max(1, tot - card.lastCpu[1]);
                card.lastCpu = [idle, tot];
                const m = l[1].split(" ");
                card.mem = Number(m[0]) / Number(m[1]);
                card.disk = parseInt(l[2]) / 100;
                card.power = l.length > 3 && l[3] !== "" ? "Battery " + l[3] + "%" : "On AC power";
            }
        }
    }
    Timer { interval: 2000; running: card.visible; repeat: true; triggeredOnStart: true; onTriggered: probe.running = true }
    Process {
        id: wx
        command: ["sh", "-c", "curl -s --max-time 6 'https://wttr.in/" + encodeURIComponent(Theme.desk.city) + "?m&format=%t|%C' | head -c 60"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split("|"); if (p.length === 2 && p[0].indexOf("°") >= 0) card.weather = Theme.desk.city + "  " + p[0].replace("+", "") + "  " + p[1] } }
    }
    Timer { interval: 1800000; running: Theme.desk.city !== ""; repeat: true; triggeredOnStart: true; onTriggered: wx.running = true }

    component Enso: Item {
        id: e
        property real v: 0; property string label: ""; property color c: Theme.t.accent; property int seed: 1
        width: 78; height: 112
        Canvas {
            id: cv; width: 78; height: 78
            property real v: e.v
            onVChanged: requestPaint()
            Behavior on v { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            function rnd(i) { const x = Math.sin(i * 12.9898 + e.seed * 78.233) * 43758.5453; return x - Math.floor(x) }
            function stroke(ctx, frac, col, alpha, wmax) {
                const cx = 39, cy = 39, R = 31, a0 = -Math.PI / 2 + 0.25, n = Math.max(2, Math.floor(160 * frac));
                ctx.fillStyle = col;
                for (let i = 0; i < n; i++) {
                    const t = i / 160, ang = a0 + t * Math.PI * 2 * 0.94;
                    const taper = Math.min(1, t * 160 / 10) * (1 - Math.pow(i / n, 3) * 0.75);
                    const wob = (rnd(i) - 0.5) * 0.9;
                    const r = (wmax * (0.55 + 0.45 * Math.sin(t * 9 + e.seed)) * taper) / 2;
                    ctx.globalAlpha = alpha * (0.75 + 0.25 * rnd(i + 7));
                    ctx.beginPath(); ctx.arc(cx + (R + wob) * Math.cos(ang), cy + (R + wob) * Math.sin(ang), Math.max(0.6, r), 0, Math.PI * 2); ctx.fill();
                }
                ctx.globalAlpha = 1;
            }
            onPaint: {
                const x = getContext("2d"); x.reset();
                stroke(x, 1, Theme.t.text, 0.10, 5);
                stroke(x, Math.max(0.03, v), e.c, 0.95, 6.5);
            }
            Text { anchors.centerIn: parent; text: Math.round(e.v * 100); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 22 }
        }
        Text { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; text: e.label
               color: Theme.alpha(Theme.t.text, 0.62); font.family: Theme.ui; font.pixelSize: 10; font.letterSpacing: 2 }
    }

    Column {
        x: 22; y: 22; width: parent.width - 44; spacing: 16
        Row {
            width: parent.width
            Text { id: hd; text: "SYSTEM"; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 15; font.letterSpacing: 5 }
            Item { width: parent.width - hd.width - pct.width; height: 1 }
            Text { id: pct; text: "%"; color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 14 }
        }
        Row {
            spacing: 12; anchors.horizontalCenter: parent.horizontalCenter
            Enso { v: card.cpu; label: "CPU"; c: Theme.t.accent; seed: 1 }
            Enso { v: card.mem; label: "MEMORY"; c: Theme.t.gold; seed: 2 }
            Enso { v: card.disk; label: "DISK"; c: Theme.alpha(Theme.t.text, 0.9); seed: 3 }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.t.gold, 0.18) }
        Column {
            spacing: 6
            Text { visible: card.weather !== ""; text: card.weather; color: Theme.alpha(Theme.t.text, 0.85); font.family: Theme.ui; font.pixelSize: 12 }
            Text { text: card.power; color: Theme.alpha(Theme.t.text, 0.55); font.family: Theme.ui; font.pixelSize: 12 }
        }
    }
}
