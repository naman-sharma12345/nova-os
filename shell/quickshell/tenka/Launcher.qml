// The launcher: a frosted card in the middle of the screen. One big search line; with nothing typed,
// six pinned paths as large tiles and every other app below; typing turns it into a ranked list.
// Super+Space, or the crest in the bar.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

PanelWindow {
    id: launcher
    property bool open: false
    property int sel: 0
    // faces: "menu" (default: a title-screen list on the boot menu's brush stroke) | "grid" (frosted tiles)
    readonly property string face: Theme.launcherStyle
    readonly property var field: face === "menu" ? msearch : search
    visible: open || card.opacity > 0.01 || menu.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open ? launcher.hide() : launcher.show() }
        // "show" never answers over `qs ipc call` (Recall found the same), so the open verb is "open"
        function open(): void { launcher.show() }
        function hide(): void { launcher.open = false }
        function type(q: string): void { launcher.show(); launcher.field.text = q }
    }
    onOpenChanged: Theme.hush = open
    function show() { search.text = ""; msearch.text = ""; sel = 0; open = true; field.forceActiveFocus() }
    function hide() { open = false }

    readonly property var hidden: /^(org\.xfce\.mousepad-settings|xfce|panel-|thunar-|xfce4-|kvantum|qt6ct|picom|conky|vim|nm-connection|org\.xfce\.ristretto-settings)/
    readonly property var pinnedIds: ["firefox-esr", "kitty", "thunar", "org.xfce.mousepad", "btop", "tenka-theme"]
    readonly property var all: DesktopEntries.applications.values
        .filter(a => !a.noDisplay && !hidden.test(a.id))
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var pinned: pinnedIds.map(id => all.find(a => a.id === id)).filter(a => !!a)
    readonly property var rest: all.filter(a => pinnedIds.indexOf(a.id) < 0)
    readonly property string q: field.text.trim().toLowerCase()
    function score(a) {
        const n = a.name.toLowerCase();
        if (n.startsWith(q)) return 0;
        if (n.includes(q)) return 1;
        if ((a.genericName || "").toLowerCase().includes(q) || (a.keywords || []).join(" ").toLowerCase().includes(q)) return 2;
        if ((a.comment || "").toLowerCase().includes(q)) return 3;
        if (q.length > 1 && n.split(/[\s\-_.]+/).map(w => w[0] || "").join("").startsWith(q)) return 2;
        return 9;
    }
    readonly property var found: q === "" ? [] : all.map(a => [score(a), a]).filter(x => x[0] < 9).sort((x, y) => x[0] - y[0] || used(y[1]) - used(x[1]) || x[1].name.localeCompare(y[1].name)).map(x => x[1])
    readonly property var flat: q === "" ? pinned.concat(often, others) : (calc ? [calc] : []).concat(found)
    readonly property var names: ({ "kitty": "Terminal", "btop": "Monitor", "org.xfce.ristretto": "Images", "nwg-look": "Appearance",
        "org.xfce.mousepad": "Notes", "firefox-esr": "Firefox", "thunar": "Files", "org.pulseaudio.pavucontrol": "Sound",
        "calamares-install-debian": "Install Tenka", "tenka-theme": "Choose your path", "mpv": "Player" })
    function nice(a) { return a.calc ? a.name : (names[a.id] || a.name) }
    function sectionAt(i) {
        if (q !== "") return !calc ? "" : (i === 0 ? "RECKONING" : (i === 1 ? "FOUND" : ""));
        if (i === 0) return "PINNED";
        if (often.length && i === pinned.length) return "OFTEN";
        if (i === pinned.length + often.length) return "ALL PATHS";
        return "";
    }
    // the matched letters of a name, underlined (flat; no colour change on the brush stroke)
    function marked(a) {
        const t = nice(a), esc = x => x.replace(/&/g, "&amp;").replace(/</g, "&lt;");
        const i = q === "" || a.calc ? -1 : t.toLowerCase().indexOf(q);
        return i < 0 ? esc(t) : esc(t.slice(0, i)) + "<u>" + esc(t.slice(i, i + q.length)) + "</u>" + esc(t.slice(i + q.length));
    }
    readonly property var drawn: ({ "kitty": "terminal", "thunar": "files", "firefox-esr": "browser", "org.xfce.mousepad": "editor",
        "nwg-look": "settings", "org.pulseaudio.pavucontrol": "music", "btop": "monitor", "tenka-theme": "path",
        "org.xfce.ristretto": "images", "calamares-install-debian": "install", "mpv": "player" })
    function iconFor(a) { return a.calc ? "" : drawn[a.id] ? Theme.icon(drawn[a.id]) : Quickshell.iconPath(a.icon, "application-x-executable") }
    // what you open most rises: a plain list of launches (one id per line, last 300 kept)
    FileView {
        id: usage
        path: Quickshell.env("HOME") + "/.config/tenka/launches"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var counts: {
        const c = {};
        (usage.text() || "").split("\n").forEach(l => { if (l) c[l] = (c[l] || 0) + 1 });
        return c;
    }
    function used(a) { return counts[a.id] || 0 }
    readonly property var often: rest.filter(a => used(a) > 0).sort((x, y) => used(y) - used(x)).slice(0, 4)
    readonly property var others: rest.filter(a => often.indexOf(a) < 0)
    function remember(a) {
        Theme.run("mkdir -p ~/.config/tenka; f=~/.config/tenka/launches; printf '%s\\n' '" + a.id.replace(/'/g, "") +
                  "' >> $f; tail -n 300 $f > $f.t && mv $f.t $f")
    }
    // a sum typed in the search line is worked out in place; ENTER copies the answer
    readonly property var calc: {
        const t = field.text.trim().replace(/^=/, "").replace(/×/g, "*").replace(/÷/g, "/").replace(/,/g, "");
        if (!/^[\d\s.+\-*\/%()^]+$/.test(t) || !/\d/.test(t) || !/[+\-*\/%^]/.test(t.replace(/^-/, ""))) return null;
        try {
            const v = Function("return (" + t.replace(/\^/g, "**") + ")")();
            if (typeof v !== "number" || !isFinite(v)) return null;
            return { calc: true, id: "", name: String(Math.round(v * 1e10) / 1e10), expr: t };
        } catch (e) { return null }
    }
    function launch(a) {
        if (!a) return;
        if (a.calc) { Theme.run("printf %s '" + a.name + "' | wl-copy"); hide(); return }
        remember(a); a.execute(); hide()
    }

    // the room dims around the card
    Rectangle {
        anchors.fill: parent; opacity: Math.max(card.opacity, menu.opacity)
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.t.base, 0.30) }
            GradientStop { position: 1; color: Theme.alpha(Theme.t.base, 0.62) } }
    }
    MouseArea { anchors.fill: parent; onClicked: launcher.hide() }

    Glass {
        id: card
        visible: launcher.face === "grid"
        width: 940; height: 690; radius: 30; tint: 0.46; line: 0.18; innerLine: 0.2
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 - 10 + (launcher.open ? 0 : 26)
        opacity: launcher.open ? 1 : 0
        scale: launcher.open ? 1 : 0.97
        Behavior on y { NumberAnimation { duration: Theme.ms(280); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(280); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        onYChanged: place()
        MouseArea { anchors.fill: parent }   // swallow clicks

        // ---- the search line
        Rectangle {
            id: pill
            x: 30; y: 30; width: parent.width - 60; height: 68; radius: 34
            color: Theme.alpha(Theme.t.base, 0.50)
            border.width: 1; border.color: Theme.alpha(Theme.gold, search.activeFocus ? 0.50 : 0.24)
            Rectangle { width: 46; height: 46; radius: 23; x: 11; anchors.verticalCenter: parent.verticalCenter; color: Theme.accent
                Text { anchors.centerIn: parent; text: "\uf002"; font.family: Theme.glyphs; font.pixelSize: 18; color: Theme.t.ink } }
            TextField {
                id: search
                anchors.left: parent.left; anchors.leftMargin: 70; anchors.right: escChip.left; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                background: null
                placeholderText: Theme.t.seekWord + " an app, a tool, a path…"
                placeholderTextColor: Theme.alpha(Theme.t.text, 0.42)
                color: Theme.t.text; font.family: Theme.display; font.pixelSize: 25; font.letterSpacing: 0.5
                selectionColor: Theme.alpha(Theme.accent, 0.5)
                onTextChanged: launcher.sel = 0
                Keys.onEscapePressed: launcher.hide()
                Keys.onDownPressed: launcher.sel = Math.min(launcher.flat.length - 1, launcher.sel + (launcher.q === "" ? 6 : 1))
                Keys.onUpPressed: launcher.sel = Math.max(0, launcher.sel - (launcher.q === "" ? 6 : 1))
                Keys.onRightPressed: launcher.sel = Math.min(launcher.flat.length - 1, launcher.sel + 1)
                Keys.onLeftPressed: launcher.sel = Math.max(0, launcher.sel - 1)
                onAccepted: launcher.launch(launcher.flat[launcher.sel])
            }
            Rectangle {
                id: escChip
                anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                width: escT.width + 20; height: 26; radius: 8; color: Theme.alpha(Theme.t.text, 0.08)
                border.width: 1; border.color: Theme.alpha(Theme.t.text, 0.14)
                Text { id: escT; anchors.centerIn: parent; text: "ESC"; color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.ui; font.pixelSize: 11; font.letterSpacing: 1.5 }
            }
        }

        component Label: Row {
            property string text
            spacing: 12
            Text { text: parent.text; color: Theme.gold; font.family: Theme.display; font.pixelSize: 13; font.letterSpacing: 6; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 120; height: 1; anchors.verticalCenter: parent.verticalCenter
                color: Theme.alpha(Theme.gold, 0.35) }   // flat hairline, no fade
        }

        component Tile: Item {
            id: tile
            required property var app
            required property int flatIndex
            property int iconSize: 46
            readonly property bool on: launcher.sel === flatIndex
            width: 146; height: 128
            Rectangle {
                anchors.fill: parent; anchors.margins: 4; radius: 22
                color: tile.on ? Theme.alpha(Theme.accent, 0.20) : (ma.containsMouse ? Theme.alpha(Theme.t.text, 0.06) : "transparent")
                border.width: tile.on ? 1 : 0; border.color: Theme.alpha(Theme.accent, 0.85)
                Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
            }
            Rectangle {
                id: chip
                width: 72; height: 72; radius: 22; y: 14; anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.alpha(Theme.t.text, tile.on ? 0.08 : 0.0); border.width: 1; border.color: Theme.alpha(Theme.gold, tile.on ? 0.55 : 0.0)
                IconImage { anchors.centerIn: parent; implicitSize: tile.iconSize; source: launcher.iconFor(tile.app) }
            }
            Text {
                anchors.top: chip.bottom; anchors.topMargin: 11; anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 16; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                text: launcher.nice(tile.app)
                color: tile.on ? Theme.t.text : Theme.alpha(Theme.t.text, 0.8)
                font.family: tile.on ? Theme.display : Theme.ui; font.pixelSize: 14
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onEntered: launcher.sel = tile.flatIndex; onClicked: launcher.launch(tile.app) }
        }

        // ---- nothing typed: pinned + every path
        Column {
            visible: launcher.q === ""
            x: 30; y: 124; width: parent.width - 60; spacing: 14
            Label { text: "PINNED"; leftPadding: 10 }
            Row {
                Repeater { model: launcher.pinned
                    Tile { required property var modelData; required property int index; app: modelData; flatIndex: index; iconSize: 50 } }
            }
            Item { width: 1; height: 2 }
            Label { text: "ALL PATHS  ·  " + launcher.all.length; leftPadding: 10 }
            Flickable {
                width: parent.width; height: 128; clip: true; contentHeight: restGrid.height
                Grid {
                    id: restGrid; columns: 6
                    Repeater { model: launcher.rest
                        Tile { required property var modelData; required property int index; app: modelData; flatIndex: launcher.pinned.length + index; iconSize: 42 } }
                }
            }
            Item { width: 1; height: 2 }
            Label { text: "RITES"; leftPadding: 10 }
            Row {
                leftPadding: 8; spacing: 12
                Repeater {
                    model: [["\uf023", Theme.t.lockWord, "loginctl lock-session"],
                            ["\uf030", "Capture", "sleep 0.4; tenka-shot"],
                            ["\udb81\ude80", Theme.xia ? "Walk the path of Tenka" : "Walk the path of Tianxia", Theme.xia ? "tenka-theme samurai" : "tenka-theme xianxia"],
                            ["\uf186", Theme.t.suspendWord, "systemctl suspend"],
                            ["\uf011", Theme.t.shutdownWord, "qs -c tenka ipc call power toggle"]]
                    Rectangle {
                        required property var modelData; required property int index
                        height: 44; width: rr.width + 36; radius: 22
                        color: rm.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.t.text, 0.06)
                        border.width: 1; border.color: Theme.alpha(index === 2 ? Theme.gold : Theme.t.text, index === 2 ? 0.5 : 0.14)
                        Row { id: rr; anchors.centerIn: parent; spacing: 10
                            Text { text: modelData[0]; font.family: Theme.glyphs; font.pixelSize: 14; color: index === 4 ? Theme.accent : Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData[1]; font.family: Theme.display; font.pixelSize: 15; color: Theme.alpha(Theme.t.text, 0.88); anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; onClicked: { launcher.hide(); Theme.run(modelData[2]) } }
                    }
                }
            }
        }

        // ---- typing: a ranked list
        ListView {
            id: list
            visible: launcher.q !== ""
            x: 30; y: 124; width: parent.width - 60; height: parent.height - 124 - 70
            clip: true; spacing: 4
            model: launcher.flat
            currentIndex: launcher.sel
            highlightMoveDuration: 140
            highlight: Rectangle { radius: 18; color: Theme.alpha(Theme.accent, 0.20); border.width: 1; border.color: Theme.alpha(Theme.accent, 0.85)
                Rectangle { width: 4; height: 26; radius: 2; color: Theme.accent; x: 10; anchors.verticalCenter: parent.verticalCenter } }
            delegate: Item {
                required property var modelData
                required property int index
                width: list.width; height: 64
                Row {
                    anchors.verticalCenter: parent.verticalCenter; x: 26; spacing: 18
                    IconImage { source: launcher.iconFor(modelData); implicitSize: 38; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Text { text: launcher.nice(modelData); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 20 }
                        Text { text: modelData.calc ? "Enter copies the answer" : (modelData.comment || modelData.genericName || ""); visible: text !== ""; width: 640; elide: Text.ElideRight
                               color: Theme.alpha(Theme.t.text, 0.55); font.family: Theme.ui; font.pixelSize: 12 }
                    }
                }
                Text { visible: index === list.currentIndex; anchors.right: parent.right; anchors.rightMargin: 22; anchors.verticalCenter: parent.verticalCenter
                       text: "OPEN  ↵"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 4 }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: launcher.sel = index; onClicked: launcher.launch(modelData) }
            }
        }

        // ---- the foot
        Rectangle { x: 30; width: parent.width - 60; height: 1; y: parent.height - 58; color: Theme.alpha(Theme.gold, 0.16) }
        Row {
            x: 40; y: parent.height - 40; spacing: 22
            Repeater {
                model: [["↵", "open"], ["↑ ↓ ← →", "move"], ["Esc", "close"]]
                Row { required property var modelData; spacing: 8
                    Text { text: modelData[0]; color: Theme.gold; font.family: Theme.ui; font.pixelSize: 12 }
                    Text { text: modelData[1]; color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12 } }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 40; y: parent.height - 44; spacing: 10
            Image { source: Theme.t.crest; width: 20; height: 20; mipmap: true; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Theme.t.word + "  ·  " + Theme.hourName(Theme.now).toUpperCase(); color: Theme.alpha(Theme.t.text, 0.5)
                   font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ======================================================================== face "menu"
    // The launcher as a title-screen menu: one hairline search, then the paths as a list in Marcellus;
    // the chosen one sits on the boot menu's own brush stroke (a flat jade band in Tianxia). No tiles, no glow.
    Item {
        id: menu
        visible: launcher.face === "menu"
        readonly property int rows: Math.min(8, Math.max(1, launcher.flat.length))
        // a section's first row carries a 24 px head: a gold small-caps word set into a hairline
        readonly property int heads: { let h = 0; for (let i = 0; i < rows; i++) if (launcher.sectionAt(i) !== "") h++; return h }
        width: 640; height: 112 + rows * 54 + heads * 24 + 64
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22 + (launcher.open ? 0 : 20)
        opacity: launcher.open ? 1 : 0
        Behavior on y { NumberAnimation { duration: Theme.ms(280); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        MouseArea { anchors.fill: parent }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, Theme.selfBlur ? 0.88 : 0.70)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.45) }

        Text { x: 34; y: 34; text: Theme.t.seekWord.toUpperCase(); color: Theme.gold; font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 5 }
        TextField {
            id: msearch
            x: 110; y: 18; width: parent.width - 140; height: 52
            background: null
            placeholderText: "an app, a tool, a path"
            placeholderTextColor: Theme.alpha(Theme.t.text, 0.38)
            color: Theme.t.text; font.family: Theme.display; font.pixelSize: 24
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            onTextChanged: launcher.sel = 0
            Keys.onEscapePressed: launcher.hide()
            Keys.onDownPressed: launcher.sel = Math.min(launcher.flat.length - 1, launcher.sel + 1)
            Keys.onUpPressed: launcher.sel = Math.max(0, launcher.sel - 1)
            onAccepted: launcher.launch(launcher.flat[launcher.sel])
        }
        Rectangle { x: 30; y: 78; width: parent.width - 60; height: 1
            color: Theme.alpha(Theme.gold, 0.35) }

        ListView {
            id: mlist
            x: 22; y: 96; width: parent.width - 44; height: menu.rows * 54 + menu.heads * 24
            clip: true; interactive: true
            model: launcher.flat
            currentIndex: launcher.sel
            highlightMoveDuration: 180
            highlightFollowsCurrentItem: true
            highlight: Item {
                width: mlist.width; height: mlist.currentItem ? mlist.currentItem.height : 54
                Image { source: Theme.t.stroke; width: 430; height: 54; smooth: true; anchors.bottom: parent.bottom; x: -4 }
            }
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: index === mlist.currentIndex
                readonly property string head: launcher.sectionAt(index)
                width: mlist.width; height: 54 + (head !== "" ? 24 : 0)
                Item {
                    visible: row.head !== ""
                    width: parent.width; height: 24
                    Text { id: headT; x: 12; anchors.verticalCenter: parent.verticalCenter; text: row.head
                           color: Theme.gold; font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 4 }
                    Rectangle { anchors.left: headT.right; anchors.leftMargin: 12; anchors.right: parent.right; anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter; height: 1; color: Theme.alpha(Theme.gold, 0.22) }
                }
                Item {
                    width: parent.width; height: 54; anchors.bottom: parent.bottom
                    IconImage { x: 30; anchors.verticalCenter: parent.verticalCenter; implicitSize: 22; visible: !row.modelData.calc
                                source: launcher.iconFor(row.modelData); opacity: row.on ? 1 : 0.7 }
                    Text { x: 30; width: 22; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter
                           visible: !!row.modelData.calc; text: "="; font.family: Theme.display; font.pixelSize: 24
                           color: row.on ? "#fff8ec" : Theme.gold }
                    Text { x: 68; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.StyledText; text: launcher.marked(row.modelData)
                           color: row.on ? "#fff8ec" : Theme.alpha(Theme.t.text, 0.72); font.family: Theme.display; font.pixelSize: 21 }
                    Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                           text: row.modelData.calc ? "ENTER COPIES" : (row.modelData.genericName || "").replace(/\s*\(.*\)\s*/, "").toUpperCase()
                           width: 220; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
                           color: Theme.alpha(Theme.t.text, row.on ? 0.55 : 0.3); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 3 }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: launcher.sel = row.index; onClicked: launcher.launch(row.modelData) }
            }
        }
        // nothing matched: say so plainly instead of an empty card
        Text {
            visible: launcher.q !== "" && launcher.flat.length === 0
            x: 34; y: 96; height: 54; verticalAlignment: Text.AlignVCenter
            text: "No path by that name."
            color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.display; font.pixelSize: 19; font.italic: false
        }
        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: "ENTER  to open      ↑ ↓  to choose      ESC  to close"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: launcher.q === "" ? launcher.all.length + " PATHS" : (launcher.calc ? "THE SUM" : launcher.found.length + " FOUND")
            color: Theme.alpha(Theme.gold, 0.7); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 3
        }
    }
}
