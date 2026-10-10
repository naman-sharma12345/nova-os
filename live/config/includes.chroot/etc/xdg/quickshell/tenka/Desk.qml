// The desktop is a title card: a huge clock in the art's negative space, a gold hairline,
// the date in tracked capitals, the hour's old name, and a proverb that changes each hour.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: desk
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "tenka-desk"
    mask: Region {}
    readonly property real s: Math.min(width / 1920, height / 1080)

    Item {
        id: title
        x: 150 * desk.s; y: 210 * desk.s
        width: 760 * desk.s; height: 520 * desk.s

        Text {
            id: clockText
            text: Qt.formatTime(Theme.now, "HH:mm")
            color: Theme.t.text
            font.family: Theme.display; font.pixelSize: 236 * desk.s; font.letterSpacing: 4 * desk.s
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: Theme.t.name === "xianxia" ? Theme.t.accent : Theme.t.gold
                shadowBlur: 1.0; shadowOpacity: 0.55; shadowHorizontalOffset: 0; shadowVerticalOffset: 0
            }
        }
        Rectangle {
            id: rule
            anchors.top: clockText.bottom; anchors.topMargin: -6 * desk.s
            x: -24 * desk.s; width: clockText.width + 48 * desk.s; height: 1
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.t.gold }
                GradientStop { position: 1; color: "transparent" } }
            Rectangle { width: 9 * desk.s; height: width; rotation: 45; color: Theme.t.gold; anchors.centerIn: parent }
        }
        Text {
            id: dateText
            anchors.top: rule.bottom; anchors.topMargin: 22 * desk.s
            anchors.horizontalCenter: rule.horizontalCenter
            text: Qt.formatDate(Theme.now, "dddd  ·  d MMMM").toUpperCase()
            color: Theme.t.gold
            font.family: Theme.display; font.pixelSize: 24 * desk.s; font.letterSpacing: 9 * desk.s
            style: Text.Raised; styleColor: Theme.alpha(Qt.color(Theme.t.base), 0.6)
        }
        Text {
            id: hourText
            anchors.top: dateText.bottom; anchors.topMargin: 10 * desk.s
            anchors.horizontalCenter: rule.horizontalCenter
            text: Theme.hourName(Theme.now).toUpperCase()
            color: Theme.alpha(Qt.color(Theme.t.text), 0.62)
            font.family: Theme.display; font.pixelSize: 15 * desk.s; font.letterSpacing: 7 * desk.s
        }
        Text {
            anchors.top: hourText.bottom; anchors.topMargin: 44 * desk.s
            anchors.horizontalCenter: rule.horizontalCenter
            width: Math.min(rule.width, 640 * desk.s); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            style: Text.Raised; styleColor: Theme.alpha(Qt.color(Theme.t.base), 0.6)
            text: "“" + Theme.t.proverbs[Theme.now.getHours() % Math.max(1, Theme.t.proverbs.length)] + "”"
            color: Theme.alpha(Qt.color(Theme.t.text), 0.82)
            font.family: Theme.display; font.pixelSize: 23 * desk.s; font.italic: false; font.letterSpacing: 1
        }
    }

    // a small system card in the lower left: crest, the pack's name, memory and uptime
    SysCard { x: 150 * desk.s; y: desk.height - height - 96 * desk.s; scale: desk.s; transformOrigin: Item.BottomLeft }
}
