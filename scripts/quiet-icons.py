#!/usr/bin/env python3
"""Quiet the drawn Tenka line icons (app icons in Tenka-<Theme>, the shell's own icons): drop the
soft glow pass under each line and settle the line at 1.9 px. Idempotent.
Naman, Oct 10: "simple, not neon glow". Run: python3 scripts/quiet-icons.py"""
import glob, os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLOW = re.compile(r'<g fill="none" stroke="[^"]+" stroke-opacity="0\.2\d*" stroke-width="[\d.]+"[^>]*>.*?</g>', re.S)
files = (glob.glob(os.path.join(ROOT, "live/config/includes.chroot/usr/share/icons/Tenka-*/scalable/*/*.svg"))
         + glob.glob(os.path.join(ROOT, "shell/quickshell/tenka/assets/*/icons/*.svg")))
n = 0
for f in files:
    s = open(f).read()
    t = GLOW.sub("", s, count=1)
    t = t.replace('stroke-width="2.2"', 'stroke-width="1.9"')
    if t != s:
        open(f, "w").write(t); n += 1
print("quiet icons:", n, "of", len(files))
