// The Field: a calm overview of every workspace, our own (Hyprland has none built in). Each workspace is a
// small desk on its own wallpaper, its windows laid out where they really sit, as flat plates (a live still of
// the window when the compositor can copy it). The current one carries an accent hairline and sits on the
// pack's brush stroke. ENTER or a click goes there, a click on a plate focuses that window, a plate dragged
// onto another desk moves the window there. Super+Tab, or qs ipc call overview toggle. Flat: ink, one gold rule.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: ov
    property bool open: false
    property int sel: 0                 // index into desks
    property var clients: []            // hyprctl clients -j, or the sim file
    property int focusedWs: 1
    property real monW: Theme.sw
    property real monH: Theme.sh
    readonly property bool onHypr: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
    readonly property string sim: Quickshell.env("TENKA_OVERVIEW_SIM") || ""
    visible: open || field.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-overview"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    GlobalShortcut { appid: "tenka"; name: "overview"; description: "The Field: every desk at once"
                     onPressed: ov.open ? ov.hide() : ov.reveal() }
    IpcHandler {
        target: "overview"
        function toggle(): void { ov.open ? ov.hide() : ov.reveal() }
        function open(): void { ov.reveal() }
        function hide(): void { ov.hide() }
        function pick(n: int): void { if (!ov.open) ov.reveal(); ov.sel = Math.max(0, Math.min(ov.desks.length - 1, n)) }
    }
    onOpenChanged: Theme.hush = open
    function reveal() { readQ.running = true; open = true; keys.forceActiveFocus() }
    function hide() { open = false }

    // one read per opening: the windows, the focused workspace and the monitor's size
    Process {
        id: readQ
        command: ov.sim !== "" ? ["sh", "-c", "cat \"$1\"", "sh", ov.sim]
               : ["sh", "-c", "printf '{\"c\":'; hyprctl clients -j 2>/dev/null || printf '[]'; printf ',\"w\":'; " +
                  "hyprctl activeworkspace -j 2>/dev/null || printf '{}'; printf ',\"m\":'; hyprctl monitors -j 2>/dev/null || printf '[]'; printf '}'"]
        stdout: StdioCollector { onStreamFinished: ov.parse(text) }
    }
    function parse(t) {
        let d = {}
        try { d = JSON.parse(t) } catch (e) { d = {} }
        const m = (d.m || []).find(x => x.focused) || (d.m || [])[0]
        if (m && m.width) { monW = m.width / (m.scale || 1); monH = m.height / (m.scale || 1) }
        clients = (d.c || []).filter(c => c.workspace && c.workspace.id > 0 && c.mapped !== false && !c.hidden)
        focusedWs = (d.w && d.w.id > 0) ? d.w.id : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
        sel = Math.max(0, desks.findIndex(k => k.id === focusedWs))
    }
    // the desks: every workspace with a window, the current one, and one empty desk after the last
    readonly property var desks: {
        const ids = {}
        for (const c of clients) ids[c.workspace.id] = true
        ids[focusedWs] = true
        const list = Object.keys(ids).map(Number).sort((a, b) => a - b)
        const next = list.length ? Math.min(10, list[list.length - 1] + 1) : 1
        if (!ids[next]) list.push(next)
        return list.map(id => ({ id: id, wins: clients.filter(c => c.workspace.id === id), empty: !clients.some(c => c.workspace.id === id) }))
    }
    readonly property var numerals: ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    function nice(c) { const s = (c["class"] || c.initialClass || "window").split(".").pop(); return s.replace(/[-_]/g, " ") }

    // dispatch: the Lua form first (0.55), the old verb if that is refused
    Process { id: actQ; property var cmd: []; command: cmd; onExited: if (ov.open) readQ.running = true }
    function run(lua, legacy) {
        if (sim !== "") return
        actQ.cmd = ["sh", "-c", "hyprctl dispatch \"$1\" | grep -qx ok || hyprctl dispatch $2", "sh", lua, legacy]
        actQ.running = true
    }
    function go(id) { run("hl.dsp.focus({ workspace = " + id + " })", "workspace " + id); hide() }
    function focusWin(c) { run("hl.dsp.focus({ window = \"address:" + c.address + "\" })", "focuswindow address:" + c.address); hide() }
    function moveWin(c, id) {
        if (!c || c.workspace.id === id) return
        if (sim !== "") { const cs = clients.slice(); const k = cs.indexOf(c); cs[k] = Object.assign({}, c, { workspace: { id: id } }); clients = cs; return }
        run("hl.dsp.window.move({ workspace = " + id + ", window = \"address:" + c.address + "\", silent = true })",
            "movetoworkspacesilent " + id + ",address:" + c.address)
    }
    function topLevelOf(c) {
        if (!onHypr) return null
        const a = String(c.address || "").replace(/^0x/, "")
        return Hyprland.toplevels.values.find(t => String(t.address).replace(/^0x/, "") === a) || null
    }

    // the field: the wallpaper under a flat wash of the pack's ink
    Item {
        id: field
        anchors.fill: parent
        opacity: ov.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.perf ? 0 : 200; easing.type: Easing.OutCubic } }
        Rectangle { anchors.fill: parent; color: Theme.t.base; opacity: 0.86 }
        MouseArea { anchors.fill: parent; onClicked: ov.hide() }

        // the head: a gold small-caps word set into a hairline, and a quiet count beneath
        Column {
          id: body
          anchors.centerIn: parent; anchors.verticalCenterOffset: -24
          spacing: 52
          Column {
            id: head
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16
                Rectangle { width: 120; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
                Text { text: Theme.xia ? "THE REALMS" : "THE PROVINCES"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 6 }
                Rectangle { width: 120; height: 1; color: Theme.alpha(Theme.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property int used: ov.desks.filter(k => !k.empty).length
                text: (used || 1) + (used === 1 ? " desk · " : " desks · ") + ov.clients.length + (ov.clients.length === 1 ? " window" : " windows")
                color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.ui; font.pixelSize: 15
            }
        }

        // the desks, one row up to five, then two rows
        Flow {
            id: flow
            readonly property int per: ov.desks.length <= 5 ? Math.max(1, ov.desks.length) : Math.ceil(ov.desks.length / 2)
            readonly property real tw: Math.min(420, (field.width * 0.86 - (per - 1) * 36) / per)
            readonly property real th: tw * ov.monH / ov.monW
            width: per * tw + (per - 1) * 36
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 36
            Repeater {
                model: ov.desks
                delegate: Item {
                    id: desk
                    required property var modelData
                    required property int index
                    readonly property bool cur: modelData.id === ov.focusedWs
                    readonly property bool on: index === ov.sel
                    readonly property real k: flow.tw / ov.monW
                    width: flow.tw; height: flow.th + 58
                    z: on ? 2 : 0

                    Rectangle {          // the desk itself
                        id: tile
                        width: flow.tw; height: flow.th
                        radius: Theme.ledgerR
                        color: Theme.t.surface
                        Image {
                            anchors.fill: parent; anchors.margins: 1; clip: true; source: Theme.t.wallpaper; fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 480; asynchronous: true; smooth: true
                            opacity: desk.modelData.empty ? 0.22 : 0.5
                        }
                        Text {
                            visible: desk.modelData.empty; anchors.centerIn: parent
                            text: "AN EMPTY DESK"; color: Theme.alpha(Theme.t.text, 0.55)
                            font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4
                        }
                        Repeater {        // the windows where they really sit
                            model: desk.modelData.wins
                            delegate: Rectangle {
                                id: plate
                                required property var modelData
                                readonly property var at: modelData.at || [0, 0]
                                readonly property var sz: modelData.size || [ov.monW, ov.monH]
                                readonly property var tl: ov.topLevelOf(modelData)
                                x: Math.max(2, at[0] * desk.k); y: Math.max(2, at[1] * desk.k)
                                width: Math.max(28, Math.min(tile.width - x - 2, sz[0] * desk.k))
                                height: Math.max(20, Math.min(tile.height - y - 2, sz[1] * desk.k))
                                radius: Math.max(3, Theme.ledgerR / 2)
                                color: Theme.alpha(Theme.t.base, 0.86)
                                border.width: modelData.focusHistoryID === 0 ? 1.5 : 1
                                border.color: modelData.focusHistoryID === 0 ? Theme.accent : Theme.alpha(Theme.t.text, 0.16)
                                z: dragArea.active ? 10 : 1
                                ScreencopyView {
                                    anchors.fill: parent; anchors.margins: 1
                                    visible: plate.tl !== null && hasContent
                                    captureSource: plate.tl ? plate.tl.wayland : null
                                    live: false
                                }
                                Column {
                                    visible: plate.tl === null
                                    anchors.centerIn: parent
                                    width: parent.width - 14
                                    spacing: 3
                                    Text {
                                        width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                        text: ov.nice(plate.modelData).toUpperCase(); color: Theme.gold
                                        font.family: Theme.display; font.pixelSize: plate.height > 60 ? 10 : 8; font.letterSpacing: 2.5
                                    }
                                    Text {
                                        visible: plate.height > 46
                                        width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                        text: plate.modelData.title || ""; color: Theme.alpha(Theme.t.text, 0.78)
                                        font.family: Theme.ui; font.pixelSize: plate.height > 90 ? 12 : 10
                                    }
                                }
                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    drag.target: plate
                                    property bool active: drag.active
                                    property real ox: 0; property real oy: 0
                                    onPressed: { ox = plate.x; oy = plate.y }
                                    onReleased: {
                                        if (!drag.active) { ov.focusWin(plate.modelData); return }
                                        const p = plate.mapToItem(flow, plate.width / 2, plate.height / 2)
                                        const hit = flow.childAt(p.x, p.y)
                                        plate.x = ox; plate.y = oy
                                        if (hit && hit.modelData) ov.moveWin(plate.modelData, hit.modelData.id)
                                    }
                                    onClicked: {}
                                }
                            }
                        }
                        MouseArea { anchors.fill: parent; z: -1; hoverEnabled: true; onEntered: ov.sel = desk.index; onClicked: ov.go(desk.modelData.id) }
                    }
                    Rectangle {          // the current desk: one accent hairline; the chosen one: a quieter gold one
                        anchors.fill: tile; anchors.margins: -5; radius: tile.radius + 5; color: "transparent"
                        border.width: desk.cur ? 2 : 1
                        border.color: desk.cur ? Theme.accent : Theme.alpha(Theme.gold, 0.55)
                        visible: desk.cur || desk.on
                    }
                    Item {               // the name: a numeral, on the brush stroke when chosen
                        anchors.top: tile.bottom; anchors.topMargin: 16
                        width: tile.width; height: 34
                        Image {
                            visible: desk.on; source: Theme.t.stroke; smooth: true
                            readonly property real band: nameRow.width + 72      // the stroke's ink spans 81% of its file
                            width: band / 0.81; height: 38; y: -2
                            x: (parent.width - band) / 2
                        }
                        Row {
                            id: nameRow
                            anchors.centerIn: parent
                            spacing: 10
                            Text {
                                text: ov.numerals[desk.modelData.id] || String(desk.modelData.id)
                                color: desk.on ? "#fff8ec" : Theme.t.text
                                font.family: Theme.display; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: desk.modelData.empty ? "new" : desk.modelData.wins.length + (desk.modelData.wins.length === 1 ? " window" : " windows")
                                color: desk.on ? Theme.alpha("#fff8ec", 0.8) : Theme.alpha(Theme.t.text, 0.5)
                                font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }

        }

        // the foot: what the keys do
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: Math.round(parent.height * 0.08)
            text: "ENTER  GO      CLICK A WINDOW  FOCUS      DRAG A WINDOW  MOVE IT      ESC  CLOSE"
            color: Theme.alpha(Theme.t.text, 0.42); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 3
        }
    }

    Item {
        id: keys
        focus: ov.open
        Keys.onPressed: e => {
            const n = ov.desks.length
            if (e.key === Qt.Key_Escape) ov.hide()
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) ov.sel = (ov.sel + 1) % n
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) ov.sel = (ov.sel - 1 + n) % n
            else if (e.key === Qt.Key_Down) ov.sel = Math.min(n - 1, ov.sel + flow.per)
            else if (e.key === Qt.Key_Up) ov.sel = Math.max(0, ov.sel - flow.per)
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) ov.go(ov.desks[ov.sel].id)
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) ov.go(e.key - Qt.Key_0)
            else return
            e.accepted = true
        }
    }
}
