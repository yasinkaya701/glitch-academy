# 010 · Kas Atölyesi varlıkları
Durum: açık | Üretici: Codex | Sahne: `stations/muscle/` | Öncelik: yüksek | Kaynak: docs/STORY.md, docs/ART_DIRECTION.md

## Kapsam
AYT Biyoloji düzeyi: kasın yapısı (kas → lif → miyofibril → sarkomer), kayan iplik modeli (aktin, miyozin, Ca²⁺, ATP), sinir–kas kavşağı, kasın uzunluk–kuvvet ilişkisi, kas ve eklemin birlikte çalışması. Klinik ya da hastalık parçası yok.

Hikâyede Misafirler kasın "uzunluk ne olursa kuvvet aynı" olduğunu varsayacak şekilde bozuyor. Oyuncu izole kası gerer, uyarır, kuvveti ölçer ve gerçek eğriyi bulur. Kod tarafı (`muscle_sim.gd`, `sarcomere_view.gd`) hazır, istenen yalnızca görsel varlıklar.

Tümü gerçek laboratuvar ve anatomi gerçekçiliğinde, sinematik ışıkta (tek sıcak ana ışık + soğuk dolgu), PBR. GLB'lerde düğümler isimli, pivotlar belirtilen yerde, 1 birim = 1 m (mikroskobik modellerde 1 birim = 1 µm, notta belirt).

## A. İzole kas deney düzeneği (miyograf), `stations/muscle/assets/bench/`
`myograph.glb`: laboratuvar masası üstünde fizyolojik çözeltili cam organ banyosu, içinde asılı kurbağa baldır kası (gastroknemius) ve tendonu.
- Düğümler: `Bath` (cam, yarı saydam), `Solution` (sıvı yüzeyi, ayrı), `Muscle` (kas, ölçeklenebilir: boyu uzayıp kısalabilir), `TendonTop`, `TendonBottom`, `ForceTransducer` (üstte kuvvet sensörü, ayrı), `Electrodes` (iki elektrot, uyarıda parlayabilir `Tip_A`, `Tip_B`), `Clamp` (alt tutucu), `StretchKnob` (kası geren vida, döner), `Stand`.
- Ayrıca `kymograph.glb`: dönen silindir ve iğne (`Drum`, `Stylus`), kuvvet eğrisini çizen eski tip kayıt düzeneği. `Drum` döner, `Stylus` dikey hareket eder.
- Kabul: kas `Muscle` düğümü Y'de %60–%140 ölçeklenince bozulmadan uzar ve kısalır.

## B. Kas yapısı, kademeli yakınlaşma, `stations/muscle/assets/structure/`
Tek bir kasın içine doğru inen dört ölçek, her biri ayrı GLB ve ortak renk dili:
- `muscle_belly.glb`: kas karnı, tendon, fasiyal zar (`Epimysium`), kesit.
- `fascicle.glb`: kas demeti (`Perimysium`), içinde lifler.
- `fiber.glb`: tek kas lifi (hücre), `Sarcolemma`, çok çekirdek (`Nucleus_1..6`), mitokondri, miyofibrillerin kesiti.
- `myofibril.glb`: miyofibril, bant desenli (açık ve koyu şeritler), Z çizgileri. Bantlar için malzeme ayrı (`BandA`, `BandI`, `ZLine`).
Her ölçek bir sonrakine geçişte aynı malzeme dilini taşır, geçiş ölçeklemeyle yapılacak.

## C. Sarkomer modeli, `stations/muscle/assets/sarcomere/`
Kod şu an procedural çiziyor. Gerçekçi karşılığı: `sarcomere.glb` ve ayrı parçalar.
- `thick_filament.glb`: miyozin (`Tail`, ve 12 ayrı baş `Head_01..12`, her başın menteşesi pivot). Baş açık ve gergin konumda iki pozda, aynı pivot.
- `thin_filament.glb`: aktin (iki zincirli sarmal), `Tropomyosin`, `Troponin` (3 birim), Ca²⁺ bağlanınca tropomiyozin açılacağı için `Tropomyosin` ayrı düğüm ve iki konum (kapalı, açık).
- `z_disc.glb`, `m_line.glb`, `titin.glb` (yay gibi, uzayabilir).
- Aktin, miyozin ve Ca²⁺ için ayrıştırılabilir renk: miyozin amber, aktin camgöbeği, Ca²⁺ beyaz, ATP yeşil (`ca_ion.glb`, `atp.glb` küçük parçacık modelleri).

## D. Sinir–kas kavşağı, `stations/muscle/assets/junction/`
`neuromuscular_junction.glb`: motor nöron ucu (`Terminal`), sinaptik veziküller (`Vesicle_*`, asetilkolin), sinaptik aralık, kas zarındaki ACh reseptörleri (`Receptor_*`), T-tüpçüğü (`TTubule`), sarkoplazmik retikulum (`SR`, içinde Ca²⁺ parçacık yuvası).
Düğümler ayrı, veziküller terminalden aralığa hareket edebilsin.

## E. Eklem ve kol, `stations/muscle/assets/limb/`
`arm_biceps.glb`: kemik (`Humerus`, `Radius`, `Ulna`), `Biceps`, `Triceps`, tendonlar, `Elbow` ekleminde pivot. Biceps kısalınca ön kol yukarı, triceps kısalınca aşağı döner. Antagonist çalışma gösterilecek. Düğümler kasları ayrı ölçeklenebilir.

## Kabul
Her GLB Godot'a hatasız aktarılır, ölçek ve pivotlar notta yazıldığı gibi. Kas ve sarkomer parçaları üst üste binmeden açılıp kapanır. Metin gömülmez. Teslimde sahneden iki ekran görüntüsü ve kaynak/lisans notu. Doku boyutu 2048, toplam ≤ 300 MB, tercihen ≤ 150 MB.

## Sırayla teslim
1. A (miyograf), 2. C (sarkomer), 3. B (yapı ölçekleri), 4. D, 5. E.
