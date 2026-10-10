// Tenka SDDM greeter: one QML, two theme packs (theme.conf carries colours, art and words).
// Three faces, picked by theme.conf `style` (or /etc/tenka/login-style through the pack's
// theme.conf.user):
//   "title" (default): the boot menu's own title screen carried on into the login, the same art,
//                      the same baked wordmark and the same brush stroke on the chosen entry.
//                      A menu you drive with the keyboard: you, your session, rest, sheathe.
//   "brush":           the lock screen's face: the weekday written enormous behind the clock.
//   "card":            the v3 title column with a frosted card (the splash's last frame).
// One hidden TextInput holds the password for every face, so focus and login live in one place.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920; height: 1080
    color: config.base
    readonly property string face: (config.style && config.style !== "") ? config.style : "title"
    readonly property bool xia: config.pack === "xianxia"
    readonly property real s: Math.min(width / 1920, height / 1080)
    readonly property real ox: (width - 1920 * s) / 2
    readonly property real colX: ox + 470 * s          // centre of the card face's title column
    // the title art is cropped to fill; k/ix/iy map its 1920x1080 design grid onto the screen
    readonly property real k: Math.max(width / 1920, height / 1080)
    readonly property real ix: (width - 1920 * k) / 2
    readonly property real iy: (height - 1080 * k) / 2
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    readonly property var hours: ["Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"]
    property date now: new Date()
    property real intro: 0
    property bool failed: false
    NumberAnimation on intro { from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic; running: true }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Repeater { id: userRep; model: userModel; delegate: Item { property string uname: model.name; property string rname: model.realName } }
    Repeater { id: sessRep; model: sessionModel; delegate: Item { property string sname: model.name } }

    function currentUser() { var it = userRep.itemAt(userIndex); return it ? it.uname : (userModel.lastUser || "") }
    function currentReal() { var it = userRep.itemAt(userIndex); var n = it && it.rname !== "" ? it.rname : currentUser()
        // the live ISO's account is "Live session user": on the title screen it is simply the wanderer
        return (n === "" || /^live/i.test(n)) ? "Wanderer" : n }
    function currentSession() { var it = sessRep.itemAt(sessionIndex); return it ? it.sname : (xia ? "Tianxia" : "Tenka") }
    function al(c, a) { var q = Qt.darker(c, 1.0); return Qt.rgba(q.r, q.g, q.b, a) }
    function doLogin() { root.failed = false; sddm.login(currentUser(), pw.text, sessionIndex) }
    function nextSession(d) { var n = Math.max(1, sessRep.count); sessionIndex = (sessionIndex + d + n) % n }
    function shichen() { return "Hour of the " + hours[Math.floor(((now.getHours() + 1) % 24) / 2)] }
    function hm() { return Qt.formatTime(now, "hh:mm") }

    Connections {
        target: sddm
        function onLoginFailed() { pw.text = ""; root.failed = true; shake.restart(); pw.forceActiveFocus() }
    }

    // the one password field (invisible): every face draws its own view of it
    TextInput {
        id: pw
        width: 1; height: 1; opacity: 0
        echoMode: TextInput.Password
        focus: true
        onTextChanged: if (text.length > 0) root.failed = false
        Keys.onReturnPressed: titleMenu.activate()
        Keys.onEnterPressed: titleMenu.activate()
        Keys.onUpPressed: titleMenu.move(-1)
        Keys.onDownPressed: titleMenu.move(1)
        Keys.onLeftPressed: if (root.face !== "title" || titleMenu.rows[titleMenu.cur].kind === "session") root.nextSession(-1)
        Keys.onRightPressed: if (root.face !== "title" || titleMenu.rows[titleMenu.cur].kind === "session") root.nextSession(1)
        Keys.onTabPressed: root.nextSession(1)
        Component.onCompleted: forceActiveFocus()
    }
    MouseArea { anchors.fill: parent; onClicked: pw.forceActiveFocus(); z: -1 }
    // the shared shake on a failed login
    property real shakeX: 0
    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeX"; to: -14; duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: 12; duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: -6; duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 60 }
    }

    // ======================================================================= "title"
    Item {
        id: titleFace
        visible: root.face === "title"
        anchors.fill: parent
        Image { anchors.fill: parent; source: "title.jpg"; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: false }

        // bottom right, on the key line's baseline: the time and the hour, so the art keeps its sky
        Row {
            x: root.ix + (1920 - 116) * root.k - width; y: root.iy + 1012 * root.k - height
            spacing: 18 * root.k
            opacity: root.intro * 0.95
            Text { anchors.baseline: clk.baseline; text: (Qt.formatDate(root.now, "dddd  ·  d MMMM") + "  ·  " + root.shichen()).toUpperCase()
                   color: root.al(config.gold, 0.85); font.family: config.displayFont; font.pixelSize: 15 * root.k; font.letterSpacing: 3.5 * root.k }
            Text { id: clk; text: root.hm(); color: config.text
                   font.family: config.displayFont; font.pixelSize: 40 * root.k; font.letterSpacing: 5 * root.k }
        }

        // the menu, on the boot menu's own grid: left 116, top 540, rows of 62 + 10
        Item {
            id: titleMenu
            x: root.ix + 116 * root.k + root.shakeX * root.k; y: root.iy + 540 * root.k
            width: 760 * root.k; height: 4 * 72 * root.k
            opacity: root.intro
            property int cur: 0
            readonly property var rows: [
                { t: root.currentReal(), kind: "you", ok: true },
                { t: root.currentSession(), kind: "session", ok: true },
                { t: config.suspendText, kind: "suspend", ok: sddm.canSuspend },
                { t: config.shutdownText, kind: "poweroff", ok: sddm.canPowerOff } ].filter(function (r) { return r.ok })
            function move(d) { cur = (cur + d + rows.length) % rows.length }
            function activate() {
                var r = rows[cur].kind
                if (r === "you") root.doLogin()
                else if (r === "session") root.nextSession(1)
                else if (r === "suspend") sddm.suspend()
                else if (r === "poweroff") sddm.powerOff()
            }
            // the stroke glides between rows
            Image {
                source: "select.png"; smooth: true
                width: 520 * root.k; height: 62 * root.k
                y: titleMenu.cur * 72 * root.k
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }
            Repeater {
                model: titleMenu.rows
                delegate: Item {
                    required property var modelData
                    required property int index
                    y: index * 72 * root.k; width: titleMenu.width; height: 62 * root.k
                    readonly property bool on: titleMenu.cur === index
                    Text {
                        id: lbl
                        x: 36 * root.k; anchors.verticalCenter: parent.verticalCenter
                        text: modelData.t
                        color: parent.on ? "#fff8ec" : "#948a7d"
                        font.family: config.displayFont; font.pixelSize: 34 * root.k
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    // row 0: the password, as diamonds on a hairline right after your name
                    Item {
                        visible: modelData.kind === "you"
                        x: lbl.x + lbl.implicitWidth + 30 * root.k; anchors.verticalCenter: parent.verticalCenter
                        width: 230 * root.k; height: 30 * root.k
                        Row {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 9 * root.k
                            Repeater { model: Math.min(pw.text.length, 16)
                                Rectangle { width: 8 * root.k; height: width; radius: root.xia ? width / 2 : 1; rotation: root.xia ? 0 : 45
                                            color: config.gold; anchors.verticalCenter: parent.verticalCenter } }
                        }
                        Rectangle {   // the cursor: a thin gold stroke that breathes while it waits
                            visible: pw.text.length === 0 && parent.parent.on
                            width: 2; height: 28 * root.k; anchors.verticalCenter: parent.verticalCenter; color: config.gold
                            SequentialAnimation on opacity { loops: Animation.Infinite; running: true
                                NumberAnimation { to: 0.15; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
                        }
                    }
                    // row 1: the session cycles with ← →
                    Text {
                        visible: modelData.kind === "session"
                        x: lbl.x + lbl.implicitWidth + 24 * root.k; anchors.verticalCenter: parent.verticalCenter
                        text: "‹  SESSION  ›"; color: root.al(config.text, parent.on ? 0.75 : 0.32)
                        font.family: config.displayFont; font.pixelSize: 14 * root.k; font.letterSpacing: 3 * root.k
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: titleMenu.cur = index
                        onClicked: { titleMenu.cur = index; titleMenu.activate(); pw.forceActiveFocus() } }
                }
            }
        }
        // under the menu: what the selected row does / the gate's answer
        Text {
            x: root.ix + 152 * root.k; y: root.iy + (540 + titleMenu.rows.length * 72 + 14) * root.k
            opacity: root.intro
            text: root.failed ? config.failText
                : titleMenu.cur === 0 ? (pw.text.length ? "ENTER  " + config.enterText.toLowerCase() : "type your password")
                : titleMenu.rows[titleMenu.cur].kind === "session" ? "←  →  choose the session" : "ENTER  to confirm"
            color: root.failed ? config.accent : root.al(config.text, 0.55)
            font.family: config.displayFont; font.pixelSize: 15 * root.k; font.letterSpacing: 3 * root.k
        }
        // the boot menu's key line, same place, same voice
        Text {
            x: root.ix + 116 * root.k; y: root.iy + 1012 * root.k - height
            opacity: root.intro * 0.9
            text: "ENTER  to begin      ↑ ↓  to choose      ← →  session"
            color: root.al(config.text, 0.47)
            font.family: config.displayFont; font.pixelSize: 15 * root.k; font.letterSpacing: 2.7 * root.k
        }
    }

    // ======================================================================= "brush"
    Item {
        id: brushFace
        visible: root.face === "brush"
        anchors.fill: parent
        Image { anchors.fill: parent; source: config.background; fillMode: Image.PreserveAspectCrop; smooth: true }
        Rectangle { anchors.fill: parent; color: root.al(config.base, 0.45) }
        Text {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -70 * root.s
            text: Qt.formatDate(root.now, "dddd").toUpperCase()
            color: "transparent"; style: Text.Outline; styleColor: root.al(config.gold, 0.35)
            font.family: config.brandFont; font.pixelSize: 300 * root.s; font.letterSpacing: 10 * root.s
            scale: Math.min(1, (parent.width * 0.96) / Math.max(1, implicitWidth))
            opacity: root.intro
        }
        Rectangle { anchors.centerIn: parent; anchors.verticalCenterOffset: 60 * root.s
                    width: 520 * root.s * root.intro; height: 3 * root.s; radius: height / 2; color: config.accent; opacity: 0.85 }
        Text {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -50 * root.s
            text: root.hm(); color: config.text
            font.family: config.displayFont; font.pixelSize: 190 * root.s
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 1.0; shadowOpacity: 0.5 }
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: root.shakeX * root.s
            y: parent.height * 0.5 + 100 * root.s; spacing: 16 * root.s
            opacity: root.intro
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 14 * root.s
                Image { source: config.crest; width: 34 * root.s; height: width; smooth: true; anchors.verticalCenter: parent.verticalCenter }
                Text { text: root.currentReal(); color: config.text; font.family: config.displayFont; font.pixelSize: 28 * root.s; font.letterSpacing: 2
                       anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 360 * root.s; height: 50 * root.s; radius: height / 2
                color: root.al(config.base, 0.5); border.width: 1
                border.color: root.failed ? config.accent : root.al(config.gold, 0.55)
                Row { anchors.centerIn: parent; spacing: 9 * root.s; visible: pw.text.length > 0
                      Repeater { model: Math.min(pw.text.length, 18)
                          Rectangle { width: 8 * root.s; height: width; radius: root.xia ? width / 2 : 1.5; rotation: root.xia ? 0 : 45; color: config.gold } } }
                Text { anchors.centerIn: parent; visible: pw.text.length === 0
                       text: root.failed ? config.failText : config.greet
                       color: root.failed ? config.accent : root.al(config.text, 0.5)
                       font.family: config.displayFont; font.pixelSize: 16 * root.s; font.letterSpacing: 3 }
            }
        }
        Text {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.leftMargin: 64 * root.s; anchors.bottomMargin: 48 * root.s
            text: root.currentSession().toUpperCase() + "   ‹ ›"; color: root.al(config.text, 0.6)
            font.family: config.displayFont; font.pixelSize: 15 * root.s; font.letterSpacing: 4 * root.s
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.nextSession(1) }
        }
        Row {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: 64 * root.s; anchors.bottomMargin: 48 * root.s
            spacing: 40 * root.s
            Repeater {
                model: [ { t: config.suspendText, a: 0, ok: sddm.canSuspend }, { t: config.rebootText, a: 1, ok: sddm.canReboot }, { t: config.shutdownText, a: 2, ok: sddm.canPowerOff } ]
                delegate: Text {
                    visible: modelData.ok; text: modelData.t.toUpperCase()
                    color: bpa.containsMouse ? config.gold : root.al(config.text, 0.6)
                    font.family: config.displayFont; font.pixelSize: 15 * root.s; font.letterSpacing: 4 * root.s
                    MouseArea { id: bpa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.a === 0 ? sddm.suspend() : (modelData.a === 1 ? sddm.reboot() : sddm.powerOff()) }
                }
            }
        }
    }
    // ======================================================================= "card"
    Item {
        id: cardFace
        visible: root.face === "card"
        anchors.fill: parent
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
            anchors.horizontalCenterOffset: root.shakeX * root.s
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
                Item {   // the password, drawn from the shared field
                    width: parent.width; height: 52 * root.s
                    Rectangle { anchors.fill: parent; radius: 12 * root.s; color: root.al(config.base, 0.45) }
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                        height: 2; width: parent.width - 24 * root.s; color: config.accent; radius: 1
                    }
                    Text { anchors.centerIn: parent; text: pw.text.length ? "•".repeat(Math.min(pw.text.length, 20)) : config.passwordHint
                           color: pw.text.length ? config.text : root.al(config.subtext, 0.85)
                           font.family: config.displayFont; font.pixelSize: 19 * root.s; font.letterSpacing: 1 }
                }
                Item {
                    id: go
                    width: parent.width; height: 52 * root.s
                    Image { anchors.fill: parent; source: config.button; smooth: true; opacity: goArea.containsMouse ? 1 : 0.9 }
                    Text { anchors.centerIn: parent; text: config.enterText; color: config.onAccent
                           font.family: config.displayFont; font.pixelSize: 21 * root.s; font.letterSpacing: 5 * root.s }
                    MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                }
                Text { id: errorText; text: config.failText; color: config.accent; opacity: root.failed ? 1 : 0; height: 0
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
}
