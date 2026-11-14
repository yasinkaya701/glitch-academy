# Yeni simülasyonlar · oynanabilir prototipler

Bu değişiklik mevcut deneyleri, hikâyenin yedi bölümlük LGS sırasını ve bütün diğer rotaları silmeden iki bağımsız istasyon ekler. Her görev `scripts/mission.gd` sözleşmesini izler ve yalnızca doğru bağımsız uygulamadan sonra `completed.emit()` çağırır.

## LGS / Kalıtım Laboratuvarı

- **Yol:** LGS → *Kalıtım Laboratuvarı*; 8. sınıf keşif listesinde de bulunur.
- **Arıza:** MERİDYEN'in kalıtım kaydı, baskın özellik göründüğünde çekinik aleli yok sayar.
- **Gözlem:** `AA × aa` çaprazlamasında tüm hücrelerin `Aa` olduğunu gör; `Aa × Aa` deneyinde `AA, Aa, Aa, aa` olasılıklarını karşılaştır.
- **Öğrencinin eylemi:** İki örneği ölçümle açtıktan sonra `Aa × aa` için çekinik fenotipin olasılığını (%50) tahmin eder.
- **Görsel ilişki:** 3B tohumların sarı/yeşil fenotipi, 2B Punnett karesiyle aynı genotip hesabından gelir. Yanlış giriş onarmaz.
- **Bilimsel sınır:** 1:2:1 ve 3:1 ifadeleri yavru sayısı değil, teorik olasılıktır. Model, tek bir gen ve tam baskınlık varsayımını kullanır.

İstasyon dosyaları: `stations/genetics/{genetics_model.gd,mission.gd,mission.tscn,mission.tres}`.

## AYT / Akış Laboratuvarı

- **Yol:** YKS → AYT → Sayısal / Eşit ağırlık → *Akış Laboratuvarı*; ayrıca 12. sınıf keşif listesi.
- **Arıza:** Sayaç `q(T)×T` değerini birikmiş hacim sanıyor; artan debide bu sonuç hatalı.
- **Gözlem:** `q(t)=2+t` L/s. `T=2 s` için `V=6 L`; `T=4 s` için `V=16 L`, yanlış sensörün `24 L` tahminiyle karşılaştır.
- **Öğrencinin eylemi:** 30 litrelik hedef için süreyi kendisi ayarlar ve çalıştırır. Doğru cevap `T=6 s`, çünkü `V(T)=2T+T²/2`.
- **Görsel ilişki:** Akış grafiğinin altında dolan alan, 3B tanktaki su yüksekliği ve sayısal toplam tek bir fonksiyondan hesaplanır.
- **Sınırlar:** Basitleştirilmiş lineer debi modeli; t 0–8 s, tank kapasitesi 36 L. Tankın fiziksel çizimi 36 L'de dolar; sayısal değer aşarsa taşma olarak işaretlenir.

İstasyon dosyaları: `stations/integral/{integral_model.gd,mission.gd,mission.tscn,mission.tres}`.

## Çalıştırma ve test

Godot **4.7.2 Standard** ile F5; sonra ilgili rotadan istasyonu aç. Tek bir sahne için F6 kullanılabilir. Sayısal model ve onarım kapısı testi:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/new_simulations_test.gd
```

**Doğrulama notu:** Model eşitlikleri yazılı olarak kontrol edildi. Bu ortamda Godot çalıştırılmadığı için sahne parser'ı, render çıktıları ve 1280×720 ekran görüntüsü henüz doğrulanmadı. PR birleştirilmeden önce Godot testini ve iki sahnenin F5/F6 görsel incelemesini çalıştırın.

## Ekip sınırı

- LGS: yalnızca `stations/genetics/`
- YKS: yalnızca `stations/integral/`
- Ortak katalog: `scripts/control_center.gd` (entegrasyon)

Yeni simülasyonlar ileride aynı `mission.tres` tanımıyla ve bağımsız bir `model.gd` ile eklenebilir. LGS isteğe bağlı istasyon ana yedi sahnenin zorunlu kilit zincirinin dışında kalır.
