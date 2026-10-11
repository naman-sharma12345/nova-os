// A hairline meter: the name, the number in gold, a 1px track with a 2px filled part and a
// small diamond (a dot in Tianxia) where it ends. No fills, no glow.
import QtQuick

Item {
    id: hm
    property real v: 0
    property string k: ""
    property string unit: ""
    property color c: Theme.gold   // value fills are one colour across the shell and Lite
    width: parent ? parent.width : 0; height: 40
    Behavior on v { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Text { y: 2; text: hm.k; color: Theme.alpha(Theme.t.text, 0.86); font.family: Theme.display; font.pixelSize: 15 }
    Text { y: 4; anchors.right: parent.right; text: Math.round(hm.v * 100) + hm.unit; color: Theme.gold
           font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 1 }
    Item {
        y: 27; width: parent.width; height: 9
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Theme.alpha(Theme.t.text, 0.16) }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.max(2, parent.width * hm.v); height: 2; color: hm.c }
        Rectangle { x: Math.max(0, parent.width * hm.v - width / 2); anchors.verticalCenter: parent.verticalCenter
                    width: 7; height: 7; radius: Theme.xia ? 3.5 : 0; rotation: Theme.xia ? 0 : 45; color: Theme.gold }
    }
}
