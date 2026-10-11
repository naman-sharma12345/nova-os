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
    window.thunar.background:not(.xfce4-panel):not(.tenka-lite) {{ background-color: {rgba(p['base'], 0.97)}; }}
    .thunar .sidebar:not(.tenka-lite), .thunar .sidebar treeview.view:not(.tenka-lite) {{ background-color: {rgba(p['mantle'], 0.35)}; }}
    """))
    # ---------- theme.env (read by scripts) ----------
    W(f"themes/{name}/theme.env", "\n".join([
        f'THEME_NAME="{name}"', f'THEME_DISPLAY="{T["display"]}"', f'THEME_TAGLINE="{T["tagline"]}"',
        f'THEME_CURSOR="{T["cursor"]}"', f'THEME_ICONS="{T["icons"]}"', f'THEME_ICON_FOLDER="{T["icon_folder"]}"',
        f'THEME_GTK="{T["gtk"]}"', f'THEME_GTK_FALLBACK="{T["gtk_fallback"]}"', f'THEME_FONT_DISPLAY="{T["font_display"]}"',
        f'THEME_FONT_BRAND="{T["font_brand"]}"',
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
    W(f"{H}/.config/gtk-4.0/gtk.css", gtkcss)
    # Tenka Lite (xfwm4: no blur) writes ~/.cache/tenka/session.css at login with denser glass; Hyprland removes it.
    # GTK skips a missing import with a warning.
    W(f"{H}/.config/gtk-3.0/gtk.css", '@import url("../../.cache/tenka/session.css");\n' + gtkcss + textwrap.dedent(f"""\
    window.background:not(.xfce4-panel), .thunar .sidebar, .sidebar {{ background-color: {p['base']}; color: {p['text']}; }}
    headerbar, .titlebar {{ background-color: {p['surface']}; color: {p['text']}; box-shadow: none; }}
    selection {{ background-color: {rgba(p['accent'], 0.35)}; color: {p['text']}; }}
    /* tooltips speak in the UI face too. This has to live here: GTK applies the xsettings font above the theme,
       so a tooltip rule in the theme's gtk.css loses; the user sheet sits above both. */
    tooltip label {{ font-family: Marcellus; font-size: 12px; letter-spacing: 0.3px; }}
    /* the Lite dock's window list (its own sheet, class .menu) speaks Marcellus too */
    .menu label {{ font-family: Marcellus; }}
    /* ---- the file manager, "glass" (Naman: more translucent, in line with the theme): one sheet of ink glass
       over the art (Hyprland blurs what is behind it), a clear content area, a gold hairline between the panes,
       the chosen place marked by a short accent rule (the ledger's mark), a hairline path bar, ledger corners,
       Marcellus labels. No pills, no glow anywhere. ---- */
    window.thunar.background, window.thunar.background:not(.xfce4-panel) {{ background-color: {rgba(p['base'], 0.50)}; color: {p['text']}; }}
    .thunar * {{ font-family: Marcellus; }}
    .thunar iconview, .thunar iconview.view, .thunar .view, .thunar treeview.view, .thunar scrolledwindow, .thunar viewport,
    .thunar notebook, .thunar notebook > stack, .thunar notebook > header {{ background-color: transparent; background-image: none; border: none; box-shadow: none; color: {p['text']}; }}
    .thunar iconview {{ padding: 22px 18px; }}
    .thunar iconview:selected, .thunar .view:selected:not(treeview) {{ background-color: {rgba(p['accent'], 0.24)}; color: {p['text']}; border-radius: {12 if name == 'xianxia' else 6}px; }}
    .thunar .sidebar, .thunar .sidebar treeview.view, .thunar .shortcuts-pane {{ background-color: {rgba(p['mantle'], 0.20)}; }}
    .thunar .sidebar treeview.view {{ padding: 5px 10px; color: {p['subtext']}; }}
    .thunar .sidebar treeview.view:selected {{ background-color: {rgba(p['accent'], 0.12)}; background-image: linear-gradient({p['accent']}, {p['accent']});
        background-size: 2px 16px; background-position: left center; background-repeat: no-repeat; color: {p['text']}; border-radius: 0; border: none; }}
    .thunar .sidebar treeview.view:hover {{ background-color: {rgba(p['text'], 0.05)}; border-radius: 0; }}
    .thunar toolbar, .thunar .toolbar {{ background-color: transparent; border-bottom: 1px solid {rgba(p['accent2'], 0.22)}; padding: 8px 12px; }}
    .thunar toolbar button, .thunar button {{ border-radius: {12 if name == 'xianxia' else 6}px; background: transparent; border: none; box-shadow: none; color: {p['subtext']}; -gtk-icon-shadow: none; }}
    .thunar toolbar button:hover, .thunar button:hover {{ background-color: {rgba(p['text'], 0.07)}; color: {p['text']}; }}
    .thunar entry {{ border-radius: 0; background-color: transparent; border: none; border-bottom: 1px solid {rgba(p['accent2'], 0.40)}; color: {p['text']}; padding: 5px 6px; box-shadow: none; caret-color: {p['accent2']}; }}
    .thunar statusbar, .thunar .statusbar {{ background-color: transparent; color: {rgba(p['subtext'], 0.8)}; font-size: 9pt; border: none; }}
    .thunar paned > separator {{ background-color: {rgba(p['accent2'], 0.45)}; background-image: none; min-width: 1px; }}
    scrollbar, scrollbar trough {{ background: transparent; border: none; }}
    scrollbar slider {{ background-color: {rgba(p['accent2'], 0.35)}; border-radius: 99px; min-width: 3px; min-height: 3px; border: none; }}
    scrollbar slider:hover {{ background-color: {rgba(p['accent2'], 0.6)}; }}
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
    """))
    W(f"{H}/.config/gtk-4.0/settings.ini", textwrap.dedent(f"""\
    [Settings]
    gtk-icon-theme-name={T['icons']}
    gtk-cursor-theme-name={T['cursor']}
    gtk-cursor-theme-size=24
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=1
    gtk-decoration-layout=:
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
    kv_svg, kv_conf = tenka_kvantum.build(name, T)
    W(f"{H}/.config/Kvantum/{T['gtk']}/{T['gtk']}.svg", kv_svg)
    W(f"{H}/.config/Kvantum/{T['gtk']}/{T['gtk']}.kvconfig", kv_conf)
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
    }
    newtab_vars = {"--newtab-background-color": fx['bar'], "--newtab-background-color-secondary": fx['tab'],
                   "--newtab-text-primary-color": fx['text'], "--newtab-text-secondary-color": fx['sub'],
                   "--newtab-element-hover-color": fx['hov'], "--newtab-primary-action-background": fx['acc'],
                   "--newtab-border-color": fx['line'], "--newtab-textbox-background-color": fx['tab']}
    vblock = lambda d: "\n".join(f"    {k}: {v} !important;" for k, v in d.items())
    W(f"{H}/.config/tenka/firefox.css", f"""/* Tenka {T['display']}: Firefox chrome + new tab. Generated by scripts/gen-themes.py; flat, no glow. */
@-moz-document url("chrome://browser/content/browser.xhtml") {{
  :root, :root:-moz-lwtheme, #navigator-toolbox, #titlebar, toolbar, #nav-bar, #TabsToolbar, #PersonalToolbar, #urlbar, panel {{
{vblock(chrome_vars)}
  }}
  #navigator-toolbox, #titlebar, #TabsToolbar {{ background-color: {fx['bg']} !important; background-image: none !important; color: {fx['text']} !important; }}
  #nav-bar, #PersonalToolbar, #FindToolbar, findbar {{ background-color: {fx['bar']} !important; background-image: none !important; color: {fx['text']} !important; }}
  #urlbar-background, #searchbar {{ background-color: {fx['field']} !important; }}
  #urlbar[focused] > #urlbar-background {{ background-color: {fx['bg']} !important; outline: 1px solid {fx['acc']} !important; }}
  #navigator-toolbox {{ border-bottom: 1px solid {fx['line']} !important; }}
  .tab-background[selected] {{ background-color: {fx['tab']} !important; background-image: none !important; box-shadow: inset 0 -2px 0 {fx['acc']} !important; border-radius: {max(4, T['rounding'] - 4)}px !important; }}
  .tab-background {{ border-radius: {max(4, T['rounding'] - 4)}px !important; }}
  #urlbar-background {{ border-radius: {max(4, T['rounding'] - 4)}px !important; }}
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
        border = f'"{a(p["accent2"], "d9")}"'
        inactive = a(p["text"], "14")
        # ledger corners: Tenka's windows are nearly square like the desk sheet and the control center
        # (a blade edge), Tianxia keeps a little more softness (mist)
        bsize, rnd, rpow = 1, (6 if name == "samurai" else 12), 2.5
        shadow = "0x66000000"
        curves = [("emphasizedDecel", (0.05, 0.7), (0.1, 1)), ("emphasizedAccel", (0.3, 0), (0.8, 0.15)),
                  ("standard", (0.2, 0), (0, 1)), ("menuDecel", (0.1, 1), (0, 1)), ("menuAccel", (0.52, 0.03), (0.72, 0.08))]
        if name == "samurai":
            anims = [("windowsIn", 4, "emphasizedDecel", "popin 92%"), ("windowsOut", 3, "emphasizedAccel", "popin 95%"),
                     ("windowsMove", 5, "emphasizedDecel", "slide"), ("border", 8, "standard", None), ("fade", 4, "standard", None),
                     ("fadeLayersIn", 4, "menuDecel", None), ("fadeLayersOut", 3, "menuAccel", None),
                     ("layersIn", 4, "emphasizedDecel", "slide"), ("layersOut", 3, "emphasizedAccel", "slide"),
                     ("workspaces", 5, "emphasizedDecel", "slide"), ("specialWorkspace", 5, "emphasizedDecel", "slidevert")]
        else:
            anims = [("windowsIn", 6, "emphasizedDecel", "popin 86%"), ("windowsOut", 5, "emphasizedAccel", "popin 92%"),
                     ("windowsMove", 6, "emphasizedDecel", "slide"), ("border", 10, "standard", None), ("fade", 6, "standard", None),
                     ("fadeLayersIn", 6, "menuDecel", None), ("fadeLayersOut", 4, "menuAccel", None),
                     ("layersIn", 6, "emphasizedDecel", "slide"), ("layersOut", 4, "emphasizedAccel", "slide"),
                     ("workspaces", 7, "emphasizedDecel", "slidefadevert 15%"), ("specialWorkspace", 7, "emphasizedDecel", "slidefadevert 20%")]
        extra_general = ["        border_size = 1,", "        gaps_in = 7,", "        gaps_out = 16,", "        gaps_workspaces = 50,"]
        extra_deco = ["        rounding_power = 2.5,", "        dim_inactive = true,", "        dim_strength = 0.05,"]
        shadow_extra = ["            range = 28,", "            render_power = 3,", '            offset = "0 6",']
    else:
        inactive = a(p["overlay"], "aa"); bsize, rnd = T["border"], T["rounding"]
        extra_general, extra_deco, shadow_extra = [], [], []
    lua = [f"-- generated by scripts/gen-themes.py\n-- {note}", "local T = {}",
           "T.name = " + json.dumps(name), "T.display = " + json.dumps(T["display"]), "T.cursor = " + json.dumps(T["cursor"]),
           "T.c = {" + ", ".join(f'{k} = "{v}"' for k, v in p.items()) + "}", "",
           "hl.config({", "    general = {", *extra_general, "        col = {", f"            active_border   = {border},",
           f'            inactive_border = "{inactive}",', "        },", "    },",
           "    decoration = {", f"        rounding = {rnd},", *extra_deco, "        shadow = {", f"            color = {shadow},",
           *shadow_extra, "            color_inactive = 0x33000000,", "        },", "    },", "})", ""]
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
