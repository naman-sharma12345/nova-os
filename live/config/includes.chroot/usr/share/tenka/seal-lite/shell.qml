// Tenka Lite's Seal (Tianxia: The Talisman): the flagship's polkit prompt on X11. Quickshell's polkit agent
// in a config of its own (no layer shell here): when an app asks for leave to act as the administrator, one
// small frameless window in the middle of the screen carries the same card (/etc/xdg/quickshell/tenka/seal/
// SealCard.qml). tenka-seal-lite starts it at login and falls back to hyprpolkitagent if it cannot register.
// TENKA_SEAL_SIM shows the card with a stand-in request (renders); TENKA_SEAL_SIM=wrong adds the refusal line.
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Window
import "file:///etc/xdg/quickshell/tenka/seal"

ShellRoot {
    id: root
    readonly property string simWord: Quickshell.env("TENKA_SEAL_SIM") || ""
    readonly property bool sim: simWord !== ""
    readonly property var flow: agent.flow
    readonly property bool open: flow !== null || sim
    property bool wrong: false
    property var th: ({})
    readonly property bool xia: th.name === "xianxia"

    FileView {
        id: tf
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/tenka/shell-theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.th = JSON.parse(tf.text()) } catch (e) {} }
    }
    PolkitAgent { id: agent }
    // tells tenka-seal-lite the agent is ours, so hyprpolkitagent is not needed
    Process { running: agent.isRegistered; command: ["sh", "-c", "touch \"${XDG_RUNTIME_DIR:-/tmp}/tenka-seal\""] }
    Connections {
        target: root.flow
        function onAuthenticationFailed() { root.wrong = true; card.clear(); card.focusField() }
        function onIsResponseRequiredChanged() { if (root.flow && root.flow.isResponseRequired) card.focusField() }
    }
    onFlowChanged: { wrong = false; if (flow) card.focusField() }

    Window {
        id: w
        visible: root.open
        flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        width: card.width; height: card.height
        x: Screen.virtualX + (Screen.width - width) / 2
        y: Screen.virtualY + Screen.height * 0.3
        color: root.th.base || "#0f0d0c"
        title: root.xia ? "The Talisman" : "The Seal"
        onVisibleChanged: if (visible) { w.requestActivate(); card.focusField() }

        SealCard {
            id: card
            base: root.th.base || "#0f0d0c"; text: root.th.text || "#efe6d6"; gold: root.th.gold || "#c9a35a"
            accent: root.th.accent || "#b5452f"; radius: 0; xia: root.xia
            sealImage: "file:///etc/xdg/quickshell/tenka/assets/" + (root.th.name || "samurai") + "/seal.png"
            message: root.flow ? root.flow.message : "Authentication is needed to install software."
            prompt: root.flow ? (root.flow.inputPrompt || "Password:") : "Password:"
            note: root.flow ? (root.flow.supplementaryMessage || (root.wrong ? "That word was not right. Try again." : ""))
                            : (root.simWord === "wrong" ? "Sorry, that didn't work. Please try again." : "")
            noteIsError: root.flow ? (root.flow.supplementaryIsError || (root.wrong && !root.flow.supplementaryMessage)) : note !== ""
            echo: root.flow ? root.flow.responseVisible : false
            who: Quickshell.env("USER") || "you"
            preset: root.sim && !root.flow ? "kept word" : ""
            onGive: word => { if (root.flow && root.flow.isResponseRequired) { root.wrong = false; root.flow.submit(word) } }
            onRefuse: if (root.flow) root.flow.cancelAuthenticationRequest()
        }
    }
}
