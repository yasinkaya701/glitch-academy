# Heart tissue material

`heart_tissue.tres` uses the existing `art/textures/tex_tissue_{albedo,normal,roughness}.png` maps without modifying the heart model or UVs. The shader adds restrained procedural micro-ripple and low-contrast vessel undertone, with a wetter specular response and subsurface backlight. `wet_tissue.gdshader` and its material in `art/materials/` are kept as the first look-dev iteration.
