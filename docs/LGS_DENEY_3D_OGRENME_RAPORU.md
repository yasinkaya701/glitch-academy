# LGS — Deneyler, 3B Modeller ve Etkileşimli Öğrenme Raporu

**Proje:** Glitch Academy / Yanlış Dünya  
**Hedef:** 8. sınıf LGS rotası; ortaokul kazanımlarıyla yeniden kullanılabilir deney altyapısı  
**Tarih:** 13 Kasım 2026  
**Durum:** Ürün ve öğretim tasarımı önerisi — kodlanmış/oynanabilir içerik iddiası değildir.

> **Kapsam uyarısı:** Bu belge, MEB'in yayımladığı “zorunlu deneylerin eksiksiz resmî listesi” değildir. 8. sınıf Fen Bilimleri üniteleri üzerinden kurgulanmış **64 önerilen sanal deney, model veya uygulama** envanteridir. Bunların bir kısmı gerçek laboratuvar deneyinin dijital karşılığı, bir kısmı ise kavram modeli, veri incelemesi veya problem çözme görevidir. Kazanım kodu, program sürümü ve sınav kapsamı üretim öncesinde resmî MEB/TTKB kaynağına göre tek tek doğrulanmalıdır. 2026–2027 8. sınıf programı ile kademeli geçişteki yeni Maarif programı karıştırılmamalıdır.

## 1. Projeyle uyum: Bölge fethetme değil, bozulan dünyayı onarma

Glitch Academy'nin mevcut oyun döngüsü: **bozulan kuralın sonucunu göster → kavramı öğret → tahmin yaptır → deney yaptır → sonucu yorumlat → yeni durumda tek başına uygulat → istasyonu onar**. Bu rapordaki hiçbir deney salt 3B animasyon izlemekle bitmemeli. Öğrencinin kullandığı fiziksel veya matematiksel ilişki, simülasyonun davranışını gerçekten belirlemeli.

Mevcut repo ile temas noktaları:

- **Mevsim Gözlemevi:** stations/seasons/ ve mevcut ilk görev tasarımı.
- **Basınç İstasyonu:** stations/pressure/; sıvı basıncı ve değişken kontrolü öncelikli.
- **Gösterge Laboratuvarı:** stations/indicator/; asit-baz ayıraçları.
- **Köprü Atölyesi:** stations/bridge/; Pisagor ve LGS üçgenleri.
- **Prizma Deposu:** stations/prism/; mevcut kapsamda 7. sınıf keşfi, LGS katı cisim etkinlikleri ayrı kazanım eşlemesiyle paylaşılabilir.
- **3B altyapı:** scenes/experiment_3d.tscn; model 3B, ölçüm/etiket/grafik tercihen okunaklı 2B.

Her istasyon için önerilen veri alanları: **route=lgs, grade=8, program_surumu, unit, kazanım_kodu (doğrulanınca), bilimsel varsayım, bağımsız/değişen/sabit tutulan değişken, gözlenen sonuç, kavram yanılgısı, bağımsız uygulama sorusu, kaynak, kabul testleri**. YKS istasyonlarıyla ortak motor paylaşılabilir; LGS düzeyi formül ve görevleri ayrı tutulur.

### Uygulama biçimi kodları

| Kod | Biçim | Kullanılacak durum |
|---|---|---|
| 3B | Döndürülebilir/yerleştirilebilir model | DNA, Dünya, makara, baraj, makineler, açınım |
| 2B | Grafik, koordinat, tablo, şema | Çaprazlama, doğrusal grafik, Punnett karesi, enerji piramidi |
| H | Hibrit 3B + 2B | Basınç sensörü, hâl değişimi, deney + grafik |
| S | Simülasyon/karar akışı | Ekosistem, hava tahmini, enerji yönetimi |

## 2. LGS Fen Bilimleri — 64 etkinlik envanteri

