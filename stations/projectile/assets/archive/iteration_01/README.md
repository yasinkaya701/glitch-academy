# Atış Alanı · Görsel varlıklar

Section B of issue #17. Bu klasör yalnızca `stations/projectile/` sahnesinin varlıklarını içerir; fizik hesabını değiştirmez.

## Kullanım ve boyutlar

| Dosya | Boyut | Mod | Boyut (bayt) | İşlev |
|---|---:|---|---:|---|
| `range_bg.png` | 1920×1080 | RGB | 1,080,611 | 45 m platformu, aşağı uzanan zemin ve sağda boş etki alanı; 60 m hedef yuvası |
| `ball_launch.png` | 128×128 | RGBA | 12,591 | Amber şeritli yatay atış küresi |
| `ball_drop.png` | 128×128 | RGBA | 12,141 | Soğuk mint işaretli bırakılan küre |
| `launcher.png` | 640×384 | RGBA | 10,646 | Yatay pnömatik namlu ve eşzamanlı bırakma elektromıknatısı |
| `target_ring.png` | 512×192 | RGBA | 3,854 | Hedefin sönük durumu; sprite anchor/ölçeği `target_ring_on.png` ile aynıdır |
| `target_ring_on.png` | 512×192 | RGBA | 19,076 | Hedefe iniş doğrulandığında yanan durum |

## Yeniden üretim ve kaynak

`python3 stations/projectile/assets/generate_assets.py` komutu altı PNG'yi deterministik olarak üretir. Pillow dışında bağımlılığı yoktur. Geometri, katmanlı ışık, malzeme tonlaması ve sabit tohumlu yüzey dokusu betikte tanımlıdır. Görsel kaynak olarak dış görsel, font, iz sürülmüş çizim veya AI çıktısı kullanılmamıştır; harici lisans gerektiren parça yoktur.

İlk düzenleme turu, önceki konseptleri koruma kuralı gereği `archive/iteration_01/` altında saklanmıştır. Son tur kök PNG dosyalarıdır; arşiv jeneratör tarafından yazılmaz.

## Kontrol

Çıktı adları, ölçüler ve PNG modları Pillow ile doğrulandı. Godot 4.7.2 headless editor import'u başarıyla tamamlandı; arka plan, launcher, küreler ve hedefin açık/kapalı durumları görüntü olarak incelendi. Arka planın sağ tarafı Godot'ta ölçüm ve arayüz yazıları için boş bırakılmıştır. Sahne varlıkları henüz bir `mission.tscn` içine bağlanmamıştır.
