# Hazır varlık kaynakları

Proje ticari değil. Yine de kaynağı kayıt altında tutuyoruz ki kimin ne kullandığı belli olsun.

| Varlık | Yol | Kaynak | Not |
|---|---|---|---|
| İnsan kalbi (kesit) | `stations/heart/assets/model/heart_cutaway_light.glb` | [Grab3D · Human Heart Cutaway](https://grab3d.com/models/anatomy/human-heart-cutaway/) | CC0, 13 MB hafif sürüm. Dört odacık, kapakçıklar, kordalar, aort, akciğer atardamarı, ana toplardamarlar. Ölçek yaklaşık 0,28 birim. Tam sürüm (27 MB, 800k üçgen) aynı sayfada. |
| Analog multimetre | `stations/photoelectric/assets/polyhaven/retro_multimeter/` | [Poly Haven · Retro Multimeter](https://polyhaven.com/a/retro_multimeter) | elli moeller, CC0 1.0; glTF ve 4K PBR dokular. Fotoelektrik deneyde ibresi simülasyon akımına bağlanır. |
| Sera iç mekânı | `stations/seasons/assets/grab3d/greenhouse-interior.glb` | [Grab3D · Greenhouse Interior](https://grab3d.com/models/buildings/greenhouse-interior/) | Cozy Isometric Rooms Kit; CC0 1.0, oyun kullanımı için optimize 48.266 üçgen ve 2K dokular. Cam sera, saksı tezgâhları ve bitkiler tek tutarlı hazır model olarak sahneye bağlandı. |
| Metal ölçüm masası | `stations/measurement/assets/polyhaven/metal_office_desk/` | [Poly Haven · Metal Office Desk](https://polyhaven.com/a/metal_office_desk) | Ulan Cabanilla, CC0 1.0; glTF ve 2K PBR dokular. Ölçüm araçlarının bulunduğu 3D laboratuvara bağlandı. |
| Meyve tartısı | `stations/measurement/assets/grab3d/produce-scale.glb` | [Grab3D · Produce Scale](https://grab3d.com/models/electronics/produce-scale/) | Cozy Kitchen Kit; CC0 1.0, 6.146 üçgen ve 2K PBR dokular. Meyve model üzerinde durur; kütle ölçümü sahnesinde tek parça hazır tartı olarak kullanılıyor. |
| Tarih arşivi · altı şahsiyet | `stations/history/assets/archives/` | [Görsel başına kaynak, sanatçı, lisans ve sağlama toplamı](../stations/history/ASSET_SOURCES.md) | Bellini’ye atfedilen Fatih, Tiziano çevresinden Kanuni, tarihî minyatürler, Atatürk dönem fotoğrafı ve açıkça modern temsil olarak etiketlenen Mete Han heykeli. Özgün dosyalar korunur; yapay yüz ve alfa kesimi kullanılmaz. |

Poly Haven ve ambientCG'den gelen PBR dokular da CC0, doğrudan kullanılabilir. Poly Haven'ın lisansı varlıkların ticari kullanımına ve atıf zorunluluğu olmadan kullanımına izin verir: [lisans](https://polyhaven.com/license).

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
