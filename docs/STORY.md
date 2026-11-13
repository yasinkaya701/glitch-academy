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

## Bölümler

**I. Ölçü (Fizik).** Misafirler önce ölçmenin kendisine dokunur: birim, yön, zaman. İlk altı kayma birbirine bağlıdır, her biri bir öncekinin kurduğu aracı kullanır.

| # | İstasyon | Görünen yanlış | Kaymanın kaynağı | Çürütme (ve güç) | Kayıt satırı |
|---|---|---|---|---|---|
| 1 | Ölçüm Atölyesi (TYT) | Parça yuvaya sığmaz | Santimetre metre sayılıyor | 240 cm ile 2,4 m'yi rayda karşılaştır | "Sayı doğruydu. Birimi değişmişti." |
| 2 | Vektör Limanı (AYT) | Kapsül yanaşma noktasını kaçırır | Yer değiştirmeler yönsüz toplanıyor | Aynı iki oku ters yönde ekle (**Gör**) | "Uzunluk toplandı. Yön silinmişti." |
| 3 | **Düşüş Odası (AYT)** | Aynı yükseklikten çelik küre 2,0 s, sünger top 4,3 s sürede iner. Cihaz ikisini de 2,0 s bekler | Odada hava yokmuş gibi hesaplanıyor | Havayı boşalt (**Ayır**): iki cisim birlikte iner | "Kütle değildi. Hava hesaptan çıkarılmıştı." |
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