### Ünite 1 — Mevsimler ve İklim (1–6)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 1 | Dünya'nın eksen eğikliği | Ekseni eğ, yörüngedeki konumu değiştir; yarım kürelerin ışık alışını karşılaştır | 3B |
| 2 | Mevsimler | 21 Mart/21 Haziran/23 Eylül/21 Aralık konumlarını karşılaştır; karşıt yarım küre mevsimlerini açıklat | 3B |
| 3 | Işığın geliş açısı | Işık açısını değiştir; eşit enerjinin yayıldığı alanı gözlemle | H |
| 4 | Gündüz ve gece süresi | Enlem ve tarih seç; gündüz süresini karşılaştır | H |
| 5 | Hava hareketleri | Sıcaklık ve hava basıncı alanlarını yorumlayarak rüzgâr yönü tahmin et | S |
| 6 | Hava durumu ve iklim | Günlük hava grafiğini uzun dönem ortalama ile karşılaştır; doğru çıkarımı seç | 2B |

**Yanlış Dünya görevi:** Mevsim Gözlemevi, Dünya'nın eksenini yanlış yönlendiriyor. Oyuncu önce kuzey-güney yarım kürede beklenen mevsimleri tahmin eder, sonra modeli düzeltir. **Yanılgı kontrolü:** Mevsimlerin temel nedeni Güneş'e uzaklık değildir. Dünya ekseni, yörüngedeki konum ve ışığın geliş açısı birlikte gösterilmelidir.

### Ünite 2 — DNA ve Genetik Kod (7–15)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 7 | DNA çift sarmalı | Nükleotidleri yerleştir; A–T ve G–C tamamlayıcılığını uygula | 3B |
| 8 | DNA eşlenmesi | Ayrılan zincirlere uygun nükleotidleri ekle ve iki DNA'yı tamamla | H |
| 9 | Hücre–çekirdek–kromozom–DNA–gen | Yakınlaştırılabilir iç içe yapıları doğru büyüklük ve konum ilişkisiyle incele | 3B |
| 10 | Monohibrit çaprazlama | Ebeveyn genotiplerini seç, Punnett karesini doldur, olasılıkları yorumla | 2B |
| 11 | Genotip ve fenotip | Baskın/çekinik alelleri ve çevresel koşulları ayırt ederek örnekleri sınıflandır | 2B |
| 12 | Cinsiyetin kromozomal belirlenmesi | X/Y aktarım olasılıklarını modelle; her doğumun ayrı olay olduğunu tartış | 2B |
| 13 | Mutasyon ve modifikasyon | DNA dizisindeki değişimi çevrenin fenotip etkisinden ayır | H |
| 14 | Adaptasyon | Kalıtsal varyasyonların farklı ortamlarda nesiller boyunca nasıl seçildiğini gör | S |
| 15 | Biyoteknoloji | Islah, gen aktarımı, klonlama örneklerini amaç, yarar ve etik boyutlarıyla eşleştir | H |

**Yanlış Dünya görevi:** DNA istasyonu yanlış eşleşme yüzünden veriyi kopyalayamıyor. Oyuncu sarmalı tamir eder; ayrı bir bölümde bezelyelerin olası yavrularını hesaplar. **Yanılgı kontrolü:** Modifikasyon doğrudan DNA dizisini değiştirmez; tek bir bireyin yaşamı boyunca kazandığı özellikleri otomatik olarak adaptasyon gibi sunma. DNA eşlenmesinde molekülün gerçeğe uygun şematik sadeleştirmesi belirtilebilir.

### Ünite 3 — Basınç (16–23)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 16 | Katı basıncı | Aynı yüzeyde ağırlığı, aynı ağırlıkta temas alanını değiştir | H |
| 17 | Çivili yüzey | Çivi sayısını değiştir; ağırlığın temas noktalarına dağılımını karşılaştır | 3B |
| 18 | Sıvı derinliği | Aynı sıvıda farklı derinlikteki sensörleri karşılaştır | H |
| 19 | Sıvı yoğunluğu | Aynı derinlikte sıvı türünü değiştir; basınç göstergesini oku | H |
| 20 | Kap şekli ve sıvı basıncı | Farklı biçimli kaplarda eşit derinlikleri karşılaştır | 3B |
| 21 | Hidrolik düzenek | Bağlı pistonları ve kuvvet iletimini görselleştir; nitel çözüm yap | 3B |
| 22 | Açık hava basıncı | Atmosfer basıncını gösteren güvenli sanal örnekleri incele | H |
| 23 | Basıncın uygulamaları | Baraj, kar ayakkabısı, bıçak, enjektör ve fren tasarımlarını eşleştir | S |

