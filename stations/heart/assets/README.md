# Heart interaction sprites

Issue #3 interaction art for the existing `heart_cutaway_light.glb`. These sprites are standalone transparent overlays; they do not replace or edit the model or gameplay scripts.

## Files and dimensions

- `valve_{tricuspid,mitral,pulmonary,aortic}_{open,closed,damaged}.png`: twelve centered 512×512 RGBA overlays. Semilunar valves have three cusps; the mitral has two leaflets. Damaged states show calcification or a discrete leaflet/coaptation fault. All states use the same registration and upper-left light.
- `vessel_{artery,vein}_tile.png`: two 512×128 RGBA horizontal tiles with distinct wall thickness and open lumen.
- `vessel_cap_{artery,vein}_{open,attached}.png`: four 512×512 connector-end overlays.
- `port_{out,in,connected}.png`: three 128×128 RGBA metal/glass port states.
- `rbc_{rich,poor}.png`: two 128×128 biconcave erythrocytes. `rbc_rich_sheet.png` is eight aligned 128×128 frames in a 1024×128 strip.

`valve_sprite_generator.py`, `vessel_assets.py`, and `generate_ports.py` are the editable, deterministic sources for their respective authored drawings. The RBC SVG files are editable vector sources. RBC PNGs reuse the matching original sprites from the Heart look-dev pack so the two issue packages stay visually consistent.

The sprite set uses a restrained medical-illustration treatment, warm tissue, satin metal and dark internal cavities. There is no text, AI-rendered imagery, or new third-party model. All outputs are PNG/RGBA; use only the middle section of the vessel tiles for seamless repeats and keep overlays centered on the existing valve/port anchors.
