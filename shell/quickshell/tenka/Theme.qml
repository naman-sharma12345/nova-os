pragma Singleton
// Colours, type, art and words for the active pack. ~/.config/tenka/shell-theme.json is written
// by `tenka-theme`; the shell follows it live.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root
    readonly property alias t: adapter
    readonly property string display: "Marcellus"
    readonly property string brand: "Cinzel Decorative"
    readonly property string ui: "Marcellus"   // the one UI face (regular only; it has no bold)
    readonly property string glyphs: "Symbols Nerd Font"
    readonly property bool xia: adapter.name === "xianxia"
    // the ledger faces share the windows' corners: Tenka nearly square (a blade edge), Tianxia a little softer
    readonly property int ledgerR: xia ? 12 : 6
    // Off Hyprland (sway, a nested test, Lite) nothing blurs behind layers, so glass frosts itself
    // from a pre-blurred copy of the wallpaper. On Hyprland the compositor's blur does it.
    readonly property bool selfBlur: Quickshell.env("TENKA_SELF_BLUR") === "1" || (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") === ""
    readonly property string wallBlur: adapter.wallpaper.replace("/wallpapers/", "/wallpapers-blur/")
    readonly property real sw: Quickshell.screens.length ? Quickshell.screens[0].width : 1920
    readonly property real sh: Quickshell.screens.length ? Quickshell.screens[0].height : 1080
    readonly property int r: 22          // the one card radius
    readonly property int gap: 18        // the one spacing unit
    function alpha(c, a) { const q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
    property date now: clock.date
    property bool stillness: false       // do-not-disturb
    property bool nightInk: false        // hyprsunset
    property bool deskOpen: false        // the card cluster and the dock are showing
    property bool hush: false            // a full overlay (launcher, power) is up: the desk type steps back
    // windows on the focused workspace: the desk's big type steps back while you work, so it never
    // reads through a translucent terminal (TENKA_DESK_STAY=1 keeps it). Asked of hyprctl on each
    // window/workspace event: Quickshell's own toplevel list misses windows opened before it tracked them.
    property int wsWindows: 0
    readonly property bool working: Quickshell.env("TENKA_DESK_STAY") !== "1" && wsWindows > 0
    Process {
        id: wsQ; command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.wsWindows = JSON.parse(text).windows || 0 } catch (e) { root.wsWindows = 0 } } }
    }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (/^(openwindow|closewindow|movewindow|workspace|focusedmon|activespecial)/.test(ev.name)) wsQ.running = true
            if (ev.name === "configreloaded") perfQ.running = true   // tenka-perf reloads Hyprland after it flips the mode
        }
    }
    Component.onCompleted: { perfQ.running = true; if ((Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== "") wsQ.running = true }
    // Performance mode (tenka-perf): its flag file is ~/.config/tenka/perf. The shell's own motion rests with it.
    property bool perf: false
    Process {
        id: perfQ; command: ["sh", "-c", "test -e \"$HOME/.config/tenka/perf\" && echo on || echo off"]
        stdout: StdioCollector { onStreamFinished: root.perf = text.trim() === "on" }
    }
    property bool pinOpen: false         // keep them up (desk open via IPC / clock)
    function asset(p) { return Qt.resolvedUrl("assets/" + adapter.name + "/" + p) }
    function icon(n) { return asset("icons/" + n + ".svg") }
    property int unread: 0
    // the OSD, when the notch carries it: kind ("volume" | "brightness"), value 0..1, and a tick that re-arms it
    property string osdKind: ""
    property real osdValue: 0
    property int osdTick: 0

    SystemClock { id: clock; precision: SystemClock.Seconds }
    IpcHandler {
        target: "desk"
        function toggle(): void { root.deskOpen = !root.deskOpen; root.pinOpen = root.deskOpen }
        function open(): void { root.pinOpen = true; root.deskOpen = true }
        function close(): void { root.pinOpen = false; root.deskOpen = false }
    }
    // ~/.config/tenka/desk.json: { "city": "New Delhi", "events": [ { "title": "…", "when": "Mon" } ] }
    FileView {
        path: Quickshell.env("HOME") + "/.config/tenka/desk.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter { id: deskCfg; property string city: ""; property var events: []; property string style: ""; property string bar: ""; property string lock: ""; property string cc: ""; property string launcher: ""; property string cards: ""; property string dock: "" }
    }
    readonly property alias desk: deskCfg
    // the desk title layout: "blade" (big clock left, seal, proverb), "film" (a cinematic lower band),
    // "scroll" (a hanging scroll at the left edge). desk.json "style" or TENKA_DESK picks it.
    // the bar: "line" (dots + time, no box), "frame" (an ink passe-partout round the screen, the bar in its top
    // edge), "notch" (one ink pill hanging from the top centre). desk.json "bar" or TENKA_BAR picks it.
    readonly property string barStyle: Quickshell.env("TENKA_BAR") || deskCfg.bar || "notch"
    readonly property string deskStyle: Quickshell.env("TENKA_DESK") || deskCfg.style || "blade"
    readonly property string ccStyle: Quickshell.env("TENKA_CC") || deskCfg.cc || "ledger"
    readonly property string launcherStyle: Quickshell.env("TENKA_LAUNCHER") || deskCfg.launcher || "menu"
    readonly property string cardsStyle: Quickshell.env("TENKA_CARDS") || deskCfg.cards || "ledger"   // ledger | bare | glass
    readonly property string dockStyle: Quickshell.env("TENKA_DOCK") || deskCfg.dock || "ledger"      // ledger | glass

    FileView {
        path: Quickshell.env("HOME") + "/.config/tenka/shell-theme.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: adapter
            property string name: "samurai"
            property string display: "Tenka"
            property string word: "TENKA"
            property string tagline: "ALL UNDER HEAVEN"
            property string base: "#0f0d0c"
            property string surface: "#1a1614"
            property string accent: "#d8412f"
            property string gold: "#c9a35a"
            property string text: "#efe6d6"
            property string subtext: "#b8ab96"
            property string ink: "#fff8ec"
            property string wallpaper: "/usr/share/tenka/themes/samurai/wallpapers/00-title-card.jpg"
            property string keyart: "/usr/share/tenka/themes/samurai/keyart.jpg"
            property string crest: "/usr/share/tenka/themes/samurai/crest-1024.png"
            property string stroke: "/usr/share/grub/themes/tenka-samurai/select_c.png"
            property string sounds: "/usr/share/tenka/themes/samurai/sounds"
            property string clan: "Ronin of the Tenka clan"
            property string seekWord: "Seek"
            property string lockWord: "Guard"
            property string logoutWord: "Retreat"
            property string suspendWord: "Rest"
            property string rebootWord: "Return"
            property string shutdownWord: "Sheathe"
            property string stillWord: "Stillness"
            property var proverbs: ["Fall seven times, stand up eight.", "The bamboo that bends is stronger than the oak that resists.", "The sword is the soul.", "Even monkeys fall from trees.", "A single arrow is easily broken, not ten in a bundle."]
        }
    }

    function hourName(d) {
        const a = ["Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"];
        return "Hour of the " + a[Math.floor(((d.getHours() + 1) % 24) / 2)];
    }
    function hm(d) { const h = d.getHours() % 12 || 12; return h + ":" + Qt.formatTime(d, "mm") }
    function ap(d) { return d.getHours() < 12 ? "AM" : "PM" }
    function chime(name) { Quickshell.execDetached(["sh", "-c", "pw-play " + adapter.sounds + "/" + name + ".ogg 2>/dev/null || paplay " + adapter.sounds + "/" + name + ".ogg 2>/dev/null"]) }
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function ipc(target, fn) { Quickshell.execDetached(["qs", "-c", "tenka", "ipc", "call", target, fn]) }
}
