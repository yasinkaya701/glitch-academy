# UI asset pack

Current assets are the Meridian observatory console system. Dimensions and generation are recorded in `tools/generate_ui_assets.py`; all sprites are transparent RGBA PNGs. The 9-slice safe edge is 24 px for `panel_glass.png` and `panel_info.png`.

Run `python3 tools/generate_ui_assets.py` from the repository root to rebuild the PNG set. Run `python3 tools/build_display_font.py` with Python 3 plus fontTools 4.x to rebuild `assets/fonts/YanlisDunyaMeridian-Display.ttf` from tracked `assets/fonts/Inter.ttf`. The font carries Turkish Latin glyphs. License and derivation details are in `assets/fonts/OFL.txt` and `assets/ui/VISUAL_LANGUAGE.md`.

The prior asset pack, its generator, notes, and original logo are preserved in `assets/ui/archive/legacy_v1/`. Do not restore archived v1 files into the current paths without reviewing their old visual direction.
