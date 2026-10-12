// The desk in the ledger language (Theme.cardsStyle "ledger", default; "bare" drops the ink sheet):
// one quiet ink sheet with three ruled boxes side by side — 01 MONTH, 02 SOUND, 03 MACHINE.
// Text rows and hairline meters instead of seals, ensō rings and brush bars. No fills, no glow.
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import "almanac"

Item {
    id: dl
    property real ox: 0; property real oy: 0
    property bool bare: Theme.cardsStyle === "bare"
    width: row.width + 48; height: row.height + 44
    function place() { sheet.place() }

    // ---------------------------------------------------------------- data
    property real cpu: 0; property real mem: 0; property real disk: 0
    property var lastCpu: null
    property string memText: ""; property string weather: ""; property string power: ""
    Process {
        id: probe
        command: ["sh", "-c", "head -1 /proc/stat; free -m | awk '/Mem:/ {print $3\" \"$2}'; df -P / | awk 'NR==2 {print $5}'; cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                const c = l[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = c[3] + c[4], tot = c.reduce((a, b) => a + b, 0);
                if (dl.lastCpu) dl.cpu = 1 - (idle - dl.lastCpu[0]) / Math.max(1, tot - dl.lastCpu[1]);
                dl.lastCpu = [idle, tot];
                const m = l[1].split(" ");
                dl.mem = Number(m[0]) / Number(m[1]);
                dl.memText = (Number(m[0]) / 1024).toFixed(1) + " of " + Math.round(Number(m[1]) / 1024) + " GB";
                dl.disk = parseInt(l[2]) / 100;
                dl.power = l.length > 3 && l[3] !== "" ? "Battery  " + l[3] + "%" : "On AC power";
            }
        }
    }
    Timer { interval: 2000; running: dl.visible; repeat: true; triggeredOnStart: true; onTriggered: probe.running = true }
    Process {
        id: wx
        command: ["sh", "-c", "curl -s --max-time 6 'https://wttr.in/" + encodeURIComponent(Theme.desk.city) + "?m&format=%t|%C' | head -c 60"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split("|"); if (p.length === 2 && p[0].indexOf("°") >= 0) dl.weather = Theme.desk.city + "  " + p[0].replace("+", "") + "  " + p[1] } }
    }
    Timer { interval: 1800000; running: Theme.desk.city !== ""; repeat: true; triggeredOnStart: true; onTriggered: wx.running = true }

    property var almanac: null
    Process {
        id: almP
        command: ["tenka-almanac", "json"]
        stdout: StdioCollector { onStreamFinished: { try { dl.almanac = JSON.parse(text) } catch (e) {} } }
    }
    // the term turns every ~15 days and the moon by the hour: once on open, then every 20 minutes while up
    Timer { interval: 1200000; running: dl.visible; repeat: true; triggeredOnStart: true; onTriggered: almP.running = true }
    Connections { target: Theme.t; function onNameChanged() { almP.running = true } }
    // The Pillow Book (Tianxia: The Jade Record): whether today's page is written, and its first words
    property string page: ""
    Process { id: pageP; command: ["tenka-journal", "today"]; stdout: StdioCollector { onStreamFinished: dl.page = text.trim() } }
    Timer { interval: 60000; running: dl.visible; repeat: true; triggeredOnStart: true; onTriggered: pageP.running = true }
    Connections { target: Theme; function onHushChanged() { if (!Theme.hush) pageP.running = true } }   // the book just closed

    readonly property var p: Mpris.players.values.length ? Mpris.players.values[0] : null
    readonly property real frac: !p || !p.lengthSupported || p.length <= 0 ? 0 : Math.min(1, p.position / p.length)
    function mmss(s) { s = Math.max(0, Math.floor(s || 0)); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2) }
    Timer { running: !!dl.p && dl.p.isPlaying; interval: 1000; repeat: true; onTriggered: if (dl.p) dl.p.positionChanged() }

    readonly property date d: Theme.now
    readonly property int first: (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7
    readonly property int days: new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
    readonly property int weeks: Math.ceil((first + days) / 7)

    // ---------------------------------------------------------------- the sheet
    Glass {
        id: sheet
        visible: !dl.bare
        anchors.fill: parent
        ox: dl.ox; oy: dl.oy
        radius: Theme.ledgerR; tint: Theme.selfBlur ? 0.66 : 0.56; line: 0.42; innerLine: 0; sheen: false
    }

    readonly property real bh: Math.max(b1.implicitHeight, b2.implicitHeight, b3.implicitHeight)
    Row {
        id: row
        x: 24; y: 22; spacing: 20

        LedgerBox {
            id: b1
            num: "01"; label: "MONTH"; aside: Qt.formatDate(dl.d, "MMMM yyyy").toUpperCase()
            width: 300; height: dl.bh
            Column {
                width: parent.width; spacing: 10
                Grid {
                    id: grid
                    readonly property real cw: parent.width / 7
                    columns: 7; rowSpacing: 2
                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        Text { required property string modelData
                               width: grid.cw; height: 22; horizontalAlignment: Text.AlignHCenter; text: modelData
                               color: Theme.alpha(Theme.gold, 0.85); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 1 }
                    }
                    Repeater {
                        model: dl.weeks * 7
                        Item {
                            required property int index
                            readonly property int day: index - dl.first + 1
                            readonly property bool real: day >= 1 && day <= dl.days
                            readonly property bool today: day === dl.d.getDate()
                            readonly property bool past: day < dl.d.getDate()
                            width: grid.cw; height: 26
                            Rectangle { anchors.centerIn: parent; width: 24; height: 24; visible: parent.today && parent.real
                                        color: "transparent"; border.width: 1; border.color: Theme.accent; radius: Theme.xia ? 12 : 2 }
                            Text { anchors.centerIn: parent; text: parent.real ? parent.day : ""
                                   color: parent.today ? Theme.t.text : Theme.alpha(Theme.t.text, parent.past ? 0.28 : 0.82)
                                   font.family: Theme.display; font.pixelSize: 13 }
                        }
                    }
                }
                // The Almanac (Tianxia: The Heavenly Calendar): the solar term, its micro-season or old
                // saying, and tonight's moon, from tenka-almanac (computed locally, no network)
                Item {
                    id: alm
                    visible: dl.almanac !== null
                    width: parent.width; height: visible ? Math.max(48, almCol.implicitHeight + 18) : 0
                    Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.08) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theme.ipc("almanac", "open") }
                    MoonGlyph { id: moon; x: 2; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 2
                                width: 24; height: 24; e: dl.almanac ? dl.almanac.moon.elongation : 0
                                lit: Theme.alpha(Theme.t.text, 0.86); dark: Theme.alpha(Theme.t.text, 0.10); rim: Theme.alpha(Theme.gold, 0.45) }
                    Column {
                        id: almCol
                        x: moon.width + 14; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 2
                        width: parent.width - x; spacing: 3
                        Row {
                            width: parent.width; spacing: 0
                            Text { id: termT; text: dl.almanac ? dl.almanac.term : ""; color: Theme.alpha(Theme.t.text, 0.92)
                                   font.family: Theme.display; font.pixelSize: 14 }
                            Item { width: parent.width - termT.width - moonT.width; height: 1 }
                            Text { id: moonT; text: dl.almanac ? dl.almanac.moon.phase.toUpperCase() : ""; color: Theme.alpha(Theme.t.text, 0.45)
                                   font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 2; anchors.baseline: termT.baseline }
                        }
                        Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                               lineHeight: 1.1; text: dl.almanac ? dl.almanac.detail : ""
                               color: Theme.alpha(Theme.gold, 0.9); font.family: Theme.display; font.pixelSize: 12 }
                    }
                }
                // the sun over your place today (tenka-almanac): the day as a hairline, the light on it in gold, now a dot
                Item {
                    id: sunRow
                    readonly property var s: dl.almanac && dl.almanac.sun && dl.almanac.sun.rise ? dl.almanac.sun : null
                    function fx(hm) { const p = hm.split(":"); return (+p[0] * 60 + +p[1]) / 1440 }
                    function hm(t) { return t.replace(/^0/, "") }
                    visible: s !== null
                    width: parent.width; height: visible ? 40 : 0
                    Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.08) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theme.ipc("almanac", "open") }
                    Item {
                        id: sunBar; y: 12; width: parent.width; height: 7
                        Rectangle { y: 3; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.14) }
                        Rectangle { visible: sunRow.s !== null; y: 2; height: 3; color: Theme.alpha(Theme.gold, 0.85)
                                    x: sunRow.s ? sunBar.width * sunRow.fx(sunRow.s.rise) : 0
                                    width: sunRow.s ? sunBar.width * (sunRow.fx(sunRow.s.set) - sunRow.fx(sunRow.s.rise)) : 0 }
                        Rectangle { x: sunBar.width * (Theme.now.getHours() * 60 + Theme.now.getMinutes()) / 1440 - 3.5; y: 0
                                    width: 7; height: 7; radius: 3.5; color: Theme.t.text }
                    }
                    Text { id: riseT; y: 22; x: sunRow.s ? Math.max(0, Math.min(sunRow.width / 2 - width - 6, sunRow.width * sunRow.fx(sunRow.s.rise) - width / 2)) : 0
                           text: sunRow.s ? "SUNRISE  " + sunRow.hm(sunRow.s.rise) : ""; color: Theme.alpha(Theme.t.text, 0.6)
                           font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 2 }
                    Text { y: 22; x: sunRow.s ? Math.min(sunRow.width - width, Math.max(sunRow.width / 2 + 6, sunRow.width * sunRow.fx(sunRow.s.set) - width / 2)) : 0
                           text: sunRow.s ? "SUNSET  " + sunRow.hm(sunRow.s.set) : ""; color: Theme.alpha(Theme.t.text, 0.6)
                           font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 2 }
                }
                // today's page in the Pillow Book: its first words, or an open invitation; a click opens the book
                Item {
                    width: parent.width; height: 30
                    Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.08) }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Theme.ipc("journal", "open") }
                    Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - pgW.width - 12; elide: Text.ElideRight
                           text: dl.page !== "" ? dl.page.split("\n")[0] : (Theme.xia ? "The Jade Record" : "The Pillow Book")
                           color: Theme.alpha(Theme.t.text, dl.page !== "" ? 0.86 : 0.55); font.family: Theme.display; font.pixelSize: 14 }
                    Text { id: pgW; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                           text: dl.page !== "" ? "TODAY" : "UNWRITTEN"
                           color: Theme.alpha(Theme.gold, dl.page !== "" ? 0.9 : 0.6); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 2 }
                }
                Repeater {
                    model: Theme.desk.events.slice(0, 2)
                    Item {
                        required property var modelData; required property int index
                        width: parent.width; height: 30
                        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.08) }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.title; color: Theme.alpha(Theme.t.text, 0.86)
                               font.family: Theme.display; font.pixelSize: 14; width: parent.width - wh.width - 12; elide: Text.ElideRight }
                        Text { id: wh; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: modelData.when.toUpperCase()
                               color: Theme.gold; font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 2 }
                    }
                }
            }
        }

        LedgerBox {
            id: b2
            num: "02"; label: "SOUND"; aside: !dl.p ? "QUIET" : (dl.p.isPlaying ? "PLAYING" : "PAUSED")
            width: 330; height: dl.bh
            Column {
                width: parent.width; spacing: 16
                Row {
                    spacing: 16; width: parent.width
                    Item {
                        width: 84; height: 84
                        Image { anchors.fill: parent; anchors.margins: 1; fillMode: Image.PreserveAspectCrop; sourceSize.height: 240; smooth: true
                                source: dl.p && dl.p.trackArtUrl ? dl.p.trackArtUrl : Theme.t.keyart; opacity: dl.p ? 1 : 0.55 }
                        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.gold, 0.45) }
                    }
                    Column {
                        width: parent.width - 100; spacing: 5; anchors.verticalCenter: parent.verticalCenter
                        Text { width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; color: Theme.t.text
                               font.family: Theme.display; font.pixelSize: 19; lineHeight: 1.05
                               text: !dl.p ? "Nothing playing" : (dl.p.trackTitle || "Untitled") }
                        Text { width: parent.width; elide: Text.ElideRight; color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.display; font.pixelSize: 13
                               text: !dl.p ? "Play anything; it lands here" : (dl.p.trackArtist || dl.p.identity) }
                    }
                }
                Item {
                    width: parent.width; height: 26
                    Rectangle { y: 4; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.16) }
                    Rectangle { y: 3.5; width: Math.max(2, parent.width * dl.frac); height: 2; color: Theme.accent }
                    Rectangle { x: Math.max(0, parent.width * dl.frac - 3.5); y: 1; width: 7; height: 7; radius: Theme.xia ? 3.5 : 0
                                rotation: Theme.xia ? 0 : 45; color: Theme.gold }
                    Text { y: 13; text: dl.p ? dl.mmss(dl.p.position) : "0:00"; color: Theme.alpha(Theme.t.text, 0.42); font.family: Theme.display; font.pixelSize: 11 }
                    Text { y: 13; anchors.right: parent.right; text: dl.p ? dl.mmss(dl.p.length) : "0:00"; color: Theme.alpha(Theme.t.text, 0.42); font.family: Theme.display; font.pixelSize: 11 }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 34
                    Repeater {
                        model: ["PREV", dl.p && dl.p.isPlaying ? "PAUSE" : "PLAY", "NEXT"]
                        Text {
                            required property string modelData; required property int index
                            text: modelData; font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 4
                            color: index === 1 ? Theme.accent : Theme.alpha(Theme.t.text, tm.containsMouse ? 0.9 : 0.5)
                            opacity: dl.p ? 1 : 0.5
                            MouseArea { id: tm; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; enabled: !!dl.p
                                        onClicked: index === 0 ? dl.p.previous() : index === 1 ? dl.p.togglePlaying() : dl.p.next() }
                        }
                    }
                }
            }
        }

        LedgerBox {
            id: b3
            num: "03"; label: "MACHINE"
            width: 280; height: dl.bh
            Column {
                width: parent.width; spacing: 6
                LedgerMeter { k: "Processor"; v: dl.cpu }
                LedgerMeter { k: "Memory"; v: dl.mem }
                LedgerMeter { k: "Disk"; v: dl.disk }
                Item { width: 1; height: 4 }
                Text { text: dl.weather !== "" ? dl.weather : Theme.sky.word ? Theme.sky.place + "  " + Theme.sky.temp + "  \u00b7  " + Theme.sky.word : dl.power; color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 1 }
            }
        }
    }
}
