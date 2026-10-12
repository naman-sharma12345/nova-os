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

def _rot(pts, deg):
    a = math.radians(deg); ca, sa = math.cos(a), math.sin(a)
    return [(16 + (x - 16) * ca - (y - 16) * sa, 16 + (x - 16) * sa + (y - 16) * ca) for x, y in pts]

# a slim double-headed arrow along the x axis (design units), turned for each resize direction
DBL = [(3.5, 16), (10, 10.2), (10, 14.5), (22, 14.5), (22, 10.2), (28.5, 16), (22, 21.8), (22, 17.5), (10, 17.5), (10, 21.8)]

def stroked(n, c, polys, mark=False):
    # ink body with one crisp edge stroked round it (round joins, so tips stay pointed and the notches
    # between heads stay open), then the body laid over the strokes
    im = canvas(n); d = ImageDraw.Draw(im); m = Image.new("L", im.size, 0); dm = ImageDraw.Draw(m)
    w = max(1, int(round(1.4 * n / 32 * SS))) * 2; e = c["edge"] + (255,)
    for pts in polys:
        P = [(S(x, n), S(y, n)) for x, y in pts]
        d.line(P + [P[0]], fill=e, width=w, joint="curve"); d.polygon(P, fill=e)
        for x, y in P: d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=e)
        dm.polygon(P, fill=255)
    im.paste(Image.new("RGBA", m.size, c["ink"] + (255,)), (0, 0), m)
    if mark: d.rectangle([S(15.0, n), S(15.0, n), S(17.0, n), S(17.0, n)], fill=c["mark"] + (255,))
    return finish(im, n), (n // 2, n // 2)

def resize(n, c, deg):
    return stroked(n, c, [_rot(DBL, deg)])

MOV = [(3.5, 16), (9.5, 11.8), (9.5, 14.6), (22.5, 14.6), (22.5, 11.8), (28.5, 16), (22.5, 20.2), (22.5, 17.4), (9.5, 17.4), (9.5, 20.2)]

def move(n, c):
    return stroked(n, c, [_rot(MOV, 0), _rot(MOV, 90)], mark=True)

def noway(n, c):
    # the arrow with a small barred ring beside it, in the pack's mark colour
    im = canvas(n); d = ImageDraw.Draw(im)
    poly(d, [(3, 2), (3, 24.5), (8.6, 19.4), (12.4, 27.6), (16.0, 26.0), (12.3, 18.0), (19.8, 17.6)], n, c["ink"] + (255,), c["edge"] + (255,), 1.6)
    r = S(4.8, n); cx, cy = S(24.5, n), S(24.5, n); W = max(1, int(S(1.7, n)))
    d.ellipse([cx - r - S(1.2, n), cy - r - S(1.2, n), cx + r + S(1.2, n), cy + r + S(1.2, n)], fill=c["ink"] + (255,))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c["mark"] + (255,), width=W)
    q = r * 0.7071
    d.line([cx - q, cy + q, cx + q, cy - q], fill=c["mark"] + (255,), width=W)
    return finish(im, n), (round(3 * n / 32), round(2 * n / 32))

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

