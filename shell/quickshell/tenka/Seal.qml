// The Seal: our own polkit prompt (Quickshell's polkit agent), in place of the stock dialog. When an app
// asks for leave to act as the administrator, the desk dims to a flat ink wash and one small card asks for
// the word: the pack's seal, what is asked in Marcellus, the account, one ruled field. ENTER seals, ESC
// refuses. A wrong word says so in the accent, plainly. Flat: ink, one gold rule, no glow.
// tenka-session starts hyprpolkitagent only if the shell has not taken the agent's place within 15 s.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import "seal"

PanelWindow {
    id: seal
    readonly property bool sim: (Quickshell.env("TENKA_SEAL_SIM") || "") !== ""
    readonly property var flow: agent.flow
    readonly property bool open: flow !== null || sim
    readonly property string message: flow ? flow.message : "Authentication is needed to install software."
    readonly property string prompt: flow ? (flow.inputPrompt || "Password:") : "Password:"
    property bool wrong: false   // a refused word: polkit does not always send its own message, so we say it
    readonly property string note: flow ? (flow.supplementaryMessage || (wrong ? "That word was not right. Try again." : "")) : (Quickshell.env("TENKA_SEAL_SIM") === "wrong" ? "Sorry, that didn't work. Please try again." : "")
    readonly property bool noteIsError: flow ? (flow.supplementaryIsError || (wrong && !flow.supplementaryMessage)) : note !== ""
    readonly property bool echo: flow ? flow.responseVisible : false
    readonly property string who: Quickshell.env("USER") || "you"
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tenka-seal"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    PolkitAgent { id: agent }
    // tells tenka-session the shell holds the agent, so hyprpolkitagent is not needed
    Process { running: agent.isRegistered; command: ["sh", "-c", "touch \"${XDG_RUNTIME_DIR:-/tmp}/tenka-seal\""] }
    onOpenChanged: { Theme.hush = open; wrong = false; if (open) card.focusField() }
    onFlowChanged: if (flow) card.focusField()
    Connections {
        target: seal.flow
        function onAuthenticationFailed() { seal.wrong = true; card.clear(); card.focusField() }
        function onIsResponseRequiredChanged() { if (seal.flow && seal.flow.isResponseRequired) card.focusField() }
    }
    function give(word) { if (flow && flow.isResponseRequired) { wrong = false; flow.submit(word) } }
    function refuse() { if (flow) flow.cancelAuthenticationRequest() }

    // the desk steps back: one flat wash, no blur needed
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, seal.open ? 0.62 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: seal.open }

    // the card itself is seal/SealCard.qml, shared with Tenka Lite
    SealCard {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.3 + (seal.open ? 0 : 16)
        opacity: seal.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        base: Theme.t.base; text: Theme.t.text; gold: Theme.gold; accent: Theme.accent
        radius: Theme.ledgerR; face: Theme.display; xia: Theme.xia; sealImage: Theme.asset("seal.png")
        message: seal.message; who: seal.who; prompt: seal.prompt; note: seal.note; noteIsError: seal.noteIsError; echo: seal.echo
        preset: seal.sim && !seal.flow ? "kept word" : ""
        onGive: w => seal.give(w)
        onRefuse: seal.refuse()
    }
}
