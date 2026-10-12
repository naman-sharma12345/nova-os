#!/usr/bin/env python3
"""Tenka folder icons (places): one drawn set per theme, written into the Tenka-<Theme> icon themes.
Direction is chosen by FOLDER_STYLE (edge [default] | flat | paper | lacquer | line | washi).
The default is quiet on purpose (Naman, Oct 10: "simple, not neon glow"): flat shapes, no glow, no shadow. Run: python3 scripts/gen-folders.py [style]"""
import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAL = {
    "samurai": dict(theme="Tenka-Samurai", base="#0f0d0c", body="#2a2320", body2="#3a302a", gold="#c9a35a", accent="#d8412f", paper="#efe6d6", ink="#fff8ec",
                    # the quiet sets: muted stone (flat), raw washi (paper), dark ink (edge)
                    stone="#6e6259", stone2="#564b44", washi="#d6cbb8", washi2="#b3a591", inkb="#4d413a", inkb2="#5e5048"),
    "xianxia": dict(theme="Tenka-Xianxia", base="#0b1513", body="#1a2e29", body2="#25403a", gold="#e2bd6b", accent="#5fc9a0", paper="#eef3ec", ink="#0b1513",
                    stone="#4a625b", stone2="#3a4f49", washi="#cfd8cf", washi2="#a9b8ad", inkb="#2f4a43", inkb2="#3c5b53"),
}
# glyphs, drawn on the folder's front (24x24 box placed at 12,19)
G = {
    "folder": "",
    "home": "M6 12l6-5 6 5M8 11v7h8v-7",
    "desktop": "M5 7h14v9H5zM10 19h4M12 16v3",
    "documents": "M8 6h6l3 3v10H8zM10 12h5M10 15h5",
    "download": "M12 5v10M8 11l4 4 4-4M7 19h10",
    "music": "M10 17V7l8-2v10M10 17a2 2 0 1 1-4 0 2 2 0 0 1 4 0zM18 15a2 2 0 1 1-4 0 2 2 0 0 1 4 0z",
    "pictures": "M5 7h14v11H5zM6 17l4-5 3 3 2-2 3 4M15 10.5a1 1 0 1 0 0 .1",
    "videos": "M10 8l6 4-6 4z",
    "templates": "M7 6h10v13H7zM9.5 10h5M9.5 13h5",
    "public": "M9 11a2 2 0 1 0 0-.1M15 11a2 2 0 1 0 0-.1M5 18c1-3 7-3 8 0M11 18c1-3 7-3 8 0",
    "remote": "M12 5a7 7 0 1 0 0 14 7 7 0 0 0 0-14zM5 12h14M12 5c3 3 3 11 0 14M12 5c-3 3-3 11 0 14",
    "bookmark": "M8 5h8v14l-4-3-4 3z",
}
NAMES = {
    "folder": ["folder", "inode-directory", "folder-open", "folder-drag-accept"],
    "home": ["user-home", "folder-home"], "desktop": ["user-desktop", "folder-desktop"],
    "documents": ["folder-documents"], "download": ["folder-download", "folder-downloads"],
    "music": ["folder-music"], "pictures": ["folder-pictures", "folder-images"], "videos": ["folder-videos"],
    "templates": ["folder-templates"], "public": ["folder-publicshare"], "remote": ["folder-remote", "network-workgroup"],
    "bookmark": ["user-bookmarks"],
}
BACK = "M4 12.5a3 3 0 0 1 3-3h10.5l4 4H41a3 3 0 0 1 3 3v21a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z"
FRONT = "M4 18.5h40v19a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z"

# devices and the bin, for the sidebar: same quiet language (flat ink body, one gold hairline)
DEV = {
    "computer": ["computer", "user-computer"],
    "drive": ["drive-harddisk", "drive-harddisk-system", "drive-removable-media", "drive-harddisk-usb"],
    "trash": ["user-trash"], "trash-full": ["user-trash-full"],
}

def dev_svg(kind, p):
    b, b2, gd = p["inkb"], p["inkb2"], p["gold"]
    if kind == "computer":
        return (f'<rect x="5" y="8" width="38" height="26" rx="3.5" fill="{b2}"/><rect x="8" y="11" width="32" height="20" rx="1.5" fill="{b}"/>'
                f'<path d="M18 40h12M24 34v6" stroke="{b2}" stroke-width="3" stroke-linecap="round"/><path d="M8.6 30.5h30.8" stroke="{gd}" stroke-width="1.1" stroke-opacity=".85"/>')
    if kind == "drive":
        return (f'<rect x="5" y="14" width="38" height="20" rx="4" fill="{b}"/><path d="M5.6 24h36.8" stroke="{gd}" stroke-width="1.1" stroke-opacity=".85"/>'
                f'<circle cx="36" cy="29" r="1.6" fill="{gd}" fill-opacity=".9"/>')
    full = kind == "trash-full"
    return ((f'<path d="M15 10h18l-1 4H16z" fill="{p["washi2"]}" fill-opacity=".55"/>' if full else "")
            + f'<path d="M11 15h26l-2.4 24a3 3 0 0 1-3 2.7H16.4a3 3 0 0 1-3-2.7z" fill="{b}"/>'
            f'<rect x="8" y="12" width="32" height="4" rx="2" fill="{b2}"/><path d="M19 9h10" stroke="{b2}" stroke-width="3" stroke-linecap="round"/>'
            f'<path d="M11.6 16.5h24.8" stroke="{gd}" stroke-width="1.1" stroke-opacity=".85"/>')

