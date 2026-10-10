# Writes themes/<theme>/home/.config/tenka/shell-theme.json: the words, colours and art the
# Tenka shell (shell/quickshell/tenka) reads for each pack. tenka-theme copies it into $HOME.
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKS = {
  "samurai": {
    "name": "samurai",
    "display": "Tenka",
    "word": "TENKA",
    "tagline": "ALL UNDER HEAVEN",
    "base": "#0f0d0c",
    "surface": "#1a1614",
    "accent": "#d8412f",
    "gold": "#c9a35a",
    "text": "#efe6d6",
    "subtext": "#b8ab96",
    "ink": "#fff8ec",
    "wallpaper": "/usr/share/tenka/themes/samurai/wallpapers/00-desktop.jpg",
    "keyart": "/usr/share/tenka/themes/samurai/keyart.jpg",
    "crest": "/usr/share/tenka/themes/samurai/crest-1024.png",
    "stroke": "/usr/share/grub/themes/tenka-samurai/select_c.png",
    "sounds": "/usr/share/tenka/themes/samurai/sounds",
    "clan": "Ronin of the Tenka clan",
    "seekWord": "Seek",
    "lockWord": "Guard",
    "logoutWord": "Retreat",
    "suspendWord": "Rest",
    "rebootWord": "Return",
    "shutdownWord": "Sheathe",
    "stillWord": "Stillness",
    "proverbs": [
      "Fall seven times, stand up eight.",
      "The bamboo that bends is stronger than the oak that resists.",
      "The sword is the soul.",
      "Even monkeys fall from trees.",
      "A single arrow is easily broken, not ten in a bundle.",
      "Beginning is easy. Continuing is hard."
    ]
  },
  "xianxia": {
    "name": "xianxia",
    "display": "Tianxia",
    "word": "TIANXIA",
    "tagline": "ALL UNDER HEAVEN",
    "base": "#0b1513",
    "surface": "#12201d",
    "accent": "#5fc9a0",
    "gold": "#e2bd6b",
    "text": "#eef3ec",
    "subtext": "#a9bdb4",
    "ink": "#06110e",
    "wallpaper": "/usr/share/tenka/themes/xianxia/wallpapers/00-desktop.jpg",
    "keyart": "/usr/share/tenka/themes/xianxia/keyart.jpg",
    "crest": "/usr/share/tenka/themes/xianxia/crest-1024.png",
    "stroke": "/usr/share/grub/themes/tenka-xianxia/select_c.png",
    "sounds": "/usr/share/tenka/themes/xianxia/sounds",
    "clan": "Disciple of the Tianxia sect",
    "seekWord": "Divine",
    "lockWord": "Seal",
    "logoutWord": "Descend",
    "suspendWord": "Meditate",
    "rebootWord": "Rebirth",
    "shutdownWord": "Ascend",
    "stillWord": "Seclusion",
    "proverbs": [
      "A journey of a thousand li begins beneath your feet.",
      "Water is soft, yet it wears away stone.",
      "Cultivate the heart, and the sword will follow.",
      "Heaven and earth are wide. The heart is wider.",
      "The Dao that can be named is not the eternal Dao.",
      "Still water runs deep."
    ]
  }
}
for name, pack in PACKS.items():
    d = os.path.join(ROOT, "themes", name, "home", ".config", "tenka")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "shell-theme.json"), "w") as f:
        json.dump(pack, f, indent=2, ensure_ascii=False)
print("shell themes written")
