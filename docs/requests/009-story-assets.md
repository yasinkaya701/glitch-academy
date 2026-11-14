# 009 · Hikâye varlıkları: Misafir imzası, güçler, Üç Güneş
Durum: teslim edildi | Üretici: Codex | Öncelik: yüksek | Kaynak: docs/STORY.md

Hikâye değişti: Misafirler (üç güneşli kaotik bir dünyadan gelen varlıklar) Dünya'nın yasalarına küçük kaymalar bırakıyor, oyuncu Zaman Makinesi ve güçlerle onları onarıyor. Düşüş Odası teslimi (#11) oyuna alındı, `chamber_bg.png` ve sensör plakası kullanılıyor. Aşağıdakiler yeni.

## A. Misafir imzası (her istasyonda aynı bileşen)
`assets/world/signature/`: şeffaf PNG, 1920×1080 ve 512×512 iki boyut.
- `tear_01..04.png`: dünyada ince "yırtık": birkaç piksel kalınlığında kırık ışık çizgisi, kenarında camgöbeği ve eflatun renk ayrışması. Yatay ve dikey varyant.
- `glitch_noise.png`: yatay bant gürültüsü (tile), kısa titremede kullanılacak.
- `ghost_ring.png`: cismin etrafında renk ayrışmalı halka (düşen küre için).
Metinsiz, süssüz. Her öğe 0,3–1 sn titreyip kaybolacak şekilde ince.

## B. Güçler şeridi ikonları
`assets/ui/powers/`: 96×96 şeffaf PNG, her biri normal ve basılı hâl. Tek renk çizgi ikonu, 2 px çizgi, köşeleri yuvarlak, mevcut arayüz paletiyle (docs/ART_DIRECTION.md).
- `sar` (saat yönünün tersine dönen ok ve kum saati), `yavaslat` (yarım dolu daire), `ayir` (iki parçaya ayrılan kare), `gor` (göz ve ince ızgara).

## C. Düşüş Odası sahne parçaları (`stations/free_fall/assets/`)
Mevcut `chamber_bg.png` ile aynı ışık ve renk dilinde, şeffaf PNG, 256×256:
- `ball_steel.png` (cilalı çelik küre), `ball_foam.png` (sarı sünger top), `capsule.png` (turuncu kargo kapsülü, yeşil şerit), `feather.png`, `hammer.png`.
- `glass_highlight.png`: cam odanın üstüne bindirilecek dikey yansıma bandı (şeffaf, 160×600), toplar camın içinde kalsın diye.
- `chamber_bg_clear.png`: `chamber_bg.png` aynısı ama cam odanın içi tamamen boş ve sağ yarı daha geniş koyu duvar (ölçü yazıları için).

## D. Üç Güneş gökyüzü (final sahnesi)
`assets/world/three_suns/`: 3840×1080 yatay panorama, üç güneşli yabancı gökyüzü (sıcak amber, soğuk beyaz, soluk kırmızı), kaotik ama güzel. Metinsiz. Ayrıca her güneş ayrı şeffaf katman (`sun_a.png`, `sun_b.png`, `sun_c.png`, 1024×1024, yumuşak ışıma).

## Kabul
Godot'a hatasız aktarılır, boyutlar ve adlar yukarıdaki gibi. Teslimde sahneden iki ekran görüntüsü. Kaynak ve lisans notu.

## Teslim notu

- PNG'ler ve üretim kaynakları talep edilen yollarda; kaynak/lisans ve boyutlar [teslim özetinde](../review/issue15_assets.md).
- [A/B/C asset board](../review/issue15_abc_asset_board.png) ve [D asset board](../review/issue15_d_asset_board.png) önizlemedir; çalışan sahne ekran görüntüsü değildir.
- Bu asset-only dalında bağlanmış çalışan sahne yok; dolayısıyla kabulde istenen iki sahne ekran görüntüsü sağlanamıyor.
- Pillow boyut/mod kontrolleri ve Godot 4.7.2 headless import başarılı.
