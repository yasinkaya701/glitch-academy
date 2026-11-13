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

All geometry uses metres in the original `+Y` up frame. The anatomical body is centered near `(0, 0.066, 0)`; scale the whole model uniformly about that origin. `HeartBody` is the existing detailed CC0 cutaway model, embedded unchanged as the visible anatomical underlay. `WallRA`, `WallRV`, `WallLA`, and `WallLV` are separate open-front cavity linings recessed in its four chamber openings; each pivot is at the room center and each wall remains independently scaleable for physiology. `CavityLipRA`, `CavityLipRV`, `CavityLipLA`, and `CavityLipLV` sit flush to each opening edge. `BloodRA`, `BloodRV`, `BloodLA`, and `BloodLV` are individual shallow ellipsoids placed just inside the anterior openings; uniform scale `[0.35, 1.0]` about each node origin controls the visible fill size.

Room landmarks are `RA`, `RV`, `LA`, `LV` and valve centers are `Tricuspid`, `Mitral`, `Aortic`, `Pulmonary` in `build_heart.py`; their exact coordinates and flow directions are sourced from `stations/heart/heart_stage.gd`. Each `Valve*Frame` rotates local +Z onto that valve's flow axis. Annuli, leaflets, and hinge pivots are children of that frame, so AV valves point with downward flow and semilunar valves point up/outward instead of facing the review camera. The `SVC`, `IVC`, `Aorta`, `PulmonaryTrunk`, `PulmonaryVeinL`, and `PulmonaryVeinR` tubes begin inside the shared myocardium and end at exposed, open mouths. Each mouth has a `ClampPoint` interaction node carrying the matching vessel name in `extras`.

`BloodRA/RV` use the deoxygenated blue material and `BloodLA/LV` the oxygenated red material. Their broad, shallow volumes sit just inside each anterior cavity opening; uniform scale `[0.35, 1.0]` produces a visible low-fill pool through full-chamber fill without changing the wall or crossing the cavity lip.

`tools/clamp_vessel.glb` has an open split-ring cradle sized for vessel outer diameters from 7–11 mm. `JawA` and `JawB` are separate movable groups with the clamp axis at the local origin (+Z); each includes a rounded half-ring and a connected handle. Their inward rotation narrows the opening. A hinge bridge and screw connect the handles. The previous rod-only clamp is retained at `tools/archive/iteration_01/`.

Each valve has an `Annulus<Valve>`, individually named `Leaflet<Valve><index>` nodes, and `Hinge<Valve><index>` parents positioned at the hinge. Leaflets are children of the hinge nodes, so rotating a hinge rotates its leaflet in place. `ChordaeTricuspid1/2` and `ChordaeMitral1/2` connect free-edge regions to two matching `Papillary<Valve>1/2` nodes. Semilunar valves intentionally have no chordae or papillary muscles. Names and pivots remain stable across all four leaky variants.

## Provenance and scope

Geometry and maps are original, hand-authored parametric teaching geometry, not a clinical reconstruction. Procedural maps use a fixed seed and contain no text. The existing CC0 heart assets are left unchanged. No clinical, pathology, surgical or implanted content is present.

## Godot review and import QA

`capture_review.gd` renders the actual imported GLBs in Godot 4.7.2 with a warm key and cool fill:

- `docs/review/heart008_segmented_front.png` — the complete healthy model from the anterior.
- `docs/review/heart008_segmented_oblique.png` — an elevated +X/+Z angle that exposes valve-plane orientation.
- `docs/review/heart008_aortic_leaky_front.png` — matching node layout with one aortic cusp held open.
- `docs/review/heart008_clamp_vessel.png` — isolated split-ring clamp and connected handles.

These are imported-asset review renders, not screenshots of an integrated mission. Godot 4.7.2 headless import completed without errors or warnings. Structural review confirmed 63 stable node names across the healthy model and all four leaky variants; each leaky model marks only its corresponding first leaflet as partially open. Quaternion normals for all four annuli match their physiological flow vectors. The clamp has independent `JawA`/`JawB` groups sized for 7–11 mm vessel diameters. Current five heart GLBs total about 100 MB; the full folder is about 413 MB with archived iterations.

Rebuild and capture from the repository root:

```sh
python3 stations/heart/assets/segmented/build_heart.py
godot --headless --editor --path . --import --quit
godot --path . --rendering-method gl_compatibility --script res://stations/heart/assets/segmented/capture_review.gd
```

Iterations 01–03 are retained in `archive/`; iteration 03 records oriented valve frames and readable fill volumes. `../tools/archive/iteration_01/` preserves the initial rod-only clamp, and `iteration_02/` stores the split-ring revision. `.gdignore` keeps Godot from importing duplicate archived UIDs.


Godot glTF import appends numeric suffixes to repeated child names (`ClampPoint2`, etc.). Each segmented GLB sidecar runs `normalize_clamp_points_import.gd` as an `EditorScenePostImport` hook to restore the vessel-local `ClampPoint` name in the imported scene. Source glTF names and `extras.vessel` remain unchanged. After importing, validate all variants with `godot --headless --path . --script res://stations/heart/assets/segmented/verify_clamp_points.gd`.
