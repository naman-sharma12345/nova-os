# Tenka: xianxia theme ("Tianxia") — asset attribution

All assets in this directory were made for the Tenka distro and ship under the repository's MIT licence (use them CC0-style).
No third-party copyrighted images, fonts, samples or traced artwork were used. Generated images contain no text or real-world logos.
The only marks are the seal/crest shapes drawn here.

## Wallpapers (3840×2160, JPEG q92)

Generated images were produced with a text-to-image model, then finished procedurally at 4K. Each was quality-checked at full size
for garbled text, malformed hands and broken blades, then finished locally: JPEG deblocking (edge-aware Gaussian),
Lanczos resize to 3840×2160 where needed, a light unsharp mask and fine film grain (numpy/PIL).

| File | Method | Model | Notes |
|---|---|---|---|
| `wallpapers/01-floating-peaks.jpg` | generated | a text-to-image model | karst pillar peaks in jade mist, gold sun halo, cranes; deblock, upscale, grain |
| `wallpapers/02-demonic-path.jpg` | generated | a text-to-image model | blood moon over a demonic sect fortress |
| `wallpapers/03-jade-lotus.jpg` | hybrid | a text-to-image model | glowing lotus on dark jade water; upscaled, +140 procedural jade/gold qi motes (screen blend), grain |
| `wallpapers/04-ladies-pavilion.jpg` | generated | a text-to-image model | silk-curtained pavilion, peach blossom, moonlit lotus pond |
| `wallpapers/05-cloud-sea-seclusion.jpg` | generated | a text-to-image model | tiny meditating figure (from behind) above a sea of clouds |
| `wallpapers/06-pleasure-river.jpg` | generated | a text-to-image model | lantern-lit pleasure boats, night market and fireworks |
| `wallpapers/07-golden-dragon.jpg` | generated | a text-to-image model | gold-leaf long dragon in clouds on jade |
| `wallpapers/08-alchemy-hall.jpg` | generated | a text-to-image model | bronze pill furnace with orange-gold fire |
| `wallpapers/09-celestial-palace.jpg` | generated | a text-to-image model | floating celestial palace with waterfalls |
| `wallpapers/10-frost-sect.jpg` | generated | a text-to-image model | ice-crystal palace on a frozen peak under aurora |
| `wallpapers/11-imperial-city.jpg` | generated | a text-to-image model | red-walled, gold-roofed palace city under the Milky Way (original, not a depiction of a real site plan) |
| `wallpapers/12-sword-tomb.jpg` | generated | a text-to-image model | field of swords in the ground at a purple/orange dusk |
| `wallpapers/00-desktop.jpg` | generated, finished locally | a text-to-image model | moon, ring and pavilion; the jade ring was toned down in its band only (value ×0.62, saturation ×0.55) so it reads as paint, not as a neon light; `wallpapers-blur/` copy re-made (960×540, Gaussian 16) |

`wallpapers/preview-contact.jpg` is a 4×3 contact sheet (1920 px wide) of the above.

## Everything else: procedural, made by hand in code (numpy / PIL / scipy / hand-written SVG / rsvg-convert / ffmpeg)

- `crest.svg`, `crest-1024.png`, `crest-mono.svg`: hand-written SVG with an 8-trigram (bagua) gold ring around a jade lotus over a cloud line; mono version uses `currentColor`.
- `plymouth/frame-000…047.png` (360×360 RGBA): procedural jade qi vortex (3-arm log spiral + 6-fold wisps, pulsing white-gold core), orbiting jade/gold motes and two counter-rotating gold rings. Every motion completes a whole period in 48 frames, so the loop is seamless.
- `plymouth/progress-track.png`, `plymouth/progress-fill.png` (480×6): procedural glow line, jade→gold.
- `sounds/login.ogg` (2.9 s), `sounds/notify.ogg` (0.75 s): synthesized guzheng (Karplus–Strong with a gentle vibrato) glissando up a D-major pentatonic, plus a synthesized singing-bowl / temple-bell tone (inharmonic partials 1 : 2.76 : 5.40 : 8.93 with beating) and an algorithmic reverb. Ogg Vorbis 48 kHz, ≈ −16 LUFS, true peak ≤ −1 dBTP.
- `icons/wlogout/*.svg` (256×256): hand-drawn line art in celestial white #eef3ec with a jade #5fc9a0 accent: talisman with seal (lock), cloud gate (logout), crescent over cloud (suspend), lotus bud (hibernate), jian sword through a power arc (shutdown), taiji / yin-yang ring (reboot).
- `fastfetch/logo.png` (512×512): the crest on a soft jade glow. `fastfetch/logo.txt`: 18×38 block-character crest (lotus in a ring); `$1` jade, `$2` gold, `$3` white.
- `textures/xiangyun-tile.png` (512×512, seamless): xiangyun curls on a dotted diamond lattice in overlay #1d332e on transparent. `textures/divider.svg` (600×40): a gold cloud-scroll line with a jade bead.

