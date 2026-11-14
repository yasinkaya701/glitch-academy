# 015 · Vektör Limanı 3B model ve arka plan
Durum: açık | Üretici: Codex | Hat: YKS | Sahne: `stations/vectors/` | Öncelik: yüksek | Kaynak: stations/vectors/mission.gd, docs/ART_DIRECTION.md, docs/STORY.md

## Bağlam
Vektör Limanı yeniden yazıldı (`harbor_stage.gd`): rıhtımda iki itici, bir kapsül ve yanaşma halkası; oyuncu iki itişi uç uca ekleyip bileşkeyi bulur. Mantık ve akış hazır, `tests/vectors_flow_test.tscn` ile test ediliyor. **Görseller şu an kodla kurulmuş düz kutu, kapsül ve halka.** Aşağıdakiler onların yerine geçecek. Oyuncunun okuyacağı ızgara, oklar ve etiketler kodda kalır; varlıklarda metin, sayı, ok ve ızgara olmaz.

Bilimsel kural: görsel vektör bilgisini yanlış anlatmaz. Kapsülün ön ve arka yönü açıkça okunur (burun, itici memesi). Rıhtım düz bir yüzeydir: kamera yukarıdan ve eğik bakar, doğu sağa, kuzey ekranda yukarıya gider. Ölçek: 1 birim = 0,55 m, rıhtım 7,6 × 5,9 m.

Stil: Gözlemevi dili. Gece laboratuvarı, grafit zemin, kehribar (`#dfae63`), adaçayı (`#8fbea0`), camgöbeği (`#6fe3c1`). Mavi ton yok. Gerçekçi, sade, süssüz. Parlak yapay zekâ illüstrasyonu, aşırı ayrıntı ve okunmaz küçük ayrıntı istemiyoruz.

## Kalite ölçütü (3B)
Asıl görsel 3B sahnedir: kamera yukarıdan eğik bakar ama kapsül ve düzenek 3× yakınlaştırmada da inandırıcı olmalı. Hedef: gerçek bir liman ve uzay kargosu hissi, tek sanat yönü, fotogerçekçiye yakın PBR.
- Tüm modeller aynı dilde: aynı metal, aynı aşınma düzeyi, aynı ışık şeridi tasarımı. Stil dışı tek parça teslim edilmez.
- Gerçek yapıdan yola çık: kaynak izi, perçin sırası, panel derzi, bakım kapağı, bağlantı elemanı. Her ayrıntının bir işlevi olsun; rastgele "sci-fi" süs ve oyuncak pürüzsüzlüğü yok.
- PBR zorunlu: BaseColor, Normal (OpenGL), ORM, gerekirse Emissive. Kenar aşınması, ince yağ ve is izi.
- Bütçe: kapsül ≤ 30 bin üçgen, itici ≤ 15 bin, halka ≤ 8 bin, baba ≤ 2 bin. Doku en çok 2048 (kapsül), diğerleri 1024; model başına en çok iki malzeme.
- Hareketli parçalar (kanat, nozul, kapak) ayrı düğüm; +X öne bakar.

## A. Kapsül, `stations/vectors/assets/models/`
- `capsule.glb`: Arşiv kargo kapsülü, uzunluk 0,45 birim, çap 0,2. Burun modülü (ön cam, sensör dizisi, anten) ve yük bölümü (bakım kapağı, kilit kolu, boş kimlik plakası). Arkada ana nozul, gövdede dört manevra itici ağzı, iki kısa yan kanat, gövde boyunca emissive ışık şeridi (rengi koddan).
  Düğümler: `Capsule` (kök), `Hull`, `Cockpit`, `Window`, `Antenna`, `Hatch`, `Nozzle`, `Thruster_1..4`, `Wing_L`, `Wing_R`, `Strip`. Pivot gövde merkezinde, burun +X, zemine oturma y = 0.
- `capsule_wreck.glb`: hatalı yanaşma sonrası: gövde hafif eğik ve çizik, sol kanat kırık, cam çatlak, kapak aralık, is izi, şerit sönük. Aynı düğüm adları.
- Kabul: 1280×720'de 60–80 px uzunlukta okunur; 3×'te panel derzi, perçin ve cam yansıması görünür. Burun ve arka yön renksiz de ayırt edilir.

