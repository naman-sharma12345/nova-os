// A glass card: ink (or jade-dark) tint, a hairline of gold, soft inner light.
// Hyprland blurs what is behind it (layer rules on the tenka-* namespaces).
import QtQuick

Rectangle {
    id: g
    property real tint: 0.62
    property real line: 0.28
    radius: 22
    color: Theme.alpha(Qt.color(Theme.t.base), tint)
    border.width: 1
    border.color: Theme.alpha(Qt.color(Theme.t.gold), line)
    Rectangle {   // top sheen
        anchors.fill: parent; anchors.margins: 1; radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Qt.color(Theme.t.text), 0.06) }
            GradientStop { position: 0.35; color: "transparent" }
        }
    }
}
