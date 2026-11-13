# Segmented heart inspector

This optional look-dev scene previews the five delivered segmented heart GLBs and the split-ring vessel clamp. It does not replace `heart_view.tscn`, `heart_stage.gd`, the production cutaway model, or any mission logic.

## Open and control

From the project root, run:

```sh
godot --path . --scene res://stations/heart/heart_segmented_inspector.tscn
```

Use the left/right arrow buttons to cycle between the healthy, tricuspid-leaky, mitral-leaky, aortic-leaky, and pulmonary-leaky models. **Place clamp on aorta** attaches `tools/clamp_vessel.glb` at `Aorta/ClampPoint`; **Hide aortic clamp** removes it. Drag the 3D view to orbit and use the scroll wheel to zoom.

The models remain at their authored metric scale (`1 unit = 1 m`). The heart pivot is centered at `(0, 0.066, 0)` without rescaling. Clamp local `+Z` follows the final aortic tube segment, approximately `(+0.005, -0.002, 0)`; its authored 7–11 mm fit range matches the vessel scale.

The existing `heart_stage.gd` uses another cutaway mesh and a set of interaction/flow anchors measured against that mesh. Replacing only its model would move valve insertion points, vessel hookups, labels, blood overlays, and pick targets. This inspector therefore keeps the new art available for review without changing those gameplay coordinates. Earlier segmented iterations remain archived beside the source generator.

## Review captures

`docs/review/heart008_inspector_healthy_clamp.png` and `heart008_inspector_aortic_leak.png` are captures of this running inspector scene, including the on-aorta clamp and the aortic leak variant. Regenerate with Godot 4.7.2:

```sh
godot --path . --script res://stations/heart/capture_segmented_inspector.gd
```

Run this capture with a GPU renderer (the tested Godot 4.7.2 Metal/Forward+ renderer); headless dummy rendering cannot save the viewport captures.
