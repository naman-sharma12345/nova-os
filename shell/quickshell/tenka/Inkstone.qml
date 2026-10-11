// The Inkstone (Tianxia: The Brush): our own glyph picker, Super+. , the thing Linux desktops lack and other
// systems keep behind a key: every emoji, the marks (arrows, maths, money, typographer's signs) and the ink
// shelf (CJK punctuation and a few seal characters with their readings), found by name as you type. One flat
// ledger card: shelves in small caps, a quiet grid, the chosen glyph large with its name in Marcellus. ENTER
// places it in the window behind (and on the clipboard), TAB walks the shelves, ESC closes. The shelves come
// from tenka-glyphs (Unicode's own names); the last thirty placed sit on LATELY.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: ink
    property bool open: false
    property var all: []
    property var shelves: ["lately", "faces", "people", "nature", "food", "places", "things", "signs", "marks", "ink"]
    property var lately: []
    property int shelf: 1
    property int sel: 0
    property bool fresh: false     // just opened: LATELY leads once the shelves arrive, if anything was placed
    readonly property string query: field.text.trim().toLowerCase()
    readonly property var shown: {
        if (query !== "") {
            const w = query.split(/\s+/)
            return all.filter(x => w.every(t => x.n.indexOf(t) >= 0)).slice(0, 360)
        }
        const s = shelves[shelf]
        if (s === "lately") return lately.map(g => all.find(x => x.g === g) || { g: g, n: "", s: "lately" })
        return all.filter(x => x.s === s)
    }
    readonly property var cur: shown.length ? shown[Math.min(sel, shown.length - 1)] : null

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-inkstone"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "glyphs"
        function open(): void { ink.reveal() }
        function hide(): void { ink.open = false }
        function toggle(): void { ink.open ? (ink.open = false) : ink.reveal() }
        function state(): string { return (ink.open ? "open" : "closed") + " glyphs=" + ink.all.length + " shelf=" + ink.shelves[ink.shelf]
                                          + " shown=" + ink.shown.length + (ink.cur ? " sel=" + ink.cur.n : "") }
    }
    GlobalShortcut { appid: "tenka"; name: "glyphs"; description: "The Inkstone: find and place a glyph"
                     onPressed: ink.open ? (ink.open = false) : ink.reveal() }
    onOpenChanged: Theme.hush = open
    onShownChanged: sel = Math.min(sel, Math.max(0, shown.length - 1))

    Process {
        id: listP
        command: ["tenka-glyphs", "list"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const d = JSON.parse(text)
                ink.all = d.glyphs; ink.lately = d.lately
                if (d.shelves) ink.shelves = d.shelves
                const sq = Quickshell.env("TENKA_GLYPH_SIM_SHELF")
                if (sq) ink.shelf = Math.max(0, ink.shelves.indexOf(sq))
                else if (ink.fresh) ink.shelf = ink.lately.length ? 0 : 1
                if (Quickshell.env("TENKA_GLYPH_SIM_SEL")) ink.sel = parseInt(Quickshell.env("TENKA_GLYPH_SIM_SEL"))
            } catch (e) {}
        } }
    }
    Process { id: placeP; property string g: ""; command: ["tenka-glyphs", "place", g] }

    function reveal() {
        field.text = Quickshell.env("TENKA_GLYPH_SIM_QUERY") || ""
        sel = 0; shelf = lately.length ? 0 : 1; fresh = true
        open = true; listP.running = true
        field.forceActiveFocus()
    }
    function place() {
        if (!cur) return
        placeP.g = cur.g; open = false; placeP.running = true
    }
    function walk(d) { fresh = false; field.text = ""; shelf = (shelf + d + shelves.length) % shelves.length; sel = 0 }

    // the desk steps back: one flat wash
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, ink.open ? 0.55 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: ink.open; onClicked: ink.open = false }

    Item {
        id: card
        width: 700; height: 646
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, parent.height * 0.18) + (ink.open ? 0 : 16)
        opacity: ink.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, 0.95)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.4) }
        MouseArea { anchors.fill: parent }

        Row {
            x: 34; y: 30; spacing: 14
            Text { text: Theme.xia ? "THE BRUSH" : "THE INKSTONE"; color: Theme.gold; font.family: Theme.display
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 64; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            Text { text: ink.query !== "" ? ink.shown.length + " found" : ink.all.length + " glyphs"
                   color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        TextField {
            id: field
            x: 30; y: 62; width: parent.width - 60; height: 50
            background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                               color: field.activeFocus ? Theme.accent : Theme.alpha(Theme.gold, 0.4) } }
            placeholderText: "find by name: moon, arrow, tea, heaven …"
            placeholderTextColor: Theme.alpha(Theme.t.text, 0.38)
            color: Theme.t.text; font.family: Theme.display; font.pixelSize: 20; leftPadding: 4
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            onTextChanged: ink.sel = 0
            Keys.onPressed: e => {
                const n = ink.shown.length, c = grid.cols
                if (e.key === Qt.Key_Escape) { if (field.text !== "") field.text = ""; else ink.open = false }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) ink.place()
                else if (e.key === Qt.Key_Tab) ink.walk(1)
                else if (e.key === Qt.Key_Backtab) ink.walk(-1)
                else if (e.key === Qt.Key_Right) { if (n) ink.sel = Math.min(n - 1, ink.sel + 1) }
                else if (e.key === Qt.Key_Left) { if (n) ink.sel = Math.max(0, ink.sel - 1) }
                else if (e.key === Qt.Key_Down) { if (n) ink.sel = Math.min(n - 1, ink.sel + c) }
                else if (e.key === Qt.Key_Up) { if (n) ink.sel = Math.max(0, ink.sel - c) }
                else return
                e.accepted = true
            }
        }
        Row {
            id: tabs
            x: 34; y: 128; spacing: 20
            opacity: ink.query === "" ? 1 : 0.35
            Repeater {
                model: ink.shelves
                Text {
                    required property string modelData
                    required property int index
                    readonly property bool on: index === ink.shelf && ink.query === ""
                    text: modelData.toUpperCase(); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3
                    color: on ? Theme.gold : Theme.alpha(Theme.t.text, 0.5)
                    Rectangle { visible: parent.on; anchors.top: parent.bottom; anchors.topMargin: 5; width: parent.width - 3; height: 1; color: Theme.gold }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                onClicked: { ink.fresh = false; field.text = ""; ink.shelf = parent.index; ink.sel = 0; field.forceActiveFocus() } }
                }
            }
        }
        Rectangle { x: 30; y: 156; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.35) }

        GridView {
            id: grid
            readonly property int cols: 12
            x: 30; y: 166; width: parent.width - 60; height: 6 * cellHeight
            cellWidth: width / cols; cellHeight: 52
            clip: true; boundsBehavior: Flickable.StopAtBounds
            model: ink.shown
            currentIndex: ink.sel
            highlightFollowsCurrentItem: true
            highlightMoveDuration: Theme.perf ? 0 : 90
            highlight: Item {
                Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 3; color: Theme.alpha(Theme.accent, 0.16) }
                Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 3; anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 18; height: 2; color: Theme.accent }
            }
            delegate: Item {
                required property var modelData
                required property int index
                width: grid.cellWidth; height: grid.cellHeight
                Text { anchors.centerIn: parent; text: parent.modelData.g; font.pixelSize: 27
                       font.family: parent.modelData.s === "ink" || parent.modelData.s === "marks" ? Theme.display : Theme.ui
                       color: Theme.t.text }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { ink.sel = parent.index; ink.place() } }
            }
        }
        Text {
            visible: ink.shown.length === 0
            x: 34; y: 190; width: parent.width - 68; wrapMode: Text.WordWrap
            text: ink.query !== "" ? "No glyph goes by that name." : ink.shelves[ink.shelf] === "lately" ? "Nothing placed yet." : "Reading the shelves …"
            color: Theme.alpha(Theme.t.text, 0.62); font.family: Theme.display; font.pixelSize: 17
        }
        Rectangle { x: 30; y: grid.y + grid.height + 8; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.25) }
        Row {
            x: 34; y: grid.y + grid.height + 20; spacing: 18
            Text { text: ink.cur ? ink.cur.g : ""; font.pixelSize: 40; color: Theme.t.text; anchors.verticalCenter: parent.verticalCenter
                   font.family: ink.cur && (ink.cur.s === "ink" || ink.cur.s === "marks") ? Theme.display : Theme.ui }
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Text { text: ink.cur ? ink.cur.n : ""; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 18
                       width: 520; elide: Text.ElideRight }
                Text { text: ink.cur ? ink.cur.s.toUpperCase() + (ink.cur.g.length ? "   ·   U+" + ink.cur.g.codePointAt(0).toString(16).toUpperCase() : "") : ""
                       color: Theme.alpha(Theme.gold, 0.8); font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3 }
            }
        }
        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 22
            text: "ENTER  to place      TAB  next shelf      ARROWS  to move      ESC  to close"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
    }
}
