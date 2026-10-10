// Tenka welcome: choose your path. Exit codes: 10 samurai, 11 xianxia (+10 = performance mode on).
import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: win
    width: 1180; height: 700
    visible: true
    color: "#0a0908"
    title: "Welcome to Tenka"
    flags: Qt.Window
    property bool lite: Qt.application.arguments.indexOf("--lite") >= 0
    property string reason: { var a = Qt.application.arguments; var i = a.indexOf("--reason"); return i >= 0 && i + 1 < a.length ? a[i + 1] : "" }
    property bool perf: lite
    property int hovered: -1

    function choose(i) { Qt.exit((i === 0 ? 10 : 11) + (perf ? 10 : 0)) }

    Column {
        anchors.top: parent.top; anchors.topMargin: 34
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        Text { text: "Choose your path"; color: "#efe6d6"; font.family: "Cormorant Garamond"; font.pixelSize: 42; font.weight: Font.DemiBold
               anchors.horizontalCenter: parent.horizontalCenter }
        Text { text: "Two complete looks. Switch any time with Super + T, or run tenka-theme."; color: "#9b9488"; font.family: "Inter"; font.pixelSize: 15
               anchors.horizontalCenter: parent.horizontalCenter }
    }

    Row {
        id: cards
        anchors.centerIn: parent; anchors.verticalCenterOffset: 14
        spacing: 28
        Repeater {
            model: [
                { name: "TENKA", sub: "Samurai", tag: "The way of the blade", img: "/usr/share/tenka/themes/samurai/wallpapers/02-torii-night.jpg",
                  crest: "/usr/share/tenka/themes/samurai/crest-1024.png", accent: "#d8412f", gold: "#c9a35a", font: "Cormorant Garamond" },
                { name: "TIANXIA", sub: "Xianxia", tag: "The path to immortality", img: "/usr/share/tenka/themes/xianxia/wallpapers/01-floating-peaks.jpg",
                  crest: "/usr/share/tenka/themes/xianxia/crest-1024.png", accent: "#5fc9a0", gold: "#e2bd6b", font: "Cinzel" }
            ]
            delegate: Item {
                width: 530; height: 400
                scale: ma.containsMouse ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Rectangle { id: frame; anchors.fill: parent; radius: 22; color: "#000"; clip: true
                    border.width: ma.containsMouse ? 2 : 1; border.color: ma.containsMouse ? modelData.accent : "#2a2522"
                    Image { anchors.fill: parent; anchors.margins: 1; source: "file://" + modelData.img; fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 1060; asynchronous: true; opacity: 0.92 }
                    Rectangle { anchors.fill: parent; radius: 22
                        gradient: Gradient { GradientStop { position: 0.35; color: "#00000000" } GradientStop { position: 1.0; color: "#e6000000" } } }
                }
                Image { source: "file://" + modelData.crest; width: 74; height: 74; x: 28; y: 26; smooth: true; mipmap: true }
                Column {
                    x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 26; spacing: 4
                    Text { text: modelData.name; color: "#f4efe6"; font.family: modelData.font; font.pixelSize: 50; font.letterSpacing: 3 }
                    Text { text: modelData.sub + "  ·  " + modelData.tag; color: modelData.gold; font.family: "Cormorant Garamond"; font.italic: true; font.pixelSize: 21 }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.choose(index) }
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 26
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        Text {
            visible: win.lite
            width: 900; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            text: "This machine is running Tenka Lite (" + (win.reason !== "" ? win.reason : "light hardware") + "): the same art on a lighter engine. Pick “Tenka” at the login screen for the full Hyprland desktop on a machine with 3D graphics."
            color: "#c9a35a"; font.family: "Inter"; font.pixelSize: 14
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
            CheckBox { id: cb; checked: win.perf; onToggled: win.perf = checked }
            Text { text: "Performance mode: motion and blur off, all the art stays"; color: "#cfc6b6"; font.family: "Inter"; font.pixelSize: 14
                   anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
