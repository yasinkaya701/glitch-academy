# Fizik arkı · Kayma kurguları (Bölüm I · Ölçü)

[STORY.md](STORY.md) kuralına göre altı istasyonun her biri için eksiksiz kurgu. Her sayı `tests/physics_rules_test.gd` ve `tests/fall_test.gd` ile doğrulanmıştır. Düşüş Odası uygulanmış referanstır (`stations/free_fall/`). Diğerlerinin kural katmanı hazır, sahneleri varlık teslimini bekliyor ([011](requests/011-physics-scenes.md)).

Ortak yapı: **Açılış** (≤ 8 sn, atlanabilir, anlatıcı yok) → **Deney** (güç kullanılır, tek değişken) → **Uygulama** (yeni durumda sayı girilir) → **Mühür** (ışık ve kayıt satırı). Yanlış cevap sahnede yanlış sonuç üretir, nedeni tek cümledir. Her açılışta Misafir imzası görünür.

---

## 1 · Ölçüm Atölyesi · TYT Fizik Bilimine Giriş

**Kayma.** Cihaz santimetreyi metre sayıyor. **Kaynağı:** birim dönüşümü silinmiş. **Güç:** Yavaşlat.

**Açılış.** Raya yeni bir bağlantı parçası inmek üzere. Cihaz ekranı "240" okuyor, rayın yanındaki cetvelde parça 2,4 m. Parça yuvaya inerken 100 kat büyük çiziliyor, yuvaya sığmıyor ve taşıyıcı duruyor. Parçanın kenarında kısa süre renk ayrışması.

**Deney.**
1. Cetvelle parçanın uzunluğunu, teraziyle kütlesini, sayaçla düşüş süresini ölç. Ölçüm okunur, birim ayrı bir kutuda seçilir.
2. Birimi eşle: uzunluk **m**, kütle **kg**, süre **s** (SI). Seçilen birim yanlışsa cihaz sayıyı yine gösterir ama şerit üzerinde parça yanlış boyda çizilir.
3. Yol ve süreden ortalama sürat: taşıyıcı 6 m'yi 3 s'de gidiyor, v = 6 / 3 = 2 m/s. **Yavaşlat** ile sayaç anlık okunur. Sürat göstergesi büyüklük (skaler), yönlü ok yön (vektör) verir.

**Uygulama.** Yeni parça 240 cm. Metre cinsinden gir.
- **2,4** (virgül ya da nokta): parça oturur, taşıyıcı çalışır.
- **240**: parça 100 kat uzun çizilir, yuvaya sığmaz. *Cümle: "240 cm, 240 m değil. Metreye çevirirken 100'e böl."*
- **24**: 10 kat uzun. *"Santimetreyi metreye çevirmek için 100'e bölünür, 10'a değil."*
- İkinci adım: kütle 1500 g → **1,5 kg**. Yanlışta (1500) taşıyıcı ağır sayılıp kalkmaz.

**Mühür.** Ray bağlantısı tamamlanır, sahne ışığı sıcaklaşır. *Kayıt: "Sayı doğruydu. Birimi değişmişti."*

**Kazanım.** TYT Fizik Bilimine Giriş: büyüklükler, SI birimleri, ortalama sürat. **Kabul.** Ondalık virgül ve nokta aynı değeri verir, birim ve sonuç animasyonu tutarlı.

---

## 2 · Vektör Limanı · AYT Vektörler

**Kayma.** Cihaz yer değiştirmeleri yönsüz topluyor. **Kaynağı:** yön silinmiş, yalnız uzunluk kalmış. **Güç:** Gör.

**Açılış.** Kargo kapsülü iki rota segmentini izliyor: 3 birim doğu, 4 birim kuzey. Cihaz yanaşma noktasını **7** birim uzakta işaretliyor (3 + 4). Kapsül oraya gidiyor, gerçek nokta 5 birim uzakta, kapsül iki birim ileri geçip limanı kaçırıyor. Kapsülün gölgesi iki yönde ikiye ayrışıyor.

**Deney.**
1. 3 birim doğu ve 4 birim kuzey oklarını uç uca ekle. Son nokta (3, 4). **Gör** ile bileşenler ve açı çizilir.
2. Aynı bileşkeyi paralelkenarla çiz. İki yöntem aynı sonucu verir: büyüklük √(3² + 4²) = **5**.
3. Yer değiştirme (başlangıçtan son noktaya, 5) ile alınan yolu (7) karşılaştır: biri vektör, biri skaler.

