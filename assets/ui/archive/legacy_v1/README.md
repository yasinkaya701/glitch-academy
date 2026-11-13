# UI asset pack

All UI PNGs are RGBA in sRGB. Panel edges use 24 px margins for 9-slice scaling.

`logo.svg` and `logo.png` are the primary wordmark: pale lettering with restrained cyan and amber rules, no magenta split or glow. `logo.png` is a 1024×256 Quick Look rasterization of the SVG. The previous RGB-shifted treatment is preserved as `logo_legacy_glitch.svg` and `logo_legacy_glitch.png` for comparison; do not use it as the current logo.

The icon files live in `icons/`. Station and route icons are 128×128; state icons are 64×64. The mission frame keeps its large center fully transparent.

The deterministic sprite generator is included at `tools/generate_ui_assets.py`. From the repository root, run `python3 tools/generate_ui_assets.py` to regenerate panels, buttons, badges, icons, frame, plinth, and intro plate. It does not overwrite `logo.svg`, `logo.png`, or `control_center_bg.jpg`.

Font availability is documented in `FONT_ASSETS.md`.
