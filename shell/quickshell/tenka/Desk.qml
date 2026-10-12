// The desktop, minimal: the art, the time, one seal, the date and the day's proverb. Nothing else.
// Click the clock (or Super+D, or the bottom edge) and the cards and the dock slide in.
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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
    ParticleSystem { id: ps; running: !Theme.perf; paused: Theme.working || Theme.hush || Theme.focus }
    // what falls follows the season (Theme.season): plum petals in spring, Tianxia's rising motes or Tenka's
    // petals in summer, maple leaves in autumn (in the season's own ink), snow in winter. Flat sprites, no glow.
    // ...unless the sky outside says otherwise (Theme.sky, tenka-sky): rain or a storm brings fine rain, snow brings snow
    readonly property string fall: Theme.sky.kind === "rain" || Theme.sky.kind === "storm" ? "rain" : Theme.sky.kind === "snow" ? "flake"
                                 : Theme.season === "maple" ? "leaf" : Theme.season === "snow" ? "flake"
                                 : (Theme.xia && Theme.season === "lotus") ? "mote" : "petal"
    component Fall: Emitter {
        required property string kind
        system: ps; group: kind; enabled: desk.fall === kind
        lifeSpan: 18000; lifeSpanVariation: 3000
        // the first handful once the season and the sky are known (a burst at creation scattered whatever the
        // defaults named for the first instant: petals and snow in autumn)
        Timer { interval: 1500; running: true; onTriggered: if (parent.enabled) parent.burst(parent.kind === "mote" ? 18 : parent.kind === "flake" ? 24 : parent.kind === "rain" ? 60 : 6) }
        onEnabledChanged: if (enabled && kind === "rain") burst(60)
    }
    Fall { kind: "petal"; x: desk.width * 0.3; y: -40; width: desk.width * 0.8; height: 1
           emitRate: 0.9; size: 15; sizeVariation: 6
           velocity: AngleDirection { angle: 112; angleVariation: 15; magnitude: 58; magnitudeVariation: 15 } }
    Fall { kind: "mote"; x: 0; y: desk.height; width: desk.width; height: 1
           emitRate: 2.5; size: 14; sizeVariation: 6
           velocity: AngleDirection { angle: 270; angleVariation: 15; magnitude: 45; magnitudeVariation: 15 } }
    Fall { kind: "leaf"; x: desk.width * 0.15; y: -40; width: desk.width * 0.9; height: 1
           emitRate: 0.8; size: 30; sizeVariation: 8
           velocity: AngleDirection { angle: 104; angleVariation: 18; magnitude: 52; magnitudeVariation: 14 } }
    Fall { kind: "flake"; x: 0; y: -20; width: desk.width; height: 1
           emitRate: 3.0; size: 13; sizeVariation: 5
           velocity: AngleDirection { angle: 96; angleVariation: 10; magnitude: 38; magnitudeVariation: 12 } }
    // rain: thin slanted strokes, quick and many, a heavier fall in a storm; drawn in the art's own pale ink
    Fall { kind: "rain"; x: -desk.width * 0.1; y: -60; width: desk.width * 1.15; height: 1
           lifeSpan: 2200; lifeSpanVariation: 300
           emitRate: Theme.sky.kind === "storm" ? 70 : (Theme.sky.code >= 51 && Theme.sky.code <= 57) ? 22 : 42; size: 34; sizeVariation: 12
           velocity: AngleDirection { angle: 102; angleVariation: 2; magnitude: 760; magnitudeVariation: 120 } }
    Wander { system: ps; groups: ["petal", "mote", "leaf", "flake"]; xVariance: 60; pace: 40; affectedParameter: Wander.Velocity }
    component Sprite: ImageParticle {
        system: ps
        entryEffect: ImageParticle.Fade
        opacity: Theme.working || Theme.hush || Theme.focus ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
    }
    Sprite { groups: ["petal"]; source: "assets/petal.png"; alpha: Theme.xia ? 0.6 : 0.75; alphaVariation: 0.3
             rotationVariation: 180; rotationVelocityVariation: 60 }
    Sprite { groups: ["mote"]; source: "assets/mote.png"; alpha: 0.5; alphaVariation: 0.3 }
    Sprite { groups: ["leaf"]; source: "assets/leaf.png"; color: Theme.seasonInk; colorVariation: 0.08
             alpha: 0.92; alphaVariation: 0.1; rotationVariation: 180; rotationVelocityVariation: 40 }   // the leaf carries a flat ink edge
    Sprite { groups: ["rain"]; source: "assets/rain.png"; color: desk.lightArt ? Theme.t.base : Theme.t.text; alpha: 0.34; alphaVariation: 0.14
             autoRotation: true; entryEffect: ImageParticle.None }
    Sprite { groups: ["flake"]; source: "assets/flake.png"; alpha: 0.85; alphaVariation: 0.2   // white with a thin ink rim: reads on pale art too
             rotationVariation: 30; rotationVelocityVariation: 20 }


    // mist: a pale haze rising from the foot of the art, no blur and no glow; it breathes very slowly
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: parent.height * 0.62
        opacity: Theme.sky.kind === "mist" && !Theme.hush && !Theme.focus ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 2400 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.alpha(Theme.t.text, 0.14) }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.t.text, 0.30) }
        }
        SequentialAnimation on anchors.bottomMargin { running: Theme.sky.kind === "mist" && !Theme.perf; loops: Animation.Infinite
            NumberAnimation { from: 0; to: -40; duration: 14000; easing.type: Easing.InOutSine }
            NumberAnimation { from: -40; to: 0; duration: 14000; easing.type: Easing.InOutSine } }
    }

    // ---- the real moon, on a clear night. tenka-moon says where it stands in this sky (altitude, azimuth and the
    // tilt of its lit limb, worked out on the machine, nothing asked online); the desk sets it in the picture's
    // open sky: rising at the left of that space, setting at the right (turned over in the southern half of
    // the world), higher as it climbs. The phase and the tilt are tonight's own: the low boat moon of the tropics,
    // the upright quarter of the north, its seas turned as they stand. Flat: paper and a breath of ink, a hairline rim, no glow. It shows only
    // at night when the sky is clear or barely clouded (paler then), and when the sky is unknown (tenka-sky off or
    // offline) it trusts the heavens; cloud, rain, snow, mist or a storm hide it. It rests with the petals.
    property var moon: ({})
    Process {
        id: moonP
        command: ["tenka-moon", "state"]
        stdout: StdioCollector { onStreamFinished: { try { const m = JSON.parse(text); if (m && m.phase) desk.moon = m } catch (e) {} } }
    }
    Timer { interval: 600000; repeat: true; running: true; triggeredOnStart: true; onTriggered: moonP.running = true }
    // pictures of the packs with an open sky for it, and where that sky is (fractions of the screen). Pictures that
    // paint their own moon or sun (Moon and Seigaiha, Bamboo Moon, Red Sun, the Frost Sect's moon...) or have no sky
    // are left alone: one moon to a sky.
    readonly property var moonSkies: ({
        "samurai/00-desktop": [0.76, 0.07, 0.95, 0.22], "samurai/02-torii-night": [0.56, 0.08, 0.95, 0.40],
        "samurai/07-pagoda-snow": [0.68, 0.08, 0.92, 0.34], "xianxia/01-floating-peaks": [0.62, 0.06, 0.92, 0.28],
        "xianxia/05-cloud-sea-seclusion": [0.64, 0.05, 0.94, 0.22], "xianxia/09-celestial-palace": [0.58, 0.04, 0.95, 0.18],
        "xianxia/11-imperial-city": [0.62, 0.05, 0.95, 0.20] })
    readonly property bool moonNight: Theme.phase === "night" || (Theme.phase === "dusk" && Theme.sky.day === false)
    readonly property real moonVeil: Theme.sky.kind === "clear" || Theme.sky.kind === "" || Theme.sky.kind === undefined ? 1
                                   : Theme.sky.code === 2 ? 0.5 : 0
    Canvas {
        id: deskMoon
        readonly property real d: Math.round(66 * desk.s)
        readonly property real alt: desk.moon.alt === undefined ? -90 : desk.moon.alt
        readonly property real az: desk.moon.az || 180
        // 0 where it rises, 1 where it sets, facing the equator (the moon's own half of the sky)
        readonly property real u: {
            let v = ((desk.moon.south ? az - 270 : az - 90) + 360) % 360 / 180
            return v <= 1 ? v : (v > 1.5 ? 0 : 1)
        }
        // the open sky of the picture, where a moon can hang without crossing the art: [left, top, right, bottom]
        readonly property var box: {
            const w = Theme.t.wallpaper || "", m = w.match(/themes\/([^\/]+)\/wallpapers\/([^\/.]+)\./)
            if (m) return desk.moonSkies[m[1] + "/" + m[2]] || null       // a pack picture: only where it has an open sky
            return /moon|sun|luna|lune|soleil/i.test(w.split("/").pop()) ? null : [0.56, 0.08, 0.92, 0.40]   // your own picture
        }
        width: d + 8; height: d + 8
        x: box ? desk.width * (box[0] + (box[2] - box[0]) * u) - width / 2 : -width
        y: box ? desk.height * (box[3] - (box[3] - box[1]) * Math.min(Math.max(alt, 0), 75) / 75) - height / 2 : 0
        Behavior on x { NumberAnimation { duration: 4000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 4000; easing.type: Easing.InOutSine } }
        readonly property bool shown: box !== null && desk.moonNight && alt > 2 && (desk.moon.illumination || 0) >= 0.02 && desk.moonVeil > 0
        opacity: shown && !Theme.working && !Theme.hush && !Theme.focus ? 0.92 * desk.moonVeil : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 2400 } }
        antialiasing: true
        renderTarget: Canvas.Image
        readonly property url maria: Qt.resolvedUrl("assets/maria.png")
        Component.onCompleted: loadImage(maria)
        onImageLoaded: requestPaint()
        readonly property string key: [desk.moon.fraction, desk.moon.tilt, desk.moon.turn, desk.type, desk.lightArt, d].join("|")
        onKeyChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            const cx = width / 2, cy = height / 2, R = d / 2
            const T = desk.type, c = Math.cos(2 * Math.PI * (desk.moon.fraction || 0))
            // the lit limb's middle points at the sun: tilt is measured from straight up toward the left
            const z = (desk.moon.tilt === undefined ? (desk.moon.waxing !== false) !== (desk.moon.south === true) ? 270 : 90
                                                    : desk.moon.tilt) * Math.PI / 180
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI)
            ctx.fillStyle = Qt.rgba(T.r, T.g, T.b, 0.07); ctx.fill()               // the dark of the moon, earthshine
            ctx.save()
            ctx.translate(cx, cy); ctx.rotate(Math.atan2(-Math.cos(z), -Math.sin(z)))
            ctx.beginPath()
            const N = 48
            for (let i = 0; i <= N; i++) { const t = -Math.PI / 2 + Math.PI * i / N; const px = R * Math.cos(t), py = R * Math.sin(t)
                                           i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py) }
            for (let i = 0; i <= N; i++) { const t = Math.PI / 2 - Math.PI * i / N; ctx.lineTo(R * c * Math.cos(t), R * Math.sin(t)) }
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(T.r, T.g, T.b, 0.94); ctx.fill()
            // the seas where they really lie (assets/maria.png, from NASA's public-domain LRO map), on the lit part only,
            // the face turned as it stands in this sky (turn: the parallactic angle); on pale art the ink moon goes without
            if (!desk.lightArt && isImageLoaded(deskMoon.maria)) {
                ctx.clip(); ctx.rotate(-Math.atan2(-Math.cos(z), -Math.sin(z)) + (desk.moon.turn || 0) * Math.PI / 180)
                ctx.globalAlpha = 0.17; ctx.drawImage(deskMoon.maria, -R, -R, 2 * R, 2 * R); ctx.globalAlpha = 1
            }
            ctx.restore()
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI)
            ctx.lineWidth = 1; ctx.strokeStyle = Qt.rgba(T.r, T.g, T.b, 0.24); ctx.stroke()
        }
    }

    // ---- the art's tone behind the type. A tiny canvas reads the wallpaper (48x27) and averages the
    // luminance under the title block; on a pale picture (snow, mist) the desk's type turns to the
    // pack's own ink, like brush on paper, and drops its shadow. Flat: a colour change, no plate, no glow.
    property real tone: 0
    readonly property bool lightArt: tone > 0.6
    readonly property color type: lightArt ? Theme.t.base : Theme.t.text
    Canvas {
        id: toneProbe
        x: -200; width: 48; height: 27        // off-screen, still painted
        readonly property string src: Theme.t.wallpaper ? "file://" + Theme.t.wallpaper : ""
        onSrcChanged: if (src) loadImage(src)
        Component.onCompleted: if (src) loadImage(src)
        onImageLoaded: requestPaint()
        onPaint: {
            if (!src || !isImageLoaded(src)) return
            const ctx = getContext("2d")
            ctx.drawImage(src, 0, 0, width, height)
            const d = ctx.getImageData(0, 0, width, height).data
            let sum = 0, n = 0
            for (let y = 4; y <= 16; y++) for (let x = 3; x <= 26; x++) {   // the blade title block on the 1920 grid
                const i = (y * width + x) * 4
                sum += (0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2]) / 255; n++
            }
            desk.tone = n ? sum / n : 0
        }
    }
    Item {
        id: title
        visible: Theme.deskStyle === "blade"
        x: 136 * desk.s; y: 150 * desk.s
        opacity: Theme.hush || Theme.working ? 0 : Theme.focus ? 0.38 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
        width: 900 * desk.s; height: 600 * desk.s

        Row {
            id: clockRow
            spacing: 30 * desk.s
            Text {
                id: clockText
                text: Theme.hm(Theme.now)
                color: desk.type
                font.family: Theme.display; font.pixelSize: 268 * desk.s; font.letterSpacing: -2 * desk.s
                layer.enabled: !Theme.perf && !desk.lightArt
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowColor: "#000000"   // a plain drop shadow for legibility, never a coloured glow
                    shadowBlur: 0.3; shadowOpacity: 0.35; shadowVerticalOffset: 3
                }
            }
            // the one accent: a hand-stamped seal with the weekday and the day
            Item {
                anchors.top: clockText.top; anchors.topMargin: 74 * desk.s
                width: 84 * desk.s; height: 170 * desk.s
                Text { id: ampm; text: Theme.ap(Theme.now); color: Theme.alpha(desk.type, 0.75); anchors.horizontalCenter: parent.horizontalCenter
                       font.family: Theme.display; font.pixelSize: 22 * desk.s; font.letterSpacing: 5 * desk.s }
                Item {   // the day: a thin vermilion ruled tag (was a filled stamp; quieter, no fill)
                    id: seal
                    anchors.top: ampm.bottom; anchors.topMargin: 12 * desk.s; anchors.horizontalCenter: parent.horizontalCenter
                    width: 72 * desk.s; height: 92 * desk.s
                    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, 0.18); radius: Theme.xia ? 8 * desk.s : 2 * desk.s
                                border.width: Math.max(1, Math.round(desk.s)); border.color: Theme.alpha(Theme.accent, 0.85) }
                    Column {
                        anchors.centerIn: parent; spacing: 2 * desk.s
                        Text { text: Qt.formatDate(Theme.now, "ddd").toUpperCase(); color: Theme.accent; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 14 * desk.s; font.letterSpacing: 4 * desk.s }
                        Text { text: Theme.now.getDate(); color: desk.type; anchors.horizontalCenter: parent.horizontalCenter
                               font.family: Theme.display; font.pixelSize: 38 * desk.s }
                    }
                }
            }
        }
        Text {
            id: dateText
            anchors.top: clockRow.bottom; anchors.topMargin: -20 * desk.s; x: 8 * desk.s
            text: Qt.formatDate(Theme.now, "MMMM yyyy").toUpperCase()   // the hour's old name moved to the line below
            color: Theme.alpha(desk.type, desk.lightArt ? 0.9 : 0.82)
            font.family: Theme.display; font.pixelSize: 19 * desk.s; font.letterSpacing: 9 * desk.s
        }
        Text {   // the hour and the season on a short second line, so neither runs into the art at the line's end
            id: seasonText
            anchors.top: dateText.bottom; anchors.topMargin: 12 * desk.s; x: 8 * desk.s
            textFormat: Text.StyledText
            text: Theme.hourName(Theme.now).toUpperCase() + (Theme.seasonWord ? "   ·   <font color=\"" + (desk.lightArt ? Theme.accent : Theme.seasonInk)
                  + "\">" + Theme.seasonWord.toUpperCase() + " SEASON</font>" : "")
            color: Theme.alpha(desk.type, desk.lightArt ? 0.85 : 0.72)
            font.family: Theme.display; font.pixelSize: 14 * desk.s; font.letterSpacing: 8 * desk.s
        }
        ProverbPlate {
            id: prov
            anchors.top: seasonText.bottom; anchors.topMargin: 26 * desk.s; x: 8 * desk.s
            s: desk.s; maxWidth: 560; size: 22; textOpacity: desk.lightArt ? 0.9 : 0.78; shadow: !desk.lightArt
            ink: desk.type; onLight: desk.lightArt
        }
        MouseArea { id: clockHit; x: 0; y: 0; width: clockRow.width; height: clockRow.height; cursorShape: Qt.PointingHandCursor
                    onClicked: { Theme.deskOpen = !Theme.deskOpen; Theme.pinOpen = Theme.deskOpen } }
    }

    // ---- direction "film": the art is the frame; the time lives in a cinematic lower band
    Item {
        id: film
        visible: Theme.deskStyle === "film"
        anchors.fill: parent
        opacity: Theme.hush || Theme.working ? 0 : Theme.focus ? 0.38 : 1
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
                color: Theme.alpha(Theme.gold, 0.5) }
            Image { width: 34 * desk.s; height: 42 * desk.s; source: Theme.asset("seal.png"); smooth: true; rotation: -3
                Text { anchors.centerIn: parent; text: Theme.now.getDate(); color: Theme.t.ink; font.family: Theme.display; font.pixelSize: 17 * desk.s } }
            Rectangle { width: 260 * desk.s; height: 1; anchors.verticalCenter: parent.verticalCenter
                color: Theme.alpha(Theme.gold, 0.5) }
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
            text: "“" + Theme.proverb + "”"
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
        opacity: Theme.hush || Theme.working ? 0 : Theme.focus ? 0.38 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Rectangle {   // the cord
            anchors.horizontalCenter: parent.horizontalCenter; y: 0; width: 1; height: 64 * desk.s
            color: Theme.alpha(Theme.gold, 0.7)
        }
        Rectangle {   // the scroll: frosted silk with a gold rod top and bottom
            id: silk
            y: 64 * desk.s; width: parent.width; height: parent.height - 64 * desk.s
            radius: 4 * desk.s
            color: Theme.alpha(Theme.t.base, 0.52)
            border.width: 1; border.color: Theme.alpha(Theme.gold, 0.28)
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: -5 * desk.s; width: parent.width + 24 * desk.s; height: 8 * desk.s; radius: 4 * desk.s; color: Theme.gold; opacity: 0.85 }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 3 * desk.s; width: parent.width + 24 * desk.s; height: 8 * desk.s; radius: 4 * desk.s; color: Theme.gold; opacity: 0.85 }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 46 * desk.s; spacing: 0
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: (Theme.now.getHours() % 12 || 12)
                       color: Theme.t.text; font.family: Theme.display; font.pixelSize: 110 * desk.s; lineHeight: 0.9 }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 46 * desk.s; height: 2; color: Theme.accent }
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
                    text: Theme.proverb
                    color: Theme.alpha(Theme.t.text, 0.72)
                    font.family: Theme.display; font.pixelSize: 15 * desk.s; font.letterSpacing: 2 * desk.s
                }
            }
        }
        MouseArea { id: scrollHit; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: scroll.visible
                    onClicked: { Theme.deskOpen = !Theme.deskOpen; Theme.pinOpen = Theme.deskOpen } }
    }
}
