// The Pillow Book's card (Tianxia: The Jade Record), the same in both sessions: the flagship shell (Journal.qml)
// and Tenka Lite (/usr/share/tenka/journal/LiteJournal.qml). A few lines a day: today's page on ruled hairlines
// under the day's season from the almanac, and the earlier days down the right (a year ago today first, when it
// was written). tenka-journal keeps the pages (set `s` from `tenka-journal state`); this card only asks: saveAsked
// while writing (after a pause) and when it closes. Esc keeps the page and closes, Ctrl+Enter the same,
// Ctrl+Up / Ctrl+Down walk the earlier days (read only), Esc on an earlier day comes back to today.
// Pure QtQuick. Flat, no glow.
import QtQuick

FocusScope {
    id: card
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#d8412f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property bool xia: false
    property var s: ({ title: "", label: "", text: "", season: "", count: 0, limit: 800, ago: null, entries: [] })
    property int sel: -1                         // -1: today's page; else an index into `days`
    property bool dirty: false
    readonly property var days: (s.ago ? [Object.assign({ ago: true }, s.ago)] : []).concat((s.entries || []).filter(e => !s.ago || e.date !== s.ago.date))
    readonly property var shown: sel >= 0 && sel < days.length ? days[sel] : null
    readonly property real rule: Math.max(20, fm.lineSpacing)   // one hairline under each line of the page
    FontMetrics { id: fm; font.family: card.face; font.pixelSize: 18 }
    width: 780; height: 452
    signal dismissed()
    signal saveAsked(string page)

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    // a new `s` refreshes the page only while nothing unsaved is on it
    onSChanged: if (!dirty) page.text = s.text || ""
    function keep() { if (dirty) { card.saveAsked(page.text); dirty = false } }
    function close() { keep(); sel = -1; card.dismissed() }
    function begin() { dirty = false; sel = -1; page.text = s.text || ""; page.cursorPosition = page.length; page.forceActiveFocus() }

    Timer { id: pause; interval: 900; onTriggered: card.keep() }

    Rectangle { anchors.fill: parent; radius: card.radius; color: card.alpha(card.base, 0.96)
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }
    MouseArea { anchors.fill: parent; onClicked: { card.sel = -1; page.forceActiveFocus() } }

    // the heading: the book's name, a hairline, the day
    Row {
        x: 36; y: 30; spacing: 14
        Text { text: (card.s.title || (card.xia ? "The Jade Record" : "The Pillow Book")).toUpperCase(); color: card.gold
               font.family: card.face; font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 40; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        Text { text: card.shown ? card.shown.long : card.s.label; color: card.alpha(card.text, 0.62); font.family: card.uiFace
               font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
    }
    Text { anchors.right: parent.right; anchors.rightMargin: 36; y: 31
           text: card.s.count === 1 ? "one day kept" : card.s.count > 1 ? card.s.count + " days kept" : ""
           color: card.alpha(card.text, 0.34); font.family: card.uiFace; font.pixelSize: 12 }

    // today's page (or an earlier one, read only)
    Item {
        id: leaf
        x: 36; y: 70; width: 452; height: card.height - y - 60
        Text { id: season; width: parent.width; elide: Text.ElideRight
               text: card.shown ? (card.shown.ago ? (card.xia ? "A year ago, this day" : "A year ago today") + (card.shown.term ? "  \u00b7  " + card.shown.term : "")
                                                  : card.shown.term)
                                : card.s.season
               color: card.alpha(card.gold, 0.85); font.family: card.uiFace; font.pixelSize: 13 }
        Item {
            id: ruled
            y: 34; width: parent.width; height: parent.height - y
            clip: true
            Repeater {
                model: Math.max(0, Math.floor((ruled.height - page.topPadding) / card.rule))
                Rectangle { required property int index; y: page.topPadding + (index + 1) * card.rule - fm.descent * 0.35; width: ruled.width; height: 1
                            color: card.alpha(card.text, index === 0 ? 0.10 : 0.07) }
            }
            Flickable {
                id: flick
                anchors.fill: parent; contentHeight: page.contentHeight; boundsBehavior: Flickable.StopAtBounds
                contentY: Math.max(0, page.cursorRectangle.y + card.rule - height)
                interactive: false
                TextEdit {
                    id: page
                    width: ruled.width; focus: true
                    visible: !card.shown
                    color: card.text; selectionColor: card.alpha(card.accent, 0.30); selectedTextColor: card.text
                    font.family: card.face; font.pixelSize: 18
                    wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText
                    // the text sits on the hairlines: one rule per line (the face's own line spacing)
                    topPadding: 4; leftPadding: 2
                    cursorDelegate: Rectangle { width: 1; color: card.gold }
                    onTextChanged: {
                        if (length > card.s.limit) { const p = cursorPosition; text = text.slice(0, card.s.limit); cursorPosition = Math.min(p, length) }
                        if (activeFocus || card.dirty) { card.dirty = text !== (card.s.text || ""); pause.restart() }
                    }
                    Keys.onPressed: e => {
                        const ctl = e.modifiers & Qt.ControlModifier
                        if (e.key === Qt.Key_Escape) { if (card.sel >= 0) card.sel = -1; else card.close() }
                        else if (ctl && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) card.close()
                        else if (ctl && e.key === Qt.Key_Up) { card.keep(); card.sel = Math.min(card.days.length - 1, card.sel + 1) }
                        else if (ctl && e.key === Qt.Key_Down) card.sel = Math.max(-1, card.sel - 1)
                        else if (card.sel >= 0) { e.accepted = true; return }   // an earlier day is read only
                        else return
                        e.accepted = true
                    }
                }
                Text {
                    visible: !!card.shown
                    width: ruled.width; wrapMode: Text.Wrap; topPadding: 4; leftPadding: 2
                    text: card.shown ? card.shown.text : ""
                    color: card.alpha(card.text, 0.78); font.family: card.face; font.pixelSize: 18
                    lineHeight: card.rule; lineHeightMode: Text.FixedHeight
                }
            }
            Text {
                visible: !card.shown && page.length === 0
                x: 2; y: 4; color: card.alpha(card.text, 0.30); font.family: card.face; font.pixelSize: 18
                text: card.xia ? "What did the day teach?" : "What was worth noting today?"
            }
        }
    }
    // the foot: the keys, and how much of the page is left
    Text { x: 36; y: card.height - 38
           text: card.shown ? "Esc  back to today" : "Esc  keep and close     Ctrl + \u2191 \u2193  earlier days"
           color: card.alpha(card.text, 0.34); font.family: card.uiFace; font.pixelSize: 12 }
    Text { x: 36 + leaf.width - width; y: card.height - 38
           visible: !card.shown && page.length > card.s.limit * 0.6
           text: (card.s.limit - page.length) + " left"
           color: card.alpha(page.length >= card.s.limit ? card.accent : card.text, 0.42); font.family: card.uiFace; font.pixelSize: 12 }

    Rectangle { x: 514; y: 72; width: 1; height: card.height - 72 - 44; color: card.alpha(card.gold, 0.22) }

    // the earlier days
    Item {
        x: 538; y: 70; width: card.width - x - 32; height: card.height - y - 50
        Text { text: card.xia ? "BEFORE" : "EARLIER"; color: card.gold; font.family: card.face; font.pixelSize: 11; font.letterSpacing: 4 }
        Text { y: 34; width: parent.width; visible: card.days.length === 0; wrapMode: Text.Wrap
               text: card.xia ? "The first slip is today's." : "The first page is today's."
               color: card.alpha(card.text, 0.36); font.family: card.uiFace; font.pixelSize: 13 }
        ListView {
            id: list
            y: 30; width: parent.width; height: parent.height - y; clip: true
            model: card.days; spacing: 4; boundsBehavior: Flickable.StopAtBounds
            currentIndex: card.sel
            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: Item {
                id: row
                required property var modelData; required property int index
                readonly property bool on: card.sel === index
                width: list.width; height: 54
                Rectangle { x: 0; y: 6; width: 2; height: 40; color: card.accent; visible: row.on }
                Text { x: 14; y: 6; width: parent.width - 14 - termT.width - 8; elide: Text.ElideRight
                       text: row.modelData.ago ? (card.xia ? "A year ago, this day" : "A year ago today") : row.modelData.label
                       color: row.modelData.ago ? card.gold : card.alpha(card.text, row.on ? 0.95 : 0.80)
                       font.family: card.uiFace; font.pixelSize: 13 }
                Text { id: termT; anchors.right: parent.right; y: 8; text: row.modelData.ago ? "" : row.modelData.term
                       color: card.alpha(card.text, 0.34); font.family: card.uiFace; font.pixelSize: 11 }
                Text { x: 14; y: 27; width: parent.width - 14; elide: Text.ElideRight; maximumLineCount: 1
                       text: (row.modelData.text || "").replace(/\n/g, "  ")
                       color: card.alpha(card.text, row.on ? 0.62 : 0.46); font.family: card.face; font.pixelSize: 13 }
                Rectangle { anchors.bottom: parent.bottom; x: 14; width: parent.width - 14; height: 1; color: card.alpha(card.text, 0.06) }
                MouseArea { anchors.fill: parent; onClicked: { card.keep(); card.sel = row.on ? -1 : row.index; page.forceActiveFocus() } }
            }
        }
    }
}
