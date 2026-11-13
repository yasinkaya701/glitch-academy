# Measurement Workshop assets

This folder supplies Section D of [issue #17](https://github.com/yasinkaya701/glitch-academy/issues/17): a quiet measurement bench and reusable measurement/rail sprites.

## Files
- `bench_bg.png` — 1920×1080 photorealistic night-lab bench. Instruments sit under the warm pool at left; the right wall stays uncluttered for live Godot readouts. `bench_bg_source.png` is the preserved 1672×941 source image.
- `ruler.png` — 640×128 transparent precision ruler.
- `balance.png` — 512×512 transparent top-pan analytical balance and calibration mass.
- `stopwatch.png` — 320×320 transparent analog stopwatch.
- `rail_piece.png` — 512×256 transparent air-track extrusion segment with repeatable ends.
- `rail_slot.png` — 512×256 transparent photogate shoe that fits the extrusion.
- `measurement_preview.jpg` — contact sheet for review only; not a scene screenshot.

## Source and provenance
The bench background was generated specifically for this scene with OpenAI ImageGen; its unmodified 1672×941 source is preserved as `bench_bg_source.png`, and the deterministic Pillow generator only resizes it to 1920×1080. Every transparent measurement sprite is hand-authored from geometry, gradients, highlights, and surface marks in `tools/generate_measurement_assets.py`. No external models, fonts, or stock images are used. The earlier vector background, its preview, and its generator remain in `stations/measurement/assets/archive/iteration_01/`. Regenerate with:

```sh
python3 tools/generate_measurement_assets.py
```

Objects are unlabeled so the game can localize labels and measurement values. The preview is an asset board, not evidence of a running mission.
