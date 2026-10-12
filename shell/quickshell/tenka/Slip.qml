// The Slip: a note to self pinned on the desk, our own. One short slip in the house style (the pack's seal,
// a gold small-caps label, the note in Marcellus) on a flat ink plate at the desk's upper right. It shows only
// on an empty desk, steps back in focus, and hides when empty. Super+N writes on it (ESC or Ctrl+Enter keeps
// it, an empty slip is taken down). Kept in ~/.config/tenka/slip.txt. qs ipc call slip edit|done|clear.
// Focus first: the slip's surface stays mapped (empty input region while idle), Super+N arrives as the
// compositor's global shortcut tenka:slip (no qs process to start), and the plate shows only once the field
// holds the keyboard, so the first keys land on the slip and not in the window behind.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: slip
    property bool editing: false
    readonly property string note: (store.text() || "").trim()
    property bool focusLate: false
    readonly property bool held: editing && (field.activeFocus || focusLate)
    readonly property bool resting: note !== "" && !Theme.working && !Theme.hush
    visible: true
    mask: Region { item: slip.editing || plate.opacity > 0.01 ? plate : null }
    anchors { top: true; right: true }
    margins { top: 96; right: 64 }
    implicitWidth: 340; implicitHeight: plate.height + 8
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "tenka-slip"
    WlrLayershell.keyboardFocus: editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.config/tenka/slip.txt"
        watchChanges: true
        onFileChanged: reload()
        printErrors: false
    }
    IpcHandler {
        target: "slip"
        function edit(): void { slip.editing ? slip.keep() : slip.begin() }
        function done(): void { if (slip.editing) slip.keep() }
        function clear(): void { store.setText(""); slip.editing = false }
        function state(): string { return (slip.editing ? "editing" : "idle") + (slip.held ? " held" : "") + (field.activeFocus ? " focus" : "") }
    }
    GlobalShortcut { appid: "tenka"; name: "slip"; description: "The Slip: write a note to self"
                     onPressed: slip.editing ? slip.keep() : slip.begin() }
    Timer { interval: 700; running: slip.editing && !slip.held; onTriggered: slip.focusLate = true }
    onEditingChanged: if (!editing) focusLate = false
    function begin() { field.text = note; editing = true; field.forceActiveFocus(); field.cursorPosition = field.length }
    function keep() { store.setText(field.text.trim().slice(0, 400) + (field.text.trim() ? "\n" : "")); editing = false }

    Rectangle {
        id: plate
        width: 340
        height: body.implicitHeight + 40
        radius: Theme.ledgerR
        color: Theme.alpha(Theme.t.base, slip.editing ? 0.94 : 0.74)
        border.width: 1
        border.color: slip.editing ? Theme.alpha(Theme.accent, 0.8) : Theme.alpha(Theme.gold, 0.28)
        opacity: slip.editing ? (slip.held ? 1 : 0) : !slip.resting ? 0 : Theme.focus ? 0.38 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.perf ? 0 : 240; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }

        Column {
            id: body
            x: 22; y: 20; width: parent.width - 44
            spacing: 10
            Row {
                spacing: 10
                Image { width: 15; height: 18; source: Theme.asset("seal.png"); smooth: true; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "A NOTE TO SELF"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 4; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 48; height: 1; color: Theme.alpha(Theme.gold, 0.45); anchors.verticalCenter: parent.verticalCenter }
            }
            Text {
                visible: !slip.editing
                width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 8; elide: Text.ElideRight
                text: slip.note; color: Theme.t.text; lineHeight: 1.15
                font.family: Theme.display; font.pixelSize: 17
            }
            TextEdit {
                id: field
                visible: slip.editing
                width: parent.width; wrapMode: TextEdit.Wrap
                color: Theme.t.text; selectionColor: Theme.alpha(Theme.accent, 0.5); selectedTextColor: Theme.t.text
                font.family: Theme.display; font.pixelSize: 17
                Text {
                    visible: field.length === 0
                    text: "Write a line to come back to."; color: Theme.alpha(Theme.t.text, 0.4)
                    font: field.font
                }
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape || ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && (e.modifiers & Qt.ControlModifier))) { slip.keep(); e.accepted = true }
                    else if (field.length >= 400 && e.text.length && e.key !== Qt.Key_Backspace && e.key !== Qt.Key_Delete) e.accepted = true
                }
            }
            Text {
                visible: slip.editing
                text: "ESC  KEEP      EMPTY  TAKES IT DOWN"
                color: Theme.alpha(Theme.t.text, 0.4); font.family: Theme.display; font.pixelSize: 9; font.letterSpacing: 3
            }
        }
    }
}
