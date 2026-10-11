-- ╭──────────────────────────────────────────────────────────────╮
-- │  Tenka · Hyprland                                            │
-- │  Shared layout + keys. Colours, borders and motion come from │
-- │  ~/.config/hypr/theme.lua, which `tenka-theme` swaps.        │
-- ╰──────────────────────────────────────────────────────────────╯
local HOME = os.getenv("HOME")
local ok, T = pcall(dofile, HOME .. "/.config/hypr/theme.lua")
if not ok then T = { cursor = "Tenka-Samurai-Cursors" } end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local terminal = "kitty"
local files    = "thunar"
local browser  = "firefox-esr"
local menu     = "tenka-launcher"

-- environment -------------------------------------------------------------
hl.env("XCURSOR_THEME", T.cursor)
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- autostart ---------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("tenka-session")
end)

-- look --------------------------------------------------------------------
hl.config({
    general = {
        -- gaps, border size, colours, rounding and motion come from theme.lua (the per-theme rice)
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 0.97,
        dim_inactive = false,
        shadow = {
            enabled = true,
            range = 26,
            render_power = 3,
            offset = "0 8",
        },
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            new_optimizations = true,
            xray = false,
            noise = 0.025,
            contrast = 1.05,
            brightness = 0.85,
            vibrancy = 0.22,
            vibrancy_darkness = 0.4,
            popups = true,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        animate_manual_resizes = true,
        focus_on_activate = true,
        background_color = 0xff0a0908,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = true },
    },
    cursor = { no_hardware_cursors = true },
    -- no stock update/donation windows over a themed desktop (the update screen also crashed under llvmpipe in the VM)
    ecosystem = { no_update_news = true, no_donation_nag = true },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- layers: frosted glass for every shell surface --------------------------
for _, ns in ipairs({ "waybar", "launcher", "notifications", "logout_dialog", "swayosd", "gtk-layer-shell",
                      "tenka-launcher", "tenka-control", "tenka-notify", "tenka-cards", "tenka-dock", "tenka-osd", "tenka-power" }) do
    hl.layer_rule({ name = "glass-" .. ns, match = { namespace = "^" .. ns .. "$" }, blur = true, ignore_alpha = 0.2 })
end
hl.layer_rule({ name = "wallpaper-fade", match = { namespace = "^wallpaper$" }, animation = "fade" })
hl.layer_rule({ name = "launcher-dim", match = { namespace = "^launcher$" }, dim_around = true })
hl.layer_rule({ name = "logout-anim", match = { namespace = "^logout_dialog$" }, animation = "fade" })
-- the Tenka shell animates its own surfaces; the compositor only fades them
hl.layer_rule({ name = "tenka-fade", match = { namespace = "^tenka-(launcher|control|power|cards|osd|overview|switcher|air|bond|inkstone)$" }, animation = "fade" })
hl.layer_rule({ name = "tenka-wall", match = { namespace = "^tenka-wall$" }, animation = "fade" })

-- windows -----------------------------------------------------------------
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "float-utils",
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|nwg-look|qt6ct|tenka-welcome|imv|calamares)$" },
    float = true, center = true, size = "1100 720" })
-- the welcome runs on the qml runtime, whose Wayland app_id is org.qt-project.qml (RESOURCE_NAME only
-- names X11 windows), so it is matched by its title: floated, centred, at the size it was drawn for
hl.window_rule({ name = "tenka-welcome", match = { title = "^(Welcome to Tenka)$" },
    float = true, center = true, size = "1180 700" })
-- The Glance (tenka-glance, Ctrl+Space in Files) is a qml window too: floated and centred at its own size
hl.window_rule({ name = "tenka-glance", match = { title = "^(The Glance)$" }, float = true, center = true })
hl.window_rule({ name = "glass-terminal", match = { class = "^(kitty)$" }, opacity = "0.94 0.88" })
-- the file manager is translucent through its own GTK CSS (glass); the compositor only blurs behind it
hl.window_rule({ name = "glass-files", match = { class = "^([Tt]hunar)$" }, opacity = "1.0 0.94" })
hl.window_rule({ name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true })