def write_hyprcursor(root, name, shapes, aliases, pack):
    """The same shapes as a hyprcursor theme (manifest.hl + one .hlc zip per shape), so Hyprland draws them
    at any scale from its own loader; Xcursor stays for X apps, Lite and anything that does not read hyprcursor."""
    import io, zipfile
    hd = os.path.join(root, "hyprcursors"); os.makedirs(hd, exist_ok=True)
    with open(os.path.join(root, "manifest.hl"), "w") as f:
        f.write(f"name = {name}\ndescription = Tenka {pack} cursors: ink body, one crisp edge\nversion = 1\ncursors_directory = hyprcursors\n")
    for shape, (frames_by_size, delay) in shapes.items():
        first = frames_by_size[min(frames_by_size)][0]
        im0, (xh, yh) = first
        meta = ["resize_algorithm = bilinear", f"hotspot_x = {xh / im0.size[0]:.3f}", f"hotspot_y = {yh / im0.size[1]:.3f}"]
        meta += [f"define_override = {a}" for a in aliases.get(shape, [])]
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
            for sz, frames in sorted(frames_by_size.items()):
                for i, (im, _) in enumerate(frames):
                    fn = f"{shape}_{sz}" + (f"_{i:02d}" if len(frames) > 1 else "") + ".png"
                    b = io.BytesIO(); im.save(b, "PNG"); z.writestr(fn, b.getvalue())
                    meta.append(f"define_size = {sz}, {fn}" + (f", {delay}" if len(frames) > 1 else ""))
            z.writestr("meta.hl", "\n".join(meta) + "\n")
        with open(os.path.join(hd, shape + ".hlc"), "wb") as f: f.write(buf.getvalue())

ALIASES = {
    "left_ptr": ["default", "arrow", "top_left_arrow", "left_arrow"],
    "hand2": ["pointer", "hand1", "pointing_hand", "9d800788f1b08800ae810202380a0822", "e29285e634086352946a0e7090d73106"],
    "xterm": ["text", "ibeam"],
    "crosshair": ["cross", "tcross", "cell"],
    "watch": ["wait"],
    "left_ptr_watch": ["progress", "half-busy", "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"],
    # window edges and corners (Hyprland asks for these when you resize by the border) and their CSS names
    "sb_v_double_arrow": ["ns-resize", "n-resize", "s-resize", "top_side", "bottom_side", "row-resize", "size_ver", "v_double_arrow",
                          "split_v", "00008160000006810000408080010102", "2870a09082c103050810ffdffffe0204"],
    "sb_h_double_arrow": ["ew-resize", "e-resize", "w-resize", "left_side", "right_side", "col-resize", "size_hor", "h_double_arrow",
                          "split_h", "028006030e0e7ebffc7f7070c0600140", "14fef782d02440884392942c11205230"],
    "bd_double_arrow": ["nwse-resize", "nw-resize", "se-resize", "top_left_corner", "bottom_right_corner", "size_fdiag",
                        "c7088f0f3e6c8088236ef8e1e3e70000"],
    "fd_double_arrow": ["nesw-resize", "ne-resize", "sw-resize", "top_right_corner", "bottom_left_corner", "size_bdiag",
                        "fcf1c3c7cd4491d801f1e1c78f100000"],
    "fleur": ["move", "all-scroll", "size_all", "grab", "grabbing", "closedhand", "openhand", "dnd-move", "pointer-move",
              "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f"],
    "circle": ["not-allowed", "no-drop", "dnd-no-drop", "forbidden", "crossed_circle", "03b6e0fcb3499374a867c041f52298f0"],
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
        single.update({"sb_v_double_arrow": lambda n: resize(n, c, 90), "sb_h_double_arrow": lambda n: resize(n, c, 0),
                       "bd_double_arrow": lambda n: resize(n, c, 45), "fd_double_arrow": lambda n: resize(n, c, -45),
                       "fleur": lambda n: move(n, c), "circle": lambda n: noway(n, c),
                       "left_ptr_watch": lambda n: arrow(n, c, mark=True)})
        F = 12
        shapes = {nm: ({s: [fn(s)] for s in SIZES}, 0) for nm, fn in single.items()}
        shapes["watch"] = ({s: [ring(s, c, i, F) for i in range(F)] for s in SIZES}, 60)
        for nm, (fbs, delay) in shapes.items():
            write_xcursor(os.path.join(cd, nm), fbs, delay=delay)
        write_hyprcursor(root, name, shapes, ALIASES, pack)
        for src, al in ALIASES.items():
            for a in al:
                p = os.path.join(cd, a)
                if os.path.lexists(p): os.remove(p)
                os.symlink(src, p)
        print("cursors:", root)

if __name__ == "__main__":
    main()
