# Yanlış Dünya · Hikâye

Bu belge anlatının ve oyun mantığının tek kaynağıdır. Her istasyon kendi bozulmasını buradaki kurala göre yazar. Oyun içi metin kısa kalır (docs/UX.md): hikâye uzun yazıyla değil, sahnedeki nesnelerle, kısa kayıt satırlarıyla ve oyuncunun kullandığı güçlerle anlatılır.

## Çekirdek fikir

Üç cisim problemi şunu söyler: üç kütle birbirini çekerken gelecek önceden hesaplanamaz. Küçük bir fark, bir süre sonra bambaşka bir yola çıkar. Bu oyunda bir uygarlık tam böyle bir gökte yaşar: üç güneşli, kaotik, hiçbir şeyin öngörülemediği bir dünya. Onlar için bilim, bir yasanın iki gün sonra da tutacağını bilmek bile değildir.

Dünya'nın en değerli özelliği onlar için tam budur: **yasalar yerinde durur, ölçüm tekrarlanır, bugün ölçülen yarın da doğrudur.** Bu yüzden Dünya'ya gelmeden önce onu bozmaya başlarlar. Saldırmazlar. Doğanın işleyişinde küçük, tutarsız kaymalar bırakırlar, böylece insanlar neyin doğru olduğundan emin olamaz ve bilim durur. Misafirler adını verdiğimiz bu varlıkların silahı kuvvet değil **güvensizliktir**.

Oyuncu bu kaymaları onarabilen tek kişidir.

## Oyuncu ve güçleri

Oyuncu **Kalibratör**'dür. Elinde bir **Zaman Makinesi** ve onunla gelen doğa üstü güçler vardır. Güçler oyun mantığının kendisidir: her biri bilimsel yöntemin bir adımını oyuncunun eline verir. Arayüzde tek bir alt şerit olarak durur, her istasyonda aynı yerdedir.

| Güç | Ne yapar | Öğrettiği yöntem |
|---|---|---|
| **Sar** | Olayı kaymanın başladığı ana geri götürür, deneyi aynı koşulda yeniden başlatır | Tekrarlanabilirlik: aynı koşul, aynı sonuç |
| **Yavaşlat** | Zamanı ¼ hıza çeker | Hızlı olayı okumak, grafiği anlık değerle eşlemek |
| **Ayır** | Tek bir değişkeni sıfırlar (havayı çeker, sürtünmeyi alır, kütleyi eşitler) | Kontrollü deney: bir şeyi değiştir, gerisini sabit tut |
| **Gör** | Görünmeyen nicelikleri gösterir (vektör oku, basınç, akış yönü) | Model: ölçülen ile hesaplanan aynı şekilde çizilir |

Güçlerin bir sınırı vardır: oyuncu **tahmin ederek** değil **ölçerek** ilerler. Güçler ölçümü kolaylaştırır, sonucu söylemez. Yanlış sayı sahnede yanlış sonuç üretir ve neden öyle olduğu tek cümleyle yazılır.

## Misafir imzası

Her kaymada aynı görsel iz vardır: dünyaya ince bir **yırtık**. Cisimlerin kenarında kısa süreli renk ayrışması, bir noktada doğrusal olmayan titreme, cihaz göstergesinde bir an görünen anlamsız sayı. Kayma onarılınca iz silinir ve sahnenin ışığı bir kademe sıcaklaşır. İz her istasyonda aynıdır, oyuncu onu tanımayı öğrenir.

## Kayma kuralı

Her istasyonun kayması üç parçadan kurulur:

1. **Görünen yanlış.** Oyuncu yanlışı ilk saniyede sahnede görür (zaman, mesafe, yön, kan). Metin gerekmez.
2. **Kaymanın kaynağı.** Misafirlerin değiştirdiği tek bir varsayım. Oyuncu bunu ölçümle bulur, kimse söylemez.
3. **Ölçümle çürütme.** Aynı düzenekte tek değişkeni ayırarak varsayım çürütülür. Çürütülen yasa **mühürlenir**: kayıt defterine kalıcı bir satır, sahnede kalıcı bir ışık olarak girer.

