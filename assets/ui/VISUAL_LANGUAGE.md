# Yanlış Dünya interface language

The interface is a repaired observatory instrument, not a stack of floating windows. Its signature is the **meridian index**: a split cyan crown datum, short amber bearing mark, matched edge scales, and clipped steel cuts modeled after the observatory calibration ring. The same index returns on the panel, selection rail, route markers, station dock, and logo. Repeated marks should explain alignment, selection, route, or state; remove them when they do not carry information.

## Palette and material

Use the project palette from `docs/ART_DIRECTION.md`: midnight `#070B12`, glass `#0F1824`, pale `#E8F1F2`, repair `#6FE3C1`, amber `#F2A65A`, and fault `#E5645A`. Surface fills stay matte and low contrast. Cyan indicates measurement or focus, amber indicates the current bearing or action, green means repaired, and red marks a fault. Every state also changes its symbol or silhouette. No neon bloom, magenta fringe, random HUD lettering, or decorative status copy.

The common upper-left light appears as a narrow pale seam. Controls are cut-corner instrument parts with shallow grooves and a small bearing indicator. Their crown index and opposed side scales tie them to the meridian ring instead of generic cards. Hover changes the bearing and edge; press moves the face one pixel into its socket; disabled removes the bearing and uses a broken/dashed edge. The primary action is a warm ceramic switch with an amber side rail. Select rows use a single amber datum, not a luminous card.

## Type scale

`YanlisDunyaMeridian-Display.ttf` is an original outline face built from hand-drawn glyphs in `tools/meridian_glyphs.py`; it does not reuse Inter contours. Tall instrument capitals, open counters, chamfered terminals, and compact lowercase give titles a distinct calibration-mark character. Turkish glyphs include İ ı Ş Ğ Ç Ö Ü in both cases; numerals and interface punctuation are included. Use it for the logo, short titles, and station names only. Tracked `Inter.ttf` is the body face and fallback. Logo SVG and PNG are generated from the same glyph source. See `assets/fonts/LICENSE-Meridian-Display.txt` and `assets/fonts/OFL.txt`.

| Role | Size | Face | Use |
|---|---:|---|---|
| Opening title | 56–72 px | Meridian Display | One short name, generous tracking |
| Screen / station title | 32–40 px | Meridian Display | One line |
| Section | 22–26 px | Inter SemiBold | Short instrument label |
| Instruction / control | 18 px | Inter Medium | One action sentence, at most 90 characters |
| Feedback / measurement | 16 px | Inter | One result near the relevant object |
| Compact metadata | 13–14 px | Inter Medium | Route code, units, state |

Avoid using a title, paragraph, and button as a repeated card recipe. Follow `docs/UX.md`: one instruction, feedback attached to the instrument, and details behind the small information control.

## States and symbols

- Done: a six-sided stamped seal plus check.
- Ready: a centered aperture and short amber index.
- Locked: a closed shackle silhouette.
- Playable: outlined circle with a play wedge.
- Repaired: closed ring and check with green repair color.

The station pictograms use one pale stroke, built from recognizable physical cues: a tilted globe axis, ruled measure, vector arrows, truss, prism and beam, falling mass, liquid meniscus, anatomical heart, and pressure dial. At 48 px, preserve the central silhouette and drop secondary marks before thinning the stroke.

## Nine-slice and layout

`panel_glass.png` and `panel_info.png` keep their edge geometry inside a 24 px inset. Stretch only the middle. The mission frame is a peripheral frame with a clear play aperture; the narrow right dock is reserved for optional details, not persistent explanation. Do not put text in the PNGs. The title plate is the exception only in that the game title is layered as live text above it.
