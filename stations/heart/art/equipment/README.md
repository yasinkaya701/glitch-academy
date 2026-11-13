# Perfusion equipment

Six original, node-separated GLB props for the heart-room perfusion rig. They use glTF/Godot meter units, +Y up, front-facing details toward +Z, and restrained satin stainless, slate enamel, polymer, borosilicate glass, and warm task-light materials. They are standalone placement props; no gameplay or station scripts are included.

| File | Approximate envelope (m) | Placement / animation nodes |
|---|---:|---|
| `perfusion_pump.glb` | 0.43 × 0.36 × 0.36 | `Rollers` pivot around the peristaltic head axis; three `Roller_*` children |
| `reservoir.glb` | 0.23 × 0.47 × 0.17 | `Liquid` group with separate volume and surface meshes |
| `stand.glb` | 0.42 × 1.45 × 0.41 | Weighted floor base, post, crossbar, equipment clamps |
| `hose_holder.glb` | 0.12 × 0.17 × 0.13 | Two lined, 70 mm hose loops; mounting block and bolts |
| `manometer.glb` | 0.13 × 0.16 × 0.05 | `Glass` cover and center-pivot `Needle` group; physical dial ticks |
| `side_lamp.glb` | 0.40 × 0.31 × 0.13 | Clamp-mounted articulated arm, reflector, warm bulb |

`generate_equipment.py` is the source for all six meshes. Run it with Python 3 to rebuild the GLBs in place. Mesh geometry and materials are authored procedurally; the models contain no external image or model dependencies. The pump's `Rollers` and the reservoir's `Liquid` nodes are separate groups so the scene owner can rotate or adjust them without changing the other equipment.