**Yanlış Dünya görevi:** Barajda basınç sensörleri ters okuyor. Oyuncu önce tahmin yapar, sadece bir bağımsız değişkeni değiştirerek ölçer, ardından güçlendirilmesi gereken seviyeyi seçer. **Yanılgı kontrolü:** Eşit derinlik ve eşit yoğunlukta kabın şekli sıvı basıncını tek başına değiştirmez. Gaz basıncı ve hidrolik ayrıntıların hesaplama seviyesi LGS kazanım sınırını aşmamalı.

### Ünite 4 — Madde ve Endüstri (24–35)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 24 | Periyodik sistem | Element kartlarını metal/yarımetal/ametal/soygaz olarak sınıflandır | 2B |
| 25 | Fiziksel değişim | Erime, kırılma, çözünme örneklerinde madde kimliğini tartış | H |
| 26 | Kimyasal değişim | Tepkime öncesi-sonrası gözlemleri karşılaştır; yeni madde oluşumunu sorgula | H |
| 27 | Taneciklerle tepkime | Atomların korunup yeniden düzenlenmesini tanecik modeliyle göster | 3B |
| 28 | Asit–baz ayıracı | Kırmızı lahana suyu gibi ayıraçlarla sanal maddeleri test et | H |
| 29 | pH laboratuvarı | Maddeleri asit/baz/nötr olarak sınıflandır; gösterge sonucunu yorumla | H |
| 30 | Asitlerin maddeye etkisi | Uygun malzemelerdeki etkileri sanal deneylerle karşılaştır | H |
| 31 | Asit yağmuru | Malzemeler ve doğal çevre üzerindeki etkiyi zaman içinde incele | S |
| 32 | Isı alışverişi ve kütle | Aynı maddeye eşit enerji aktarırken kütleyi değiştir | H |
| 33 | Öz ısı karşılaştırması | Aynı kütle/aynı enerjiyle farklı maddelerin sıcaklık değişimini karşılaştır | H |
| 34 | Hâl değişimi grafiği | Isı ver/al; sıcaklık-zaman grafiğinde hâl değişimi aralıklarını yorumla | H |
| 35 | Kimya endüstrisi | Üretim sürecinde uygun madde, güvenlik ve çevre kararları ver | S |

**Yanlış Dünya görevi:** Gösterge Laboratuvarı bilinmeyen sıvıları yanlış hatta gönderiyor. Oyuncu ayıraçla ölçer, sınıflandırır, doğru vanayı onarır. **Güvenlik:** Gerçek hayatta ev kimyasallarını karıştırmayı öneren talimat verilmez. Asit-baz renkleri kullanılan ayıraca ve pH'a göre doğru gösterilir. Isı/sıcaklık eş anlamlı değildir; hâl değişimi grafiği saf madde ve uygun koşul varsayımını belirtir.

### Ünite 5 — Basit Makineler (36–43)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 36 | Sabit makara | İpin çekilme yönünü değiştir; kuvvetin yönündeki değişimi gör | 3B |
| 37 | Hareketli makara | Yükün yükselme miktarı ile çekilen ip uzunluğunu karşılaştır | 3B |
| 38 | Palanga | Makara/taşıyıcı ip kolu sayısını değiştir, kuvvet-yol ilişkisini gözlemle | 3B |
| 39 | Kaldıraç | Destek, yük ve kuvvet uygulama noktalarını yer değiştirerek dengeyi kur | 3B |
| 40 | Eğik düzlem | Aynı yüksekliğe ulaşırken rampa uzunluğunu değiştir; gerekli kuvvet ve yolu karşılaştır | 3B |
| 41 | Çıkrık | Kol ve tambur yarıçaplarını değiştir; kuvvet avantajını gözle | 3B |
| 42 | Dişli/vida/çark | Farklı basit makine düzeneklerinde hareketin yönünü ve işlevini gözlemle | 3B |
| 43 | Birleşik makine tasarımı | Vinçte kaldıraç, makara veya eğik düzlem seçerek hedef yükü kaldır | 3B |

