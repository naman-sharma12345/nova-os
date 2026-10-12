#!/usr/bin/env python3
"""gen-ambience.py: The Garden's four sound beds (Tianxia: The Mountain Hall), made here from noise and a few
sine partials. No samples and no recordings, so nothing to license.

  rain    rain on a wooden roof: a soft wash, thousands of small drops, now and then a nearer one
  stream  a shallow stream over stones: moving water bands and a babble of small bright bubbles
  pines   wind in pine trees: gusts that rise and fall, the needles' hiss riding on them
  embers  a low fire: a quiet roar under crackles and the odd pop

Everything is built on one 48-second circle (filters in the frequency domain, slow swells with whole cycles,
events wrapped around the end), so each file loops with no seam and no crossfade. Written as Ogg Vorbis to
live/config/includes.chroot/usr/share/sounds/tenka-ambience/<name>.ogg. Outputs are committed; run this again
(needs numpy and ffmpeg with libvorbis) only to change them.
"""
import os, subprocess, tempfile, wave
import numpy as np

SR = 48000
DUR = 48
N = SR * DUR
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "live", "config", "includes.chroot",
                   "usr", "share", "sounds", "tenka-ambience")
rng = np.random.default_rng(1600)          # fixed seed: the same files every run

F = np.fft.rfftfreq(N, 1 / SR)

def shaped(spec):
    """circular noise with the given magnitude spectrum (array over F)"""
    ph = np.exp(2j * np.pi * rng.random(len(F)))
    x = np.fft.irfft(spec * ph, N)
    return x / (np.std(x) + 1e-12)

def band(lo, hi, tilt=0.0, soft=1.6):
    """smooth band-pass magnitude from lo to hi Hz, with a spectral tilt in dB/octave"""
    f = np.maximum(F, 1.0)
    m = 1 / (1 + (lo / f) ** (2 * soft)) / (1 + (f / hi) ** (2 * soft))
    return m * (f / 1000.0) ** (tilt / 6.02)

def swell(rate, depth, floor=0.0):
    """a slow random swell, circular, with energy around `rate` Hz; 0..1 scaled by depth over floor"""
    s = shaped(band(rate * 0.3, rate * 1.6, soft=2))
    s = (s - s.min()) / (s.max() - s.min())
    return floor + depth * s

def events(rate, length, make, amp_sigma=0.6):
    """add `rate` events per second, each make(n) samples long, at random times, wrapped around the circle"""
    out = np.zeros((2, N))
    k = rng.poisson(rate * DUR)
    for t0 in rng.integers(0, N, k):
        e = make()
        a = np.exp(rng.normal(0, amp_sigma))
        pan = rng.uniform(-0.8, 0.8)
        g = np.array([np.sqrt((1 - pan) / 2), np.sqrt((1 + pan) / 2)]) * a
        idx = (t0 + np.arange(len(e))) % N
        out[0, idx] += g[0] * e
        out[1, idx] += g[1] * e
    return out

def stereo(fn):
    return np.stack([fn(), fn()])

def drop():                                   # one raindrop: a tiny resonant plip with a click of noise
    n = int(SR * rng.uniform(0.006, 0.03)); t = np.arange(n) / SR
    f = rng.uniform(1800, 5200)
    tone = np.sin(2 * np.pi * f * t * (1 + 0.6 * t / t[-1])) * np.exp(-t / rng.uniform(0.002, 0.008))
    click = rng.normal(0, 1, n) * np.exp(-t / 0.0012)
    return 0.6 * tone + 0.4 * click

def near_drop():                              # a nearer, heavier drop on the eaves
    n = int(SR * 0.09); t = np.arange(n) / SR
    f = rng.uniform(700, 1500)
    return np.sin(2 * np.pi * f * t * (1 + 0.9 * t / t[-1])) * np.exp(-t / 0.018) + 0.3 * rng.normal(0, 1, n) * np.exp(-t / 0.003)

def bubble():                                 # a bubble in the stream: a short rising sine
    n = int(SR * rng.uniform(0.02, 0.07)); t = np.arange(n) / SR
    f0 = rng.uniform(380, 1300)
    ph = 2 * np.pi * np.cumsum(f0 * (1 + 1.4 * t / t[-1])) / SR
    return np.sin(ph) * np.sin(np.pi * t / t[-1]) ** 2

