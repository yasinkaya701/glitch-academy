# 012 · Şov kalitesi varlıklar: kalp kapakçıkları, Stern–Gerlach hattı, fizik düzenekleri
Durum: açık | Üretici: Codex (kota dolarsa Gemini) | Öncelik: yüksek | Kaynak: docs/ART_DIRECTION.md, docs/STORY.md, docs/HEART.md, docs/EXPERIMENTS.md

Kalite ölçütü: oyunun vitrin sahneleri. Fotogerçekçi, tek sıcak ana ışık + soğuk dolgu, metinsiz. Hatalı anatomi, çarpık geometri, stil dışı veya yapay zekâ dokusu kabul edilmez, teslimden önce düzelt. Her varlık aynı sahnede aynı ışık yönünde olsun. Tüm 2D görseller şeffaf PNG, 3D modeller `.glb`, etkileşimli parçalar ayrı ve adlı düğümler.

## A. Kalp kapakçıkları, `stations/heart/assets/valves/` (en önemli)

Mevcut kapak, Godot'ta kodla kurulmuş basit geometri. Yerine gerçek protez görünümü isteniyor. Ölçek: halka dış çapı 0,10 birim (kalp modeli ile aynı birim, bkz. docs/HEART.md), +Y ekseni akış yönü, pivot halkanın merkezinde.

- `valve_mechanical.glb`: **mekanik çift yaprakçıklı kapak** (triküspit ve mitral için). Pirolitik karbon iki yarım disk yaprakçık, titanyum halka, dikiş manşeti (kumaş dokusu, dikiş izleri). Düğümler: `Ring`, `Cuff`, `LeafletA`, `LeafletB`. Yaprakçık pivotları menteşe eksenine hizalı, `LeafletA` ve `LeafletB` X ekseni etrafında 0°'den 78°'ye dönünce açılır, 0°'de tam kapanır ve kenarlar örtüşür.
- `valve_bioprosthetic.glb`: **biyoprotez üç yaprakçıklı kapak** (pulmoner ve aort için). Üç destek direği (stent) kumaş kaplı, perikard dokusundan üç yaprak, yaprak kenarlarında doğal kıvrım ve ince damar dokusu. Düğümler: `Stent`, `Cuff`, `Cusp1`, `Cusp2`, `Cusp3`. Her yaprak merkeze doğru kapanır, 70° dışa açılır. Üç yaprak kapalıyken birleşme çizgisi ince bir Y.
- `valve_leaking.glb` ve `valve_stuck.glb`: aynı kapakların hasarlı hâlleri (kalsifiye ve yapışmış bir yaprak, kısmen açık kalan yaprak). Arıza teşhisi için gözle ayırt edilebilir, ama rengi tek başına bilgi taşımasın: şekil farkı olsun.
- `valve_arrow.glb`: akış yönünü gösteren, halkaya takılabilir küçük ok parçası. Düğüm adı `Arrow`.
- `valve_slot_ring.png` (şeffaf, 512×512): kalp üstünde boş yuvayı belirten ince ışıklı halka, boş ve dolu iki durum.

Kabul: Godot'ta `Ring` ve yaprak düğümleri tek tek döndürülebilir, mekanik kapak kapalıyken ışık sızdırmaz, biyoprotez yaprakları iç içe geçmez. Kalp kesiti modeli (`stations/heart/assets/model/heart_cutaway_light.glb`) içinde dört yuvaya ölçek ve yön olarak oturduğunu gösteren bir ekran görüntüsü.

## B. Spin Hattı (Stern–Gerlach), `stations/spin/assets/`

Sahne şu an 2D çiziliyor (`stations/spin/spin_view.gd`). Şov sahnesi için fotogerçekçi laboratuvar düzeneği:

- `apparatus_bg.png` (1920×1080): karanlık vakum hattı laboratuvarı, soldan sağa uzanan ince çelik tüp, üç mıknatıs aşaması ve bir dedektör yerleşimi için boş duraklar, sağda bir ekran plakası. Sağ alt köşe metin için sade.
- `oven.png` (şeffaf, 512×512): ince bir çıkış deliği olan sıcak atom fırını, tel sargı, çıkışta turuncu ışıma.
- `magnet_pair.png` (şeffaf, 512×768, yandan): eşit olmayan alan için keskin kenarlı üst kutup ve oluklu alt kutup, bobinler, soğutma boruları. İki durum: kapalı ve açık (mavi-beyaz iç ışık). Atom kanalı iki kutbun arasında okunabilsin.
- `detector_head.png` (şeffaf, 512×512): sezyum, gümüş atom sayacı kafası, `magnet_pair` ile uyumlu malzeme.
- `screen_plate.png` (şeffaf, 256×768): temiz cam ekran, iz bırakacak fosfor yüzey. Atom izleri kod ile çizilecek.

