# Muscle structure models

Four deterministic, hand-authored glTF 2.0 models for the muscle zoom sequence. They contain mesh geometry and per-mesh PBR materials only; there are no embedded labels, external textures, downloaded models, or generated imagery.

## Models and hierarchy

| File | Contents | Local scale and pivot |
| --- | --- | --- |
| `muscle_belly.glb` | Fusiform muscle belly, proximal/distal tendons, translucent epimysium with an anterior cutaway and seven fascicle bundles | Root `MuscleBelly`, pivot at belly center, axis Y, units metres; envelope about 18 × 50 × 13 mm |
| `fascicle.glb` | Open perimysium sleeve and 37 parallel skeletal muscle fibers | Root `Fascicle`, pivot at fascicle center, axis Y, units micrometres; envelope about 1,400 × 50,000 × 1,200 µm |
| `fiber.glb` | Open sarcolemma, sarcoplasm, 19 longitudinal myofibrils, six peripheral myonuclei and eight intermyofibrillar mitochondria | Root `MuscleFiber`, pivot at fiber center, axis Y, units micrometres; envelope about 90 × 50,000 × 80 µm |
| `myofibril.glb` | Three repeating sarcomeres, with split A-band flanks around H zones, I-band intervals and four Z discs | Root `Myofibril`, pivot at center, axis Y, units micrometres; envelope about 0.95 × 6 × 0.95 µm |

The hierarchy descends by diameter: the 1.4 mm fascicle fits inside the 13 mm belly; the 90 µm fiber fits inside the fascicle; and 0.95 µm myofibrils fit inside the fiber. The models keep these local measurement units and are meant to be used as successive zoom targets, not displayed simultaneously at a shared unscaled scene size. The documented roots are stable pivots for the zoom handoff.

## Mesh names and materials

Important nodes are named `Epimysium`, `Perimysium`, `Sarcolemma`, `Nucleus_1` through `Nucleus_6`, and `Myofibril_01` through `Myofibril_19`. The myofibril uses separate repeated nodes and materials named `BandA`, `BandI`, and `ZLine`; `H zone` is a separate inset region. Tissue colors follow the adjacent bench package: warm coral contractile tissue, pale collagen, cool translucent membranes, plum nuclei, and restrained amber mitochondria. Surface normals face outward and cutaway edges are the actual thickness of each open sheath.

## Source, provenance, and previews

`generate_structure.py` is the source of all four binary GLBs. It writes primitive triangle meshes, normals, named nodes, and glTF PBR material factors from fixed anatomical parameters. Geometry is deterministic and uses only the Python standard library; no source assets were copied or transformed. This branch had no earlier Section B concept to preserve or archive.

`capture_previews.tscn` and `capture_previews.gd` load and render the actual imported GLBs in Godot 4.7.2, then save `preview_belly_fascicle.png` and `preview_fiber_myofibril.png` from the live viewport. For review visibility, the captures apply non-uniform display scaling to the fascicle and fiber diameters and magnify the 6 µm myofibril repeat; the GLB dimensions above remain unchanged.

To regenerate the models, run `python3 stations/muscle/assets/structure/generate_structure.py` from the repository root. To render the previews, run the project with `res://stations/muscle/assets/structure/capture_previews.tscn` in Godot 4.7.2.