**Yanlış Dünya görevi:** İnşaat vincinin makara düzeni bozuk. Oyuncu yükü kaldırmak için doğru düzeneği kurar. **Yanılgı kontrolü:** İdeal basit makineler işten ve enerjiden kazanç sağlamaz; kuvvet kazancı ile yol kaybı birlikte gösterilmeli. Sürtünme varsa verim ayrımı açık olmalı.

### Ünite 6 — Enerji Dönüşümleri ve Çevre Bilimi (44–54)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 44 | Besin zinciri | Üretici, tüketici ve ayrıştırıcıları uygun ilişkilerle bağla | 2B |
| 45 | Besin ağı | Bir popülasyonu değiştir; bağlı canlıların durumunu gözle ve açıkla | S |
| 46 | Ekoloji piramidi | Basamaklar boyunca enerji aktarımını ve azalmasını gör | 2B |
| 47 | Biyolojik birikim | Kirleticinin besin ağındaki dağılımını şematik olarak incele | H |
| 48 | Fotosentez değişkenleri | Işık, CO₂, su ve sıcaklık koşullarını tek tek değiştir; hızı nitel karşılaştır | H |
| 49 | Solunum | Canlıların enerji ihtiyacını fotosentezden ayıran örnekler incele | H |
| 50 | Su döngüsü | Buharlaşma, yoğunlaşma ve yağış süreçlerini çalıştır | 3B |
| 51 | Karbon ve oksijen döngüleri | Atmosfer, canlılar, yanma ve fotosentez arasındaki madde akışını izle | H |
| 52 | Azot döngüsü | Toprak, mikroorganizmalar ve canlılar arasındaki dönüşümleri eşleştir | H |
| 53 | Sera etkisi | Işınım giriş-çıkışı ile sıcaklık eğilimini kavramsal modelde incele | H |
| 54 | Geri dönüşüm ve sürdürülebilirlik | Atıkları ayrıştır, kaynak tüketimi ve enerji seçeneklerini karşılaştır | S |

**Yanlış Dünya görevi:** Ekosistem merkezi tek türün kaybolmasını önemsiz sayıyor. Oyuncu besin ağı üzerindeki etkileri izleyerek dengeyi onarır. **Yanılgı kontrolü:** Enerji döngü yapmaz, ekosistemde akar; madde döngüye katılır. Fotosentez hızı basit doğrusal ve sınırsız artış şeklinde modellenmemeli. Sera etkisi yalnızca “ısıyı kapatan cam kapak” analojisine indirgenmemeli.

### Ünite 7 — Elektrik Yükleri ve Elektrik Enerjisi (55–64)

| # | Deney / model | Öğrencinin kontrolü ve gözlemi | Biçim |
|---|---|---|---|
| 55 | Elektrik yükleri arası etkileşim | Aynı/zıt yükleri yaklaştır; itme-çekme yönünü tahmin et | 3B |
| 56 | Sürtünmeyle elektriklenme | Yalıtkan malzeme çiftlerinde yük aktarımını kavramsal olarak gör | H |
| 57 | Dokunmayla elektriklenme | Yüklü ve nötr iletkenleri temas ettir; son durumları karşılaştır | H |
| 58 | Etki ile elektriklenme | Yaklaştırılan yüklü cismin iletkendeki yük ayrışmasını modelle | H |
| 59 | Elektroskop | Farklı yüklü nesnelerle yaprakların durumunu yorumla | 3B |
| 60 | Topraklama | İletkenin yeryüzüyle yük alışverişini göster | H |
| 61 | Elektrik enerjisinin dönüşümü | Lamba, ısıtıcı ve motorun enerji dönüşümünü eşleştir | H |
| 62 | Jeneratör | Mekanik hareket ile elektrik üretiminin temel ilişkisini göster | 3B |
| 63 | Enerji santralleri | Hidroelektrik, rüzgâr, termik vb. üretim yollarını ve etkilerini karşılaştır | S |
| 64 | Enerji verimliliği | Ev/şehir tüketimini azaltan seçimleri yap; kWh verilerini yorumla | S |

