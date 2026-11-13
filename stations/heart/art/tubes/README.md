# Tube and connection assets

All models are original, code-authored GLB geometry in meters. The common tube/connector axis is +Y. Connector mating planes are at local `Y=0`, so the male and female parts share the same mating pivot. Nodes that move or receive material changes remain separate.

The deterministic source generator is `../valves/generate_asset_pack.py`. From the repository root, run `python3 stations/heart/art/valves/generate_asset_pack.py` to regenerate both folders. It requires Python 3 and Pillow and writes only into the `valves/` and `tubes/` folders.

| File | Approximate dimensions | Structure and materials |
|---|---|---|
| `connector_male.glb` | 9.8 mm OD × 4.2 mm long | `ConnectorRoot`, hollow stainless body, three separate barbs, polymer grip collar, silicone seal, and a +Y lead lip. |
| `connector_female.glb` | 10.6 mm OD × 4.0 mm long | `ConnectorRoot`, hollow female socket and internal guide rings, three barbs, matching grip collar and silicone socket seal. Mating plane matches the male part. |
| `clamp_open.glb` | 9.2 mm jaw OD; fits 8 mm tube | `ClampRoot` contains `HingeA`/`HingeB`; each parents a separate `JawA`/`JawB` and soft liner. Jaw ends are opened by about 40 degrees. |
| `clamp_closed.glb` | 9.2 mm jaw OD; fits 8 mm tube | Same node and pivot layout as the open state, with a near-closed 7 degree split. |
| `cannula.glb` | 41 mm long, 4.2 mm hub OD, 2.7 mm lumen | `CannulaRoot`, translucent polymer shaft, open lumen, distal side ports, tapered tip ribs, stainless luer hub, grip rings, and silicone gasket. The insertion tip is +Y. |

`tube_glass_tile.png`, `tube_glass_tile_normal.png`, and `tube_glass_tile_roughness.png` are seamless 512×128 tile maps. They are intended for a translucent, double-sided vessel material (low alpha, low roughness); the narrow longitudinal highlight suggests a wet inner wall without baking a lighting effect into the texture. The supplied maps are deliberately low-contrast so particles and flow remain readable.
