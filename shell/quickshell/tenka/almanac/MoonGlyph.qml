// The moon as it stands tonight, drawn flat: an unlit disc in faint ink with a hairline rim, and the lit
// part in paper. e = the moon's elongation from the sun in degrees (0 new, 90 first quarter, 180 full),
// from tenka-almanac. Theme-free, so Tenka Lite can use it too (almanac/AlmanacCard.qml, DeskLedger.qml). Lit side on the right while waxing, as seen from the northern half of the world.
import QtQuick

Canvas {
    id: m
    property real e: 0
    property color lit: Qt.rgba(0.94, 0.90, 0.84, 0.86)    // the owner sets these from the theme
    property color dark: Qt.rgba(0.94, 0.90, 0.84, 0.10)
    property color rim: Qt.rgba(0.79, 0.64, 0.35, 0.45)
    width: 22; height: 22
    antialiasing: true
    onEChanged: requestPaint()
    onLitChanged: requestPaint()
    onDarkChanged: requestPaint()
    onRimChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - 1, cx = width / 2, cy = height / 2;
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.fillStyle = dark; ctx.fill();
        const er = e * Math.PI / 180, wax = e < 180, side = wax ? 1 : -1, c = Math.cos(er) * side, N = 40;
        ctx.beginPath();
        for (let i = 0; i <= N; i++) {            // the lit limb, top to bottom
            const f = -Math.PI / 2 + Math.PI * i / N;
            const x = cx + side * r * Math.cos(f), y = cy + r * Math.sin(f);
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        for (let i = N; i >= 0; i--) {            // the terminator, bottom to top
            const f = -Math.PI / 2 + Math.PI * i / N;
            ctx.lineTo(cx + c * r * Math.cos(f), cy + r * Math.sin(f));
        }
        ctx.closePath(); ctx.fillStyle = lit; ctx.fill();
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.lineWidth = 1; ctx.strokeStyle = rim; ctx.stroke();
    }
}
