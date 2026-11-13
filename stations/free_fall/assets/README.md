# Düşüş Odası assetleri

`chamber.glb` is a 5 m tall, +Y-up Godot/glTF 2.0 chamber. Its named interaction nodes are `Glass`, `Base`, `Release_Left`, `Release_Right`, and `Sensor_Plate`; additional meshes split out the pump tube, caps, rims, and release anchors. Mesh materials are metallic/roughness PBR values. Six 2048² texture maps are included for teams that want texture-driven material variation:

- `tex_metal_albedo.png`, `tex_metal_normal.png`, `tex_metal_roughness.png`
- `tex_glass_albedo.png`, `tex_glass_normal.png`, `tex_glass_roughness.png`

`mass_light.glb` and `mass_heavy.glb` share the same centered cylinder dimensions and use aluminum and brass PBR materials, respectively. `sensor_plate_off.png` and `sensor_plate_on.png` are registered 512² transparent states. `chamber_bg.png` and `air_fault.png` are 1920×1080 scene backdrops; both already depict the chamber. `air_fault.png` also shows the feather and hammer fault. Do not layer `chamber_bg.png` under `chamber.glb` unless the scene intentionally uses the backdrop as a distant/static chamber treatment. Measurement lines and labels are intentionally left to Godot.

## Kaynak ve yeniden üretim

`generate_assets.py` deterministik olarak iki sensör durumunu, altı PBR haritasını ve üç GLB modeli üretir. Betik yalnızca bu çıktıları yeniler; `chamber_bg.png` ile `air_fault.png` dosyalarına dokunmaz.

Arka planlar bu pakete hazır raster görseller olarak eklenmiştir. Bunların kaynak/katman dosyası veya yeniden üretim tarifi repoda bulunmuyor; PNG'ler korunması gereken teslim kaynaklarıdır. Betiği yeniden çalıştırmak arka planları değiştirmez.
