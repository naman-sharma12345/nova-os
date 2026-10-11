// The lock screen's face, shared by the real session lock and the preview window (TENKA_LOCK_PREVIEW=1).
// Four directions: "ledger" (default: the desk's language, a ruled column at the lower left, an
// underline field, no fills), "card" (the title card), "brush" (a giant weekday written behind a
// centred clock), "still" (almost nothing: the frosted art, the time, a gold rule that takes your password).
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: face
    property var lock
    readonly property real s: Math.min(width / 1920, height / 1080)
    readonly property string style: Quickshell.env("TENKA_LOCK") || Theme.desk.lock || "ledger"

    Image { anchors.fill: parent; source: Theme.wallBlur; fillMode: Image.PreserveAspectCrop; smooth: true }
    Image { anchors.fill: parent; source: Theme.t.wallpaper; fillMode: Image.PreserveAspectCrop; opacity: 0.35; sourceSize.width: 1920 }
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, 0.25) }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: Theme.alpha(Theme.t.base, 0.72) }
            GradientStop { position: 0.38; color: Theme.alpha(Theme.t.base, 0.35) }
            GradientStop { position: 0.62; color: Theme.alpha(Theme.t.base, 0.0) } }
    }
    Image { anchors.fill: parent; source: "assets/vignette.png" }

    Item {
        visible: face.style === "card"
        x: 136 * face.s; y: 190 * face.s; width: 900 * face.s; height: 700 * face.s
        Row {
            id: hr; spacing: 14 * face.s
            Rectangle { width: 8 * face.s; height: width; rotation: 45; color: Theme.t.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Theme.hourName(Theme.now).toUpperCase(); color: Theme.t.gold; font.family: Theme.display
                   font.pixelSize: 17 * face.s; font.letterSpacing: 9 * face.s }
        }
        Row {
            id: cr; anchors.top: hr.bottom; anchors.topMargin: -20 * face.s; x: -8 * face.s; spacing: 30 * face.s
            Text { id: ct; text: Theme.hm(Theme.now); color: Theme.t.text; font.family: Theme.display
                   font.pixelSize: 250 * face.s; font.letterSpacing: -2 * face.s
                   layer.enabled: !Theme.perf
                   layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.3; shadowOpacity: 0.35; shadowVerticalOffset: 3 } }
            Item {
                anchors.top: ct.top; anchors.topMargin: 70 * face.s; width: 84 * face.s; height: 160 * face.s
                Text { id: ap; text: Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.75); anchors.horizontalCenter: parent.horizontalCenter
                       font.family: Theme.display; font.pixelSize: 22 * face.s; font.letterSpacing: 5 * face.s }
                Image {
                    anchors.top: ap.bottom; anchors.topMargin: 12 * face.s; anchors.horizontalCenter: parent.horizontalCenter
                    width: 84 * face.s; height: 104 * face.s; source: Theme.asset("seal.png"); rotation: -2; smooth: true
                    Column { anchors.centerIn: parent
                        Text { text: Qt.formatDate(Theme.now, "ddd").toUpperCase(); color: Theme.t.ink; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 17 * face.s; font.letterSpacing: 3 * face.s }
                        Text { text: Theme.now.getDate(); color: Theme.t.ink; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 40 * face.s } }
                }
            }
        }
        Text { id: dt; anchors.top: cr.bottom; anchors.topMargin: -18 * face.s; x: 6 * face.s
               text: Qt.formatDate(Theme.now, "MMMM yyyy").toUpperCase(); color: Theme.alpha(Theme.t.text, 0.8)
               font.family: Theme.display; font.pixelSize: 19 * face.s; font.letterSpacing: 9 * face.s }
        Text { id: ttl; anchors.top: dt.bottom; anchors.topMargin: 40 * face.s; x: 6 * face.s
               text: Theme.xia ? "The sect gate is sealed." : "The blade rests."
               color: Theme.t.text; font.family: Theme.display; font.pixelSize: 34 * face.s }

        // the password pill
        Rectangle {
            id: pill
            anchors.top: ttl.bottom; anchors.topMargin: 30 * face.s; x: 6 * face.s
            width: 420 * face.s; height: 60 * face.s; radius: height / 2
            color: Theme.alpha(Theme.t.base, 0.55); border.width: 1
            border.color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.gold, field.activeFocus ? 0.7 : 0.4)
            Image { x: 10 * face.s; anchors.verticalCenter: parent.verticalCenter; width: 40 * face.s; height: 40 * face.s; source: Theme.t.crest; mipmap: true }
            Row {
                x: 64 * face.s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * face.s
                visible: face.lock.typed.length > 0
                Repeater { model: Math.min(face.lock.typed.length, 18)
                    Rectangle { width: 9 * face.s; height: width; radius: Theme.xia ? width / 2 : 1.5; rotation: Theme.xia ? 0 : 45; color: Theme.t.gold } }
            }
            Text { x: 64 * face.s; anchors.verticalCenter: parent.verticalCenter; visible: face.lock.typed.length === 0
                   text: Theme.xia ? "Speak the word" : "Your password"; color: Theme.alpha(Theme.t.text, 0.45)
                   font.family: Theme.display; font.pixelSize: 18 * face.s; font.letterSpacing: 1 }
            Rectangle { anchors.right: parent.right; anchors.rightMargin: 8 * face.s; anchors.verticalCenter: parent.verticalCenter
                        width: 44 * face.s; height: width; radius: width / 2; color: Theme.t.accent; opacity: face.lock.busy ? 0.5 : 1
                        Text { anchors.centerIn: parent; text: "\uf061"; font.family: Theme.glyphs; font.pixelSize: 16 * face.s; color: Theme.t.ink }
                        MouseArea { anchors.fill: parent; onClicked: face.lock.submit() } }
            TextInput {
                id: field; anchors.fill: parent; opacity: 0; focus: true; echoMode: TextInput.Password
                text: face.lock.typed; onTextChanged: face.lock.typed = text
                Keys.onReturnPressed: face.lock.submit(); Keys.onEnterPressed: face.lock.submit()
                Component.onCompleted: forceActiveFocus()
            }
        }
        Text { anchors.top: pill.bottom; anchors.topMargin: 14 * face.s; x: 30 * face.s
               text: face.lock.status !== "" ? face.lock.status : (Theme.xia ? "Enter to pass the gate" : "Enter to draw the blade")
               color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12 * face.s }
    }
    Row {
        visible: face.style !== "still" && face.style !== "ledger"
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 40 * face.s; spacing: 12 * face.s
        Text { text: (Quickshell.env("USER") || ""); color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display; font.pixelSize: 14 * face.s; font.letterSpacing: 3 }
        Image { source: Theme.t.crest; width: 22 * face.s; height: 22 * face.s; mipmap: true; anchors.verticalCenter: parent.verticalCenter }
    }


    // shared input for the other directions
    TextInput {
        id: field2; visible: face.style !== "card"; width: 1; height: 1; opacity: 0; focus: face.style !== "card"
        echoMode: TextInput.Password; text: face.lock.typed; onTextChanged: face.lock.typed = text
        Keys.onReturnPressed: face.lock.submit(); Keys.onEnterPressed: face.lock.submit()
        Component.onCompleted: if (visible) forceActiveFocus()
    }
    readonly property string motto: Theme.xia ? "The sect gate is sealed." : "The blade rests."
    readonly property string hint: face.lock.status !== "" ? face.lock.status : (Theme.xia ? "speak the word" : "your password")

    // ---- "brush": the weekday, enormous and faint, written behind a centred clock
    Item {
        visible: face.style === "brush"
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, 0.35) }
        Text {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -60 * face.s
            text: Qt.formatDate(Theme.now, "dddd").toUpperCase()
            color: "transparent"; style: Text.Outline; styleColor: Theme.alpha(Theme.t.gold, 0.35)
            font.family: Theme.brand; font.pixelSize: 300 * face.s; font.letterSpacing: 10 * face.s
            scale: Math.min(1, (parent.width * 0.96) / Math.max(1, implicitWidth))
        }
        Rectangle {   // a single vermilion / jade stroke under the word
            anchors.centerIn: parent; anchors.verticalCenterOffset: 70 * face.s
            width: 520 * face.s; height: 3 * face.s; radius: height / 2; color: Theme.t.accent; opacity: 0.85
        }
        Column {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -40 * face.s; spacing: 0
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.hm(Theme.now); color: Theme.t.text
                   font.family: Theme.display; font.pixelSize: 190 * face.s
                   layer.enabled: !Theme.perf
                   layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.3; shadowOpacity: 0.4; shadowVerticalOffset: 2 } }
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.5 + 110 * face.s; spacing: 18 * face.s
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: face.motto; color: Theme.t.text
                   font.family: Theme.display; font.pixelSize: 26 * face.s; font.letterSpacing: 2 }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 360 * face.s; height: 50 * face.s; radius: height / 2
                color: Theme.alpha(Theme.t.base, 0.5); border.width: 1
                border.color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.gold, 0.55)
                Row { anchors.centerIn: parent; spacing: 9 * face.s; visible: face.lock.typed.length > 0
                      Repeater { model: Math.min(face.lock.typed.length, 18)
                          Rectangle { width: 8 * face.s; height: width; radius: Theme.xia ? width / 2 : 1.5; rotation: Theme.xia ? 0 : 45; color: Theme.t.gold } } }
                Text { anchors.centerIn: parent; visible: face.lock.typed.length === 0; text: face.hint
                       color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.5)
                       font.family: Theme.display; font.pixelSize: 16 * face.s; font.letterSpacing: 3 }
            }
        }
    }

    // ---- "still": the art, the time, and a gold rule that takes your password
    Item {
        visible: face.style === "still"
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, 0.2) }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.70; spacing: 14 * face.s
            Image { anchors.horizontalCenter: parent.horizontalCenter; width: 30 * face.s; height: 38 * face.s; source: Theme.asset("seal.png"); smooth: true
                Text { anchors.centerIn: parent; text: Theme.now.getDate(); color: Theme.t.ink; font.family: Theme.display; font.pixelSize: 15 * face.s } }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.hm(Theme.now) + "  " + Theme.ap(Theme.now); color: Theme.t.text
                   font.family: Theme.display; font.pixelSize: 44 * face.s; font.letterSpacing: 6 * face.s }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter; width: 300 * face.s; height: 30 * face.s
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                    color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.gold, 0.6) }
                Row { anchors.centerIn: parent; spacing: 8 * face.s; visible: face.lock.typed.length > 0
                      Repeater { model: Math.min(face.lock.typed.length, 18)
                          Rectangle { width: 5 * face.s; height: width; radius: width / 2; color: Theme.t.gold } } }
                Text { anchors.centerIn: parent; visible: face.lock.typed.length === 0; text: face.hint
                       color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.45)
                       font.family: Theme.display; font.pixelSize: 13 * face.s; font.letterSpacing: 5 * face.s }
            }
        }
    }

    // ---- "ledger": a ruled column at the lower left, in the desk's language. No fills, no glow.
    Item {
        visible: face.style === "ledger"
        anchors.fill: parent
        readonly property color bad: Theme.t.accent
        Column {
            x: 140 * face.s; anchors.bottom: parent.bottom; anchors.bottomMargin: 150 * face.s
            spacing: 0
            // 01 · the day, in small caps
            Row {
                spacing: 14 * face.s
                Text { text: "01"; color: Theme.alpha(Theme.t.gold, 0.7); font.family: Theme.display
                       font.pixelSize: 13 * face.s; font.letterSpacing: 3 * face.s; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 28 * face.s; height: 1; color: Theme.alpha(Theme.t.gold, 0.6); anchors.verticalCenter: parent.verticalCenter }
                Text { text: Qt.formatDate(Theme.now, "dddd  ·  d MMMM").toUpperCase(); color: Theme.t.gold
                       font.family: Theme.display; font.pixelSize: 15 * face.s; font.letterSpacing: 6 * face.s }
            }
            // the time
            Row {
                spacing: 18 * face.s
                Text { id: lt; text: Theme.hm(Theme.now); color: Theme.t.text; font.family: Theme.display
                       font.pixelSize: 176 * face.s; font.letterSpacing: -1 * face.s }
                Text { text: Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display
                       font.pixelSize: 20 * face.s; font.letterSpacing: 5 * face.s
                       anchors.baseline: lt.baseline }
            }
            // the rule: one hairline with a short accent at its head
            Item {
                width: 470 * face.s; height: 2 * face.s
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Theme.alpha(Theme.t.gold, 0.55) }
                Rectangle { width: 56 * face.s; height: 2 * face.s; color: Theme.t.accent }
            }
            Item { width: 1; height: 22 * face.s }
            Text { text: face.motto; color: Theme.alpha(Theme.t.text, 0.9); font.family: Theme.display
                   font.pixelSize: 24 * face.s; font.letterSpacing: 1 }
            Item { width: 1; height: 44 * face.s }
            // 02 · the field: a label, the marks, one underline
            Row {
                spacing: 14 * face.s
                Text { text: "02"; color: Theme.alpha(Theme.t.gold, 0.7); font.family: Theme.display
                       font.pixelSize: 13 * face.s; font.letterSpacing: 3 * face.s; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 28 * face.s; height: 1; color: Theme.alpha(Theme.t.gold, 0.6); anchors.verticalCenter: parent.verticalCenter }
                Text { text: (Theme.xia ? "THE WORD" : "PASSWORD") + "  ·  " + (Quickshell.env("USER") || "").toUpperCase()
                       color: Theme.alpha(Theme.t.text, 0.65); font.family: Theme.display; font.pixelSize: 13 * face.s; font.letterSpacing: 5 * face.s }
            }
            Item { width: 1; height: 10 * face.s }
            Item {
                width: 470 * face.s; height: 44 * face.s
                Row { anchors.verticalCenter: parent.verticalCenter; spacing: 11 * face.s; visible: face.lock.typed.length > 0
                      Repeater { model: Math.min(face.lock.typed.length, 24)
                          Rectangle { width: 7 * face.s; height: width; radius: Theme.xia ? width / 2 : 0; rotation: Theme.xia ? 0 : 45; color: Theme.t.gold } } }
                Text { anchors.verticalCenter: parent.verticalCenter; visible: face.lock.typed.length === 0
                       text: face.lock.status !== "" ? face.lock.status : (Theme.xia ? "Speak the word" : "Type to unlock")
                       color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.4)
                       font.family: Theme.display; font.pixelSize: 18 * face.s; font.letterSpacing: 1 }
                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                       text: face.lock.busy ? "· · ·" : "ENTER"; color: Theme.alpha(Theme.t.gold, face.lock.typed.length > 0 ? 0.95 : 0.45)
                       font.family: Theme.display; font.pixelSize: 12 * face.s; font.letterSpacing: 5 * face.s
                       MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: face.lock.submit() } }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                            color: face.lock.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.gold, face.lock.typed.length > 0 ? 0.9 : 0.5) }
            }
        }
    }
}
