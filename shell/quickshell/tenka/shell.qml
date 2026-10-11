//@ pragma IconTheme Papirus-Dark
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Tenka shell (Quickshell). Every surface is drawn here in the active theme pack:
// the wallpaper, the desktop title card and its cards, the bar, the launcher, the control
// center, notifications, the on-screen display and the power menu.
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property ShellScreen modelData
            Wall { screen: perScreen.modelData }
            Desk { screen: perScreen.modelData }
            Bar { screen: perScreen.modelData }
            Frame { screen: perScreen.modelData }
            Notch { screen: perScreen.modelData }
            Dock { screen: perScreen.modelData }
            Cards { screen: perScreen.modelData }
            FocusVeil { screen: perScreen.modelData }
            Threshold { screen: perScreen.modelData }
        }
    }
    Launcher {}
    Clipboard {}
    Overview {}
    Switcher {}
    Slip {}
    ControlCenter {}
    Notifications {}
    Osd {}
    PowerMenu {}
    Lock {}
}
