// The Inkstone's card (Tianxia: The Brush), the same in both sessions: the flagship shell (Inkstone.qml, a
// layer-shell overlay) and Tenka Lite (/usr/share/tenka/inkstone/LiteInkstone.qml, a small Qt window on X11).
// Pure QtQuick + Controls, no Quickshell, so both can load it. It holds the finding and the walking; the
// window around it fetches the shelves (tenka-glyphs list), and places what `placed` hands it.
import QtQuick
import QtQuick.Controls

Item {
    id: card
    width: 700; height: 646
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#d8412f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property bool xia: false
    property bool motion: true
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
    signal placed(string glyph)
    signal dismissed()
    onShownChanged: sel = Math.min(sel, Math.max(0, shown.length - 1))

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    // a fresh opening: the query (if any), LATELY first when something was placed before
    function reset(q) { field.text = q || ""; sel = 0; shelf = lately.length ? 0 : 1; fresh = true; field.forceActiveFocus() }
    // the shelves arrived (JSON from tenka-glyphs list); simShelf/simSel are the renders' honest stand-ins
    function load(d, simShelf, simSel) {
        all = d.glyphs || []; lately = d.lately || []
        if (d.shelves) shelves = d.shelves
        if (simShelf) shelf = Math.max(0, shelves.indexOf(simShelf))
        else if (fresh) shelf = lately.length ? 0 : 1
        if (simSel) sel = parseInt(simSel)
    }
    function focusField() { field.forceActiveFocus() }
    function place() { if (cur) placed(cur.g) }
    function walk(d) { fresh = false; field.text = ""; shelf = (shelf + d + shelves.length) % shelves.length; sel = 0 }

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.95)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent }

    Row {
        x: 34; y: 30; spacing: 14
        Text { text: card.xia ? "THE BRUSH" : "THE INKSTONE"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 64; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        Text { text: card.query !== "" ? card.shown.length + " found" : card.all.length + " glyphs"
               color: card.alpha(card.text, 0.5); font.family: card.uiFace; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    TextField {
        id: field
        x: 30; y: 62; width: parent.width - 60; height: 50
        background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                           color: field.activeFocus ? card.accent : card.alpha(card.gold, 0.4) } }
        placeholderText: "find by name: moon, arrow, tea, heaven …"
        placeholderTextColor: card.alpha(card.text, 0.38)
        color: card.text; font.family: card.face; font.pixelSize: 20; leftPadding: 4
        selectionColor: card.alpha(card.accent, 0.5)
        onTextChanged: card.sel = 0
        Keys.onPressed: e => {
            const n = card.shown.length, c = grid.cols
            if (e.key === Qt.Key_Escape) { if (field.text !== "") field.text = ""; else card.dismissed() }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) card.place()
            else if (e.key === Qt.Key_Tab) card.walk(1)
            else if (e.key === Qt.Key_Backtab) card.walk(-1)
            else if (e.key === Qt.Key_Right) { if (n) card.sel = Math.min(n - 1, card.sel + 1) }
            else if (e.key === Qt.Key_Left) { if (n) card.sel = Math.max(0, card.sel - 1) }
            else if (e.key === Qt.Key_Down) { if (n) card.sel = Math.min(n - 1, card.sel + c) }
            else if (e.key === Qt.Key_Up) { if (n) card.sel = Math.max(0, card.sel - c) }
            else return
            e.accepted = true
        }
    }
    Row {
        id: tabs
        x: 34; y: 128; spacing: 20
        opacity: card.query === "" ? 1 : 0.35
        Repeater {
            model: card.shelves
            Text {
                required property string modelData
                required property int index
                readonly property bool on: index === card.shelf && card.query === ""
                text: modelData.toUpperCase(); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 3
                color: on ? card.gold : card.alpha(card.text, 0.5)
                Rectangle { visible: parent.on; anchors.top: parent.bottom; anchors.topMargin: 5; width: parent.width - 3; height: 1; color: card.gold }
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                            onClicked: { card.fresh = false; field.text = ""; card.shelf = parent.index; card.sel = 0; field.forceActiveFocus() } }
            }
        }
    }
    Rectangle { x: 30; y: 156; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.35) }

    GridView {
        id: grid
        readonly property int cols: 12
        x: 30; y: 166; width: parent.width - 60; height: 6 * cellHeight
        cellWidth: width / cols; cellHeight: 52
        clip: true; boundsBehavior: Flickable.StopAtBounds
        model: card.shown
        currentIndex: card.sel
        highlightFollowsCurrentItem: true
        highlightMoveDuration: card.motion ? 90 : 0
        highlight: Item {
            Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 3; color: card.alpha(card.accent, 0.16) }
            Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 3; anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 18; height: 2; color: card.accent }
        }
        delegate: Item {
            required property var modelData
            required property int index
            width: grid.cellWidth; height: grid.cellHeight
            Text { anchors.centerIn: parent; text: parent.modelData.g; font.pixelSize: 27
                   font.family: parent.modelData.s === "ink" || parent.modelData.s === "marks" ? card.face : card.uiFace
                   color: card.text }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { card.sel = parent.index; card.place() } }
        }
    }
    Text {
        visible: card.shown.length === 0
        x: 34; y: 190; width: parent.width - 68; wrapMode: Text.WordWrap
        text: card.query !== "" ? "No glyph goes by that name." : card.shelves[card.shelf] === "lately" ? "Nothing placed yet." : "Reading the shelves …"
        color: card.alpha(card.text, 0.62); font.family: card.face; font.pixelSize: 17
    }
    Rectangle { x: 30; y: grid.y + grid.height + 8; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.25) }
    Row {
        x: 34; y: grid.y + grid.height + 20; spacing: 18
        Text { text: card.cur ? card.cur.g : ""; font.pixelSize: 40; color: card.text; anchors.verticalCenter: parent.verticalCenter
               font.family: card.cur && (card.cur.s === "ink" || card.cur.s === "marks") ? card.face : card.uiFace }
        Column {
            anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Text { text: card.cur ? card.cur.n : ""; color: card.text; font.family: card.face; font.pixelSize: 18
                   width: 520; elide: Text.ElideRight }
            Text { text: card.cur ? card.cur.s.toUpperCase() + (card.cur.g.length ? "   ·   U+" + card.cur.g.codePointAt(0).toString(16).toUpperCase() : "") : ""
                   color: card.alpha(card.gold, 0.8); font.family: card.face; font.pixelSize: 10; font.letterSpacing: 3 }
        }
    }
    Text {
        x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 22
        text: "ENTER  to place      TAB  next shelf      ARROWS  to move      ESC  to close"
        color: card.alpha(card.text, 0.45); font.family: card.face; font.pixelSize: 12; font.letterSpacing: 2
    }
}
