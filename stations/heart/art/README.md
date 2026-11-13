# Codex alanı

Bu klasör yalnızca look-dev kaynakları içerir: materyaller, shader, PBR haritaları, ortam ayarları, ışık rig'i ve takılabilir ekipman meshleri. Oyun akışı veya görev script'i içermez.

## Kaynaklar

- `light_rig.tscn` and `heart_environment.tres`: one warm upper-left key and a restrained cool rear fill on the project's dark navy background. Glow is disabled; tissue and metal are shaped by light and roughness, not emissive outlines.
- `materials/heart_tissue_wet.tres`: uses `wet_tissue.gdshader` with subtle procedural albedo, normal, and roughness maps. The base model remains the imported `heart_cutaway_light.glb`; its source dimensions are about 0.083 × 0.130 × 0.070 m, and the stage currently scales it by 7.5.
- `materials/vessel_glass.tres`, `materials/silicone_tube.tres`, `materials/surgical_steel.tres`, and `materials/valve_leaflet.tres`: separate presets for translucent vessel walls, flexible connectors, brushed metal, and soft tissue.
- `meshes/prosthetic_valve.glb`: +Y flow axis, approx. 20 mm outside diameter and 4 mm total height. The ring, cuff, leaflets, and raised `FlowOrientationKey` are separate nodes. The cue is a physical key, not a glowing outline.
- `meshes/cannula.glb`: hollow, stepped connector with lock rings; approx. 41 mm overall length.
- `meshes/tube_clamp.glb`: split clamp sized around an 8 mm outer-diameter tube.
- `meshes/tube_segment.glb`: smooth open-ended S-curve, 72 mm centerline length (about 80 mm outer envelope), 8 mm outer diameter and 6 mm lumen.
- `textures/tex_{tissue,vessel,steel}_{albedo,normal,roughness}.png`: seamless 512 × 512 PBR maps. The procedural detail is intentionally low contrast so the anatomical forms stay readable at the model's small source scale.
- `valves/README.md`: exact GLB structures, hinge pivots, `Open` animation clips, and scale variants; `valves/generate_asset_pack.py` rebuilds both valve and tube GLBs/maps.
- `tubes/README.md`: connector mating plane and clamp hinge layouts, cannula dimensions, and tiled 512×128 vessel maps.
- `equipment/README.md`: pump, reservoir, stand, hose holder, gauge, and lamp nodes/dimensions; `equipment/generate_equipment.py` rebuilds the props.

- `env/`: original 2K procedural dark perfusion-lab HDRI, paired warm/cool alpha sprites and panorama Environment resource; generator/source notes are local to the folder.
- `blood/`: oxygen-rich/deoxygenated 128px biconcave erythrocytes and a horizontal eight-frame tumble sheet, with editable SVG sources.
- `tissue/heart_tissue.gdshader` + `heart_tissue.tres`: layered wet-surface response over the existing heart PBR maps; no model or UV edits.
- `screenshots/`: two captures of the live `mission.tscn`, with the Heart model and look-dev resources staged in the SubViewport for review. These are presentation captures; no mission or gameplay script is changed.

## Provenance and license

Meshes use original geometric construction and texture maps use deterministic procedural patterns; there are no third-party images, models, or fonts in this folder. No external asset license is required. The repository does not currently declare a project-wide license, so these project-specific files should stay with the repository until its maintainers choose one. The resources use meters and +Y-up; when attaching an accessory to the current heart root, account for its 7.5 visual scale.
