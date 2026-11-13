# 004 · Düşüş Odası varlıkları
Durum: açık | Üretici: Codex | Sahne: `stations/free_fall/mission.tscn`

## Amaç
AYT Hareket: vakum odasında iki farklı kütle aynı anda düşer, oyuncu g'yi ölçüp sensör yüksekliğini hesaplar. Bu oda "gerçek deney simülasyonu" kalitesinde olmalı.

## Çıktılar (`stations/free_fall/assets/`)
| Dosya | İçerik |
|---|---|
| `chamber.glb` | Dikey cam vakum odası, metal tabanlı, yanında vakum pompası borusu. Ölçek: 1 birim = 1 m, yükseklik 5 m. Düğümler: `Glass`, `Base`, `Release_Left`, `Release_Right`, `Sensor_Plate`. |
| `mass_light.glb` `mass_heavy.glb` | Aynı boyutta iki silindir kütle, farklı malzeme (alüminyum ve pirinç, gerçekçi PBR). |
| `sensor_plate.png` | Zeminde ışıklı sensör plakası, kapalı ve tetiklenmiş iki durum. |
| `chamber_bg.png` (1920×1080) | Laboratuvar iç mekânı arka planı, karanlık, odaklı spot. Metin yok. |
| `air_fault.png` (1920×1080) | Arıza karesi: havalı odada tüy ve çekiç, yanlış ölçüm hissi. |
| `tex_*` | Metal ve cam için 2048 PBR (albedo, normal, roughness). |

## Görsel tarif
Gerçek fizik laboratuvarı: temiz, sert yansımalı cam, hafif toz. Tek sıcak spot, soğuk dolgu. Ölçü çizgileri ve grafik Godot'ta çizilir.

## Kabul ölçütü
- `.glb` Godot'a hatasız aktarılır, düğüm adları yukarıdaki gibi, ölçek doğru.
- İki kütle aynı yükseklikten bırakılabilir, bırakma noktaları ayrı düğüm.

## Varsayılanlar
Stil [ART_DIRECTION.md](../ART_DIRECTION.md). `.glb` üretilemezse çok katmanlı PNG ile 2D kesit teslim et ve notta belirt.
