# 015 · Vektör Limanı 3B model ve arka plan
Durum: açık | Üretici: Codex | Hat: YKS | Sahne: `stations/vectors/` | Öncelik: yüksek | Kaynak: stations/vectors/mission.gd, docs/ART_DIRECTION.md, docs/STORY.md

## Bağlam
Vektör Limanı yeniden yazıldı (`harbor_stage.gd`): rıhtımda iki itici, bir kapsül ve yanaşma halkası; oyuncu iki itişi uç uca ekleyip bileşkeyi bulur. Mantık ve akış hazır, `tests/vectors_flow_test.tscn` ile test ediliyor. **Görseller şu an kodla kurulmuş düz kutu, kapsül ve halka.** Aşağıdakiler onların yerine geçecek. Oyuncunun okuyacağı ızgara, oklar ve etiketler kodda kalır; varlıklarda metin, sayı, ok ve ızgara olmaz.

Bilimsel kural: görsel vektör bilgisini yanlış anlatmaz. Kapsülün ön ve arka yönü açıkça okunur (burun, itici memesi). Rıhtım düz bir yüzeydir: kamera yukarıdan ve eğik bakar, doğu sağa, kuzey ekranda yukarıya gider. Ölçek: 1 birim = 0,55 m, rıhtım 7,6 × 5,9 m.

Stil: Gözlemevi dili. Gece laboratuvarı, grafit zemin, kehribar (`#dfae63`), adaçayı (`#8fbea0`), camgöbeği (`#6fe3c1`). Mavi ton yok. Gerçekçi, sade, süssüz. Parlak yapay zekâ illüstrasyonu, aşırı ayrıntı ve okunmaz küçük ayrıntı istemiyoruz.

## A. Kapsül, `stations/vectors/assets/models/`
- `capsule.glb`: Arşiv kargo kapsülü, uzunluk 0,45 birim. Mat metal gövde, burunda ön cam, arkada tek itici memesi, iki kısa yan kanat, ince kehribar ışık şeridi. Düğümler: `Capsule` (kök), `Hull`, `Window`, `Nozzle`, `Strip`. Pivot gövde merkezinde, burun +X yönünde, zemine oturma yüksekliği y = 0.
- `capsule_wreck.glb`: aynı kapsül, hatalı yanaşma sonrası hâli: gövde hafif yamuk, kanat kırık, cam çatlak. Aynı düğüm adları.
- Kabul: 1280×720'de kapsül 60–80 px uzunlukta okunur; burun ve arka yön renksiz de ayırt edilir.

## B. Yanaşma düzeneği, `stations/vectors/assets/models/`
- `dock_ring.glb`: zemine gömülü yanaşma halkası, dış çap 0,6 birim, yükseklik 0,05. Halka (`Ring`) ve iç kapak (`Pad`) ayrı düğüm; halkada emissive bir şerit (`Lamp`) olsun, rengi koddan verilecek.
- `thruster_a.glb`, `thruster_b.glb`: iki itici, rıhtım kenarında duran küçük sabit itici ünitesi (0,5 × 0,3 × 0,3 birim), memeleri kapsüle bakar. A kehribar, B adaçayı ışık şeridiyle; şerit dışında aynı model.
- `bollard.glb`: bağlama babası, yükseklik 0,15 birim.
- Kabul: ikisi yan yana konunca renksiz de A ve B işaretiyle (A: tek çizgi, B: çift çizgi, geometrik kabartma) ayırt edilir.

## C. Rıhtım ve çevre, `stations/vectors/assets/`
- `quay_top.png` (PBR): rıhtım betonu, 2048×2048 tile, `quay_albedo.png`, `quay_normal.png`, `quay_roughness.png`. Koyu grafit, ince derz, hafif kullanım izi. Kahverengi, kumlu ya da kirli görünüm istemiyoruz.
- `harbor_backdrop.png`: 4096×2048 eşdikdörtgen gece limanı, kamera aşağıya baktığı için yalnız ufuk ve su kenarı görünür: koyu su, uzakta vinç ve konteyner silüetleri, seyrek sarı ışıklar, hafif sis. Arka plan rengi `#10110f`'tan belirgin biçimde açık olmasın; ızgara ve oklar bunun üstünde okunacak. Mavi baskın olmasın (grafit-yeşil, kehribar ışık).
- `water.glb` veya `water_normal.png`: sakin su yüzeyi için tile edilebilir normal haritası, 1024×1024.
- Kabul: rıhtım ve arka plan yan yana konunca fark yalnızca ince dokudur, ızgara çizgileri (beyaz, %16 saydam) üstte okunur.

## D. Giriş sprite'ı, `stations/vectors/assets/intro/`
Açılışta otopilotun yanlış toplamı görülür (≤ 8 sn, atlanabilir).
- `autopilot_line.png`: otopilotun "3 + 4 = 7" rotasını gösteren uzun, düz, kehribar ışık çizgisi dokusu (1024×16, şeffaf, metinsiz).
- `overshoot_flash.png`: kapsül yanaşma noktasını geçtiği an oynayacak, 512×512, şeffaf, ince halka ve kısa kırık ışık (Misafir imzası #15 A ile aynı dil), metinsiz.

## Genel kabul
- Tüm GLB'ler Godot'a hatasız aktarılır; ölçek, pivot ve düğüm adları yukarıdaki gibidir. Doku boyutu en çok 2048, toplam ≤ 60 MB (disk dar).
- Teslimde `stations/vectors/assets/README.md` güncellenir: her dosyanın kaynağı, üretim yöntemi, lisans notu.
- Teslimde Godot içinden iki ekran görüntüsü: Kriz ve Kurtar adımları, 1280×720 ve 900×600 (%130 yazı).
- Dosyaları yalnızca bu klasörlere koy; `stations/vectors/*.gd` ve `scripts/` dosyalarına dokunma. Koda bağlama işini Claude yapar. Eski `stations/vectors/assets/*.png` (üstten bakış sprite'ları) artık kullanılmıyor, silmeden `archive/`da kalsın.