def crackle():                                # a crackle: a burst of bright noise, a few ms
    n = int(SR * rng.uniform(0.002, 0.012)); t = np.arange(n) / SR
    x = rng.normal(0, 1, n) * np.exp(-t / rng.uniform(0.0008, 0.003))
    return np.diff(np.concatenate([[0], x]))  # brighter

def pop():                                    # a pop of resin
    n = int(SR * 0.05); t = np.arange(n) / SR
    return rng.normal(0, 1, n) * np.exp(-t / 0.006) + 0.5 * np.sin(2 * np.pi * rng.uniform(250, 600) * t) * np.exp(-t / 0.01)

def rain():
    wash = stereo(lambda: shaped(band(300, 7000, tilt=-1.5))) * 0.22
    roof = stereo(lambda: shaped(band(40, 260, tilt=-3))) * 0.10
    drops = events(420, 0, drop, 0.7) * 0.10
    near = events(1.6, 0, near_drop, 0.4) * 0.12
    return (wash + roof) * swell(0.05, 0.35, 0.65) + drops + near

def stream():
    beds = sum(stereo(lambda lo=lo, hi=hi: shaped(band(lo, hi, soft=2))) * swell(r, 0.8, 0.2) * w
               for lo, hi, r, w in [(180, 500, 0.7, 0.20), (500, 1300, 1.3, 0.16), (1300, 3200, 2.1, 0.10), (3200, 7000, 3.0, 0.04)])
    babble = events(22, 0, bubble, 0.5) * 0.06
    return beds + babble

def pines():
    g = swell(0.06, 0.85, 0.15)                     # the gusts
    body = stereo(lambda: shaped(band(150, 900, tilt=-2))) * 0.28
    hiss = stereo(lambda: shaped(band(2500, 8000, tilt=-1))) * 0.07
    whistle = stereo(lambda: shaped(band(600, 760, soft=4))) * 0.05
    return body * g + hiss * g ** 1.6 + whistle * swell(0.11, 1.0) * g

def embers():
    roar = stereo(lambda: shaped(band(30, 300, tilt=-4))) * 0.20 * swell(0.3, 0.4, 0.6)
    lick = stereo(lambda: shaped(band(300, 1500, tilt=-3))) * 0.05 * swell(0.9, 1.0)
    cr = events(14, 0, crackle, 0.9) * 0.20
    pp = events(0.5, 0, pop, 0.3) * 0.18
    return roar + lick + cr + pp

def lufs(x):
    """integrated loudness (EBU R128) of a float stereo buffer, measured by ffmpeg"""
    import json, re
    with tempfile.TemporaryDirectory() as d:
        w = os.path.join(d, "m.wav"); _wav(w, x)
        r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", w, "-af", "loudnorm=print_format=json", "-f", "null", "-"],
                           capture_output=True, text=True)
        return float(json.loads(re.findall(r"\{[^{}]*\}", r.stderr)[-1])["input_i"])

def _wav(path, x):
    pcm = (np.clip(x, -1, 1).T * 32767).astype(np.int16)
    with wave.open(path, "wb") as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR); f.writeframes(pcm.tobytes())

TARGET = -24.0      # every bed at the same quiet loudness (LUFS), so switching between them is not a jump

def soft(x, knee=0.5):
    """a gentle limiter: untouched under the knee, rounded off above it, never past 0.9"""
    a = np.abs(x); over = a > knee
    y = x.copy()
    y[over] = np.sign(x[over]) * (knee + (0.9 - knee) * np.tanh((a[over] - knee) / (0.9 - knee)))
    return y

def write(name, x):
    x = x - x.mean(axis=1, keepdims=True)
    x = x / (np.abs(x).max() + 1e-12) * 0.5
    for _ in range(3):                                   # loudness, then the limiter, then loudness again
        x = soft(x * 10 ** ((TARGET - lufs(x)) / 20))
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        w = os.path.join(d, name + ".wav"); _wav(w, x)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", w, "-c:a", "libvorbis", "-q:a", "2",
                        "-metadata", "title=" + name.capitalize(), "-metadata", "artist=Tenka",
                        os.path.join(OUT, name + ".ogg")], check=True)
    print("ambience: %s %.1f LUFS, peak %.2f" % (name, lufs(x), np.abs(x).max()))

if __name__ == "__main__":
    for name, fn in [("rain", rain), ("stream", stream), ("pines", pines), ("embers", embers)]:
        write(name, fn())
