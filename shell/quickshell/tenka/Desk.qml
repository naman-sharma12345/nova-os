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
    mask: Region { item: clockHit }
    readonly property real s: Math.min(width / 1920, height / 1080)

    Image { anchors.fill: parent; source: "assets/vignette.png"; smooth: true; opacity: 0.85 }
    Rectangle {   // a breath of ink behind the time
        anchors.fill: parent
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
    ParticleSystem { id: ps; running: true }
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
    }

    Item {
        id: title
        x: 136 * desk.s; y: 150 * desk.s
        opacity: Theme.hush ? 0 : 1
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
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowColor: Theme.xia ? Theme.t.accent : "#000000"
                    shadowBlur: 1.0; shadowOpacity: Theme.xia ? 0.35 : 0.40; shadowVerticalOffset: Theme.xia ? 0 : 6
                }
            }
            // the one accent: a hand-stamped seal with the weekday and the day
            Item {
                anchors.top: clockText.top; anchors.topMargin: 74 * desk.s
                width: 84 * desk.s; height: 170 * desk.s
                Text { id: ampm; text: Theme.ap(Theme.now); color: Theme.alpha(Theme.t.text, 0.75); anchors.horizontalCenter: parent.horizontalCenter
                       font.family: Theme.display; font.pixelSize: 22 * desk.s; font.letterSpacing: 5 * desk.s }
                Image {
                    id: seal
                    anchors.top: ampm.bottom; anchors.topMargin: 12 * desk.s; anchors.horizontalCenter: parent.horizontalCenter
                    width: 84 * desk.s; height: 104 * desk.s; source: Theme.asset("seal.png"); fillMode: Image.Stretch; smooth: true
                    rotation: -2
                    Column {
                        anchors.centerIn: parent; spacing: 0
                        Text { text: Qt.formatDate(Theme.now, "ddd").toUpperCase(); color: Theme.t.ink; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 17 * desk.s; font.letterSpacing: 3 * desk.s }
                        Text { text: Theme.now.getDate(); color: Theme.t.ink; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 40 * desk.s }
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
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.6; shadowOpacity: 0.6; shadowVerticalOffset: 2 }
        }
        MouseArea { id: clockHit; x: 0; y: 0; width: clockRow.width; height: clockRow.height; cursorShape: Qt.PointingHandCursor
                    onClicked: { Theme.deskOpen = !Theme.deskOpen; Theme.pinOpen = Theme.deskOpen } }
    }
}
