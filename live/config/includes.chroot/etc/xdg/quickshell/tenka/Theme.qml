pragma Singleton
// Colours, type, art and words for the active pack. ~/.config/tenka/shell-theme.json is written
// by `tenka-theme`; the shell follows it live.
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property alias t: adapter
    readonly property string display: "Marcellus"
    readonly property string ui: "Inter"
    readonly property string glyphs: "Symbols Nerd Font"
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    property date now: clock.date

    SystemClock { id: clock; precision: SystemClock.Seconds }

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
            property string wallpaper: "/usr/share/tenka/themes/samurai/wallpapers/13-ronin-red-sun.jpg"
            property string crest: "/usr/share/tenka/themes/samurai/crest-1024.png"
            property string stroke: "/usr/share/grub/themes/tenka-samurai/select_c.png"
            property string seekWord: "SEEK"
            property string lockWord: "Guard"
            property string logoutWord: "Retreat"
            property string suspendWord: "Rest"
            property string rebootWord: "Return"
            property string shutdownWord: "Sheathe"
            property var proverbs: ["The sword is the soul.", "Fall seven times, stand up eight.", "The bamboo that bends is stronger than the oak that resists."]
        }
    }

    function hourName(d) {
        const a = ["Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"];
        return "Hour of the " + a[Math.floor(((d.getHours() + 1) % 24) / 2)];
    }
}
