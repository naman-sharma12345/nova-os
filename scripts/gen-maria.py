#!/usr/bin/env python3
"""gen-maria.py: makes shell/quickshell/tenka/assets/maria.png, the near side's seas as a flat mask (black, alpha =
how much sea), drawn under the lit part of the moon by the Moon Viewing card and the desk's moon.

Source: NASA Scientific Visualization Studio, CGI Moon Kit, lroc_color_poles_1k.jpg (LRO/LROC; NASA imagery is
in the public domain): https://svs.gsfc.nasa.gov/4720. The map is projected orthographically onto the near side
(libration ignored), blurred a little, and everything darker than the highlands becomes sea, with a soft edge.
Run once by hand with the map saved beside it; the build does not fetch anything.
    python3 scripts/gen-maria.py lroc_color_poles_1k.jpg
"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter

N = 256
src = sys.argv[1] if len(sys.argv) > 1 else "lroc_color_poles_1k.jpg"
mp = np.asarray(Image.open(src).convert("L"), dtype=np.float32) / 255
H, W = mp.shape
yy, xx = np.mgrid[0:N, 0:N]
X = (xx + 0.5 - N / 2) / (N / 2); Y = (yy + 0.5 - N / 2) / (N / 2)
rr = np.sqrt(X ** 2 + Y ** 2); inside = rr <= 1
lat = np.arcsin(np.clip(-Y, -1, 1)); lon = np.arcsin(np.clip(X / np.maximum(np.cos(lat), 1e-6), -1, 1))
u = ((np.degrees(lon) + 180) / 360 * W).astype(int) % W; v = ((90 - np.degrees(lat)) / 180 * H).astype(int).clip(0, H - 1)
ortho = Image.fromarray((np.where(inside, mp[v, u], 0) * 255).astype(np.uint8))
sm = np.asarray(ortho.filter(ImageFilter.GaussianBlur(1.6)), dtype=np.float32) / 255
mask = np.clip((0.405 - sm) / 0.05, 0, 1) * inside * np.clip((1 - rr) / 0.04, 0, 1)
a = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
out = np.zeros((N, N, 4), np.uint8); out[..., 3] = np.asarray(a)
dst = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "shell", "quickshell", "tenka", "assets", "maria.png")
Image.fromarray(out, "RGBA").save(dst, optimize=True)
print("maria.png:", dst)
