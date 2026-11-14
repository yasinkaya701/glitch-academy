# Newton sled asset pack (issue #17, Section A)

`rail_bg.png` is a 1920×1080 night-lab backdrop. The long air-bearing track and cyan finish line sit left of the dark, low-detail measurement wall. It contains no cart or gate frame; place the dynamic assets on top in Godot. The sled art is side-on and faces right, with its pneumatic impulse nozzle at the left/rear.

| File | Size / mode | Use |
|---|---|---|
| `rail_bg.png` | 1920×1080 RGB | Static air-track lab background |
| `sled_light.png` | 512×256 RGBA | Empty-deck sled |
| `sled_heavy.png` | 512×256 RGBA | Same sled with three steel masses |
| `thruster_glow.png` | 512×256 RGBA | Amber thrust, aligned to the sled's rear nozzle |
| `finish_gate_closed.png` | 512×512 RGBA | Gate with the padded stop bar down |
| `finish_gate_open.png` | 512×512 RGBA | Matching gate with the stop bar raised |
| `finish_gate.png` | 512×512 RGBA | Alias of the closed state |
| `preview_light.png`, `preview_heavy.png` | 1920×1080 RGB | Background composites showing both sled/gate states |

Overlay the thruster image at the sled origin shifted 98 px left, so its bright nozzle bloom (local x≈128) meets the sled nozzle (local x≈30). It points left, away from the sled.

## Source and provenance

Run `python3 generate_assets.py` from this directory. Pillow and NumPy are required. The static laboratory render and the two matched transparent object sheets were created specifically for this asset request with OpenAI ImageGen; the untouched source PNGs are preserved in `archive/rail_bg_source.png`, `archive/sled_sprite_sheet_source.png`, and `archive/finish_gate_sprite_sheet_source.png`. The script crops and normalizes these to the exact game dimensions, applies only a small deterministic grain pass to the background, and generates the previews. There are no external stock images, logos, fonts, text, or third-party textures.

The first vector-only exploration was retained as `archive/rail_bg_procedural_v1.png`, `archive/sled_light_procedural_v1.png`, `archive/sled_heavy_procedural_v1.png`, and the two procedural gate v1 images. Those are archived concept iterations, not current runtime assets.
