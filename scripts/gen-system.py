#!/usr/bin/env python3
"""Tenka system-theme generator: boot menu (GRUB), boot splash (Plymouth), login (SDDM),
installer (Calamares) for both theme packs. Needs Pillow; grub-mkfont for GRUB fonts.

    python3 scripts/gen-system.py
"""
import os, sys, shutil, subprocess, json, textwrap, glob
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib.util
spec = importlib.util.spec_from_file_location("gt", os.path.join(os.path.dirname(os.path.abspath(__file__)), "gen-themes.py"))
gt = importlib.util.module_from_spec(spec); spec.loader.exec_module(gt)
ROOT = gt.ROOT
IC = os.path.join(ROOT, "live/config/includes.chroot")
FONTS = os.path.join(IC, "usr/share/fonts/truetype/tenka")
VERSION = "0.1"

BG = {"samurai": "02-torii-night.jpg", "xianxia": "01-floating-peaks.jpg"}
# one painting per installer slide, darker scenes so the ledger text always reads
SLIDE_BG = {"samurai": ["00-title-card.jpg", "14-pagoda-moon.jpg", "09-bamboo-moon.jpg", "01-fuji-sumie.jpg"],
            "xianxia": ["00-desktop.jpg", "13-heaven-gate.jpg", "07-golden-dragon.jpg", "14-cloud-sea-cultivator.jpg"]}
DISPLAY_TTF = {"samurai": os.path.join(FONTS, "CormorantGaramond[wght].ttf"), "xianxia": os.path.join(FONTS, "Cinzel[wght].ttf")}
WORDS = {
  "samurai": dict(enter="Enter the dojo", fail="The gate stays closed. Try again.", suspend="Rest", reboot="Return", shutdown="Sheathe",
                  footer="TENKA  ·  THE WAY OF THE BLADE", italic="false",
                  slides=[("Tenka", "A desktop forged with intent: every edge, every motion, every colour drawn from sumi ink and vermilion."),
                          ("Two paths", "Switch to Tianxia at any time with Super + T. The desk, the boot and the login all follow."),
                          ("The way of the keys", "Super + Space to seek, Super + Return for the terminal, Super + Escape to rest or retreat.",
                           [("Super", "Space", "seek"), ("Super", "Return", "the terminal"), ("Super", "Escape", "rest or retreat")]),
                          ("Nearly there", "Your system is being set down on the disk. Breathe.")]),
  "xianxia": dict(enter="Step onto the path", fail="The formation rejects you. Try again.", suspend="Meditate", reboot="Rebirth", shutdown="Ascend",
                  footer="TIANXIA  ·  THE PATH TO IMMORTALITY", italic="true",
                  slides=[("Tianxia", "All under heaven: jade mist, floating peaks and drifting qi, gathered into one desktop."),
                          ("Two paths", "Return to Tenka at any time with Super + T. The desk, the boot and the login all follow."),
                          ("The heavenly keys", "Super + Space to divine, Super + Return for the terminal, Super + Escape to ascend.",
                           [("Super", "Space", "divine"), ("Super", "Return", "the terminal"), ("Super", "Escape", "ascend")]),
                          ("Ascension is near", "Your cave abode is being carved into the disk. Be still.")]),
}

def W(path, data, mode=0o644):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb" if isinstance(data, bytes) else "w") as f: f.write(data)
    os.chmod(path, mode)

def hexrgb(c): c = c.lstrip("#"); return tuple(int(c[i:i+2], 16) for i in (0, 2, 4))

