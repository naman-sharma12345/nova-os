// The day's proverb as a small calligraphy plate: the pack's seal, a gold small-caps label and a
// short brush rule, then the line itself in Marcellus. One proverb a day (Theme.proverb), the same
// on the desk and the lock. Flat; the only effect is the desk's soft legibility shadow.
import QtQuick
import QtQuick.Effects

Item {
    id: plate
    property real s: 1
    property bool alignRight: false          // set against the right edge (the lock)
    property real maxWidth: 560
    property real size: 24
    property real textOpacity: 0.86
    property bool shadow: false
    implicitWidth: maxWidth * s
    implicitHeight: col.height
    width: implicitWidth; height: implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 12 * plate.s
        Row {
            anchors.right: plate.alignRight ? parent.right : undefined
            layoutDirection: plate.alignRight ? Qt.RightToLeft : Qt.LeftToRight
            spacing: 12 * plate.s
            Image { width: 18 * plate.s; height: 22 * plate.s; source: Theme.asset("seal.png"); smooth: true
                    rotation: -3; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "THE DAY'S WORD"; color: Theme.alpha(Theme.gold, 0.9); font.family: Theme.display
                   font.pixelSize: 12 * plate.s; font.letterSpacing: 6 * plate.s; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 36 * plate.s; height: 1; color: Theme.alpha(Theme.gold, 0.55); anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            width: parent.width; wrapMode: Text.WordWrap
            horizontalAlignment: plate.alignRight ? Text.AlignRight : Text.AlignLeft
            text: Theme.proverb
            color: Theme.alpha(Theme.t.text, plate.textOpacity)
            font.family: Theme.display; font.pixelSize: plate.size * plate.s; lineHeight: 1.28
            layer.enabled: plate.shadow && !Theme.perf
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.25; shadowOpacity: 0.5; shadowVerticalOffset: 1 }
        }
    }
}
