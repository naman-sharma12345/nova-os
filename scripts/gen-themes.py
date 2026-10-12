#!/usr/bin/env python3
"""Tenka theme generator.

Writes every per-theme config (Hyprland colours, waybar, launcher, notifications,
terminal, power menu, fastfetch, GTK/Qt/Plasma colours, hyprlock wording) from
one palette + wording table, so both packs stay cohesive.

    python3 scripts/gen-themes.py        # regenerate themes/<t>/home and system themes
"""
import os, sys, json, textwrap
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tenka_kvantum
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

THEMES = {
  "samurai": dict(
    display="Tenka", tagline="The way of the blade", pretty="Tenka",
    p=dict(base="#0f0d0c", mantle="#0a0908", surface="#1b1816", overlay="#2a2522",
           text="#efe6d6", subtext="#b8ab96", accent="#d8412f", accent2="#c9a35a",
           accent_l="#e85a45", alt="#6f86b8", alt_d="#2e3f63", soft="#f2a7b5", green="#7d8f5a"),
    font_display="Marcellus", font_brand="Cinzel Decorative", font_ui="Inter", font_mono="JetBrains Mono",
    cursor="Tenka-Samurai-Cursors", icons="Tenka-Samurai", icon_folder="red",
    gtk="Tenka-Samurai", gtk_fallback="Orchis-Dark",
    rounding=10, border=2,
    words=dict(
      lock_title="The blade rests.", lock_sub="Speak the word to return", lock_ph="password",
      lock="Guard", logout="Retreat", suspend="Rest", hibernate="Meditate", reboot="Return", shutdown="Sheathe",
      launcher_prompt="seek  ", welcome="Welcome back", greet="Return to the dojo",
      ff_keys=dict(os="Clan", host="Fortress", kernel="Blade", uptime="Vigil", packages="Arsenal", shell="Scroll",
                   wm="Dojo", theme="Armour", terminal="Brush", cpu="Spirit", gpu="Lantern", memory="Ki", disk="Land"),
      ff_title="the way of the blade"),
    ws_icons=dict(active="\u25c9", default="\u25cb", empty="\u00b7"),
    anim="samurai",
  ),
  "xianxia": dict(
    display="Tianxia", tagline="The path to immortality", pretty="Tianxia",
    p=dict(base="#0b1513", mantle="#07100e", surface="#12211e", overlay="#1d332e",
           text="#eef3ec", subtext="#a9bdb4", accent="#5fc9a0", accent2="#e2bd6b",
           accent_l="#9ee6c4", alt="#8fb3d1", alt_d="#2c4a5c", soft="#f0a3b8", green="#e2553f"),
    font_display="Marcellus", font_brand="Cinzel Decorative", font_ui="Inter", font_mono="JetBrains Mono",
    cursor="Tenka-Xianxia-Cursors", icons="Tenka-Xianxia", icon_folder="teal",
    gtk="Tenka-Xianxia", gtk_fallback="Orchis-Dark",
    rounding=16, border=2,
    words=dict(
      lock_title="In seclusion.", lock_sub="Recite the incantation to emerge", lock_ph="incantation",
      lock="Seclusion", logout="Descend", suspend="Meditate", hibernate="Dormancy", reboot="Rebirth", shutdown="Ascend",
      launcher_prompt="divine  ", welcome="The heavens welcome you", greet="Step onto the path",
      ff_keys=dict(os="Realm", host="Cave Abode", kernel="Core", uptime="Cultivated", packages="Treasures", shell="Scripture",
                   wm="Sect", theme="Robes", terminal="Talisman", cpu="Spirit Root", gpu="Elixir Furnace", memory="Qi", disk="Spirit Land"),
      ff_title="the path to immortality"),
    ws_icons=dict(active="\u25c6", default="\u25c7", empty="\u00b7"),
    anim="xianxia",
  ),
}

def hx(c): return c.lstrip("#")
def rgba(c, a): c = hx(c); return f"rgba({int(c[0:2],16)}, {int(c[2:4],16)}, {int(c[4:6],16)}, {a})"
def rgb_t(c): c = hx(c); return f"{int(c[0:2],16)},{int(c[2:4],16)},{int(c[4:6],16)}"
def mix(a, b, t):
    a, b = hx(a), hx(b)
    return "#" + "".join(f"{round(int(a[i:i+2],16)*(1-t)+int(b[i:i+2],16)*t):02x}" for i in (0,2,4))

def W(path, s, mode=0o644):
    path = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f: f.write(s)
    os.chmod(path, mode)

