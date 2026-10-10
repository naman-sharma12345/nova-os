// The month: weekday initials in gold, past days in shadow, today under a hand-stamped seal,
// and the next things on your list (~/.config/tenka/desk.json "events").
import QtQuick

Glass {
    id: cal
    width: 300; height: 296; radius: 24; tint: 0.30; innerLine: 0.22; line: 0.16
    readonly property date d: Theme.now
    readonly property int first: (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7
    readonly property int days: new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
    readonly property int weeks: Math.ceil((first + days) / 7)
    readonly property real cw: (width - 44) / 7

    Column {
        x: 22; y: 22; width: parent.width - 44; spacing: 10
        Row {
            width: parent.width
            Text { id: mon; text: Qt.formatDate(cal.d, "MMMM").toUpperCase(); color: Theme.t.text; font.family: Theme.display; font.pixelSize: 15; font.letterSpacing: 5 }
            Item { width: parent.width - mon.width - yr.width; height: 1 }
            Text { id: yr; text: Qt.formatDate(cal.d, "yyyy"); color: Theme.alpha(Theme.t.text, 0.45); font.family: Theme.display; font.pixelSize: 14; font.letterSpacing: 3 }
        }
        Grid {
            columns: 7; rowSpacing: 1
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Text { required property string modelData
                       width: cal.cw; height: 20; horizontalAlignment: Text.AlignHCenter; text: modelData
                       color: Theme.t.gold; font.family: Theme.display; font.pixelSize: 11; font.letterSpacing: 1 }
            }
            Repeater {
                model: cal.weeks * 7
                Item {
                    required property int index
                    readonly property int day: index - cal.first + 1
                    readonly property bool real: day >= 1 && day <= cal.days
                    readonly property bool today: day === cal.d.getDate()
                    readonly property bool past: day < cal.d.getDate()
                    width: cal.cw; height: 24
                    Image { anchors.centerIn: parent; width: 30; height: 30; visible: parent.today && parent.real; source: Theme.asset("seal.png"); rotation: -4; smooth: true }
                    Text { anchors.centerIn: parent; text: parent.real ? parent.day : ""
                           color: parent.today ? Theme.t.ink : Theme.alpha(Theme.t.text, parent.past ? 0.30 : 0.88)
                           font.family: parent.today ? Theme.display : Theme.ui; font.pixelSize: parent.today ? 14 : 12 }
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.t.gold, 0.18); visible: Theme.desk.events.length > 0 }
        Repeater {
            model: Theme.desk.events.slice(0, 2)
            Row {
                required property var modelData
                spacing: 10
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.t.accent; anchors.verticalCenter: parent.verticalCenter }
                Text { text: modelData.title; color: Theme.alpha(Theme.t.text, 0.88); font.family: Theme.ui; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "·  " + modelData.when; color: Theme.alpha(Theme.t.gold, 0.85); font.family: Theme.display; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