## Kriz kuralı

Soyut "cihaz yanlış sanıyor" yetmez. Her istasyon **somut bir kriz**tir:

- **Kaybedilecek bir şey vardır** ve sahnede görünür: kapsül kırılır, kapı kapalı kalır, kayıt silinir.
- **Sınırlı deneme ve son an** vardır (üç kapsül, kapak penceresi, sayaç). Cezası puan değil, sahnedeki sonuçtur.
- **Çözüm, konunun tamamını ister.** Son görev, öğrenilen kavramların hepsini birlikte kullanmayı gerektiren çok koşullu bir kurtarmadır. Biri eksikse sahnede kısmi bir hata görünür ve hata, eksik kavramı gösterir (hava var → vakum eksik; süre uzun → yükseklik yanlış).
- Deneyler çözümün kanıtını toplar, bilgi çıkarma ve ezber değildir. Oyuncu "neden" sorusunu ölçümle cevaplamadan kurtarma ekranına geçemez.

**Ortak iplik: Arşiv zinciri.** Gözlemevi'nin doğrulanmış ölçüm kayıtları (insanlığın bildiği yasalar) bir veri kapsülünde Arşiv'e taşınıyor. Misafirler zinciri halka halka koparmış. Her fizik istasyonu bu zincirin bir halkasıdır:

| Halka | Kriz | Kurtarmanın koşulları (hepsi birlikte) |
|---|---|---|
| 1 Ölçüm Atölyesi | Taşıyıcı ray kopuk, parça yuvaya sığmıyor | uzunluğu **m**'ye, kütleyi **kg**'a çevir ve rayın 2 m/s sınırından süreyi hesapla |
| 2 Vektör Limanı | Kapsül limanı kaçırıyor | iki rota segmentini ve yan rüzgârı bileşke olarak topla (yön, büyüklük) |
| 3 Düşüş Odası | Kapsül kapak kapandıktan sonra geliyor, her şey yavaş düşüyor | **g'yi ölç (h = ½gt²), kapsülü bu çekime göre kurtar, çekim dengeleyiciyi ayarlayıp g = 10'u geri getir** (uygulandı) |
| 4 Newton Kızağı | Kızak varış kapısına geç kalıyor | yükü seç (itici sınırı 40 N) ve F = m·a ile kuvveti gir |
| 5 Atış Alanı | Kapsül hedef halkasını ıskalıyor | düşüş süresinden yatay hızı bul, bırak–fırlat zamanlamasını eşitle |
| 6 Çarpışma Hattı | Arşiv kapısındaki iki araba kapıyı çarparak kırıyor | durdurma hızını (işaretli) hesapla ve ısıya giden enerjiyi (≤ 15 J) doğrula |
| Final | Arşiv'i Misafirlere ulaştırmak | iki cisim kapalı çözüm, üç cisim kaotik: öngörülemezlik de ölçülür |

## Bölümler

**I. Ölçü (Fizik).** Misafirler önce ölçmenin kendisine dokunur: birim, yön, zaman. İlk altı kayma birbirine bağlıdır, her biri bir öncekinin kurduğu aracı kullanır.

