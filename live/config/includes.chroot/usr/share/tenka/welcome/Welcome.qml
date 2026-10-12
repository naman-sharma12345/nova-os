// Tenka welcome: choose your path. Exit codes: 10 samurai, 11 xianxia (+10 = performance mode on), 30 install (live).
// The ledger language of the desk and the control center: ink, 1px gold rules, numbered small caps,
// Marcellus for words, Cinzel Decorative for the two names. No rounded cards, no bounce, no glow.
import QtQuick
import QtQuick.Window

Window {
    id: win
    width: 1180; height: 700
    // shown only after the app has its name: X11 reads WM_CLASS when the window is first created,
    // so docks (XFCE docklike) match it to tenka-theme.desktop (StartupWMClass=tenka-welcome)
    // instead of grouping it under the qml runtime's generic gear
    visible: false
    Component.onCompleted: { Qt.application.name = "tenka-welcome"; visible = true }
    color: "#0a0908"
    title: "Welcome to Tenka"
    // frameless: the welcome draws its own ledger frame (no window-manager title bar over its header);
    // drag anywhere to move, Esc or LATER to close without choosing
    flags: Qt.Window | Qt.FramelessWindowHint
    property bool lite: Qt.application.arguments.indexOf("--lite") >= 0
    property string reason: { var a = Qt.application.arguments; var i = a.indexOf("--reason"); return i >= 0 && i + 1 < a.length ? a[i + 1] : "" }
    property bool perf: lite
    property bool hypr: Qt.application.arguments.indexOf("--hypr") >= 0
    property bool live: Qt.application.arguments.indexOf("--live") >= 0   // running from the USB, the installer is here
    property int peek: { var a = Qt.application.arguments; var i = a.indexOf("--peek"); return i >= 0 && i + 1 < a.length ? Number(a[i + 1]) : -1 }   // renders only
    readonly property color text: "#efe6d6"
    readonly property color sub: "#9b9488"
    readonly property color gold: "#c9a35a"
    readonly property string ui: "Marcellus"

    function choose(i) { Qt.exit((i === 0 ? 10 : 11) + (perf ? 10 : 0)) }
    function al(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: win.al(win.gold, 0.45); z: 100 }
    DragHandler { target: null; onActiveChanged: if (active) win.startSystemMove() }
    Shortcut { sequence: "Esc"; onActivated: Qt.exit(0) }
    Text {
        id: later
        anchors.right: parent.right; anchors.rightMargin: 40; y: 46
        text: "LATER"; font.family: win.ui; font.pixelSize: 12; font.letterSpacing: 5
        color: lm.containsMouse ? win.text : win.al(win.text, 0.45)
        MouseArea { id: lm; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.exit(0) }
    }
    // live session: the installer one click from the first screen (it keeps the path chosen here)
    Row {
        visible: win.live
        anchors.right: later.left; anchors.rightMargin: 44; y: 40; spacing: 12
        Rectangle { width: 7; height: 7; rotation: 45; color: win.gold; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: "INSTALL TO DISK"; font.family: win.ui; font.pixelSize: 12; font.letterSpacing: 5
            color: im.containsMouse ? win.text : win.gold
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.bottom; anchors.topMargin: 6; height: 1
                        color: win.al(win.gold, im.containsMouse ? 0.9 : 0.45) }
            MouseArea { id: im; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.exit(30) }
        }
    }

    // header: a numbered small-caps line, the title, one hairline
    Column {
        x: 60; y: 44; spacing: 10
        Row {
            spacing: 12
            Text { text: "01"; color: win.al(win.gold, 0.7); font.family: win.ui; font.pixelSize: 12; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: 26; height: 1; color: win.al(win.gold, 0.6); anchors.verticalCenter: parent.verticalCenter }
            Text { text: "WELCOME"; color: win.gold; font.family: win.ui; font.pixelSize: 13; font.letterSpacing: 6 }
        }
        Text { text: "Choose your path"; color: win.text; font.family: win.ui; font.pixelSize: 40 }
        Text { text: win.live ? "Two complete looks, the same system. Switch any time with Super + T; the path you pick here is the one the installer keeps."
                              : "Two complete looks, the same system. Switch any time with Super + T."; color: win.sub; font.family: win.ui; font.pixelSize: 15 }
    }

    Row {
        id: cards
        x: 60; y: 196
        spacing: 40
        Repeater {
            model: [
                { num: "I", name: "Tenka", sub: "SAMURAI  ·  THE WAY OF THE BLADE", img: "/usr/share/tenka/themes/samurai/wallpapers/02-torii-night.jpg",
                  crest: "/usr/share/tenka/themes/samurai/crest-1024.png", accent: "#d8412f" },
                { num: "II", name: "Tianxia", sub: "XIANXIA  ·  THE PATH TO IMMORTALITY", img: "/usr/share/tenka/themes/xianxia/wallpapers/01-floating-peaks.jpg",
                  crest: "/usr/share/tenka/themes/xianxia/crest-1024.png", accent: "#5fc9a0" }
            ]
            delegate: Item {
                id: card
                width: 510; height: 330
                readonly property bool on: ma.containsMouse || win.peek === index
                // the art, quiet until you point at it
                Image { anchors.fill: parent; anchors.margins: 8; source: "file://" + modelData.img; fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 1020; asynchronous: true; opacity: card.on ? 0.95 : 0.62
                        Behavior on opacity { NumberAnimation { duration: 220 } } }
                Rectangle { anchors.fill: parent; anchors.margins: 8
                    gradient: Gradient { GradientStop { position: 0.3; color: "#00000000" } GradientStop { position: 1.0; color: "#e60a0908" } } }
                // the frame: one gold hairline with its numeral sitting in a gap at the top left
                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: card.on ? modelData.accent : win.al(win.gold, 0.45)
                            Behavior on border.color { ColorAnimation { duration: 220 } } }
                Rectangle { x: 18; y: -1; width: numT.width + 16; height: 3; color: win.color }
                Text { id: numT; x: 26; y: -8; text: modelData.num; color: card.on ? modelData.accent : win.gold; font.family: win.ui; font.pixelSize: 13; font.letterSpacing: 3 }
                Image { source: "file://" + modelData.crest; width: 40; height: 40; x: 26; y: 26; smooth: true; mipmap: true; opacity: 0.95 }
                Column {
                    x: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; spacing: 10
                    Text { text: modelData.name; color: win.text; font.family: "Cinzel Decorative"; font.pixelSize: 46; font.letterSpacing: 2 }
                    Row {
                        spacing: 12
                        Rectangle { width: 30; height: 2; color: modelData.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.sub; color: win.al(win.text, 0.75); font.family: win.ui; font.pixelSize: 12; font.letterSpacing: 4 }
                    }
                }
                Text { anchors.right: parent.right; anchors.rightMargin: 28; y: 38
                       text: "BEGIN"; color: card.on ? modelData.accent : win.al(win.gold, 0.0); font.family: win.ui; font.pixelSize: 12; font.letterSpacing: 5
                       Behavior on color { ColorAnimation { duration: 220 } } }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.choose(index) }
            }
        }
    }

    // footer: one hairline, then the machine note and the performance switch as a ruled box
    Rectangle { x: 60; y: 572; width: win.width - 120; height: 1; color: win.al(win.gold, 0.3) }
    Row {
        x: 60; y: 596; spacing: 14
        Item {
            width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
            Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: win.al(win.gold, 0.8) }
            Rectangle { anchors.centerIn: parent; width: 7; height: 7; rotation: 45; color: win.gold; visible: win.perf }
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: win.perf = !win.perf }
        }
        Column {
            spacing: 4
            Text { text: "PERFORMANCE MODE"; color: win.text; font.family: win.ui; font.pixelSize: 12; font.letterSpacing: 4
                   MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.perf = !win.perf } }
            Text { text: "Motion and blur rest; all the art stays."; color: win.sub; font.family: win.ui; font.pixelSize: 13 }
        }
    }
    Text {
        visible: win.lite
        x: 520; y: 596; width: win.width - 580; wrapMode: Text.WordWrap; lineHeight: 1.2
        text: win.hypr ? "This machine has " + win.reason + ", so performance mode starts on. For the lightest feel, pick Tenka Lite at the login screen."
                      : "Running Tenka Lite (" + win.reason + "): the same art on a lighter engine. Pick Tenka at the login screen for the full Hyprland desktop."
        color: win.al(win.gold, 0.9); font.family: win.ui; font.pixelSize: 13
    }
}
