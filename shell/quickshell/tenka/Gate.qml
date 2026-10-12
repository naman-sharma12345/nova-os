// The gate: the login screen's last frame (its picture, the enso as a watermark and the seal),
// laid out on the very grid scripts/sddm/Main.qml and the Plymouth splash use. The arrival
// overlay (Threshold.qml) and the lock face (LockFace.qml) both open through it, so boot,
// login, lock and desk read as one continuous scene. Flat: opacity and scale only, no glow.
import QtQuick

Item {
    id: gate
    property real ensoOpacity: 0.14     // where the login screen leaves the enso
    property real sealOpacity: 0
    property real sealScale: 1
    readonly property string dir: "file:///usr/share/sddm/themes/tenka-" + Theme.t.name + "/"
    readonly property real s: Math.min(width / 1920, height / 1080)
    readonly property real colX: (width - 1920 * s) / 2 + 470 * s

    Rectangle { anchors.fill: parent; color: Theme.t.base }
    Image {
        anchors.fill: parent; source: gate.dir + "background.png"
        fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: false
        sourceSize.width: 1920
    }
    Image {
        source: gate.dir + "enso.png"
        width: 520 * gate.s; height: width; smooth: true
        x: gate.colX - width / 2; y: 420 * gate.s - height / 2
        opacity: gate.ensoOpacity
    }
    Image {
        id: seal
        source: gate.dir + "seal.png"
        width: 211 * gate.s; height: width; smooth: true
        x: gate.colX + 175 * gate.s - width / 2; y: 585 * gate.s - height / 2
        opacity: gate.sealOpacity; scale: gate.sealScale
        // no art on disk (a dev box): the pack's crest stands in
        Image { anchors.fill: parent; anchors.margins: parent.width * 0.2; source: Theme.t.crest; mipmap: true
                visible: seal.status === Image.Error }
    }

    // the one gesture: the seal is pressed (a short settle from 108% to 100%)
    function stamp() { stampAnim.restart() }
    ParallelAnimation {
        id: stampAnim
        NumberAnimation { target: gate; property: "sealOpacity"; from: 0; to: 1; duration: Theme.ms(180); easing.type: Easing.OutQuad }
        NumberAnimation { target: gate; property: "sealScale"; from: 1.08; to: 1; duration: Theme.ms(360); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.ease }
    }
}