def svg(kind, p, style):
    g = G[kind]
    glyph = lambda col, w: (f'<g transform="translate(12 19) scale(1)" fill="none" stroke="{col}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"><path d="{g}"/></g>' if g else "")
    if style == "lacquer":   # dark lacquer box, gold rim, a seal stamped on the corner
        seal = (f'<rect x="31" y="27" width="10" height="10" rx="1.6" fill="{p["accent"]}" transform="rotate(-4 36 32)"/>'
                f'<circle cx="36" cy="32" r="1.6" fill="{p["paper"]}" fill-opacity=".85"/>') if kind == "folder" else ""
        return (f'<path d="{BACK}" fill="{p["body2"]}" stroke="{p["gold"]}" stroke-opacity=".55" stroke-width="1.2"/>'
                f'<path d="{FRONT}" fill="{p["body"]}" stroke="{p["gold"]}" stroke-width="1.6"/>'
                f'<path d="M7 21.5h34" stroke="{p["gold"]}" stroke-opacity=".35" stroke-width=".8"/>'
                + glyph(p["gold"], 1.8) + seal)
    if style == "line":      # the dock's gold line language: a glow pass, then the line
        body = (f'<path d="{BACK}" fill="{p["gold"]}" fill-opacity=".10" stroke="{p["gold"]}" stroke-width="2"/>'
                f'<path d="{FRONT}" fill="{p["gold"]}" fill-opacity=".14" stroke="{p["gold"]}" stroke-width="2"/>')
        return (f'<g opacity=".22"><path d="{FRONT}" fill="none" stroke="{p["gold"]}" stroke-width="5"/></g>' + body + glyph(p["gold"], 2))
    if style == "silk":      # Rice V: a lacquer back in the theme's colour, a silk-paper front that catches light
        #  (a soft top-to-bottom shade), one gold lip, the glyph as a fine ink line. Reads on dark glass, no glow.
        def mx(a, b, t):
            a, b = a.lstrip("#"), b.lstrip("#")
            return "#" + "".join(f"{round(int(a[i:i+2],16)*(1-t)+int(b[i:i+2],16)*t):02x}" for i in (0, 2, 4))
        back = mx(p["accent"], p["base"], 0.38)
        top, bot = p["paper"], mx(p["washi"], p["washi2"], 0.7)
        fine = (f'<g transform="translate(16.6 23.4) scale(.62)" fill="none" stroke="{p["base"]}" stroke-opacity=".62" stroke-width="2.2" '
                f'stroke-linecap="round" stroke-linejoin="round"><path d="{g}"/></g>' if g else "")
        return (f'<defs><linearGradient id="f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
                f'<stop offset="1" stop-color="{bot}"/></linearGradient></defs>'
                f'<path d="{BACK}" fill="{back}"/>'
                f'<path d="{FRONT}" fill="url(#f)"/>'
                f'<path d="M4.2 18.9h39.6" stroke="{p["gold"]}" stroke-width="1.2" stroke-opacity=".95"/>'
                f'<path d="M4 37.5v.0a3 3 0 0 0 3 3h34a3 3 0 0 0 3-3" fill="none" stroke="{p["base"]}" stroke-opacity=".18" stroke-width="1"/>'
                + fine)
    if style == "washi":     # pale paper folder with a lacquer tab: bold on dark surfaces
        return (f'<path d="{BACK}" fill="{p["accent"]}"/>'
                f'<path d="{FRONT}" fill="{p["paper"]}"/>'
                f'<path d="M4 18.5h40v3H4z" fill="{p["gold"]}" fill-opacity=".85"/>'
                + glyph(p["base"], 2))
    # --- the quiet sets (Naman: "simple, not neon glow"): flat shapes, no glow, no shadow, a tiny glyph at most
    small = lambda col, op: (f'<g transform="translate(17.5 22.5) scale(.55)" fill="none" stroke="{col}" stroke-opacity="{op}" stroke-width="2.6" '
                             f'stroke-linecap="round" stroke-linejoin="round"><path d="{g}"/></g>' if g else "")
    if style == "flat":      # one muted tone, the back a shade deeper; nothing else
        return f'<path d="{BACK}" fill="{p["stone2"]}"/><path d="{FRONT}" fill="{p["stone"]}"/>' + small(p["base"], .55)
    if style == "paper":     # raw washi, a deeper paper tab
        return f'<path d="{BACK}" fill="{p["washi2"]}"/><path d="{FRONT}" fill="{p["washi"]}"/>' + small(p["base"], .45)
    if style == "edge":      # dark ink body, one gold hairline along the front's top edge
        return (f'<path d="{BACK}" fill="{p["inkb2"]}"/><path d="{FRONT}" fill="{p["inkb"]}"/>'
                f'<path d="M4.6 18.5h38.8" stroke="{p["gold"]}" stroke-width="1.1" stroke-opacity=".85"/>' + small(p["gold"], .7))
    raise SystemExit("unknown style " + style)

