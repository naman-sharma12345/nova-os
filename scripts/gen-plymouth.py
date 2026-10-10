#!/usr/bin/env python3
"""Tenka boot splash (Plymouth, script module): the title card, alive.

The same key art as the boot menu and the login screen, lightly darkened; mist banks drift,
sakura fall (Tenka) or qi motes rise (Tianxia); a big enso paints itself (a jade ring draws
itself for Tianxia), the seal stamps in, the wordmark fades up, and boot progress is a brush
line (a jade line with a gold bead) that grows under it. No glow anywhere: lines and ink only. No text ever flashes. The final frame
is the login screen's own background, so the hand-off to SDDM is seamless.

    python3 scripts/gen-plymouth.py
"""
import os, shutil, textwrap, importlib.util
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("tenka_art", os.path.join(HERE, "tenka_art.py"))
ta = importlib.util.module_from_spec(spec); spec.loader.exec_module(ta)
ROOT = ta.ROOT
IC = os.path.join(ROOT, "live/config/includes.chroot")
NFRAMES = 40
D = 520                      # enso / ring diameter at 1080p
CX, CY = 470, 420            # centre of the title column
PROG_W = 360


def handoff_scene(theme):
    """The shared splash/login background: the graded key art, darkened a touch."""
    im = ta.scene(theme).convert("RGB")
    a = np.asarray(im, np.float32) * 0.86
    return Image.fromarray(a.astype(np.uint8))


def enso_frames(d, theme):
    P = ta.PAL[theme]
    if theme == "samurai":
        a, u = ta.polar_stroke(D, 62, seed=12, start=118, sweep=338, dry=0.6, tail=0.45, ink=0.85)
        col = ta.hexc(P["text"])[:3]
        glow_col = ta.hexc(P["gold"])[:3]
    else:
        # a jade ring: one crisp 2 px line (no halo, no glow: the standing rule), drawn by a gold bead
        yy, xx = np.mgrid[0:D, 0:D].astype(np.float32); c = D / 2
        rad = np.hypot(xx - c, yy - c); Rr = D / 2 - 40
        ang = (np.degrees(np.arctan2(yy - c, xx - c)) + 90) % 360
        u = np.where(np.abs(rad - Rr) < 30, ang / 360, 2.0)
        a = np.clip(np.exp(-((rad - Rr) / 1.25) ** 2) * 1.15, 0, 1)
        col = ta.hexc(P["acc"])[:3]; glow_col = ta.hexc(P["gold"])[:3]
        # the formation: an inner rune ring of ticks, an outer dashed ring, and a faint jade disc
        ticks = ((np.abs(rad - (Rr - 24)) < 7) & ((ang % 7.5) < 1.1)).astype(np.float32) * 0.9
        ticks += ((np.abs(rad - (Rr - 24)) < 12) & ((ang % 30) < 1.4)).astype(np.float32) * 0.9
        inner = np.exp(-((rad - (Rr - 24)) / 1.0) ** 2) * 0.5
        outer = np.exp(-((rad - (Rr + 18)) / 1.2) ** 2) * ((ang % 4) < 2.6) * 0.6
        rune = np.clip(ticks + inner + outer, 0, 1)
        ang_r = ang / 360
    for i in range(NFRAMES):
        p = (i + 1) / NFRAMES
        m = np.clip((p * 1.02 - u) / 0.012, 0, 1) * a
        arr = np.zeros((D, D, 4), np.uint8); arr[..., :3] = col; arr[..., 3] = (m * 255).astype(np.uint8)
        im = Image.fromarray(arr, "RGBA")
        out = im   # no gold glow behind the stroke: ink and line only
        if theme == "xianxia":
            rm = rune * np.clip((p - ang_r) / 0.2, 0, 1) * min(1.0, p * 1.5)
            r_arr = np.zeros((D, D, 4), np.uint8); r_arr[..., :3] = ta.hexc(P["gold"])[:3]; r_arr[..., 3] = (rm * 255).astype(np.uint8)
            out = Image.alpha_composite(out, Image.fromarray(r_arr, "RGBA"))
            disc = np.exp(-(rad / (Rr * 0.9)) ** 4) * 0.08 * p
            d_arr = np.zeros((D, D, 4), np.uint8); d_arr[..., :3] = col; d_arr[..., 3] = (disc * 255).astype(np.uint8)
            out = Image.alpha_composite(Image.fromarray(d_arr, "RGBA"), out)
            if p < 1.0:   # the gold bead at the drawing head
                th = np.radians(p * 360 - 90); bx, by = D / 2 + Rr * np.cos(th), D / 2 + Rr * np.sin(th)
                b = Image.new("RGBA", (D, D), (0, 0, 0, 0)); ImageDraw.Draw(b).ellipse((bx - 4, by - 4, bx + 4, by + 4), fill=ta.hexc(P["gold"]))
                out = Image.alpha_composite(out, b)
        out.save(os.path.join(d, f"enso-{i:02d}.png"), optimize=True)


