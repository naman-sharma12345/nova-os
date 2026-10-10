#!/usr/bin/env python3
"""Tenka cursors: a small custom Xcursor theme per pack, drawn here and written as Xcursor files
in pure Python (no xcursorgen needed).

    python3 scripts/gen-cursors.py      # -> live/config/includes.chroot/usr/share/icons/Tenka-<Pack>-Cursors

Quiet by rule: an ink body, one crisp metallic edge (gold in Tenka, pale jade in Tianxia), no glow,
no gradients. Shapes we do not draw fall back to Bibata via Inherits=.
"""
import os, struct, math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "live/config/includes.chroot/usr/share/icons")
PACKS = {
    "Samurai": dict(ink=(15, 13, 12), edge=(201, 163, 90), mark=(216, 65, 47), inherit="Bibata-Modern-Classic"),
    "Xianxia": dict(ink=(11, 21, 19), edge=(214, 236, 224), mark=(95, 201, 160), inherit="Bibata-Modern-Ice"),
}
SIZES = [24, 32, 48, 64]
SS = 8  # supersampling

def S(v, n):  # design units are a 32 px canvas
    return v * n / 32 * SS

def canvas(n):
    return Image.new("RGBA", (n * SS, n * SS), (0, 0, 0, 0))

def finish(im, n):
    return im.resize((n, n), Image.LANCZOS)

def poly(d, pts, n, fill, edge, w):
    P = [(S(x, n), S(y, n)) for x, y in pts]
    d.polygon(P, fill=fill)
    d.line(P + [P[0]], fill=edge, width=max(1, int(round(w * n / 32 * SS))), joint="curve")

def arrow(n, c, mark=False):
    im = canvas(n); d = ImageDraw.Draw(im)
    # a slim, slightly long arrow with a straight tail
    pts = [(3, 2), (3, 24.5), (8.6, 19.4), (12.4, 27.6), (16.0, 26.0), (12.3, 18.0), (19.8, 17.6)]
    poly(d, pts, n, c["ink"] + (255,), c["edge"] + (255,), 1.6)
    if mark:  # progress: a small open ring beside the arrow
        r = S(4.6, n); cx, cy = S(24.5, n), S(25.0, n)
        d.arc([cx - r, cy - r, cx + r, cy + r], start=-90, end=200, fill=c["mark"] + (255,), width=int(S(1.6, n)))
    return finish(im, n), (round(3 * n / 32), round(2 * n / 32))

def hand(n, c):
    # a pointing hand drawn as one silhouette (index finger up at the left, three folded fingers,
    # thumb, palm), then outlined: ink body, one crisp edge
    m = Image.new("L", (n * SS, n * SS), 0); d = ImageDraw.Draw(m)
    R = lambda x0, y0, x1, y1, r: d.rounded_rectangle([S(x0, n), S(y0, n), S(x1, n), S(y1, n)], radius=S(r, n), fill=255)
    R(9.2, 1.8, 14.0, 19, 2.4)                       # index finger
    R(13.6, 11.6, 17.9, 20, 2.1); R(17.5, 12.8, 21.8, 21, 2.1); R(21.4, 14.4, 25.6, 22, 2.1)   # folded fingers
    R(9.2, 16.5, 25.6, 29.6, 5.2)                    # palm
    d.line([S(10.5, n), S(23.5, n), S(5.6, n), S(17.6, n)], fill=255, width=int(S(4.2, n)))      # thumb
    d.ellipse([S(3.5, n), S(15.5, n), S(7.7, n), S(19.7, n)], fill=255)
    k = max(3, int(round(1.6 * n / 32 * SS)) * 2 + 1)
    outer = m.filter(ImageFilter.MaxFilter(k))
    im = Image.new("RGBA", m.size, c["edge"] + (0,)); im.putalpha(outer)
    body = Image.new("RGBA", m.size, c["ink"] + (255,)); im.paste(body, (0, 0), m)
    d2 = ImageDraw.Draw(im); w = max(1, int(round(1.1 * n / 32 * SS)))
    for x, y0 in ((13.8, 12.6), (17.7, 13.8), (21.6, 15.4)):   # the creases between fingers
        d2.line([S(x, n), S(y0, n), S(x, n), S(19.5, n)], fill=c["edge"] + (255,), width=w)
    return finish(im, n), (round(11.6 * n / 32), round(2 * n / 32))

