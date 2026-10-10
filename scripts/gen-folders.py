#!/usr/bin/env python3
"""Tenka folder icons (places): one drawn set per theme, written into the Tenka-<Theme> icon themes.
Direction is chosen by FOLDER_STYLE (lacquer | line | washi). Run: python3 scripts/gen-folders.py [style]"""
import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAL = {
    "samurai": dict(theme="Tenka-Samurai", base="#0f0d0c", body="#2a2320", body2="#3a302a", gold="#c9a35a", accent="#d8412f", paper="#efe6d6", ink="#fff8ec"),
    "xianxia": dict(theme="Tenka-Xianxia", base="#0b1513", body="#1a2e29", body2="#25403a", gold="#e2bd6b", accent="#5fc9a0", paper="#eef3ec", ink="#0b1513"),
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
    if style == "washi":     # pale paper folder with a lacquer tab: bold on dark surfaces
        return (f'<path d="{BACK}" fill="{p["accent"]}"/>'
                f'<path d="{FRONT}" fill="{p["paper"]}"/>'
                f'<path d="M4 18.5h40v3H4z" fill="{p["gold"]}" fill-opacity=".85"/>'
                + glyph(p["base"], 2))
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

if __name__ == "__main__":
    style = (sys.argv[1] if len(sys.argv) > 1 else os.environ.get("FOLDER_STYLE", "line"))
    out = sys.argv[2] if len(sys.argv) > 2 else None
    write(style, out)
    print("folders:", style)
