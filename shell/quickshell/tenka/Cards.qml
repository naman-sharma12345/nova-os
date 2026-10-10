// The card cluster: three small frosted cards that slide up from the lower left when the desk is
// opened (click the clock, Super+D, or touch the bottom edge), and slide away again.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: cards
    anchors { bottom: true; left: true }
    margins { left: 120; bottom: 118 }
    implicitWidth: row.width + 40; implicitHeight: 330
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "tenka-cards"
    visible: Theme.deskOpen || row.opacity > 0.01
    readonly property real ox: 120
    readonly property real oy: screen ? screen.height - 118 - implicitHeight : 0

    Row {
        id: row
        x: 16; y: 22 + (Theme.deskOpen ? 0 : 40)
        spacing: 22
        opacity: Theme.deskOpen ? 1 : 0
        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260 } }
        onYChanged: { cal.place(); med.place(); sys.place() }
        CalendarCard { id: cal; ox: cards.ox; oy: cards.oy }
        MediaCard { id: med; ox: cards.ox; oy: cards.oy }
        SysCard { id: sys; ox: cards.ox; oy: cards.oy }
    }
}
