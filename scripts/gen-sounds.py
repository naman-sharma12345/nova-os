#!/usr/bin/env python3
"""gen-sounds.py: Tenka's two freedesktop sound themes, drawn from plucked strings (no samples, no recordings).

  Tenka-Samurai: a koto, Hirajoshi on D (D E F A Bb), bright and dry.
  Tenka-Xianxia: a guzheng, the gong pentatonic on G (G A B D E), each note sliding up into its pitch, a little
                 vibrato, a longer hall.
Every event is one to four plucked notes, short and soft (UI sounds sit below the login chime), written as Ogg
Vorbis to live/config/includes.chroot/usr/share/sounds/Tenka-<Theme>/stereo/<event>.oga with an index.theme.
GTK and XFCE play them by name (gtk-sound-theme-name / Net/SoundThemeName); tenka-sound plays one by name.
The outputs are committed; run this again (needs numpy and ffmpeg with libvorbis) only to change them.
"""
import os, subprocess, tempfile, wave
import numpy as np

SR = 48000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "live", "config", "includes.chroot", "usr", "share", "sounds")

def hz(m): return 440.0 * 2 ** ((m - 69) / 12)

def pluck(midi, dur, kind, vel=1.0, bend=0.0):
    """one plucked string, additive: harmonics that die faster the higher they are, a pluck-position comb,
    a short noise of the nail, and for the guzheng a slide up into the note and a late vibrato"""
    n = int(dur * SR); t = np.arange(n) / SR
    f0 = hz(midi)
    if kind == "zheng":
        slide = bend * np.exp(-t / 0.05)                     # starts `bend` semitones under, glides up in ~80 ms
        vib = 0.12 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.18) / 0.25, 0, 1)
        f = f0 * 2 ** ((-slide + vib) / 12)
        tau1, pos, nh, inh, bright = 1.6, 0.18, 14, 0.0004, 0.85
    else:
        f = np.full(n, f0)
        tau1, pos, nh, inh, bright = 0.9, 0.11, 16, 0.0007, 1.0
    phase = 2 * np.pi * np.cumsum(f) / SR
    y = np.zeros(n)
    for h in range(1, nh + 1):
        if f0 * h > SR * 0.45: break
        a = abs(np.sin(np.pi * h * pos)) / h ** (1.15 - 0.25 * bright)
        tau = tau1 / (1 + 0.55 * (h - 1) ** 1.1)
        y += a * np.sin(phase * h * (1 + inh * h * h)) * np.exp(-t / tau)
    att = np.clip(t / 0.0025, 0, 1)                           # no click: 2.5 ms in
    # the hand damps the string over the last third of its length, so no note is ever cut off mid-ring
    rel = np.where(t < 0.66 * dur, 1.0, 0.5 + 0.5 * np.cos(np.pi * np.clip((t - 0.66 * dur) / (0.34 * dur), 0, 1)))
    att = att * rel
    nail = np.random.default_rng(midi).standard_normal(n) * np.exp(-t / 0.006) * 0.25
    nail = np.convolve(nail, np.ones(6) / 6, mode="same")
    return (y * att + nail * (0.6 if kind == "koto" else 0.35)) * vel

def room(x, kind):
    """a small hall: exponentially dying, slightly smoothed noise, the two ears different"""
    rt = 0.55 if kind == "koto" else 1.1
    m = int(rt * SR); t = np.arange(m) / SR
    out = []
    for s in (3, 7):
        ir = np.random.default_rng(s).standard_normal(m) * np.exp(-6.9 * t / rt)
        ir = np.convolve(ir, np.ones(8) / 8, mode="same"); ir[:int(0.012 * SR)] = 0
        ir /= np.sqrt((ir ** 2).sum())
        wet = np.convolve(x, ir)
        dry = np.concatenate([x, np.zeros(len(wet) - len(x))])
        out.append(dry + (0.16 if kind == "koto" else 0.24) * wet)
    return np.stack(out, 1)

