# 002 · Vektör Limanı sahnesi
Durum: açık | Üretici: Codex | Sahne: `stations/vectors/mission.tscn`

## Amaç
Şu an düz bir ızgara ve minik altıgen kapsül var, bir yönetim paneline benziyor. Oyuncu gece yarısı bir uzay limanında, gerçek bir kargo kapsülünü yanaşma noktasına yönlendirdiğini görmeli. Izgara kalır ama liman zemininin üstünde ince bir ölçü katmanı olur.

## Çıktılar
Hepsi `stations/vectors/assets/` altında.

| Dosya | Boyut | İçerik |
|---|---|---|
| `harbor_top.png` | 2048×1536 | Limanın tam üstten görünümü. Sönük metal iniş platformu, ortada yanaşma halkası, kenarlarda bakım yolları, uzakta karanlık deniz/uzay. Kuzey yukarı. Izgara çizgisi, ok veya yazı yok. |
| `capsule_top.png` | 512×512 | Kargo kapsülü üstten, uç yönü sağ (doğu). Gerçekçi: gövde panelleri, itici kanatçıklar, küçük pencere. Şeffaf zemin. Merkezi tuvalin tam ortasında. |
| `capsule_thrust.png` | 512×512 | Aynı kapsül, itici ışıkları yanık. Aynı hizada. |
| `dock_ring_off.png` `dock_ring_on.png` | 512×512 | Yanaşma halkası. Off: sönük. On: iç hat amber yanıyor. Merkez ortada. |
| `wrong_dock_wreck.png` | 1024×1024 | Hatalı rotada kapsülün durduğu yer. Karşı tarafta bir yanaşma çizgisini kaçırmış kapsül, uyarı ışıkları kırmızı (`#E5645A`). Şeffaf zemin. |
| `harbor_fault.png` | 1920×1080 | Açılış arıza sahnesi, kısa animasyonun kare görseli. Kontrol cihazı yönleri silmiş: kapsül yanaşma noktasının yanından geçip uzaklaşıyor, liman ışıkları kırmızı. Sinematik, geniş açı. |

## Görsel tarif
Gerçekçi fiziksel malzeme: sönük çelik, boyalı panel, hafif aşınma, ıslak zeminde ışık yansıması. Tek ana ışık, amber liman lambaları. Gökyüzü yıldızlı lacivert. Kapsülün ve limanın ölçeği tutarlı: kapsül, halkanın yaklaşık %20'si. Ölçü ve vektör okları Godot'ta çizilir, görsele işlenmez.

## Kabul ölçütü
- Kapsül görselleri üst üste konunca birebir hizalı.
- `harbor_top.png` üstüne çizilen ızgara ve oklar okunur kalır (zemin aşırı detaylı değil).
- Kuzey, yukarı ve doğu, sağ. Kapsül ucu doğuya bakar.
- Çarpık geometri, bozuk panel çizgisi veya metin yok.

## Varsayılanlar
Stil [ART_DIRECTION.md](../ART_DIRECTION.md). Çıktı üretilemezse `harbor_fault.png` sonraya kalabilir, diğerleri öncelikli.
