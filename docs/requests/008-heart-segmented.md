# 008 · Kalp · parçalı model
Durum: açık | Üretici: Codex | Sahne: `stations/heart/` | Öncelik: yüksek

## Kapsam
AYT Biyoloji düzeyi: odacıklar, damarlar, kapaklar, kirli (oksijence fakir) ve temiz (oksijence zengin) kan. Hastalık, cerrahi ya da klinik parça yok (darlık, septum deliği, stent, yama, halka, kanül istenmiyor).

## Amaç
Bugünkü kalp tek parça ve tek malzeme. Kapağa, damara ve odacığa ayrı ayrı müdahale edilemiyor, kan duvarın içinde görünmüyor. Fizyoloji motoru (`scripts/physio/circulation.gd`) odacık hacmini, kapak açıklığını ve damar akışını hesaplıyor. Model bunu parça parça göstermeli.

## Çıktılar (`stations/heart/assets/segmented/`, GLB, 1 birim = 1 m, kalp ≈ 0,13 m, +Y yukarı)
1. `heart_segmented.glb`: isimli düğümler, her biri kendi mesh'i ve pivotuyla. Konumlar mevcut kalpteki ölçülmüş noktalarla (`docs/ENGINE.md`) uyumlu.
   - Odacık duvarları: `WallRA`, `WallRV`, `WallLA`, `WallLV` (kesit, içi görünür, kasılırken ölçeklenebilir, pivot odacık merkezinde).
   - Kan hacmi: `BloodRA`, `BloodRV`, `BloodLA`, `BloodLV`. Odacığın iç boşluğunu dolduran kapalı mesh, düğüm ölçeğiyle şişip inecek (boş ≈ %35, dolu %100). Ayrı, yarı saydam ıslak malzeme. Rengi kodla verilecek (mavi kirli, kırmızı temiz).
   - Damarlar: `Aorta`, `PulmonaryTrunk`, `SVC`, `IVC`, `PulmonaryVeinL`, `PulmonaryVeinR`. İçi boş, duvarlı, her birinde boş düğüm `ClampPoint`.
   - Kapaklar: `AnnulusTricuspid`, `AnnulusMitral`, `AnnulusAortic`, `AnnulusPulmonary`. Halka, yaprakçıklar (`LeafletTricuspid1..3`, `LeafletMitral1..2`, `LeafletAortic1..3`, `LeafletPulmonary1..3`) ve menteşe pivotları. Açık ve kapalı konumda temiz kapanmalı. Kordalar ve papiller kaslar (`Chordae*`, `Papillary*`).
2. Her kapak için `*_leaky` varyantı: yaprakçıklar tam kapanmıyor (yetersiz kapak). Aynı düğüm adları ve pivotlar.
3. `stations/heart/assets/tools/clamp_vessel.glb`: damarı kapatan kelepçe, iki çene ayrı düğüm (`JawA`, `JawB`).
4. Doku: ıslak kalp kası ve damar duvarı için PBR (albedo, normal, roughness, 2K), UV bozulmadan.

## Kabul ölçütü
Godot'ta `Wall*` ve `Blood*` düğümleri ölçeklenince mesh'ler birbirinin içinden geçmeden şişip iner. Her kapağın sağlam ve yetersiz hâli açık ve kapalı konumda doğru görünür. Kelepçe her damara oturur. Yakın planda plastik görünüm ve çarpık geometri yok.

## Varsayılanlar
Kaynak ve lisansı teslim notuna yaz. Sağ ve sol anatomik yön. Metin ya da etiket gömme.

## Sonraki iş (bilgi)
Aynı motorla Kas Atölyesi gelecek (iskelet kası, kiriş, sarkomer). İsimlendirme kuralını (isimli düğüm, pivot, boş müdahale noktası) aynen sürdür.
