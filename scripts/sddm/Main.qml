// Tenka SDDM greeter: one QML, two theme packs (theme.conf carries colours, art and words).
// The background is the boot splash's own last frame, so Plymouth hands over without a seam:
// the enso (or jade ring) the splash painted settles back into a watermark, and the clock and
// a frosted card rise into the title column.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920; height: 1080
    color: config.base
    readonly property real s: Math.min(width / 1920, height / 1080)
    readonly property real ox: (width - 1920 * s) / 2
    readonly property real colX: ox + 470 * s          // centre of the title column
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    readonly property var hours: ["Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"]
    property date now: new Date()
    property real intro: 0
    NumberAnimation on intro { from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic; running: true }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Repeater { id: userRep; model: userModel; delegate: Item { property string uname: model.name; property string rname: model.realName } }
    Repeater { id: sessRep; model: sessionModel; delegate: Item { property string sname: model.name } }

    function currentUser() { var it = userRep.itemAt(userIndex); return it ? it.uname : userModel.lastUser }
    function currentReal() { var it = userRep.itemAt(userIndex); return it && it.rname !== "" ? it.rname : currentUser() }
    function currentSession() { var it = sessRep.itemAt(sessionIndex); return it ? it.sname : "" }
    function al(c, a) { var q = Qt.darker(c, 1.0); return Qt.rgba(q.r, q.g, q.b, a) }
    function doLogin() { errorText.opacity = 0; sddm.login(currentUser(), pw.text, sessionIndex) }
    function shichen() { return "Hour of the " + hours[Math.floor(((now.getHours() + 1) % 24) / 2)] }

    Connections {
        target: sddm
        function onLoginFailed() { pw.text = ""; errorText.opacity = 1; shake.restart(); pw.forceActiveFocus() }
    }

    // ---------- the splash's last frame ----------
    Image {
        id: bg
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }
    // the enso / ring and the seal, exactly where the splash left them, settling into a watermark
    Image {
        source: config.enso
        width: 520 * root.s; height: width; smooth: true
        x: root.colX - width / 2; y: 420 * root.s - height / 2
        opacity: 1 - 0.86 * root.intro
    }
    Image {
        source: config.seal
        width: 211 * root.s; height: width; smooth: true
        x: root.colX + 175 * root.s - width / 2; y: 585 * root.s - height / 2
        opacity: 1 - root.intro
    }

    // ---------- the title column: clock, date, card ----------
    Item {
        id: column
        x: root.colX - 260 * root.s; width: 520 * root.s
        y: (210 + 40 * (1 - root.intro)) * root.s; height: 760 * root.s
        opacity: root.intro

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "hh:mm")
            color: config.text
            font.family: config.displayFont; font.pixelSize: 132 * root.s; font.letterSpacing: 6 * root.s
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: config.glow; shadowBlur: 1.0; shadowOpacity: 0.55; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
        }
        Rectangle {   // gold hairline with a bead
            id: rule
            anchors.top: clock.bottom; anchors.topMargin: 4 * root.s
            anchors.horizontalCenter: parent.horizontalCenter
            width: 360 * root.s; height: 1
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: config.gold }
                GradientStop { position: 1; color: "transparent" } }
            Rectangle { width: 8 * root.s; height: width; rotation: 45; color: config.gold; anchors.centerIn: parent }
        }
        Text {
            id: date
            anchors.top: rule.bottom; anchors.topMargin: 18 * root.s
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd  ·  d MMMM").toUpperCase() + "  ·  " + root.shichen().toUpperCase()
            color: config.gold
            font.family: config.displayFont; font.pixelSize: 17 * root.s; font.letterSpacing: 4 * root.s
        }

        // frosted card
        Item {
            id: card
            anchors.top: date.bottom; anchors.topMargin: 54 * root.s
            anchors.horizontalCenter: parent.horizontalCenter
            width: 460 * root.s; height: 330 * root.s
            SequentialAnimation {
                id: shake
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -14 * root.s; duration: 60 }
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12 * root.s; duration: 60 }
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6 * root.s; duration: 60 }
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }
            ShaderEffectSource {
                id: glassSrc
                anchors.fill: parent
                sourceItem: bg
                sourceRect: Qt.rect(card.mapToItem(bg, 0, 0).x, card.mapToItem(bg, 0, 0).y, card.width, card.height)
                visible: false
            }
            Rectangle { id: glassMask; anchors.fill: parent; radius: 22 * root.s; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: parent
                source: glassSrc
                blurEnabled: true; blur: 1.0; blurMax: 64
                saturation: -0.2; brightness: -0.08
                maskEnabled: true; maskSource: glassMask
            }
            Rectangle {
                anchors.fill: parent
                radius: 22 * root.s
                color: root.al(config.base, 0.42)
                border.color: root.al(config.gold, 0.30); border.width: 1
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 84 * root.s
                spacing: 20 * root.s

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16 * root.s
                    Image { source: config.crest; width: 44 * root.s; height: width; smooth: true; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: root.currentReal()
                        color: config.text; font.family: config.displayFont; font.pixelSize: 32 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.userIndex = (root.userIndex + 1) % Math.max(1, userRep.count) }
                    }
                }
                TextField {
                    id: pw
                    width: parent.width; height: 52 * root.s
                    echoMode: TextInput.Password; passwordCharacter: "•"
                    placeholderText: config.passwordHint
                    placeholderTextColor: root.al(config.subtext, 0.85)
                    color: config.text; font.family: config.displayFont; font.pixelSize: 19 * root.s; font.letterSpacing: 1
                    horizontalAlignment: TextInput.AlignHCenter
                    focus: true
                    background: Item {
                        Rectangle { anchors.fill: parent; radius: 12 * root.s; color: root.al(config.base, 0.45) }
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                            height: 2; width: pw.activeFocus ? parent.width - 24 * root.s : parent.width * 0.4
                            color: config.accent; radius: 1
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                    Keys.onReturnPressed: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()
                    Component.onCompleted: forceActiveFocus()
                }
                Item {
                    id: go
                    width: parent.width; height: 52 * root.s
                    Image { anchors.fill: parent; source: config.button; smooth: true; opacity: goArea.containsMouse ? 1 : 0.9 }
                    Text { anchors.centerIn: parent; text: config.enterText; color: config.onAccent
                           font.family: config.displayFont; font.pixelSize: 21 * root.s; font.letterSpacing: 5 * root.s }
                    MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                }
                Text { id: errorText; text: config.failText; color: config.accent; opacity: 0; height: 0
                       font.family: config.displayFont; font.pixelSize: 15 * root.s; anchors.horizontalCenter: parent.horizontalCenter
                       Behavior on opacity { NumberAnimation { duration: 300 } } }
                Text {
                    text: root.currentSession() + "   ▾"
                    color: root.al(config.subtext, 0.95); font.family: config.displayFont; font.pixelSize: 16 * root.s; font.letterSpacing: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessRep.count) }
                }
            }
        }
    }

    // ---------- bottom: power, in Marcellus ----------
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 64 * root.s; anchors.bottomMargin: 48 * root.s
        spacing: 40 * root.s
        opacity: root.intro
        Repeater {
            model: [ { t: config.suspendText, a: 0, ok: sddm.canSuspend },
                     { t: config.rebootText, a: 1, ok: sddm.canReboot },
                     { t: config.shutdownText, a: 2, ok: sddm.canPowerOff } ]
            delegate: Text {
                visible: modelData.ok
                text: modelData.t.toUpperCase()
                color: pa.containsMouse ? config.gold : root.al(config.text, 0.7)
                font.family: config.displayFont; font.pixelSize: 16 * root.s; font.letterSpacing: 4 * root.s
                MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.a === 0 ? sddm.suspend() : (modelData.a === 1 ? sddm.reboot() : sddm.powerOff()) }
            }
        }
    }
    Text {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: 150 * root.s; anchors.bottomMargin: 48 * root.s
        opacity: root.intro
        text: config.footer.toUpperCase(); color: root.al(config.text, 0.45)
        font.family: config.displayFont; font.pixelSize: 14 * root.s; font.letterSpacing: 4 * root.s
    }
}
