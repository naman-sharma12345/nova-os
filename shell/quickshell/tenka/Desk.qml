// The desktop, minimal: the art, the time, one seal, the date and the hour's proverb. Nothing else.
// Click the clock (or Super+D, or the bottom edge) and the cards and the dock slide in.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Particles

PanelWindow {
    id: desk
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "tenka-desk"
    mask: Region { item: Theme.deskStyle === "film" ? filmHit : Theme.deskStyle === "scroll" ? scrollHit : clockHit }
    readonly property real s: Math.min(width / 1920, height / 1080)

    Image { anchors.fill: parent; source: "assets/vignette.png"; smooth: true; opacity: 0.85 }
    Rectangle {   // a breath of ink behind the time
        anchors.fill: parent
        visible: Theme.deskStyle !== "film"
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: Theme.alpha(Theme.t.base, 0.42) }
            GradientStop { position: 0.26; color: Theme.alpha(Theme.t.base, 0.18) }
            GradientStop { position: 0.46; color: Theme.alpha(Theme.t.base, 0.0) } }
    }
    Rectangle {   // and under the bar
        anchors.left: parent.left; anchors.right: parent.right; height: 80 * desk.s
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.t.base, 0.40) }
            GradientStop { position: 1; color: Theme.alpha(Theme.t.base, 0.0) } }
    }

    // ---- life: a few petals (Tenka) or rising qi motes (Tianxia)
    // they rest in Performance mode, and pause (faded out) while windows cover the desk or an overlay is up
    ParticleSystem { id: ps; running: !Theme.perf; paused: Theme.working || Theme.hush }
    Emitter {
        system: ps
        x: Theme.xia ? 0 : desk.width * 0.3; y: Theme.xia ? desk.height : -40
        width: Theme.xia ? desk.width : desk.width * 0.8; height: 1
        emitRate: Theme.xia ? 2.5 : 0.9; lifeSpan: 18000; lifeSpanVariation: 3000
        size: Theme.xia ? 14 : 15; sizeVariation: 6
        velocity: AngleDirection { angle: Theme.xia ? 270 : 112; angleVariation: 15; magnitude: Theme.xia ? 45 : 58; magnitudeVariation: 15 }
        Component.onCompleted: burst(Theme.xia ? 18 : 6)
    }
    Wander { system: ps; xVariance: 60; pace: 40; affectedParameter: Wander.Velocity }
    ImageParticle {
        system: ps; source: Theme.xia ? "assets/mote.png" : "assets/petal.png"
        alpha: Theme.xia ? 0.5 : 0.75; alphaVariation: 0.3
        rotationVariation: Theme.xia ? 0 : 180; rotationVelocityVariation: Theme.xia ? 0 : 60
        entryEffect: ImageParticle.Fade
        opacity: Theme.working || Theme.hush ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
    }

    Item {
        id: title
        visible: Theme.deskStyle === "blade"
        x: 136 * desk.s; y: 150 * desk.s
        opacity: Theme.hush || Theme.working ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
        width: 900 * desk.s; height: 600 * desk.s

        Row {
            id: clockRow
            spacing: 30 * desk.s
            Text {
                id: clockText
                text: Theme.hm(Theme.now)
                color: Theme.t.text
                font.family: Theme.display; font.pixelSize: 268 * desk.s; font.letterSpacing: -2 * desk.s
                layer.enabled: !Theme.perf
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowColor: "#000000"   // a plain drop shadow for legibility, never a coloured glow
                    shadowBlur: 0.3; shadowOpacity: 0.35; shadowVerticalOffset: 3
                }
            }
            // the one accent: a hand-stamped seal with the weekday and the day
            Item {
                anchors.top: clockText.top; anchors.topMargin: 74 * desk.s
                width: 84 * desk.s; height: 170 * desk.s
                Text { id: ampm; text: Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.75); anchors.horizontalCenter: parent.horizontalCenter
                       font.family: Theme.display; font.pixelSize: 22 * desk.s; font.letterSpacing: 5 * desk.s }
                Item {   // the day: a thin vermilion ruled tag (was a filled stamp; quieter, no fill)
                    id: seal
                    anchors.top: ampm.bottom; anchors.topMargin: 12 * desk.s; anchors.horizontalCenter: parent.horizontalCenter
                    width: 72 * desk.s; height: 92 * desk.s
                    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, 0.18); radius: Theme.xia ? 8 * desk.s : 2 * desk.s
                                border.width: Math.max(1, Math.round(desk.s)); border.color: Theme.alpha(Theme.t.accent, 0.85) }
                    Column {
                        anchors.centerIn: parent; spacing: 2 * desk.s
                        Text { text: Qt.formatDate(Theme.now, "ddd").toUpperCase(); color: Theme.t.accent; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 14 * desk.s; font.letterSpacing: 4 * desk.s }
                        Text { text: Theme.now.getDate(); color: Theme.t.text; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 38 * desk.s }
                    }
                }
            }
        }
        Text {
            id: dateText
            anchors.top: clockRow.bottom; anchors.topMargin: -20 * desk.s; x: 8 * desk.s
            text: Qt.formatDate(Theme.now, "MMMM yyyy").toUpperCase() + "   ·   " + Theme.hourName(Theme.now).toUpperCase()
            color: Theme.alpha(Theme.t.text, 0.82)
            font.family: Theme.display; font.pixelSize: 19 * desk.s; font.letterSpacing: 9 * desk.s
        }
        Text {
            id: prov
            anchors.top: dateText.bottom; anchors.topMargin: 34 * desk.s; x: 8 * desk.s
            width: 560 * desk.s; wrapMode: Text.WordWrap
            text: Theme.t.proverbs[Theme.now.getHours() % Math.max(1, Theme.t.proverbs.length)]
            color: Theme.alpha(Theme.t.text, 0.72)
            font.family: Theme.display; font.pixelSize: 22 * desk.s; lineHeight: 1.25
            layer.enabled: !Theme.perf
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.25; shadowOpacity: 0.5; shadowVerticalOffset: 1 }
        }
        MouseArea { id: clockHit; x: 0; y: 0; width: clockRow.width; height: clockRow.height; cursorShape: Qt.PointingHandCursor
                    onClicked: { Theme.deskOpen = !Theme.deskOpen; Theme.pinOpen = Theme.deskOpen } }
    }

    // ---- direction "film": the art is the frame; the time lives in a cinematic lower band
    Item {
        id: film
        visible: Theme.deskStyle === "film"
        anchors.fill: parent
        opacity: Theme.hush || Theme.working ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Rectangle {   // the lower letterbox: ink that fades up into the art
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 300 * desk.s
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(Theme.t.base, 0.0) }
                GradientStop { position: 0.55; color: Theme.alpha(Theme.t.base, 0.55) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.t.base, 0.86) } }
        }
        Text {   // the time, wide and quiet, like a title over the last shot
            id: filmClock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 178 * desk.s
            text: Theme.hm(Theme.now)
            color: Theme.t.text
            font.family: Theme.display; font.pixelSize: 132 * desk.s; font.letterSpacing: 26 * desk.s
            layer.enabled: !Theme.perf
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowBlur: 0.3; shadowOpacity: 0.35; shadowVerticalOffset: 2 }
        }
        Row {   // gold hairline · seal · gold hairline
            id: filmRule
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: filmClock.bottom; anchors.topMargin: 8 * desk.s
            spacing: 22 * desk.s
            Rectangle { width: 260 * desk.s; height: 1; anchors.verticalCenter: parent.verticalCenter
                color: Theme.alpha(Theme.t.gold, 0.5) }
            Image { width: 34 * desk.s; height: 42 * desk.s; source: Theme.asset("seal.png"); smooth: true; rotation: -3
                Text { anchors.centerIn: parent; text: Theme.now.getDate(); color: Theme.t.ink; font.family: Theme.display; font.pixelSize: 17 * desk.s } }
            Rectangle { width: 260 * desk.s; height: 1; anchors.verticalCenter: parent.verticalCenter
                color: Theme.alpha(Theme.t.gold, 0.5) }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: filmRule.bottom; anchors.topMargin: 16 * desk.s
            text: Theme.ap(Theme.now) + "   ·   " + Qt.formatDate(Theme.now, "dddd d MMMM").toUpperCase() + "   ·   " + Theme.hourName(Theme.now).toUpperCase()
            color: Theme.alpha(Theme.t.text, 0.78)
            font.family: Theme.display; font.pixelSize: 15 * desk.s; font.letterSpacing: 8 * desk.s
        }
        Text {   // the proverb, as a subtitle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 40 * desk.s
            text: "“" + Theme.t.proverbs[Theme.now.getHours() % Math.max(1, Theme.t.proverbs.length)] + "”"
            color: Theme.alpha(Theme.t.text, 0.55)
            font.family: Theme.display; font.italic: false; font.pixelSize: 16 * desk.s; font.letterSpacing: 1.5 * desk.s
        }
        MouseArea { id: filmHit; x: filmClock.x; y: filmClock.y; width: filmClock.width; height: filmClock.height
                    cursorShape: Qt.PointingHandCursor; enabled: film.visible
                    onClicked: { Theme.deskOpen = !Theme.deskOpen; Theme.pinOpen = Theme.deskOpen } }
    }

    // ---- direction "scroll": a narrow hanging scroll at the left edge, read top to bottom
    Item {
        id: scroll
        visible: Theme.deskStyle === "scroll"
        x: 120 * desk.s; y: 0
        width: 156 * desk.s; height: 900 * desk.s
        opacity: Theme.hush || Theme.working ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Rectangle {   // the cord
            anchors.horizontalCenter: parent.horizontalCenter; y: 0; width: 1; height: 64 * desk.s
            color: Theme.alpha(Theme.t.gold, 0.7)
        }
        Rectangle {   // the scroll: frosted silk with a gold rod top and bottom
            id: silk
            y: 64 * desk.s; width: parent.width; height: parent.height - 64 * desk.s
            radius: 4 * desk.s
            color: Theme.alpha(Theme.t.base, 0.52)
            border.width: 1; border.color: Theme.alpha(Theme.t.gold, 0.28)
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: -5 * desk.s; width: parent.width + 24 * desk.s; height: 8 * desk.s; radius: 4 * desk.s; color: Theme.t.gold; opacity: 0.85 }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 3 * desk.s; width: parent.width + 24 * desk.s; height: 8 * desk.s; radius: 4 * desk.s; color: Theme.t.gold; opacity: 0.85 }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 46 * desk.s; spacing: 0
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: (Theme.now.getHours() % 12 || 12)
                       color: Theme.t.text; font.family: Theme.display; font.pixelSize: 110 * desk.s; lineHeight: 0.9 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 46 * desk.s; height: 2; color: Theme.t.accent }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(Theme.now, "mm")
                       color: Theme.t.text; font.family: Theme.display; font.pixelSize: 110 * desk.s; lineHeight: 0.9 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.7)
                       font.family: Theme.display; font.pixelSize: 16 * desk.s; font.letterSpacing: 6 * desk.s; topPadding: 6 * desk.s }
                Item { width: 1; height: 26 * desk.s }
                Image { anchors.horizontalCenter: parent.horizontalCenter; width: 64 * desk.s; height: 80 * desk.s; source: Theme.asset("seal.png"); smooth: true; rotation: -2
                    Column { anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(Theme.now, "ddd").toUpperCase(); color: Theme.t.ink; font.family: Theme.display; font.pixelSize: 13 * desk.s; font.letterSpacing: 2 * desk.s }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.now.getDate(); color: Theme.t.ink; font.family: Theme.display; font.pixelSize: 30 * desk.s } } }
            }
            Item {   // the proverb, written down the scroll
                anchors.horizontalCenter: parent.horizontalCenter
                y: 455 * desk.s; width: 60 * desk.s; height: parent.height - 480 * desk.s
                Text {
                    anchors.centerIn: parent
                    rotation: 90
                    width: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; lineHeight: 1.2
                    text: Theme.t.proverbs[Theme.now.getHours() % Math.max(1, Theme.t.proverbs.length)]
                    color: Theme.alpha(Theme.t.text, 0.72)
                    font.family: Theme.display; font.pixelSize: 15 * desk.s; font.letterSpacing: 2 * desk.s
                }
            }
        }
        MouseArea { id: scrollHit; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: scroll.visible
                    onClicked: { Theme.deskOpen = !Theme.deskOpen; Theme.pinOpen = Theme.deskOpen } }
    }
}
