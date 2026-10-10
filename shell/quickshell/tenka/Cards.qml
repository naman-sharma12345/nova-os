// The desk cards that slide up from the lower left when the desk is opened (click the clock,
// Super+D, or touch the bottom edge). Theme.cardsStyle: "ledger" (default) = one ink sheet with
// three ruled boxes (DeskLedger.qml); "bare" = the same boxes straight on the art; "glass" = the
// older three frosted cards.
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: cards
    anchors { bottom: true; left: true }
    margins { left: 120; bottom: 118 }
    readonly property bool glassFace: Theme.cardsStyle === "glass"
    implicitWidth: glassFace ? row.width + 40 : ledger.width + 40
    implicitHeight: glassFace ? 330 : ledger.height + 62
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "tenka-cards"
    visible: Theme.deskOpen || row.opacity > 0.01 || ledger.opacity > 0.01
    readonly property real ox: 120
    readonly property real oy: screen ? screen.height - 118 - implicitHeight : 0

    Row {
        id: row
        visible: cards.glassFace
        x: 16; y: 22 + (Theme.deskOpen ? 0 : 40)
        spacing: 22
        opacity: Theme.deskOpen && cards.glassFace ? 1 : 0
        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260 } }
        onYChanged: { cal.place(); med.place(); sys.place() }
        CalendarCard { id: cal; ox: cards.ox; oy: cards.oy }
        MediaCard { id: med; ox: cards.ox; oy: cards.oy }
        SysCard { id: sys; ox: cards.ox; oy: cards.oy }
    }
    DeskLedger {
        id: ledger
        visible: !cards.glassFace
        ox: cards.ox; oy: cards.oy
        x: 16; y: 22 + (Theme.deskOpen ? 0 : 30)
        opacity: Theme.deskOpen && !cards.glassFace ? 1 : 0
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 240 } }
        onYChanged: place()
    }
}
