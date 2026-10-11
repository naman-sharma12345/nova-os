// Notifications: ruled notes that slide in at the top right: ink, one gold rule, the sender set into the
// top edge, the words, and its actions as small-caps words (vermilion for the first).
// A soft koto / guzheng note plays unless Stillness (do-not-disturb) is on.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick

PanelWindow {
    id: nw
    anchors { top: true; right: true }
    margins { top: 66; right: 14 }
    implicitWidth: 420
    implicitHeight: Math.max(1, stack.height + 30)
    color: "transparent"
    visible: list.count > 0 || nw.summary !== null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-notify"

    ListModel { id: list }
    // Focus holds what arrives (critical still comes through). When focus ends the held notes come back as
    // one quiet card: how many, from whom, and the newest line. Clicking it opens nothing; it just goes.
    property var held: []
    function hold(n) { const h = held.slice(); h.push({ app: n.appName || "Tenka", summary: n.summary || "" }); held = h }
    property bool wasFocus: false
    property var summary: null
    Connections {
        target: Theme
        function onFocusChanged() {
            if (Theme.focus) { nw.wasFocus = true; return }
            if (!nw.wasFocus) return
            nw.wasFocus = false
            if (nw.held.length === 0) return
            const apps = []
            for (const h of nw.held) if (apps.indexOf(h.app) < 0) apps.push(h.app)
            const last = nw.held[nw.held.length - 1]
            nw.summary = { count: nw.held.length,
                           from: apps.slice(0, 3).join("  \u00b7  ") + (apps.length > 3 ? "  \u00b7  +" + (apps.length - 3) : ""),
                           last: last.summary }
            nw.held = []
            Theme.chime("notify")
        }
    }
    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true; bodySupported: true; imageSupported: true; bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true;
            Theme.unread += 1;
            if (Theme.focus && n.urgency !== NotificationUrgency.Critical) { nw.hold(n); return }
            if (Theme.stillness && n.urgency !== NotificationUrgency.Critical) return;
            list.insert(0, { n: n, born: Date.now() });
            if (list.count > 4) list.remove(4);
            Theme.chime("notify");
        }
    }

    Column {
        id: stack
        x: 10; y: 0; width: 400; spacing: 12
        move: Transition { NumberAnimation { properties: "y"; duration: 260; easing.type: Easing.OutCubic } }
        // the focus summary: the same ruled note, its sender word FOCUS, one line for the count and one for who
        Item {
            id: sumCard
            visible: nw.summary !== null
            width: 400; height: visible ? sumCol.height + 44 : 0
            opacity: visible ? 1 : 0
            Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 260 } }
            Timer { running: sumCard.visible; interval: 12000; onTriggered: nw.summary = null }
            readonly property color rc: Theme.alpha(Theme.gold, 0.42)
            readonly property int rr: Theme.ledgerR
            readonly property var cuts: [0, sumWord.x - 8, sumWord.x + sumWord.width + 8, width]
            Rectangle { anchors.fill: parent; anchors.topMargin: 8; radius: sumCard.rr; color: Theme.alpha(Theme.t.base, Theme.selfBlur ? 0.92 : 0.80) }
            Item {   // sides and bottom
                y: 8 + sumCard.rr; width: sumCard.width; height: Math.max(0, sumCard.height - y); clip: true
                Rectangle { y: -sumCard.rr; width: sumCard.width; height: sumCard.height - 8; radius: sumCard.rr
                            color: "transparent"; border.width: 1; border.color: sumCard.rc }
            }
            Repeater {   // the top rule, opened around the word
                model: 2
                Item {
                    required property int index
                    x: sumCard.cuts[index * 2]; y: 8; width: Math.max(0, sumCard.cuts[index * 2 + 1] - x); height: sumCard.rr; clip: true
                    Rectangle { x: -parent.x; width: sumCard.width; height: sumCard.height - 8; radius: sumCard.rr
                                color: "transparent"; border.width: 1; border.color: sumCard.rc }
                }
            }
            Text { id: sumWord; x: 22; y: 1; height: 14; verticalAlignment: Text.AlignVCenter; text: "FOCUS"; color: Theme.gold
                   font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
            Column {
                id: sumCol
                x: 20; y: 26; width: parent.width - 40; spacing: 5
                Text { text: nw.summary ? (nw.summary.count === 1 ? "One note waited while you were in focus" : nw.summary.count + " notes waited while you were in focus") : ""
                       color: Theme.t.text; font.family: Theme.display; font.pixelSize: 17; width: parent.width; elide: Text.ElideRight }
                Text { text: nw.summary ? nw.summary.from.toUpperCase() : ""; color: Theme.alpha(Theme.gold, 0.85); font.family: Theme.display
                       font.pixelSize: 11; font.letterSpacing: 3; width: parent.width; elide: Text.ElideRight }
                Text { text: nw.summary ? nw.summary.last : ""; visible: text !== ""; color: Theme.alpha(Theme.t.text, 0.66); font.family: Theme.ui
                       font.pixelSize: 13; width: parent.width; elide: Text.ElideRight }
            }
            MouseArea { anchors.fill: parent; z: -1; onClicked: nw.summary = null }
        }
        Repeater {
            model: list
            delegate: Item {
                // a ruled note (the control center's language): ink, one gold rule, the sender set into
                // the top edge, the words, the actions as small-caps words. No tile, no glow.
                id: card
                required property var n
                required property int index
                width: 400; height: body.height + 44
                property real slide: 40
                transform: Translate { x: card.slide }
                opacity: 0
                Component.onCompleted: { slide = 0; opacity = 1 }
                Behavior on slide { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Timer { running: card.n && card.n.urgency !== NotificationUrgency.Critical; interval: 7000; onTriggered: list.remove(card.index) }
                readonly property bool crit: !!card.n && card.n.urgency === NotificationUrgency.Critical

                // the frame: ink fill, then one 1px rule drawn in clipped pieces so the top rule opens
                // around the sender and the time (nothing painted behind them: no patch on any wallpaper)
                readonly property color rc: crit ? Theme.alpha(Theme.accent, 0.85) : Theme.alpha(Theme.gold, 0.42)
                readonly property int rr: Theme.ledgerR
                readonly property var cuts: [0, sender.x - 8, sender.x + sender.width + 8, stamp.x - 8, stamp.x + stamp.width + 8, width]
                Rectangle { anchors.fill: parent; anchors.topMargin: 8; radius: card.rr; color: Theme.alpha(Theme.t.base, Theme.selfBlur ? 0.92 : 0.80) }
                Item {   // sides and bottom
                    y: 8 + card.rr; width: card.width; height: card.height - y; clip: true
                    Rectangle { y: -card.rr; width: card.width; height: card.height - 8; radius: card.rr
                                color: "transparent"; border.width: 1; border.color: card.rc }
                }
                Repeater {   // the top rule, in three pieces around the two gaps
                    model: 3
                    Item {
                        required property int index
                        x: card.cuts[index * 2]; y: 8; width: Math.max(0, card.cuts[index * 2 + 1] - x); height: card.rr; clip: true
                        Rectangle { x: -parent.x; width: card.width; height: card.height - 8; radius: card.rr
                                    color: "transparent"; border.width: 1; border.color: card.rc }
                    }
                }
                Row {   // the sender, set into the top rule
                    id: sender; x: 22; y: 0; height: 16; spacing: 7
                    IconImage { implicitSize: 13; anchors.verticalCenter: parent.verticalCenter; visible: !!(card.n && card.n.appIcon)
                                source: card.n && card.n.appIcon ? Quickshell.iconPath(card.n.appIcon, "dialog-information") : "" }
                    Text { text: (card.n ? card.n.appName || "Tenka" : "").toUpperCase(); color: card.crit ? Theme.accent : Theme.gold
                           font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4; anchors.verticalCenter: parent.verticalCenter }
                }
                Text { id: stamp; anchors.right: parent.right; anchors.rightMargin: 22; y: 1; height: 14; verticalAlignment: Text.AlignVCenter
                       text: Theme.hm(Theme.now)
                       color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 2 }
                Row {
                    id: body
                    x: 20; y: 26; width: parent.width - 40; spacing: 14
                    Image { visible: !!(card.n && card.n.image); source: card.n ? card.n.image : ""; width: 44; height: 44
                            fillMode: Image.PreserveAspectCrop; smooth: true }
                    Column {
                        width: parent.width - (card.n && card.n.image ? 58 : 0); spacing: 5
                        Text { text: card.n ? card.n.summary : ""; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 17
                               width: parent.width; elide: Text.ElideRight }
                        Text { text: card.n ? card.n.body : ""; visible: text !== ""; color: Theme.alpha(Theme.t.text, 0.66); font.family: Theme.ui; font.pixelSize: 13
                               width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight; lineHeight: 1.1 }
                        Row {
                            visible: !!card.n && card.n.actions.length > 0; spacing: 22; topPadding: 6
                            Repeater {
                                model: card.n ? card.n.actions : []
                                Text {
                                    required property var modelData; required property int index
                                    text: modelData.text.toUpperCase(); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 3
                                    color: am.containsMouse ? Theme.t.text : (index === 0 ? Theme.accent : Theme.alpha(Theme.t.text, 0.6))
                                    MouseArea { id: am; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { modelData.invoke(); list.remove(card.index) } }
                                }
                            }
                        }
                    }
                }
                MouseArea { anchors.fill: parent; z: -1; onClicked: { if (card.n) card.n.dismiss(); list.remove(card.index) } }
            }
        }
    }
}