Spin dönen küre olarak çizilmeyecek (docs/EXPERIMENTS.md modelleme kuralı): hiçbir görselde dönen top, ok veya "sarmal" olmasın.

## C. Fizik düzenekleri, cila paketi

- Dalga Girişimi, `stations/waves/assets/`: `ripple_tank_bg.png` (1920×1080, iki noktasal kaynaklı dalga tankı, yukarıdan yarı perspektif, sağda sade alan), `vibrator_source.png` (şeffaf, 256×256, titreşim motorlu kaynak), `sensor_a.png` ve `sensor_b.png` (şeffaf, 256×256, A sensörü hassas optik kafa, B alıcısı arşiv veri alıcı, ikisi ayrı silüet).
- Fotoelektrik, `stations/photoelectric/assets/`: `vacuum_tube.png` (şeffaf, 768×768, cam tüp, sezyum plaka, toplayıcı, ışık girişi), `lamp_beam.png` (frekansa göre tint edilebilen, beyaz tabanlı ışın), `archive_door.png` (şeffaf, kapalı ve açık iki durum).
- Düşüş Odası, `stations/free_fall/assets/`: mevcut `chamber_bg.png` ile uyumlu `gravity_stabilizer.png` (şeffaf, 512×768, dişli ve ayar kadranlı kütle çekim dengeleyici), `capsule_shatter.png` (kapsül parçalanma sprite sayfası, 8 kare, 256×256).

## Teslim ve kabul

- Her dosya Godot'a hatasız aktarılır, adlar yukarıdaki gibi, aynı sahnedeki parçalar aynı ışık yönünde.
- Her paket için kaynak ve lisans notu (`docs/ASSET_SOURCES.md` biçimi). Harici model kullanıldıysa CC0 veya ticari kullanıma açık olsun.
- Teslimde ilgili sahne içinde hedef çözünürlükte (1600×900 ve 1920×1080) iki ekran görüntüsü. Okunabilirlik: etiketler ve ölçümler varlıkların üstünde okunmalı.
- Öncelik sırası: A (kapakçıklar), B (spin), sonra C. İstasyon sahibi varlıkları kendi sahnesine bağlar.

## D. Çarpışma Hattı ve Newton Kızağı, gerçek model ve sahne (öncelik: yüksek, A'dan sonra)

Mevcut sahne Godot'ta kodla kurulmuş kutular ve Metal009/DiamondPlate dokularıyla yapıldı, kabul edilmedi. Yerine hazır model ve sahne isteniyor. Stil: fotogerçekçi laboratuvar, nötr çelik ve koyu gri, tek sıcak ana ışık. Parlak renk yalnızca küçük aksan olsun (araba üstündeki ince şerit). Pembe, mor, neon yok.

- `stations/collision/assets/cart_a.glb`, `cart_b.glb`: hava yastıklı ray arabası, alüminyum gövde, yan tampon, üstte ağırlık yuvaları. Ağırlık için `stations/free_fall/assets/mass_heavy.glb` ile uyumlu 1 kg'lık pirinç silindirler, 1'den 6'ya kadar dizilebilsin. Pivot gövde ortası, +X çarpışma yönü. Adlı düğümler: `Body`, `BumperLeft`, `BumperRight`, `LoadSlot1`...`LoadSlot6`.
- `stations/collision/assets/air_track.glb`: 3 m hava yastıklı ray, delikli üst yüzey, ayaklar, iki uç tamponu, 10 cm işaretli cetvel şeridi.
- `stations/collision/assets/archive_door.glb`: metal çerçeveli cam kapı. `Glass` ayrı düğüm olsun (parçalanma animasyonu Godot'ta). Çatlak ve sağlam iki doku durumu.
- `stations/collision/assets/lab_set.glb` veya `lab_bg.png` (1920×1080): sade laboratuvar tezgâhı ve duvar, sağ yarı ölçü yazıları için temiz.
- Newton Kızağı: aynı ray ve araba ailesi, itici kızak varyantı (`sled.glb`, arkada itici nozulu), varış kapısı `finish_gate.glb`.
- Düğme ve arayüz: bu sahnelerde kullanılacak yuvarlak kaydırıcı tutacağı ve kaydırıcı rayı için Meridian setine `slider_track.png`, `slider_grabber.png` eklensin (9 dilim).

Kabul: modeller `assets/materials` PBR dokularıyla değil kendi dokularıyla gelir, aynı ışık yönünde, Godot'a hatasız aktarılır. Teslimde 1600×900 iki ekran görüntüsü.
