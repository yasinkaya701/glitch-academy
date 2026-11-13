# Deney ve arayüz denetimi · 2026-11-14

Mevcut istasyonların [DESIGN.md](../DESIGN.md) kurallarına göre denetimi. Bulgular kod okunarak çıkarıldı, sayılar elle doğrulandı. Bir madde düzeldikçe satırı silinir.

## Ortak sorunlar

Fizik istasyonları `scripts/physics/experiment_mission.gd` şablonunu paylaştığı için aynı sorunları taşır.

| # | Sorun | DESIGN.md kuralı | Nerede |
|---|---|---|---|
| 1 | Hata mesajındaki "Örnek: …" doğru cevabın kendisi | İpucu cevabı içermez | 12 yer, aşağıdaki tablo |
| 2 | Teşhis üç şıklı düğme, yanlış seçimin bedeli yok | Teşhis şıkla yapılmaz | Düşüş, Newton, Atış, Çarpışma, Spin, Dalga, Fotoelektrik |
| 3 | Sına toast'ı kuralı söylüyor ("Kütle arttıkça ivme azalıyor"), Neden adımı aynı şeyi soruyor | Sonucu oyun söylemez | Aynı istasyonlar |
| 4 | Ölç adımında sayılar yönergede veriliyor ("4 kg yüke 20 N") | Sayı cihazdan okunur | Newton, Atış, Çarpışma, Dalga, Fotoelektrik |
| 5 | Üç hak bitince haklar sınırsız yenileniyor | Hak sınırlıdır ve bitmesinin bir sonucu vardır | Hepsi |
| 6 | Bozma tutarsız: Düşüş'te dünyanın g'si değişiyor, diğerlerinde cihazın modeli yanlış | Dünya her zaman doğru kuralla çalışır, bozuk olan MERİDYEN'in ayarıdır | Düşüş Odası |
| 7 | Adım adı "Ölç/Onar", akış beş ya da altı adım, isimler değişken | Altı adım: Kriz, Sına, Teşhis, Düzelt, Toparla, Mühür | Hepsi |

### Cevabı veren ipuçları

| İstasyon | Satır | İpucu | Doğru cevap |
|---|---|---|---|
| Düşüş Odası | `mission.gd` `_check_measure` | Örnek: 6,0 | g = 6 |
| Düşüş Odası | `_run_rescue` | Örnek: 27 | ½·6·3² = 27 |
| Newton Kızağı | `_check_measure` | Örnek: 5 | 20 / 4 |
| Newton Kızağı | `_run_rescue` | Örnek: 30 | 6 · 2·40/4² |
| Atış Alanı | ölç | Örnek: 3 | √(2·45/10) |
| Atış Alanı | kurtar | Örnek: 20 | 60 / 3 |
| Çarpışma Hattı | ölç | Örnek: 1 | (6 − 3) / 3 |
| Çarpışma Hattı | ısı | Örnek: 9,6 | 6 + 3,6 J |
| Spin Hattı | ölç | Örnek: 50 | %50 |
| Dalga Girişimi | ölç | Örnek: 1,5 | 3 / 2 |
| Dalga Girişimi | kurtar | Örnek: 6 | tek çözüm 6 Hz |
| Fotoelektrik Kapısı | ölç ve kurtar | Örnek: 5,0 · Örnek: 8 ve 70 | 5,0; 8 ve 70 kapıyı açıyor (1,24 eV, 5,6 µA) |

## İstasyonlar

**Düşüş Odası** (referans)
- Düzelt adımı, yön ipucu veren kaydırıcıyla ikili aramaya dönüşüyor, hesap gerekmiyor. Öneri: iki ayardan doğrusal kalibrasyon (eğim ve kesişim) hesaplatmak.
- Hava açıkken "Ama oda zaten vakumdaydı" yazıyor.
- Yeni bozma önerisi: MERİDYEN'in düşüş öngörüsü kütleye bağlı (ağır cisim önce düşer). Kapak zamanlaması bu öngörüyle ayarlanıyor, hafif kapsül geç kalıyor.