**Yanlış Dünya görevi:** Enerji şehrindeki elektroskop yanlış işaret veriyor ve enerji kaynakları yanlış yönlendiriliyor. Oyuncu yüklerin etkileşimiyle problemi teşhis eder, sonra enerji dönüşümleri görevini tamamlar. **Yanılgı kontrolü:** Sürtünme yük yaratmaz, yüklerin aktarımını sağlar; toplam elektrik yükü korunur. “Nötr” kavramını “yük içermiyor” diye anlatma.

## 3. LGS Matematik — doğru yerde 3B, diğer yerde dinamik 2B

Matematikte “deney” çoğu zaman parametreyi değiştirip bir bağıntıyı sınamadır; 3B kullanımının kendisi öğrenme çıktısı değildir.

| Konu | Etkileşim / model | Uygun biçim | Öncelik |
|---|---|---|---|
| Çarpanlar ve katlar | Alanı artıksız karolarla kaplama; ortak tekrar çevrimi | 2B | P1 |
| Üslü ifadeler | Çarpılarak büyüme, ölçek karşılaştırması, bilimsel gösterim | 2B | P1 |
| Kareköklü ifadeler | Kare alanından kenar elde et; sayı doğrusunda kök uzunluğunu konumlandır | 2B | P0 |
| Veri analizi | Tabloya dayalı sütun/çizgi/daire grafik oluşturma ve yorumlama | 2B | P1 |
| Basit olayların olasılığı | Torba/zar/çark tekrarları; deneysel frekans ile teorik olasılığı karşılaştır | 2B+isteğe bağlı 3B | P1 |
| Cebirsel ifadeler ve özdeşlikler | Kare/dikdörtgen parçalarıyla (a+b)² ve farkların karesi | 2B | P0 |
| Doğrusal denklemler | Eğim ve sabiti değiştir; grafikte doğruyu canlı taşı | 2B | P0 |
| Eşitsizlikler | Sınır değer ve açık/kapalı uçlarla güvenli bölge seç | 2B | P1 |
| Üçgenler ve Pisagor | Köprü dik kenarlarını sürükle; kenar karelerinin alanını karşılaştır | H | P0 |
| Eşlik ve benzerlik | Ölçekli iki köprüyü/haritayı karşılaştır; uzunluk oranı bul | H | P0 |
| Dönüşüm geometrisi | Koordinat düzleminde yansıma ve ötelemeyi uygula | 2B | P1 |
| Geometrik cisimler | Prizma, silindir, piramit, koni modellerini döndür; açınım/kesit ve yüzey alanı ilişkisini incele | 3B | P0 |

### Matematik için örnek onarım görevleri

1. **Köprü Atölyesi:** 6–8–10 köprüsünde kenar karelerini karşılaştır, ardından 9 ve 12 birim dik kenardan 15 birim kiriş seç. Önce gör, sonra yeni uzunlukları bağımsız hesapla.
2. **Prizma Deposu:** Kutu açınımını doğru katla; taban/yan yüzleri eşleştir. 7. sınıf hacim ile 8. sınıf geometrik cisim kazanımları ayrı rotada filtrelenmeli.
3. **Özdeşlik Atölyesi:** Parçalanan kare platformu (a+b)² = a²+2ab+b² düzeniyle yeniden birleştir.
4. **Koordinat Kontrolü:** Grafik eğimini değiştirerek yanlış yönlendirilen aracı hedefe ulaştır; x-y eksenlerini ve birimleri belirt.

## 4. Diğer LGS dersleri: 3B gösteri yerine anlamlı etkileşim

