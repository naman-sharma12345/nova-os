// The Glance's card (Tianxia: The Glimpse): one file at a time, flat. A picture or the frame of a video fills
// the page, a PDF shows its first page, a text its opening lines in the mono face, a folder what it holds;
// anything else its facts. tenka-glance writes the facts (`g`) and fills the slow previews in as they come.
import QtQuick

Item {
    id: card
    width: 980; height: 700
    property color base: "#0f0d0c"
    property color text: "#efe6d6"
    property color gold: "#c9a35a"
    property color accent: "#b5452f"
    property real radius: 6
    property string face: "Marcellus"
    property string uiFace: "Marcellus"
    property string sysFace: "Inter"
    property string monoFace: "JetBrains Mono"
    property bool xia: false
    property var g: ({ items: [] })
    property int at: 0
    readonly property var f: g.items.length ? g.items[Math.min(at, g.items.length - 1)] : null
    signal dismissed()
    signal opened(string path)

    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    function when(t) { const d = new Date(t * 1000); return d.toLocaleDateString(Qt.locale("en_GB"), "d MMMM yyyy") + ", " + d.toLocaleTimeString(Qt.locale("en_GB"), "HH:mm") }
    function step(d) { if (g.items.length) at = (at + d + g.items.length) % g.items.length }
    readonly property var meta: {
        if (!f) return []
        const m = [f.word]
        if (f.extra) m.push(f.extra)
        if (f.kind === "folder" && f.count >= 0) m.push(f.count + (f.count === 1 ? " item" : " items"))
        if (f.size) m.push(f.size)
        m.push(when(f.mtime))
        return m
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape || (e.key === Qt.Key_Space && (e.modifiers & Qt.ControlModifier))) card.dismissed()
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Space) card.step(1)
        else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backspace) card.step(-1)
        else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && card.f) card.opened(card.f.path)
        else return
        e.accepted = true
    }
    Rectangle { anchors.fill: parent; radius: card.radius; color: card.base
                border.width: 1; border.color: card.alpha(card.gold, 0.4) }

    Row {
        x: 34; y: 30; spacing: 14
        Text { text: card.xia ? "THE GLIMPSE" : "THE GLANCE"; color: card.gold; font.family: card.face
               font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 64; height: 1; color: card.alpha(card.gold, 0.5); anchors.verticalCenter: parent.verticalCenter }
        Text { text: card.g.items.length > 1 ? (card.at + 1) + " of " + card.g.items.length : ""; color: card.alpha(card.text, 0.5)
               font.family: card.uiFace; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    Text {
        x: 34; y: 56; width: parent.width - 68; text: card.f ? card.f.name : ""; elide: Text.ElideMiddle
        color: card.text; font.family: card.face; font.pixelSize: 26
    }
    Rectangle { x: 30; y: 104; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.35) }

    // the page
    Item {
        id: page
        x: 34; y: 126; width: parent.width - 68; height: parent.height - 126 - 78
        clip: true
        Image {
            id: pic
            anchors.fill: parent
            visible: card.f !== null && (card.f.kind === "image" || card.f.preview !== "")
            source: !card.f ? "" : card.f.kind === "image" ? "file://" + card.f.path : card.f.preview !== "" ? "file://" + card.f.preview : ""
            fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true; mipmap: true
            sourceSize.width: 1800
        }
        // a PDF page sits on its own paper edge
        Rectangle {
            visible: pic.visible && card.f && card.f.kind === "pdf" && pic.status === Image.Ready
            x: (page.width - pic.paintedWidth) / 2 - 1; y: (page.height - pic.paintedHeight) / 2 - 1
            width: pic.paintedWidth + 2; height: pic.paintedHeight + 2; color: "transparent"
            border.width: 1; border.color: card.alpha(card.text, 0.18)
        }
        Text {
            anchors.fill: parent
            visible: card.f !== null && card.f.kind === "text"
            text: card.f ? card.f.lines : ""; textFormat: Text.PlainText; wrapMode: Text.NoWrap
            color: card.alpha(card.text, 0.86); font.family: card.monoFace; font.pixelSize: 13; lineHeight: 1.15
        }
        Grid {
            visible: card.f !== null && card.f.kind === "folder"
            columns: 2; columnSpacing: 40; rowSpacing: 10; y: 6
            Repeater {
                model: card.f && card.f.kind === "folder" ? card.f.items : []
                delegate: Row {
                    required property var modelData
                    spacing: 12; width: (page.width - 40) / 2
                    Rectangle { width: 8; height: 8; radius: modelData.dir ? 0 : 4; anchors.verticalCenter: parent.verticalCenter
                                color: modelData.dir ? card.gold : "transparent"; border.width: modelData.dir ? 0 : 1
                                border.color: card.alpha(card.text, 0.45) }
                    Text { text: modelData.name; color: card.alpha(card.text, modelData.dir ? 0.92 : 0.75); elide: Text.ElideRight
                           width: parent.width - 20; font.family: card.sysFace; font.pixelSize: 14 }
                }
            }
        }
        Text {
            visible: card.f !== null && card.f.kind === "folder" && card.f.count > card.f.items.length
            anchors.bottom: parent.bottom; text: card.f ? "and " + (card.f.count - card.f.items.length) + " more" : ""
            color: card.alpha(card.text, 0.4); font.family: card.uiFace; font.pixelSize: 13
        }
        // a sound, or anything with no picture: its kind in large type, and its words if it has them
        Column {
            anchors.centerIn: parent; spacing: 12
            visible: card.f !== null && (card.f.kind === "audio" || card.f.kind === "other" || ((card.f.kind === "pdf" || card.f.kind === "video") && card.f.preview === ""))
            Text { anchors.horizontalCenter: parent.horizontalCenter; color: card.alpha(card.gold, 0.85); font.family: card.face
                   font.pixelSize: 44; font.letterSpacing: 6
                   text: !card.f ? "" : !card.f.ready ? "…" : card.f.kind === "audio" ? (card.xia ? "SOUND" : "SOUND") : (card.f.name.split(".").length > 1 ? card.f.name.split(".").pop().toUpperCase() : card.f.word.toUpperCase()) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; color: card.alpha(card.text, 0.8); font.family: card.uiFace; font.pixelSize: 18
                   text: card.f && card.f.title ? card.f.title : ""; visible: text !== "" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; color: card.alpha(card.text, 0.5); font.family: card.uiFace; font.pixelSize: 14
                   text: card.f && card.f.artist ? card.f.artist : ""; visible: text !== "" }
        }
    }

    Rectangle { x: 30; y: parent.height - 62; width: parent.width - 60; height: 1; color: card.alpha(card.gold, 0.2) }
    Text {
        x: 34; y: parent.height - 44; width: parent.width - 340
        text: card.meta.join("   ·   "); elide: Text.ElideRight
        color: card.alpha(card.text, 0.6); font.family: card.sysFace; font.pixelSize: 12
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 34; y: parent.height - 44
        text: (card.g.items.length > 1 ? "← → browse   ·   " : "") + "Enter opens   ·   ESC closes"
        color: card.alpha(card.text, 0.35); font.family: card.uiFace; font.pixelSize: 12
    }
}
