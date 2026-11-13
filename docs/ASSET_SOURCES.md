# Hazır varlık kaynakları

Proje ticari değil. Yine de kaynağı kayıt altında tutuyoruz ki kimin ne kullandığı belli olsun.

| Varlık | Yol | Kaynak | Not |
|---|---|---|---|
| İnsan kalbi (kesit) | `stations/heart/assets/model/heart_cutaway_light.glb` | [Grab3D · Human Heart Cutaway](https://grab3d.com/models/anatomy/human-heart-cutaway/) | CC0, 13 MB hafif sürüm. Dört odacık, kapakçıklar, kordalar, aort, akciğer atardamarı, ana toplardamarlar. Ölçek yaklaşık 0,28 birim. Tam sürüm (27 MB, 800k üçgen) aynı sayfada. |

Poly Haven ve ambientCG'den gelen PBR dokular da CC0, doğrudan kullanılabilir.

## Ortak model kütüphanesi (`assets/models/`)

[Grab3D](https://grab3d.com/models/) CC0 kütüphanesinden 44 model, hafif sürümler, toplam yaklaşık 150 MB. Parçalara ayrılma durumu ve ölçekler kullanılmadan önce istasyon sahibi tarafından Godot'ta kontrol edilir.

- **Anatomi:** human-lungs, neuron, human-brain, human-kidney, human-eye, human-ear-anatomy, human-hand, human-skeleton, human-muscles, human-skin-layers, digestive-system, blood-cells, human-cell, plant-cell, cell-membrane, dna, dna-helix.
- **Fizik:** glass-prism, horseshoe-magnet, newtons-cradle, pendulum, van-de-graaff-generator, tesla-coil, x-ray-tube, gravity-well, lunar-eclipse, solar-eclipse, earth-layers.
- **Kimya ve atom:** atomic-orbitals, bohr-model, atom-model, erlenmeyer-flask, beaker, graduated-cylinder, burette, bunsen-burner, retort-stand, lab-bench, petri-dish, pipette, molecule-kit, water-molecule, co2-molecule.
- **Fen:** greenhouse-effect, water-cycle.

Her istasyon modeli kendi klasörüne kopyalamaz, `res://assets/models/` yolundan örnekler.

## Poly Haven (CC0, `assets/polyhaven/`)

[Poly Haven](https://polyhaven.com) varlıkları CC0, ticari kullanıma ve değişikliğe açık. 13 Kasım 2026'da API üzerinden indirildi.

| Varlık | Yol | Not |
|---|---|---|
| Aerodynamics Workshop (HDRI, 2k) | `assets/polyhaven/hdri/aerodynamics_workshop/` | Fizik sahnelerinin arka planı ve yansıma ışığı |
| Concrete Floor Painted, Wood Table 001, Metal Plate (1k PBR) | `assets/polyhaven/tex/` | Zemin, tezgâh üstü, ray ve gövde |
| Desk Lamp Arm 01, Industrial Microscope, Metal Toolbox, Steel Frame Shelves 01, Vintage Spacecraft Instrument (1k glTF) | `assets/polyhaven/models/` | Sahne dekoru ve ölçü aleti |

## Khronos glTF Sample Assets

| Varlık | Yol | Kaynak | Lisans |
|---|---|---|---|
| Toy Car | `assets/models/toy_car/ToyCar.glb` | [KhronosGroup/glTF-Sample-Assets · ToyCar](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/ToyCar) | CC0 1.0. Fizik deneylerinde (Çarpışma Hattı, Newton Kızağı) dinamik araba olarak kullanılır. |