| Ders | Önerilen görev | Uygun teknik | Temel öğrenme çıktısı |
|---|---|---|---|
| T.C. İnkılap Tarihi ve Atatürkçülük | Tarihli belgelerden olay sıralaması kur; haritada cepheleri ve neden-sonuç bağlarını doğrula | 2B harita + zaman çizelgesi | Kanıtla kronoloji kurma |
| Türkçe | Paragrafta iddia, dayanak, çıkarım ve çeldiriciyi işaretle; metni yeniden sırala | 2B metin etkileşimi | Okuduğunu anlama ve yorum |
| İngilizce | Günlük yaşam diyaloglarında doğru yanıt ve yönerge seç; dinleme-görsel eşleştirme | Karakter + 2B diyalog | Bağlamda dil kullanımı |
| Din Kültürü ve Ahlak Bilgisi | Kavramları örnek olaylarla eşleştir; bağlama dayalı yorumlama görevleri | 2B senaryo | Kavramı gerçek bağlama uygulama |

Bu alanlardaki içerikler sınıf/sınav bazında ayrıca resmî kazanımlara bağlanmalı; tarihsel belge ile kurgusal “arıza” sahnesi açık biçimde ayrılmalı.

## 5. Bir deneyin oynanış sözleşmesi

**Açılış (atlanabilir):** Bozulmuş fizik/kimya/biyoloji kuralının etkisi somut olarak görülür.  
**Keşif:** Terimler ve model parçaları tek tek tanıtılır; gerekiyorsa kısa yönlendirme.  
**Tahmin:** Öğrenci bir sonraki gözlemi işaretler veya miktarı girer.  
**Kontrollü deney:** Aynı anda tek bağımsız değişkeni değiştirir; ölçüm, birim ve grafik güncellenir.  
**Açıklama:** Hangi sebebin sonucu değiştirdiğini kendi seçimiyle ifade eder.  
**Transfer:** Deneydeki sayıların aynısıyla değil, **yeni koşullardaki** LGS tipi soruyla test edilir.  
**Onarım:** Doğru bilimsel ilişki dünya düzenine uygulanır; hata yapan öğrenci açıklama görüp yeniden dener.

**Ölçülebilir başarı:** Ön tahmin doğruluğu, bağımsız soruda doğruluk, yanlış anlama türü, tekrar denemesi ve bilgiyi yeni probleme transfer. Görselin ne kadar “etkileyici” olduğu tek başına başarı sayılmaz.

**Arayüz kalitesi:** Metrik sayılar, ölçüm birimleri ve grafikler yüksek kontrastlı 2B panelde okunur. Sadece renkle anlam taşıma; ok, etiket, titreşim/animasyon da kullan. Görev F6 ile ayrı, F5 ile merkezden açılabilmeli. Yanlış/doğru/yeniden dene/merkeze dön akışları doğrulanmalı.

## 6. P0 / P1 / P2 geliştirme sırası

| Öncelik | İstasyon / prototip | Gerekçe | Çalışan kabul ölçütü |
|---|---|---|---|
| P0 | Mevsim Gözlemevi | Reponun ilk LGS görevi, güçlü 3B gerekçe | Eksen/yörünge değişince ışık ve yarım küre açıklaması tutarlı |
| P0 | Basınç İstasyonu | Kontrollü deney + neden-sonuç doğrudan gözlenebilir | Derinlik/yoğunluk tek tek değişir, sensör ve bağımsız soru aynı kurala uyar |
| P0 | Gösterge Laboratuvarı | Mevcut istasyon klasörü ve belirgin sınıflandırma görevi | Ayıraç sonucu doğru, numune doğru hatta yönlenir |
| P0 | Köprü Atölyesi | Matematik ile 3B modeli dengeler | 6–8–10 keşfi ve 9–12–15 bağımsız uygulaması çalışır |
| P1 | DNA onarım laboratuvarı | 3B yapı + 2B çaprazlama | Eşleşme hatası tanınır, yeni çaprazlama ayrı test edilir |
| P1 | Basit makineler/vinç | 3B mekanik doğrudan öğretime katkılı | Kuvvet-yol değişimi ve iş korunumu doğru |
| P1 | Geometrik cisimler/açınım | Gerçek uzamsal anlama gerektirir | Modelin ağını aç-kapa, yüzeyleri doğru eşleştir |
| P2 | Ekosistem yönetimi | Birden çok bağlı etkileşim, hata ayıklama maliyetli | Bir popülasyon değişiminin neden-sonuç zinciri açıklanır |
| P2 | Elektriklenme ve santral | Birden fazla ayrı bilimsel sistem | Yük korunumu ve enerji dönüşümüne uygun durumlar |

