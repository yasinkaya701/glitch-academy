# Three Suns sky

Hand-authored sky art for issue #9, section D. `three_suns_panorama.png` is the 3840×1080 panorama; `three_suns.png` is an identical short-name alias for callers that expect that filename. The three source layers are transparent 1024×1024 RGBA PNGs and include the sun disk, fine corona, and soft local glow.

## Layer anchors

Place each layer with its local center `(512, 512)` at the matching panorama pixel below. The panorama is composed from these same PNG layers by `generate.py`, so a layer can be swapped or animated without rescaling or offset guesswork.

| Layer | Panorama center | Tone |
|---|---:|---|
| `sun_a.png` | `(770, 389)` | amber |
| `sun_b.png` | `(1960, 297)` | cool white |
| `sun_c.png` | `(3146, 526)` | pale red |

## Rebuild

Run `python3 generate.py` from this folder. The illustration is deterministic (seed `318`) and drawn with Pillow primitives and hand-authored curves; it uses no external image assets or generated text. The design treats the suns as a navigational anomaly in a foreign sky: broken orbital tracks, crossing mineral-colored currents, a few sharp shard silhouettes, and four compact star swarms. Palette and restrained luminous accents follow `docs/ART_DIRECTION.md`.
