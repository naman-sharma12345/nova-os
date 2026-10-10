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
    property string typed: Quickshell.env("TENKA_LOCK_PREVIEW") === "1" ? (Quickshell.env("TENKA_LOCK_TYPED") || "") : ""   // renders only
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
            LockFace { anchors.fill: parent; lock: root }
        }
    }

    // a preview of the face as an ordinary layer (renders and screenshots), never a real lock
    PanelWindow {
        visible: Quickshell.env("TENKA_LOCK_PREVIEW") === "1"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: Theme.t.base
        LockFace { anchors.fill: parent; lock: root }
    }
}
