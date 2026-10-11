# Tenka: samurai theme ("Tenka") — asset attribution

All assets in this directory were made for the Tenka distro and ship under the repository's MIT licence (use them CC0-style).
No third-party copyrighted images, fonts, samples or traced artwork were used. Generated images contain no text or real-world logos.
The only marks are the seal/crest shapes drawn here.

## Wallpapers (3840×2160, JPEG q92)

Generated images were produced with a text-to-image model, then finished procedurally at 4K. Each was quality-checked at full size
for garbled text, malformed hands and broken blades, then finished locally: JPEG deblocking (edge-aware Gaussian),
Lanczos resize to 3840×2160 where needed, a light unsharp mask and fine film grain (numpy/PIL).

| File | Method | Model | Notes |
|---|---|---|---|
| `wallpapers/01-fuji-sumie.jpg` | generated | a text-to-image model | ink-wash Mt Fuji, vermilion sun on washi; deblocked, Lanczos-upscaled to 4K, film grain |
| `wallpapers/02-torii-night.jpg` | generated | a text-to-image model | torii in mist over still water at night; upscaled, vermilion saturation lift, grain |
| `wallpapers/03-enso-washi.jpg` | hybrid | a text-to-image model | dry-brush enso on washi; upscaled, procedural hanko seal composited (multiply), grain |
| `wallpapers/04-moon-seigaiha.jpg` | procedural | — | numpy: seigaiha wave field with ukiyo-e scalloped edge, gold-leaf accents, washi moon with gold ring, depth-of-field sakura petals, grain |
| `wallpapers/05-ronin-dusk.jpg` | generated | a text-to-image model | ink-wash lone figure on a cliff at dusk (small, from behind); deblock + grain |
| `wallpapers/06-katana-sakura.jpg` | generated | a text-to-image model | sheathed katana on a stand with sakura petals; checked close-up for blade/fitting errors |
| `wallpapers/07-pagoda-snow.jpg` | generated | a text-to-image model | five-storey pagoda in snowfall |
| `wallpapers/08-koi-pond.jpg` | generated | a text-to-image model | koi pond from above |
| `wallpapers/09-bamboo-moon.jpg` | generated | a text-to-image model | bamboo forest under moonlight |
| `wallpapers/10-great-wave.jpg` | generated | a text-to-image model | original ukiyo-e style wave (inspired by the public-domain Edo-period print tradition; no copy of a specific work used as input) |
| `wallpapers/11-maple-ember.jpg` | generated | a text-to-image model | crimson/gold maple leaves on charcoal |
| `wallpapers/12-castle-red-moon.jpg` | generated | a text-to-image model | castle silhouette against a red moon (second render; the first had a duplicate moon) |

`wallpapers/preview-contact.jpg` is a 4×3 contact sheet (1920 px wide) of the above.

## Everything else: procedural, made by hand in code (numpy / PIL / scipy / hand-written SVG / rsvg-convert / ffmpeg)

- `crest.svg`, `crest-1024.png`, `crest-mono.svg`: hand-written SVG sakura kamon (5 notched petals, gold double ring); mono version uses `currentColor`.
- `plymouth/frame-000…047.png` (360×360 RGBA): procedural dry-brush ensō drawn in washi cream. Polar stroke model with 60 bristles that dry out at random points; frames 0–35 draw the stroke (ease-in-out), frames 36–47 breathe, and a procedural vermilion hanko seal fades in from frame 38.
- `plymouth/progress-track.png`, `plymouth/progress-fill.png` (480×6): procedural ragged brush line, vermilion→gold.
- `sounds/login.ogg` (2.8 s), `sounds/notify.ogg` (0.62 s): synthesized koto plucks (Karplus–Strong with pluck-position comb and body filters) in the In / Miyako-bushi scale (E F A B C). login adds a breathy synthesized shakuhachi tone (sine partials, vibrato, band-passed breath noise) and an algorithmic reverb. Ogg Vorbis 48 kHz, normalized to ≈ −16 LUFS, true peak ≤ −1 dBTP.
- `icons/wlogout/*.svg` (256×256): hand-drawn line art in washi #efe6d6 with a vermilion #d8412f accent: sheathed katana (lock), torii (logout), crescent moon (suspend), sakura bud (hibernate), broken ensō with a power stroke (shutdown), ensō arrow (reboot).
- `fastfetch/logo.png` (512×512): the crest on a soft vermilion glow. `fastfetch/logo.txt`: 18×38 block-character crest; `$1` vermilion, `$2` gold, `$3` cream.
- `textures/seigaiha-tile.png` (512×512, seamless): seigaiha lines in overlay #2a2522 on transparent.

