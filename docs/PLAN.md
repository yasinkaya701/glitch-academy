# Yanlış Dünya · Hackathon planı

Godot 4.7.2 ve GDScript ile Türkçe bir masaüstü oyunu. Yaklaşık 15 saniyelik atlanabilir açılışta bir köprü kapanmaz, vakum odasında iki yük farklı zamanlarda düşer ve kalp modelinde kan geriye kaçar. Oyuncu kontrol merkezinden istasyon seçer, bozulmayı gözlemler, ölçüm yapar ve öğrendiği kuralı yeni bir durumda kullanarak istasyonu onarır.

Görselleştirmede ölçü, şekil ve formül birlikte güncellenir. Köprüde bir köşe sürüklendiğinde kenarın uzunluğu, üzerinde çizilen karenin alanı ve denklemdeki ilgili terim değişir. Kalpte oklar aynı modeldeki kapakçık ve akış durumunu gösterir. [3Blue1Brown · The Essence of Calculus](https://www.3blue1brown.com/lessons/essence-of-calculus/)

Prizma, vakum odası ve deney kapları için 3D modeller kullanılabilir. Prizmada birim küpleri Godot mesh'leriyle oluştur. Daha ayrıntılı modelleri Blender'da üretip `.glb` olarak ekle. Kalp modeli kullanılırsa odacık, kapakçık ve damar bağlantılarını ayrı parçalar olarak doğrula. Formül, ölçüm ve grafikler 2D panellerde okunur. Bölümü alan kişi, deneyin nasıl anlaşılacağına göre sahnenin kamera ve görsel yaklaşımını belirler. [Godot 3D varlık biçimleri](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)

## İlk teslim

İlk geliştirme turu açılış animasyonu ve kontrol merkezini kapsar. LGS, TYT ve AYT kendi ders ve ünite sıralarıyla ilerler. Onaylanan ilk görevler LGS Mevsimler, TYT Ölçüm ve Birimler, AYT Vektörler. [İlk görevlerin oynanış ve kabul ölçütleri](FIRST_MISSIONS.md)

Aşağıdaki istasyonlar sonraki içerik havuzunda yer alır. Her istasyon, bozuk kuralın sonucunu gösteren kısa bir açılışın ardından gözlem, yönlendirmeli uygulama ve bağımsız uygulama içerir.

| İstasyon | Rota | Oynanış ve kabul ölçütü |
|---|---|---|
| İspat Laboratuvarı | LGS, 8. sınıf | Yapay zekânın `(a+b)² = a²+b²` şeklindeki hatalı özdeşlik ispatında eksik `2ab` terimini bul. 3D alan modelindeki iki `ab` parçasını doğru sonuçla eşleştir. Kazanım: `M.8.2.1.3`, özdeşlikleri modellerle açıklar. [MEB 8. sınıf Matematik](https://odsgm.meb.gov.tr/www/8-sinif-matematik-unitelendirilmis-ornek-sorular/icerik/677) |
| Prizma Deposu | 7. sınıf keşfi | Birim küp katmanlarından `V = taban alanı × yükseklik` ilişkisini çıkar. `4 × 3 × 2` kasayı `24` birim küple doldur. Eksik dolum ve taşma görünür. [MEB Geometrik Nicelikler](https://tymm.meb.gov.tr/ortaokul-matematik-dersi/unite/467) |
| Düşüş Odası | AYT Fizik | Vakumda aynı yükseklikten ilk hızsız bırakılan iki farklı kütleyi karşılaştır. Kütleye bağlı sahte ivmeyi kaldır. Onarılan modelde `h = ½gt²` ile `20 m` ve `2 s` ölçümünden `g = 10 m/s²` hesapla. Sensöre `3 s` sonra ulaşmak için `45 m` ayarla. İki kütle eşit sürede iner ve yanlış yükseklik zamanlamayı değiştirir. [MEB serbest düşüş](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/beceri_temelli/11/fizik/files/basic-html/page45.html) |
| Gösterge Laboratuvarı | LGS Fen, TYT Kimya | LGS'de referansların gösterge tepkisini incele, bilinmeyen numuneyi ölç ve asit, baz veya nötr hattına gönder. TYT'de iki sulu numunenin pH değerinden daha asidik olanı bulup vanayı aç. Yanlış seçimde vana kapalı kalır. Ölçüm sonucu renk ve metinle görünür. [MEB 8. sınıf Fen](https://odsgm.meb.gov.tr/www/8-sinif-fen-bilimleri-unitelendirilmis-ornek-sorular/icerik/676), [MEB TYT Kimya](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/3adim/tyt/kimya/kimya.pdf) |
| Kalp Odası | AYT Biyoloji | Dört odacığı, büyük damarları ve dört kapakçığı tanı. Küçük ve büyük dolaşımı kur, pompanın dolum ve boşaltımını izle. Ters akışı teşhis et, kalbi onar ve vücut dokularına oksijen taşınmasını geri getir. [Kalp Odası öğrenme akışı](HEART.md) |
| Basınç İstasyonu | LGS Fen | Bir karşılaştırmada sıvıyı sabit tutup derinliği, diğerinde derinliği sabit tutup sıvı türünü değiştir. Sensör okumalarından yararlanarak hedef basınca ulaş ve kapağı aç. LGS ekranı gözlem, kontrollü deney ve karşılaştırmayı kullanır. [MEB sıvı basıncı](https://odsgm.meb.gov.tr/destekmateryal/pdf/8kt/fen/3.pdf) |
| Palanga Atölyesi | LGS Fen | Gerçekçi 3B sabit ve hareketli makarayı gözlemle. Sabit makarada yük ve ip ucu aynı büyüklükte ivmelenir; tek hareketli makarada yük a ivmesiyle yükselirken ip ucu 2a ile iner. MERİDYEN etiketleri ters çevirir; oyuncu yanlışlığı düzelterek vinci onarır. |

## Rotalar ve konu haritası

Sınıf keşfi 5–12. sınıf filtresini kullanır. LGS, TYT ve AYT görevleri kendi kazanımlarını taşır. Örneğin Gösterge Laboratuvarı LGS'de Fen Bilimleri, TYT'de Kimya görevidir. AYT Kalp Odası'nda kapakçık zamanlaması, sınıf keşfinde ise ilgili program düzeyinde dolaşım anlatımı kullanılır. 2022 PDF'leri konu fikri verir. Sınav eşleştirmelerinde yürürlükteki 8. sınıf programı, TTKB'nin 2026 YKS listesi ve ÖSYM kitapçıkları dayanak alınır. 2027 YKS'nin ayrı konu listesi plan hazırlanırken doğrulanamadı. [2022 TYT referansı](https://aksaraysbl.meb.k12.tr/meb_iys_dosyalar/68/01/973040/dosyalar/2022_03/07093256_2022-TYT-Konulari.pdf), [2022 AYT Sayısal referansı](https://sehitcancalskanmtal.meb.k12.tr/meb_iys_dosyalar/06/21/761800/dosyalar/2021_11/01205648_2022-AYT-Sayisal-konulari.pdf), [TTKB 2026 YKS kapsamı](https://ttkb.meb.gov.tr/www/icerik_goruntule.php?DIL=tr&KNO=831), [MEB 2027 LGS](https://odsgm.meb.gov.tr/www/lgs-kapsamindaki-merkezi-sinavin-tarihi-belli-oldu/icerik/1755/tr), [MEB 2028 geçişi](https://www.meb.gov.tr/yks-ve-lgsde-yeni-mufredata-uyumlu-soru-modeli-2028de-hayata-gececek/haber/39265/tr)

| Bölge | Sonraki bölüm fikirleri |
|---|---|
| Matematik ve Geometri | Gölgeden benzer üçgenlerle kule yüksekliği bulma, açıortayla alanı bölme, dörtgenlerle zemin kaplama, yansıma ve ötelemeyle harita onarma, prizma açınımını katlama, olasılıkla dağılım ayarlama, AYT'de doğru ve çember denklemleriyle rota kurma, türevle anlık hızı ve integralle birikimi görme |
| Fizik | TYT optikte ışını aynalarla hedefe ulaştırma, devre kurma ve kaldırma kuvvetiyle platformu dengeleme. AYT'de atış, tork, momentum, manyetizma ve dalga girişimi |
| Kimya | Taneciklerle tepkime denkleştirme ve kütle korunumu, karışım ayırma, mol oranı, gaz pistonları, molarite, hız ve kimyasal denge |
| Biyoloji ve Anatomi | Ortaokulda sade dolaşım, TYT'de hücre ve zar taşınımı. AYT'de alveol, nefron, refleks, enzim, fotosentez ve popülasyon dengesi |
| Fen Bilimleri | Eksen eğikliğiyle mevsimler, bezelyede tek karakter çaprazlaması, kaldıraç ve makara, elektrik yükleri, hâl değişimi ve enerji dönüşümleri |

**Felsefe ve Tarih son içerik aşamasında geliştirilir.** Fikir Meydanı'nda oyuncu NPC'lerle konuşur, örnek ister ve itiraz eder. Locke veya Descartes'ın görüşünü temsil eden karakter kendi gerekçesini yeniden kurduğunda görev çözülür. Zaman Arşivi'nde kurmaca arıza Sivas'ta cemiyetlerin birleşmesini engellemek üzeredir. Oyuncu kongre kararını ve tarihli belgeleri kullanarak doğru kararı devreye sokar. Amasya Genelgesi, Erzurum Kongresi, Sivas Kongresi ve TBMM'nin açılışını doğru sıraya yerleştirir. Oyun, kurmaca arıza ve belgelenen olay çizgisini sahnede etiketler. [MEB Descartes ve Locke](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/felsefe/11/unite4/files/basic-html/page7.html), [TBMM tarihçesi](https://cdn.tbmm.gov.tr/TbmmWeb/Yayinlar/Dosya/8968713a-84eb-4c10-88d1-c2f4232ea60b.pdf)

## Ekip ve 24 saatlik sıra

Yasin Codex ve Claude ile, ekip arkadaşı Codex ve Gemini ile çalışır. Hangi görevi kimin alacağını Yasin belirler. Görev devri ve ortak dosyaların düzeni [AGENTS.md](../AGENTS.md) içinde.

| Saat | Çıktı |
|---|---|
| 0–2 | Açılış ve kontrol merkezi, ortak sahne sözleşmesi ve demo Mac'inde dışa aktarma provası |
| 2–10 | LGS Mevsimler, TYT Ölçüm ve Birimler ve AYT Vektörler, rota başına ilk oynanabilir öğrenme bölümü |
| 10–18 | İlk üç bölümün kalite turu, rota kontrolleri ve ardından sıradaki konular |
| 18–24 | Hatalı girdiler, yeniden deneme, açılışı atlama, merkeze dönüş ve çevrimdışı paket açılışı doğrulanır |

Jüri rotası, oynanabilir ve doğrulanmış bölümler arasından seçilir. Her görevde oyuncu gözlem yapar, bir kuralı uygular ve onarımın sonucunu görür. Süre sıkışırsa ses ve geçiş animasyonları sadeleşir.
