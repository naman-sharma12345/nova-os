//@ pragma IconTheme Papirus-Dark
// Tenka shell (Quickshell): a desktop title card, a floating bar, a launcher,
// a control center and notifications, all drawn in the active theme pack.
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property ShellScreen modelData
            Desk { screen: perScreen.modelData }
            Bar { screen: perScreen.modelData }
        }
    }
    Launcher {}
    ControlCenter {}
    Notifications {}
}
