# Measurement Workshop assets

This folder supplies Section D of [issue #17](https://github.com/yasinkaya701/glitch-academy/issues/17): a quiet measurement bench and reusable measurement/rail sprites.

## Files
- `bench_bg.png` — 1920×1080 night-lab bench, with instruments staged left and a deliberately dark open wall on the right for live Godot labels.
- `ruler.png` — 640×128 transparent precision ruler.
- `balance.png` — 512×512 transparent top-pan analytical balance and calibration mass.
- `stopwatch.png` — 320×320 transparent analog stopwatch.
- `rail_piece.png` — 512×256 transparent air-track extrusion segment with repeatable ends.
- `rail_slot.png` — 512×256 transparent photogate shoe that fits the extrusion.
- `measurement_preview.jpg` — contact sheet for review only; not a scene screenshot.

## Source and provenance
All pixels are authored from deterministic geometry, gradients, highlights, and surface marks in `tools/generate_measurement_assets.py` using Pillow. No external artwork, models, fonts, or AI-generated image content is used. Regenerate with:

```sh
python3 tools/generate_measurement_assets.py
```

Objects are unlabeled so the game can localize labels and measurement values. The preview is an asset board, not evidence of a running mission.