def seal(d, theme):
    """A carved seal: vermilion square with the sakura knocked out (Tenka), a round cinnabar seal with the lotus (Tianxia)."""
    P = ta.PAL[theme]; S = 132
    crest = Image.open(os.path.join(ROOT, "themes", theme, "crest-1024.png")).convert("RGBA").resize((S, S), Image.LANCZOS)
    ca = np.asarray(crest, np.float32)
    lum = ca[..., :3].mean(-1); knock = (ca[..., 3] > 100) & (lum > 60)
    rng = np.random.default_rng(4)
    shape = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(shape)
    if theme == "samurai": dr.rounded_rectangle((6, 6, S - 6, S - 6), radius=10, fill=255)
    else: dr.ellipse((6, 6, S - 6, S - 6), fill=255)
    m = np.asarray(shape, np.float32) / 255
    inner = np.asarray(Image.fromarray(knock.astype(np.uint8) * 255).resize((int(S * .72), int(S * .72)), Image.LANCZOS), np.float32) / 255
    k = np.zeros((S, S), np.float32); o = (S - inner.shape[0]) // 2; k[o:o + inner.shape[0], o:o + inner.shape[1]] = inner
    grain = ta.fbm(S, S, 4, 9, 3)
    a = np.clip(m * (1 - k) * (0.75 + 0.35 * grain) - (rng.random((S, S)) > 0.985) * 0.6, 0, 1)
    col = ta.hexc(P["acc"] if theme == "samurai" else P["ind"])[:3]
    arr = np.zeros((S, S, 4), np.uint8); arr[..., :3] = col; arr[..., 3] = (a * 255).astype(np.uint8)
    im = Image.fromarray(arr, "RGBA")
    for i, sc in enumerate((1.6, 1.35, 1.15, 1.0)):   # the stamp lands
        sz = int(S * sc); Image.new("RGBA", (int(S * 1.6), int(S * 1.6)), (0, 0, 0, 0)).save(os.path.join(d, f"seal-{i}.png"))
        c = Image.new("RGBA", (int(S * 1.6), int(S * 1.6)), (0, 0, 0, 0)); c.alpha_composite(im.resize((sz, sz), Image.LANCZOS), ((c.width - sz) // 2, (c.height - sz) // 2))
        c.save(os.path.join(d, f"seal-{i}.png"))


def wordmark(d, theme):
    P = ta.PAL[theme]
    c = Image.new("RGBA", (900, 230), (0, 0, 0, 0))
    size = ta.word_size(P["word"], ta.CIND, 0.10, 520 if theme == "samurai" else 560)
    c2, (x, y, wW, wH) = ta.wordmark(c, theme, 0, 0, size, 1.0, "cinzel")
    # re-render centred
    c = Image.new("RGBA", (900, 230), (0, 0, 0, 0))
    c, (x, y, wW, wH) = ta.wordmark(c, theme, int(450 - wW / 2), 40, size, 1.0, "cinzel")
    ta.place_text(c, (450, 40 + wH + 30), P["tag"], ta.MARC, 21, ta.hexc(P["gold"], 230), track_em=0.62, anchor="c")
    c.save(os.path.join(d, "wordmark.png"))


def progress(d, theme):
    P = ta.PAL[theme]; H = 22; N = 32
    if theme == "samurai":
        a = ta.brush_stroke(PROG_W, 12, seed=31, dry=0.35, head=0.02, tail=0.12, wave=0.0)
        full = Image.new("RGBA", (PROG_W, H), ta.hexc(P["acc"])[:3] + (0,)); m = Image.new("L", (PROG_W, H), 0); m.paste(ta.mask_img(a), (0, 5)); full.putalpha(m)
    else:
        full = Image.new("RGBA", (PROG_W, H), (0, 0, 0, 0)); ImageDraw.Draw(full).line((0, H // 2, PROG_W, H // 2), fill=ta.hexc(P["acc"]), width=2)
    track = Image.new("RGBA", (PROG_W, H), (0, 0, 0, 0)); ImageDraw.Draw(track).line((0, H // 2, PROG_W, H // 2), fill=ta.hexc(P["gold"], 60), width=1)
    track.save(os.path.join(d, "progress-track.png"))
    xs = np.arange(PROG_W)[None, :]
    for i in range(N + 1):
        p = i / N; im = full.copy(); al = np.asarray(im.getchannel("A"), np.float32)
        al *= np.clip((p * PROG_W - xs) / 6, 0, 1); im.putalpha(Image.fromarray(al.astype(np.uint8)))
        if theme == "xianxia" and 0 < p:
            bx = int(p * PROG_W) - 1; b = Image.new("RGBA", (PROG_W, H), (0, 0, 0, 0))
            ImageDraw.Draw(b).ellipse((bx - 4, H / 2 - 4, bx + 4, H / 2 + 4), fill=ta.hexc(P["gold"]))
            im = Image.alpha_composite(im, b)
        im.save(os.path.join(d, f"progress-{i:02d}.png"), optimize=True)


def mist(w, h, seed, color, strength):
    n = ta.aniso_noise(w, h, 420, 160, seed, 5)
    yy = np.linspace(0, 1, h)[:, None]
    band = np.exp(-((yy - 0.55) / 0.30) ** 2)
    a = np.clip((n - 0.40) * 2.2, 0, 1) * band * 255 * strength
    k = w // 6; ramp = np.linspace(0, 1, k)[None, :]
    a[:, :k] = a[:, :k] * ramp + a[:, -k:] * (1 - ramp); a = a[:, :w - k]
    arr = np.dstack([np.full(a.shape, c, np.uint8) for c in color] + [a.astype(np.uint8)])
    return Image.fromarray(arr, "RGBA").filter(ImageFilter.GaussianBlur(4))


def sprites(d, theme):
    rng = np.random.default_rng(2)
    if theme == "samurai":
        for j, (s, col) in enumerate(((5, (246, 214, 220)), (7, (242, 196, 206)), (9, (250, 226, 230)), (12, (236, 180, 194)))):
            p = ta.petal_sprite(s, rng, col)
            if s >= 12: p = p.filter(ImageFilter.GaussianBlur(1.5))
            p.save(os.path.join(d, f"particle-{j}.png"))
    else:
        for j, (s, col) in enumerate(((3, (255, 220, 140)), (4, (150, 255, 205)), (6, (255, 214, 130)), (2, (240, 255, 245)))):
            ta.mote_sprite(s, col).save(os.path.join(d, f"particle-{j}.png"))
    mc = (236, 228, 218) if theme == "samurai" else (214, 240, 230)
    mist(2600, 420, 3, mc, 0.50).save(os.path.join(d, "mist-a.png"))
    mist(2800, 520, 9, mc, 0.38).save(os.path.join(d, "mist-b.png"))


SCRIPT = r"""// @NAME@ boot splash, generated by scripts/gen-plymouth.py. Silent: no text unless a password is needed.
W = Window.GetWidth(); H = Window.GetHeight();
Window.SetBackgroundTopColor(@BG@); Window.SetBackgroundBottomColor(@BG@);
k = H / 1080; if (W / 1920 < k) k = W / 1920;
// background: cover the screen
bgi = Image("scene.png"); bs = W / bgi.GetWidth(); if (H / bgi.GetHeight() > bs) bs = H / bgi.GetHeight();
bg = Sprite(bgi.Scale(bgi.GetWidth() * bs, bgi.GetHeight() * bs));
bg.SetX((W - bgi.GetWidth() * bs) / 2); bg.SetY((H - bgi.GetHeight() * bs) / 2); bg.SetZ(-100);
ox = (W - 1920 * k) / 2; oy = (H - 1080 * k) / 2;   // the 1080p design box, centred
fun S(img) { return img.Scale(img.GetWidth() * k, img.GetHeight() * k); }

// mist banks, two copies each so they wrap
ma = S(Image("mist-a.png")); mb = S(Image("mist-b.png"));
m1 = Sprite(ma); m2 = Sprite(ma); m3 = Sprite(mb); m4 = Sprite(mb);
m1.SetY(H - ma.GetHeight() * 1.05); m2.SetY(m1.GetY()); m3.SetY(H - mb.GetHeight() * 1.35); m4.SetY(m3.GetY());
m1.SetOpacity(@M1@); m2.SetOpacity(@M1@); m3.SetOpacity(@M2@); m4.SetOpacity(@M2@);
m1.SetZ(5); m2.SetZ(5); m3.SetZ(4); m4.SetZ(4);

// the enso (or jade ring) paints itself
for (i = 0; i < @NF@; i++) { if (i < 10) n = "0" + i; else n = "" + i; en[i] = S(Image("enso-" + n + ".png")); }
enso = Sprite(en[0]); enso.SetOpacity(0); enso.SetZ(10);
enso.SetX(ox + @CX@ * k - en[0].GetWidth() / 2); enso.SetY(oy + @CY@ * k - en[0].GetHeight() / 2);
for (i = 0; i < 4; i++) sl[i] = S(Image("seal-" + i + ".png"));
seal = Sprite(sl[0]); seal.SetOpacity(0); seal.SetZ(12);
seal.SetX(ox + @SX@ * k - sl[0].GetWidth() / 2); seal.SetY(oy + @SY@ * k - sl[0].GetHeight() / 2);
wmi = S(Image("wordmark.png")); wm = Sprite(wmi); wm.SetOpacity(0); wm.SetZ(10);
wm.SetX(ox + @CX@ * k - wmi.GetWidth() / 2); wm.SetY(oy + @WY@ * k);
for (i = 0; i <= 32; i++) { if (i < 10) n = "0" + i; else n = "" + i; pr[i] = S(Image("progress-" + n + ".png")); }
tri = S(Image("progress-track.png")); track = Sprite(tri); track.SetOpacity(0); track.SetZ(10);
prog = Sprite(pr[0]); prog.SetZ(11); prog.SetOpacity(0);
track.SetX(ox + @CX@ * k - tri.GetWidth() / 2); track.SetY(oy + @PY@ * k); prog.SetX(track.GetX()); prog.SetY(track.GetY());

// particles: @PARTS@
for (j = 0; j < 4; j++) pim[j] = S(Image("particle-" + j + ".png"));
NP = @NP@;
for (i = 0; i < NP; i++) {
  ps[i] = Sprite(pim[i % 4]); px[i] = Math.Random() * W; py[i] = Math.Random() * H;
  pv[i] = (0.6 + Math.Random() * 1.4) * k; ph[i] = Math.Random() * 6.28; ps[i].SetZ(20 + i % 4);
  ps[i].SetX(px[i]); ps[i].SetY(py[i]); ps[i].SetOpacity(0);
}

t = 0; progress = 0; shown = 0;
fun refresh_cb() {
  t++;
  // fade the overlays in over the first second
  f = t / 50; if (f > 1) f = 1;
  mx = (t * 0.35 * k) % ma.GetWidth(); m1.SetX(-mx); m2.SetX(ma.GetWidth() - mx);
  mx2 = (t * 0.22 * k) % mb.GetWidth(); m3.SetX(-mb.GetWidth() + mx2); m4.SetX(mx2);
  for (i = 0; i < NP; i++) {
    @MOVE@
    ps[i].SetX(px[i]); ps[i].SetY(py[i]);
  }
  // enso: 20 to 120
  if (t > 20) {
    e = Math.Int((t - 20) / 2.5); if (e > @NF@ - 1) e = @NF@ - 1;
    enso.SetImage(en[e]); enso.SetOpacity(1);
  }
  // seal stamps in: 125 to 137
  if (t > 125) { s = Math.Int((t - 125) / 3); if (s > 3) s = 3; seal.SetImage(sl[s]); o = (t - 125) / 6; if (o > 1) o = 1; seal.SetOpacity(o); }
  // wordmark and progress fade up: 135 to 185
  if (t > 135) { o = (t - 135) / 50; if (o > 1) o = 1; wm.SetOpacity(o); track.SetOpacity(o); prog.SetOpacity(o); }
  p = Math.Int(progress * 32); if (p > 32) p = 32; if (p < 0) p = 0;
  prog.SetImage(pr[p]);
}
Plymouth.SetRefreshFunction(refresh_cb);
fun progress_cb(duration, value) { if (value > progress) progress = value; }
Plymouth.SetBootProgressFunction(progress_cb);

// disk-unlock prompt (only when needed), in the theme's own words and colours
pmsg = Sprite(); pbul = Sprite(); pmsg.SetZ(30); pbul.SetZ(30);
fun pw_cb(prompt, bullets) {
  pmsg.SetImage(Image.Text("Enter the passphrase to unlock", @TXT@, 1, "Marcellus 20")); pmsg.SetOpacity(1);
  pmsg.SetX(ox + @CX@ * k - pmsg.GetImage().GetWidth() / 2); pmsg.SetY(oy + (@PY@ + 40) * k);
  s = ""; for (i = 0; i < bullets; i++) s += "*  ";
  pbul.SetImage(Image.Text(s, @ACCT@, 1, "Marcellus 22")); pbul.SetOpacity(1);
  pbul.SetX(ox + @CX@ * k - pbul.GetImage().GetWidth() / 2); pbul.SetY(oy + (@PY@ + 80) * k);
}
Plymouth.SetDisplayPasswordFunction(pw_cb);
fun normal_cb() { pmsg.SetOpacity(0); pbul.SetOpacity(0); }
Plymouth.SetDisplayNormalFunction(normal_cb);
fun msg_cb(text) { }
Plymouth.SetMessageFunction(msg_cb);
fun quit_cb() { prog.SetImage(pr[32]); }
Plymouth.SetQuitFunction(quit_cb);
"""

MOVE = {
    "samurai": "py[i] += pv[i] * 1.3; px[i] += (0.7 + Math.Sin(t / 40 + ph[i]) * 0.9) * k; if (py[i] > H + 40) { py[i] = -40; px[i] = Math.Random() * W; } if (px[i] > W + 40) px[i] = -40; ps[i].SetOpacity(f * 0.9);",
    "xianxia": "py[i] -= pv[i] * 0.8; px[i] += Math.Sin(t / 50 + ph[i]) * 0.5 * k; ps[i].SetOpacity(f * (0.3 + 0.6 * Math.Sin(t / 25 + ph[i]) * Math.Sin(t / 25 + ph[i]))); if (py[i] < -30) { py[i] = H + 30; px[i] = Math.Random() * W; }",
}


def build(theme):
    P = ta.PAL[theme]
    d = os.path.join(IC, f"usr/share/plymouth/themes/tenka-{theme}")
    shutil.rmtree(d, ignore_errors=True); os.makedirs(d)
    sc = handoff_scene(theme); sc.save(os.path.join(d, "scene.png"), optimize=True)
    # the login screen uses the very same picture
    sddm = os.path.join(IC, f"usr/share/sddm/themes/tenka-{theme}"); os.makedirs(sddm, exist_ok=True)
    sc.save(os.path.join(sddm, "background.png"), optimize=True)
    enso_frames(d, theme); seal(d, theme); wordmark(d, theme); progress(d, theme); sprites(d, theme)
    shutil.copy(os.path.join(d, f"enso-{NFRAMES - 1:02d}.png"), os.path.join(sddm, "enso.png"))
    shutil.copy(os.path.join(d, "seal-3.png"), os.path.join(sddm, "seal.png"))
    f3 = lambda c: ", ".join(f"{v / 255:.3f}" for v in ta.hexc(c)[:3])
    s = SCRIPT
    for key, val in {"@NAME@": P["display"], "@BG@": f3(P["base"]), "@M1@": "0.55", "@M2@": "0.42", "@NF@": str(NFRAMES),
                     "@NP@": "36" if theme == "samurai" else "48", "@PARTS@": "falling sakura" if theme == "samurai" else "rising qi motes",
                     "@MOVE@": MOVE[theme], "@CX@": str(CX), "@CY@": str(CY), "@SX@": str(CX + 175), "@SY@": str(CY + 165),
                     "@WY@": str(CY + D // 2 + 8), "@PY@": str(CY + D // 2 + 250),
                     "@TXT@": f3(P["text"]), "@ACCT@": f3(P["gold"])}.items():
        s = s.replace(key, val)
    with open(os.path.join(d, f"tenka-{theme}.script"), "w") as fh: fh.write(s)
    with open(os.path.join(d, f"tenka-{theme}.plymouth"), "w") as fh:
        fh.write(textwrap.dedent(f"""\
        [Plymouth Theme]
        Name={P['display']}
        Description={P['display']}: all under heaven
        ModuleName=script

        [script]
        ImageDir=/usr/share/plymouth/themes/tenka-{theme}
        ScriptFile=/usr/share/plymouth/themes/tenka-{theme}/tenka-{theme}.script
        """))


if __name__ == "__main__":
    for n in ta.PAL:
        build(n); print("plymouth:", n)
