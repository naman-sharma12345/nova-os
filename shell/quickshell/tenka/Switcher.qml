// The Turn: our own Alt+Tab (Hyprland has no window switcher). Every window, most recent first, as a ruled
// ledger card: numbered in gold, the app in small caps, the title in Marcellus, the chosen one on the pack's
// brush stroke, and on the right a still of it (when the compositor can copy it) with its desk's numeral.
// Alt+Tab opens it on the window before this one; Tab / Shift+Tab walk, letting go of Alt (or ENTER) goes
// there, ESC stays. qs ipc call switcher next|prev|commit|hide. Flat: ink, one gold rule, no glow.
// The keys come from the compositor as global shortcuts (tenka:switcher-next|prev|commit), not by spawning a
// qs ipc client per key: no process start on a slow machine, and press and Alt-release arrive in order. A quick
// tap (Alt let go before the list is read) still goes to the window before this one; the card only shows when
// Alt is held past a beat, so a tap never flashes it.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: sw
    property bool open: false
    property int sel: 0
    property var wins: []
    readonly property bool onHypr: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
    readonly property string sim: Quickshell.env("TENKA_OVERVIEW_SIM") || ""
    property int pendingStep: 1
    property bool loaded: false        // the window list has been read for this opening
    property bool commitPending: false // Alt was let go before the list was read
    property bool shown: false         // the card shows only once Alt is held past a beat
    property double lastGo: 0
    property double lateRelease: 0     // an Alt-release that arrived before the opening (ipc race only)
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-switcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "switcher"
        function next(): void { sw.step(1) }
        function prev(): void { sw.step(-1) }
        function commit(): void { sw.letGo() }
        function hide(): void { sw.open = false }
        function state(): string { return (sw.open ? "open" : "closed") + (sw.shown ? " shown" : "") + (sw.loaded ? " loaded" : "") + " sel=" + sw.sel + " wins=" + sw.wins.length }
    }
    GlobalShortcut { appid: "tenka"; name: "switcher-next"; description: "The Turn: next window"; onPressed: sw.step(1) }
    GlobalShortcut { appid: "tenka"; name: "switcher-prev"; description: "The Turn: previous window"; onPressed: sw.step(-1) }
    GlobalShortcut { appid: "tenka"; name: "switcher-commit"; description: "The Turn: go (Alt let go)"
                     onPressed: sw.letGo(); onReleased: sw.letGo() }
    onOpenChanged: { Theme.hush = open; if (!open) { shown = false; commitPending = false } }
    Timer { interval: 140; running: sw.open && !sw.shown; onTriggered: sw.shown = true }
    function step(d) {
        if (!open) {
            pendingStep = d; loaded = false; commitPending = (Date.now() - lateRelease) < 1500; lateRelease = 0
            readQ.running = true; open = true; keys.forceActiveFocus(); return
        }
        if (wins.length) sel = (sel + d + wins.length) % wins.length
    }
    function letGo() {
        if (open) { if (loaded) go(); else commitPending = true }
        else if (Date.now() - lastGo > 400) lateRelease = Date.now()
    }
    Process {
        id: readQ
        command: sw.sim !== "" ? ["sh", "-c", "cat \"$1\"", "sh", sw.sim]
               : ["sh", "-c", "printf '{\"c\":'; hyprctl clients -j 2>/dev/null || printf '[]'; printf '}'"]
        stdout: StdioCollector { onStreamFinished: sw.parse(text) }
    }
    function parse(t) {
        let d = {}
        try { d = JSON.parse(t) } catch (e) { d = {} }
        wins = (d.c || []).filter(c => c.workspace && c.workspace.id > 0 && c.mapped !== false && !c.hidden)
                          .sort((a, b) => (a.focusHistoryID || 0) - (b.focusHistoryID || 0))
        sel = wins.length > 1 ? (pendingStep > 0 ? 1 : wins.length - 1) : 0
        loaded = true
        if (commitPending && open) go()
    }
    readonly property var cur: wins.length ? wins[Math.min(sel, wins.length - 1)] : null
    readonly property var numerals: ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    function nice(c) { const s = (c["class"] || c.initialClass || "window").split(".").pop(); return s.replace(/[-_]/g, " ") }
    function topLevelOf(c) {
        if (!onHypr || !c) return null
        const a = String(c.address || "").replace(/^0x/, "")
        return Hyprland.toplevels.values.find(t => String(t.address).replace(/^0x/, "") === a) || null
    }
    Process { id: actQ; property var cmd: []; command: cmd }
    function go() {
        if (!open) return
        const c = cur; open = false; lastGo = Date.now()
        if (!c || sim !== "") return
        actQ.cmd = ["sh", "-c", "hyprctl dispatch \"$1\" | grep -qx ok || hyprctl dispatch focuswindow address:$2", "sh",
                    "hl.dsp.focus({ window = \"address:" + c.address + "\" })", c.address]
        actQ.running = true
    }

    MouseArea { anchors.fill: parent; enabled: sw.open; onClicked: sw.open = false }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 900; height: Math.min(560, 132 + Math.max(4, Math.min(8, sw.wins.length)) * 46)
        radius: Theme.ledgerR
        color: Theme.alpha(Theme.t.base, 0.96)
        border.width: 1; border.color: Theme.alpha(Theme.gold, 0.35)
        opacity: sw.open && sw.shown ? 1 : 0
        scale: sw.open || Theme.perf ? 1 : 0.985
        Behavior on opacity { NumberAnimation { duration: Theme.perf ? 0 : 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.perf ? 0 : 160; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }

        Row {
            x: 34; y: 30; spacing: 14
            Text { text: "THE TURN"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 64; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            Text { text: sw.wins.length + (sw.wins.length === 1 ? " window" : " windows"); color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { x: 470; y: 70; width: 1; height: parent.height - 104; color: Theme.alpha(Theme.t.text, 0.1) }

        ListView {
            id: list
            x: 22; y: 70; width: 430; height: parent.height - 100
            clip: true; interactive: false
            model: sw.wins
            currentIndex: sw.sel
            highlightMoveDuration: 0
            preferredHighlightBegin: height / 2 - 23; preferredHighlightEnd: height / 2 + 23
            highlightRangeMode: ListView.ApplyRange
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: index === sw.sel
                width: list.width; height: 46
                Image { visible: row.on; source: Theme.t.stroke; width: 430 / 0.81 * 0.98; height: 46; smooth: true; x: -6 }
                Text {
                    x: 14; width: 26; anchors.verticalCenter: parent.verticalCenter
                    text: String(row.index + 1); color: row.on ? "#fff8ec" : Theme.gold
                    font.family: Theme.display; font.pixelSize: 13
                }
                Column {
                    x: 46; width: parent.width - 120; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: sw.nice(row.modelData).toUpperCase(); color: row.on ? Theme.alpha("#fff8ec", 0.85) : Theme.gold
                        font.family: Theme.display; font.pixelSize: 9; font.letterSpacing: 2.5
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: row.modelData.title || sw.nice(row.modelData); color: row.on ? "#fff8ec" : Theme.alpha(Theme.t.text, 0.78)
                        font.family: Theme.ui; font.pixelSize: 15
                    }
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    text: sw.numerals[row.modelData.workspace.id] || String(row.modelData.workspace.id)
                    color: row.on ? Theme.alpha("#fff8ec", 0.8) : Theme.alpha(Theme.t.text, 0.4)
                    font.family: Theme.display; font.pixelSize: 13
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: sw.sel = row.index; onClicked: { sw.sel = row.index; sw.go() } }
            }
        }

        // the chosen one, read whole: a still if the compositor can copy it, else its name set large
        Item {
            id: pane
            x: 494; y: 70; width: parent.width - 494 - 30; height: parent.height - 104
            readonly property var tl: sw.topLevelOf(sw.cur)
            Rectangle {
                id: shot
                width: parent.width; height: Math.round(width * 9 / 16)
                radius: Math.max(3, Theme.ledgerR / 2)
                color: Theme.t.surface
                border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.12)
                clip: true
                Image { anchors.fill: parent; anchors.margins: 1; source: Theme.t.wallpaper; fillMode: Image.PreserveAspectCrop; sourceSize.width: 420; opacity: 0.32; asynchronous: true }
                ScreencopyView {
                    anchors.fill: parent; anchors.margins: 1
                    visible: pane.tl !== null && hasContent
                    captureSource: pane.tl ? pane.tl.wayland : null
                    live: false
                }
                Column {
                    visible: pane.tl === null
                    anchors.centerIn: parent; spacing: 6; width: parent.width - 40
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                           text: sw.cur ? sw.nice(sw.cur).toUpperCase() : ""; color: Theme.gold
                           font.family: Theme.display; font.pixelSize: 16; font.letterSpacing: 5 }
                    Rectangle { width: 40; height: 1; color: Theme.alpha(Theme.gold, 0.6); anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
            Text {
                anchors.top: shot.bottom; anchors.topMargin: 16; width: parent.width
                text: sw.cur ? (sw.cur.title || sw.nice(sw.cur)) : ""; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                color: Theme.t.text; font.family: Theme.display; font.pixelSize: 18
            }
            Text {
                anchors.bottom: parent.bottom; width: parent.width
                text: sw.cur ? ("ON DESK " + (sw.numerals[sw.cur.workspace.id] || sw.cur.workspace.id) + (sw.cur.floating ? "  ·  FLOATING" : "")) : ""
                color: Theme.alpha(Theme.gold, 0.85); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 4
            }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 30; y: 32
            text: "LET GO OF ALT  ↵"; color: Theme.alpha(Theme.t.text, 0.42); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3
        }
    }

    Item {
        id: keys
        focus: sw.open
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) sw.open = false
            else if (e.key === Qt.Key_Backtab || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier)) || e.key === Qt.Key_Up) sw.step(-1)
            else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Down) sw.step(1)
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) sw.go()
            else return
            e.accepted = true
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_Meta) { sw.letGo(); e.accepted = true } }
    }
}