def beam(n, c):
    im = canvas(n); d = ImageDraw.Draw(im)
    W = max(1, int(round(2.4 * n / 32 * SS)))
    e = c["edge"] + (255,); k = c["ink"] + (255,)
    for col, w in ((k, W + int(S(2.2, n))), (e, W)):
        d.line([S(16, n), S(6, n), S(16, n), S(26, n)], fill=col, width=w)
        d.line([S(12, n), S(5.5, n), S(20, n), S(5.5, n)], fill=col, width=w)
        d.line([S(12, n), S(26.5, n), S(20, n), S(26.5, n)], fill=col, width=w)
    return finish(im, n), (n // 2, n // 2)

def cross(n, c):
    im = canvas(n); d = ImageDraw.Draw(im)
    W = max(1, int(round(1.8 * n / 32 * SS))); e = c["edge"] + (255,); k = c["ink"] + (255,)
    for col, w in ((k, W + int(S(2, n))), (e, W)):
        d.line([S(16, n), S(4, n), S(16, n), S(13, n)], fill=col, width=w); d.line([S(16, n), S(19, n), S(16, n), S(28, n)], fill=col, width=w)
        d.line([S(4, n), S(16, n), S(13, n), S(16, n)], fill=col, width=w); d.line([S(19, n), S(16, n), S(28, n), S(16, n)], fill=col, width=w)
    d.rectangle([S(15.2, n), S(15.2, n), S(16.8, n), S(16.8, n)], fill=c["mark"] + (255,))
    return finish(im, n), (n // 2, n // 2)

def ring(n, c, frame, frames):
    im = canvas(n); d = ImageDraw.Draw(im)
    r = S(9, n); cx = cy = S(16, n); W = int(S(2.4, n))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c["ink"] + (255,), width=W + int(S(2, n)))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c["edge"] + (110,), width=W)
    a = frame * 360 / frames
    d.arc([cx - r, cy - r, cx + r, cy + r], start=a - 90, end=a + 30, fill=c["mark"] + (255,), width=W)
    return finish(im, n), (n // 2, n // 2)

def write_xcursor(path, frames_by_size, delay=0):
    """frames_by_size: {nominal: [(PIL RGBA, (xhot, yhot)), ...]}"""
    chunks = []
    for nom, frames in sorted(frames_by_size.items()):
        for im, (xh, yh) in frames:
            w, h = im.size
            px = im.load(); data = bytearray()
            for y in range(h):
                for x in range(w):
                    r, g, b, a = px[x, y]
                    r, g, b = r * a // 255, g * a // 255, b * a // 255  # premultiplied ARGB
                    data += struct.pack("<I", (a << 24) | (r << 16) | (g << 8) | b)
            chunks.append((nom, struct.pack("<9I", 36, 0xFFFD0002, nom, 1, w, h, xh, yh, delay) + bytes(data)))
    n = len(chunks); pos = 16 + 12 * n; toc = b""; body = b""
    for nom, ch in chunks:
        toc += struct.pack("<3I", 0xFFFD0002, nom, pos + len(body)); body += ch
    with open(path, "wb") as f:
        f.write(b"Xcur" + struct.pack("<3I", 16, 0x10000, n) + toc + body)

ALIASES = {
    "left_ptr": ["default", "arrow", "top_left_arrow", "left_arrow"],
    "hand2": ["pointer", "hand1", "pointing_hand", "9d800788f1b08800ae810202380a0822", "e29285e634086352946a0e7090d73106"],
    "xterm": ["text", "ibeam"],
    "crosshair": ["cross", "tcross", "cell"],
    "watch": ["wait"],
    "left_ptr_watch": ["progress", "half-busy", "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"],
}

def main():
    for pack, c in PACKS.items():
        name = f"Tenka-{pack}-Cursors"; root = os.path.join(OUT, name); cd = os.path.join(root, "cursors")
        os.makedirs(cd, exist_ok=True)
        with open(os.path.join(root, "index.theme"), "w") as f:
            f.write(f"[Icon Theme]\nName={name}\nComment=Tenka cursors: ink body, one crisp edge\nInherits={c['inherit']}\n")
        with open(os.path.join(root, "cursor.theme"), "w") as f:
            f.write(f"[Icon Theme]\nInherits={name}\n")
        single = {"left_ptr": lambda n: arrow(n, c), "hand2": lambda n: hand(n, c), "xterm": lambda n: beam(n, c),
                  "crosshair": lambda n: cross(n, c)}
        for nm, fn in single.items():
            write_xcursor(os.path.join(cd, nm), {s: [fn(s)] for s in SIZES})
        F = 12
        write_xcursor(os.path.join(cd, "watch"), {s: [ring(s, c, i, F) for i in range(F)] for s in SIZES}, delay=60)
        write_xcursor(os.path.join(cd, "left_ptr_watch"), {s: [arrow(s, c, mark=True)] for s in SIZES})
        for src, al in ALIASES.items():
            for a in al:
                p = os.path.join(cd, a)
                if os.path.lexists(p): os.remove(p)
                os.symlink(src, p)
        print("cursors:", root)

if __name__ == "__main__":
    main()
