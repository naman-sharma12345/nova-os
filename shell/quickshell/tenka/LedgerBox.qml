// A ruled box in the ledger language: 1px gold rules with a gap in the top rule where the label
// sits ("01   MONTH"), so nothing is painted behind the label and the box works on any surface.
import QtQuick

Item {
    id: bx
    property string num: ""
    property string label: ""
    property string aside: ""          // small text set into the top rule on the right
    property real rule: 0.34
    property int pad: 18
    default property alias content: inner.data
    implicitHeight: inner.childrenRect.height + 26 + pad
    readonly property color rc: Theme.alpha(Theme.t.gold, rule)

    // rules: left, right, bottom, and the top in two pieces around the label / aside
    Rectangle { x: 0; y: 8; width: 1; height: bx.height - 8; color: bx.rc }
    Rectangle { x: bx.width - 1; y: 8; width: 1; height: bx.height - 8; color: bx.rc }
    Rectangle { x: 0; y: bx.height - 1; width: bx.width; height: 1; color: bx.rc }
    Rectangle { x: 0; y: 8; width: 10; height: 1; color: bx.rc }
    Rectangle { x: lbl.x + lbl.width + 8; y: 8; width: Math.max(0, (as.visible ? as.x - 8 : bx.width) - x); height: 1; color: bx.rc }
    Rectangle { visible: as.visible; x: as.x + as.width + 8; y: 8; width: Math.max(0, bx.width - x); height: 1; color: bx.rc }
    Text { id: lbl; x: 18; y: 1; text: bx.num + (bx.num ? "   " : "") + bx.label
           color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
    Text { id: as; visible: bx.aside !== ""; anchors.right: parent.right; anchors.rightMargin: 18; y: 1; text: bx.aside
           color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 3 }
    Item { id: inner; x: bx.pad; y: 26; width: bx.width - 2 * bx.pad; height: childrenRect.height }
}
