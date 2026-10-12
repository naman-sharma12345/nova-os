// Recall: the clipboard history (cliphist) as a ruled ledger card. The kept items on the left, the chosen
// one read in full on the right: words wrap, pictures show. Type to narrow, ENTER puts it back on the
// clipboard, DEL forgets it. Super+Shift+V, or tenka-clipboard. Flat: ink, one gold rule, the brush stroke.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: clip
    property bool open: false
    property int sel: 0
    property var items: []          // { id, text, kind: "text" | "link" | "image", ext, file }
    property string full: ""        // the chosen text, read whole
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-recall"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "clipboard"
        function toggle(): void { clip.open ? clip.hide() : clip.show() }
        function open(): void { clip.show() }
        function type(q: string): void { if (!clip.open) clip.show(); field.text = q }
        function hide(): void { clip.hide() }
    }
    onOpenChanged: Theme.hush = open
    function show() { field.text = ""; sel = 0; open = true; listQ.running = true; field.forceActiveFocus() }
    function hide() { open = false }

    readonly property string dir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/tenka-recall"
    // one pass: the newest 80, pictures decoded once into the runtime dir so they can be shown
    Process {
        id: listQ
        command: ["sh", "-c", "d=\"$1\"; mkdir -p \"$d\"; cliphist list 2>/dev/null | head -80 > \"$d/list\"; " +
                  "while IFS=\"$(printf '\\t')\" read -r id rest; do case \"$rest\" in '[[ binary data'*) " +
                  "e=$(echo \"$rest\" | awk '{print $5}'); [ -s \"$d/$id.$e\" ] || printf '%s\\t\\n' \"$id\" | cliphist decode > \"$d/$id.$e\" 2>/dev/null ;; esac; " +
                  "done < \"$d/list\"; cat \"$d/list\"", "sh", clip.dir]
        stdout: StdioCollector { onStreamFinished: clip.parse(text) }
    }
    function parse(t) {
        const out = []
        for (const line of t.split("\n")) {
            const k = line.indexOf("\t"); if (k < 1) continue
            const id = line.slice(0, k), rest = line.slice(k + 1)
            const bin = /^\[\[ binary data .* (\w+) (\d+x\d+)? ?\]\]$/.exec(rest)
            if (bin) { const e = rest.split(/\s+/)[4]; out.push({ id: id, text: rest.split(/\s+/).slice(5, -1).join(" "), kind: "image", ext: e, file: "file://" + clip.dir + "/" + id + "." + e }) }
            else out.push({ id: id, text: rest.replace(/\s+/g, " ").trim(), kind: /^(https?:\/\/|www\.)\S+$/.test(rest.trim()) ? "link" : "text", ext: "", file: "" })
        }
        items = out; sel = 0; readSel()
    }
    readonly property string q: field.text.trim().toLowerCase()
    readonly property var shown: q === "" ? items : items.filter(i => i.text.toLowerCase().includes(q) || (q === "image" && i.kind === "image"))
    readonly property var cur: shown.length ? shown[Math.min(sel, shown.length - 1)] : null
    onCurChanged: readSel()
    Process { id: readQ; property string want: ""; command: ["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist decode 2>/dev/null | head -c 4000", "sh", want]
              stdout: StdioCollector { onStreamFinished: clip.full = text } }
    function readSel() { full = cur ? cur.text : ""; if (cur && cur.kind !== "image") { readQ.want = cur.id; readQ.running = true } }
    Process { id: actQ; property var cmd: []; command: cmd; onExited: if (clip.open) listQ.running = true }
    function recall(i) { if (!i) return; actQ.cmd = ["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist decode | wl-copy", "sh", i.id]; actQ.running = true; hide() }
    function forget(i) { if (!i) return; actQ.cmd = ["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete; rm -f \"$2\"/\"$1\".*", "sh", i.id, clip.dir]; actQ.running = true }

    MouseArea { anchors.fill: parent; enabled: clip.open; onClicked: clip.hide() }

    Item {
        id: card
        width: 1040; height: 620
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18 + (clip.open ? 0 : 20)
        opacity: clip.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(280); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: Theme.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease } }
        MouseArea { anchors.fill: parent }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, Theme.selfBlur ? 0.9 : 0.74)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.45) }

        Text { x: 34; y: 34; text: "RECALL"; color: Theme.gold; font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 5 }
        TextField {
            id: field
            x: 130; y: 18; width: 420; height: 52
            background: null
            placeholderText: "something you kept"
            placeholderTextColor: Theme.alpha(Theme.t.text, 0.38)
            color: Theme.t.text; font.family: Theme.display; font.pixelSize: 24
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            onTextChanged: clip.sel = 0
            Keys.onEscapePressed: clip.hide()
            Keys.onDownPressed: clip.sel = Math.min(clip.shown.length - 1, clip.sel + 1)
            Keys.onUpPressed: clip.sel = Math.max(0, clip.sel - 1)
            Keys.onDeletePressed: event => { if (field.text === "") clip.forget(clip.cur); else event.accepted = false }
            onAccepted: clip.recall(clip.cur)
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 34; y: 34
               text: clip.q === "" ? clip.items.length + " KEPT" : clip.shown.length + " FOUND"
               color: Theme.alpha(Theme.gold, 0.7); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 3 }
        Rectangle { x: 30; y: 78; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.35) }

        // the kept items
        ListView {
            id: list
            x: 22; y: 92; width: 500; height: 8 * 54
            clip: true
            model: clip.shown
            currentIndex: clip.sel
            highlightMoveDuration: 180
            highlight: Item { width: list.width; height: 54
                Image { source: Theme.t.stroke; width: 470; height: 54; smooth: true; anchors.verticalCenter: parent.verticalCenter; x: -4 } }
            delegate: Item {
                required property var modelData
                required property int index
                readonly property bool on: index === list.currentIndex
                width: list.width; height: 54
                Text { x: 22; anchors.verticalCenter: parent.verticalCenter; text: (index + 1 < 10 ? "0" : "") + (index + 1)
                       color: parent.on ? "#fff8ec" : Theme.alpha(Theme.gold, 0.7); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2 }
                Image { x: 62; anchors.verticalCenter: parent.verticalCenter; visible: modelData.kind === "image"; source: modelData.file
                        width: 52; height: 34; fillMode: Image.PreserveAspectCrop; sourceSize.width: 160; asynchronous: true }
                Text { x: modelData.kind === "image" ? 128 : 62; width: parent.width - x - 90; anchors.verticalCenter: parent.verticalCenter
                       text: modelData.kind === "image" ? "A picture  " + modelData.text : modelData.text; elide: Text.ElideRight
                       color: parent.on ? "#fff8ec" : Theme.alpha(Theme.t.text, 0.75); font.family: Theme.display; font.pixelSize: 18 }
                Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                       text: modelData.kind.toUpperCase(); color: Theme.alpha(Theme.t.text, parent.on ? 0.6 : 0.3)
                       font.family: Theme.display; font.pixelSize: 10; font.letterSpacing: 3 }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: clip.sel = index; onClicked: clip.recall(modelData) }
            }
        }
        Text { x: 56; y: 120; visible: clip.items.length === 0; text: "Nothing kept yet. Copy something and it waits here."
               color: Theme.alpha(Theme.t.text, 0.5); font.family: Theme.display; font.pixelSize: 17 }

        // the chosen one, read in full
        Rectangle { x: 540; y: 100; width: 1; height: 8 * 54 - 16; color: Theme.alpha(Theme.gold, 0.28) }
        Item {
            x: 570; y: 100; width: parent.width - 570 - 34; height: 8 * 54 - 16
            Text { id: kindWord; text: clip.cur ? (clip.cur.kind === "image" ? "PICTURE" : clip.cur.kind === "link" ? "LINK" : "WORDS") + (clip.cur.kind === "image" ? "   " + clip.cur.text.toUpperCase() : "   " + clip.full.length + " CHARACTERS") : ""
                   color: Theme.alpha(Theme.gold, 0.85); font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }
            Image { y: 30; width: parent.width; height: parent.height - 30; visible: !!clip.cur && clip.cur.kind === "image"
                    source: clip.cur && clip.cur.kind === "image" ? clip.cur.file : ""; fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft; verticalAlignment: Image.AlignTop; asynchronous: true; sourceSize.width: 1000 }
            Text { y: 30; width: parent.width; height: parent.height - 30; visible: !!clip.cur && clip.cur.kind !== "image"
                   text: clip.full; wrapMode: Text.WrapAnywhere; elide: Text.ElideRight; clip: true; textFormat: Text.PlainText
                   color: clip.cur && clip.cur.kind === "link" ? Theme.accent : Theme.alpha(Theme.t.text, 0.85)
                   font.family: clip.cur && clip.cur.kind === "link" ? Theme.display : Theme.ui; font.pixelSize: 15; lineHeight: 1.25 }
        }

        Rectangle { x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 58; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.2) }
        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: "ENTER  to recall      DEL  to forget      ↑ ↓  to choose      ESC  to close"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
    }
}