**Newton Kızağı**
- STORY.md'de "yük seç, itici sınırı 40 N" var, kodda tek değer ve 1–100 N.
- Kızak yerine oyuncak araba (`assets/models/toy_car`) kullanılıyor.

**Atış Alanı:** Fizik doğru. Toparla adımı tek formülle çözülüyor ve ikinci bir koşul yok.

**Çarpışma Hattı:** "Isı en çok 15 J" koşulu karar gerektirmiyor, doğru durdurmada ısı her zaman 9,6 J.

**Spin Hattı:** Ardışık Stern–Gerlach süzgeçleri AYT Kimya kazanımının (spin kuantum sayısı) ötesinde. Sınıflar rotasında gösteri olarak kalmalı.

**Dalga Girişimi:** Düz shader ve sağda bir veri paneli var. Tezgâh üstünde bir dalga leğenine taşınmalı.

**Fotoelektrik Kapısı:** Fizik doğru. İpucu sızıntısı dışında 2D düzenek sorunu var.

**Kalp Odası:** Debi adımında ekran "x × 70 = … (ihtiyaç 10500)" hesabını canlı gösteriyor. Oyuncu kaydırıcıyı sayılar eşitlenene kadar sürüyor, hesap yapmıyor.

**Depo Atölyesi (türev):** En iyi kurgulanmış istasyon: ölçüm, eğim ve uygulama birbirine bağlı. 2D çizim 3D düzeneğe taşınmalı.

**Gösterge Laboratuvarı:** TYT'de iki numuneden düşük pH'lısını seçmek yarı yarıya tahminle geçiliyor. Çizimlerde `ThemeDB.fallback_font` (Godot varsayılan yazı tipi) kullanılıyor.

**Ölçüm Atölyesi, Vektör Limanı, Mevsim Gözlemevi:** Başlık, paragraf ve düğmeden oluşan eski metin paneli yapısında. Düzenek 2D çizimle taklit ediliyor.

**YKS mikro görevleri (13):** Hepsi seçme, eşleştirme ya da sıralama sorusu. Kriz, bozma ve ölçüm yok. Sosyoloji eşleştirmesinde statü ve rol karışmış ("Ders anlatmak" bir rol).

**Üç Güneş:** Oyuncu ölçmeden ve karar vermeden bitiriyor, her Δv tamamlanma sayılıyor. STORY.md'deki "aynı başlangıçtan iki kez başlatınca bile sonuç ayrışır" cümlesi bilimsel olarak yanlış: deterministik sistemde aynı başlangıç aynı sonucu verir, kaos küçük bir farkın büyümesidir. Kod doğru yapıyor, belge düzeltilmeli.

## Arayüz

| Alan | Durum |
|---|---|
| Tema | IBM Plex ve Inter. Etiketler aralıklı büyük harf. "ADIM 2/5 · SINA" gibi noktalı meta dizileri. |
| Gözlemevi | Liste ve gri bloklar, boş görünen paneller, "KONTROL MERKEZİ" kicker'ı |
| HUD | Sağ üstte tek kalmış "i", toast taşması, güç şeridinin yeri istasyona göre değişiyor |
| 3D tezgâh | Hangar HDRI'ı, gri zemin, ahşap tezgâh, okunmayan Label3D |
| Kopya renkler | `stage_kit.gd`, `mission_hud.gd`, `stations/yks/mission.gd`, `indicator/mission.gd` kendi `Color("#…")` sabitlerini taşıyor |
| Meridian Display | Elle çizilmiş, aileyle uyumsuz. Arşive kaldırılacak. |
| Metin denetimi | Yok. `tools/` altına aralıklı büyük harf, noktalı dizi, uzun tire, emoji ve cevabı içeren "Örnek" arayan bir denetleyici gerekli. |

## Sağlam olanlar

- Bütün simülasyonların fiziği doğru, kural kodu çizimden ayrı ve testli.
- Yanlış girişlerdeki neden cümleleri tipik hataları yakalıyor: ½ çarpanını unutmak, işareti ters almak, ters bölmek.
