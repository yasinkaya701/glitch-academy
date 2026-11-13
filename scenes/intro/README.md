# Açılış sahnesi

`res://scenes/intro/intro.tscn`, kontrol merkezinin üstünde sekiz saniyelik, atlanabilir hikâye açılışını oynatır. Tam ekran Dünya kadrajı önce sakin ve tutarlı görünür; Meridyen yörüngeyi kaydırıp gerçeklikte ince bir yırtık açar. Kalibratör'ün Zaman Makinesi geri sarma yayıyla görünür olur, fakat bozulma sürer. Son kare, ilk LGS sinyali olan Mevsim Gözlemevi'ne yöneltir.

Giriş, `finished` ve gerekiyorsa `alarm_changed` sinyallerini bağladıktan sonra `start()` çağrısıyla başlar. **Açılışı geç** düğmesi ve **Esc** aynı `finished` sinyalini yayınlar. `alarm_changed(strength: float)` 0–1 aralığında yoğunluk bildirir ve bitişte 0'a döner.
