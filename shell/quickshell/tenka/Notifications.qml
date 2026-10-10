// Notifications: frosted cards that spring in under the bar's right island, with the app's
// icon in a seal, a gold line for who sent it, the words, and its actions as pills.
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
            delegate: Glass {
                id: card
                required property var n
                required property int index
                ox: nw.screen ? nw.screen.width - nw.implicitWidth - 14 : 0; oy: 66
                width: 400; height: body.height + 36; radius: 22; tint: 0.55
                property real slide: 60
                transform: Translate { x: card.slide }
                opacity: 0
                Component.onCompleted: { slide = 0; opacity = 1 }
                Behavior on slide { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Timer { running: card.n && card.n.urgency !== NotificationUrgency.Critical; interval: 7000; onTriggered: list.remove(card.index) }

                Rectangle { x: 0; y: 18; width: 3; height: parent.height - 36; radius: 2; color: Theme.t.accent }
                Row {
                    id: body
                    x: 18; y: 18; width: parent.width - 36; spacing: 14
                    Rectangle {
                        width: 46; height: 46; radius: Theme.xia ? 23 : 14
                        color: Theme.alpha(Theme.t.text, 0.07); border.width: 1; border.color: Theme.alpha(Theme.t.gold, 0.35)
                        IconImage { anchors.centerIn: parent; implicitSize: 28; visible: !!(card.n && (card.n.image || card.n.appIcon))
                                    source: card.n ? (card.n.image || Quickshell.iconPath(card.n.appIcon, "dialog-information")) : "" }
                        Image { anchors.centerIn: parent; width: 30; height: 30; mipmap: true; source: Theme.t.crest
                                visible: !(card.n && (card.n.image || card.n.appIcon)) }
                    }
                    Column {
                        width: parent.width - 60; spacing: 5
                        Row {
                            width: parent.width
                            Text { text: (card.n ? card.n.appName || "Tenka" : "").toUpperCase(); color: Theme.t.gold; font.family: Theme.display
                                   font.pixelSize: 11; font.letterSpacing: 4; width: parent.width - 60; elide: Text.ElideRight }
                            Text { text: "now"; color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.ui; font.pixelSize: 11; width: 60; horizontalAlignment: Text.AlignRight }
                        }
                        Text { text: card.n ? card.n.summary : ""; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 18
                               width: parent.width; elide: Text.ElideRight }
                        Text { text: card.n ? card.n.body : ""; visible: text !== ""; color: Theme.alpha(Theme.t.text, 0.72); font.family: Theme.ui; font.pixelSize: 13
                               width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight; lineHeight: 1.1 }
                        Row {
                            visible: card.n && card.n.actions.length > 0; spacing: 8; topPadding: 6
                            Repeater {
                                model: card.n ? card.n.actions : []
                                Rectangle {
                                    required property var modelData; required property int index
                                    height: 32; width: at.width + 28; radius: 16
                                    color: index === 0 ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.08)
                                    border.width: index === 0 ? 0 : 1; border.color: Theme.alpha(Theme.t.text, 0.16)
                                    Text { id: at; anchors.centerIn: parent; text: modelData.text; font.family: Theme.display; font.pixelSize: 13
                                           color: index === 0 ? Theme.t.ink : Theme.t.text }
                                    MouseArea { anchors.fill: parent; onClicked: { modelData.invoke(); list.remove(card.index) } }
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