**Hackathon kapsam önerisi:** Her etkinliğe sahte bir buton koymak yerine mevcut P0 istasyonlarından 2–4 tanesini uçtan uca oynanabilir tamamla. Diğer 64 fikir katalog olarak kalabilir. Gerçek uygulama sayısı, bağlı sahneler ve test sonuçları üzerinden raporlanmalı; taslakları “tamamlandı” sayma.

## 7. Ortak teknik/öğretimsel kabul ölçütleri

- Deney çıktısı rastgele animasyon değil, varsayılan kurala/ölçüme bağlıdır.
- Kontrol edilen ve bağımsız değişkenler ayrılmıştır; ölçüm birimi açık yazılır.
- 3B kameranın kayması veya sürükle-bırak performansı bilimsel ilişkiyi bozmaz.
- LGS düzeyinde olmayan ileri formül varsa “ek keşif” etiketi kullanılır; zorunlu uygulama sorusuna sızmaz.
- Model varsayımları yazılır (ideal makine, saf madde, seçilen genetik model, sabit yerçekimi vb.).
- Düzgün yeniden başlatma ve sahne temizleme sağlanır; görev kontrol merkezinin rota filtresini bozmadan çalışır.
- Renk körlüğü ve farklı ekran boyutu için kritik sonuçlar rakam, sembol veya yazıyla da sunulur.
- Öğretmen/öğrenci için veri korunumu: öğrenme metrikleri toplanacaksa kişisel veriler ve izinler ayrıca tasarlanır.

## 8. Resmî kaynaklara bağlama ve doğrulama listesi

Önceden repoda kullanılan başvuru noktaları:

- [MEB 8. sınıf Fen Bilimleri ünite örnek soruları](https://odsgm.meb.gov.tr/www/8-sinif-fen-bilimleri-unitelendirilmis-ornek-sorular/icerik/676)
- [MEB 8. sınıf Matematik ünite örnek soruları](https://odsgm.meb.gov.tr/www/8-sinif-matematik-unitelendirilmis-ornek-sorular/icerik/677)
- [MEB 8. sınıf sıvı basıncı destek materyali](https://odsgm.meb.gov.tr/destekmateryal/pdf/8kt/fen/3.pdf)
- [Türkiye Yüzyılı Maarif Modeli — 8. sınıf Fen](https://tymm.meb.gov.tr/ogretim-programlari/fen-bilimleri-dersi/9)
- [Türkiye Yüzyılı Maarif Modeli — Ortaokul Matematik programı](https://tymm.meb.gov.tr/upload/program/2024programmat5678Onayli.pdf)
- Repodaki [CURRICULUM.md](CURRICULUM.md), [PLAN.md](PLAN.md), [AGENTS.md](../AGENTS.md) ve [FIRST_MISSIONS.md](FIRST_MISSIONS.md).

**Doğrulama işi, içerik geliştirme başlamadan önce:** (1) uygulama yılındaki resmî 8. sınıf Fen/Matematik öğretim programını indir, (2) her tablo satırını gerçek kazanım koduyla eşleştir ya da “müfredat üstü” olarak işaretle, (3) soru tarzını MEB'in resmî örnekleriyle karşılaştır, (4) etkinlik gerçekten deney mi, model mi, yoksa uygulama görevi mi metadata alanına yaz. Bu yapılmadan “64 resmî LGS deneyi” başlığı kullanma.

---

**Sonuç:** En yüksek öğrenme kazanımı, yalnızca görselleştirme değil; öğrencinin **tahmin etmesi, değişkeni kontrol etmesi, sonucu gerekçelendirmesi ve yeni problemi çözmesidir**. Glitch Academy'de 3B modeller bu öğrenme döngüsüne hizmet etmeli, onun yerini almamalıdır.