def phrase(notes, kind, tail=0.25):
    """notes: (start s, midi, length s, velocity[, bend])"""
    end = max(s + d for s, _, d, *_ in notes) + tail
    x = np.zeros(int(end * SR))
    for s, m, d, v, *b in notes:
        y = pluck(m, d, kind, v, b[0] if b else (1.0 if kind == "zheng" else 0.0))
        i = int(s * SR); x[i:i + len(y)] += y[: len(x) - i]
    st = room(x, kind)
    k = int(0.03 * SR)                                        # fade the tail to true silence
    st[-k:] *= np.linspace(1, 0, k)[:, None]
    return st

def write(path, st, peak_db):
    env = np.abs(st).max(1)                                   # end where the ring has fallen 54 dB, with a 40 ms fade
    last = np.nonzero(env > env.max() * 10 ** (-54 / 20))[0][-1]
    st = st[: min(len(st), last + int(0.04 * SR))].copy()
    k = int(0.04 * SR); st[-k:] *= np.linspace(1, 0, k)[:, None]
    st = st / np.abs(st).max() * 10 ** (peak_db / 20)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf: wav = tf.name
    with wave.open(wav, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(st, -1, 1) * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "4",
                    "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", path], check=True)
    os.remove(wav)

# the scale degrees each theme plays (MIDI), low to high
SCALES = {"Samurai": ("koto", [50, 52, 53, 57, 58, 62, 64, 65, 69, 70, 74]),      # D3 E F A Bb D4 E F A Bb D5
          "Xianxia": ("zheng", [55, 57, 59, 62, 64, 67, 69, 71, 74, 76, 79])}     # G3 A B D E G4 A B D E G5

def events(kind, s):
    """event -> (notes, peak dB). s is the scale; the same gestures in both themes"""
    q = 0.075 if kind == "koto" else 0.09
    return {
        "message-new-instant": ([(0, s[7], .5, .8), (q * 1.4, s[9], .7, .7)], -9),
        "bell":                ([(0, s[9], .6, .7)], -10),
        "window-attention":    ([(0, s[8], .5, .7), (q * 1.3, s[8], .5, .55)], -10),
        "dialog-information":  ([(0, s[7], .6, .7)], -11),
        "dialog-warning":      ([(0, s[8], .5, .8), (q * 1.6, s[5], .8, .8)], -8),
        "dialog-error":        ([(0, s[3], .5, .9), (q * 1.2, s[2], .9, .9)], -7),
        "complete":            ([(0, s[5], .5, .7), (q, s[7], .5, .7), (2 * q, s[9], .8, .75)], -9),
        "device-added":        ([(0, s[4], .4, .7), (q, s[7], .7, .75)], -10),
        "device-removed":      ([(0, s[7], .4, .7), (q, s[4], .7, .75)], -10),
        "power-plug":          ([(0, s[2], .4, .7), (q, s[5], .7, .75)], -10),
        "power-unplug":        ([(0, s[5], .4, .7), (q, s[2], .7, .75)], -10),
        "battery-low":         ([(0, s[2], .6, .8), (q * 2.5, s[1], .9, .8)], -8),
        "trash-empty":         ([(i * q * 0.5, s[9 - i * 2], .45, .6) for i in range(4)], -10),
        "screen-capture":      ([(0, s[10], .16, .6, 0.3)], -12),
        "camera-shutter":      ([(0, s[10], .16, .6, 0.3)], -12),
        "audio-volume-change": ([(0, s[8], .12, .5, 0.0)], -16),
        "desktop-logout":      ([(0, s[9], .6, .7), (q * 1.5, s[7], .6, .7), (q * 3, s[5], 1.2, .75)], -8),
    }

def main():
    for name, (kind, s) in SCALES.items():
        base = os.path.join(ROOT, f"Tenka-{name}")
        for ev, (notes, pk) in events(kind, s).items():
            write(os.path.join(base, "stereo", ev + ".oga"), phrase(notes, kind, 0.12 if ev in ("screen-capture", "camera-shutter", "audio-volume-change") else 0.25), pk)
        with open(os.path.join(base, "index.theme"), "w") as f:
            f.write(f"[Sound Theme]\nName=Tenka {name}\nComment={'A koto' if kind == 'koto' else 'A guzheng'}: Tenka's system sounds, generated by scripts/gen-sounds.py\n"
                    "Directories=stereo\nInherits=freedesktop\n\n[stereo]\nOutputProfile=stereo\n")
        print("sounds:", name, len(events(kind, s)))

if __name__ == "__main__":
    main()
