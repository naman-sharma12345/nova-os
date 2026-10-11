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
import QtQuick.Controls

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
    onOpenChanged: { Theme.hush = open; wrong = false; if (open) { field.text = ""; field.forceActiveFocus() } }
    onFlowChanged: if (flow) { field.text = ""; field.forceActiveFocus() }
    Connections {
        target: seal.flow
        function onAuthenticationFailed() { seal.wrong = true; field.text = ""; field.forceActiveFocus() }
        function onIsResponseRequiredChanged() { if (seal.flow && seal.flow.isResponseRequired) field.forceActiveFocus() }
    }
    function give() { if (flow && flow.isResponseRequired) { wrong = false; flow.submit(field.text) } field.text = "" }
    function refuse() { if (flow) flow.cancelAuthenticationRequest() }

    // the desk steps back: one flat wash, no blur needed
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.t.base, seal.open ? 0.62 : 0)
                Behavior on color { enabled: !Theme.perf; ColorAnimation { duration: 220 } } }
    MouseArea { anchors.fill: parent; enabled: seal.open }

    Item {
        id: card
        width: 620; height: 352
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.3 + (seal.open ? 0 : 16)
        opacity: seal.open ? 1 : 0
        Behavior on y { enabled: !Theme.perf; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: !Theme.perf; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Rectangle { anchors.fill: parent; radius: Theme.ledgerR; color: Theme.alpha(Theme.t.base, 0.94)
                    border.width: 1; border.color: Theme.alpha(Theme.gold, 0.45) }

        Row {
            x: 34; y: 30; spacing: 14
            Image { width: 22; height: 26; source: Theme.asset("seal.png"); smooth: true; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Theme.xia ? "THE TALISMAN IS ASKED" : "THE SEAL IS ASKED"; color: Theme.gold; font.family: Theme.display
                   font.pixelSize: 12; font.letterSpacing: 5; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { x: 30; y: 74; width: parent.width - 60; height: 1; color: Theme.alpha(Theme.gold, 0.35) }

        Text { x: 34; y: 96; width: parent.width - 68; text: seal.message; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
               color: Theme.t.text; font.family: Theme.display; font.pixelSize: 21; lineHeight: 1.15 }
        Text { x: 34; y: 176; text: "AS  " + seal.who.toUpperCase(); color: Theme.alpha(Theme.gold, 0.75)
               font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 4 }

        TextField {
            id: field
            x: 30; y: 200; width: parent.width - 60; height: 52
            background: Item { Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                               color: field.activeFocus ? Theme.accent : Theme.alpha(Theme.gold, 0.4) } }
            placeholderText: seal.prompt.replace(/:\s*$/, "").toLowerCase()
            placeholderTextColor: Theme.alpha(Theme.t.text, 0.38)
            echoMode: seal.echo ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            color: Theme.t.text; font.family: Theme.display; font.pixelSize: 22; leftPadding: 4
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            text: seal.sim && !seal.flow ? "kept word" : ""
            Keys.onEscapePressed: seal.refuse()
            onAccepted: seal.give()
        }
        Text { x: 34; y: 266; width: parent.width - 68; visible: seal.note !== ""; text: seal.note; elide: Text.ElideRight
               color: seal.noteIsError ? Theme.accent : Theme.alpha(Theme.t.text, 0.6); font.family: Theme.display; font.pixelSize: 14 }

        Text {
            x: 34; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
            text: "ENTER  to seal      ESC  to refuse"
            color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 12; font.letterSpacing: 2
        }
    }
}
