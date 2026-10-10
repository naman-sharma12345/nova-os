// Notifications: glass cards in the top right, the summary in Marcellus, a thin accent edge.
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

Scope {
    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => { n.tracked = true; }
    }
    PanelWindow {
        visible: server.trackedNotifications.values.length > 0
        anchors { top: true; right: true }
        margins { top: 70; right: 16 }
        implicitWidth: 400; implicitHeight: Math.max(1, col.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "tenka-notify"
        Column {
            id: col; width: parent.width; spacing: 10
            Repeater {
                model: server.trackedNotifications
                delegate: Glass {
                    id: nc
                    required property Notification modelData
                    width: 400; height: 92; radius: 20; tint: 0.8
                    Rectangle { width: 3; height: parent.height - 30; radius: 2; color: Theme.t.accent; anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 30; anchors.right: parent.right; anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text { text: nc.modelData.appName.toUpperCase(); color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
                        Text { text: nc.modelData.summary; color: Theme.t.text; font.family: Theme.display; font.pixelSize: 17; elide: Text.ElideRight; width: parent.width }
                        Text { text: nc.modelData.body; color: Theme.alpha(Qt.color(Theme.t.text), 0.65); font.family: Theme.ui; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                    }
                    Timer { interval: 6000; running: true; onTriggered: nc.modelData.expire() }
                    MouseArea { anchors.fill: parent; onClicked: nc.modelData.dismiss() }
                }
            }
        }
    }
}
