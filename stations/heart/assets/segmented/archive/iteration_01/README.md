# Segmented heart teaching model

Generated deterministically by `build_heart.py` (Python 3, NumPy, Pillow). Rebuild with:

```sh
python3 stations/heart/assets/segmented/build_heart.py
```

## Deliverables

- `heart_segmented.glb`: four separate cavity walls and blood volumes, six open-lumen vessels, four annuli, individually named leaflets and hinge pivots, chordae and papillary muscles.
- `heart_segmented_{tricuspid,mitral,aortic,pulmonary}_leaky.glb`: same node names and transforms as the base model; the matching valve has one cusp held partly open.
- `../tools/clamp_vessel.glb`: isolated educational demonstration prop with independently movable `JawA` and `JawB` nodes.
- `*_albedo.png`, `*_normal.png`, `*_roughness.png`: 2048 px procedural PBR texture maps, also embedded in the heart GLBs.

## Scene contract

One GLB unit is one metre. +Y is up. The room wall nodes (`WallRA`, `WallRV`, `WallLA`, `WallLV`), blood nodes (`BloodRA`, `BloodRV`, `BloodLA`, `BloodLV`), annuli and their meshes are centered on their documented anatomy/pivot points. Scale a blood node uniformly about its origin between 0.35 and 1.0. Each vessel node is hollow and open at both ends; a `ClampPoint` node is placed at each exposed end for attachment. Each leaflet has its own `Hinge<Valve><index>` pivot node. Names are deliberately stable across the four leaky variants.

Chamber and vessel surfaces are hand-authored parametric teaching geometry, not a clinical anatomical reconstruction. The room landmarks and valve centers come from the measured coordinates in `stations/heart/heart_stage.gd`; the underlying single-piece CC0 model remains untouched. Geometry and procedural maps here are original, with no third-party model or image source. There are no labels, pathology, surgical devices, stents, cannulae, or clamps in the anatomy files. The separate jaw prop is generic and educational only.