| # | İstasyon | Görünen yanlış | Kaymanın kaynağı | Çürütme (ve güç) | Kayıt satırı |
|---|---|---|---|---|---|
| 1 | Ölçüm Atölyesi (TYT) | Parça yuvaya sığmaz | Santimetre metre sayılıyor | 240 cm ile 2,4 m'yi rayda karşılaştır | "Sayı doğruydu. Birimi değişmişti." |
| 2 | Vektör Limanı (AYT) | Kapsül yanaşma noktasını kaçırır | Yer değiştirmeler yönsüz toplanıyor | Aynı iki oku ters yönde ekle (**Gör**) | "Uzunluk toplandı. Yön silinmişti." |
| 3 | **Düşüş Odası (AYT)** | Oda vakumda ama her şey beklenenden yavaş düşüyor: çelik ve sünger top 20 m'yi 2,58 s'de iner, cihaz 2,00 s bekler. Kapsül kapak kapandıktan sonra gelir | Misafirler Dünya'nın yer çekimini zayıflattı (g = 6 m/s²) | Kütleyi ve havayı ele (**Ayır**): vakumda ikisi eşit ama yine yavaş, geriye çekim kalır | "Kütle de hava da değildi. Çekimin kendisi kaymıştı." |
| 4 | Newton Kızağı (AYT) | Aynı itişle iki yük aynı hızlanır | İvme kütleden bağımsız sayılıyor | Aynı kuvvette iki kütleyi karşılaştır (**Yavaşlat**) | "İtiş yazılmış, yük silinmişti." |
| 5 | Atış Alanı (AYT) | Top hedefin önüne düşer | Yatay ve düşey hareket bağlanmış | İki topu aynı anda bırak ve fırlat (**Sar**) | "İki hareket tek sayılmıştı." |
| 6 | Çarpışma Hattı (AYT) | Çarpışmada toplam hareket kaybolur | Momentumun yönü korunmuyor | Ters yönde çarpıştır, toplamı al (**Gör**) | "Hareket yok olmamıştı. Yön değiştirmişti." |

**II. Yaşam (Biyoloji).** Misafirler canlı sisteme geçer. Kalp Odası: dolaşımın tek yönlülüğü bozulmuştur. Kayma: kan geri akıyor, çünkü yönü belirleyen şey (kapak) kayıp. Çürütme: kapakları doğru yönde yerleştir, oksijenin döngüsünü kapat. Kasta da aynı model sürer: uzunluk–kuvvet ilişkisi yanlış kurulmuştur.

**III. Madde (Kimya).** Misafirler maddenin tepkisine dokunur: göstergeler yanlış renk verir, tepkime beklenmedik yönde gider.

**IV. Sayı (Matematik).** Köprü, prizma, türev: Misafirler sayıların kendisini oynatır. Tutarsızlık, hesabın yerine tahminin geçmesidir.

## Final: Üç Güneş

Altıncı kaymadan sonra oyuncu Misafirlerin gökyüzünü görür: üç güneş, birbirini çeken üç kütle. Son istasyon **Kütle Çekim ve Kepler** (AYT Fizik 15) üzerinden kurulur. İki cisim için yörünge kapalı çözümle hesaplanır ve tahmin tutar. Üçüncü cisim eklenince küçük bir ilk fark yörüngeleri ayırır: oyuncu aynı başlangıçtan iki kez **Sar** yapıp başlattığında bile sonuç ayrışır. Ders, bilimin sınırıdır: öngörülemezlik de ölçülebilir bir şeydir.

Oyuncu bunu görünce Misafirlerin Dünya'ya neden saldırdığını anlar. Dünya'yı yok etmek istemezler, öngörülebilir bir yer ararlar. Oyun bittiğinde oyuncu mühürlenen yasaların hepsini Misafirlere, onların ölçebileceği biçimde yollar. Sonuç kesin bir zafer değil, bir anlaşmadır: yasalar yerinde, bir kapı açık.

## İstasyon yazım kuralları

- Açılış (≤ 8 sn, atlanabilir): kayma sahnede bir kez, Misafir imzasıyla görünür. Anlatıcı yoktur.
- Deney: oyuncu bir gücü kullanır, tek değişkeni değiştirir, sonucu ölçü cihazından okur. Yönerge tek cümledir.
- Uygulama: yeni bir durumda sayı girilir. Yanlış sayı yanlış sonuç üretir, neden tek cümleyle söylenir.
- Mühür: onarım sahnede ışık olarak kalır, kayıt defterine bir satır girer. Ödül puan değil, dünyanın düzelmesidir.

## Görsel ve arayüz ilkesi

Gerçek laboratuvar gerçekçiliği, sade ve sınıflı arayüz. Ekranda yalnızca yönerge, güçler şeridi ve ölçü cihazları durur. Etiket yığını, süs paneli, uzun metin yok. Misafir imzası tek bir yerde tanımlanır ve her sahnede aynı bileşenle çizilir.
