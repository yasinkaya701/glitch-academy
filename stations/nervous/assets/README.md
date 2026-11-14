# Refleks Merkezi asset guide

All PNGs use transparent RGBA and have no baked-in labels. Matching SVG files are the editable vector sources. Keep each related image at its full canvas size and place layers at the same origin; do not trim transparent margins.

## Neuron layers

The six `neuron_layers_*.png` files share a **2048×1024** canvas and fixed landmarks: soma center `(672, 520)`, axon centerline around `y=520`, myelin internodes from `x=1018` through `x=1778`, and Ranvier gaps centered at `x=1190`, `1392`, and `1594`. Composite in this order:

1. `neuron_layers_dendrites.png`
2. `neuron_layers_axon.png`
3. `neuron_layers_myelin.png`
4. `neuron_layers_nodes.png`
5. `neuron_layers_soma.png`
6. `neuron_layers_terminals.png`

The signal direction is soma to terminals, left to right. Dendrites branch into the soma; the axon is singular. Myelin segments remain separated so the three exposed Ranvier nodes stay visible.

## Synapse

`synapse.png` and `vesicles.png` both use a **2048×1024** canvas. Draw `synapse.png` first, then place `vesicles.png` at `(0, 0)`. Vesicles are intentionally absent from the static synapse base so they can be animated independently. The presynaptic terminal is on the left; the postsynaptic receptor membrane is on the right; the cleft remains open between them.

## Spinal cord and reflex states

- `spinal_cord.png` is **1536×1536**. Dorsal/posterior is at the top, ventral/anterior at the bottom. The butterfly-shaped gray matter sits inside lighter white matter: narrower dorsal/posterior horns are at the top, broader ventral/anterior horns at the bottom. Upper posterior sensory roots include paired dorsal root ganglia; lower anterior motor roots leave without ganglia.
- `hand_arm.png` and `hand_withdrawn.png` are **2048×1024** state swaps with the same proximal forearm anchor. Show only one at a time.
- `muscle_relaxed.png` and `muscle_contracted.png` are **2048×1024** state swaps. Show only one at a time.
- `stove_hot.png` is **2048×1024**, an isolated hot-plate cutout with transparent surroundings.

`archive/flat_v1/` keeps the original icon pass, `archive/flat_v2/` keeps the earlier cyan-glow vector pass, and `archive/flat_v3/` preserves the warm anatomical pass before the synapse edge-detail revision. All archived passes are retained for comparison; the current SVGs are the warm anatomical linework pass. The revised neuron uses a single axon, warm tissue gradation, restrained edge shading, and four separated myelin internodes with three exposed Ranvier gaps. The synapse shows a defined extracellular cleft, an axon-fed bouton with active zones, a separate dense vesicle/release-particle layer, opposed membranes, and postsynaptic receptor proteins. The cord uses the dorsal ganglia and ventral motor roots to preserve sensory/motor orientation. Limb state drawings keep the same proximal forearm origin.

## Provenance and audit

The current editable sources are project-authored SVG vector illustrations with matching transparent RGBA PNG exports. No external images, font renders, or embedded labels are used. All active PNGs were verified pixel-for-pixel against their corresponding SVG imports with Godot 4.7.2 and re-rasterized where the PNG lagged behind its source. A misplaced hot-surface stroke was removed from `hand_arm.svg` so the separate `stove_hot.png` remains the only stove prop. The SVG source stays the editing source of truth.

Audited canvas sizes and formats:

- Six `neuron_layers_*.png` files, `synapse.png`, `vesicles.png`, both hand states, both muscle states, and `stove_hot.png`: **2048×1024, RGBA**.
- `spinal_cord.png`: **1536×1536, RGBA**.
- Every requested image has transparent pixels around its artwork. Paired hand and muscle states retain their shared canvas and fixed proximal anchor; layer alignment is tested by compositing at `(0, 0)`.

A labeled asset board is available at [nervous_asset_board.png](../../../docs/review/nervous_asset_board.png). It composites the neuron and synapse layers and shows the state pairs on the art-direction background. It is a review board, not a running game scene or screenshot. Scene integration and in-game composition remain for the station scene author.

The earlier `archive/flat_v1/`, `archive/flat_v2/`, and `archive/flat_v3/` concepts were preserved unchanged during this audit.

### Anatomy reference

Dorsal sensory entry, ventral motor exit, and relative dorsal/ventral gray-horn shape were checked against the [NCBI Bookshelf spinal-cord anatomy chapter](https://www.ncbi.nlm.nih.gov/books/NBK11008/) and [Neuroanatomy, Spinal Cord](https://www.ncbi.nlm.nih.gov/books/NBK559056/).