def wordmark(name, T, size, path, spacing=0.18, sub=None):
    """Flat letters and an italic line under them; no coloured halo (Naman: no neon, no glow)."""
    p = T["p"]
    f = ImageFont.truetype(DISPLAY_TTF[name], size)
    if name == "xianxia":
        try: f.set_variation_by_axes([600])
        except Exception: pass
    text = T["display"].upper()
    sp = int(size * spacing)
    widths = [f.getbbox(ch)[2] - f.getbbox(ch)[0] if ch.strip() else size // 3 for ch in text]
    tw = sum(widths) + sp * (len(text) - 1)
    fs = ImageFont.truetype(os.path.join(FONTS, "CormorantGaramond-Italic[wght].ttf"), int(size * 0.36)) if sub else None
    sw = (fs.getbbox(sub)[2] if sub else 0)
    w, h = max(tw, sw) + size, int(size * (2.0 if sub else 1.5))
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    x = (w - tw) // 2
    for ch, cw in zip(text, widths):
        d.text((x - f.getbbox(ch)[0], int(size * 0.12)), ch, font=f, fill=hexrgb(p["text"]) + (255,)); x += cw + sp
    if sub:
        d.text(((w - sw) // 2, int(size * 1.32)), sub, font=fs, fill=hexrgb(p["accent2"]) + (235,))
    im.save(path)
    return im

def crest(name, px):
    src = os.path.join(ROOT, "themes", name, "crest-1024.png")
    if os.path.exists(src):
        return Image.open(src).convert("RGBA").resize((px, px), Image.LANCZOS)
    im = Image.new("RGBA", (px, px), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c = hexrgb(gt.THEMES[name]["p"]["accent"])
    d.ellipse((px * .08, px * .08, px * .92, px * .92), outline=c + (255,), width=max(2, px // 18))
    return im

def divider(name, w, h):
    src = os.path.join(ROOT, "themes", name, "textures", "divider.svg")
    out = f"/tmp/tenka-divider-{name}.png"
    if os.path.exists(src) and shutil.which("rsvg-convert"):
        subprocess.run(["rsvg-convert", "-w", str(w), "-h", str(h), "-a", src, "-o", out], check=False)
        if os.path.exists(out): return Image.open(out).convert("RGBA")
    p = gt.THEMES[name]["p"]
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for i in range(w):
        a = int(255 * (1 - abs(i - w / 2) / (w / 2)) ** 1.5)
        d.line((i, h // 2, i, h // 2 + 1), fill=hexrgb(p["accent2"]) + (a,))
    return im

def bg_image(name, size, darken=0.55, blur=0, file=None):
    if name == "xianxia": darken *= 0.72
    im = Image.open(os.path.join(ROOT, "themes", name, "wallpapers", file or BG[name])).convert("RGB")
    sw, sh = size; r = max(sw / im.width, sh / im.height)   # cover, centre crop: never squash the painting
    im = im.resize((round(im.width * r), round(im.height * r)), Image.LANCZOS)
    l, t = (im.width - sw) // 2, (im.height - sh) // 2; im = im.crop((l, t, l + sw, t + sh))
    if blur: im = im.filter(ImageFilter.GaussianBlur(blur))
    return ImageEnhance.Brightness(im).enhance(darken)

# ------------------------------------------------------------------ SDDM
def button(name, T):
    """The login button: a vermilion dry-brush stroke (Tenka) or a flat jade pill with a gold edge (Tianxia), at 2x. No glow."""
    import importlib.util as _u
    sp = _u.spec_from_file_location("tenka_art", os.path.join(os.path.dirname(os.path.abspath(__file__)), "tenka_art.py"))
    ta = _u.module_from_spec(sp); sp.loader.exec_module(ta)
    w, h = 752, 104
    if name == "samurai":
        a = ta.brush_stroke(w - 16, h - 8, seed=41, dry=0.35, head=0.025, tail=0.18, wave=0.03, ink=1.1)
        m = Image.new("L", (w, h), 0); m.paste(ta.mask_img(a), (8, 4))
        im = Image.new("RGBA", (w, h), ta.hexc(ta.PAL["samurai"]["acc"])[:3] + (0,)); im.putalpha(m)
        return im
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(im)   # flat: no blurred halo behind the pill
    d.rounded_rectangle((10, 10, w - 10, h - 10), radius=(h - 20) // 2, fill=ta.hexc("#5fc9a0", 235), outline=ta.hexc("#e2bd6b", 230), width=2)
    return im


def sddm(name, T):
    p, w = T["p"], T["words"]; X = WORDS[name]
    d = os.path.join(IC, f"usr/share/sddm/themes/tenka-{name}")
    os.makedirs(d, exist_ok=True)
    shutil.copy(os.path.join(ROOT, "scripts/sddm/Main.qml"), os.path.join(d, "Main.qml"))
    # background.png, enso.png and seal.png are the splash's own last frame: scripts/gen-plymouth.py writes them
    button(name, T).save(os.path.join(d, "button.png"))
    crest(name, 256).save(os.path.join(d, "crest.png"))
    divider(name, 600, 40).save(os.path.join(d, "divider.png"))
    disp = T["font_display"]
    W(os.path.join(d, "metadata.desktop"), textwrap.dedent(f"""\
    [SddmGreeterTheme]
    Name={T['display']}
    Description={T['display']}: {T['tagline']}
    Author=Tenka
    License=MIT
    Type=sddm-theme
    Version={VERSION}
    MainScript=Main.qml
    ConfigFile=theme.conf
    Theme-Id=tenka-{name}
    Theme-API=2.0
    QtVersion=6
    """))
    on_accent = p["base"] if name == "xianxia" else p["text"]
    W(os.path.join(d, "theme.conf"), textwrap.dedent(f"""\
    [General]
    # login face: title (the boot menu title screen, carried on), brush (the lock face) or card (v3)
    face=title
    pack={name}
    background=background.png
    enso=enso.png
    seal=seal.png
    crest=crest.png
    button=button.png
    displayName={T['display'].upper()}
    tagline={T['tagline']}
    displayFont=Marcellus
    brandFont=Cinzel Decorative
    greet={w['greet']}
    passwordHint={w['lock_ph']}
    enterText={X['enter']}
    failText={X['fail']}
    suspendText={X['suspend']}
    rebootText={X['reboot']}
    shutdownText={X['shutdown']}
    footer={X['footer']}
    italicTagline={X['italic']}
    radius={T['rounding'] + 8}
    base={p['base']}
    mantle={p['mantle']}
    text={p['text']}
    subtext={p['subtext']}
    accent={p['accent']}
    accent2={p['accent2']}
    onAccent={on_accent}
    gold={p['accent2']}
    glow={p['accent'] if name == 'xianxia' else p['accent2']}
    """))

# ------------------------------------------------------------------ Plymouth
PLY_SCRIPT = r"""// Tenka boot splash (generated by scripts/gen-system.py)
Window.SetBackgroundTopColor(@TOP@);
Window.SetBackgroundBottomColor(@BOT@);
W = Window.GetWidth(); H = Window.GetHeight();

bg = Image("background.png");
bgs = Sprite(bg.Scale(W, H)); bgs.SetZ(-10);

for (i = 0; i < 48; i++) {
  if (i < 10) n = "00" + i; else n = "0" + i;
  frames[i] = Image("frame-" + n + ".png");
}
anim = Sprite(frames[0]);
anim.SetX(W / 2 - frames[0].GetWidth() / 2);
anim.SetY(H / 2 - frames[0].GetHeight() / 2 - 70);

wm = Image("wordmark.png");
wms = Sprite(wm);
wms.SetX(W / 2 - wm.GetWidth() / 2);
wms.SetY(H / 2 + frames[0].GetHeight() / 2 - 40);
wms.SetOpacity(0);

track = Image("progress-track.png"); fillimg = Image("progress-fill.png");
ts = Sprite(track); ts.SetX(W / 2 - track.GetWidth() / 2); ts.SetY(H * 0.86); ts.SetOpacity(0.6);
fs = Sprite(); fs.SetX(W / 2 - track.GetWidth() / 2); fs.SetY(H * 0.86);

t = 0;
fun refresh() {
  t++;
  f = Math.Int(t / 2);
  if (@LOOP@) { f = f % 48; }
  else { if (f > 47) f = 36 + (f - 36) % 12; }
  anim.SetImage(frames[f]);
  o = t / 60; if (o > 1) o = 1; wms.SetOpacity(o);
}
Plymouth.SetRefreshFunction(refresh);

fun progress(duration, progress) {
  w = Math.Int(fillimg.GetWidth() * progress);
  if (w > 0) fs.SetImage(fillimg.Crop(0, 0, w, fillimg.GetHeight()));
}
Plymouth.SetBootProgressFunction(progress);

// password prompt (encrypted disks)
pmsg = Sprite(); pbul = Sprite();
fun pw_cb(prompt, bullets) {
  pmsg.SetImage(Image.Text(prompt, @TR@, @TG@, @TB@, 1, "Inter 14"));
  pmsg.SetX(W / 2 - pmsg.GetImage().GetWidth() / 2); pmsg.SetY(H * 0.74);
  s = ""; for (i = 0; i < bullets; i++) s += "•  ";
  pbul.SetImage(Image.Text(s, @AR@, @AG@, @AB@, 1, "Inter 18"));
  pbul.SetX(W / 2 - pbul.GetImage().GetWidth() / 2); pbul.SetY(H * 0.78);
}
Plymouth.SetDisplayPasswordFunction(pw_cb);
fun normal_cb() { pmsg.SetOpacity(0); pbul.SetOpacity(0); }
Plymouth.SetDisplayNormalFunction(normal_cb);
msg = Sprite();
fun message_cb(text) { msg.SetImage(Image.Text(text, @TR@, @TG@, @TB@, 0.7, "Inter 11")); msg.SetX(W / 2 - msg.GetImage().GetWidth() / 2); msg.SetY(H * 0.92); }
Plymouth.SetMessageFunction(message_cb);
"""

def plymouth(name, T):
    p = T["p"]
    d = os.path.join(IC, f"usr/share/plymouth/themes/tenka-{name}")
    os.makedirs(d, exist_ok=True)
    src = os.path.join(ROOT, "themes", name, "plymouth")
    frames = sorted(glob.glob(os.path.join(src, "frame-*.png")))
    for f in frames: shutil.copy(f, d)
    for f in ("progress-track.png", "progress-fill.png"):
        if os.path.exists(os.path.join(src, f)): shutil.copy(os.path.join(src, f), d)
    wordmark(name, T, 64, os.path.join(d, "wordmark.png"), sub=T["tagline"].lower())
    # very dark, blurred version of the theme's hero wallpaper
    bg_image(name, (1280, 720), darken=0.28, blur=18).save(os.path.join(d, "background.png"))
    f2 = lambda c: ", ".join(f"{v / 255:.3f}" for v in hexrgb(c))
    tr, tg, tb = (f"{v / 255:.3f}" for v in hexrgb(p["text"])); ar, ag, ab = (f"{v / 255:.3f}" for v in hexrgb(p["accent"]))
    s = (PLY_SCRIPT.replace("@TOP@", f2(p["base"])).replace("@BOT@", f2(p["mantle"])).replace("@LOOP@", "1" if name == "xianxia" else "0")
         .replace("@TR@", tr).replace("@TG@", tg).replace("@TB@", tb).replace("@AR@", ar).replace("@AG@", ag).replace("@AB@", ab))
    W(os.path.join(d, f"tenka-{name}.script"), s)
    W(os.path.join(d, f"tenka-{name}.plymouth"), textwrap.dedent(f"""\
    [Plymouth Theme]
    Name={T['display']}
    Description={T['display']}: {T['tagline']}
    ModuleName=script

    [script]
    ImageDir=/usr/share/plymouth/themes/tenka-{name}
    ScriptFile=/usr/share/plymouth/themes/tenka-{name}/tenka-{name}.script
    """))

# ------------------------------------------------------------------ GRUB
def grub_assets(name, T, d, live=False):
    p = T["p"]; os.makedirs(d, exist_ok=True)
    bg = bg_image(name, (1920, 1080), darken=0.62).convert("RGBA")
    # left-to-centre veil so the menu reads
    veil = Image.new("RGBA", bg.size, (0, 0, 0, 0)); vd = ImageDraw.Draw(veil)
    for y in range(1080):
        a = int(150 * max(0, (y - 380) / 700))
        vd.line((0, y, 1920, y), fill=(0, 0, 0, a))
    bg = Image.alpha_composite(bg, veil)
    c = crest(name, 150); bg.alpha_composite(c, (960 - 75, 150))
    wm = wordmark(name, T, 84, "/tmp/tenka-wm.png", sub=T["tagline"].lower())
    bg.alpha_composite(wm, (960 - wm.width // 2, 320))
    bg.convert("RGB").save(os.path.join(d, "background.png"))
    # selection pill (9-slice)
    def pill(fill, border):
        im = Image.new("RGBA", (40, 30), (0, 0, 0, 0)); dd = ImageDraw.Draw(im)
        dd.rounded_rectangle((0, 0, 39, 29), radius=10, fill=fill, outline=border, width=2)
        parts = {"nw": (0, 0, 12, 12), "n": (12, 0, 28, 12), "ne": (28, 0, 40, 12), "w": (0, 12, 12, 18), "c": (12, 12, 28, 18),
                 "e": (28, 12, 40, 18), "sw": (0, 18, 12, 30), "s": (12, 18, 28, 30), "se": (28, 18, 40, 30)}
        return {k: im.crop(v) for k, v in parts.items()}
    for k, im in pill(hexrgb(p["accent"]) + (70,), hexrgb(p["accent2"]) + (210,)).items():
        im.save(os.path.join(d, f"select_{k}.png"))
    # fonts
    if shutil.which("grub-mkfont"):
        inter = next((f for f in ["/usr/share/fonts/opentype/inter/Inter-Regular.otf", "/usr/share/fonts/truetype/inter/Inter-Regular.ttf", "/usr/share/fonts/opentype/inter/Inter-Regular.ttf",
                                   os.path.join(ROOT, "build-cache/Inter-Regular.ttf")] if os.path.exists(f)), None)
        if inter:
            for sz in (16, 22):
                subprocess.run(["grub-mkfont", "-s", str(sz), "-n", "Tenka Inter", "-o", os.path.join(d, f"inter-{sz}.pf2"), inter], check=False)
    a = lambda c: c
    tt = textwrap.dedent(f"""\
    # {T['display']} GRUB theme (generated by scripts/gen-system.py)
    title-text: ""
    desktop-image: "background.png"
    desktop-color: "{p['base']}"
    terminal-font: "Tenka Inter Regular 16"
    terminal-box: "select_*.png"

    + boot_menu {{
        left = 50%-330
        top = 56%
        width = 660
        height = 30%
        item_font = "Tenka Inter Regular 22"
        selected_item_font = "Tenka Inter Regular 22"
        item_color = "{p['subtext']}"
        selected_item_color = "{p['text']}"
        item_height = 40
        item_padding = 6
        item_spacing = 16
        selected_item_pixmap_style = "select_*.png"
        icon_width = 0
        icon_height = 0
        item_icon_space = 0
        scrollbar = false
    }}

    + label {{
        id = "__timeout__"
        top = 92%
        left = 0
        width = 100%
        align = "center"
        font = "Tenka Inter Regular 16"
        color = "{p['subtext']}"
        text = "The gate opens in %d"
    }}
    """)
    W(os.path.join(d, "theme.txt"), tt)

def grub_live(name, T):
    """The ISO's own boot menu (live-build's grub-pc bootloader dir)."""
    lb = os.path.join(ROOT, "live/config/bootloaders/grub-pc")
    if not os.path.exists(os.path.join(lb, "grub.cfg")):
        shutil.copytree("/usr/share/live/build/bootloaders/grub-pc", lb, dirs_exist_ok=True)
    grub_assets(name, T, os.path.join(lb, "live-theme"), live=True)
    shutil.copy(os.path.join(lb, "live-theme/background.png"), os.path.join(ROOT, "live/config/bootloaders/splash.png"))
    W(os.path.join(lb, "theme.cfg"), textwrap.dedent("""\
    set color_normal=light-gray/black
    set color_highlight=white/black
    loadfont /boot/grub/live-theme/inter-16.pf2
    loadfont /boot/grub/live-theme/inter-22.pf2
    set theme=/boot/grub/live-theme/theme.txt
    """))
    W(os.path.join(lb, "config.cfg"), textwrap.dedent("""\
    set default=0
    set timeout=8
    if loadfont /boot/grub/live-theme/inter-16.pf2 ; then
        set gfxmode=1920x1080,1280x720,auto
        set gfxpayload=keep
        insmod efi_gop
        insmod efi_uga
        insmod video_bochs
        insmod video_cirrus
        insmod all_video
    else
        set gfxmode=auto
        insmod all_video
    fi
    insmod gfxterm
    insmod png
    source /boot/grub/theme.cfg
    terminal_output gfxterm
    """))
    W(os.path.join(lb, "grub.cfg"), textwrap.dedent("""\
    source /boot/grub/config.cfg

    menuentry "Enter Tenka  ·  the way of the blade" --hotkey=t {
        linux @KERNEL_LIVE@ @APPEND_LIVE@ tenka.theme=samurai
        initrd @INITRD_LIVE@
    }
    menuentry "Enter Tianxia  ·  the path to immortality" --hotkey=x {
        linux @KERNEL_LIVE@ @APPEND_LIVE@ tenka.theme=xianxia
        initrd @INITRD_LIVE@
    }
    menuentry "Tenka Lite  ·  for older PCs and VMs without 3D" --hotkey=l {
        linux @KERNEL_LIVE@ @APPEND_LIVE@ tenka.session=lite
        initrd @INITRD_LIVE@
    }
    menuentry "Safe graphics" --hotkey=s {
        linux @KERNEL_LIVE@ @APPEND_LIVE@ nomodeset tenka.session=lite
        initrd @INITRD_LIVE@
    }
    if [ "${grub_platform}" = "efi" ]; then
    menuentry "Firmware settings" {
        fwsetup
    }
    fi
    """))

# ------------------------------------------------------------------ Calamares
# The installer speaks the same title-screen language as GRUB, the login and the launcher:
# a QML sidebar with the steps as a menu (the current one on the brush stroke), an ink stylesheet
# for every Qt widget (1px gold rules, Marcellus, no fills, no glow), and ledger slides.
def calamares(name, T):
    p = T["p"]; X = WORDS[name]
    d = os.path.join(IC, f"etc/calamares/branding/tenka-{name}")
    os.makedirs(d, exist_ok=True)
    crest(name, 256).save(os.path.join(d, "logo.png"))
    wm = wordmark(name, T, 72, os.path.join(d, "welcome.png"), sub=T["tagline"].lower())
    for i, s in enumerate(X["slides"], 1):
        im = bg_image(name, (1200, 660), darken=1.0, file=SLIDE_BG[name][(i - 1) % len(SLIDE_BG[name])]).convert("RGB")
        # even exposure across the set: each painting is brought to the same quiet mean, never brightened
        from PIL import ImageStat
        mean = ImageStat.Stat(im.convert("L")).mean[0] / 255
        im = ImageEnhance.Brightness(im).enhance(max(0.3, min(1.0, 0.2 / max(mean, 1e-3))))
        im.save(os.path.join(d, f"slide{i}.jpg"), quality=88)
    disp = T["font_display"]; n = len(X["slides"])
    def ga(c, a): c = c.lstrip("#"); return f"#{int(a*255):02x}{c}"
    PT, PS, PA, PA2, PM = p["text"], p["subtext"], p["accent"], p["accent2"], p["mantle"]
    rule = ga(PA2, 0.45)
    def body_qml(i, s):
        if len(s) > 2:   # a key slide: hairline keycaps, then the verb
            rows = "\n".join(
                f'Row {{ spacing: 8; Row {{ width: 150; spacing: 8; ' + " ".join(
                    f'Rectangle {{ width: k{i}_{r}_{c}.width + 18; height: 24; color: "transparent"; border.width: 1; border.color: "{rule}"; '
                    f'Text {{ id: k{i}_{r}_{c}; anchors.centerIn: parent; text: "{key}"; color: "{PT}"; font.family: "{disp}"; font.pixelSize: 12; font.letterSpacing: 1 }} }}'
                    + ("" if c == len(keys) - 1 else f' Text {{ anchors.verticalCenter: parent.verticalCenter; text: "+"; color: "{ga(PT, 0.45)}"; font.family: "{disp}"; font.pixelSize: 12 }}')
                    for c, key in enumerate(keys))
                + f' }} Text {{ anchors.verticalCenter: parent.verticalCenter; text: "{verb}"; color: "{PS}"; font.family: "{disp}"; font.pixelSize: 15 }} }}'
                for r, (*keys, verb) in enumerate(s[2]))
            return f'Column {{ x: 22; y: 78; spacing: 9\n{textwrap.indent(rows, "    ")}\n}}'
        return (f'Text {{ x: 22; y: 80; width: parent.width - 44; wrapMode: Text.WordWrap; text: "{s[1].replace(chr(34), chr(39))}"; '
                f'color: "{PS}"; font.family: "{disp}"; font.pixelSize: 15; lineHeight: 1.15 }}')
    ticks = lambda i: " ".join(f'Rectangle {{ width: {18 if k == i else 10}; height: 1; anchors.verticalCenter: parent.verticalCenter; '
                               f'color: "{PA if k == i else ga(PT, 0.35)}" }}' for k in range(1, n + 1))
    slides_qml = "\n".join(textwrap.dedent(f"""\
        Slide {{
            x: 0; y: 0; width: parent.width; height: parent.height   // the art fills the whole pane (the stock slide is an inset box)
            Image {{ anchors.fill: parent; source: "slide{i}.jpg"; fillMode: Image.PreserveAspectCrop; smooth: true }}
            Rectangle {{ anchors.fill: parent; gradient: Gradient {{ GradientStop {{ position: 0.30; color: "transparent" }} GradientStop {{ position: 1.0; color: "{ga(PM, 0.88)}" }} }} }}
            Item {{   // a ruled box, the label set into a gap in the top rule
                x: 44; width: parent.width - 88; height: {170 if len(s) > 2 else 150}; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
                Rectangle {{ x: 0; y: 8; width: 1; height: parent.height - 8; color: "{rule}" }}
                Rectangle {{ x: parent.width - 1; y: 8; width: 1; height: parent.height - 8; color: "{rule}" }}
                Rectangle {{ y: parent.height - 1; width: parent.width; height: 1; color: "{rule}" }}
                Rectangle {{ y: 8; width: 10; height: 1; color: "{rule}" }}
                Rectangle {{ x: lb{i}.x + lb{i}.width + 8; y: 8; width: tk{i}.x - x - 8; height: 1; color: "{rule}" }}
                Rectangle {{ x: tk{i}.x + tk{i}.width + 8; y: 8; width: parent.width - x; height: 1; color: "{rule}" }}
                Text {{ id: lb{i}; x: 18; y: 1; text: "0{i}   {s[0].upper()}"; color: "{PA2}"; font.family: "{disp}"; font.pixelSize: 11; font.letterSpacing: 4 }}
                Row {{ id: tk{i}; anchors.right: parent.right; anchors.rightMargin: 18; y: 2; height: 12; spacing: 5; {ticks(i)} }}
                Text {{ x: 22; y: 34; width: parent.width - 44; text: "{s[0]}"; color: "{PT}"; font.family: "{disp}"; font.pixelSize: 30 }}
        """) + textwrap.indent(body_qml(i, s), " " * 8) + "\n    }\n}" for i, s in enumerate(X["slides"], 1))
    W(os.path.join(d, "show.qml"), "import QtQuick\nimport calamares.slideshow 1.0\n\nPresentation {\n    id: presentation\n"
      "    function nextSlide() { presentation.goToNextSlide() }\n"
      "    // a slow ink fade between slides instead of a hard cut\n"
      "    NumberAnimation { id: inkIn; property: \"opacity\"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }\n"
      "    function switchSlides(from, to, forward) { to.opacity = 0; to.visible = true; from.visible = false; inkIn.target = to; inkIn.restart(); return true }\n"
      "    Timer { interval: 9000; running: presentation.activatedInCalamares; repeat: true; onTriggered: nextSlide() }\n"
      + textwrap.indent(slides_qml, "    ") + "\n    function onActivate() { }\n    function onLeave() { }\n}\n")

    # the sidebar: the steps as the title-screen menu
    W(os.path.join(d, "calamares-sidebar.qml"), textwrap.dedent(f"""\
    // Tenka installer sidebar: the wordmark, then the steps as a menu, the current one on the
    // same brush stroke as GRUB, the login and the launcher. No tiles, no glow.
    import QtQuick
    import io.calamares.ui 1.0
    import io.calamares.core 1.0

    Rectangle {{
        id: side
        color: "{p['mantle']}"
        anchors.fill: parent
        implicitWidth: 260
        Rectangle {{ anchors.right: parent.right; width: 1; height: parent.height; color: "{ga(p['accent2'], 0.35)}" }}
        Text {{ id: wm; x: 30; y: 34; text: "{T['display'].upper()}"; color: "{p['text']}"; font.family: "{T['font_brand']}"; font.pixelSize: 26; font.letterSpacing: 3 }}
        Text {{ x: 31; width: side.width - 50; anchors.top: wm.bottom; anchors.topMargin: 6; text: "{T['tagline'].upper()}"; color: "{p['accent2']}"; font.family: "{disp}"; font.pixelSize: 10; font.letterSpacing: 2
               fontSizeMode: Text.HorizontalFit; minimumPixelSize: 7 }}
        Rectangle {{ x: 30; y: 110; width: side.width - 60; height: 1; color: "{ga(p['accent2'], 0.30)}" }}
        Item {{
            id: menu
            x: 0; y: 136; width: side.width; height: steps.count * 46
            Image {{   // the stroke glides between steps
                source: "file:///usr/share/sddm/themes/tenka-{name}/select.png"; smooth: true
                x: 10; width: side.width - 12; height: 40
                y: ViewManager.currentStepIndex * 46 + 3
                Behavior on y {{ NumberAnimation {{ duration: 260; easing.type: Easing.OutCubic }} }}
            }}
            Repeater {{
                id: steps
                model: ViewManager
                Item {{
                    required property int index
                    required property string display
                    readonly property bool cur: index === ViewManager.currentStepIndex
                    readonly property bool done: index < ViewManager.currentStepIndex
                    y: index * 46; width: side.width; height: 46
                    Text {{ x: 30; anchors.verticalCenter: parent.verticalCenter; text: (index < 9 ? "0" : "") + (index + 1)
                           color: parent.cur ? "{p['text']}" : "{ga(p['accent2'], 0.75)}"; font.family: "{disp}"; font.pixelSize: 11; font.letterSpacing: 2 }}
                    Text {{ x: 62; anchors.verticalCenter: parent.verticalCenter; text: parent.display
                           color: parent.cur ? "{p['text']}" : (parent.done ? "{ga(p['text'], 0.55)}" : "{ga(p['text'], 0.38)}")
                           font.family: "{disp}"; font.pixelSize: 17; font.letterSpacing: 1 }}
                }}
            }}
        }}
        Text {{ x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 26; text: "{T['display'].upper()}  ·  {VERSION}"
               color: "{ga(p['text'], 0.35)}"; font.family: "{disp}"; font.pixelSize: 10; font.letterSpacing: 3 }}
    }}
    """))

    # every Qt widget in the installer, in ink: the stylesheet Calamares loads from the branding dir
    acc, gold, txt, sub = p["accent"], p["accent2"], p["text"], p["subtext"]
    W(os.path.join(d, "stylesheet.qss"), textwrap.dedent(f"""\
    /* Tenka installer: ink surfaces, 1px gold rules, Marcellus, no fills, no glow. */
    QWidget {{ background-color: {p['base']}; color: {txt}; font-family: "{disp}"; font-size: 11pt;
              selection-background-color: {rgba_q(acc, 0.35)}; selection-color: {txt}; }}
    QLabel {{ background: transparent; }}
    QFrame, QScrollArea, QStackedWidget {{ border: none; }}
    #sidebarApp, #sidebarMenuApp {{ background-color: {p['mantle']}; }}
    QPushButton {{ background: transparent; color: {txt}; border: 1px solid {rgba_q(gold, 0.45)}; border-radius: 3px;
                  padding: 7px 18px; min-width: 70px; letter-spacing: 2px; }}
    QPushButton:hover {{ border-color: {gold}; color: {gold}; }}
    QPushButton:pressed {{ background: {rgba_q(gold, 0.10)}; }}
    QPushButton:default, QPushButton#view-button-next {{ border-color: {acc}; color: {txt}; }}
    QPushButton:default:hover, QPushButton#view-button-next:hover {{ background: {rgba_q(acc, 0.12)}; color: {txt}; }}
    QPushButton:disabled {{ color: {rgba_q(txt, 0.3)}; border-color: {rgba_q(txt, 0.12)}; }}
    QLineEdit, QSpinBox, QPlainTextEdit, QTextEdit {{ background: {rgba_q(txt, 0.03)}; border: none; border-bottom: 1px solid {rgba_q(gold, 0.5)};
               padding: 6px 4px; color: {txt}; }}
    QLineEdit:focus {{ border-bottom: 1px solid {acc}; }}
    QComboBox {{ background: transparent; border: 1px solid {rgba_q(gold, 0.35)}; border-radius: 3px; padding: 5px 10px; color: {txt}; }}
    QComboBox:hover {{ border-color: {gold}; }}
    QComboBox::drop-down {{ border: none; width: 22px; }}
    QComboBox QAbstractItemView {{ background: {p['surface']}; border: 1px solid {rgba_q(gold, 0.35)}; selection-background-color: {rgba_q(acc, 0.3)}; }}
    QListView, QTreeView, QTableView, QListWidget, QTreeWidget {{ background: {rgba_q(txt, 0.02)}; border: 1px solid {rgba_q(gold, 0.22)};
               alternate-background-color: {rgba_q(txt, 0.03)}; outline: 0; }}
    QListView::item, QTreeView::item {{ padding: 4px 6px; }}
    QListView::item:selected, QTreeView::item:selected, QListWidget::item:selected {{ background: transparent; color: {txt};
               border-left: 2px solid {acc}; }}
    QListView::item:hover, QTreeView::item:hover {{ background: {rgba_q(gold, 0.06)}; }}
    QHeaderView::section {{ background: transparent; color: {gold}; border: none; border-bottom: 1px solid {rgba_q(gold, 0.3)}; padding: 4px 6px; }}
    QCheckBox, QRadioButton {{ background: transparent; spacing: 10px; }}
    QCheckBox::indicator, QRadioButton::indicator {{ width: 11px; height: 11px; border: 1px solid {rgba_q(txt, 0.5)}; background: transparent; }}
    QRadioButton::indicator {{ border-radius: 6px; }}
    QCheckBox::indicator:checked, QRadioButton::indicator:checked {{ background: {acc}; border-color: {acc}; }}
    QProgressBar {{ background: {rgba_q(txt, 0.12)}; border: none; height: 2px; max-height: 2px; text-align: center; color: transparent; }}
    QProgressBar::chunk {{ background: {acc}; }}
    QScrollBar:vertical {{ background: transparent; width: 8px; margin: 2px; }}
    QScrollBar::handle:vertical {{ background: {rgba_q(gold, 0.35)}; border-radius: 3px; min-height: 30px; }}
    QScrollBar::add-line, QScrollBar::sub-line {{ height: 0; width: 0; }}
    QScrollBar:horizontal {{ background: transparent; height: 8px; margin: 2px; }}
    QScrollBar::handle:horizontal {{ background: {rgba_q(gold, 0.35)}; border-radius: 3px; min-width: 30px; }}
    QToolTip {{ background: {p['surface']}; color: {txt}; border: 1px solid {rgba_q(gold, 0.45)}; padding: 4px 8px; }}
    QGroupBox {{ border: 1px solid {rgba_q(gold, 0.3)}; border-radius: 3px; margin-top: 14px; padding-top: 10px; }}
    QGroupBox::title {{ subcontrol-origin: margin; left: 12px; padding: 0 6px; color: {gold}; }}
    """))

    W(os.path.join(d, "branding.desc"), textwrap.dedent(f"""\
    ---
    componentName:  tenka-{name}
    welcomeStyleCalamares: false
    welcomeExpandingLogo: true
    windowExpanding: normal
    windowSize: 1040px,660px
    windowPlacement: center
    sidebar: qml
    navigation: widget
    strings:
        productName:         {T['display']}
        shortProductName:    {T['display']}
        version:             {VERSION}
        shortVersion:        {VERSION}
        versionedName:       {T['display']} {VERSION}
        shortVersionedName:  {T['display']} {VERSION}
        bootloaderEntryName: {T['display']}
        productUrl:          https://github.com/naman-sharma12345/tenka
        supportUrl:          https://github.com/naman-sharma12345/tenka/issues
        knownIssuesUrl:      https://github.com/naman-sharma12345/tenka/issues
        releaseNotesUrl:     https://github.com/naman-sharma12345/tenka/releases
    images:
        productLogo:         "logo.png"
        productIcon:         "logo.png"
        productWelcome:      "welcome.png"
    slideshow:               "show.qml"
    slideshowAPI: 2
    style:
       SidebarBackground:        "{p['mantle']}"
       SidebarText:              "{p['subtext']}"
       SidebarTextCurrent:       "{p['text']}"
       SidebarBackgroundCurrent: "{p['mantle']}"
    """))

def rgba_q(c, a):
    c = c.lstrip("#"); return f"rgba({int(c[0:2],16)}, {int(c[2:4],16)}, {int(c[4:6],16)}, {int(round(a*255))})"

if __name__ == "__main__":
    for n, T in gt.THEMES.items():
        sddm(n, T); calamares(n, T)
        print("system themes (sddm, calamares):", n)
    # boot menu + splash live in their own generators
    subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "gen-boot.py")], check=True)
    subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "gen-plymouth.py")], check=True)
