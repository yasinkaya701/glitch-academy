# 014 · Üç Güneş (final) 3B varlıkları
Durum: açık | Üretici: Codex | Hat: YKS | Sahne: `stations/yks/` | Öncelik: yüksek | Kaynak: stations/yks/THREE_SUNS_DESIGN_CARD.md, docs/STORY.md (Perde 3), docs/ART_DIRECTION.md

## Bağlam
Final artık 3B bir sahnede oynanıyor (`three_suns_stage.gd`): üç güneş, iz bırakan yörüngeler, tek gezegenli Kepler modu, ölçü cihazı ve MERİDYEN'in yetki çekirdeği. Mantık ve akış hazır, test ediliyor (`tests/three_suns_flow_test.tscn`). **Görseller şu an kodla çizilen düz küreler ve çizgiler.** Aşağıdakiler onların yerine geçecek. Gökyüzü panoraması #15'te (D) zaten teslim edildi; burada tekrarı yok.

Bilimsel kural: görsel hiçbir şeyi yanlış anlatmaz. Üç güneşin kütlesi eşittir ve hepsi aynı büyüklüktedir (renk farkı yalnızca ayırt etmek içindir, kütle ya da sıcaklık anlamı taşımaz). Yörünge ve zaman davranışı kodda, varlıklarda değil.

Stil: Gözlemevi dili. Gece laboratuvarı, grafit zemin, camgöbeği (`#6fe3c1`), kehribar (`#f2a65a`), adaçayı (`#8fbea0`). Gerçekçi, sade, süssüz. Metin, sayı ve etiket hiçbir görselde gömülü olmaz. Parlak yapay zekâ illüstrasyonu, aşırı ayrıntı ve okunmaz küçük ayrıntı istemiyoruz.

## A. Üç güneş, `stations/yks/assets/stars/`
- `star_a.glb`, `star_b.glb`, `star_c.glb`: aynı büyüklükte üç küre, yüzey granülasyonlu fotosfer, yumuşak kenar kararması (limb darkening). Renkler: A sıcak kehribar, B soğuk beyaz-mavi, C soluk kırmızı. Düğüm adı `Star`, pivot merkezde, çap 0,4 birim.
- `corona_a.png`, `corona_b.png`, `corona_c.png`: 1024×1024 şeffaf, yumuşak ışıma halkası (billboard olarak kullanılacak), metinsiz.
- Kabul: 1280×720'de ekranda 40–60 px çapında okunur; üçü yan yana renkle ve ek olarak **konum etiketiyle** ayırt edilir (renk tek başına değil).

## B. Gezegen ve Kepler düzeneği, `stations/yks/assets/kepler/`
- `planet.glb`: küçük, sade gezegen (çap 0,3 birim), hafif atmosfer kenarı, kıtaları belli ama Dünya'yı birebir kopyalamayan yüzey. Düğüm `Planet`.
- `start_marker.glb`: yörüngede başlangıç çizgisini gösteren ince direk ve taban (yüksekliği 0,9 birim), parlak uç. Düğüm `Marker`.
- `orbit_ring.png`: yörünge halkası için ince, düz ışık çizgisi dokusu (tile, 1024×32), şeffaf.
- `counter_ghost.png`: "sayaç dolduğu anda gezegenin konumu" için yarı saydam halka, 256×256.
- Kabul: Kepler modunda gezegen ile başlangıç işareti arasındaki mesafe ekranda rahat görülür.

## C. Ölçü cihazı paneli, `stations/yks/assets/console/`
- `measure_panel.png`: 9-dilim (9-slice) panel, 512×320, koyu grafit, ince kehribar köşe vurgusu, içi boş. Kenar payı: 24 px. Sağ üstte ekranda 272×170 px'e ölçeklenecek.
- Vektör ikonlar (SVG, 24 px ızgara, tek çizgi kalınlığı 1,8, `#b1ac9e` rengi): `icon_clock.svg` (süre), `icon_distance.svg` (iki iz arası mesafe), `icon_threshold.svg` (eşik ε), `icon_separated.svg` (ayrıldı, yalnız şekille: ▲ gibi, renk gerekmez), `icon_together.svg` (birlikte, ● gibi).
- Kabul: ikonlar 18 px'te okunur. Renk tek başına durum anlatmaz.