**Uygulama.** Yeni rota 5 birim doğu, 12 birim güney. Bileşkeyi (x, y) ve büyüklüğü gir.
- Doğru: **(5, −12), büyüklük 13**. Kapsül hedefe oturur.
- İşaret yanlış, **(5, 12)**: kapsül kuzeyde, karşı tarafta durur. *"Güney eksi y yönüdür."*
- Büyüklük **17** (5 + 12, yönsüz): kapsül 4 birim ileri geçer. *"Dik bileşenler toplanmaz, bileşke √(5² + 12²) olur."*

**Mühür.** Liman kapısı kapanır, ışık sıcaklaşır. *Kayıt: "Uzunluk toplandı. Yön silinmişti."*

**Kazanım.** 11.1.1.3 (2026 YKS): vektörlerin bileşkesi. **Kabul.** İki çizim yöntemi aynı sonucu verir, ekran koordinatı kuzey–güneyi ters göstermez.

---

## 3 · Düşüş Odası · AYT Hareket (uygulandı)

**Kayma.** Cihaz odada hava yokmuş gibi hesaplıyor. **Güç:** Ayır (havayı çek).
Açılış: çelik küre 2,00 s, sünger top 4,34 s, cihaz her ikisini 2,00 s bekliyor. Deney: vakum, g = 2h/t² = 10 m/s². Uygulama: 45 m'den kapsül 3,00 s. *Kayıt: "Kütle değildi. Hava hesaptan çıkarılmıştı."* Ayrıntı `stations/free_fall/mission.gd`.

---

## 4 · Newton Kızağı · AYT Newton'un Hareket Yasaları

**Kayma.** Cihaz ivmeyi kütleden bağımsız sayıyor (a = F). **Kaynağı:** kütle denklemden silinmiş. **Güç:** Yavaşlat.

**Açılış.** Hava yastıklı rayda iki aynı itici kızak yan yana. Biri 2 kg, biri 5 kg yük taşıyor, ikisine de 10 N itiş. Cihaz ikisini de 10 m/s² ile hızlanacak sanıyor ve varış zamanını ona göre yazıyor. Ağır kızak geride kalıyor, cihazın "varış" ışığı yanlış zamanda yanıyor. Ağır kızağın arkasında renk ayrışması.

**Deney.**
1. Aynı itişle (10 N) iki kızağı bırak. **Yavaşlat** ile hız–zaman grafiğini izle: 2 kg için eğim **5 m/s²**, 5 kg için **2 m/s²**.
2. Kuvveti ikiye katla (20 N): eğim ikiye katlanır. Kütleyi ikiye katla: eğim yarıya iner.
3. Oran: a = F / m. Grafik eğimi ile hesap aynı şekilde çizilir.

**Uygulama.** 6 kg yük, ray 40 m, kızak durgun başlayıp **tam 4 s'de** varmalı. Gereken itiş kuvvetini (N) gir.
- Doğru: gereken ivme a = 2d/t² = 2·40/16 = 5 m/s², **F = m·a = 30 N**. Kızak tam zamanında varır.
- **5** (cihazın a = F yanlışıyla): kızak 40 m'yi 9,8 s'de gider. *"İvme yalnız kuvvete bağlı değil, F = m·a."*
- **6** (kütleyi çarpmayı unutarak): a = 6 / 6 = 1 m/s², kızak 40 m'yi 8,9 s'de gider. *"Gereken ivmeyi bulduktan sonra kütleyle çarp: F = m·a."*

**Mühür.** Kızak varış çizgisinde durur, ışık sıcaklaşır. *Kayıt: "İtiş yazılmış, yük silinmişti."*

**Kazanım.** AYT Fizik 6: Newton'un ikinci yasası, F = m·a. **Kabul.** Hava yastıklı ray sürtünmesizdir, grafik eğimi ile ivme eşleşir, doğru F ile varış süresi 4,00 s.

---

## 5 · Atış Alanı · AYT Atışlar

**Kayma.** Cihaz yatay ve düşey hareketi birbirine bağlıyor. **Kaynağı:** yatay hız arttıkça düşüşü yavaşlatıyor. **Güç:** Sar.

**Açılış.** 45 m yükseklikte iki top. Biri bırakılıyor, biri yatay 20 m/s ile atılıyor. Cihaz atılan topu daha geç düşecek sanıyor: ekran 5,4 s gösteriyor. Atılan top beklentinin çok önünde, gerçek zamanda yere iniyor, bırakılan topla aynı anda. Atılan topun izinde renk ayrışması.

**Deney.**
1. İki topu aynı anda bırak ve fırlat. Yere birlikte inerler (ikisi de t = √(2h/g) = **3 s**).
2. **Sar** ile aynı atışı farklı yatay hızlarla (10, 20, 30 m/s) tekrarla: süre hep 3 s, menzil 30, 60, 90 m.
3. İzi çiz: yatay bileşen sabit hızlı, düşey bileşen serbest düşme. İki bileşen ayrı çizilir, bileşke yol parabol.