## B. Yanaşma düzeneği ve rıhtım nesneleri, `stations/vectors/assets/models/`
- `dock_ring.glb`: zemine gömülü platform, dış çap 0,6, yükseklik 0,05: `Ring`, `Pad`, `Latch_1..4`, emissive `Lamp` (rengi koddan), kapakta kilit deliği ve ızgara.
- `thruster_a.glb`, `thruster_b.glb`: rıhtım kenarında sabit itici ünitesi (0,5 × 0,3 × 0,3): gövde, piston, `Nozzle`, hortum, boş kadranlı basınç göstergesi. A tek çizgi, B çift çizgi geometrik kabartma; `Strip` A kehribar, B adaçayı.
- `bollard.glb` (yükseklik 0,15), `crate_small.glb` / `crate_large.glb` (0,18 / 0,3, köşeli, boş etiket çerçevesi), `lamp_post.glb` (0,6, kehribar `Lamp`). Oyun alanı dışında kenarlarda durur.
- Kabul: A ve B yan yana renksiz de ayırt edilir. Oyun alanı içinde yalnız halka ve kapsül var; hiçbir nesne ızgara çizgisini ya da oku örtmez (yükseklik ≤ 0,05).

## C. Rıhtım, çevre ve arka plan, `stations/vectors/assets/`
- `quay_kit.glb`: modüler rıhtım (1 × 1 döşeme, köşe, kenar kirişi, derz), betonarme levha, çelik kenar profili. `quay_albedo.png`, `quay_normal.png`, `quay_orm.png` 2048 tile: koyu grafit-gri beton, ince derz, hafif lastik ve yağ izi. Kahverengi, kumlu, sarı kirli görünüm yok.
- `water_normal.png` (1024 tile) ve `water.glb` (≤ 2 bin üçgen, hafif dalgalı).
- `harbor_backdrop.png`: 4096×2048 eşdikdörtgen gece limanı: uzakta vinçler, konteyner yığınları, gemi silüeti, seyrek kehribar ışık, alçak sis. `#10110f`'tan belirgin açık değil; mavi baskın değil (grafit-yeşil, kehribar).
- `harbor_far.glb`: arka planda gerçek derinlik: iki vinç, konteyner yığını, gemi gövdesi (≤ 40 bin üçgen, tek malzeme).
- Kabul: rıhtım ve arka plan yan yana fark yalnızca ince dokudur; ızgara (beyaz, %16) üstte okunur. Işık: tek sıcak ana ışık, soğuk-yeşil dolgu.

## D. Giriş sprite'ı, `stations/vectors/assets/intro/`
Açılışta otopilotun yanlış toplamı görülür (≤ 8 sn, atlanabilir).
- `autopilot_line.png`: otopilotun "3 + 4 = 7" rotasını gösteren uzun, düz, kehribar ışık çizgisi dokusu (1024×16, şeffaf, metinsiz).
- `overshoot_flash.png`: kapsül yanaşma noktasını geçtiği an oynayacak, 512×512, şeffaf, ince halka ve kısa kırık ışık (Misafir imzası #15 A ile aynı dil), metinsiz.

## Genel kabul
- Tüm GLB'ler Godot'a hatasız aktarılır; ölçek, pivot ve düğüm adları yukarıdaki gibidir. Doku boyutu en çok 2048, toplam ≤ 90 MB (disk dar).
- Teslimde `stations/vectors/assets/README.md` güncellenir: her dosyanın kaynağı, üretim yöntemi, lisans notu.
- Teslimde Godot içinden iki ekran görüntüsü: Kriz ve Kurtar adımları, 1280×720 ve 900×600 (%130 yazı).
- Dosyaları yalnızca bu klasörlere koy; `stations/vectors/*.gd` ve `scripts/` dosyalarına dokunma. Koda bağlama işini Claude yapar. Eski `stations/vectors/assets/*.png` (üstten bakış sprite'ları) artık kullanılmıyor, silmeden `archive/`da kalsın.
