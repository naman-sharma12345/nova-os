// The lock screen is the desktop's title card: the art softly frosted, an ink falloff, the hour's
// old name, the clock with the day's seal, the pack's line and one quiet pill for your password.
// `qs -c tenka ipc call lock lock` (tenka-lock / hypridle) locks; PAM unlocks.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    property string typed: ""
    property string status: ""
    property bool busy: false

    IpcHandler { target: "lock"; function lock(): void { root.typed = ""; root.status = ""; lk.locked = true } }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: { if (responseRequired) respond(root.typed) }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) { lk.locked = false; root.typed = ""; root.status = "" }
            else { root.status = Theme.xia ? "The seal holds. Try again." : "The gate stays shut. Try again."; root.typed = "" }
        }
    }
    function submit() { if (root.busy || root.typed === "") return; root.busy = true; root.status = ""; pam.start() }

    WlSessionLock {
        id: lk
        WlSessionLockSurface {
            id: surf
            color: Theme.t.base
            readonly property real s: Math.min(width / 1920, height / 1080)

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
                x: 136 * surf.s; y: 190 * surf.s; width: 900 * surf.s; height: 700 * surf.s
                Row {
                    id: hr; spacing: 14 * surf.s
                    Rectangle { width: 8 * surf.s; height: width; rotation: 45; color: Theme.t.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Theme.hourName(Theme.now).toUpperCase(); color: Theme.t.gold; font.family: Theme.display
                           font.pixelSize: 17 * surf.s; font.letterSpacing: 9 * surf.s }
                }
                Row {
                    id: cr; anchors.top: hr.bottom; anchors.topMargin: -20 * surf.s; x: -8 * surf.s; spacing: 30 * surf.s
                    Text { id: ct; text: Theme.hm(Theme.now); color: Theme.t.text; font.family: Theme.display
                           font.pixelSize: 250 * surf.s; font.letterSpacing: -2 * surf.s
                           layer.enabled: true
                           layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.xia ? Theme.t.accent : "black"; shadowBlur: 1.0; shadowOpacity: 0.45 } }
                    Item {
                        anchors.top: ct.top; anchors.topMargin: 70 * surf.s; width: 84 * surf.s; height: 160 * surf.s
                        Text { id: ap; text: Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.75); anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 22 * surf.s; font.letterSpacing: 5 * surf.s }
                        Image {
                            anchors.top: ap.bottom; anchors.topMargin: 12 * surf.s; anchors.horizontalCenter: parent.horizontalCenter
                            width: 84 * surf.s; height: 104 * surf.s; source: Theme.asset("seal.png"); rotation: -2; smooth: true
                            Column { anchors.centerIn: parent
                                Text { text: Qt.formatDate(Theme.now, "ddd").toUpperCase(); color: Theme.t.ink; anchors.horizontalCenter: parent.horizontalCenter
                                       font.family: Theme.display; font.pixelSize: 17 * surf.s; font.letterSpacing: 3 * surf.s }
                                Text { text: Theme.now.getDate(); color: Theme.t.ink; anchors.horizontalCenter: parent.horizontalCenter
                                       font.family: Theme.display; font.pixelSize: 40 * surf.s } }
                        }
                    }
                }
                Text { id: dt; anchors.top: cr.bottom; anchors.topMargin: -18 * surf.s; x: 6 * surf.s
                       text: Qt.formatDate(Theme.now, "MMMM yyyy").toUpperCase(); color: Theme.alpha(Theme.t.text, 0.8)
                       font.family: Theme.display; font.pixelSize: 19 * surf.s; font.letterSpacing: 9 * surf.s }
                Text { id: ttl; anchors.top: dt.bottom; anchors.topMargin: 40 * surf.s; x: 6 * surf.s
                       text: Theme.xia ? "The sect gate is sealed." : "The blade rests."
                       color: Theme.t.text; font.family: Theme.display; font.pixelSize: 34 * surf.s }

                // the password pill
                Rectangle {
                    id: pill
                    anchors.top: ttl.bottom; anchors.topMargin: 30 * surf.s; x: 6 * surf.s
                    width: 420 * surf.s; height: 60 * surf.s; radius: height / 2
                    color: Theme.alpha(Theme.t.base, 0.55); border.width: 1
                    border.color: root.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.gold, field.activeFocus ? 0.7 : 0.4)
                    Image { x: 10 * surf.s; anchors.verticalCenter: parent.verticalCenter; width: 40 * surf.s; height: 40 * surf.s; source: Theme.t.crest; mipmap: true }
                    Row {
                        x: 64 * surf.s; anchors.verticalCenter: parent.verticalCenter; spacing: 10 * surf.s
                        visible: root.typed.length > 0
                        Repeater { model: Math.min(root.typed.length, 18)
                            Rectangle { width: 9 * surf.s; height: width; radius: Theme.xia ? width / 2 : 1.5; rotation: Theme.xia ? 0 : 45; color: Theme.t.gold } }
                    }
                    Text { x: 64 * surf.s; anchors.verticalCenter: parent.verticalCenter; visible: root.typed.length === 0
                           text: Theme.xia ? "Speak the word" : "Your password"; color: Theme.alpha(Theme.t.text, 0.45)
                           font.family: Theme.display; font.pixelSize: 18 * surf.s; font.letterSpacing: 1 }
                    Rectangle { anchors.right: parent.right; anchors.rightMargin: 8 * surf.s; anchors.verticalCenter: parent.verticalCenter
                                width: 44 * surf.s; height: width; radius: width / 2; color: Theme.t.accent; opacity: root.busy ? 0.5 : 1
                                Text { anchors.centerIn: parent; text: "\uf061"; font.family: Theme.glyphs; font.pixelSize: 16 * surf.s; color: Theme.t.ink }
                                MouseArea { anchors.fill: parent; onClicked: root.submit() } }
                    TextInput {
                        id: field; anchors.fill: parent; opacity: 0; focus: true; echoMode: TextInput.Password
                        text: root.typed; onTextChanged: root.typed = text
                        Keys.onReturnPressed: root.submit(); Keys.onEnterPressed: root.submit()
                        Component.onCompleted: forceActiveFocus()
                    }
                }
                Text { anchors.top: pill.bottom; anchors.topMargin: 14 * surf.s; x: 30 * surf.s
                       text: root.status !== "" ? root.status : (Theme.xia ? "Enter to pass the gate" : "Enter to draw the blade")
                       color: root.status !== "" ? Theme.t.accent : Theme.alpha(Theme.t.text, 0.5); font.family: Theme.ui; font.pixelSize: 12 * surf.s }
            }
            Row {
                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 40 * surf.s; spacing: 12 * surf.s
                Text { text: (Quickshell.env("USER") || ""); color: Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display; font.pixelSize: 14 * surf.s; font.letterSpacing: 3 }
                Image { source: Theme.t.crest; width: 22 * surf.s; height: 22 * surf.s; mipmap: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
