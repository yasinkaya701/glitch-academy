# Collision Track assets

This package supplies the five first-party raster assets requested in issue #17, section C. The four transparent sprites are original deterministic raster drawings. The full-screen background was generated for this project and then cropped/resized locally. No outside imagery, fonts, or textures were used; no third-party licenses apply.

## Files and placement

- `track_bg.png` — 1920×1080 RGB night-laboratory scene. Side-on air track crosses the lower middle, with its warm alignment notch at screen center and two cyan optical sensor gates on either side. Upper/right wall area stays quiet for the experiment readout. Contains no text.
- `cart_a.png`, `cart_b.png` — 384×192 RGBA side-view cart sprites. A is blue and has one small fixed test mass. B is warm brass and has two retained ballast blocks, making its larger mass visible by silhouette and detail as well as color.
- `cart_stuck.png` — 512×192 RGBA pair of carts nose-to-nose with a distinct central latch for the inelastic outcome.
- `bumper_spring.png` — 256×192 RGBA aligned compression-spring bumper for the elastic case.

The sprite canvases are transparent and centered. The sprite canvas origin is centered. Cart wheel bottoms are at Y≈159 px relative to the canvas center; the visible rail sits near Y≈696 px in `track_bg.png`, so start cart and stuck-pair centers around `(x, 633)` in background coordinates. The Godot previews use the full background scaled by ⅔ and place the cart centers at Y=431 screen pixels. These are starting placements; station camera/scale may adjust to match the scene. Spring travel axis is horizontal (+X).

## Rebuild and provenance

Run `python3 stations/collision/assets/generate_assets.py` from the repository root. It requires Pillow and deterministically rebuilds the four transparent sprites from fixed geometry, colors, and draw order; it preserves `track_bg.png`.

`track_bg.png` was generated on 2026-11-13 with OpenAI ImageGen through Codex, then center-cropped to 16:9 and resized to 1920×1080 with Lanczos filtering. It was visually reviewed and contains no legible text, logos, or unwanted figures. No third-party source images or textures were used. `previews/collision_approach.png` and `previews/collision_stuck.png` are Godot 4.7.2 captures with the assets placed against the background.

Backdrop prompt: “Photorealistic night mechanics lab, straight-on level side camera, a long precise horizontal air-cushion track across the lower middle with a small clear collision point at center and two matching optical sensor gate frames at one-third and two-thirds width. No carts. Left third has dim lab windows and workbench; upper half and most of the right half are quiet uncluttered dark navy wall with room for game measurements, while the track remains visible. One restrained warm amber task lamp above the collision point, soft light pool, subtle cyan sensor reflections, brushed stainless steel and dark anodized rails. Realistic materials and shadows, deep blue-black palette, cinematic production background with photographic texture. No text, numbers, symbols, logos, people, motion blur, holograms, extra lamps, repeated gates, exaggerated glow, or graphic overlays.”

The art uses the project's navy room, one warm overhead pool, restrained cool sensor light, brushed metal rails, and real side-view wheeled carts. Mechanical features are purposeful: the air slots and support feet establish the track, paired beam gates mark measurement points, retained ballast distinguishes B, and the joined latch separates stuck from rebound outcomes.
