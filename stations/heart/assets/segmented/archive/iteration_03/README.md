# Segmented heart teaching model

Generated deterministically by `build_heart.py` (Python 3, NumPy, Pillow). Rebuild with:

```sh
python3 stations/heart/assets/segmented/build_heart.py
```

## Deliverables

- `heart_segmented.glb`: one continuous cutaway `HeartBody`, four recessed `Wall*` cavity linings and blood volumes, six open-lumen vessels, four annuli, individually named leaflets and pivots, and AV chordae/papillary groups.
- `heart_segmented_{tricuspid,mitral,aortic,pulmonary}_leaky.glb`: same stable node layout as the base, with one matching cusp held partly open in each variant.
- `../tools/clamp_vessel.glb`: separate educational prop with two independently movable jaws.
- Procedural PBR texture maps are embedded in each GLB; the PNG source maps remain beside this README.

## Node names, scale and pivots

All geometry uses metres in the original `+Y` up frame. The anatomical body is centered near `(0, 0.066, 0)`; scale the whole model uniformly about that origin. Its silhouette is built as one tapered myocardium mesh with four anterior openings. `WallRA`, `WallRV`, `WallLA`, and `WallLV` are open-front posterior cavity linings recessed behind those openings; each pivot is at the room center and each wall remains separate for physiology scaling. `CavityLipRA`, `CavityLipRV`, `CavityLipLA`, and `CavityLipLV` sit flush to the opening edges. `BloodRA`, `BloodRV`, `BloodLA`, and `BloodLV` are individual smaller, translucent ellipsoids recessed inside the openings; uniform scale `[0.35, 1.0]` about each node origin controls their fill size.

Room landmarks are `RA`, `RV`, `LA`, `LV` and valve centers are `Tricuspid`, `Mitral`, `Aortic`, `Pulmonary` in `build_heart.py`; their exact coordinates are sourced from `stations/heart/heart_stage.gd`. The `SVC`, `IVC`, `Aorta`, `PulmonaryTrunk`, `PulmonaryVeinL`, and `PulmonaryVeinR` tubes begin inside the shared myocardium and end at exposed, open mouths. Each mouth has a `ClampPoint` interaction node carrying the matching vessel name in `extras`.

Each valve has an `Annulus<Valve>`, individually named `Leaflet<Valve><index>` nodes, and `Hinge<Valve><index>` parents positioned at the hinge. Leaflets are children of the hinge nodes, so rotating a hinge rotates its leaflet in place. `ChordaeTricuspid1/2` and `ChordaeMitral1/2` connect free-edge regions to two matching `Papillary<Valve>1/2` nodes. Semilunar valves intentionally have no chordae or papillary muscles. Names and pivots remain stable across all four leaky variants.

## Provenance and scope

Geometry and maps are original, hand-authored parametric teaching geometry, not a clinical reconstruction. Procedural maps use a fixed seed and contain no text. The existing CC0 heart assets are left unchanged. No clinical, pathology, surgical or implanted content is present.

Iterations before the current correction are retained under `archive/iteration_01/` and `archive/iteration_02/`; `.gdignore` keeps Godot from importing duplicate archived UIDs.