## D. Karanlık uzay, `stations/yks/assets/space/`
- `space_dark.png`: 4096×2048 eşdikdörtgen (equirectangular) çok koyu uzay; arka plan rengi `#0b0e14`'ten belirgin biçimde açık olmasın, çünkü parlak yörünge izleri bunun üstünde okunacak. Çok seyrek yıldız, ancak çok hafif bir toz bulutu ipucu. Metinsiz.
- `star_dust.png`: 1024×1024 şeffaf, kayan toz taneciği (tile).
- Kabul: `#0b0e14` zeminle yan yana konunca fark yalnızca ince dokudur.

## E. İz ve ayrılma efektleri, `stations/yks/assets/fx/`
- `trail_dash.png`: iz çizgisi için hafif noktalı çizgi dokusu (tile, 512×16), şeffaf.
- `gap_together.png` ve `gap_separated.png`: iki iz arasındaki mesafe çizgisi için ince ışık dokusu (256×16). Birlikte: kâğıt beyazı; ayrılmış: kırmızı, ayrıca çizgi kesikli olsun (renk tek başına durum vermesin).
- `separation_flash.png`: izler eşiği (ε) aştığı an bir kez oynayacak, 512×512, şeffaf, ince halka ve kısa kırık ışık (Misafir imzası #15 A ile aynı dil), metinsiz.
- Kabul: 1280×720'de iz üzerindeki efektler izi örtmez.

## F. Karar sahnesi, `stations/yks/assets/decision/`
- `meridyen_core.glb`: MERİDYEN'in merkezi yetki çekirdeği. Gözlemevi dili: grafit gövde, ortada yumuşak kırmızı atım yapan çekirdek, etrafında dönebilen üç ince halka (`Ring_1..3` ayrı düğümler). Çap 0,8 birim.
- `meridyen_core_released.glb`: aynı model, yetki kalkmış hâli: halkalar açılmış, çekirdek soğuk adaçayı rengi (`#8fbea0`), atım yok. Aynı düğüm adları.
- `treaty_seal.png`: mühür, 1024×1024 şeffaf. İçinde "açık kapı" görünümü: yarım açık bir halka ve ondan çıkan ışık çizgisi. Zafer değil anlaşma hissi. Metin yok.
- `archive_capsule.glb`: Arşiv veri kapsülü (hikâyedeki Arşiv zincirinin taşıyıcısı), uzunluk 0,6 birim, mat metal, ince ışık şeritli. Düğüm `Capsule`.
- Kabul: çekirdek 1280×720'de 120 px çapında okunur; iki hâl yan yana konunca fark yalnızca şekil ve ışıkla da anlaşılır.

## G. Kriz açılışı için kısa sprite dizisi, `stations/yks/assets/intro/`
Açılışta MERİDYEN'in "öngörü ufku sınırsız" iddiası ile ölçülen izin ayrışması görülür (≤ 8 sn, atlanabilir).
- `prediction_line.png`: MERİDYEN'in kusursuz öngörüsünü gösteren uzun, düz, soğuk ışık çizgisi dokusu (1024×16), şeffaf.
- `drift_1..6.png`: ölçülen izin tahminden yavaş yavaş kopmasını gösteren 6 kare, 512×512, şeffaf, ince kırık ışık (Misafir imzası dili).
- Kabul: kareler arka arkaya oynayınca titreme değil, yavaş ayrışma hissi verir.

## Genel kabul
- Tüm GLB'ler Godot'a hatasız aktarılır; ölçek, pivot ve düğüm adları yukarıdaki gibidir. Doku boyutu en çok 2048, toplam ≤ 100 MB (disk dar).
- Teslimde `stations/yks/assets/README.md`: her dosyanın kaynağı, üretim yöntemi ve lisans notu.
- Teslimde Godot içinden iki ekran görüntüsü: Kepler modu ve üç cisim ayrılma anı, 1280×720 ve 900×600 (%130 yazı).
- Dosyaları yalnızca bu klasörlere koy; `stations/yks/*.gd` ve `scripts/` dosyalarına dokunma. Koda bağlama işini Claude yapar.
