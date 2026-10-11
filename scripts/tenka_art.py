#!/usr/bin/env python3
"""Shared art helpers for Tenka's boot experience (GRUB, Plymouth, SDDM).
Everything here is procedural (numpy + PIL): dry-brush strokes, ink-bled wordmarks,
light rays, petals and qi motes, and the title-card grade of the key art.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FONTS = os.path.join(ROOT, "live/config/includes.chroot/usr/share/fonts/truetype/tenka")
MARC = os.path.join(FONTS, "Marcellus-Regular.ttf")
CIND = os.path.join(FONTS, "CinzelDecorative-Bold.ttf")

PAL = {
    "samurai": dict(display="Tenka", base="#0f0d0c", acc="#d8412f", gold="#c9a35a", text="#efe6d6", ind="#2e3f63",
                    word="TENKA", tag="ALL UNDER HEAVEN", style="cinzel+", src=(0.785, 0.30),
                    unsel="#948a7d", sel="#fff8ec"),
    "xianxia": dict(display="Tianxia", base="#0b1513", acc="#5fc9a0", gold="#e2bd6b", text="#eef3ec", ind="#e2553f",
                    word="TIANXIA", tag="ALL UNDER HEAVEN", style="cinzel", src=(0.865, 0.27),
                    unsel="#8fa69c", sel="#f4fff8"),
}
LX = 150  # left edge of the title column at 1080p


def keyart(theme):
    return os.path.join(ROOT, "themes", theme, "keyart.jpg")


def hexc(c, a=255):
    c = c.lstrip("#"); return (int(c[:2], 16), int(c[2:4], 16), int(c[4:], 16), a)


def aniso_noise(w, h, sx, sy, seed, oct=3):
    rng = np.random.default_rng(seed); out = np.zeros((h, w), np.float32); amp = 1; tot = 0
    for o in range(oct):
        gw, gh = max(2, int(w / sx * 2 ** o)), max(2, int(h / sy * 2 ** o))
        g = Image.fromarray((rng.random((gh, gw)) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        out += amp * np.asarray(g, np.float32) / 255; tot += amp; amp *= .55
    return out / tot


def fbm(w, h, scale, seed, oct=4):
    return aniso_noise(w, h, scale, scale, seed, oct)


def brush_stroke(w, h, seed=3, dry=0.5, head=0.05, tail=0.45, wave=0.06, ink=1.0):
    """Alpha (0..1) of a horizontal dry-brush stroke filling w x h: a pressed head,
    bristle streaks, ragged edges and a dry tail where the ink runs out."""
    x = np.linspace(0, 1, w); rng = np.random.default_rng(seed)
    prof = np.clip(x / head, 0, 1) ** 0.45 * np.clip((1 - x) / tail, 0, 1) ** 0.55
    prof *= (0.88 + 0.12 * np.sin(x * np.pi * 1.7 + rng.random() * 3))
    center = 0.5 + wave * np.sin(x * np.pi * (0.8 + rng.random()) + rng.random() * 6)
    yy = np.linspace(0, 1, h)[:, None]
    half = 0.47 * prof[None, :]
    en = aniso_noise(w, h, w / 90, h / 6, seed + 1, 3)
    d = np.abs(yy - center[None, :]) / np.maximum(half, 1e-4) + (en - 0.5) * 0.25
    body = np.clip((1.0 - d) * 14, 0, 1)
    br = aniso_noise(w, h, w / 5, 1.3, seed + 2, 3)
    load = np.clip(ink * 1.25 - x * 1.25, 0, 1)[None, :]
    edgef = np.clip(d, 0, 1) ** 3
    keep = load * (1 - edgef * 0.85)
    thr = dry * (1 - keep) + 0.18 * edgef
    streak = np.clip((br - thr) * 9, 0, 1)
    a = body * np.clip(np.maximum(streak, keep), 0, 1)
    a *= 0.8 + 0.2 * aniso_noise(w, h, w / 4, h / 3, seed + 3, 2)
    return np.clip(a, 0, 1)


def bilinear(img, yy, xx):
    y0 = np.floor(yy).astype(int); x0 = np.floor(xx).astype(int)
    y1 = np.minimum(y0 + 1, img.shape[0] - 1); x1 = np.minimum(x0 + 1, img.shape[1] - 1)
    fy = yy - y0; fx = xx - x0
    return (img[y0, x0] * (1 - fx) + img[y0, x1] * fx) * (1 - fy) + (img[y1, x0] * (1 - fx) + img[y1, x1] * fx) * fy


def polar_stroke(D, thick, seed=5, start=-100, sweep=330, dry=0.5, tail=0.35, ink=0.9):
    """A brush stroke bent into a circle (the enso). Returns alpha and the 0..1 position along the stroke."""
    Rr = D / 2 - thick * 0.75
    circ = int(2 * np.pi * Rr * sweep / 360)
    st = brush_stroke(circ, int(thick), seed=seed, dry=dry, head=0.03, tail=tail, wave=0.05, ink=ink)
    yy, xx = np.mgrid[0:D, 0:D].astype(np.float32); c = D / 2
    ang = (np.degrees(np.arctan2(yy - c, xx - c)) - start) % 360
    rad = np.hypot(xx - c, yy - c)
    u = ang / sweep
    wob = thick * 0.18 * np.sin(u * np.pi * 2.2 + 1.3)
    v = (rad - (Rr - thick / 2) - wob) / thick
    valid = (u <= 1) & (v >= -0.05) & (v < 1.05)
    a = bilinear(st, np.clip(v, 0, 1) * (thick - 1), np.clip(u, 0, 1) * (circ - 1))
    return np.where(valid, a, 0).astype(np.float32), np.where(valid, u, 2.0)


def mask_img(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def text_mask(text, fontpath, size, track_em=0.0, pad=60):
    f = ImageFont.truetype(fontpath, size)
    d0 = ImageDraw.Draw(Image.new("L", (1, 1)))
    ws = [d0.textlength(c, font=f) for c in text]; tr = track_em * size
    W = int(sum(ws) + tr * (len(text) - 1)) + 2 * pad
    asc, desc = f.getmetrics(); H = asc + desc + 2 * pad
    m = Image.new("L", (W, H), 0); d = ImageDraw.Draw(m); x = pad
    for c, w in zip(text, ws):
        d.text((x, pad), c, font=f, fill=255); x += w + tr
    return m, m.getbbox()


def word_size(word, fp, tr, target):
    m, bb = text_mask(word, fp, 200, tr, pad=10); return int(200 * target / (bb[2] - bb[0]))


def place_text(canvas, xy, text, fontpath, size, color, track_em=0.0, anchor="l"):
    f = ImageFont.truetype(fontpath, size); d = ImageDraw.Draw(canvas)
    ws = [d.textlength(c, font=f) for c in text]; tr = track_em * size; tot = sum(ws) + tr * (len(text) - 1)
    x, y = xy
    if anchor == "c": x -= tot / 2
    if anchor == "r": x -= tot
    for c, w in zip(text, ws):
        d.text((x, y), c, font=f, fill=color); x += w + tr
    return tot


def grad_fill(size, stops):
    w, h = size; y = np.linspace(0, 1, h)
    out = np.zeros((h, 1, 3), np.float32)
    for i in range(3):
        out[:, 0, i] = np.interp(y, [s[0] for s in stops], [s[1][i] for s in stops])
    return Image.fromarray(np.repeat(out, w, 1).astype(np.uint8), "RGB")


def ink_bleed(mask, seed=1, amt=2.0):
    a = np.asarray(mask.filter(ImageFilter.GaussianBlur(amt)), np.float32) / 255
    n = fbm(mask.width, mask.height, 6, seed, 3)
    t = 0.5 + (n - 0.5) * 0.35
    return mask_img(np.clip((a - t) * 8 + 0.5, 0, 1))


def add_layer(base, color, mask, opacity=1.0):
    lay = Image.new("RGBA", base.size, color[:3] + (0,))
    lay.putalpha(Image.fromarray(np.clip(np.asarray(mask, np.float32) * opacity, 0, 255).astype(np.uint8)))
    return Image.alpha_composite(base, lay)


def screen_glow(base, color, mask, radius, strength):
    g = mask.filter(ImageFilter.GaussianBlur(radius))
    b = np.asarray(base.convert("RGB"), np.float32) / 255; a = np.asarray(g, np.float32)[..., None] / 255 * strength
    c = np.array(color[:3], np.float32) / 255
    out = 1 - (1 - b) * (1 - c * a)
    res = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
    if base.mode == "RGBA": res.putalpha(base.getchannel("A"))
    return res


def hairline(w, color, thick=1, fade=0.45):
    h = max(9, thick * 9)
    x = np.linspace(0, 1, w); a = np.clip(np.minimum(x, 1 - x) / fade, 0, 1)
    arr = np.zeros((h, w, 4), np.uint8); arr[..., :3] = color[:3]
    for t in range(thick): arr[h // 2 - thick // 2 + t, :, 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def rays(w, h, src, seed):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = src[0] * w, src[1] * h
    ang = np.arctan2(yy - cy, xx - cx); dist = np.hypot(xx - cx, yy - cy) / w
    rng = np.random.default_rng(seed); v = np.zeros_like(ang)
    for i in range(14):
        f = rng.integers(5, 60); ph = rng.random() * 6.28; v += np.cos(ang * f + ph) * rng.random()
    v = (v - v.min()) / (v.max() - v.min()); v = np.clip((v - 0.55) * 3, 0, 1)
    return v * np.exp(-dist * 2.2) * np.clip(dist * 6, 0, 1) * np.exp(-dist * 3.5), dist


def petal_sprite(s, rng, color=None):
    pw, ph = int(s * 2.2) + 2, int(s * 1.3) + 2
    p = Image.new("RGBA", (pw * 3, pw * 3), (0, 0, 0, 0)); d = ImageDraw.Draw(p)
    col = color or (246, 214, 214); a = int(150 + 100 * rng.random())
    d.ellipse((pw * 1.5 - pw / 2, pw * 1.5 - ph / 2, pw * 1.5 + pw / 2, pw * 1.5 + ph / 2), fill=col + (a,))
    d.ellipse((pw * 1.5 + pw * 0.15, pw * 1.5 - ph * 0.2, pw * 1.5 + pw * 0.55, pw * 1.5 + ph * 0.2), fill=(0, 0, 0, 0))
    return p.rotate(rng.random() * 360, resample=Image.BICUBIC)


def mote_sprite(s, color):
    r = int(s * 3) + 3; p = Image.new("RGBA", (r * 2, r * 2), (0, 0, 0, 0)); d = ImageDraw.Draw(p)
    d.ellipse((r - s / 2, r - s / 2, r + s / 2, r + s / 2), fill=color + (255,))
    for _ in range(2): p = Image.alpha_composite(p.filter(ImageFilter.GaussianBlur(s * 0.9)), p)
    return p


def particles(w, h, kind, seed, count, region=None, size=(3, 9), color=None):
    lay = Image.new("RGBA", (w, h), (0, 0, 0, 0)); rng = np.random.default_rng(seed)
    for i in range(count):
        x = rng.random() * w; y = rng.random() * h
        if region and not region(x / w, y / h): continue
        s = rng.uniform(*size) * (w / 1920)
        p = petal_sprite(s, rng, color) if kind == "petal" else mote_sprite(s, color or (255, 214, 130))
        lay.alpha_composite(p, (int(x), int(y)))
    return lay


def lin_grad_mask(w, h, x0, x1, a0, a1, gamma=1.0):
    x = np.clip((np.arange(w) / w - x0) / (x1 - x0), 0, 1) ** gamma
    return np.repeat((a0 + (a1 - a0) * x)[None, :], h, 0)


def scene(theme, s=1.0, particles_on=True):
    """The title-card grade of the key art: light rays and bloom from the sun/moon, an ink falloff
    on the left third where the title and menu live, a bottom vignette, and baked depth particles."""
    W, H = int(1920 * s), int(1080 * s); P = PAL[theme]
    im = Image.open(keyart(theme)).convert("RGB").resize((W, H), Image.LANCZOS)
    base = np.array(hexc(P["base"])[:3], np.float32)
    a = np.asarray(im, np.float32)
    rr, dist = rays(W, H, P["src"], 7)
    rcol = np.array((255, 150, 100) if theme == "samurai" else (170, 255, 215), np.float32)
    a = a + rr[..., None] * rcol * 0.18 + np.exp(-(dist / 0.12) ** 2)[..., None] * 0.10 * rcol
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    m = lin_grad_mask(W, H, 0.0, 0.6, 0.80, 0.0, 1.5)
    pool = np.exp(-(((xx / W - 0.17) / 0.26) ** 2 + ((yy / H - 0.66) / 0.30) ** 2)) * 0.55
    m = np.clip(np.maximum(m, pool), 0, 0.9)
    m = np.maximum(m, np.clip((yy / H - 0.75) / 0.25, 0, 1) ** 1.5 * 0.5)
    a = a * (1 - m[..., None]) + base * m[..., None]
    pool2 = np.exp(-(((xx / W - 0.15) / 0.22) ** 2 + ((yy / H - 0.67) / 0.22) ** 2)) * 0.45
    a = a * (1 - pool2[..., None]) + base * pool2[..., None]
    out = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")
    if particles_on:
        if theme == "samurai":
            layers = [particles(W, H, "petal", 3, 300, lambda u, v: u > 0.48 or v < 0.10, (2, 5)),
                      particles(W, H, "petal", 5, 40, lambda u, v: u > 0.5, (5, 8)).filter(ImageFilter.GaussianBlur(1 * s)),
                      particles(W, H, "petal", 4, 12, lambda u, v: u > 0.62, (12, 20)).filter(ImageFilter.GaussianBlur(4 * s))]
        else:
            layers = [particles(W, H, "mote", 3, 240, lambda u, v: u > 0.48, (1.5, 4), (255, 220, 140)),
                      particles(W, H, "mote", 5, 40, lambda u, v: u > 0.5, (3, 6), (150, 255, 205)).filter(ImageFilter.GaussianBlur(1 * s)),
                      particles(W, H, "mote", 4, 14, lambda u, v: u > 0.62, (7, 13), (255, 214, 130)).filter(ImageFilter.GaussianBlur(4 * s))]
        for l in layers: out.alpha_composite(l)
    return out


def wordmark(canvas, theme, x, y, size, s=1.0, style=None):
    """Bake the wordmark: optional dry-brush swipe, a plain ink shadow, and washi-to-gold letters with ink-bled edges.
    Flat and crisp (Naman: no neon, no glow): no coloured halo around the letters, the swipe or the bead."""
    P = PAL[theme]; word = P["word"]; style = style or P["style"]
    fp, tr = (MARC, 0.30) if style == "marcellus" else (CIND, 0.10)
    m, bb = text_mask(word, fp, size, tr, pad=int(80 * s))
    wW, wH = bb[2] - bb[0], bb[3] - bb[1]
    if style in ("cinzel+", "marcellus"):
        bw, bh = int(wW * 1.12), int(wH * 0.70)
        sm = mask_img(brush_stroke(bw, bh, seed=11, dry=0.55, head=0.035, tail=0.55, wave=0.05)).rotate(-2.0, expand=True, resample=Image.BICUBIC)
        smf = Image.new("L", canvas.size, 0); smf.paste(sm, (x - int(40 * s), y + int(wH * 0.38)))
        col = hexc(P["acc"])
        canvas = add_layer(canvas, col, smf, 0.80)
    m = m.crop((bb[0] - int(60 * s), bb[1] - int(60 * s), bb[2] + int(60 * s), bb[3] + int(60 * s)))
    full = Image.new("L", canvas.size, 0); full.paste(m, (x - int(60 * s), y - int(60 * s)))
    canvas = add_layer(canvas, (0, 0, 0), full.filter(ImageFilter.GaussianBlur(14 * s)), 0.85)
    bled = ink_bleed(full, seed=5, amt=1.2 * s)
    top, g = hexc(P["text"]), hexc(P["gold"]); Hc = canvas.height
    fill = grad_fill(canvas.size, [(0, top[:3]), (y / Hc, top[:3]),
                                   ((y + wH * 0.55) / Hc, tuple(int(a * 0.6 + b * 0.4) for a, b in zip(top[:3], g[:3]))),
                                   ((y + wH * 1.2) / Hc, g[:3]), (1, g[:3])]).convert("RGBA")
    fill.putalpha(bled)
    return Image.alpha_composite(canvas, fill), (x, y, wW, wH)


def title_block(canvas, theme, s=1.0, x=None, base_y=330, target_w=820, max_size=205, style=None, hint=True):
    """Wordmark + gold hairline with a diamond bead + tracked tagline. Returns canvas and the block's box."""
    P = PAL[theme]; style = style or P["style"]; x = LX if x is None else x
    fp, tr = (MARC, 0.30) if style == "marcellus" else (CIND, 0.10)
    size = min(int(max_size * s), word_size(P["word"], fp, tr, target_w * s))
    m, bb = text_mask(P["word"], fp, size, tr, pad=10); wW, wH = bb[2] - bb[0], bb[3] - bb[1]
    y0 = int(base_y * s) - wH
    canvas, _ = wordmark(canvas, theme, int(x * s), y0, size, s, style)
    gold = hexc(P["gold"]); hy = int((base_y + 42) * s)
    hl = hairline(int(wW + 60 * s), gold, thick=max(1, int(s)))
    pos = (int(x * s - 30 * s), hy - hl.height // 2)
    canvas.alpha_composite(hl, pos)
    bx = int(x * s + wW / 2); r = int(5 * s)
    bead = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(bead).polygon([(bx, hy - r), (bx + r, hy), (bx, hy + r), (bx - r, hy)], fill=gold)
    canvas.alpha_composite(bead)
    place_text(canvas, (x * s + wW / 2, hy + int(22 * s)), P["tag"], MARC, int(21 * s), hexc(P["gold"], 235), track_em=0.62, anchor="c")
    return canvas, (int(x * s), y0, wW, wH)
