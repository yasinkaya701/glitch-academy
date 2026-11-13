# Açılış sahnesi

`res://scenes/intro/intro.tscn` ana sahnedeki gözlemevi görüntüsünün üstünde çalışır. Kök düğüm tam ekran bir `Control` öğesidir. Başlangıçta gizlidir. Önce `finished` ve gerekiyorsa `alarm_changed` sinyallerini bağla, ardından `start()` çağır.

- `finished` süre dolduğunda, **Açılışı geç** düğmesine basıldığında veya **Esc** kullanıldığında bir kez yayınlanır.
- `alarm_changed(strength: float)` gözlemevindeki ışık veya alarm animasyonunu sürmek için 0–1 aralığında yoğunluk bildirir. Bitişte 0 yayınlanır.
- Açılış 14 saniyedir. Dört bölüm gözlem, ölçüm farkı, ayar paneli arızası ve kontrol merkezine dönüşü gösterir. Sahne örneği her oyun başlangıcında bir kez oynar.