-- keys --------------------------------------------------------------------
local M = "SUPER"
hl.bind(M .. " + Return",      hl.dsp.exec_cmd(terminal))
hl.bind(M .. " + Space",       hl.dsp.exec_cmd(menu))
hl.bind(M .. " + D",           hl.dsp.exec_cmd("qs -c tenka ipc call desk toggle"))
hl.bind(M .. " + A",           hl.dsp.exec_cmd("qs -c tenka ipc call control toggle"))
hl.bind(M .. " + E",           hl.dsp.exec_cmd(files))
hl.bind(M .. " + B",           hl.dsp.exec_cmd(browser))
hl.bind(M .. " + Q",           hl.dsp.window.close())
hl.bind(M .. " + F",           hl.dsp.window.fullscreen())
hl.bind(M .. " + V",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + P",           hl.dsp.window.pseudo())
hl.bind(M .. " + J",           hl.dsp.layout("togglesplit"))
hl.bind(M .. " + L",           hl.dsp.exec_cmd("tenka-lock"))
hl.bind(M .. " + Escape",      hl.dsp.exec_cmd("tenka-power"))
hl.bind(M .. " + T",           hl.dsp.exec_cmd("tenka-theme-menu"))
hl.bind(M .. " + W",           hl.dsp.exec_cmd("tenka-wallpaper next"))
hl.bind(M .. " + SHIFT + V",   hl.dsp.exec_cmd("tenka-clipboard"))
-- the shell's own surfaces take their keys as global shortcuts (straight to the shell, in order, no process
-- start per key); `qs -c tenka ipc call overview|switcher|slip ...` still works from scripts
hl.bind(M .. " + Tab",         hl.dsp.global("tenka:overview"))        -- the field: every desk at once
hl.bind("ALT + Tab",           hl.dsp.global("tenka:switcher-next"))   -- the turn: our own window switcher
hl.bind("ALT + SHIFT + Tab",   hl.dsp.global("tenka:switcher-prev"))
hl.bind("ALT + Alt_L",         hl.dsp.global("tenka:switcher-commit"), { release = true, transparent = true, non_consuming = true })
hl.bind("ALT + Alt_R",         hl.dsp.global("tenka:switcher-commit"), { release = true, transparent = true, non_consuming = true })
hl.bind(M .. " + N",           hl.dsp.global("tenka:slip"))            -- the slip: a note to self on the desk
hl.bind(M .. " + period",      hl.dsp.global("tenka:glyphs"))          -- the inkstone: find and place a glyph
hl.bind(M .. " + SHIFT + C",   hl.dsp.global("tenka:loupe"))           -- the loupe: pick a colour, measure the screen
hl.bind(M .. " + slash",       hl.dsp.global("tenka:codex"))           -- the codex: every key this desk answers to
hl.bind(M .. " + I",           hl.dsp.global("tenka:incense"))         -- the incense: a timer that burns down
hl.bind("Print",               hl.dsp.exec_cmd("tenka-shot area"))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd("tenka-shot screen"))
hl.bind(M .. " + SHIFT + E",   hl.dsp.exec_cmd("tenka-power"))
hl.bind(M .. " + SHIFT + P",   hl.dsp.exec_cmd("tenka-perf toggle"))
hl.bind(M .. " + Z",           hl.dsp.exec_cmd("tenka-focus toggle"))   -- focus: 25 min, desk dims, notes wait

for _, d in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(M .. " + " .. d,            hl.dsp.focus({ direction = d }))
    hl.bind(M .. " + SHIFT + " .. d,    hl.dsp.window.move({ direction = d }))
end
for i = 1, 10 do
    local key = i % 10
    hl.bind(M .. " + " .. key,          hl.dsp.focus({ workspace = i }))
    hl.bind(M .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }))
end
hl.bind(M .. " + S",           hl.dsp.workspace.toggle_special("scroll"))
hl.bind(M .. " + SHIFT + S",   hl.dsp.window.move({ workspace = "special:scroll" }))
hl.bind(M .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + mouse:272",   hl.dsp.window.drag(),   { mouse = true })
hl.bind(M .. " + mouse:273",   hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ || swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- || swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("tenka-osd brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("tenka-osd brightness down"), { locked = true, repeating = true })
-- the lock keys say what they did: a small "CAPS LOCK on / off" card (the key itself still reaches the keyboard)
hl.bind("Caps_Lock",             hl.dsp.exec_cmd("tenka-osd caps"), { locked = true, release = true, non_consuming = true, transparent = true })
hl.bind("Num_Lock",              hl.dsp.exec_cmd("tenka-osd num"),  { locked = true, release = true, non_consuming = true, transparent = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- performance mode (tenka-perf on): no blur, shadows or motion; same art
pcall(dofile, HOME .. "/.config/hypr/perf.lua")
-- focus mode (tenka-focus on): the windows you are not in dim a little
pcall(dofile, HOME .. "/.config/hypr/focus.lua")

-- local overrides survive theme switches
pcall(dofile, HOME .. "/.config/hypr/user.lua")
