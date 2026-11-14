# Muscle Workshop · sarcomere assets (Section C)

All models are deterministic procedural geometry authored in `generate_assets.py` using only Python's standard library. No downloaded meshes, image generators, embedded labels, or external textures are used. Materials are inline glTF PBR values. Rebuild with:

```sh
python3 stations/muscle/assets/sarcomere/generate_assets.py
```

## Scale and shared layout

**1 unit = 1 µm.** The long axis is X, with Y/Z spanning the filament cross-section. The assembled sarcomere is 2.2 µm at rest: Z discs at X = ±1.1 µm, one 1.6 µm thick filament centered on the M-line, and two 1.0 µm thin filaments extending inward from the Z discs. For a readable longitudinal cutaway it shows one representative thin-filament pair at radial Y = 0.082 µm, where heads can reach it; the remaining neighbors in the full hexagonal lattice are omitted. The free actin tips stop 0.1 µm from the center, leaving a 0.2 µm H zone at rest. The head-free central bare zone on the thick filament is 0.16 µm; the nearest head crowns are centered at X = ±0.14 µm and their motor domains stop short of the M-line scaffold. Titin segments span 0.3 µm from each Z disc toward a thick-filament end.

The head and regulatory proteins are reduced to the interaction-relevant representative units. The thick filament has **12 animated heads** (six per half) rather than the hundreds found in a complete native filament. Diameters and molecular details are enlarged about 3× for legibility; axial sarcomere/filament lengths use the stated micrometre proportions. This is a teaching-scale model, not an atomic structure.

## Models and interaction nodes

- `sarcomere.glb`: Z disc to Z disc assembly, central M-line and bipolar thick filament, mirrored thin filaments, titin on both halves. Named groups keep components individually selectable. The two actin ends are anchored at opposite Z discs; myosin heads face away from the central bare zone.
- `thick_filament.glb`: `Tail` is the central myosin rod. `Head_01`–`Head_12` are hinge pivots at the necks; each owns its lever arm and motor-domain geometry. The 12 heads occupy two axial crowns on each half, with three radial orientations per crown. Imported animation clips `Heads_Open` and `Heads_Tense` set the same pivot nodes to the two poses. Default pose is open/cocked.
- `thin_filament.glb`: `Actin` contains two helical chains of globular subunits. `Tropomyosin` is its own pivot node on the actin groove. `Troponin` contains `Troponin_01`–`Troponin_03`; each has distinct TnC, TnI, and TnT geometry. Clips `Tropomyosin_Closed` and `Tropomyosin_Open` rotate the same pivot around local X (filament axis) between the blocking and exposed-binding-site positions. Default pose is closed.
- `z_disc.glb`: thin, cross-linked Z-disc web with separate actin anchor sites.
- `m_line.glb`: central cross-link scaffold for the thick-filament tails.
- `titin.glb`: local origin is the Z-disc anchor. The coil runs from X = 0 to X = 0.30 µm; scale only X (suggested range 0.75–1.45) to extend or shorten it while the Z anchor stays fixed.
- `ca_ion.glb`: isolated white calcium sphere with `CaIon` root; ion identity is recorded in glTF extras, not rendered as text.
- `atp.glb`: compact green ATP silhouette with three phosphate groups, ribose, and fused adenine rings. It is schematic, not atomically scaled.

Materials share the A-pack language: myosin amber, actin cyan, calcium white, ATP green; neutral graphite/ivory for structural proteins. Z-disc and M-line surfaces remain subdued so the filaments read first.

## Provenance and visual review

The geometry, pivots, pose tracks, and materials are original procedural source in this folder. The total package is well below the issue's 150 MB preference. No earlier Section C assets existed in this worktree, so there is no superseded C pass to archive.

- [Assembled sarcomere · Godot render](../../../../docs/review/sarcomere_c_assembled.png)
- [Filament pose study · Godot render](../../../../docs/review/sarcomere_c_filaments.png)

These are actual renders of the imported GLBs in temporary neutral camera/light scenes, not screenshots of an integrated mission. No mission scene or UI is changed by this asset package.

## Biological references

The arrangement follows the sliding-filament model: thin actin filaments attach to Z discs; thick myosin filaments sit around the M-line with a central bare zone; tropomyosin blocks actin sites at rest, and calcium binding at troponin permits exposure. Titin provides elastic linkage between Z disc and thick filament. See [OpenStax Biology 2e, Muscle Contraction and Locomotion](https://openstax.org/books/biology-2e/pages/38-4-muscle-contraction-and-locomotion) and [OpenStax Anatomy & Physiology 2e, Muscle Fiber Contraction and Relaxation](https://openstax.org/books/anatomy-and-physiology-2e/pages/10-3-muscle-fiber-contraction-and-relaxation).
