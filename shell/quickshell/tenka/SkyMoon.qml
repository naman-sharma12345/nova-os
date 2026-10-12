// The real moon, on a clear night, in the picture's open sky: shared by the desk (Desk.qml) and the lock (LockFace.qml),
// so the moon you saw on the desk is still there, in the same place, when the screen locks. The owner fills the screen
// with it and hands it the scale, the ink, whether the art is pale and whether to rest.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: sky
    property real s: 1
    property color ink: Theme.t.text
    property bool lightArt: false
    property bool resting: false
    property bool active: true
    // ---- the real moon, on a clear night. tenka-moon says where it stands in this sky (altitude, azimuth and the
    // tilt of its lit limb, worked out on the machine, nothing asked online); it is set in the picture's
    // open sky: rising at the left of that space, setting at the right (turned over in the southern half of
    // the world), higher as it climbs. The phase and the tilt are tonight's own: the low boat moon of the tropics,
    // the upright quarter of the north, its seas turned as they stand. Flat: paper and a breath of ink, a hairline rim, no glow. It shows only
    // at night when the sky is clear or barely clouded (paler then), and when the sky is unknown (tenka-sky off or
    // offline) it trusts the heavens; cloud, rain, snow, mist or a storm hide it. It rests with the petals.
    property var moon: ({})
    Process {
        id: moonP
        command: ["tenka-moon", "state"]
        stdout: StdioCollector { onStreamFinished: { try { const m = JSON.parse(text); if (m && m.phase) sky.moon = m } catch (e) {} } }
    }
    Timer { interval: 600000; repeat: true; running: sky.active; triggeredOnStart: true; onTriggered: moonP.running = true }
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
        id: orb
        readonly property real d: Math.round(66 * sky.s)
        readonly property real alt: sky.moon.alt === undefined ? -90 : sky.moon.alt
        readonly property real az: sky.moon.az || 180
        // 0 where it rises, 1 where it sets, facing the equator (the moon's own half of the sky)
        readonly property real u: {
            let v = ((sky.moon.south ? az - 270 : az - 90) + 360) % 360 / 180
            return v <= 1 ? v : (v > 1.5 ? 0 : 1)
        }
        // the open sky of the picture, where a moon can hang without crossing the art: [left, top, right, bottom]
        readonly property var box: {
            const w = Theme.t.wallpaper || "", m = w.match(/themes\/([^\/]+)\/wallpapers\/([^\/.]+)\./)
            if (m) return sky.moonSkies[m[1] + "/" + m[2]] || null       // a pack picture: only where it has an open sky
            return /moon|sun|luna|lune|soleil/i.test(w.split("/").pop()) ? null : [0.56, 0.08, 0.92, 0.40]   // your own picture
        }
        width: d + 8; height: d + 8
        x: box ? sky.width * (box[0] + (box[2] - box[0]) * u) - width / 2 : -width
        y: box ? sky.height * (box[3] - (box[3] - box[1]) * Math.min(Math.max(alt, 0), 75) / 75) - height / 2 : 0
        Behavior on x { NumberAnimation { duration: 4000; easing.type: Easing.InOutSine } }
        Behavior on y { NumberAnimation { duration: 4000; easing.type: Easing.InOutSine } }
        readonly property bool shown: box !== null && sky.moonNight && alt > 2 && (sky.moon.illumination || 0) >= 0.02 && sky.moonVeil > 0
        opacity: shown && !sky.resting ? 0.92 * sky.moonVeil : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 2400 } }
        antialiasing: true
        renderTarget: Canvas.Image
        readonly property url maria: Qt.resolvedUrl("assets/maria.png")
        Component.onCompleted: loadImage(maria)
        onImageLoaded: requestPaint()
        readonly property string key: [sky.moon.fraction, sky.moon.tilt, sky.moon.turn, sky.ink, sky.lightArt, d].join("|")
        onKeyChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            const cx = width / 2, cy = height / 2, R = d / 2
            const T = sky.ink, c = Math.cos(2 * Math.PI * (sky.moon.fraction || 0))
            // the lit limb's middle points at the sun: tilt is measured from straight up toward the left
            const z = (sky.moon.tilt === undefined ? (sky.moon.waxing !== false) !== (sky.moon.south === true) ? 270 : 90
                                                    : sky.moon.tilt) * Math.PI / 180
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
            if (!sky.lightArt && isImageLoaded(orb.maria)) {
                ctx.clip(); ctx.rotate(-Math.atan2(-Math.cos(z), -Math.sin(z)) + (sky.moon.turn || 0) * Math.PI / 180)
                ctx.globalAlpha = 0.17; ctx.drawImage(orb.maria, -R, -R, 2 * R, 2 * R); ctx.globalAlpha = 1
            }
            ctx.restore()
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, 2 * Math.PI)
            ctx.lineWidth = 1; ctx.strokeStyle = Qt.rgba(T.r, T.g, T.b, 0.24); ctx.stroke()
        }
    }

}