def gen(name, T):
    p, w = T["p"], T["words"]
    H = f"themes/{name}/home"
    # ---------- Tenka Lite's denser glass (xfwm4 has no blur): tenka-lite-apply copies it to ~/.cache/tenka/session.css
    W(f"themes/{name}/lite-session.css", textwrap.dedent(f"""\
    /* Tenka Lite: no compositor blur here, so Files is near-solid ink: at 0.90 the desk clock read through it (VM, nightly #7) */
    window.thunar.background:not(.xfce4-panel):not(.tenka-lite) {{ background-color: {rgba(p['base'], 0.97)}; background-image: none; }}
    .thunar .sidebar:not(.tenka-lite), .thunar .sidebar treeview.view:not(.tenka-lite) {{ background-color: {rgba(p['mantle'], 0.35)}; }}
    /* every other window too: Hyprland's washi glass is see-through because it is blurred; unblurred it would be noise */
    window.background:not(.xfce4-panel):not(.thunar):not(.tenka-lite), dialog.background:not(.tenka-lite) {{ background-color: {p['base']}; }}
    .sidebar:not(.tenka-lite) {{ background-color: {rgba(p['mantle'], 0.5)}; }}
    headerbar:not(.tenka-lite), .titlebar:not(.tenka-lite) {{ background-color: {p['surface']}; }}
    textview text:not(.tenka-lite), window.mousepad textview.view:not(.tenka-lite) {{ background-color: {p['base']}; }}
    /* T21: no blur on Lite, so menus stay dense ink sheets (the Hyprland glass rule would otherwise reach them) */
    window.background.popup:not(.xfce4-panel):not(.thunar):not(#whiskermenu-window):not(#XfceNotifyWindow):not(.tenka-lite) {{ background-color: {rgba(p['surface'], 0.97)}; background-image: none; }}
    popover.background:not(.tenka-lite), popover.menu:not(.tenka-lite) {{ background-color: {rgba(p['surface'], 0.97)}; background-image: none; }}
    """))
    # ---------- theme.env (read by scripts) ----------
    W(f"themes/{name}/theme.env", "\n".join([
        f'THEME_NAME="{name}"', f'THEME_DISPLAY="{T["display"]}"', f'THEME_TAGLINE="{T["tagline"]}"',
        f'THEME_CURSOR="{T["cursor"]}"', f'THEME_ICONS="{T["icons"]}"', f'THEME_ICON_FOLDER="{T["icon_folder"]}"',
        f'THEME_GTK="{T["gtk"]}"', f'THEME_GTK_FALLBACK="{T["gtk_fallback"]}"', f'THEME_FONT_DISPLAY="{T["font_display"]}"',
        f'THEME_FONT_BRAND="{T["font_brand"]}"',
        # the nearest of libadwaita's named accents, for GTK 4 apps that take the accent from the portal
        f'THEME_GNOME_ACCENT="{"teal" if name == "xianxia" else "red"}"',
    ] + [f'C_{k.upper()}="{v}"' for k, v in p.items()]) + "\n")
    # ---------- Hyprland palette (shared by hyprland + hyprlock) ----------
    W(f"{H}/.config/hypr/colors.conf", "# generated by scripts/gen-themes.py\n" + "\n".join(
        [f"${k} = rgb({hx(v)})" for k, v in p.items()] +
        [f"${k}_hex = {hx(v)}" for k, v in p.items()] +
        [f'$font_display = {T["font_display"]}', f'$font_ui = {T["font_ui"]}', f'$cursor = {T["cursor"]}',
         f'$theme_display = {T["display"]}', f'$theme_tagline = {T["tagline"]}',
         f'$lock_title = {w["lock_title"]}', f'$lock_sub = {w["lock_sub"]}', f'$lock_ph = {w["lock_ph"]}',
         f'$rounding = {T["rounding"]}']) + "\n")
    # ---------- kitty ----------
    if name == "samurai":
        k = dict(color0="#1b1816", color8="#4d453f", color1="#d8412f", color9="#e85a45", color2="#7d8f5a", color10="#9cb07a",
                 color3="#c9a35a", color11="#e0bf7e", color4="#6f86b8", color12="#93a8d6", color5="#f2a7b5", color13="#f8c4ce",
                 color6="#7aa59b", color14="#9fc6bd", color7="#d6ccbb", color15="#efe6d6")
    else:
        k = dict(color0="#12211e", color8="#3a564f", color1="#e2553f", color9="#f07a63", color2="#5fc9a0", color10="#9ee6c4",
                 color3="#e2bd6b", color11="#f1d494", color4="#8fb3d1", color12="#b5cfe5", color5="#f0a3b8", color13="#f7c3d1",
                 color6="#6fd3c6", color14="#a3ece3", color7="#cddbd4", color15="#eef3ec")
    # ---------- text console (TTY): the same 16 colours as the kernel's VT palette ----------
    # gen-boot.py puts this on each live boot entry; the hook puts Samurai's on the installed GRUB line.
    vt = [p['base']] + [k[f"color{i}"] for i in range(1, 7)] + [p['text']] + [k[f"color{i}"] for i in range(8, 16)]
    ch = lambda o: ",".join(str(int(hx(c)[o:o+2], 16)) for c in vt)
    W(f"themes/{name}/console.vt", f"vt.default_red={ch(0)} vt.default_grn={ch(2)} vt.default_blu={ch(4)}\n")
    W(f"{H}/.config/kitty/theme.conf", "# generated by scripts/gen-themes.py\n" + "\n".join([
        f"background {p['base']}", f"foreground {p['text']}", f"cursor {p['accent']}", f"cursor_text_color {p['base']}",
        f"selection_background {p['overlay']}", f"selection_foreground {p['text']}", f"url_color {p['accent2']}",
        f"active_border_color {p['accent']}", f"inactive_border_color {p['overlay']}",
        f"active_tab_background {p['accent']}", f"active_tab_foreground {p['base']}",
        f"inactive_tab_background {p['surface']}", f"inactive_tab_foreground {p['subtext']}", f"tab_bar_background {p['mantle']}",
        f"mark1_background {p['accent2']}"] + [f"{a} {b}" for a, b in k.items()]) + "\n")
    # ---------- waybar ----------
    disp = T["font_display"]
    W(f"{H}/.config/waybar/theme.jsonc", json.dumps({
        "hyprland/workspaces": {"format": "{icon}", "on-click": "activate", "sort-by-number": True,
                                "persistent-workspaces": {"*": 5},
                                "format-icons": {"active": T["ws_icons"]["active"], "default": T["ws_icons"]["default"], "empty": T["ws_icons"]["empty"]}},
        "custom/crest": {"format": "{}", "exec": f"echo '<span font=\"{T['font_brand']} 15\" letter_spacing=\"2048\">{T['display'].upper()}</span>'", "interval": "once",
                          "tooltip": True, "tooltip-format": T["tagline"], "on-click": "tenka-launcher", "on-click-right": "tenka-theme-menu"},
    }, indent=2, ensure_ascii=False) + "\n")
    glow = "none"   # standing rule: no neon, no glow
    W(f"{H}/.config/waybar/style.css", textwrap.dedent(f"""\
    /* {T['display']} waybar, generated by scripts/gen-themes.py */
    @define-color base {p['base']};
    @define-color surface {p['surface']};
    @define-color overlay {p['overlay']};
    @define-color text {p['text']};
    @define-color subtext {p['subtext']};
    @define-color accent {p['accent']};
    @define-color accent2 {p['accent2']};
    @define-color alt {p['alt']};

    * {{ font-family: "Inter", "Symbols Nerd Font"; font-size: 13px; font-weight: 500; min-height: 0; border: none; }}
    window#waybar {{ background: transparent; color: @text; }}
    tooltip {{ background: {rgba(p['base'], 0.92)}; border: 1px solid {rgba(p['accent2'], 0.45)}; border-radius: {T['rounding']}px; }}
    tooltip label {{ color: @text; padding: 4px 6px; }}

    .modules-left, .modules-center, .modules-right {{
      background: {rgba(p['base'], 0.62)};
      border: 1px solid {rgba(p['accent2'], 0.22)};
      border-radius: {T['rounding'] + 4}px;
      padding: 3px 8px;
      margin: 0 2px;
      box-shadow: inset 0 1px {rgba(p['text'], 0.06)};
    }}
    #custom-crest {{ color: @text; padding: 0 12px 0 8px; margin-right: 4px;
      border-right: 1px solid {rgba(p['accent2'], 0.30)}; }}
    #workspaces button {{ color: @subtext; padding: 0 7px; margin: 3px 1px; border-radius: 0; font-size: 14px;
      transition: all 220ms cubic-bezier(0.22, 1, 0.36, 1); background: transparent; box-shadow: none; }}
    #workspaces button.empty {{ color: {rgba(p['subtext'], 0.45)}; }}
    /* the current workspace: accent words on a 1px accent rule, the ledger's mark. No pill, no gradient. */
    #workspaces button.active {{ color: @accent; text-shadow: {glow}; background: transparent;
      box-shadow: inset 0 -1px 0 {p['accent']}; }}
    #workspaces button:hover {{ color: @text; background: {rgba(p['text'], 0.08)}; box-shadow: none; }}
    #window {{ color: @subtext; padding: 0 10px; font-style: italic; }}
    #custom-clock {{ font-family: "{disp}"; font-size: 16px; color: @text; padding: 0 12px; }}
    #custom-clock.hour {{ color: @accent2; }}
    #tray, #network, #pulseaudio, #battery, #cpu, #memory, #custom-notify {{ padding: 0 9px; color: @text; }}
    #network.disconnected, #pulseaudio.muted {{ color: {rgba(p['subtext'], 0.6)}; }}
    #pulseaudio {{ color: @accent2; }}
    #network {{ color: @alt; }}
    #battery.warning {{ color: @accent; }}
    #custom-power {{ color: @accent; padding: 0 10px 0 12px; margin-left: 4px; font-size: 15px;
      border-left: 1px solid {rgba(p['accent2'], 0.30)}; }}
    #custom-power:hover {{ text-shadow: {glow}; }}
    #tray > .needs-attention {{ color: @accent; }}
    """))
    # ---------- swayosd (the fallback OSD when wpctl is missing, and its caps-lock card): our flat card ----------
    W(f"{H}/.config/swayosd/style.css", textwrap.dedent(f"""\
    /* generated by scripts/gen-themes.py: swayosd in the house style, a flat ink card with a hairline gold bar, no glow */
    window#osd {{ border-radius: {T['rounding'] + 4}px; border: 1px solid {rgba(p['accent2'], 0.40)}; background: {rgba(p['base'], 0.95)}; box-shadow: none; }}
    window#osd #container {{ margin: 18px 22px; }}
    window#osd image, window#osd label {{ color: {p['text']}; font-family: "Marcellus", serif; font-size: 15px; }}
    window#osd image:disabled, window#osd progressbar:disabled {{ opacity: 0.45; }}
    window#osd progressbar {{ min-height: 2px; border-radius: 0; border: none; background: transparent; }}
    window#osd trough {{ min-height: 2px; border-radius: 0; border: none; background: {rgba(p['text'], 0.16)}; }}
    window#osd progress {{ min-height: 2px; border-radius: 0; border: none; background: {p['accent2']}; }}
    """))
    # ---------- wofi (installed as a plain picker for scripts; the desk's own launcher is the shell's) ----------
    W(f"{H}/.config/wofi/style.css", textwrap.dedent(f"""\
    /* generated by scripts/gen-themes.py: wofi as a ruled ledger list, no glow */
    window {{ background-color: {rgba(p['base'], 0.95)}; border: 1px solid {rgba(p['accent2'], 0.40)}; border-radius: {T['rounding']}px; font-family: "Inter", sans-serif; font-size: 14px; }}
    #outer-box {{ margin: 18px; }}
    #input {{ background: transparent; color: {p['text']}; border: none; border-bottom: 1px solid {rgba(p['accent2'], 0.45)}; border-radius: 0; padding: 8px 4px; margin-bottom: 10px; box-shadow: none; caret-color: {p['accent']}; }}
    #input:focus {{ border-bottom-color: {p['accent']}; box-shadow: none; }}
    #inner-box {{ background: transparent; }}
    #entry {{ padding: 7px 10px; border-radius: 0; border-left: 1px solid transparent; }}
    #entry #text {{ color: {rgba(p['text'], 0.78)}; }}
    #entry:selected {{ background-color: {rgba(p['text'], 0.06)}; border-left: 1px solid {p['accent']}; outline: none; }}
    #entry:selected #text {{ color: {p['text']}; }}
    #text, #text:selected, #entry:selected #text {{ background-color: transparent; }}
    """))
    W(f"{H}/.config/wofi/config", f"# generated by scripts/gen-themes.py\nwidth=560\nlines=8\nprompt={w['launcher_prompt']}\ninsensitive=true\nhide_scroll=true\nno_actions=true\n")
    # ---------- fuzzel ----------
    a8 = lambda c, a: hx(c) + a
    W(f"{H}/.config/fuzzel/fuzzel.ini", textwrap.dedent(f"""\
    # generated by scripts/gen-themes.py
    [main]
    font=Inter:size=13,Symbols Nerd Font:size=13
    prompt="{w['launcher_prompt']}"
    placeholder=Type to search…
    icon-theme={T['icons']}
    icons-enabled=yes
    terminal=kitty -e
    layer=overlay
    width=38
    lines=8
    horizontal-pad=28
    vertical-pad=22
    inner-pad=12
    line-height=30
    letter-spacing=0.2
    image-size-ratio=0.5
    match-counter=yes

    [colors]
    background={a8(p['base'], 'd9')}
    text={a8(p['subtext'], 'ff')}
    prompt={a8(p['accent'], 'ff')}
    placeholder={a8(p['subtext'], '88')}
    input={a8(p['text'], 'ff')}
    match={a8(p['accent2'], 'ff')}
    selection={a8(p['accent'], '33')}
    selection-text={a8(p['text'], 'ff')}
    selection-match={a8(p['accent2'], 'ff')}
    counter={a8(p['subtext'], '88')}
    border={a8(p['accent2'], '66')}

    [border]
    width=1
    radius={T['rounding'] + 8}
    """))
    # ---------- mako ----------
    W(f"{H}/.config/mako/config", textwrap.dedent(f"""\
    # generated by scripts/gen-themes.py
    font=Inter 11
    background-color={p['base']}e6
    text-color={p['text']}
    border-color={p['accent2']}88
    progress-color=over {p['accent']}55
    border-size=1
    border-radius={T['rounding'] + 4}
    padding=14,18
    margin=14
    width=380
    height=160
    icons=1
    max-icon-size=48
    icon-path=/usr/share/icons/{T['icons']}
    default-timeout=6000
    layer=overlay
    anchor=top-right
    format=<span font_desc="{disp} 13" foreground="{p['accent2']}">%s</span>\\n%b
    on-notify=exec tenka-sound notify

    [urgency=critical]
    border-color={p['accent']}
    default-timeout=0

    [mode=do-not-disturb]
    invisible=1
    """))
    # ---------- wlogout ----------
    acts = [("lock", "l", "tenka-lock"), ("logout", "e", "hyprctl dispatch 'hl.dsp.exit()' | grep -qx ok || loginctl terminate-user $USER"),
            ("suspend", "u", "systemctl suspend"), ("hibernate", "h", "systemctl hibernate"),
            ("reboot", "r", "systemctl reboot"), ("shutdown", "s", "systemctl poweroff")]
    W(f"{H}/.config/wlogout/layout", "".join(json.dumps({"label": a, "action": c, "text": w[a], "keybind": k}) + "\n" for a, k, c in acts))
    icon_css = "\n".join(f"#{a} {{ background-image: image(url(\"/usr/share/tenka/themes/{name}/icons/wlogout/{a}.svg\")); }}" for a, _, _ in acts)
    W(f"{H}/.config/wlogout/style.css", textwrap.dedent(f"""\
    /* generated by scripts/gen-themes.py */
    * {{ background-image: none; box-shadow: none; font-family: "{disp}", "Inter"; }}
    window {{ background-color: {rgba(p['mantle'], 0.72)}; }}
    button {{
      color: {p['text']}; font-size: 22px;
      background-color: {rgba(p['surface'], 0.55)};
      border: 1px solid {rgba(p['accent2'], 0.25)};
      border-radius: {T['rounding'] + 10}px;
      margin: 14px; padding-top: 120px;
      background-repeat: no-repeat; background-position: center 38%; background-size: 34%;
      transition: all 260ms cubic-bezier(0.22, 1, 0.36, 1);
    }}
    button:focus, button:active, button:hover {{
      color: {p['accent2']};
      background-color: {rgba(p['overlay'], 0.75)};
      border: 1px solid {rgba(p['accent'], 0.75)};
      background-size: 40%;
    }}
    """) + icon_css + "\n")
    # ---------- fastfetch ----------
    # the ledger: the wordmark and tagline, one gold hairline, numbered small-caps keys, no icons,
    # no colour dots, a closing hairline with a short accent head (the lock screen's rule)
    keys = w["ff_keys"]
    def esc(c): return "\u001b[38;2;" + rgb_t(c).replace(",", ";") + "m"
    RST = "\u001b[0m"
    order = ["os", "kernel", "wm", "shell", "terminal", "theme", "packages", "cpu", "memory", "uptime"]
    kw = max(len(keys[k]) for k in order) + 2
    def mod(t, n, **kw2):
        d = {"type": t, "key": f"{esc(p['subtext'])}{n:02d}{RST}  {esc(p['accent2'])}{keys[t].upper():<{kw}}{RST}"}
        d.update(kw2); return d
    ff = {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {"type": "file", "source": f"/usr/share/tenka/themes/{name}/fastfetch/logo.txt",
                 "color": {"1": "38;2;" + rgb_t(p['accent']).replace(",", ";"), "2": "38;2;" + rgb_t(p['accent2']).replace(",", ";"),
                           "3": "38;2;" + rgb_t(p['text']).replace(",", ";")},
                 "padding": {"top": 1, "left": 2, "right": 5}},
        "display": {"separator": " ", "color": {"keys": "38;2;" + rgb_t(p['accent2']).replace(",", ";"), "output": "38;2;" + rgb_t(p['text']).replace(",", ";")}},
        "modules": [
            "break",
            {"type": "custom", "format": f"{esc(p['text'])}{' '.join(T['display'].upper())}{RST}   {esc(p['subtext'])}{T['tagline'].upper()}{RST}"},
            {"type": "custom", "format": esc(p['accent2']) + "\u2500" * 46 + RST},
            mod("os", 1, format=f"{T['display']} {{version-id}} ({{codename}})"),
            mod("kernel", 2, format="Linux {release}"),
            mod("wm", 3),
            mod("shell", 4),
            mod("terminal", 5),
            mod("theme", 6),
            mod("packages", 7),
            mod("cpu", 8, format="{name}{?cores-logical} \u00b7 {cores-logical} threads{?}"),
            mod("memory", 9, format="{used} of {total}"),
            mod("uptime", 10),
            {"type": "custom", "key": " ", "format": esc(p['accent']) + "\u2501" * 6 + esc(p['accent2']) + "\u2500" * 40 + RST},
        ],
    }
    ffk = dict(ff)
    # fastfetch's terminal module asks kitty for its version (XTGETTCAP); the answer can land after it
    # exits and spill into the prompt, so in kitty the brush line is plain text
    ffk["modules"] = [m if not isinstance(m, dict) or m.get("type") != "terminal" else {"type": "custom", "format": "kitty", "key": m["key"]}
                      for m in ff["modules"]]
    ffk["logo"] = {"type": "kitty-direct", "source": f"/usr/share/tenka/themes/{name}/fastfetch/crest.png",
                                     "width": 22, "height": 11, "padding": {"top": 1, "left": 3, "right": 4}}
    W(f"{H}/.config/fastfetch/kitty.jsonc", json.dumps(ffk, indent=2, ensure_ascii=False) + "\n")
    W(f"{H}/.config/fastfetch/config.jsonc", json.dumps(ff, indent=2, ensure_ascii=False) + "\n")
    # ---------- GTK ----------
    # Rice V washi glass, frosted (root review: lighter, so the wallpaper's colour reads through; not smoked plastic):
    # a thin ink tint for legibility under a milky frost, a lit top edge, a darker side pane than the content
    sam_ = name == "samurai"
    R, Rs = T["rounding"], max(4, T["rounding"] - 4)
    tint = p['base'] if sam_ else mix(p['base'], p['surface'], 0.5)
    gl_top = rgba(tint, 0.24)
    gl_bot = rgba(tint, 0.38)
    gl_frost = rgba(p['text'], 0.07)
    gl_win = rgba(tint, 0.42)
    gl_view = rgba(p['mantle'], 0.22)
    gl_side = rgba(p['mantle'], 0.30)
    gl_head = rgba(p['text'], 0.05)
    gl_lit = rgba(p['text'], 0.14)
    gl_sel = rgba(p['accent'], 0.34)
    gl_pop = rgba(p['surface'], 0.92)
    gl_menu = rgba(p['surface'], 0.80)  # T21 A2: menus/popovers are glass over Hyprland's popup blur (Lite keeps them dense)
    gl_tip = rgba(p['surface'], 0.84)
    # every glass window and dialog except Files (its own rules), the panel and Lite's menu/notification windows
    GW = "window.background:not(.xfce4-panel):not(.thunar):not(#whiskermenu-window):not(#XfceNotifyWindow)"
    GB = "button:not(.link):not(.flat):not(.suggested-action):not(.destructive-action)"  # a plain push button (links, flat tool buttons and the accent buttons keep their own look)
    def GS(*sels): return ", ".join(f"{GW} {s}, dialog.background {s}" for s in sels)
    gtkcss = textwrap.dedent(f"""\
    /* generated by scripts/gen-themes.py: {T['display']} accents */
    @define-color accent_color {p['accent_l']};
    @define-color accent_bg_color {p['accent']};
    @define-color accent_fg_color {p['base']};
    @define-color window_bg_color {p['base']};
    @define-color window_fg_color {p['text']};
    @define-color view_bg_color {p['mantle']};
    @define-color view_fg_color {p['text']};
    @define-color headerbar_bg_color {p['surface']};
    @define-color headerbar_fg_color {p['text']};
    @define-color sidebar_bg_color {p['surface']};
    @define-color card_bg_color {p['surface']};
    @define-color popover_bg_color {p['surface']};
    @define-color dialog_bg_color {p['surface']};
    @define-color theme_selected_bg_color {p['accent']};
    @define-color theme_bg_color {p['base']};
    @define-color theme_base_color {p['mantle']};
    @define-color theme_fg_color {p['text']};
    """)
    # GTK 4 (the volume mixer and other GTK 4 tools fall back to GTK's own theme): the same washi glass, drawn explicitly
    W(f"{H}/.config/gtk-4.0/gtk.css", gtkcss + textwrap.dedent(f"""\
    /* ---- Rice V washi glass for GTK 4: see-through windows over Hyprland's blur, glass headerbars, rounded glass
       popovers, the theme's corners on buttons and fields, thin quiet sliders. No glow. ---- */
    window, window.background {{ background-color: {gl_win}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 40%); box-shadow: inset 0 1px {gl_lit}; color: {p['text']}; }}
    headerbar {{ background-color: {gl_head}; background-image: none; box-shadow: none; border-bottom: 1px solid {rgba(p['accent2'], 0.18)}; color: {p['text']}; min-height: 42px; }}
    headerbar .title, windowtitle .title {{ font-family: Marcellus; font-size: 14px; letter-spacing: 0.5px; }}
    /* a plain GTK 4 toolbar strip (File Roller's location row) drew the light default; it sits on the glass */
    .toolbar {{ background-color: transparent; background-image: none; }}
    .view, textview text, listview, columnview, gridview, list, scrolledwindow, viewport, stack, notebook, notebook > stack {{ background-color: transparent; color: {p['text']}; }}
    textview text {{ background-color: {gl_view}; }}
    list > row:selected, listview > row:selected, columnview > listview > row:selected, .navigation-sidebar > row:selected {{ background-color: {gl_sel}; color: {p['text']}; }}
    list > row:hover, listview > row:hover {{ background-color: {rgba(p['text'], 0.05)}; }}
    popover > contents, popover.menu > contents {{ background-color: {gl_pop}; border: 1px solid {rgba(p['accent2'], 0.22)}; border-radius: {R}px; box-shadow: 0 10px 30px {rgba('#000000', 0.45)}; }}
    popover > arrow {{ background-color: {gl_pop}; border: 1px solid {rgba(p['accent2'], 0.22)}; }}
    tooltip, tooltip.background {{ background-color: {gl_pop}; border: 1px solid {rgba(p['accent2'], 0.25)}; border-radius: {Rs}px; color: {p['text']}; }}
    button {{ border-radius: {Rs}px; background-color: {rgba(p['text'], 0.07)}; background-image: none; border: 1px solid {rgba(p['text'], 0.08)}; box-shadow: none; color: {p['text']}; }}
    button:hover {{ background-color: {rgba(p['text'], 0.12)}; }}
    button:checked, button.suggested-action {{ background-color: {rgba(p['accent2'], 0.22)}; border-color: {rgba(p['accent2'], 0.45)}; color: {p['text']}; }}
    button.flat, headerbar button {{ background-color: transparent; border-color: transparent; }}
    button.flat:hover, headerbar button:hover {{ background-color: {rgba(p['text'], 0.08)}; }}
    entry, spinbutton, dropdown > button, combobox > box > button {{ background-color: {rgba(p['mantle'], 0.45)}; border: 1px solid {rgba(p['text'], 0.10)}; border-radius: {Rs}px; box-shadow: none; color: {p['text']}; }}
    entry:focus-within, spinbutton:focus-within {{ border-color: {rgba(p['accent2'], 0.55)}; outline: none; }}
    scale trough {{ background-color: {rgba(p['text'], 0.12)}; min-height: 4px; min-width: 4px; border-radius: 99px; border: none; }}
    scale highlight {{ background-image: linear-gradient(to right, {p['accent2']}, {p['accent']}); background-color: {p['accent2']}; border-radius: 99px; border: none; }}
    scale slider {{ background-color: {p['text']}; border: none; border-radius: 99px; min-width: 14px; min-height: 14px; box-shadow: 0 1px 3px {rgba('#000000', 0.45)}; }}
    levelbar trough {{ background-color: {rgba(p['text'], 0.08)}; border-radius: 99px; border: none; }}
    levelbar block.filled, levelbar block.high, levelbar block.low {{ background-color: {p['accent2']}; border-radius: 99px; }}
    checkbutton check:checked, radiobutton radio:checked, check:checked, radio:checked {{ background-color: {p['accent']}; border-color: {p['accent']}; color: {p['base']}; }}
    /* T22: GTK 4 paints checks, radios and knobs with a background-image, which beat the colours above, so the stock blue showed through; text selection and links were stock too */
    checkbutton check:checked, checkbutton radio:checked, check:checked, radio:checked, switch slider, scale slider {{ background-image: none; }}
    text > selection, text > selection:focus-within, entry > text > selection, textview > text > selection {{ background-color: {gl_sel}; color: {p['text']}; }}
    link, link:link, button.link, button.link > label {{ color: {p['accent2']}; }}
    /* T22: GTK 4 measures an ellipsizing label without its letter-spacing, so every window title was cut short ("Widgets" drew as "Widge…"); no tracking on GTK 4 titles */
    headerbar .title, windowtitle .title {{ letter-spacing: 0; }}
    /* T22: one control language across GTK 3 and GTK 4: checks and radios in gold with ink marks, as GTK 3 already drew them */
    checkbutton check:checked, checkbutton radio:checked, check:checked, radio:checked {{ background-color: {p['accent2']}; border-color: {p['accent2']}; color: {p['base']}; }}
    switch {{ background-color: {rgba(p['text'], 0.14)}; border: none; border-radius: 99px; }}
    switch:checked {{ background-color: {p['accent']}; }}
    /* T23: one knob across GTK 3 and GTK 4: GTK 4 drew the switch and slider knobs in cream while GTK 3 drew them gold; now a quiet ivory knob when off and gold when on, slider knobs gold */
    switch slider {{ background-color: {rgba(p['text'], 0.55)}; border-radius: 99px; box-shadow: none; }}
    switch:checked slider {{ background-color: {p['accent2']}; }}
    scale slider {{ background-color: {p['accent2']}; }}
    notebook > header {{ background-color: transparent; border: none; box-shadow: none; }}
    notebook > header tab {{ padding: 7px 16px; color: {rgba(p['text'], 0.62)}; font-family: Marcellus; }}
    notebook > header tab:checked {{ color: {p['text']}; box-shadow: inset 0 -1px {p['accent2']}; }}
    separator {{ background-color: {rgba(p['accent2'], 0.16)}; }}
    scrollbar slider {{ background-color: {rgba(p['accent2'], 0.35)}; border-radius: 99px; min-width: 3px; min-height: 3px; border: none; }}
    /* About and message dialogs: one clear sheet, the program name in Cinzel Decorative, links and selection in gold
       (not GTK's blue), and the answers in a dialog's button row read as gold on the glass. */
    window.aboutdialog headerbar, window.dialog headerbar {{ background-color: transparent; background-image: none; border-color: transparent; box-shadow: none; }}
    window.aboutdialog box > label {{ color: {p['text']}; }}
    window.aboutdialog image + label {{ font-family: "Cinzel Decorative"; font-size: 20px; letter-spacing: 1px; color: {p['text']}; }}
    label > link, label > link:link {{ color: {p['accent2']}; }}
    label > link:visited {{ color: {rgba(p['accent2'], 0.75)}; }}
    label > selection {{ background-color: {rgba(p['accent2'], 0.28)}; color: {p['text']}; }}
    window.dialog .dialog-action-area > button {{ background-color: {rgba(p['accent2'], 0.10)}; border-color: {rgba(p['accent2'], 0.30)}; color: {p['accent2']}; font-family: Marcellus; }}
    window.dialog .dialog-action-area > button:hover {{ background-color: {rgba(p['accent2'], 0.18)}; }}
    window.dialog .dialog-action-area > button.suggested-action {{ background-color: {rgba(p['accent2'], 0.24)}; border-color: {rgba(p['accent2'], 0.50)}; color: {p['text']}; }}
    window.dialog.message box > label {{ color: {p['text']}; }}
    /* GTK 4 file chooser: the places sidebar was a solid grey slab and the column headers a second one. Both glass now,
       headers in Marcellus over a gold hairline, a softer selection, and "Open" in the title bar reads as the gold answer. */
    placessidebar {{ background-color: {gl_side}; color: {p['text']}; }}
    placessidebar *:not(row):not(button), filechooser .sidebar, filechooser .sidebar *:not(row):not(button), filechooser paned > :first-child {{ background-color: transparent; background-image: none; }}
    placessidebar row:selected, .navigation-sidebar > row:selected {{ background-color: {rgba(p['accent2'], 0.18)}; color: {p['text']}; }}
    columnview > header > button {{ background-color: transparent; background-image: none; border: none; border-radius: 0; border-bottom: 1px solid {rgba(p['accent2'], 0.20)}; box-shadow: none; color: {p['subtext']}; font-family: Marcellus; }}
    columnview, columnview > listview, gridview {{ background-color: transparent; }}
    headerbar button.suggested-action, .dialog-action-area > button.suggested-action {{ background-color: {rgba(p['accent2'], 0.22)}; border-color: {rgba(p['accent2'], 0.45)}; color: {p['text']}; }}
    /* T23: the path is a row of folder names, and Marcellus draws 0 like O and 1 like l; set it in Inter, as in GTK 3 and Thunar */
    pathbar > button, .path-bar > button, pathbar > button label {{ font-family: Inter; letter-spacing: 0; }}
    progressbar trough {{ min-height: 4px; background-color: {rgba(p['text'], 0.10)}; border: none; border-radius: 99px; box-shadow: none; }}
    progressbar progress {{ min-height: 4px; background-color: {p['accent2']}; background-image: none; border: none; border-radius: 99px; box-shadow: none; }}
    /* T20: the answer button (Open, Save, Select) is the one solid gold mark on the glass, ink on gold. */
    button.suggested-action, headerbar button.suggested-action, .dialog-action-area > button.suggested-action {{ background-color: {rgba(p['accent2'], 0.88)}; background-image: none; border: 1px solid {p['accent2']}; color: {p['mantle']}; font-weight: 600; box-shadow: none; text-shadow: none; }}
    button.suggested-action label {{ color: {p['mantle']}; text-shadow: none; }}
    button.suggested-action:hover {{ background-color: {p['accent2']}; }}
    button.suggested-action:disabled, button.suggested-action:disabled label {{ background-color: {rgba(p['accent2'], 0.30)}; color: {rgba(p['mantle'], 0.75)}; }}
    paned > separator, paned.wide > separator {{ background-color: transparent; background-image: none; border: none; box-shadow: none; }}
    placessidebar, .sidebar-pane {{ border-right: 1px solid {rgba(p['accent2'], 0.28)}; }}
    /* T21: the About dialog opens with the program name focused and GTK selects a focused selectable label; the name is
       a title, not a selection, so it opens clear: no highlight, no focus ring, the ink stays. */
    window.aboutdialog image + label > selection, window.aboutdialog image + label:focus > selection {{ background-color: transparent; color: {p['text']}; }}
    window.aboutdialog image + label:focus, window.aboutdialog image + label:focus-visible {{ outline: none; box-shadow: none; }}
    /* T21 A2: menus, popovers and tooltips are small sheets of glass over Hyprland's popup blur (blur.popups = true),
       edged with one gold hairline. Ink text, no glow. */
    popover > contents, popover.menu > contents {{ background-color: {gl_menu}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 45%); border: 1px solid {rgba(p['accent2'], 0.34)}; box-shadow: inset 0 1px {gl_lit}, 0 12px 30px {rgba('#000000', 0.40)}; }}
    popover > arrow {{ background-color: {gl_menu}; border: 1px solid {rgba(p['accent2'], 0.34)}; }}
    popover.menu modelbutton:hover, popover.menu modelbutton:selected, popover.menu row:hover {{ background-color: {rgba(p['accent2'], 0.16)}; color: {p['text']}; }}
    popover separator {{ background-color: {rgba(p['accent2'], 0.18)}; }}
    tooltip, tooltip.background {{ background-color: {gl_tip}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 60%); border: 1px solid {rgba(p['accent2'], 0.34)}; box-shadow: inset 0 1px {gl_lit}; }}
    """))
    # Tenka Lite (xfwm4: no blur) writes ~/.cache/tenka/session.css at login with denser glass; Hyprland removes it.
    # GTK skips a missing import with a warning.
    W(f"{H}/.config/gtk-3.0/gtk.css", '@import url("../../.cache/tenka/session.css");\n' + gtkcss + textwrap.dedent(f"""\
    /* ---- Rice V, "washi glass" (Naman, Oct 12: "no solid let them be see through, but at least make it better"):
       every window is one sheet of tinted glass over the art. Hyprland blurs what is behind it (more passes, a
       little grain), the sheet darkens toward the bottom so text always sits on enough ink, and type carries a
       soft drop shadow so it reads over any wallpaper. One tint per window, no patchwork of panes. No glow. ---- */
    /* GtkDialog windows are `dialog` nodes, not `window` (the settings manager, properties and file dialogs): the same glass */
    window.background:not(.xfce4-panel):not(.thunar), dialog.background {{ background-color: {gl_win}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 40%); box-shadow: inset 0 1px {gl_lit}; color: {p['text']}; }}
    /* message dialogs ("Replace this file?", "Delete permanently?") are `messagedialog` nodes, which neither rule above
       reaches, so the base theme painted them a near-solid 98% slab. Same glass now; the answers keep their gold, the message takes the page's ink. */
    messagedialog.background {{ background-color: {gl_win}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 40%); box-shadow: inset 0 1px {gl_lit}; color: {p['text']}; }}
    messagedialog.background box > label {{ color: {p['text']}; }}
    /* T23: the explanation under the question was set in Marcellus, whose 0 reads as O ("Travel 2O26"); the question keeps Marcellus, the explanation reads in Inter */
    messagedialog.background box > label {{ font-family: Inter; letter-spacing: 0; }}
    messagedialog.background box > label:first-child {{ font-family: Marcellus; letter-spacing: 0.3px; }}
    /* About dialogs: the title strip goes clear so the sheet is one pane, the program name is set in Cinzel Decorative,
       links and selected text take the gold instead of the stock blue. GTK 3's About carries no style class of its own;
       its logo is the one `image.icon-dropshadow`, and the name label sits right after it. */
    dialog.background > headerbar.titlebar, dialog.background > .titlebar {{ background-color: transparent; background-image: none; border-color: transparent; box-shadow: none; }}
    dialog.background > box > box > image.icon-dropshadow + label {{ font-family: "Cinzel Decorative"; font-size: 20px; letter-spacing: 1px; color: {p['text']}; }}
    /* T22: the version line in Inter, so its figures read as figures (Marcellus set 0.1.0 as "O.I.O") */
    dialog.background > box > box > stack > box > label:first-child {{ font-family: "Inter"; font-size: 12px; letter-spacing: 1px; color: {rgba(p['text'], 0.66)}; }}
    /* T22: GTK 3 sliders had no rule and kept the stock blue knob, and a list box was a near-solid grey slab */
    scale slider {{ background-color: {p['accent2']}; background-image: none; border: none; border-radius: 99px; min-width: 14px; min-height: 14px; margin: -5px; box-shadow: none; }}
    /* T23: the off knob was a dark disc on a dark track; a quiet ivory knob off, gold on, as in GTK 4 */
    switch slider {{ background-color: {rgba(p['text'], 0.55)}; background-image: none; box-shadow: none; }}
    switch:checked slider {{ background-color: {p['accent2']}; }}
    list {{ background-color: {gl_view}; }}
    dialog.background *:link, dialog.background label > link:link {{ color: {p['accent2']}; }}
    dialog.background *:visited, dialog.background label > link:visited {{ color: {rgba(p['accent2'], 0.75)}; }}
    dialog.background label > selection {{ background-color: {rgba(p['accent2'], 0.28)}; color: {p['text']}; }}
    dialog.background > headerbar stackswitcher button {{ font-family: Marcellus; }}
    /* the answer rows of GTK 3 dialogs (Close and Help in file properties, OK/Cancel in settings): gold on the glass, as in GTK 4 */
    dialog.background buttonbox > button:not(.link):not(.flat):not(.suggested-action):not(.destructive-action) {{ background-color: {rgba(p['accent2'], 0.10)}; border-color: {rgba(p['accent2'], 0.30)}; color: {p['accent2']}; font-family: Marcellus; }}
    dialog.background buttonbox > button:not(.link):not(.flat):not(.suggested-action):not(.destructive-action):hover {{ background-color: {rgba(p['accent2'], 0.18)}; border-color: {rgba(p['accent2'], 0.42)}; }}
    /* progress (Thunar's copy/move/delete window and every other GTK 3 bar): a thin glass trough with a gold line, not a grey slab */
    progressbar trough {{ min-height: 4px; background-color: {rgba(p['text'], 0.10)}; background-image: none; border: none; border-radius: 99px; box-shadow: none; }}
    progressbar progress {{ min-height: 4px; background-color: {p['accent2']}; background-image: none; border: none; border-radius: 99px; box-shadow: none; }}
    window.background:not(.xfce4-panel):not(.thunar) textview text, dialog.background textview text, window.background:not(.xfce4-panel):not(.thunar) .view:not(iconview), dialog.background .view:not(iconview) {{ background-color: {gl_view}; }}
    .sidebar {{ background-color: {gl_side}; color: {p['text']}; }}
    headerbar, .titlebar {{ background-color: {gl_head}; background-image: none; color: {p['text']}; box-shadow: none; border-bottom: 1px solid {rgba(p['accent2'], 0.18)}; }}
    selection {{ background-color: {gl_sel}; color: {p['text']}; }}
    menu, .menu, .context-menu, popover.background > contents, popover > contents {{ background-color: {gl_pop}; border: 1px solid {rgba(p['accent2'], 0.22)}; border-radius: {R}px; padding: 6px; }}
    menu menuitem, .menu menuitem, .context-menu menuitem {{ padding: 7px 14px; border-radius: {Rs}px; min-height: 18px; }}
    menu menuitem:hover, .menu menuitem:hover, .context-menu menuitem:hover {{ background-color: {rgba(p['accent2'], 0.16)}; color: {p['text']}; }}
    menu separator, .menu separator {{ background-color: {rgba(p['accent2'], 0.18)}; margin: 5px 10px; min-height: 1px; }}
    tooltip, tooltip.background {{ background-color: {gl_pop}; border: 1px solid {rgba(p['accent2'], 0.25)}; border-radius: {Rs}px; }}
    /* tooltips speak in the UI face too. This has to live here: GTK applies the xsettings font above the theme,
       so a tooltip rule in the theme's gtk.css loses; the user sheet sits above both. */
    /* T23: tooltips carry numbers (sizes, times, percentages) and Marcellus draws 0 like O, so they speak Inter, as GTK 4's already do */
    tooltip label {{ font-family: Inter; font-size: 12px; letter-spacing: 0; }}
    /* the Lite dock's window list (its own sheet, class .menu) speaks Marcellus too */
    .menu label {{ font-family: Marcellus; }}
    button {{ border-radius: {Rs}px; }}
    entry {{ border-radius: {Rs}px; background-color: {rgba(p['mantle'], 0.45)}; border: 1px solid {rgba(p['text'], 0.10)}; box-shadow: none; caret-color: {p['accent2']}; }}
    entry:focus {{ border-color: {rgba(p['accent2'], 0.55)}; }}
    window.background:not(.xfce4-panel):not(.thunar) iconview, dialog.background iconview, window.background:not(.xfce4-panel):not(.thunar) iconview.view, dialog.background iconview.view,
    window.background:not(.xfce4-panel):not(.thunar) scrolledwindow, dialog.background scrolledwindow, window.background:not(.xfce4-panel):not(.thunar) viewport, dialog.background viewport,
    window.background:not(.xfce4-panel):not(.thunar) .background, dialog.background .background {{ background-color: transparent; }}
    /* ExoIconView (the Settings Manager, App Finder) is a plain `widget.view` node, and exo paints every label's cell with the
       view ink too: stacked over the content ink that made dark bands under each category and a dark box behind every name.
       The icons sit straight on the one sheet; only hover and selection draw, as a quiet wash. */
    window.background:not(.xfce4-panel):not(.thunar) widget.view:not(treeview), dialog.background widget.view:not(treeview) {{ background-color: transparent; }}
    window.background:not(.xfce4-panel):not(.thunar) widget.view.cell:hover, dialog.background widget.view.cell:hover {{ background-color: {rgba(p['text'], 0.07)}; border-radius: {Rs}px; }}
    window.background:not(.xfce4-panel):not(.thunar) widget.view.cell:selected, dialog.background widget.view.cell:selected {{ background-color: {gl_sel}; color: {p['text']}; border-radius: {Rs}px; }}
    /* ---- T14 window polish: the base theme still paints a few solid ink strips inside the glass (the column
       headers of every list, the settings dialogs' heading, the file chooser's places list). They become part of
       the one sheet: a quiet frosted header band with a hairline under it, column names in spaced small words,
       the side pane set off by a single hairline, buttons as frosted keys, section titles in the UI face. ---- */
    {GS('.XfceHeading')} {{ background-color: {rgba(p['text'], 0.05)}; background-image: linear-gradient(to bottom, {rgba(p['text'], 0.07)}, transparent); box-shadow: inset 0 -1px {rgba(p['accent2'], 0.20)}; padding: 12px 18px; font-family: Marcellus; letter-spacing: 0.4px; color: {p['text']}; }}
    {GS('treeview.view header ' + GB, 'treeview.view header ' + GB + ':hover', 'treeview.view header ' + GB + ':active', 'treeview.view header ' + GB + ':disabled')} {{ background-color: transparent; background-image: none; border-style: none none solid none; border-width: 1px; border-color: {rgba(p['accent2'], 0.20)}; box-shadow: none; padding: 6px 10px; font-size: 11px; letter-spacing: 1.1px; }}
    {GS('treeview.view header ' + GB + ':not(:hover)')} {{ color: {rgba(p['subtext'], 0.9)}; }}
    {GS('placessidebar list', 'stacksidebar list', 'frame > border', 'notebook > stack')} {{ background-color: transparent; background-image: none; }}
    {GS('.sidebar')} {{ box-shadow: inset -1px 0 {rgba(p['accent2'], 0.16)}; }}
    {GS('paned > separator')} {{ background-color: {rgba(p['accent2'], 0.20)}; background-image: none; min-width: 1px; min-height: 1px; }}
    {GS('placessidebar row:selected', 'placessidebar row:selected:focus', 'stacksidebar row:selected')} {{ background-color: {rgba(p['accent'], 0.20)}; background-image: none; box-shadow: inset 2px 0 {p['accent']}; color: {p['text']}; }}
    {GS('placessidebar row:hover', 'stacksidebar row:hover', 'list row:hover', 'treeview.view:hover:not(:selected)')} {{ background-color: {rgba(p['text'], 0.05)}; }}
    {GS('list row:selected', 'treeview.view:selected', 'treeview.view:selected:focus')} {{ background-color: {rgba(p['accent'], 0.24)}; background-image: none; color: {p['text']}; }}
    {GS(GB)} {{ background-color: {rgba(p['text'], 0.07)}; background-image: none; border: 1px solid {rgba(p['text'], 0.10)}; box-shadow: inset 0 1px {rgba(p['text'], 0.05)}; color: {p['text']}; text-shadow: none; }}
    {GS(GB + ':hover')} {{ background-color: {rgba(p['text'], 0.12)}; border-color: {rgba(p['text'], 0.16)}; }}
    {GS(GB + ':active', GB + ':checked')} {{ background-color: {rgba(p['accent2'], 0.20)}; border-color: {rgba(p['accent2'], 0.40)}; }}
    {GS(GB + ':disabled')} {{ background-color: {rgba(p['text'], 0.03)}; border-color: {rgba(p['text'], 0.05)}; color: {rgba(p['text'], 0.38)}; }}
    /* T15: the inline toolbar under a list (Settings Editor's Add/Edit/Reset, Appearance's theme list) was the base theme's solid
       ink strip; it joins the sheet with one hairline above it. */
    {GS('toolbar.inline-toolbar', '.inline-toolbar', 'toolbar.inline-toolbar:backdrop', '.inline-toolbar:backdrop')} {{ background-color: transparent; background-image: none; border-style: solid none none none; border-width: 1px; border-color: {rgba(p['accent2'], 0.16)}; box-shadow: none; }}
    {GS('frame > label', 'frame > box > label')} {{ font-family: Marcellus; letter-spacing: 0.6px; color: {rgba(p['accent2'], 0.92)}; }}
    /* T23: a status bar's text sits in frame > box > label too, so the rule above set Ristretto's "3840 x 2160  1.5 MB  20.8%" as a gold Marcellus heading
       (0 read as O); status lines and the file chooser's path read in quiet Inter instead, like Thunar's */
    {GS('statusbar frame > box > label', 'statusbar frame > box > box > label', 'statusbar frame > label', 'statusbar label')} {{ font-family: Inter; letter-spacing: 0; color: {rgba(p['subtext'], 0.9)}; }}
    {GS('.path-bar button', '.path-bar button label', 'filechooser .path-bar button label')} {{ font-family: Inter; letter-spacing: 0; }}
    menubar {{ background-color: transparent; background-image: none; padding: 2px 8px; border-bottom: 1px solid {rgba(p['accent2'], 0.14)}; box-shadow: none; }}
    menubar > menuitem {{ padding: 6px 12px; border-radius: {Rs}px; font-family: Marcellus; color: {rgba(p['text'], 0.82)}; }}
    menubar > menuitem:hover {{ background-color: {rgba(p['accent2'], 0.14)}; color: {p['text']}; box-shadow: none; }}
    toolbar {{ background-color: transparent; background-image: none; border: none; }}
    notebook, notebook > stack:not(:only-child) {{ background-color: transparent; }}
    notebook > header {{ background-color: transparent; border: none; box-shadow: none; }}
    notebook > header tab {{ padding: 7px 16px; font-family: Marcellus; color: {rgba(p['text'], 0.62)}; border: none; background: transparent; }}
    notebook > header tab:checked {{ color: {p['text']}; box-shadow: inset 0 -1px {p['accent2']}; }}
    /* the text editor: the page is the window's glass (its colour scheme draws no page of its own); the gutter
       sits on the same glass, the numbers in a quieter ink */
    window.mousepad notebook scrolledwindow {{ border-left: 12px solid transparent; }}
    window.mousepad textview.view, window.mousepad textview text {{ background-color: {gl_view}; }}
    window.mousepad textview border {{ background-color: transparent; }}
    /* ---- the file manager: the same washi sheet; a header band with the path as quiet breadcrumbs (the folder
       you are in reads in full ink with a short accent rule under it); the side pane as a list of places on the
       same glass, its section names in spaced small capitals; a roomy grid whose names sit on a soft shadow;
       a tinted lift for the chosen file. ---- */
    window.thunar.background, window.thunar.background:not(.xfce4-panel) {{
        background-color: transparent;
        background-image: linear-gradient(to bottom, {gl_frost}, transparent 40%), linear-gradient(to bottom, {gl_top}, {gl_bot});
        box-shadow: inset 0 1px {gl_lit};
        color: {p['text']}; }}
    .thunar * {{ font-family: Marcellus; }}
    /* T23: Marcellus draws 0 like O and 1 like l, so names and numbers misread ("invoice-O412.pdf", "Travel 2O26", "2O GiB free").
       File names, sizes, the path and the status line are set in Inter; the places list keeps Marcellus. */
    .thunar .standard-view, .thunar .standard-view *, .thunar .path-bar button, .thunar .path-bar button *, .thunar .path-bar-button, .thunar .path-bar-button *, .thunar .location-button, .thunar .location-button *, .thunar statusbar, .thunar statusbar *, .thunar entry {{ font-family: Inter; letter-spacing: 0; }}
    .thunar iconview, .thunar iconview.view, .thunar .view, .thunar treeview.view, .thunar scrolledwindow, .thunar viewport,
    .thunar notebook, .thunar notebook > stack, .thunar notebook > header {{ background-color: transparent; background-image: none; border: none; box-shadow: none; color: {p['text']}; }}
    .thunar iconview {{ padding: 26px 22px; }}
    .thunar iconview.view {{ font-size: 13px; text-shadow: 0 1px 3px {rgba('#000000', 0.7)}; }}
    .thunar iconview:selected, .thunar .view:selected:not(treeview) {{ background-color: {gl_sel}; color: {p['text']}; border-radius: {R}px; }}
    .thunar treeview.view:selected:not(.sidebar) {{ background-color: {rgba(p['accent2'], 0.18)}; color: {p['text']}; }}
    .thunar treeview.view header button {{ background: transparent; border: none; border-bottom: 1px solid {rgba(p['accent2'], 0.20)}; color: {rgba(p['subtext'], 0.9)}; font-size: 11px; letter-spacing: 1.2px; padding: 6px 10px; }}
    .thunar .sidebar *, .thunar .shortcuts-pane * {{ background-color: transparent; }}
    /* T22: the pane and the tree both took gl_side, so the sidebar stacked two dark sheets (46% of the wallpaper through vs 66% in the file view). One sheet, lighter. */
    .thunar .sidebar {{ background-color: transparent; }}
    .thunar .shortcuts-pane {{ background-color: {rgba(p['mantle'], 0.16)}; }}
    .thunar .sidebar treeview.view {{ padding: 7px 12px; color: {rgba(p['text'], 0.82)}; font-size: 13px; text-shadow: 0 1px 2px {rgba('#000000', 0.6)}; }}
    /* the chosen place: a quiet accent wash with a 2 px accent rule at its left edge, like a ledger's margin mark */
    .thunar .sidebar treeview.view:selected, .thunar .sidebar treeview.view:selected:focus {{ background-color: {rgba(p['accent'], 0.20)}; background-image: none; box-shadow: inset 2px 0 {p['accent']}; color: {p['text']}; border-radius: 0; border: none; }}
    .thunar .sidebar treeview.view:hover {{ background-color: {rgba(p['text'], 0.06)}; border-radius: 0; }}
    .thunar .sidebar treeview.view.expander {{ color: {rgba(p['accent2'], 0.6)}; }}
    .thunar toolbar, .thunar .toolbar {{ background-color: {gl_head}; border-bottom: 1px solid {rgba(p['accent2'], 0.20)}; padding: 9px 14px; }}
    .thunar toolbar button, .thunar button {{ border-radius: {Rs}px; background: transparent; border: none; box-shadow: none; color: {rgba(p['text'], 0.78)}; -gtk-icon-shadow: none; min-width: 30px; min-height: 30px; }}
    .thunar toolbar button:hover, .thunar button:hover {{ background-color: {rgba(p['text'], 0.08)}; color: {p['text']}; }}
    .thunar .path-bar button, .thunar .path-bar-button {{ padding: 4px 11px; margin: 0 1px; color: {rgba(p['text'], 0.66)}; font-size: 13px; letter-spacing: 0.4px; border-radius: {Rs}px; }}
    .thunar .path-bar button:checked, .thunar .path-bar-button:checked {{ color: {p['text']}; background-color: transparent;
        background-image: linear-gradient({p['accent2']}, {p['accent2']}); background-size: 18px 1px; background-position: center bottom; background-repeat: no-repeat; }}
    .thunar entry {{ border-radius: {Rs}px; background-color: {rgba(p['mantle'], 0.40)}; border: 1px solid {rgba(p['accent2'], 0.30)}; color: {p['text']}; padding: 5px 10px; box-shadow: none; caret-color: {p['accent2']}; }}
    .thunar statusbar, .thunar .statusbar {{ background-color: transparent; color: {rgba(p['subtext'], 0.9)}; font-size: 11px; letter-spacing: 0.6px; border: none; border-top: 1px solid {rgba(p['accent2'], 0.12)}; padding: 2px 10px; }}
    .thunar paned > separator {{ background-color: {rgba(p['accent2'], 0.28)}; background-image: none; min-width: 1px; }}
    scrollbar, scrollbar trough {{ background: transparent; border: none; }}
    scrollbar slider {{ background-color: {rgba(p['accent2'], 0.35)}; border-radius: 99px; min-width: 3px; min-height: 3px; border: none; }}
    scrollbar slider:hover {{ background-color: {rgba(p['accent2'], 0.6)}; }}
    /* the file chooser (Open / Save in every GTK app): the base theme filled the whole chooser with a flat grey slab and
       its path row with a darker one. It is the dialog's glass now, the path row a frosted band with a hairline. */
    {GS('filechooser')} {{ background-color: transparent; background-image: none; }}
    {GS('filechooser #pathbarbox')} {{ background-color: {gl_head}; background-image: linear-gradient(to bottom, {rgba(p['text'], 0.06)}, transparent); border-bottom: 1px solid {rgba(p['accent2'], 0.20)}; }}
    {GS('filechooser .dialog-action-box')} {{ border-top: 1px solid {rgba(p['accent2'], 0.16)}; }}
    /* info bars (a file changed on disk, a folder you can't write to): the base theme's flat material yellow, red and grey
       slabs. On the glass they are a faint lift with a margin mark at the left, gold for a warning or a question, the
       accent for an error, and the words stay in the page's ink. */
    {GS('infobar > revealer > box', 'infobar:hover > revealer > box', 'infobar:backdrop > revealer > box')} {{ background-color: {rgba(p['text'], 0.06)}; background-image: none; border: none; border-bottom: 1px solid {rgba(p['accent2'], 0.14)}; box-shadow: inset 2px 0 {rgba(p['accent2'], 0.7)}; color: {p['text']}; }}
    {GS('infobar.error > revealer > box', 'infobar.error:hover > revealer > box', 'infobar.error:backdrop > revealer > box')} {{ background-color: {rgba(p['accent'], 0.12)}; box-shadow: inset 2px 0 {p['accent']}; }}
    {GS('infobar > revealer > box label')} {{ color: {p['text']}; }}
    /* T20: the answer button (Open, Save, Select) is the one solid gold mark on the glass, ink on gold. */
    button.suggested-action, headerbar button.suggested-action, .dialog-action-area > button.suggested-action {{ background-color: {rgba(p['accent2'], 0.88)}; background-image: none; border: 1px solid {p['accent2']}; color: {p['mantle']}; font-weight: 600; box-shadow: none; text-shadow: none; }}
    button.suggested-action label {{ color: {p['mantle']}; text-shadow: none; }}
    button.suggested-action:hover {{ background-color: {p['accent2']}; }}
    button.suggested-action:disabled, button.suggested-action:disabled label {{ background-color: {rgba(p['accent2'], 0.30)}; color: {rgba(p['mantle'], 0.75)}; }}
    paned > separator, paned.wide > separator {{ background-color: transparent; background-image: none; border: none; box-shadow: none; }}
    placessidebar, .sidebar-pane {{ border-right: 1px solid {rgba(p['accent2'], 0.28)}; }}
    /* T21 A2: a menu is one small sheet of glass over Hyprland's popup blur (blur.popups = true). GTK puts menus, combo
       lists and completions in a popup window: that window is the sheet, edged with one gold hairline, and the menu
       inside it is clear (it used to sit 3 px inside as a near-solid slab). Tooltips and popovers match. No glow. */
    {GW}.popup {{ background-color: {gl_menu}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 45%); border: 1px solid {rgba(p['accent2'], 0.34)}; border-radius: {R}px; box-shadow: inset 0 1px {gl_lit}; }}
    window.popup decoration, .csd.popup decoration {{ border-radius: {R}px; box-shadow: 0 12px 30px {rgba('#000000', 0.40)}; border: none; }}
    window.popup menu, .background.popup > menu, .csd.popup > menu {{ background-color: transparent; background-image: none; border: none; box-shadow: none; margin: 0; border-radius: {R}px; }}
    window.popup menu > arrow {{ background-color: transparent; border: none; }}
    popover.background, popover.menu {{ background-color: {gl_menu}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 45%); border: 1px solid {rgba(p['accent2'], 0.34)}; box-shadow: inset 0 1px {gl_lit}, 0 12px 30px {rgba('#000000', 0.40)}; }}
    tooltip, tooltip.background {{ background-color: {gl_tip}; background-image: linear-gradient(to bottom, {gl_frost}, transparent 60%); border: 1px solid {rgba(p['accent2'], 0.34)}; box-shadow: inset 0 1px {gl_lit}; }}
    /* the About dialog's name opens focused, and a focused selectable label is selected: keep the title clear */
    .aboutdialog image + label selection, dialog.background box > image + label selection {{ background-color: transparent; color: {p['text']}; }}
    """))
    W(f"{H}/.config/gtk-3.0/settings.ini", textwrap.dedent(f"""\
    [Settings]
    gtk-theme-name={T['gtk']}
    gtk-icon-theme-name={T['icons']}
    gtk-cursor-theme-name={T['cursor']}
    gtk-cursor-theme-size=24
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=1
    gtk-decoration-layout=:
    gtk-menu-images=0
    gtk-sound-theme-name=Tenka-{name.capitalize()}
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
    """))
    W(f"{H}/.config/gtk-4.0/settings.ini", textwrap.dedent(f"""\
    [Settings]
    gtk-icon-theme-name={T['icons']}
    gtk-cursor-theme-name={T['cursor']}
    gtk-cursor-theme-size=24
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=1
    gtk-decoration-layout=:
    gtk-sound-theme-name=Tenka-{name.capitalize()}
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
    """))
    # ---------- Qt (qt6ct palette, Fusion) ----------
    # order: WindowText Button Light Midlight Dark Mid Text BrightText ButtonText Base Window Shadow Highlight HighlightedText
    #        Link LinkVisited AlternateBase NoRole ToolTipBase ToolTipText PlaceholderText (Accent)
    def pal(dim=False):
        t = p['subtext'] if dim else p['text']
        cols = [t, p['surface'], mix(p['overlay'], p['text'], .15), p['overlay'], p['mantle'], mix(p['surface'], p['overlay'], .5),
                t, "#ffffff", t, p['mantle'], p['base'], "#000000", p['accent'], p['text'], p['accent2'], p['soft'],
                p['surface'], p['base'], p['surface'], p['text'], p['subtext'], p['accent']]
        return ", ".join("#ff" + hx(c) for c in cols)
    W(f"{H}/.config/qt6ct/colors/tenka-{name}.conf", f"[ColorScheme]\nactive_colors={pal()}\ndisabled_colors={pal(True)}\ninactive_colors={pal()}\n")
    W(f"{H}/.config/qt6ct/qt6ct.conf", textwrap.dedent(f"""\
    [Appearance]
    color_scheme_path=$HOME/.config/qt6ct/colors/tenka-{name}.conf
    custom_palette=false
    icon_theme={T['icons']}
    standard_dialogs=default
    style=kvantum

    [Fonts]
    fixed="JetBrains Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="Inter,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    """).replace("$HOME", "~"))
    # ---------- Kvantum (every Qt widget: polkit prompt, installer, qt6ct...) ----------
    # qt6ct picks style=kvantum above; Kvantum's own colours come from the same palette, so
    # custom_palette is off (two palettes fighting is how Qt apps end up half-themed).
    # Two twins: the glass one (Hyprland blurs behind see-through Qt windows) and a solid one for Tenka Lite,
    # performance mode and the installer (no blur there). tenka-qt-glass picks per session; the glass one is the default.
    for glass, kname in ((True, T['gtk']), (False, T['gtk'] + "Solid")):
        kv_svg, kv_conf = tenka_kvantum.build(name, T, glass=glass)
        W(f"{H}/.config/Kvantum/{kname}/{kname}.svg", kv_svg)
        W(f"{H}/.config/Kvantum/{kname}/{kname}.kvconfig", kv_conf)
    W(f"{H}/.config/Kvantum/kvantum.kvconfig", f"[General]\ntheme={T['gtk']}\n")
    # ---------- Firefox ESR: chrome + new-tab colours (loaded by /usr/lib/firefox-esr/tenka.cfg) ----------
    # One user sheet from ~/.config/tenka, so tenka-theme re-skins Firefox at its next window.
    fx = dict(bg=p['mantle'], bar=p['base'], tab=p['surface'], field=p['surface'], text=p['text'], sub=p['subtext'],
              acc=p['accent'], line=mix(p['overlay'], p['text'], .08), sel=mix(p['surface'], p['accent'], .30), hov=p['overlay'])
    chrome_vars = {
        "--toolbox-bgcolor": fx['bg'], "--toolbox-bgcolor-inactive": fx['bg'], "--toolbox-textcolor": fx['sub'],
        "--toolbox-textcolor-inactive": fx['sub'], "--toolbar-bgcolor": fx['bar'], "--toolbar-color": fx['text'],
        "--tab-selected-bgcolor": fx['tab'], "--tab-selected-textcolor": fx['text'], "--tab-hover-background-color": rgba(fx['hov'], 0.5),
        "--tabs-border-color": fx['line'], "--tab-selected-outline-color": "transparent",
        "--toolbar-field-background-color": fx['field'], "--toolbar-field-color": fx['text'],
        "--toolbar-field-border-color": "transparent", "--toolbar-field-focus-background-color": fx['bg'],
        "--toolbar-field-focus-color": fx['text'], "--toolbar-field-focus-border-color": fx['acc'],
        "--urlbar-box-bgcolor": fx['field'], "--urlbar-box-focus-bgcolor": fx['bg'], "--urlbar-box-hover-bgcolor": fx['hov'],
        "--urlbarView-highlight-background": fx['sel'], "--urlbarView-highlight-color": fx['text'],
        "--urlbarView-hover-background": rgba(fx['hov'], 0.6), "--urlbarView-separator-color": fx['line'],
        "--arrowpanel-background": fx['bg'], "--arrowpanel-color": fx['text'], "--arrowpanel-border-color": fx['line'],
        "--panel-separator-color": fx['line'], "--chrome-content-separator-color": fx['line'],
        "--focus-outline-color": fx['acc'], "--toolbarbutton-icon-fill": fx['sub'], "--toolbarbutton-icon-fill-attention": fx['acc'],
        "--button-hover-bgcolor": rgba(fx['hov'], 0.7), "--button-active-bgcolor": fx['hov'],
        "--toolbarbutton-hover-background": rgba(fx['hov'], 0.7), "--toolbarbutton-active-background": fx['hov'],
        "--sidebar-background-color": fx['bg'], "--sidebar-text-color": fx['text'], "--sidebar-border-color": fx['line'],
        "--lwt-accent-color": fx['bg'], "--lwt-text-color": fx['text'], "--lwt-tab-line-color": fx['acc'],
        "--color-accent-primary": fx['acc'], "--input-bgcolor": fx['field'], "--input-color": fx['text'],
        # Firefox 140+ (Debian 13's ESR) renamed most of the above; the same colours under the new names. (Its CSS also
    # dropped :-moz-lwtheme: one unknown selector voids the whole rule, so the list below uses [lwtheme].)
        "--toolbox-background-color": fx['bg'], "--toolbox-background-color-inactive": fx['bg'],
        "--toolbox-text-color": fx['sub'], "--toolbox-text-color-inactive": fx['sub'],
        "--toolbar-background-color": fx['bar'], "--toolbar-text-color": fx['text'],
        "--tab-background-color-selected": fx['tab'], "--tab-background-color-hover": rgba(fx['hov'], 0.5),
        "--toolbar-field-background-color": fx['field'], "--toolbar-field-text-color": fx['text'],
        "--toolbar-field-background-color-focus": fx['bg'], "--toolbar-field-text-color-focus": fx['text'],
        "--toolbar-field-border-color-focus": fx['acc'],
        "--urlbar-box-background-color": fx['field'], "--urlbar-box-background-color-focus": fx['bg'],
        "--urlbar-box-background-color-hover": fx['hov'], "--urlbar-box-background-color-active": fx['hov'], "--urlbar-box-text-color": fx['text'],
        "--urlbarview-background-color-selected": fx['sel'], "--urlbarview-text-color-selected": fx['text'],
        "--urlbarview-background-color-hover": rgba(fx['hov'], 0.6), "--urlbarview-separator-color": fx['line'],
        "--panel-background-color": fx['bg'], "--panel-text-color": fx['text'], "--panel-border-color": fx['line'],
        "--button-background-color": fx['field'], "--button-text-color": fx['text'],
        "--button-background-color-hover": rgba(fx['hov'], 0.7), "--button-background-color-active": fx['hov'],
        "--toolbarbutton-background-color-hover": rgba(fx['hov'], 0.7), "--toolbarbutton-background-color-active": fx['hov'],
    }
    newtab_vars = {"--newtab-background-color": fx['bar'], "--newtab-background-color-secondary": fx['tab'],
                   "--newtab-text-primary-color": fx['text'], "--newtab-text-secondary-color": fx['sub'],
                   "--newtab-element-hover-color": fx['hov'], "--newtab-primary-action-background": fx['acc'],
                   "--newtab-border-color": fx['line'], "--newtab-textbox-background-color": fx['tab']}
    pdf_vars = {"--main-color": fx['text'], "--body-bg-color": fx['bg'], "--scrollbar-color": fx['hov'], "--scrollbar-bg-color": fx['bg'],
                "--toolbar-bg-color": fx['bar'], "--toolbar-border-color": fx['line'], "--toolbar-box-shadow": "none",
                "--toolbar-border-bottom": f"1px solid {fx['line']}", "--sidebar-narrow-bg-color": fx['bg'],
                "--sidebar-toolbar-bg-color": fx['bar'], "--toolbar-icon-bg-color": fx['sub'], "--toolbar-icon-hover-bg-color": fx['text'],
                "--button-hover-color": fx['hov'], "--toggled-btn-color": fx['text'], "--toggled-btn-bg-color": fx['sel'],
                "--toggled-hover-active-btn-color": fx['text'], "--dropdown-btn-bg-color": fx['field'], "--separator-color": fx['line'],
                "--field-color": fx['text'], "--field-bg-color": fx['field'], "--field-border-color": fx['line'],
                "--doorhanger-bg-color": fx['bg'], "--doorhanger-border-color": fx['line'], "--doorhanger-hover-color": fx['text'],
                "--doorhanger-hover-bg-color": fx['hov'], "--doorhanger-separator-color": fx['line'], "--dialog-button-bg-color": fx['field'],
                "--dialog-button-hover-bg-color": fx['hov'], "--progress-bar-color": fx['acc'], "--color-accent-primary": fx['acc']}
    reader_vars = {"--main-background": fx['bar'], "--main-foreground": fx['text'], "--primary-color": fx['acc'],
                   "--link-foreground": fx['acc'], "--visited-link-foreground": mix(fx['acc'], fx['sub'], .5),
                   "--text-selected-background": fx['sel'], "--text-selected-foreground": fx['text'], "--selected-background": fx['sel'],
                   "--toolbar-border": fx['line'], "--icon-fill": fx['sub'], "--popup-background": fx['bg'], "--popup-foreground": fx['text'],
                   "--popup-border": fx['line'], "--toolbar-button-background-hover": rgba(fx['hov'], 0.7),
                   "--toolbar-button-background-active": fx['hov'], "--toolbar-button-foreground-active": fx['acc']}
    vblock = lambda d: "\n".join(f"    {k}: {v} !important;" for k, v in d.items())
    W(f"{H}/.config/tenka/firefox.css", f"""/* Tenka {T['display']}: Firefox chrome + new tab. Generated by scripts/gen-themes.py; flat, no glow. */
@-moz-document url("chrome://browser/content/browser.xhtml") {{
  :root, :root[lwtheme], #navigator-toolbox, #titlebar, toolbar, #nav-bar, #TabsToolbar, #PersonalToolbar, #urlbar, .urlbarView, panel {{
{vblock(chrome_vars)}
  }}
  #navigator-toolbox, #titlebar, #TabsToolbar {{ background-color: {fx['bg']} !important; background-image: none !important; color: {fx['text']} !important; }}
  #nav-bar, #PersonalToolbar, #FindToolbar, findbar {{ background-color: {fx['bar']} !important; background-image: none !important; color: {fx['text']} !important; }}
  #urlbar-background, .urlbar-background, #searchbar {{ background-color: {fx['field']} !important; }}
  #urlbar[focused] > #urlbar-background, .urlbar:is([focused], [open]) > .urlbar-background {{ background-color: {fx['bg']} !important; outline: 1px solid {fx['acc']} !important; box-shadow: none !important; }}
  #navigator-toolbox {{ border-bottom: 1px solid {fx['line']} !important; }}
  .tab-background[selected] {{ background-color: {fx['tab']} !important; background-image: none !important; box-shadow: inset 0 -2px 0 {fx['acc']} !important; border-radius: {max(4, T['rounding'] - 4)}px !important; }}
  .tab-background {{ border-radius: {max(4, T['rounding'] - 4)}px !important; }}
  #urlbar-background, .urlbar-background {{ border-radius: {max(4, T['rounding'] - 4)}px !important; }}
  .tab-label {{ font-family: "Inter", sans-serif !important; }}
  ::selection {{ background-color: {fx['sel']} !important; color: {fx['text']} !important; }}
}}
@-moz-document url-prefix("about:newtab"), url-prefix("about:home"), url-prefix("about:privatebrowsing"), url("about:blank") {{
  :root {{
{vblock(newtab_vars)}
  }}
  html, body {{ background-color: {fx['bar']} !important; color: {fx['text']} !important; }}
  .top-site-outer .tile, .top-site-outer .top-site-icon {{ background-color: {fx['tab']} !important; box-shadow: none !important; }}
  .top-site-outer:hover .tile {{ background-color: {fx['hov']} !important; }}
}}
/* Firefox's own PDF viewer (pdf.js): the document keeps the PDF's own address, so the viewer is found by its <html> */
html[mozdisallowselectionprint] {{
{vblock(pdf_vars)}
}}
html[mozdisallowselectionprint] body {{ background-color: {fx['bg']} !important; }}
html[mozdisallowselectionprint] .page {{ box-shadow: 0 0 0 1px {fx['line']} !important; border: none !important; }}
/* Reader View: the light and dark readings take the pack's ink (sepia, gray and contrast stay the reader's own choice);
   titles in Marcellus, the body in the reader's chosen face */
@-moz-document url-prefix("about:reader") {{
  body.light, body.dark, body:not(.sepia, .gray, .contrast) {{
{vblock(reader_vars)}
    color-scheme: dark !important;
  }}
  body:not(.sepia, .gray, .contrast) {{ background-color: {fx['bar']} !important; color: {fx['text']} !important; }}
  .reader-title, .moz-reader-content h1, .moz-reader-content h2, .moz-reader-content h3 {{ font-family: "Marcellus", serif !important; font-weight: 400 !important; letter-spacing: .01em; }}
  .reader-title {{ border-bottom: 1px solid {rgba(fx['acc'], 0.55)}; padding-bottom: .4em; }}
  .credits, .meta-data {{ color: {fx['sub']} !important; }}
  .moz-reader-content blockquote {{ border-inline-start: 2px solid {fx['acc']} !important; }}
}}
""")
    # ---------- terminal apps: starship, btop, mpv, imv, cava, nano (all from the palette) ----------
    acc, acc2, txt, sub, ovl, srf = p['accent'], p['accent2'], p['text'], p['subtext'], p['overlay'], p['surface']
    W(f"{H}/.config/starship.toml", f"""# {T['display']} prompt, generated by scripts/gen-themes.py: quiet, one accent
add_newline = true
palette = "tenka"
format = \"\"\"$directory$git_branch$git_status$python$rust$nodejs$cmd_duration
$character\"\"\"
[palettes.tenka]
accent = "{acc}"
gold = "{acc2}"
paper = "{txt}"
mist = "{sub}"
ink = "{ovl}"
[directory]
style = "gold"
truncation_length = 3
truncation_symbol = "…/"
[git_branch]
symbol = " "
style = "italic mist"
[git_status]
style = "accent"
[character]
success_symbol = "[❯](accent)"
error_symbol = "[❯](bold {p['soft']})"
[cmd_duration]
style = "mist"
format = " [$duration]($style)"
""")
    W(f"{H}/.config/btop/themes/tenka.theme", "# " + T['display'] + " for btop, generated by scripts/gen-themes.py\n" + "\n".join(
        f'theme[{k}]="{v}"' for k, v in dict(
            main_bg=p['base'], main_fg=txt, title=txt, hi_fg=acc, selected_bg=mix(srf, acc, .30), selected_fg=txt,
            inactive_fg=mix(sub, p['base'], .45), graph_text=sub, meter_bg=ovl, proc_misc=acc2,
            cpu_box=ovl, mem_box=ovl, net_box=ovl, proc_box=ovl, div_line=ovl,
            temp_start=p['green'] if name == "samurai" else acc, temp_mid=acc2, temp_end=p['soft'] if name == "xianxia" else acc,
            cpu_start=mix(acc, p['base'], .35), cpu_mid=acc, cpu_end=p['accent_l'],
            free_start=mix(p['alt'], p['base'], .4), free_mid=p['alt'], free_end=mix(p['alt'], txt, .3),
            cached_start=mix(acc2, p['base'], .4), cached_mid=acc2, cached_end=mix(acc2, txt, .3),
            available_start=mix(sub, p['base'], .4), available_mid=sub, available_end=txt,
            used_start=mix(acc, p['base'], .35), used_mid=acc, used_end=p['accent_l'],
            download_start=mix(p['alt'], p['base'], .4), download_mid=p['alt'], download_end=mix(p['alt'], txt, .3),
            upload_start=mix(acc, p['base'], .35), upload_mid=acc, upload_end=p['accent_l'],
            process_start=mix(acc2, p['base'], .2), process_mid=acc, process_end=p['accent_l']).items()) + "\n")
    W(f"{H}/.config/btop/btop.conf", 'color_theme = "tenka"\ntheme_background = False\ntruecolor = True\n'
      'rounded_corners = True\ngraph_symbol = "braille"\nshown_boxes = "cpu mem net proc"\n')
    ah = lambda c, a="ff": "#" + a + hx(c)          # mpv/imv take #AARRGGBB
    W(f"{H}/.config/mpv/mpv.conf", f"""# {T['display']}: calm OSD from the palette (generated by scripts/gen-themes.py)
osd-font="Inter"
osd-font-size=36
osd-color="{ah(txt)}"
osd-border-color="{ah(p['base'], 'cc')}"
osd-border-size=1.5
osd-shadow-offset=0
osd-bar-h=1.6
osd-bar-w=60
osd-bar-align-y=0.9
osd-back-color="{ah(p['base'], '00')}"
sub-font="Inter"
sub-border-color="{ah(p['base'], 'dd')}"
sub-shadow-offset=0
background-color="{p['base']}"
""")
    # mpv 0.40's osc has no seekbar colour keys: the bar and the time are drawn in timecode_color
    W(f"{H}/.config/mpv/script-opts/osc.conf", f"""# {T['display']} player controls (generated by scripts/gen-themes.py)
layout=bottombar
seekbarstyle=bar
deadzonesize=0.6
background_color={p['base']}
timecode_color={acc}
title_color={txt}
time_pos_color={txt}
buttons_color={txt}
top_buttons_color={sub}
held_element_color={acc}
""")
    W(f"{H}/.config/imv/config", f"""# {T['display']} image viewer (generated by scripts/gen-themes.py)
[options]
background = {hx(p['base'])}
overlay = false
overlay_font = Inter:12
overlay_text_color = {hx(txt)}
overlay_text_alpha = ff
overlay_background_color = {hx(p['mantle'])}
overlay_background_alpha = d0
overlay_position_bottom = true

[aliases]
q = quit
""")
    W(f"{H}/.config/cava/config", f"""# {T['display']} visualiser (generated by scripts/gen-themes.py)
[general]
bar_width = 2
bar_spacing = 1
[color]
background = default
gradient = 1
gradient_count = 3
gradient_color_1 = '{mix(acc, p['base'], .35)}'
gradient_color_2 = '{acc}'
gradient_color_3 = '{acc2}'
""")
    n3 = lambda c: "#" + "".join("%x" % round(int(hx(c)[i:i+2], 16) / 17) for i in (0, 2, 4))   # nano takes #rgb
    W(f"{H}/.config/nano/nanorc", f"""## {T['display']} for nano (generated by scripts/gen-themes.py)
include "/usr/share/nano/*.nanorc"
set linenumbers
set indicator
set titlecolor bold,{n3(txt)},{n3(srf)}
set promptcolor {n3(txt)},{n3(srf)}
set statuscolor bold,{n3(txt)},{n3(ovl)}
set errorcolor bold,{n3(txt)},{n3(mix(acc, p['base'], .2))}
set spotlightcolor {n3(p['base'])},{n3(acc2)}
set selectedcolor {n3(txt)},{n3(mix(srf, acc, .35))}
set stripecolor ,{n3(srf)}
set scrollercolor {n3(acc)}
set numbercolor {n3(mix(sub, p['base'], .35))}
set keycolor bold,{n3(acc)}
set functioncolor {n3(sub)}
set minicolor {n3(sub)},{n3(srf)}
""")
    # ---------- editor + shell tools: neovim, fzf, tmux, zathura (bat uses the terminal's own colours) ----------
    base, mantle, muted = p['base'], p['mantle'], mix(sub, p['base'], .35)
    hl = {  # group: (fg, bg, style)
        "Normal": (txt, base, ""), "NormalFloat": (txt, mantle, ""), "FloatBorder": (ovl, mantle, ""),
        "ColorColumn": (None, srf, ""), "CursorLine": (None, mix(base, srf, .6), ""), "CursorLineNr": (acc, None, "bold"),
        "LineNr": (muted, None, ""), "SignColumn": (None, base, ""), "NonText": (ovl, None, ""), "EndOfBuffer": (ovl, None, ""),
        "Visual": (None, mix(srf, acc, .30), ""), "Search": (base, acc2, ""), "IncSearch": (base, acc, ""), "CurSearch": (base, acc, ""),
        "MatchParen": (acc, None, "bold,underline"), "StatusLine": (txt, srf, ""), "StatusLineNC": (muted, mantle, ""),
        "WinSeparator": (ovl, None, ""), "VertSplit": (ovl, None, ""), "TabLine": (muted, mantle, ""), "TabLineSel": (txt, srf, "bold"),
        "TabLineFill": (None, mantle, ""), "Pmenu": (txt, mantle, ""), "PmenuSel": (txt, mix(srf, acc, .35), ""), "PmenuSbar": (None, srf, ""),
        "PmenuThumb": (None, ovl, ""), "Title": (acc2, None, "bold"), "Directory": (acc2, None, ""), "Folded": (muted, srf, ""),
        "Comment": (muted, None, "italic"), "Constant": (k['color5'], None, ""), "String": (k['color2'], None, ""),
        "Character": (k['color2'], None, ""), "Number": (k['color5'], None, ""), "Boolean": (k['color5'], None, ""),
        "Identifier": (txt, None, ""), "Function": (k['color4'], None, ""), "Statement": (acc, None, ""), "Keyword": (acc, None, ""),
        "Operator": (sub, None, ""), "PreProc": (k['color6'], None, ""), "Type": (acc2, None, ""), "Special": (acc2, None, ""),
        "Delimiter": (sub, None, ""), "Todo": (base, acc2, "bold"), "Error": (acc, None, "bold"), "ErrorMsg": (acc, None, "bold"),
        "WarningMsg": (acc2, None, ""), "MoreMsg": (k['color2'], None, ""), "Question": (k['color2'], None, ""),
        "DiagnosticError": (k['color1'], None, ""), "DiagnosticWarn": (acc2, None, ""), "DiagnosticInfo": (k['color4'], None, ""),
        "DiagnosticHint": (k['color6'], None, ""), "DiffAdd": (None, mix(base, k['color2'], .18), ""),
        "DiffChange": (None, mix(base, k['color4'], .15), ""), "DiffDelete": (None, mix(base, k['color1'], .18), ""),
        "DiffText": (None, mix(base, k['color4'], .32), ""), "SpellBad": (None, None, "undercurl"),
    }
    def nv(g_, f, b, s):
        a = [f'fg = "{f}"' if f else "", f'bg = "{b}"' if b else ""] + [f"{x} = true" for x in s.split(",") if x]
        return f'hi(0, "{g_}", {{ {", ".join(x for x in a if x)} }})'
    W(f"{H}/.config/nvim/colors/tenka.lua", "-- " + T['display'] + " for Neovim, generated by scripts/gen-themes.py (flat, one accent)\n"
      "vim.cmd('highlight clear')\nvim.o.termguicolors = true\nvim.o.background = 'dark'\nvim.g.colors_name = 'tenka'\n"
      "local hi = vim.api.nvim_set_hl\n" + "\n".join(nv(a, *b) for a, b in hl.items()) + "\n")
    # plugin/ loads after init.lua: a user's own colorscheme wins
    W(f"{H}/.config/nvim/plugin/tenka-colors.lua", "if vim.g.colors_name == nil then pcall(vim.cmd.colorscheme, 'tenka') end\n")
    # fzf reads its options from a file on every run (FZF_DEFAULT_OPTS_FILE), so a theme switch recolours
    # the next fzf in every shell that is already open
    W(f"{H}/.config/tenka/fzf.opts", f"""--color=bg+:{srf},bg:-1,fg:{sub},fg+:{txt},hl:{acc},hl+:{acc},border:{ovl},header:{acc2},info:{muted},marker:{acc2},pointer:{acc},prompt:{acc},spinner:{acc2}
--border=rounded --layout=reverse --height=40% --pointer='❯' --marker='•'
""")
    # ---------- the terminal's ink: ls / eza, man pages, grep, git (#21 "Terminal ink") ----------
    # one accent and one gold, everything else in the page's own greys: no rainbow file lists
    def sgr(c, pre=""): return f"{pre}38;2;{rgb_t(c).replace(',', ';')}"   # SGR wants ; (rgb_t gives r,g,b)
    ink = dict(dir=acc2, exe=k['color2'], link=k['color6'], media=k['color5'], audio=k['color6'], arch=acc,
               doc=txt, quiet=muted, broken=acc)
    lsc = [f"di={sgr(ink['dir'], '1;')}", f"ln={sgr(ink['link'])}", f"ex={sgr(ink['exe'], '1;')}", f"or={sgr(ink['broken'], '9;')}",
           f"mi={sgr(ink['broken'])}", f"so={sgr(k['color4'])}", f"pi={sgr(k['color4'])}", f"bd={sgr(acc2)}", f"cd={sgr(acc2)}",
           f"su={sgr(acc, '1;')}", f"sg={sgr(acc, '1;')}", f"tw={sgr(ink['dir'], '1;4;')}", f"ow={sgr(ink['dir'], '1;4;')}",
           f"st={sgr(ink['dir'], '1;')}", f"fi={sgr(txt)}", "rs=0"]
    exts = {"media": "png jpg jpeg gif webp svg avif heic bmp tif tiff mp4 mkv webm mov avi",
            "audio": "mp3 flac ogg opus wav m4a aac",
            "arch": "zip tar gz tgz xz zst bz2 7z rar deb iso img",
            "quiet": "log tmp bak swp o pyc lock part"}
    for kind, xs in exts.items():
        lsc += [f"*.{x}={sgr(ink[kind])}" for x in xs.split()]
    ls_colors = ":".join(lsc)
    def ez(c, **f):
        return "{foreground: \"" + c + "\"" + "".join(f", {a}: true" for a, on in f.items() if on) + "}"
    eza = f"""# {T['display']} for eza (generated by scripts/gen-themes.py). eza reads ~/.config/eza/theme.yml
colourful: true
filekinds:
  normal: {ez(txt)}
  directory: {ez(ink['dir'], is_bold=True)}
  symlink: {ez(ink['link'])}
  pipe: {ez(k['color4'])}
  block_device: {ez(acc2)}
  char_device: {ez(acc2)}
  socket: {ez(k['color4'])}
  special: {ez(acc2)}
  executable: {ez(ink['exe'], is_bold=True)}
  mount_point: {ez(ink['dir'], is_bold=True, is_underline=True)}
perms:
  user_read: {ez(sub)}
  user_write: {ez(acc2)}
  user_execute_file: {ez(ink['exe'], is_bold=True)}
  user_execute_other: {ez(ink['exe'])}
  group_read: {ez(sub)}
  group_write: {ez(acc2)}
  group_execute: {ez(ink['exe'])}
  other_read: {ez(sub)}
  other_write: {ez(acc)}
  other_execute: {ez(ink['exe'])}
  special_user_file: {ez(acc)}
  special_other: {ez(acc)}
  attribute: {ez(muted)}
size:
  major: {ez(sub)}
  minor: {ez(sub)}
  number_byte: {ez(sub)}
  number_kilo: {ez(sub)}
  number_mega: {ez(txt)}
  number_giga: {ez(acc2)}
  number_huge: {ez(acc)}
  unit_byte: {ez(muted)}
  unit_kilo: {ez(muted)}
  unit_mega: {ez(muted)}
  unit_giga: {ez(acc2)}
  unit_huge: {ez(acc)}
users:
  user_you: {ez(sub)}
  user_root: {ez(acc)}
  user_other: {ez(muted)}
  group_yours: {ez(muted)}
  group_other: {ez(muted)}
  group_root: {ez(acc)}
links:
  normal: {ez(sub)}
  multi_is_hard: {ez(acc2)}
git:
  new: {ez(k['color2'])}
  modified: {ez(acc2)}
  deleted: {ez(acc)}
  renamed: {ez(k['color4'])}
  typechange: {ez(k['color4'])}
  ignored: {ez(muted)}
  conflicted: {ez(acc, is_bold=True)}
git_repo:
  branch_main: {ez(sub)}
  branch_other: {ez(acc2)}
  git_clean: {ez(k['color2'])}
  git_dirty: {ez(acc2)}
file_type:
  image: {ez(ink['media'])}
  video: {ez(ink['media'])}
  music: {ez(ink['audio'])}
  lossless: {ez(ink['audio'])}
  crypto: {ez(k['color4'])}
  document: {ez(txt)}
  compressed: {ez(ink['arch'])}
  temp: {ez(muted)}
  compiled: {ez(muted)}
  build: {ez(acc2, is_underline=True)}
  source: {ez(txt)}
punctuation: {ez(mix(ovl, txt, .25))}
date: {ez(muted)}
inode: {ez(muted)}
blocks: {ez(muted)}
header: {ez(sub, is_underline=True)}
octal: {ez(muted)}
flags: {ez(muted)}
symlink_path: {ez(ink['link'])}
control_char: {ez(acc)}
broken_symlink: {ez(acc)}
broken_path_overlay: {ez(acc, is_underline=True)}
"""
    W(f"{H}/.config/eza/theme.yml", eza)
    # git: ~/.config/git/config (static, in /etc/skel) includes this file, so a user's own settings stay theirs
    W(f"{H}/.config/tenka/git-colors", f"""# {T['display']} colours for git (generated by scripts/gen-themes.py)
[color]
	ui = auto
[color "branch"]
	current = "{acc2}" bold
	local = "{sub}"
	remote = "{k['color6']}"
	upstream = "{k['color6']}"
[color "diff"]
	meta = "{acc2}"
	frag = "{k['color4']}"
	func = "{sub}"
	commit = "{acc2}"
	old = "{acc}"
	new = "{k['color2']}"
	whitespace = "{acc}" reverse
[color "status"]
	header = "{muted}"
	branch = "{acc2}" bold
	added = "{k['color2']}"
	updated = "{k['color2']}"
	changed = "{acc2}"
	untracked = "{sub}"
	unmerged = "{acc}" bold
[color "decorate"]
	HEAD = "{acc}" bold
	branch = "{acc2}"
	remoteBranch = "{k['color6']}"
	tag = "{k['color5']}"
	stash = "{muted}"
[color "grep"]
	match = "{acc}" bold
	filename = "{acc2}"
	linenumber = "{muted}"
	separator = "{mix(ovl, txt, .25)}"
""")
    na = "red" if name == "samurai" else "green"          # the accent's ANSI slot in this theme's kitty palette
    newt = " ".join(f"{k_}={v_}" for k_, v_ in dict(
        root="white,black", roottext="brown,black", helpline="gray,black", window="lightgray,black", shadow="black,black",
        border="gray,black", title="brown,black", textbox="lightgray,black", acttextbox="black,brown", label="lightgray,black",
        button="lightgray,black", actbutton="black,brown", compactbutton="lightgray,black", checkbox="lightgray,black",
        actcheckbox="black,brown", entry="white,black", disentry="gray,black", listbox="lightgray,black",
        actlistbox="black,brown", sellistbox=f"{na},black", actsellistbox="black,brown", emptyscale=",black",
        fullscale=",brown").items())
    W(f"{H}/.bashrc.d/tenka-theme.sh", f"""# Tenka colours for shell tools (generated by scripts/gen-themes.py)
[ -n "${{FZF_DEFAULT_OPTS_FILE:-}}" ] || export FZF_DEFAULT_OPTS_FILE="$HOME/.config/tenka/fzf.opts"
export BAT_THEME=ansi
# ls, tab completion and every LS_COLORS reader: the theme's ink (eza reads ~/.config/eza/theme.yml)
export LS_COLORS='{ls_colors}'
# man pages: headings in the accent, arguments in gold italics, the status line on the page's paper
export GROFF_NO_SGR=1 MANROFFOPT='-c' MANPAGER='less -R'
export LESS_TERMCAP_md=$'\\e[1;{sgr(acc)}m' LESS_TERMCAP_me=$'\\e[0m'
export LESS_TERMCAP_us=$'\\e[3;{sgr(acc2)}m' LESS_TERMCAP_ue=$'\\e[0m'
export LESS_TERMCAP_so=$'\\e[{sgr(txt)};4{sgr(mix(srf, acc, .30))[1:]}m' LESS_TERMCAP_se=$'\\e[0m'
export GREP_COLORS='mt=1;{sgr(acc)}:fn={sgr(acc2)}:ln={sgr(muted)}:bn={sgr(muted)}:se={sgr(mix(ovl, txt, .25))}'
case $- in *i*) bind 'set colored-stats on' 2>/dev/null; bind 'set colored-completion-prefix on' 2>/dev/null;; esac
# whiptail / newt dialogs (dpkg-reconfigure, installers): the terminal's own palette, so the page's ink, gold and accent
export NEWT_COLORS='{newt}'
# jq and diff in the same ink, by the terminal's own palette: keys in vermilion, strings in gold, numbers in jade;
# lines added in moss, removed in vermilion, each hunk's place in jade
export JQ_COLORS='90:31:32:36:33:39:39:31'
case $- in *i*) alias diff='diff --color=auto --palette="hd=1:ad=32:de=31:ln=36"';; esac
""")
    W(f"{H}/.config/tmux/tenka-theme.conf", f"""# {T['display']} status line for tmux (generated by scripts/gen-themes.py)
set -g status-style "bg={mantle},fg={sub}"
set -g status-left " #[fg={acc}]#S #[fg={ovl}]│ "
set -g status-right "#[fg={muted}]%H:%M "
set -g window-status-format " #I #W "
set -g window-status-current-format "#[fg={txt},bg={srf}] #I #W "
set -g pane-border-style "fg={ovl}"
set -g pane-active-border-style "fg={acc}"
set -g message-style "bg={srf},fg={txt}"
set -g mode-style "bg={mix(srf, acc, .35)},fg={txt}"
set -g clock-mode-colour "{acc}"
""")
    # the reader is glass too on Hyprland (the pages stay solid ink for reading); under Lite's X11 there is no
    # alpha visual, so the same colours land as solid, slightly deeper ink
    W(f"{H}/.config/zathura/tenka-theme", f"""# {T['display']} for zathura (generated by scripts/gen-themes.py)
set default-bg "{rgba(base, 0.58)}"
set default-fg "{txt}"
set statusbar-bg "{rgba(mantle, 0.62)}"
set statusbar-fg "{sub}"
set inputbar-bg "{rgba(mantle, 0.62)}"
set inputbar-fg "{txt}"
set notification-bg "{srf}"
set notification-fg "{txt}"
set notification-error-bg "{srf}"
set notification-error-fg "{acc}"
set notification-warning-bg "{srf}"
set notification-warning-fg "{acc2}"
set highlight-color "{rgba(acc2, 0.35)}"
set highlight-active-color "{rgba(acc, 0.45)}"
set completion-bg "{mantle}"
set completion-fg "{sub}"
set completion-highlight-bg "{mix(srf, acc, .35)}"
set completion-highlight-fg "{txt}"
set index-bg "{rgba(base, 0.58)}"
set index-fg "{sub}"
set index-active-bg "{srf}"
set index-active-fg "{txt}"
set recolor-lightcolor "{base}"
set recolor-darkcolor "{txt}"
set font "Inter 10"
""")
    # ---------- Hyprland per-theme look (Lua; Hyprland 0.55 config) ----------
    a = lambda c, al="ff": f"rgba({hx(c)}{al})"
    if name == "samurai":
        border = f'{{ colors = {{"{a(p["accent"])}", "{a(p["accent2"])}"}}, angle = 45 }}'
        shadow, curves = "0xaa000000", [("draw", (0.16, 1), (0.3, 1)), ("cut", (0.7, 0), (0.84, 0)), ("ink", (0.25, 0.1), (0.25, 1))]
        anims = [("windowsIn", 5, "draw", "slide"), ("windowsOut", 4, "cut", "slide"), ("windowsMove", 5, "draw", None),
                 ("border", 10, "ink", None), ("borderangle", 60, "ink", "loop"), ("fade", 5, "ink", None),
                 ("fadeLayersIn", 6, "ink", None), ("layersIn", 5, "draw", "slide top"), ("layersOut", 4, "cut", "fade"),
                 ("workspaces", 5, "draw", "slide"), ("specialWorkspace", 5, "draw", "slidevert")]
        note = "Tenka (Samurai): sharp, decisive motion, like a blade draw, not a bounce."
    else:
        border = f'{{ colors = {{"{a(p["accent"])}", "{a(p["accent2"])}", "{a(p["alt"])}"}}, angle = 90 }}'
        shadow, curves = "0x445fc9a0", [("drift", (0.05, 0.9), (0.1, 1.05)), ("mist", (0.4, 0), (0.2, 1)), ("rise", (0.22, 1), (0.36, 1))]
        anims = [("windowsIn", 7, "drift", "popin 80%"), ("windowsOut", 6, "mist", "popin 90%"), ("windowsMove", 6, "rise", None),
                 ("border", 12, "mist", None), ("borderangle", 80, "mist", "loop"), ("fade", 7, "mist", None),
                 ("fadeLayersIn", 8, "mist", None), ("layersIn", 6, "rise", "popin 92%"), ("layersOut", 5, "mist", "fade"),
                 ("workspaces", 7, "rise", "slidefade 15%"), ("specialWorkspace", 7, "rise", "slidefadevert 20%")]
        note = "Tianxia (Xianxia): floating, weightless motion, like mist and qi."
    # The window rice (round 3, after end-4 / Caelestia): a 1 px hairline instead of a thick gradient,
    # a soft squircle, a low long shadow, a whisper of dim on the unfocused, and Material-3 motion
    # tuned per theme (Tenka decisive, Tianxia drifting). RICE=gradient restores the old 2 px look.
    rice = os.environ.get("RICE", "hairline")
    if rice == "hairline":
        # Rice IV (the brush and the silk): still a 1 px hairline, now a two-tone gradient that turns once when focus
        # moves (borderangle "once": no endless loop, nothing redraws at rest), a lifted shadow (scale < 1, long and
        # low), the scratchpad dimmed and blurred behind, tabbed groups drawn in the theme's own ink, and motion with
        # a character per theme: Tenka a decisive brush stroke (fast in, weighted stop), Tianxia silk (slow, no
        # overshoot, drifting). No glow: shadows are black or the theme's own ink, never coloured light.
        sam = name == "samurai"
        border = (f'{{ colors = {{"{a(p["accent2"], "e6")}", "{a(p["accent"], "8c")}"}}, angle = 45 }}' if sam else
                  f'{{ colors = {{"{a(p["accent"], "d9")}", "{a(p["accent2"], "a6")}"}}, angle = 135 }}')
        inactive = a(p["text"], "14")
        # ledger corners: Tenka's windows are nearly square like the desk sheet and the control center (a blade edge),
        # Tianxia keeps more softness (mist) and a rounder squircle
        bsize, rnd, rpow = 1, (6 if sam else 12), (2.5 if sam else 3.0)
        shadow = "0x80000000" if sam else "0x8c050c0b"     # Tianxia's shadow is its own deep jade ink, still dark
        if sam:
            curves = [("brush", (0.16, 1), (0.3, 1)), ("lift", (0.7, 0), (0.84, 0)), ("ink", (0.25, 0.1), (0.25, 1)),
                      ("sheath", (0.32, 0.72), (0, 1)), ("menuDecel", (0.1, 1), (0, 1)), ("menuAccel", (0.52, 0.03), (0.72, 0.08))]
            anims = [("windowsIn", 4, "brush", "popin 94%"), ("windowsOut", 3, "lift", "popin 97%"),
                     ("windowsMove", 4.5, "brush", "slide"), ("border", 6, "ink", None), ("borderangle", 18, "ink", "once"),
                     ("fade", 3.5, "ink", None), ("fadeDim", 5, "ink", None), ("fadeLayersIn", 4, "menuDecel", None),
                     ("fadeLayersOut", 3, "menuAccel", None), ("layersIn", 4, "brush", "slide"), ("layersOut", 3, "lift", "slide"),
                     ("workspaces", 4.5, "sheath", "slide"), ("specialWorkspace", 5, "brush", "slidevert")]
        else:
            curves = [("silk", (0.22, 0.61), (0.36, 1)), ("mist", (0.45, 0), (0.55, 1)), ("drift", (0.05, 0.9), (0.1, 1)),
                      ("menuDecel", (0.1, 1), (0, 1)), ("menuAccel", (0.52, 0.03), (0.72, 0.08))]
            anims = [("windowsIn", 6, "silk", "popin 88%"), ("windowsOut", 5, "mist", "popin 94%"),
                     ("windowsMove", 6, "silk", "slide"), ("border", 9, "mist", None), ("borderangle", 30, "mist", "once"),
                     ("fade", 6, "mist", None), ("fadeDim", 7, "mist", None), ("fadeLayersIn", 6, "menuDecel", None),
                     ("fadeLayersOut", 4, "menuAccel", None), ("layersIn", 6, "silk", "slide"), ("layersOut", 4, "mist", "slide"),
                     ("workspaces", 7, "silk", "slidefadevert 18%"), ("specialWorkspace", 7, "drift", "slidefadevert 25%")]
        gi, go = (6, 14) if sam else (8, 18)
        extra_general = ["        border_size = 1,", f"        gaps_in = {gi},", f"        gaps_out = {go},", "        gaps_workspaces = 50,"]
        extra_deco = [f"        rounding_power = {rpow},", "        dim_inactive = true,", f"        dim_strength = {0.05 if sam else 0.04},",
                      "        dim_special = 0.35,", f"        inactive_opacity = {0.97 if sam else 0.95},",
                      "        blur = {", f"            size = {7 if sam else 9},", "            passes = 4,", "            special = true,",
                      "            popups_ignorealpha = 0.2,", "            input_methods = true,", f"            vibrancy = {0.30 if sam else 0.34},", "        },"]
        shadow_extra = ["            range = 36,", "            render_power = 4,", '            offset = "0 10",', "            scale = 0.98,"]
        # tabbed groups (Super + W): a quiet bar in the theme's ink, Marcellus titles, a thin indicator, no stock blue
        extra_top = ["    group = {", "        col = {", f"            border_active = {border},", f'            border_inactive = "{inactive}",',
                     "        },", "        groupbar = {", '            font_family = "Marcellus",', "            font_size = 11,",
                     "            height = 18,", "            indicator_height = 2,", "            gradients = true,",
                     f"            rounding = {max(2, rnd - 4)},", f"            gradient_rounding = {max(2, rnd - 4)},",
                     f'            text_color = "{a(p["text"])}",', "            col = {",
                     f'                active = "{a(p["accent2"] if sam else p["accent"], "40")}",',
                     f'                inactive = "{a(p["text"], "12")}",', "            },", "        },", "    },"]
    else:
        inactive = a(p["overlay"], "aa"); bsize, rnd = T["border"], T["rounding"]
        extra_general, extra_top = [], []
        extra_deco = ["        inactive_opacity = 0.97,", "        blur = {", "            size = 7,", "            passes = 3,", "            vibrancy = 0.22,", "        },"]
        shadow_extra = ["            range = 26,", "            render_power = 3,", '            offset = "0 8",']
    lua = [f"-- generated by scripts/gen-themes.py\n-- {note}", "local T = {}",
           "T.name = " + json.dumps(name), "T.display = " + json.dumps(T["display"]), "T.cursor = " + json.dumps(T["cursor"]),
           "T.c = {" + ", ".join(f'{k} = "{v}"' for k, v in p.items()) + "}", "",
           "hl.config({", "    general = {", *extra_general, "        col = {", f"            active_border   = {border},",
           f'            inactive_border = "{inactive}",', "        },", "    },",
           "    decoration = {", f"        rounding = {rnd},", *extra_deco, "        shadow = {", f"            color = {shadow},",
           *shadow_extra, "            color_inactive = 0x33000000,", "        },", "    },", *extra_top, "})", ""]
    for cn, p1, p2 in curves:
        lua.append(f'hl.curve("{cn}", {{ type = "bezier", points = {{ {{{p1[0]}, {p1[1]}}}, {{{p2[0]}, {p2[1]}}} }} }})')
    for leaf, sp, cv, st in anims:
        lua.append(f'hl.animation({{ leaf = "{leaf}", enabled = true, speed = {sp}, bezier = "{cv}"' + (f', style = "{st}"' if st else "") + " })")
    lua.append("\nreturn T\n")
    W(f"{H}/.config/hypr/theme.lua", "\n".join(lua))

if __name__ == "__main__":
    for n, t in THEMES.items():
        gen(n, t)
    print("generated:", ", ".join(THEMES))
