#!/usr/bin/env python3
"""gen-watch.py: the bells of The Watch (Tianxia: The Bell Tower), drawn from partials (no samples, no recordings).

  samurai: a small temple bell, struck once with a soft mallet; prime on G3.
  xianxia: a bronze tower bell, deeper, struck twice (the second softer), prime on E3.
A bell is inharmonic: hum, prime, minor-third tierce, quint, nominal and the upper partials, each a pair of close
sines so the tone beats slowly the way cast bronze does, each dying at its own rate (the hum last).
Written as Ogg Vorbis to live/config/includes.chroot/usr/share/sounds/tenka-watch/<theme>.ogg, peak -12 dBFS;
tenka-watch plays one softly at each double-hour. The outputs are committed; run this again (needs numpy and
ffmpeg with libvorbis) only to change them.
"""
import os, subprocess, tempfile, wave
import numpy as np

SR = 48000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "live", "config", "includes.chroot",
                   "usr", "share", "sounds", "tenka-watch")
# (ratio to the prime, amplitude, decay seconds, beat Hz)
PARTIALS = [(0.5, 0.55, 9.0, 0.55), (1.0, 1.00, 6.0, 1.10), (1.19, 0.48, 4.6, 0.80), (1.5, 0.22, 3.4, 0.0),
            (2.0, 0.42, 3.0, 1.60), (2.66, 0.18, 2.0, 0.0), (3.01, 0.13, 1.5, 2.1), (4.17, 0.07, 1.0, 0.0),
            (5.43, 0.04, 0.7, 0.0)]

def strike(f0, dur, vel=1.0, seed=1, deep=False):
    rng = np.random.default_rng(seed)
    n = int(dur * SR); t = np.arange(n) / SR
    st = np.zeros((n, 2))
    for i, (r, a, tau, beat) in enumerate(PARTIALS):
        f = f0 * r
        tau *= 0.7
        if deep: tau *= 1.35; a *= 1.25 if r < 1 else 1.0
        # a soft mallet: the upper partials start weaker and die sooner
        a *= vel ** (1 + 0.6 * max(0, r - 1))
        env = np.exp(-t / tau) * np.clip(t / (0.004 + 0.002 * r), 0, 1)
        for ch in (0, 1):
            ph = rng.uniform(0, 2 * np.pi)
            b = beat * (1.0 + 0.07 * ch)                        # the two ears beat a little apart: width without reverb
            y = 0.5 * np.sin(2 * np.pi * f * t + ph) + 0.5 * np.sin(2 * np.pi * (f + b) * t + ph * 0.7)
            st[:, ch] += a * env * y
    # the mallet's touch: 10 ms of low noise
    k = int(0.010 * SR); nz = rng.standard_normal(k) * np.hanning(2 * k)[k:]
    nz = np.convolve(nz, np.ones(24) / 24, mode="same") * 0.35 * vel
    st[:k] += nz[:, None]
    return st

def write(path, st, peak_db=-12.0):
    env = np.abs(st).max(1)
    last = np.nonzero(env > env.max() * 10 ** (-56 / 20))[0][-1]
    st = st[: min(len(st), last + int(0.05 * SR))].copy()
    k = int(1.5 * SR); st[-k:] *= np.linspace(1, 0, k)[:, None] ** 2
    st = st / np.abs(st).max() * 10 ** (peak_db / 20)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf: wav = tf.name
    with wave.open(wav, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(st, -1, 1) * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "3",
                    "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", path], check=True)
    os.remove(wav)

def main():
    write(os.path.join(OUT, "samurai.ogg"), strike(196.0, 12.0, vel=0.85, seed=7))
    a = strike(164.8, 14.0, vel=0.9, seed=11, deep=True)
    b = strike(164.8, 14.0 - 2.8, vel=0.62, seed=12, deep=True)
    off = int(2.8 * SR); a[off:off + len(b)] += b * 0.72
    write(os.path.join(OUT, "xianxia.ogg"), a)
    print("gen-watch: wrote", ", ".join(sorted(os.listdir(OUT))))

if __name__ == "__main__":
    main()