def doc(inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">{inner}</svg>\n'

def write(style, out_root=None):
    for name, p in PAL.items():
        d = out_root or os.path.join(ROOT, "live/config/includes.chroot/usr/share/icons", p["theme"], "scalable/places")
        d = os.path.join(d, name) if out_root else d
        os.makedirs(d, exist_ok=True)
        for kind, names in NAMES.items():
            s = doc(svg(kind, p, style))
            for n in names:
                open(os.path.join(d, n + ".svg"), "w").write(s)
        if style in ("edge", "flat", "paper", "silk"):
            for kind, names in DEV.items():
                s = doc(dev_svg(kind, p))
                for n in names:
                    open(os.path.join(d, n + ".svg"), "w").write(s)

# file types (mimetypes): a dark ink page with a deeper folded corner, one gold hairline under a tiny gold glyph;
# the same quiet language as the folders, so the file view stops mixing in Papirus' grey and coloured pages
PAGE = "M12 5h17l9 9v27a2 2 0 0 1-2 2H12a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z"
FOLD = "M29 5v7a2 2 0 0 0 2 2h7z"
MG = {
    "text": "M7 8h10M7 11h10M7 14h6",
    "code": "M9 8l-4 4 4 4M15 8l4 4-4 4M13 7l-2 10",
    "image": G["pictures"], "video": G["videos"], "audio": G["music"],
    "document": "M7 7h10M7 10h10M7 13h10M7 16h6",
    "archive": "M12 4v2M12 8v2M12 12v2M10 16h4v4h-4z",
    "exec": "M8 8h8v8H8zM12 5v3M12 16v3M5 12h3M16 12h3",
    "blank": "",
}
MNAMES = {
    "text": ["text-x-generic", "text-plain", "text-x-readme", "text-markdown", "text-x-log", "text-x-changelog"],
    "code": ["text-x-script", "application-x-shellscript", "text-x-python", "text-x-csrc", "text-x-chdr", "text-x-c++src",
             "application-javascript", "text-html", "application-json", "application-xml", "text-css", "text-x-makefile"],
    "image": ["image-x-generic", "image-png", "image-jpeg", "image-svg+xml", "image-gif", "image-webp"],
    "video": ["video-x-generic", "video-mp4", "video-x-matroska", "video-webm"],
    "audio": ["audio-x-generic", "audio-mpeg", "audio-x-wav", "audio-flac", "audio-ogg"],
    "document": ["application-pdf", "x-office-document", "application-vnd.oasis.opendocument.text", "application-msword"],
    "archive": ["package-x-generic", "application-zip", "application-x-tar", "application-x-compressed-tar", "application-x-archive",
                "application-x-7z-compressed", "application-vnd.debian.binary-package"],
    "exec": ["application-x-executable", "application-x-sharedlib"],
    "blank": ["unknown", "application-octet-stream", "text-x-generic-template"],
}

def mime_svg(kind, p):
    # Rice V: a silk-paper page (the folders' front), a deeper paper fold, the type's glyph as a fine ink line and one
    # short lip of the theme's colour at the foot: light enough to read on the dark glass the windows are made of
    g = MG[kind]
    def mx(a, b, t):
        a, b = a.lstrip("#"), b.lstrip("#")
        return "#" + "".join(f"{round(int(a[i:i+2],16)*(1-t)+int(b[i:i+2],16)*t):02x}" for i in (0, 2, 4))
    glyph = (f'<g transform="translate(16 18) scale(.67)" fill="none" stroke="{p["base"]}" stroke-opacity=".62" stroke-width="2.2" '
             f'stroke-linecap="round" stroke-linejoin="round"><path d="{g}"/></g>') if g else ""
    return (f'<defs><linearGradient id="m" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{p["paper"]}"/>'
            f'<stop offset="1" stop-color="{mx(p["washi"], p["washi2"], 0.7)}"/></linearGradient></defs>'
            f'<path d="{PAGE}" fill="url(#m)"/><path d="{FOLD}" fill="{p["washi2"]}"/>'
            f'<path d="M15 37h18" stroke="{mx(p["accent"], p["base"], 0.2)}" stroke-width="1.4" stroke-linecap="round"/>' + glyph)


def write_mimes():
    for name, p in PAL.items():
        d = os.path.join(ROOT, "live/config/includes.chroot/usr/share/icons", p["theme"], "scalable/mimetypes")
        os.makedirs(d, exist_ok=True)
        for kind, names in MNAMES.items():
            s = doc(mime_svg(kind, p))
            for n in names:
                open(os.path.join(d, n + ".svg"), "w").write(s)

if __name__ == "__main__":
    style = (sys.argv[1] if len(sys.argv) > 1 else os.environ.get("FOLDER_STYLE", "silk"))
    out = sys.argv[2] if len(sys.argv) > 2 else None
    write(style, out)
    if out is None: write_mimes()
    print("folders:", style)
