# Prosthetic valve assets

All meshes are original, code-authored GLB geometry in meters, with +Y as the blood-flow axis. The circular opening lies in XZ. Each valve has a centered `ValveRoot` and a deliberately small, physical `FlowOrientationKey` on the +Y side. Materials use embedded 2K albedo, normal, and roughness maps from `textures/`; the maps are deterministic, tileable surface patterns rather than baked illustrations.

`generate_asset_pack.py` is the deterministic authoring source for both `valves/` and the sibling `tubes/` directory. From the repository root, run `python3 stations/heart/art/valves/generate_asset_pack.py`. It requires Python 3 and Pillow; it writes only under `stations/heart/art/valves/` and `stations/heart/art/tubes/`.

| File | Outside radius | Structure and materials |
|---|---:|---|
| `mech_bileaflet.glb` | 0.009 m | Titanium housing and seat, woven polyester cuff, two pyrolytic-carbon leaflets. `HingeA`/`HingeB` are the two physical pivots; their children are `LeafletA`/`LeafletB`. The included `Open` animation moves both leaves symmetrically; the default pose is closed. |
| `mech_bileaflet_damaged.glb` | 0.009 m | Same interface and materials; leaflet B is shortened with calcification at the hinge to leave a visible coaptation gap. |
| `bio_trileaflet.glb` | 0.006 m | Cobalt-chrome support posts, fabric-covered stent, treated pericardial tissue. Each `Hinge1..3` parents `Leaflet1..3`. The `Open` animation moves the three cusps clear of the center; default pose is closed. |
| `bio_trileaflet_damaged.glb` | 0.006 m | Same interface, with a localized calcification cluster on cusp 2. |

The mechanical pattern is authored at the larger 18 mm outside diameter for the mitral/tricuspid positions. Scale the complete root uniformly to `2/3` when using it at the 12 mm aortic/pulmonary positions. The biological pattern is authored at 12 mm; scale to `1.5` for the 18 mm positions. Rotation in the `Open` clip is about each named hinge node; maintain the hierarchy if replacing the geometry. No scene scripts are included.
