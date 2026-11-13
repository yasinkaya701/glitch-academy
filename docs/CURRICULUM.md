# Müfredat haritası ve deney havuzu

Ürünün asıl kapsamı: ortaokuldan liseye, LGS ve YKS rotalarında müfredatın her konusunu bir deneyle öğretmek. Bu dosya, deney üretiminin tek sırası. Her konu bir "Yanlış Dünya" arızası ve onarım görevi olur.

**Kaynaklar.** TYT ve Sayısal AYT konu listeleri okundu: [TYT 2022](https://aksaraysbl.meb.k12.tr/meb_iys_dosyalar/68/01/973040/dosyalar/2022_03/07093256_2022-TYT-Konulari.pdf), [AYT Sayısal 2022](https://sehitcancalskanmtal.meb.k12.tr/meb_iys_dosyalar/06/21/761800/dosyalar/2021_11/01205648_2022-AYT-Sayisal-konulari.pdf). İkisi 2022 listesi. Güncel TTKB 2026 listesiyle her görev uygulanmadan önce teyit edilir. LGS 8. sınıf listesi ve 5–12. sınıf kataloğu henüz MEB programından satır satır okunmadı, aşağıdaki LGS bölümü bu yüzden **teyit bekliyor**.

**Soru ağırlıkları (öncelik için).** TYT: Türkçe 40, Mat+Geo 40, Sosyal 20, Fen 20 (Fizik 7, Kimya 7, Biyoloji 6). AYT Sayısal: Matematik+Geometri 40, Fizik 14, Kimya 13, Biyoloji 13.

## Ortak mekanik şablonları

Her deney bu şablonlardan birini kullanır. Böylece tasarım ve kod tekrar kullanılır, ruh bozulmaz.

| Kod | Şablon | Oyuncu ne yapar |
|---|---|---|
| H | Ölç → hesapla → gir | Ölçümden değer bulur, düzeneğe girer, simülasyon doğrular |
| Y | Yol kur | Parçaları sıraya veya yola dizer (dolaşım, sinir yolu) |
| P | Parça yerleştir | Doğru parçayı doğru yere koyar (kapakçık, devre, organik molekül) |
| K | Kaydırıcı keşfi | Değişkeni değiştirir, grafik ve şekil birlikte hareket eder |
| S | Sınıflandır / yönlendir | Numuneyi veya olayı doğru kanala gönderir |
| T | Tahmin et | Sonucu önceden tahmin eder, deney çürütür veya doğrular |
| D | Dengele | Kuvvet, tepkime veya popülasyonu dengeye getirir |

## FİZİK

TYT Fizik (7 soru) ve AYT Fizik (14 soru). Ağır konular önce.

| Rota | Konu | Arıza ve görev | Şablon | Öncelik |
|---|---|---|---|---|
| TYT | Fizik Bilimine Giriş | Birim karışıklığı, parça sığmıyor (Ölçüm Atölyesi, var) | H | A |
| TYT | Madde ve Özellikleri | Yoğunluk karışımı, gemi su çekimi | K | B |
| TYT | Kuvvet ve Hareket | Hız-zaman grafiği, asansör hareketi | K | A |
| TYT | İş, Güç ve Enerji | Roller coaster enerji korunumu | H | A |
| TYT | Isı, Sıcaklık, Genleşme | Ray ve köprü genleşmesi | H | B |
| TYT | Basınç | Hidrolik pres, sıvı basıncı (LGS ile ortak) | H | A |
| TYT | Kaldırma Kuvveti | Yüzen platformu dengede tut | D | A |
| TYT | Elektrik ve Manyetizma | Devre kur, akım ve direnç | P | A |
| TYT | Dalgalar | Dalga tankı, yay ve su dalgası | K | B |
| TYT | Optik | Ayna ve mercekle ışını hedefe ulaştır | H | A |
| AYT | 1 Vektörler | Vektör Limanı (var, yenileniyor) | H | A |
| AYT | 2 Kuvvet, Tork, Denge | Vinci dengele | D | A |
| AYT | 3 Kütle Merkezi | Asılı yükü dengede tut | D | B |
| AYT | 4 Basit Makineler | Makara, kaldıraç, eğik düzlem ile yük kaldır | H | B |
| AYT | 5 Hareket | Serbest düşüş, hız-konum grafiği (Düşüş Odası) | H | A |
| AYT | 6 Newton'un Yasaları | Kızak ve roket: F = m·a | H | A |
| AYT | 7 İş, Güç, Enerji II | Sürtünmeli yolda enerji kaybı | H | B |
| AYT | 8 Atışlar | Topu hedefe at | H | A |
| AYT | 9 İtme ve Momentum | Çarpışma sonucunu önceden bul | T | A |
| AYT | 10 Elektrik Alan, Potansiyel | Yüklü parçacığı hedefe yönlendir | H | B |
| AYT | 11 Paralel Levha, Sığa | Kondansatörü doldur | K | C |
| AYT | 12 Manyetik Alan, Kuvvet | Parçacık hızlandırıcı yörüngesi | H | A |
| AYT | 13 İndüksiyon, Alternatif Akım, Trafo | Jeneratör ve trafo ile şehir ışığı | H | B |
| AYT | 14 Çembersel Hareket | Viraj ve döner platform | H | B |
| AYT | 15 Kütle Çekim, Kepler | Uydu yörüngesi | H | A |
| AYT | 16 Basit Harmonik Hareket | Sarkaç ve yay saati | K | B |
| AYT | 17 Dalga Mekaniği, EM Dalgalar | Girişim, kırınım | K | B |
| AYT | 18 Atom Modelleri | Rutherford saçılması | T | B |
| AYT | 19 Büyük Patlama, Radyoaktivite | Yarı ömür | K | B |
| AYT | 20 Modern Fizik | Fotoelektrik olay | K | B |
| AYT | 21 Modern Fizik Uygulamaları | Yarı iletken, lazer, MR | S | C |

## KİMYA

TYT Kimya (7 soru) ve AYT Kimya (13 soru).

| Rota | Konu | Arıza ve görev | Şablon | Öncelik |
|---|---|---|---|---|
| TYT | 1 Kimya Bilimi | Laboratuvar güvenliği, birimler | S | C |
| TYT | 2 Atom ve Periyodik Sistem | Elementi özelliğinden bul | P | A |
| TYT | 3 Kimyasal Türler Arası Etkileşim | Bağ türü seç: iyonik, kovalent, metalik | S | A |
| TYT | 4 Maddenin Halleri | Hâl değişimi grafiği | K | B |
| TYT | 5 Doğa ve Kimya | Su, hava, kirlilik | S | C |
| TYT | 6 Temel Kanunlar, Hesaplamalar | Kütle korunumu, mol hesabı | H | A |
| TYT | 7 Karışımlar | Ayırma yöntemi seç | S | B |
| TYT | 8 Asitler, Bazlar, Tuzlar | Gösterge Laboratuvarı, pH | S | A |
| TYT | 9 Kimya Her Yerde | Sabun, deterjan, ilaç | S | C |
| AYT | 1 Modern Atom Teorisi | Kuantum sayıları ve **spin: Stern–Gerlach gösterisi** | T | A |
| AYT | 2 Gazlar | Piston ile P, V, T | K | A |
| AYT | 3 Sıvı Çözeltiler, Çözünürlük | Hedef molarite, doygunluk | H | A |
| AYT | 4 Tepkimelerde Enerji | Kalorimetre, entalpi | H | B |
| AYT | 5 Hız ve Denge | Derişim ve sıcaklıkla denge (Le Chatelier) | D | A |
| AYT | 6 Kimya ve Elektrik | Pil ve elektroliz | P | B |
| AYT | 7 Karbon Kimyası | Hibritleşme, izomeri | P | B |
| AYT | 8 Organik Kimya | Fonksiyonel grup, molekül kur | P | B |
| AYT | 9 Enerji Kaynakları | Yakıt seçimi, çevre etkisi | S | C |

## BİYOLOJİ

TYT Biyoloji (6 soru) ve AYT Biyoloji (13 soru). Gerçekçi 3D/katmanlı anatomi, Gemini ve Codex ile varlık üretilir.

| Rota | Konu | Arıza ve görev | Şablon | Öncelik |
|---|---|---|---|---|
| TYT | 1 Yaşam Bilimi | Canlı özellikleri, sınıflandırma | S | C |
| TYT | 2 Hücre | Organelleri yerleştir, zardan taşınım | P | A |
| TYT | 3 Canlılar Dünyası | Sınıflandırma anahtarı | S | B |
| TYT | 4 Hücre Bölünmeleri, Üreme | Mitoz ve mayoz evreleri | Y | A |
| TYT | 5 Kalıtımın Genel İlkeleri | Çaprazlama, Punnett | T | A |
| TYT | 6 Ekosistem ve Çevre | Besin zinciri ve enerji akışı | D | B |
| AYT | 1 Sinir Sistemi | Refleks yayı, impuls, sinaps (Refleks Merkezi) | Y | A |
| AYT | 2 Endokrin Sistem | Hormon geri bildirimi | D | A |
| AYT | 3 Duyu Organları | Göz, kulak yolları | Y | B |
| AYT | 4 Destek ve Hareket | Kas kasılması, eklem | P | B |
| AYT | 5 Sindirim | Enzim ve organ eşleştirme | Y | B |
| AYT | 6 Dolaşım ve Bağışıklık | **Kalp Odası** (HEART.md), bağışıklık yanıtı | Y | A |
| AYT | 7 Solunum | Alveolde gaz alışverişi | K | A |
| AYT | 8 Üriner Sistem | Nefronda süzülme, geri emilim | Y | A |
| AYT | 9 Üreme ve Embriyonik Gelişim | Gametogenez, gelişim evreleri | Y | B |
| AYT | 10 Komünite, Popülasyon | Popülasyon dengesi | D | B |
| AYT | 11 Nükleik Asitler | DNA eşleme, replikasyon | P | A |
| AYT | 12 Genetik Şifre, Protein Sentezi | Transkripsiyon, translasyon | Y | A |
| AYT | 13 Canlılık ve Enerji | ATP, enzim | K | B |
| AYT | 14 Fotosentez, Kemosentez | Işık ve CO₂ ile verim | K | A |
| AYT | 15 Hücresel Solunum | Glikoliz, Krebs, ETS | Y | B |
| AYT | 16 Bitki Biyolojisi | Taşıma dokuları, stoma | K | C |
| AYT | 17 Canlılar ve Çevre | Madde döngüleri | D | C |

## MATEMATİK VE GEOMETRİ

TYT (Matematik 25 başlık, Geometri 21) ve AYT (Matematik 31, Geometri 27). Üç ana AYT kavramı hepsi yapılacak: **türev, integral, limit**. "O olmasa ne yapamazdık" cümlesi her deneyin açılış sorusu.

| Kavram | Oyun fikri | Olmasa ne yapamazdık | Şablon | Öncelik |
|---|---|---|---|---|
| Türev (AYT 30) | Levhadan en büyük hacimli kutu (EXPERIMENTS.md) | Sınır içinde en iyi değeri bulamazdık | K | A |
| İntegral (AYT 31) | Değişen debiyle dolan havuz, alan = toplam birikim | Değişen miktarın toplamını bilemezdik | K | A |
| Limit (AYT 29) | Köprüde boşluğa yaklaşan araç, sınır değer | Süreksiz yerde sonucu bilemezdik | K | B |
| Fonksiyonlar, parabol | Su fıskiyesi yörüngesi, tepe noktası | Yörüngeyi önceden bilemezdik | H | A |
| Trigonometri | Gölgeden yükseklik, dalga | Erişilemeyen mesafeyi ölçemezdik | H | A |
| Logaritma, diziler | Büyüme, bileşik artış | Üstel büyümeyi anlayamazdık | K | B |
| Permütasyon, olasılık, binom, istatistik | Şans düzeneği, veri analizi | Belirsizliği ölçemezdik | T | B |
| Polinomlar, denklemler, eşitsizlikler | Köprü yük aralığı | Güvenli aralığı bilemezdik | H | B |
| Mantık, kümeler | Kapı kilidi mantığı | Karar zincirini kuramazdık | S | C |
| Özdeşlikler ve cebirsel ifadeler | İspat Laboratuvarı: (a+b)² alan modeli | Bir ifadenin neden her durumda eşit kaldığını gösteremezdik | K | A |
| Çember, daire, açılar | Dişli ve çark | | H | B |
| Katı cisimler (prizma, piramit, silindir, koni, küre) | Prizma Deposu, depo hacmi | Kapasiteyi bilemezdik | H | A |
| Analitik geometri (doğru, çember) | Rota ve yörünge | | H | A |
| Dönüşümler, tekrar eden şekiller | Harita yansıması, döşeme | | P | B |
| Temel konular (sayılar, bölünebilme, EBOB-EKOK, oran) | Dişli, zamanlama, karışım | | H | C |

## Sosyal ve dil (son aşama)

Felsefe (8 başlık), Tarih (21), Coğrafya (17), Din (7), Türkçe (17): fikirleri diyalogla yeniden inandırma (felsefe), bozulan olay zincirini kaynakla düzeltme (tarih). Bilim deneyleri bittikten sonra planlanır, [PLAN.md](PLAN.md) bunu zaten son öncelik olarak yazıyor.

## LGS

**İki program var.** Oyun her görevin hangi programa ait olduğunu `program_surumu` alanında tutar.

- **Eski program (2018):** 2026–2027'de 8. sınıfta okutulan program. 2027 LGS buna dayanır. Bu listeyi ikincil kaynaklar ([Milliyet](https://www.milliyet.com.tr/egitim/8-sinif-fen-bilimleri-konulari-1-donem-ve-2-donem-8-sinif-fen-bilimleri-mufredati-2025-2026-6613626), [Bilgenç](https://www.bilgenc.com/8-sinif-fen-bilimleri-konulari/)) veriyor, MEB'in resmi PDF'iyle kazanım kodları teyit edilecek.
- **Maarif programı:** [MEB TYMM 8. sınıf Fen](https://tymm.meb.gov.tr/ogretim-programlari/fen-bilimleri-dersi/9) ve [8. sınıf Matematik](https://tymm.meb.gov.tr/ogretim-programlari/ortaokul-matematik-dersi/9). Maarif geçişi kademeli ilerliyor (2026–2027'de 7. ve 11. sınıf yeni programda, bu repodaki 11. sınıf notuyla tutarlı). 8. sınıfın yeni programa geçiş yılını ve LGS'ye etkisini MEB duyurusundan teyit etmem gerekiyor, şu an tahmin olarak 2027–2028 görünüyor.

İkincil kaynaklar soru dağılımlarında birbirini tutmuyor, bu yüzden hangi ünitenin kaç soru getirdiğini resmî veri olarak kullanmıyorum. DNA ve Genetik Kod, Basınç ve Enerji Dönüşümleri birden çok kaynakta sürekli en çok soru çıkan üniteler.

### LGS Fen · eski program (7 ünite)

| Ünite | Alt konular | Oyun fikri | Şablon | Öncelik |
|---|---|---|---|---|
| 1 Mevsimler ve İklim | Mevsimlerin oluşumu, iklim ve hava hareketleri | Mevsim Gözlemevi (var), basınç farkı ve rüzgâr | K | A |
| 2 DNA ve Genetik Kod | DNA, kalıtım, mutasyon ve modifikasyon, adaptasyon, biyoteknoloji | DNA sarmalını kur, çaprazlama, mutasyonun etkisi | P | A |
| 3 Basınç | Katı, sıvı, gaz basıncı | Basınç İstasyonu | H | A |
| 4 Madde ve Endüstri | Periyodik sistem, fiziksel ve kimyasal değişim, tepkime, asit–baz, ısı etkileşimi, kimya endüstrisi | Gösterge Laboratuvarı, denklem denkleştirme, erime ve kaynama grafiği | S | A |
| 5 Basit Makineler | Kaldıraç, makara, eğik düzlem | **Palanga Atölyesi:** gerçekçi 3B sabit ve hareketli makara; MERİDYEN ip ve yük ivmelerini ters gösterir, oyuncu ilişkiyi düzeltir | H | B |
| 6 Enerji Dönüşümleri ve Çevre | Enerji dönüşümü, çevre | Santral zinciri | Y | B |
| 7 Elektrik Yükleri ve Enerjisi | Elektriklenme, devre | Yük aktar, devre kur | P | B |

### LGS Matematik · eski program

| Konu | Oyun fikri | Şablon | Öncelik |
|---|---|---|---|
| Çarpanlar ve katlar | Dişli ve zamanlama | H | C |
| Üslü ifadeler, kareköklü ifadeler | Büyüklük ölçeği, alan ve kenar | K | A |
| Veri analizi, olasılık | Şans düzeneği, grafik yorumu | T | B |
| Cebirsel ifadeler, özdeşlikler | Alanla özdeşlik: (a+b)² bölünmüş kare | K | A |
| Doğrusal denklemler, eşitsizlikler | Eğim ve rota, güvenli aralık | K | A |
| Üçgenler (açı–kenar, Pisagor) | Ayrı bir üçgenler görevi planlanmadı | H | B |
| Eşlik ve benzerlik | Gölgeden kule boyu | H | A |
| Dönüşüm geometrisi | Harita yansıma ve öteleme | P | B |
| Geometrik cisimler | Prizma Deposu, silindir ve koni | H | A |

### Maarif 8. sınıf

- **Fen (7 ünite, resmi):** Mevsimler ve İklim, Yaşamı Kolaylaştıran Kuvvet, Yaşamın Gizemi, Sesin Dünyası, Periyodik Tablo ve Maddenin Etkileşimi, Elektriğin Yolculuğu, Sürdürülebilir Yaşam ve Madde Döngüleri. "Sesin Dünyası" gibi bazı üniteler eski listede yok. Alt konuları ve kazanım kodları üniteler tek tek okunarak eklenecek.
- **Matematik (7 tema, resmi):** Sayılar ve Nicelikler, İşlemlerle Cebirsel Düşünme ve Değişimler, Geometrik Şekiller, Geometrik Nicelikler, Dönüşüm, İstatistiksel Araştırma Süreci, Veriden Olasılığa. Kazanımlar [2024 öğretim programı PDF'inde](https://tymm.meb.gov.tr/upload/program/2024programmat5678Onayli.pdf) MAT.8.x kodlarıyla duruyor.
- Ortak konular (mevsimler, basınç, periyodik tablo, elektrik) iki programda da var, deneyler aynen kullanılabilir. Eşleşmeyen konular ayrı görev olur.

## Sınıf kataloğu 5–12

Kademe: ortaokul 5–8, lise 9–12. Her görev `grade`, `routes`, program sürümü, kazanım kodu ve kaynak taşır. Sınıf rotası bu havuzdan sınıfa uygun görevleri süzer. 9–12. sınıf Maarif ve eski program ayrımı için de MEB'in sınıf sayfaları satır satır okunacak. Bu henüz yapılmadı.

## Öncelik özeti

- **A (ilk büyük teslim):** 41 satır, soru ağırlığı yüksek konular.
- **B (35 satır):** ikinci dalga.
- **C (11 satır):** yer kalırsa.
