# Atış Alanı · Görsel varlıklar

Section B of issue #17. Bu klasör yalnızca `stations/projectile/` sahnesinin varlıklarını içerir; fizik hesabını değiştirmez.

## Kullanım ve boyutlar

| Dosya | Boyut | Mod | Boyut (bayt) | İşlev |
|---|---:|---|---:|---|
| `range_bg.png` | 1920×1080 | RGB | 1,124,478 | 45 m platformu, aşağı uzanan zemin ve sağda boş etki alanı; 60 m hedef yuvası |
| `ball_launch.png` | 128×128 | RGBA | 12,591 | Amber şeritli yatay atış küresi |
| `ball_drop.png` | 128×128 | RGBA | 12,141 | Soğuk mint işaretli bırakılan küre |
| `launcher.png` | 640×384 | RGBA | 10,646 | Yatay pnömatik namlu ve eşzamanlı bırakma elektromıknatısı |
| `target_ring.png` | 512×192 | RGBA | 3,854 | Hedefin sönük durumu; sprite anchor/ölçeği `target_ring_on.png` ile aynıdır |
| `target_ring_on.png` | 512×192 | RGBA | 19,076 | Hedefe iniş doğrulandığında yanan durum |

## Yeniden üretim ve kaynak

`python3 stations/projectile/assets/generate_assets.py` komutu paket görsellerini üretir. `range_bg.png`, `generate_range_bg.gd` ve `.tscn` içindeki el yapımı Godot 3D sahnesinden GPU viewport renderıyla çıkar. Godot 4 ve çalışan masaüstü renderer gerekir; doğrulama Godot 4.7.2 / Metal renderer ile yapıldı. Geometri, PBR malzemeler, sabit tohumlu yüzey dokuları, pencere camı, ışıklar ve gölgeler kaynakta tanımlıdır. Diğer beş şeffaf PNG Pillow ile çizilir. Hiçbir harici görsel, font, iz sürülmüş çizim veya AI çıktısı kullanılmaz; harici lisans gerektiren parça yoktur. `GODOT_BIN` ortam değişkeni, Godot çalıştırılabilirinin tam yolunu seçebilir.

İlk düzenleme turunun altı PNG'si, README'si ve kaynak Pillow jeneratörü `archive/iteration_01/` altında korunur. Yeni arka plan Godot sahnesi ve bu sürümün Pillow jeneratörü kök klasördedir; jeneratör arşive dokunmaz.

## Oynanabilir sahne

Varlıklar `stations/projectile/mission.tscn` ve `mission.gd` içinde kullanılır. Godot editöründen sahneyi açıp çalıştırın veya proje kökünden:

```sh
godot --path . --rendering-method gl_compatibility --scene res://stations/projectile/mission.tscn
```

Hız kaydırıcısı yatay başlangıç hızını değiştirir; **FIRLAT** gerçek model API'sinden hesaplanan yörüngeyi ve eşzamanlı bırakılan küreyi oynatır. **SIFIRLA** deneyi başa alır. Hedef halkası 60 m çevresinde inişte yanar. Yörünge ve ölçümler `projectile_sim.gd` fonksiyonlarını çağırır; o dosyanın fizik hesabı değiştirilmemiştir. `docs/review/projectile_mission_hit.png` ve `projectile_mission_miss.png`, Godot 4.7.2 GL Compatibility çalıştırmasından alınmış iki bitiş karesidir.

## Kontrol

Çıktı adları, ölçüler ve PNG modları Pillow ile doğrulandı. Arka plan Godot'ta görsel olarak incelendi. Mission sahnesi Godot 4.7.2 ile import edilip çalıştırıldı; hit/miss ekranları gerçek sahneden kaydedildi. Launcher, küreler ve hedefin açık/kapalı durumları aynı boyutlarda korunur. İlk düzenleme turunun altı PNG'si, README'si ve kaynak Pillow jeneratörü `archive/iteration_01/` altında korunur.
