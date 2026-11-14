# Heart lab environment

`lab_hdri.hdr` is a deterministic, linear Radiance equirectangular environment map (2048 × 1024). Its dark navy room has a broad warm task-light panel above-left and a cooler, lower-energy reflection strip behind the subject. The editable source is `generate_environment.py`; run it with Python 3.

`lab_environment.tres` references the HDRI as a Godot panorama sky. `dust.svg` / `lightshaft.svg` are original alpha cutouts; their requested PNG runtime versions are rendered at native SVG dimensions. The shaft has a soft warm upper edge and a very restrained cool falloff. Use both at low opacity and let the actual lamp provide scene illumination.