**Uygulama.** Platform 45 m yükseklikte, hedef **60 m** uzakta. Atış hızını (m/s) gir.
- Doğru: t = 3 s, v₀ = 60/3 = **20 m/s**. Top hedefe iner.
- **15**: top 45 m'de yere iner, hedefin 15 m önünde. *"Yatay hız menzili, yükseklik süreyi belirler: x = v₀·t."*
- **60** (menzili hız sanmak): top 180 m'ye gider. *"60 m hedef mesafesi, hız değil. v₀ = x / t."*

**Mühür.** Top hedef halkasına iner, ışık sıcaklaşır. *Kayıt: "İki hareket tek sayılmıştı."*

**Kazanım.** AYT Fizik 8: yatay atış. **Kabul.** Yatay hız düşüş süresini değiştirmez, bırakılan ve atılan top birlikte iner.

---

## 6 · Çarpışma Hattı · AYT İtme ve Momentum

**Kayma.** Cihaz momentumu yönsüz topluyor. **Kaynağı:** momentum bir vektör olduğu unutulmuş. **Güç:** Gör.

**Açılış.** Raylı iki araba karşı karşıya: 2 kg araba +3 m/s, 1 kg araba −3 m/s. Yapışarak çarpışacaklar. Cihaz ortak hızı **3 m/s** gösteriyor (6 + 3 = 9, 9 / 3 = 3). Arabalar çarpışıp yapıştığında yavaş, **1 m/s** ile ağır arabanın yönünde gidiyor. Cihazın "hareket kaybolmuş" uyarısı yanıyor. Arabaların yapıştığı noktada renk ayrışması.

**Deney.**
1. İki arabayı çarpıştır. **Gör** ile her arabanın momentum oku çizilir: biri sağa 6, biri sola 3. Toplam ok sağa 3.
2. p = 2·3 + 1·(−3) = **3 kg·m/s**, ortak hız v = 3 / 3 = **1 m/s**. Çarpışma öncesi ve sonrası toplam ok aynı.
3. Enerjiye bak: öncesi 13,5 J, sonrası 1,5 J. Kaybolan **12 J** ısıya gitti, momentum kaybolmadı, enerji yön değiştirmedi. Esnek çarpışmada ikisi korunur.

**Uygulama.** 3 kg araba +4 m/s ile geliyor, karşısındaki 5 kg araba ters yönde. Yapışınca **durmaları** (ortak hız 0) için 5 kg arabanın hızını (m/s) gir.
- Doğru: 3·4 + 5·v = 0, **v = −2,4 m/s** (sola 2,4). Arabalar çarpışıp yapışınca durur.
- **2,4** (işaretsiz, sağa): toplam 12 + 12 = 24, birlikte 3 m/s ile sağa gider. *"Karşı yön eksi işaretlidir."*
- **−4** (kütleyi unutarak): ortak hız (12 − 20) / 8 = −1 m/s. *"Momentum kütle ile hızın çarpımıdır, 5 kg daha yavaş yeter."*

**Mühür.** Arabalar çarpışıp ray ortasında durur, ışık sıcaklaşır. *Kayıt: "Hareket yok olmamıştı. Yön değiştirmişti."*

**Kazanım.** AYT Fizik 9: momentum korunumu, esnek ve esnek olmayan çarpışma. **Kabul.** Toplam momentum çarpışma öncesi ve sonrası eşit, enerji kaybı esnek olmayan çarpışmada hesapla uyuşur.

---

## Kazanımlar tablosu

| # | İstasyon | Kazanım | Güç | Sayılar |
|---|---|---|---|---|
| 1 | Ölçüm Atölyesi | TYT Fizik Bilimine Giriş | Yavaşlat | 240 cm = 2,4 m; 6 m / 3 s = 2 m/s; 1500 g = 1,5 kg |
| 2 | Vektör Limanı | 11.1.1.3 | Gör | (3, 4) → 5; (5, −12) → 13 |
| 3 | Düşüş Odası | 11.1.4.3 | Ayır | 20 m, 2 s, g = 10; 45 m, 3 s |
| 4 | Newton Kızağı | AYT Fizik 6 | Yavaşlat | 10 N: 5 ve 2 m/s²; 40 m, 4 s, 6 kg → 30 N |
| 5 | Atış Alanı | AYT Fizik 8 | Sar | 45 m, 3 s, 60 m → 20 m/s |
| 6 | Çarpışma Hattı | AYT Fizik 9 | Gör | 2·3 + 1·(−3) → 1 m/s; 3·4 → −2,4 m/s |

Bölüm bağlantısı: Düşüş Odası'ndaki 45 m ve 3 s, Atış Alanı'nda aynı yükseklik ve süreyle geri döner. Oyuncu aynı kapsülü bu kez yatay atar.
