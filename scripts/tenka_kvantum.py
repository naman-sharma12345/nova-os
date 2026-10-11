#!/usr/bin/env python3
"""Tenka Kvantum theme: one flat SVG + kvconfig per palette (called by gen-themes.py).

Every Qt app (polkit prompt, installer, Kvantum preview, qt6ct) draws its widgets from
this. Flat ink: no gradients, no glow, 1 px borders, accent only where it means something.
"""
S = 12          # length of side/interior cells (Kvantum stretches them)

def _hx(c): return c.lstrip("#")
def _mix(a, b, t):
    a, b = _hx(a), _hx(b)
    return "#" + "".join(f"{round(int(a[i:i+2],16)*(1-t)+int(b[i:i+2],16)*t):02x}" for i in (0, 2, 4))

class _Svg:
    def __init__(self): self.parts, self.x, self.y, self.row = [], 0, 0, 0
    def at(self, w, h):
        if self.x + w > 1200: self.x, self.y, self.row = 0, self.y + self.row + 4, 0
        o = (self.x, self.y); self.x += w + 4; self.row = max(self.row, h); return o
    def g(self, id_, body): self.parts.append(f'<g id="{id_}">{body}</g>')
    def done(self):
        H = self.y + self.row + 4
        return (f'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1200" height="{H}" viewBox="0 0 1200 {H}">\n'
                + "\n".join(self.parts) + "\n</svg>\n")

def _paint(c):
    if c is None: return 'fill="#000000" fill-opacity="0"'
    col, op = c if isinstance(c, tuple) else (c, 1)
    return f'fill="{col}"' + (f' fill-opacity="{op}"' if op < 1 else "")

def _f(v): return f"{v:.2f}".rstrip("0").rstrip(".")

def box(sv, el, state, fill, border=None, R=4, b=1, sides=None):
    """9-slice element set `el-state[-side]`. border: colour or None; sides: per-side border override."""
    sides = sides or {}
    bc = {k: sides.get(k, border) for k in ("top", "bottom", "left", "right")}
    name = f"{el}-{state}"
    ox, oy = sv.at(S, S); sv.g(name, f'<rect x="{ox}" y="{oy}" width="{S}" height="{S}" {_paint(fill)}/>')
    for side in ("top", "bottom", "left", "right"):
        w, h = (S, R) if side in ("top", "bottom") else (R, S)
        ox, oy = sv.at(w, h); c = bc[side]; bw = b if side not in sides else sides.get(side + "_w", b)
        if c is None:
            body = f'<rect x="{ox}" y="{oy}" width="{w}" height="{h}" {_paint(fill)}/>'
        else:
            if side == "top":    fr, br = (ox, oy + bw, w, h - bw), (ox, oy, w, bw)
            elif side == "bottom": fr, br = (ox, oy, w, h - bw), (ox, oy + h - bw, w, bw)
            elif side == "left": fr, br = (ox + bw, oy, w - bw, h), (ox, oy, bw, h)
            else:                fr, br = (ox, oy, w - bw, h), (ox + w - bw, oy, bw, h)
            body = (f'<rect x="{_f(fr[0])}" y="{_f(fr[1])}" width="{_f(fr[2])}" height="{_f(fr[3])}" {_paint(fill)}/>'
                    f'<rect x="{_f(br[0])}" y="{_f(br[1])}" width="{_f(br[2])}" height="{_f(br[3])}" {_paint(c)}/>')
        sv.g(f"{name}-{side}", body)
    for corner, sx, sy, vs, hs in (("topleft", -1, -1, "top", "left"), ("topright", 1, -1, "top", "right"),
                                   ("bottomleft", -1, 1, "bottom", "left"), ("bottomright", 1, 1, "bottom", "right")):
        ox, oy = sv.at(R, R)
        cx, cy = ox + (R if sx < 0 else 0), oy + (R if sy < 0 else 0)
        sw = 0 if sx * sy > 0 else 1
        c = bc[vs] if bc[vs] is not None and bc[vs] == bc[hs] else None
        r = R - b if c is not None else R
        def arc(rad, s, a, bpt):
            return f"A {_f(rad)} {_f(rad)} 0 0 {s} {_f(bpt[0])} {_f(bpt[1])}"
        p1, p2 = (cx, cy + sy * r), (cx + sx * r, cy)
        body = f'<path d="M {_f(cx)} {_f(cy)} L {_f(p1[0])} {_f(p1[1])} {arc(r, sw, p1, p2)} Z" {_paint(fill)}/>'
        if c is not None:
            q1, q2 = (cx, cy + sy * R), (cx + sx * R, cy)
            body += (f'<path d="M {_f(q1[0])} {_f(q1[1])} {arc(R, sw, q1, q2)} L {_f(p2[0])} {_f(p2[1])} '
                     f'{arc(r, 1 - sw, p2, p1)} Z" {_paint(c)}/>')
        elif bc[vs] is not None or bc[hs] is not None:
            # mixed sides (tab underline): square corner carrying the one border it touches
            body = f'<rect x="{ox}" y="{oy}" width="{R}" height="{R}" {_paint(fill)}/>'
            for s_, cc in ((vs, bc[vs]), (hs, bc[hs])):
                if cc is None: continue
                bw = sides.get(s_ + "_w", b)
                if s_ == "top": body += f'<rect x="{ox}" y="{oy}" width="{R}" height="{bw}" {_paint(cc)}/>'
                if s_ == "bottom": body += f'<rect x="{ox}" y="{oy + R - bw}" width="{R}" height="{bw}" {_paint(cc)}/>'
                if s_ == "left": body += f'<rect x="{ox}" y="{oy}" width="{bw}" height="{R}" {_paint(cc)}/>'
                if s_ == "right": body += f'<rect x="{ox + R - bw}" y="{oy}" width="{bw}" height="{R}" {_paint(cc)}/>'
        # keep the cell's full bounds even where the quarter disc leaves it empty
        body = f'<rect x="{ox}" y="{oy}" width="{R}" height="{R}" {_paint(None)}/>' + body
        sv.g(f"{name}-{corner}", body)

