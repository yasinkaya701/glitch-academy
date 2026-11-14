# Muscle Workshop bench assets

These are deterministic, self-contained GLB models built from procedural meshes. Run `python3 stations/muscle/assets/bench/generate_assets.py` from the repository root to regenerate both files. The source uses only Python's standard library; no downloaded meshes, textures, or image generators are involved.

All dimensions and node translations use meters. Godot/glTF axes: X left/right, Y up, Z front/back. Both models are authored with their own geometry centered near the origin and no baked camera or lights. The materials are authored inline.

## Myograph

`myograph.glb` has an overall envelope of approximately **0.255 m wide × 0.39 m high × 0.205 m deep**. Place the model origin on the center of the stand foot. The bath spans X ±0.118 m, Y 0.121–0.233 m, Z ±0.073 m. The transparent bath walls surround the cyan-tinted physiological solution; the level sits below the rim. The gastrocnemius is a spindle-shaped, tapered muscle with pale tendon connections, immersed in the solution, with paired ceramic-insulated platinum-iridium stimulation electrodes beside the belly.

Named interaction nodes:

- `Bath`: parent for the borosilicate base and walls.
- `Solution`: solution volume mesh; material uses alpha blending.
- `Muscle`: the fusiform mesh node, centered 0.025 m below `TendonTop`'s local origin so its upper end meets the upper tendon. Default local scale is `(1, 1, 1)` and the mesh is **0.018 m wide × 0.050 m tall × 0.014 m deep**. Scale only its Y component from `0.60` to `1.40`. At non-default scale, keep the upper attachment fixed and move `TendonBottom` to `TendonTop` local Y `-0.025 - 0.025 × muscle_scale_y - 0.0135` m so the lower tendon remains joined to the muscle and lower clamp.
- `TendonTop`: parent for muscle and upper tendon; child of `ForceTransducer` at local Y −0.060 m.
- `TendonBottom`: separate child of `TendonTop`, initially at local Y −0.0635 m; move it as described when muscle length changes.
- `ForceTransducer`: independent load cell assembly above the bath.
- `Electrodes`: parent with distinct `Tip_A` and `Tip_B` nodes at the rounded exposed ends.
- `Clamp`: independent lower tendon clamp assembly.
- `StretchKnob`: independent adjustment knob; rotate around its local Y axis for manipulation.
- `Stand`: base plate, with separate `StandPost` and `StandArm` child nodes.

The center of the muscle is at world Y 0.185 m by default, fully within the bath solution. Its top and bottom connect to the upper and lower tendons at Y 0.210 m and 0.160 m. The lower clamp jaw occupies approximately Y 0.147–0.162 m. The clamp is separate from the stretch screw and knob so scene logic can adjust/preload the preparation.

## Kymograph

`kymograph.glb` is approximately **0.25 m wide × 0.183 m high × 0.16 m deep**. Its blank paper drum is 0.082 m diameter and 0.073 m long. `Drum` is centered at `(0, 0.105, 0.004)`; its cylinder axis is local **Y**. Rotate `Drum` around local Y for paper travel. Keep the paper surface blank so the scene can draw its own trace.

`Stylus` is a distinct assembly node with origin `(0.055, 0.105, 0.085)`. Its contact point reaches the front of the drum at approximately `(0, 0.105, 0.041)`. Translate its X/Y position to trace the drum; its nib and contact point are child meshes. The adjustment knob and bearing supports are separate stationary parts. Both moving nodes have geometry grouped beneath their named pivot nodes and can be animated independently.

No external asset licenses apply; all geometry and materials in these two files are original procedural work. Reproduce both GLBs with `python3 stations/muscle/assets/bench/generate_assets.py`.

## Godot scene previews

These are actual Godot 4.7.2 renders of the imported GLBs in a temporary preview scene with a neutral camera and lights; they are not in-game screenshots and do not add baked geometry to the models.

- [Myograph preview](../../../docs/review/myograph_scene_preview.png)
- [Kymograph preview](../../../docs/review/kymograph_scene_preview.png)
