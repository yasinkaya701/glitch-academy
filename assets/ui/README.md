# UI asset pack

Current assets are the Meridian observatory console system. Dimensions and generation are recorded in `tools/generate_ui_assets.py`; all sprites are transparent RGBA PNGs. The 9-slice safe edge is 24 px for `panel_glass.png` and `panel_info.png`.

Run `python3 tools/generate_ui_assets.py` from the repository root to rebuild the PNG set. To rebuild the original `assets/fonts/YanlisDunyaMeridian-Display.ttf` from hand-drawn outlines in `tools/meridian_glyphs.py`, install the sole external build dependency with `python3 -m pip install fonttools`, then run `python3 tools/build_display_font.py` from the repository root. The SVG and PNG logo use that same glyph source. Tracked `Inter.ttf` is reserved for body text and fallback. License notes are in `assets/fonts/LICENSE-Meridian-Display.txt` and `assets/fonts/OFL.txt`.

The prior asset pack, its generator, notes, and original logo are preserved in `assets/ui/archive/legacy_v1/`. The immediately previous Meridian iteration, including its Inter-derived font, is preserved in `assets/ui/archive/iteration_v2/` and `assets/fonts/archive/`. Do not restore archived v1 files into the current paths without reviewing their old visual direction.