def icon(sv, id_, w, h, body_fn):
    ox, oy = sv.at(w, h)
    sv.g(id_, f'<rect x="{ox}" y="{oy}" width="{w}" height="{h}" {_paint(None)}/>' + body_fn(ox, oy))

def chevron(d, col, sw=1.6):
    pts = {"down": "2,3.5 5,6.5 8,3.5", "up": "2,6.5 5,3.5 8,6.5",
           "right": "3.5,2 6.5,5 3.5,8", "left": "6.5,2 3.5,5 6.5,8"}[d]
    def f(ox, oy):
        p = " ".join(f"{float(a)+ox:g},{float(b)+oy:g}" for a, b in (q.split(",") for q in pts.split()))
        return f'<polyline points="{p}" fill="none" stroke="{col}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/>'
    return f

def build(name, T):
    p = T["p"]
    R = 6 if name == "samurai" else 8          # Xianxia is the softer, rounder pack
    base, mantle, surf, ovl, text, sub, acc = p["base"], p["mantle"], p["surface"], p["overlay"], p["text"], p["subtext"], p["accent"]
    hover = _mix(surf, ovl, .55)
    sel = _mix(surf, acc, .30)
    acc_soft = _mix(surf, acc, .18)
    line = _mix(ovl, text, .08)
    sv = _Svg()
    # buttons, combos, spin boxes
    box(sv, "button", "normal", surf, line, R)
    box(sv, "button", "focused", hover, _mix(line, acc, .45), R)
    box(sv, "button", "pressed", ovl, acc, R)
    box(sv, "button", "toggled", acc_soft, acc, R)
    box(sv, "button", "disabled", (surf, .5), (line, .5), R)
    # tool buttons: flat until touched
    box(sv, "tbutton", "normal", None, None, R)
    box(sv, "tbutton", "focused", hover, None, R)
    box(sv, "tbutton", "pressed", ovl, None, R)
    box(sv, "tbutton", "toggled", acc_soft, None, R)
    box(sv, "tbutton", "disabled", None, None, R)
    # text fields
    box(sv, "lineedit", "normal", mantle, line, R)
    box(sv, "lineedit", "focused", mantle, acc, R)
    box(sv, "lineedit", "disabled", (mantle, .5), (line, .5), R)
    # frames
    box(sv, "common", "normal", None, line, R)
    box(sv, "common", "focused", None, acc, R)
    box(sv, "group", "normal", (surf, .45), line, R)
    box(sv, "tabframe", "normal", _mix(base, surf, .5), line, R)
    box(sv, "tooltip", "normal", mantle, line, R)
    box(sv, "menu", "normal", mantle, line, R)
    box(sv, "header", "normal", mantle, None, 3, sides={"bottom": line})
    box(sv, "header", "focused", hover, None, 3, sides={"bottom": line})
    box(sv, "header", "pressed", ovl, None, 3, sides={"bottom": acc})
    box(sv, "header", "toggled", mantle, None, 3, sides={"bottom": acc})
    box(sv, "toolbar", "normal", None, None, 2)
    # tabs: flat, the current one is underlined in the accent
    box(sv, "tab", "normal", None, None, 3)
    box(sv, "tab", "focused", (hover, .6), None, 3)
    box(sv, "tab", "toggled", _mix(base, surf, .5), None, 3, sides={"bottom": acc, "bottom_w": 2})
    box(sv, "tab", "pressed", _mix(base, surf, .5), None, 3, sides={"bottom": acc, "bottom_w": 2})
    # lists and menus
    for el in ("itemview", "menuitem", "menubaritem"):
        box(sv, el, "normal", None, None, R - 2)
        box(sv, el, "focused", (ovl, .7), None, R - 2)
        box(sv, el, "pressed", sel, None, R - 2)
        box(sv, el, "toggled", sel, None, R - 2)
        box(sv, el, "disabled", None, None, R - 2)
    # scrollbars, sliders, progress
    box(sv, "scrollbargroove", "normal", None, None, 3)
    box(sv, "scrollbarslider", "normal", ovl, None, 3)
    box(sv, "scrollbarslider", "focused", _mix(ovl, sub, .35), None, 3)
    box(sv, "scrollbarslider", "pressed", acc, None, 3)
    box(sv, "scrollbarslider", "disabled", (ovl, .4), None, 3)
    box(sv, "slider", "normal", ovl, None, 2)
    box(sv, "slider", "toggled", acc, None, 2)
    box(sv, "slider", "disabled", (ovl, .5), None, 2)
    box(sv, "progress", "normal", ovl, None, 2)
    box(sv, "progress-pattern", "normal", acc, None, 2)
    box(sv, "progress-pattern", "disabled", (acc, .4), None, 2)
    # indicators
    for st, col in (("normal", sub), ("focused", text), ("pressed", acc), ("toggled", text), ("disabled", (ovl))):
        for d in ("up", "down", "left", "right"):
            icon(sv, f"arrow-{d}-{st}", 10, 10, chevron(d, col))
        icon(sv, f"arrow-plus-{st}", 10, 10, chevron("right", col))
        icon(sv, f"arrow-minus-{st}", 10, 10, chevron("down", col))
        icon(sv, f"menuitem-{st}", 10, 10, chevron("right", col))
        icon(sv, f"arrow-down-{st}-arrow", 10, 10, chevron("down", col))
    def cb(fillc, edge, mark=None):
        def f(ox, oy):
            s = (f'<rect x="{ox+1}" y="{oy+1}" width="14" height="14" rx="3.5" ry="3.5" fill="{fillc}" '
                 f'stroke="{edge}" stroke-width="1"/>')
            if mark == "check":
                s += (f'<polyline points="{ox+4.5},{oy+8.3} {ox+7},{oy+10.8} {ox+11.5},{oy+5.5}" fill="none" stroke="{base}" '
                      f'stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>')
            if mark == "dash":
                s += f'<rect x="{ox+4.5}" y="{oy+7.2}" width="7" height="1.8" rx="0.9" fill="{base}"/>'
            return s
        return f
    def rb(fillc, edge, dot=False):
        def f(ox, oy):
            s = f'<circle cx="{ox+8}" cy="{oy+8}" r="7" fill="{fillc}" stroke="{edge}" stroke-width="1"/>'
            if dot: s += f'<circle cx="{ox+8}" cy="{oy+8}" r="3" fill="{base}"/>'
            return s
        return f
    for st, edge in (("normal", line), ("focused", acc), ("pressed", acc), ("disabled", ovl)):
        f = mantle if st != "disabled" else base
        icon(sv, f"checkbox-{st}", 16, 16, cb(f, edge))
        icon(sv, f"checkbox-checked-{st}", 16, 16, cb(acc if st != "disabled" else ovl, acc if st != "disabled" else ovl, "check"))
        icon(sv, f"checkbox-tristate-{st}", 16, 16, cb(acc if st != "disabled" else ovl, acc if st != "disabled" else ovl, "dash"))
        icon(sv, f"radio-{st}", 16, 16, rb(f, edge))
        icon(sv, f"radio-checked-{st}", 16, 16, rb(acc if st != "disabled" else ovl, acc if st != "disabled" else ovl, True))
        icon(sv, f"item-checkbox-{st}", 16, 16, cb(f, edge))
    for st, col in (("normal", text), ("focused", _mix(text, acc, .25)), ("pressed", acc), ("disabled", ovl)):
        icon(sv, f"slidercursor-{st}", 16, 16, lambda ox, oy, c=col: f'<circle cx="{ox+8}" cy="{oy+8}" r="7" fill="{c}" stroke="{base}" stroke-width="1"/>')
    for gid, n in (("grip", 3), ("splitter-grip", 3), ("toolbar-handle", 3)):
        for st in ("normal", "focused", "pressed"):
            col = acc if st == "pressed" else (sub if st == "focused" else ovl)
            icon(sv, f"{gid}-{st}" if gid != "toolbar-handle" else gid, 9, 9,
                 lambda ox, oy, c=col: "".join(f'<circle cx="{ox+4.5}" cy="{oy+1.5+i*3}" r="1" fill="{c}"/>' for i in range(3)))
            if gid == "toolbar-handle": break
    for st in ("normal", "focused"):
        icon(sv, f"resize-grip-{st}", 12, 12, lambda ox, oy: "".join(
            f'<circle cx="{ox+x}" cy="{oy+y}" r="0.9" fill="{ovl}"/>' for x, y in ((10, 10), (6, 10), (10, 6), (2, 10), (6, 6), (10, 2))))
    for st, col in (("normal", sub), ("focused", acc), ("pressed", acc), ("toggled", acc), ("disabled", ovl)):
        x = lambda ox, oy, c=col: (f'<path d="M {ox+3} {oy+3} L {ox+9} {oy+9} M {ox+9} {oy+3} L {ox+3} {oy+9}" '
                                   f'stroke="{c}" stroke-width="1.5" stroke-linecap="round" fill="none"/>')
        icon(sv, f"tab-close-{st}", 12, 12, x)
    # dial: a flat ring and a dot, never the stock glossy knob
    for suf, ring, dot in (("", line, acc), ("-inactive", ovl, ovl)):
        icon(sv, f"dial{suf}", 40, 40, lambda ox, oy, r_=ring: f'<circle cx="{ox+20}" cy="{oy+20}" r="19" fill="{surf}" stroke="{r_}" stroke-width="1"/>')
        icon(sv, f"dial-handle{suf}", 8, 8, lambda ox, oy, d_=dot: f'<circle cx="{ox+4}" cy="{oy+4}" r="3.5" fill="{d_}"/>')
    # Kvantum paints the notches as one image over the whole dial: a ring of short ticks
    import math
    icon(sv, "dial-notches", 40, 40, lambda ox, oy: "".join(
        f'<line x1="{ox+20+19*math.cos(a):.2f}" y1="{oy+20+19*math.sin(a):.2f}" x2="{ox+20+16.5*math.cos(a):.2f}" '
        f'y2="{oy+20+16.5*math.sin(a):.2f}" stroke="{ovl}" stroke-width="1" stroke-linecap="round"/>'
        for a in (math.radians(120 + i * 25) for i in range(13))))
    svg = sv.done()

    hl = _mix(acc, base, .35)
    disp = name.capitalize()
    kv = f"""[%General]
author=Tenka (generated by scripts/gen-themes.py)
comment=Tenka {disp}: flat ink, one accent, no glow
x11drag=menubar_and_primary_toolbar
alt_mnemonic=true
left_tabs=false
attach_active_tab=false
group_toolbar_buttons=false
spread_progressbar=true
progressbar_thickness=4
composite=true
translucent_windows=false
blurring=false
popup_blurring=false
menu_shadow_depth=0
tooltip_shadow_depth=0
spread_menuitems=true
menu_separator_height=7
splitter_width=7
scroll_width=8
scroll_min_extent=40
scroll_arrows=false
transient_scrollbar=true
transient_groove=true
combo_as_lineedit=true
combo_menu=true
inline_spin_indicators=true
vertical_spin_indicators=false
slider_width=4
slider_handle_width=16
slider_handle_length=16
check_size=16
tooltip_delay=600
toolbar_icon_size=22
small_icon_size=16
large_icon_size=32
button_icon_size=16
layout_spacing=6
layout_margin=8
dark_titlebar=true
animate_states=true
no_inactiveness=true
reduce_window_opacity=0
reduce_menu_opacity=0
fill_rubberband=false
menubar_mouse_tracking=true
respect_DE=false
click_behavior=1
submenu_overlap=0
shadowless_popup=true

[GeneralColors]
window.color={base}
base.color={mantle}
alt.base.color={_mix(mantle, surf, .5)}
button.color={surf}
light.color={_mix(ovl, text, .12)}
mid.light.color={ovl}
dark.color={mantle}
mid.color={_mix(surf, ovl, .5)}
highlight.color={hl}
inactive.highlight.color={_mix(hl, base, .3)}
tooltip.base.color={mantle}
text.color={text}
window.text.color={text}
button.text.color={text}
disabled.text.color={_mix(sub, base, .45)}
tooltip.text.color={text}
highlight.text.color={text}
link.color={p['accent2']}
link.visited.color={p['soft']}
progress.indicator.text.color={text}

[Hacks]
transparent_dolphin_view=false
blur_konsole=false
transparent_ktitle_label=true
respect_darkness=true
force_size_grip=false
tint_on_mouseover=0
no_selection_tint=true
centered_forms=false
kcapacitybar_as_progressbar=true
iconless_pushbutton=false
iconless_menu=false
disabled_icon_opacity=60
lxqtmainmenu_iconsize=22
normal_default_pushbutton=true
transparent_menutitle=true
middle_click_scroll=false
scroll_jump_workaround=true

[PanelButtonCommand]
frame=true
frame.element=button
frame.top={R}
frame.bottom={R}
frame.left={R}
frame.right={R}
interior=true
interior.element=button
indicator.size=10
indicator.element=arrow
text.normal.color={text}
text.focus.color={text}
text.press.color={text}
text.toggle.color={text}
text.disabled.color={_mix(sub, base, .45)}
text.shadow=0
text.margin=1
text.iconspacing=6
text.margin.left=10
text.margin.right=10
text.margin.top=4
text.margin.bottom=4
min_width=+0.3font
min_height=+0.3font
frame.expansion=0

[PanelButtonTool]
inherits=PanelButtonCommand
frame.element=tbutton
interior.element=tbutton
text.margin.left=6
text.margin.right=6

[ToolbarButton]
inherits=PanelButtonTool

[Dock]
inherits=PanelButtonCommand
frame=false
interior=false

[DockTitle]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={sub}
text.focus.color={text}
text.bold=false

[IndicatorSpinBox]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=arrow
indicator.size=10

[RadioButton]
inherits=PanelButtonCommand
frame=false
interior.element=radio
text.margin.left=4
text.margin.right=4

[CheckBox]
inherits=PanelButtonCommand
frame=false
interior.element=checkbox
text.margin.left=4
text.margin.right=4

[Focus]
inherits=PanelButtonCommand
frame=false
interior=false

[GenericFrame]
inherits=PanelButtonCommand
frame=true
interior=false
frame.element=common
interior.element=common
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1

[LineEdit]
inherits=PanelButtonCommand
frame.element=lineedit
interior.element=lineedit
text.margin.left=8
text.margin.right=8

[DropDownButton]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=arrow
indicator.size=10

[IndicatorArrow]
indicator.element=arrow
indicator.size=10

[ToolboxTab]
inherits=PanelButtonCommand

[Tab]
inherits=PanelButtonCommand
frame.element=tab
interior.element=tab
indicator.element=tab-close
indicator.size=12
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
text.normal.color={sub}
text.focus.color={text}
text.toggle.color={text}
text.press.color={text}
text.margin.left=14
text.margin.right=14
text.margin.top=6
text.margin.bottom=6

[TabFrame]
inherits=PanelButtonCommand
frame.element=tabframe
interior.element=tabframe
interior=true

[TabBarFrame]
inherits=GenericFrame
frame=false
interior=false

[TreeExpander]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=arrow
indicator.size=10

[HeaderSection]
inherits=PanelButtonCommand
frame.element=header
interior.element=header
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
text.normal.color={sub}
text.focus.color={text}
text.press.color={text}
text.toggle.color={text}

[SizeGrip]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=resize-grip
indicator.size=12

[Toolbar]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=toolbar-handle
indicator.size=9

[Slider]
inherits=PanelButtonCommand
frame.element=slider
interior.element=slider
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2

[SliderCursor]
inherits=PanelButtonCommand
frame=false
interior.element=slidercursor

[Progressbar]
inherits=PanelButtonCommand
frame.element=progress
interior.element=progress
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.normal.color={sub}
text.focus.color={text}
text.press.color={text}
text.toggle.color={text}

[ProgressbarContents]
inherits=PanelButtonCommand
frame.element=progress-pattern
interior.element=progress-pattern
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2

[ItemView]
inherits=PanelButtonCommand
frame.element=itemview
interior.element=itemview
frame.top={R-2}
frame.bottom={R-2}
frame.left={R-2}
frame.right={R-2}
text.margin.top=3
text.margin.bottom=3
text.margin.left=6
text.margin.right=6
text.toggle.color={text}
text.press.color={text}

[Splitter]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=splitter-grip
indicator.size=9

[Scrollbar]
inherits=PanelButtonCommand
indicator.element=arrow
indicator.size=10

[ScrollbarSlider]
inherits=PanelButtonCommand
frame.element=scrollbarslider
interior.element=scrollbarslider
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
indicator.element=grip
indicator.size=0

[ScrollbarTransientSlider]
inherits=ScrollbarSlider

[ScrollbarGroove]
inherits=PanelButtonCommand
frame.element=scrollbargroove
interior.element=scrollbargroove
frame=false
interior=false

[MenuItem]
inherits=PanelButtonCommand
frame.element=menuitem
interior.element=menuitem
indicator.element=menuitem
frame.top={R-2}
frame.bottom={R-2}
frame.left={R-2}
frame.right={R-2}
text.margin.top=4
text.margin.bottom=4
text.margin.left=8
text.margin.right=8
text.focus.color={text}
text.press.color={text}
text.toggle.color={text}

[MenuBar]
inherits=PanelButtonCommand
frame=false
interior=false

[MenuBarItem]
inherits=PanelButtonCommand
frame.element=menubaritem
interior.element=menubaritem
frame.top={R-2}
frame.bottom={R-2}
frame.left={R-2}
frame.right={R-2}
text.margin.left=8
text.margin.right=8

[TitleBar]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={sub}
text.focus.color={text}

[ComboBox]
inherits=PanelButtonCommand

[Menu]
inherits=PanelButtonCommand
frame.element=menu
interior.element=menu
frame.top={R}
frame.bottom={R}
frame.left={R}
frame.right={R}
text.normal.color={text}

[GroupBox]
inherits=GenericFrame
frame=true
frame.element=group
interior=false
frame.top={R}
frame.bottom={R}
frame.left={R}
frame.right={R}
text.normal.color={sub}
text.focus.color={text}

[ToolTip]
inherits=GenericFrame
frame=true
interior=true
frame.element=tooltip
interior.element=tooltip
frame.top={R}
frame.bottom={R}
frame.left={R}
frame.right={R}
text.margin.left=6
text.margin.right=6

[StatusBar]
inherits=GenericFrame
frame=false
interior=false

[Window]
interior=false
frame=false
"""
    return svg, kv
