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
    visible: list.count > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-notify"

    ListModel { id: list }
    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true; bodySupported: true; imageSupported: true; bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true;
            Theme.unread += 1;
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

                Rectangle { anchors.fill: parent; anchors.topMargin: 8; radius: 6; color: Theme.alpha(Theme.t.base, Theme.selfBlur ? 0.92 : 0.80)
                            border.width: 1; border.color: card.crit ? Theme.t.accent : Theme.alpha(Theme.t.gold, 0.42) }
                Rectangle {   // the sender, set into the rule
                    x: 16; y: 0; height: 16; width: sender.width + 18; color: Theme.alpha(Theme.t.base, 1)
                    Row {
                        id: sender; anchors.centerIn: parent; spacing: 7
                        IconImage { implicitSize: 13; anchors.verticalCenter: parent.verticalCenter; visible: !!(card.n && card.n.appIcon)
                                    source: card.n && card.n.appIcon ? Quickshell.iconPath(card.n.appIcon, "dialog-information") : "" }
                        Text { text: (card.n ? card.n.appName || "Tenka" : "").toUpperCase(); color: card.crit ? Theme.t.accent : Theme.t.gold
                               font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Text { anchors.right: parent.right; anchors.rightMargin: 18; y: 2; text: Theme.hm(Theme.now)
                       color: Theme.alpha(Theme.t.text, 0.4); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 1 }
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
                                    color: am.containsMouse ? Theme.t.text : (index === 0 ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.6))
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
