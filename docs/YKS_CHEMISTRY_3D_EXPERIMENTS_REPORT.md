# YKS Kimya — Deney, 3B Modelleme ve Oyun İstasyonları Raporu

**Proje:** Yanlış Dünya · Glitch Academy  
**Tarih:** 13 Kasım 2026  
**Kapsam:** TYT–AYT kimya, 9–12. sınıf; eski YKS konu sırası + Türkiye Yüzyılı Maarif Modeli (TYMM) içerikleri  
**Durum:** Araştırma ve içerik tasarım belgesi. Aşağıdaki sahneler geliştirilmiş/oynanabilir kabul edilmez.

## 0. Yönetici özeti

Bu rapor, YKS kimyada deney, gözlem, moleküler model, 3B düzenek ve interaktif grafikle öğretilmesi anlamlı 41 **öğretim/deney grubu** ve her grup için birbirinden farklı **iki somut 3B/etkileşim önerisi** (toplam 82 tasarım fikri) içerir. Ayrıca ilk üretim için 17 istasyon önerir.

> **Sayıların kapsamı:** 41/82/17 bu belgenin editoryal envanter sayılarıdır; MEB'in açıkladığı resmî deney/kazanım sayıları değildir. Her grup, programda kelimesi kelimesine zorunlu bir laboratuvar deneyi olmak zorunda değildir. Programda doğrudan deney yapılması istenen başlıklara örnekler ayrıca işaretlenmiştir. Kullanılan 3B canlandırmalar, fiziksel laboratuvar deneylerinin yerine geçmiş sayılmaz.

### Müfredat geçişi

- **2026–2027:** TYMM hazırlık, 9, 10 ve 11. sınıfta; 12. sınıfta önceki öğretim programı yürürlüktedir. [MEB OGM, 01.09.2026](https://ogm.meb.gov.tr/www/2026-2027-egitim-ogretim-yili-turkiye-yuzyili-maarif-modeli-taslak-cerceve-planlar-yayimlandi/icerik/2633).
- **2026 YKS:** TTKB'nin yayımladığı 2026 YKS konu ve kazanım kapsamı ayrı bir sınav referansıdır. Bu rapor, geçmiş YKS başlıklarını korur; 2027 için bağımsız resmî konu listesi teyit edilmiş gibi davranmaz. [TTKB 2026 YKS](https://ttkb.meb.gov.tr/www/osym-tarafindan-2026-yilinda-gerceklestirilecek-quotyuksekogretim-kurumlari-sinavi-yksquotna-esas-derslere-ait-konu-ve-kazanimlar/icerik/831/tr).
- **2028:** MEB, yeni müfredata uyumlu beceri temelli soru modelini 2028 YKS için duyurmuştur. Bu, sınav formatının kesin olarak değiştiği anlamına gelmez. [MEB duyurusu](https://www.meb.gov.tr/yks-ve-lgsde-yeni-mufredata-uyumlu-soru-modeli-2028de-hayata-gececek/haber/39265/tr).

### Oyun tasarımının vazgeçilmez kuralı

Bir ünite **makro gözlem (deney) → alt-mikro model (tanecikler/bağlar/elektronlar) → sembolik düzlem (formül, grafik, denklem)** arasındaki ilişkiyi oyuncunun değiştirdiği tek bir sistem olarak göstermelidir. Döndürülebilen 3B molekül tek başına istasyon değildir. Oyuncu önce hatalı kuralın sonucu ile karşılaşır, kontrollü deneyde kuralı keşfeder, sonra yeni bir örnekte bağımsız uygular ve dünyanın bozuk mekanizmasını onarır. Bu, [AGENTS.md](../AGENTS.md) ve [PLAN.md](PLAN.md) sözleşmelerine uygundur.

## 1. Okuma anahtarı, öncelik ve bilimsel sınırlar

- **Rota:** Eski konu sırası esas alındığında TYT/AYT; TYMM'deki yeri ayrıca 2. bölümde gösterilir. Bazı konular her iki rotaya farklı derinlikle uyarlanabilir.
- **D (güvenli fiziksel gösterim):** Öğretmen gözetimindeki basit gözlem/deney sınıfı; koşul ve madde seçimi okul laboratuvarının güvenlik prosedürüne bağlıdır.
- **S (sanal deney):** Öncelikle simülasyonla ele alınması önerilen sistem; burada verilen tasarım gerçek deney yönergesi değildir.
- **M (kavramsal model):** Deney adı olarak sunulmayan, görünmeyen kavramı açıklayan 3B model.
- **P0:** Bir haftalık prototip/hackathon demoda yüksek öğretim değerine ve ayırt edici etkileşime sahip.
- **P1:** İkinci üretim dalgası; **P2:** sonraki genişletme.
- **Önemli:** Aynı konu eski programda farklı sınıfta olabilir; örneğin eski 11'deki gazlar yeni 10'da, eski 11'deki atom/orbital konuları yeni 9'da işlenebilir.

### Tasarımda kaçınılacak bilimsel hatalar

1. Orbitalleri elektronların sabit dairesel yörüngeleri gibi gösterme. Orbitalin olasılık yoğunluğu olduğunu ve sadeleştirme sınırını etiketle.
2. Moleküler bağ kırılmasını enerji çıkışı gibi gösterme; **bağ kırılması enerji alır**, yeni bağ oluşumu enerji verir.
3. Çözünmeyi her zaman kimyasal tepkime; buharlaşmayı her zaman bağ kırılması; dengeyi durgunluk olarak sunma.
4. pH ve indikatör renklerini bütün çözeltilerde tek bir kesin renge ve tek bir ideal modele indirgeme.
5. İyonların sulu çözeltide serbest elektron taşıdığını gösterme; çözelti içindeki yük taşıyıcıları iyonlardır.
6. Kimyasal dengeye giderken atomları yok etme/yaratma; denkleştirme, toplam atom sayısını korumalıdır.
7. Gazları yüzeyde sekip rastgele renk değiştiren dekoratif parçacıklar olarak kullanma; basınç/sıcaklık hacim/çarpışma ilişkisi tutarlı olsun.
8. Kimyasal izomerleri sadece molekül döndürmeyle özdeşleştirme; bağ grafı aynıysa salt döndürme yeni konstitüsyonel izomer yaratmaz.
9. Kimyasal reaksiyona ilişkin görsel abartı (patlama, köpürme, renk değişimi) her örnekte varmış gibi davranma; gerçek makro gözlemle eşleştir.
10. Molekül ölçeklerini, hızlarını ve bağ uzunluklarını gerçek zamanlı fiziksel ölçeklermiş gibi sunma; hızlandırılmış/temsili animasyon etiketleri kullan.

## 2. Konu haritası: eski YKS başlıkları ↔ TYMM

| Eski YKS/OGM sırası | TYMM 9–12 temalarındaki karşılığı | Özellikle 3B'nin çözebileceği öğrenme engeli |
|---|---|---|
| TYT: kimya bilimi, laboratuvar güvenliği, atom, periyodik sistem | 9 / Etkileşim | Soyut parçacık, orbital ve periyodik eğilimlerin nedenselliği |
| TYT: bağlar, moleküller, zayıf etkileşimler, maddenin hâlleri | 9 / Çeşitlilik | Polarite, kristal yapı, yüzey gerilimi ve tanecikler arası düzen |
| TYT: doğa ve kimya, çevre | 9 / Sürdürülebilirlik; 10 / Sürdürülebilirlik | Nanoölçek ve atık/enerji akışının görünmezliği |
| TYT: mol, kimyasal tepkimeler, kimyasal hesaplamalar | 10 / Etkileşim | Tanecik sayısı–denklem katsayısı–kütle bağı |
| Eski AYT 11: gazlar, sıvı çözeltiler | 10 / Etkileşim, Çeşitlilik | P–V–T ilişkileri, çözünme ve koligatif etkiler |
| Eski AYT 11: enerji ve hız | 11 / Etkileşim | Entalpi, çarpışma ve hız eğrilerinin açıklanması |
| Eski AYT 11: denge, asit-baz, çözünürlük dengesi | 11 / Çeşitlilik | Dinamik denge, titrasyon ve iyon dengeleri |
| Eski AYT 12: kimya ve elektrik | 12 / Etkileşim | Elektron akışı, yarı hücreler, elektroliz ve korozyon |
| Eski AYT 12: karbon kimyasına giriş, organik bileşikler | 12 / Çeşitlilik | Bağ geometrisi, izomerlik, fonksiyonel grup kimliği |
| Eski AYT 12: enerji kaynakları ve bilimsel gelişmeler | 11 ve 12 / Sürdürülebilirlik | Yakıt, yeşil hidrojen, mikroplastik ve yenilikçi malzeme |

**TYMM resmî tema sayfaları:** [9 / Etkileşim](https://tymm.meb.gov.tr/kimya-dersi/unite/92), [9 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/121), [9 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/137), [10 / Etkileşim](https://tymm.meb.gov.tr/kimya-dersi/unite/138), [10 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/159), [10 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/160), [11 / Etkileşim](https://tymm.meb.gov.tr/kimya-dersi/unite/161), [11 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/162), [11 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/163), [12 / Etkileşim](https://tymm.meb.gov.tr/kimya-dersi/unite/167), [12 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/168), [12 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/169).

## 3. Tam öğretim envanteri: 41 grup / 82 modelleme fikri

İki model sütunu birbirinden bağımsız geliştirme fikirleridir. **D/S/M etiketi, resmî deney statüsünü değil tasarımın gerçek/sanal/model doğasını belirtir.** Gerçek deney yapılması istenen güncel kazanımlara 4. bölümde ayrıca örnekler verilir.

### 3.1. Temel kimya — eski 9. sınıf / büyük ölçüde TYT (10 grup)

| ID / tip | Konu ve deney/gözlem | 3B fikir A | 3B fikir B | Oyuncudan ölçülebilir çıktı | Sıra |
|---|---|---|---|---|---|
| K01 / S | Kimyasal güvenlik: etiket, saklama, uygunsuz madde birleşimi | Sanal laboratuvarda piktogramlı kapları doğru dolaba yerleştirme | Kesitli çeker ocak, koruyucu ekipman ve atık kutusu seçim ekranı | Riskli düzeneği başlatmadan güvenli hâle getirir | P0 |
| K02 / M | Atom modelleri: Dalton→Thomson→Rutherford→Bohr→modern | Altın folyo saçılmasına dair temsili ışın/parçacık gözlemi | Varsayımları değiştirilebilir atom-model zaman tüneli | Gözlemin hangi modeli çürüttüğünü açıklar | P1 |
| K03 / M | Proton, nötron, elektron; izotop ve iyon | Çekirdek bileşimini değiştirerek izotop oluşturma | Elektron ekleyip çıkararak iyon yükü ve gösterimini bağlama | Z, A, yükü doğru okur; maddeyi bozmaz | P1 |
| K04 / M | Orbital, elektron dizilimi, Hund/Pauli/Aufbau | Olasılık bulutu kesitleri ve s/p orbital şekilleri | Enerji düzeyli sürükle-bırak orbital doldurma paneli | Kurallara uygun temel hâl dizilimi kurar | P1 |
| K05 / M | Periyodik özellikler: yarıçap, elektronegatiflik, iyonlaşma enerjisi | Etkileşimli periyodik tabloya bağlı atom boyutu modelleri | Etkin çekirdek çekimi ve perdeleme etkisi karşılaştırması | İki atomun eğilimini gerekçelendirir | P1 |
| K06 / M | Metalik/iyonik/kovalent bağ | Metalik kristal ve hareketli elektron delokalizasyonu | NaCl örgü/kristal kırılma ve iyon oluşumu görünümü | Bağ türü ile makro özelliği eşleştirir | P0 |
| K07 / M | Lewis, VSEPR, polarite | Molekülü bağ ve yalnız çift sayısına göre oluşturma | Bağ dipol vektörlerinin bileşkesini 3B gösterme | H₂O/CO₂/NH₃/BF₃ polaritesini gerekçelendirir | P0 |
| K08 / D | Hidrojen bağı ve moleküller arası etkileşimler | Su molekülleri arasında geçici H-bağı ağı | Farklı etkileşim güçlerinde buharlaşma/viskozite eğilim sahnesi | Kaynama eğilimini moleküler gerekçeyle sıralar | P1 |
| K09 / D | Katı/sıvı/gaz; erime, buharlaşma, yoğuşma | Kap kesitinde tanecik hareketleri ve faz geçişleri | Isıtma/soğutma eğrisiyle kilitlenmiş üç fazlı görünüm | Plato sırasında enerjinin nereye gittiğini açıklar | P0 |
| K10 / D | Sıvıların yüzey gerilimi, adezyon, kohezyon, kılcallık | Kapiler boruda menisküs ve duvar etkileşimi | Yüzeydeki taneciklerin komşuluk sayısı ve yüzey kuvvetleri | Farklı boru çapında yükselme eğilimini tahmin eder | P2 |

### 3.2. Tepkimeler ve çözeltiler — eski 10. sınıf / TYT; yenide 10. sınıf (11 grup)

| ID / tip | Konu ve deney/gözlem | 3B fikir A | 3B fikir B | Oyuncudan ölçülebilir çıktı | Sıra |
|---|---|---|---|---|---|
| K11 / D | Fiziksel ve kimyasal değişim; renk/gaz/çökelek gibi gözlemler | İki tüpte olayların makro karşılaştırması | Bağ grafının önce/sonra gösterimi | Sadece dış görünüşten değil tanecik bilgisinden sınıflar | P1 |
| K12 / D | Kütlenin korunumu, kapalı/açık sistem | Kapalı kapta tepkimeyi tartma | Aynı sistemi açık kapta gaz kaçışıyla kıyaslama | Gözlenen kütle farkının sistem sınırıyla ilişkisini açıklar | P0 |
| K13 / M | Mol ve Avogadro; denklem katsayıları | Tanecik paketleriyle mol ölçekleme | Kütle–mol–tanecik sayı üçgeninin senkron görselleştirmesi | Belirli molü tanecik sayısına dönüştürür | P0 |
| K14 / S | Denklem denkleştirme, sınırlayıcı bileşen, verim | Reaktif tanecikleri sayarak ürün montajı | Artan reaktifli stokiyometri üretim hattı | Verilen oranlarda maksimum ürünü hesaplar | P0 |
| K15 / D | Tepkime türleri: birleşme, ayrışma, yanma, asit-baz, çökelme | Aynı önce/sonra atom etiketli reaksiyon sahneleri | Tepkime örüntülerini karşılaştıran etkileşimli kart/kaplar | Türü, atom korunumunu ve ürünleri ilişkilendirir | P1 |
| K16 / D | Karışımlar: homojen/heterojen, kolloid, süspansiyon | Kapta çözünmüş/damla/parçacık dağılımını büyütme | Tyndall ışık yolu ve çökelme zamanı karşılaştırması | Karışımı gözlem ve dağılıma göre sınıflar | P1 |
| K17 / D | Ayırma: süzme, mıknatıs, yoğunluk, santrifüj | Filtre kağıdı/gözenek kesitinden tanecik geçişi | Yoğunluk farkıyla çok fazlı ayırma haznesi | Karışım türü için uygun yöntemi seçer | P1 |
| K18 / S | Damıtma, fraksiyonlu damıtma, buharlaştırma, kristallendirme | Soğutucu ve termometreli damıtma düzeneği kesiti | Uçuculuk/kaynama grafiği ve fraksiyon toplama paneli | Bileşenleri ayırmak için makul yöntemi seçer | P0 |
| K19 / D | Çözünme, hidratasyon, polarite, 'benzer benzeri çözer' | NaCl'nin suyla çevrelenerek iyonlarına ayrılması | Polar/apolar çözücüde farklı çözünenlerin dağılımı | Çözünürlüğü uygun etkileşimle gerekçelendirir | P0 |
| K20 / D | Asit-baz indikatörü, pH; günlük asit/bazlar | Sanal damlalıkla indikatör renk ve pH göstergesi | H₃O⁺/OH⁻ tanecik oranlarının kavramsal paneli | Bilinmeyen numuneyi pH ve indikatörle sınıflar | P0 |
| K21 / D | Derişim, seyreltme, çözünürlük ve sıcaklık | Hacim ve çözünen miktarı değişen beher | Doygunluğa yaklaşırken taneciklerin katı/çözelti fazı dağılımı | M₁V₁=M₂V₂ veya derişim hesabını uygular | P1 |

### 3.3. Fiziksel kimya — eski 11. sınıf / AYT; TYMM 10–11 (12 grup)

| ID / tip | Konu ve deney/gözlem | 3B fikir A | 3B fikir B | Oyuncudan ölçülebilir çıktı | Sıra |
|---|---|---|---|---|---|
| K22 / S | Gazların P–V–T ilişkileri: Boyle, Charles, Gay-Lussac | Piston ve manometre üzerinde kontrollü bir değişken | Aynı deneyle anlık P–V, V–T ve P–T grafikleri | Değişkenleri sabit tutup gaz yasasını keşfeder | P0 |
| K23 / S | İdeal gaz, kısmi basınç, difüzyon/efüzyon | İki gazın tanecik hız dağılımı ve karışımı | Bölmeli gaz kabında kısmi basınç ve toplam P | Dalton yasası ve mol kesrini uygular | P1 |
| K24 / S | Gerçek gazlar; basınç/sıcaklık limitleri | İdeal tanecikler ile hacimli/çekimli tanecikler kıyası | Sıkıştırmada sapmayı gösteren P–V grafiği | Hangi koşulda ideallikten sapma bekler | P2 |
| K25 / D | Derişimler: molarite, molalite, ppm; koligatif özellikler | Çözünen tanecik miktarıyla kaynama/donma eğrisi | İyonlaşan/iyonlaşmayan çözünen karşılaştırması | Koligatif etkiyi tanecik sayısıyla ilişkilendirir | P1 |
| K26 / D | Çözünürlük: sıcaklık, basınç, ortak iyon | Sıcaklık ayarlı çökelti/çözeltinin faz sınırı | Gaz çözünürlüğü için kapalı gazlı sıvı düzeneği | Katı ve gaz için farklı eğilimleri ayırt eder | P1 |
| K27 / S | Endotermik/ekzotermik; kalorimetri, entalpi | Isı yalıtımlı kap ve termometre görselleştirmesi | Enerji/reaksiyon koordinatı diyagramına bağlı bağ kırılma/oluşma | ΔH işaretini ve sıcaklık ölçümünü açıklar | P0 |
| K28 / M | Hess yasası, bağ enerjileri, oluşum entalpisi | Birden çok tepkime yolunun aynı enerji uçlarına bağlanması | Bağları kırıp yeniden bağ kuran enerji muhasebesi | Hess döngüsünde ΔH toplamını doğru bulur | P1 |
| K29 / S | Çarpışma teorisi, aktivasyon enerjisi, katalizör | Etkin/etkisiz çarpışma ve oryantasyon canlandırması | Maxwell–Boltzmann dağılımı ve enerji eşiği kesişimi | Sıcaklık/katalizörün neden farklı etkileri olduğunu açıklar | P0 |
| K30 / S | Hız: derişim, sıcaklık, yüzey alanı, katalizör | Tanecik çarpışma sayacıyla değişken kontrollü deney | İlerleme boyunca derişim–zaman/hız–zaman grafiği | Tek değişkenli deney tasarlar ve sonuç çıkarır | P0 |
| K31 / S | Hız denklemi/mertebe: başlangıç hızları | Farklı derişimli sanal deney seti ve kronometre | Hız tablosundan n ve k hesaplama paneli | Deney verisinden hız denklemini çıkarır | P1 |
| K32 / S | Kimyasal denge, Le Châtelier, K/Q | İleri–geri tepkimelerin eş zamanlı sürdüğü tanecik hacmi | Derişim/basınç/sıcaklık müdahaleli Q–K grafiği | Denge yönünü ve yeniden dengeyi gerekçelendirir | P0 |
| K33 / S | Asit-baz ve çözünürlük dengesi, titrasyon, Ksp | Büret–erlen–pH metre sistemi ve titrasyon eğrisi | Doyma, ortak iyon, çökelme/yeniden çözünme tanecik düzeneği | Eşdeğerlik noktasını ve çökelek koşulunu ayırt eder | P0 |

### 3.4. Elektrokimya, organik kimya ve sürdürülebilirlik — eski 12. sınıf / AYT (8 grup)

| ID / tip | Konu ve deney/gözlem | 3B fikir A | 3B fikir B | Oyuncudan ölçülebilir çıktı | Sıra |
|---|---|---|---|---|---|
| K34 / S | Redoks, aktiflik sırası, yarı tepkime | Metal–iyon değişiminde atom/iyon elektron aktarımı | Yükseltgenme basamağı kartlarıyla yarı tepkime denkleştirme | Anot/katot değil önce indirgenen/yükseltgeneni bulur | P1 |
| K35 / S | Galvanik hücre, tuz köprüsü, pil gerilimi | Zn/Cu yarı hücreli tel ve tuz köprüsü kesiti | Elektrot derişimi/potansiyel ve elektron yönü paneli | Elektron akışı, iyon hareketi ve hücre yönünü ayırır | P0 |
| K36 / S | Elektroliz, Faraday, metal kaplama, korozyon | Haricî güç kaynaklı elektroliz kabında iyon hareketi | Kaplama kütlesi–akım–zaman grafiği ve paslanma kesiti | Galvanik/elektrolitik farkını ve kaplama miktarını açıklar | P1 |
| K37 / M | Organik iskelet, sigma/pi, hibritleşme, geometriler | sp/sp²/sp³ merkezli 3B karbon model yapıcı | Tek/çift/üçlü bağda dönme serbestliği karşılaştırması | Bağ sayısı, geometri ve hibritleşmeyi eşleştirir | P0 |
| K38 / M | Alkan/alken/alkin/aromatik, IUPAC adlandırma | Karbon zinciri inşa edip en uzun zinciri seçme | Benzenin düzlemsel ve rezonanslı temsili | Yapıdan doğru isim ve bağ türü çıkarır | P1 |
| K39 / M | Yapısal/fonksiyonel grup/geometrik izomerlik | Aynı molekül formülüyle farklı bağlantı grafı kurma | Cis/trans ve E/Z için 3B düzen karşılaştırması | Sadece döndürme ile gerçek izomer oluşmadığını fark eder | P0 |
| K40 / S | Alkol, eter, aldehit, keton, asit, ester | Fonksiyonel grubu seçip maddeleri kimlik eşleştirme | Esterleşme ve hidrolizin temsili önce/sonra paneli | İzomerleri ve fonksiyonel grupları sınıflar | P1 |
| K41 / S | Yakıtlar, yeşil kimya, nanoteknoloji, polimerler | Enerji kaynağı karşılaştırmalı yakıt hücresi/karbon akışı | Polimer zinciri, parçacık boyutu ve çevresel akıbet sahnesi | Emisyon/atık/kaynak kısıtlarıyla karar verir | P2 |

**İlgili eski program materyali:** [MEB OGM 11. sınıf ünite listesi](https://ogmmateryal.eba.gov.tr/dersler-cepte-fasikul?d=46&k=0&s=8&u=0), [MEB OGM 12. sınıf ünite listesi](https://ogmmateryal.eba.gov.tr/dersler-cepte-fasikul?d=47&k=0&s=9&u=0).

## 4. Yeni programda açıkça deney/sorgulama vurgusu olan örnekler

Bu kısım **resmî öğrenme çıktıları ile tasarım önerilerini ayrı tutar**. Bütün deneyleri tek tek resmen zorunlu diye nitelendirmek için kazanım, açıklama, zenginleştirme ve okul türünün ayrıca incelenmesi gerekir.

| Kaynak / öğrenme çıktısı | MEB'in vurgusu | Glitch Academy karşılığı |
|---|---|---|
| [KİM.9.1.1](https://tymm.meb.gov.tr/kimya-dersi/unite/92) | Günlük kimyasal ürünlerin niteliklerini gözlemleme ve veri yorumlama | K01 güvenli laboratuvar, K11 makro–mikro karşılaştırma |
| [9. sınıf / Nanoparçacıklar](https://tymm.meb.gov.tr/kimya-dersi/unite/137) | Yeşil kimya ile evsel atıklardan metal nanoparçacık elde etmeye dönük deney | Yalnız güvenli, sanal nanoparçacık sentez ve atık minimizasyonu gösterimi |
| [10 / Etkileşim](https://tymm.meb.gov.tr/kimya-dersi/unite/138) | Kimyasal değişim modelleme, gaz yayılması deneyleri, gaz yasalarına tümevarım | K11–K14 tepkime; K22–K23 gaz düzenekleri |
| [10 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/159) | Çözünme modelleme, derişim, çözünürlük, koligatif özelliklere ilişkin çıkarımlar | K19–K21, K25–K26 |
| [10 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/160) | Mikro/makro ölçekli yeşil kimya deneyleri, atom ekonomisi, su ayak izi | K41 ekolojik karar istasyonu |
| [KİM.11.1.1 / 11.1.2](https://tymm.meb.gov.tr/kimya-dersi/unite/161) | Fiziksel/kimyasal enerji değişimi deneyi; maddelerin enerji kaynağı potansiyeline deneysel yaklaşım | K27 kalorimetri |
| [KİM.11.1.7](https://tymm.meb.gov.tr/kimya-dersi/unite/161) | Hıza etki eden faktörlerle ilgili hipotez, deney, veri analizi | K29–K31 |
| [11 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/162) | Tersinir tepkimelerde denge, asit-baz ve titrasyon deneyi, çözünürlük dengesi | K32–K33 |
| [11 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/163) | Yeşil hidrojen üzerine hipotez; mikro/nanoplastik etkilerini sorgulama | K41 enerji ve malzeme sistemleri |
| [12 / Etkileşim](https://tymm.meb.gov.tr/kimya-dersi/unite/167) | Galvanik/elektrolitik hücreleri gözlemleme; elektrolizle metal kaplama deneyi; korozyon | K34–K36 |
| [12 / Çeşitlilik](https://tymm.meb.gov.tr/kimya-dersi/unite/168) | Hibritleşme, sigma/pi bağları, geometri ve organik izomerlik | K37–K40 |
| [12 / Sürdürülebilirlik](https://tymm.meb.gov.tr/kimya-dersi/unite/169) | Boyaya duyarlı güneş pilleri, biyobozunur polimer, yapay zekâ ve sürdürülebilirlik | K41 ileri içerik |

**Fen lisesi notu:** TYMM 2026–27 yıllık planlar sayfası, bazı yıldızlı zenginleştirme uygulamalarının fen liseleri/sosyal bilimler liselerinde zorunlu olduğunu belirtir. Bu tablo, yıldızlı maddelerin tek tek karşılaştırması değildir; ürün içerik kimliğinde **resmî zorunluluk** alanı ancak kazanım bazında doğrulamadan sonra doldurulmalıdır. [MEB yıllık planlar](https://tymm.meb.gov.tr/taslak-cerceve-planlari/ortaogretim).

## 5. İlk üretim için 17 istasyon: öğretim değeri ve kabul ölçütleri

Aşağıdaki tahmini karmaşıklıklar **geliştirme iş yükü göstergesi**dir, süre taahhüdü değildir. İşlevler mevcut depoda uygulanmış varsayılmaz.

| Sahne kimliği | Başlık / ID | Oyunun bozuk kuralı | Gözlem → deney → bağımsız test | Zorluk |
|---|---|---|---|---|
| chemistry_safety | **Kimya Güvenlik Masası** / K01 | Reaktif deposunda tehlike sembolleri silinmiş | Oyuncu yanlış saklama düzenini düzeltir; uyumsuz seçim deneyi başlatmaz | Düşük |
| bond_builder | **Bağ Atölyesi** / K06 | İyonik örgü 'molekül' gibi davranıyor | NaCl örgüsü ile moleküler bileşiği karşılaştır; özellikleri ayırt et | Orta |
| molecular_geometry | **Molekül Mimarı** / K07 | Moleküller yanlış bağ açılarıyla dizilmiş | Lewis → VSEPR → dipol vektörü; yeni molekül polaritesini belirle | Orta |
| phase_lab | **Faz Kazanı** / K09 | Isıtılırken madde durmaksızın sıcaklık artırıyor | Eri(don)me platosu ve tanecik davranışını eşleştir | Orta |
| mass_conservation | **Kapalı Reaktör** / K12 | Gaz çıkışı sistem sınırı olmadan kütle kaybettiriyor | Açık/kapalı kap deneyini kontrol et; toplam kütleyi açıkla | Düşük |
| mole_factory | **Mol Fabrikası** / K13 | Parçacık sayısı ile mol yanlış ölçeklenmiş | Bilinen mol verisinden tanecik ve kütle hesapla | Düşük |
| stoichiometry | **Tepkime Montaj Hattı** / K14 | Yanlış katsayı yüzünden reaktif tükeniyor | Atomları koru; sınırlayıcıyı ve artanı belirle | Orta |
| distillation | **Ayrıştırma Kulesi** / K18 | İki sıvı hep aynı fraksiyona toplanıyor | Fraksiyonları uygun sıcaklık/aralık ve buharlaşma eğilimiyle ayır | Orta |
| dissolving | **Çözünme Odası** / K19 | Tuzun iyonları suda birbirinden ayrılmıyor | Su dipollerini ve iyon hidratasyonunu düzenle | Orta |
| indicator | **Gösterge Laboratuvarı** / K20 | Numune asit/baz sınıfı ters okunuyor | pH/indikatör gözlemiyle doğru vanayı aç | Düşük |
| gas_piston | **Piston İstasyonu** / K22 | Gaz basıncı ile hacim ilişkisi ters çalışıyor | Sabit T altında piston ve P–V eğrisiyle kuralı onar | Orta |
| calorimeter | **Enerji Odası** / K27 | Isı alarak gerçekleşen süreç ısı veriyormuş gibi gösteriliyor | Termometre ve ΔH işaretini gözleme göre düzelt | Orta |
| collisions | **Çarpışma Reaktörü** / K29–K30 | Her çarpışmada reaksiyon oluşuyor | Eşik enerjisi ve uygun yönelim koşulunu keşfet | Yüksek |
| equilibrium | **Denge Reaktörü** / K32 | Dengeye gelince her iki tepkime duruyor | Dinamik dengeyi sürdür; müdahaleyle yeni dengeyi tahmin et | Yüksek |
| titration | **Titrasyon Tezgâhı** / K33 | Eşdeğerlik/indikatör noktası karıştırılmış | Eğri, hacim ve doğru analitik kavramı bağla | Orta |
| galvanic_cell | **Elektron Köprüsü** / K35 | Elektronlar tuz köprüsünden gidiyor | Elektron/tuz köprüsü iyon hareketini doğru ayır | Orta |
| isomers | **Karbon Yapı Atölyesi** / K37/K39 | Bir molekülün döndürülmesi yeni yapısal izomer sayılıyor | Bağ grafını değiştirerek gerçek izomer elde et | Orta |

**Hackathon için ilk 3 kimya sahnesi:** Gösterge Laboratuvarı (K20), Piston İstasyonu (K22), Molekül Mimarı (K07). Bu üçlü kısa demoda sırasıyla gerçekçi deney, değişken kontrollü simülasyon ve 3B'nin eşsiz sağladığı molekül geometrisi faydasını gösterir. Ancak [FIRST_MISSIONS.md](FIRST_MISSIONS.md)'de seçilmiş **mevcut ilk üç genel oyun görevi** (LGS Mevsimler, TYT Ölçüm, AYT Vektörler) bu öneri yüzünden değişmiş sayılmaz.

## 6. Üç kimya sahnesi için ayrıntılı oyun tasarımı

### 6.1. Gösterge Laboratuvarı — K20 / TYT

**Arıza:** Arıtma tesisi iki tankın asitlik durumunu ters işaretleyerek doğru olmayan vanayı açıyor.

1. **Keşif:** Öğrenci pH ölçeğini, asit/baz ve nötr kavramlarını öğrenir; sanal referans numunelerini karşılaştırır.
2. **Kontrollü deney:** Numune A ve B için pH/indikatör gözlemini alır. Gözlenebilir renk ve sayısal değerler örnek sistemde tutarlı tutulur.
3. **Alt-mikro görünüm:** H₃O⁺/OH⁻ derişimlerinin oranı kavramsal olarak görselleştirilir; ölçek ve ideal-sulu-çözelti sadeleştirmesi belirtilir.
4. **Yeni uygulama:** Önceki numunelerden farklı üçüncü numunede doğru vanayı kendi başına seçer.
5. **Kabul:** Asit/baz/nötr sınıflama doğru; doğru vanada arıtma hattı çalışır, yanlış vanada düzeltme ipucu gösterilir; pH 7'nin nötr oluşu standart seyreltik sulu çözeltide 25 °C bağlamına bağlanır.

### 6.2. Piston İstasyonu — K22 / AYT

**Arıza:** Sabit sıcaklıkta piston aşağı indiğinde basınç da düşüyor.

1. **Keşif:** Kütle ve sıcaklık sabit iken hacim değiştirilebilen bir gaz kabı verilir.
2. **Deney:** Öğrenci pistonu çeker/iter, manometreyi ve tanecik–duvar çarpışmalarını inceler.
3. **Grafik:** P–V grafiği ve P×V çarpımı eşzamanlı güncellenir.
4. **Yeni uygulama:** Başlangıç durumu P₁=2 atm, V₁=3 L; hedef V₂=2 L. İdeal sabit sıcaklık modelinde P₂=3 atm girerek emniyet kilidini onarır.
5. **Kabul:** Değişken sabitliği görünür, P₂ hesabı doğru, P–V eğrisi azalan hiperbolik eğilimde; tanecik sayısı korunur. Mutlak sıcaklık ve ideal gaz varsayımları etiketlenir.

### 6.3. Molekül Mimarı — K07 / TYT + AYT genişletmesi

**Arıza:** Bir CO₂ molekülünün bağ açıları suya benzetilmiş; model yanlış dipol sonucu üretiyor.

1. **Keşif:** Merkez atom etrafındaki bağlayıcı ve yalnız elektron çiftlerinin itmesi ayrı temsillerle gösterilir.
2. **Deney/model:** H₂O (bükük), CO₂ (doğrusal), NH₃ (üçgen piramit), BF₃ (düzlemsel üçgen) karşılaştırılır.
3. **Kontrol:** Oyuncu bağ dipol vektörlerini gösterir ve vektörel toplamı açıp kapatır.
4. **Yeni uygulama:** Yeni bir molekülün Lewis şemasından geometrisini ve polaritesini belirler.
5. **Kabul:** Yalnız elektron çiftleri geometrinin seçiminde etkili; CO₂'nin simetrik bağ dipolleri birbirini götürür; su polar kalır; 3B döndürme sonucu değiştirmez.

## 7. Etkileşim mimarisi ve teknik veri sözleşmesi

Depoda halihazırda [AGENTS.md](../AGENTS.md) uyarınca 3B deney yer tutucusu **scenes/experiment_3d.tscn**, görevlerin klasörü **stations/<istasyon>/** ve kontrol merkezi **scripts/control_center.gd** altında katalog entegrasyonu kullanılır. Bu rapor dosyası, çalışır sahne veya kod yazıldığı anlamına gelmez.

Bir istasyon için önerilen içerik alanları:

| Alan | Örnek / açıklama |
|---|---|
| id, route, class_range | chemistry_gas_piston, ayt, 10–11 |
| legacy_topic, tymm_theme, official_source | Eski konu adı, yeni tema URL'si, doğrulanmış kazanım |
| observable, micro_model, symbolic_model | Dış gözlem, 3B tanecik sahnesi, grafik/denklem |
| independent_variable, controlled_variables, dependent_variable | Öğrencinin deney tasarımında ayırdığı değişkenler |
| visual_scale_notice | Tanecikler ve hızın şematik oluşu; geçerli ideal varsayımlar |
| error_state, experiment_state, transfer_state, repaired_state | Arıza → deney → yeni soruda uygulama → onarım |
| safe_mode, allowed_interactions | Gerçek prosedür yerine yalnız sanal gösterim gereken riskler |
| acceptance_checks | Kavramsal doğruluk, yanlış cevap ipucu, yeniden deneme ve UI okunurluğu |
| evidence_links, status | MEB/OGM URL'leri ve planned / in_progress / tested |

**3B teknik doğruluk ilkeleri:** Mesh'ler keyfî dekor olmamalı; iyon/molekül/elektron türleri farklı temsil edilmeli. Elektron akışı telde, iyon akışı çözeltide gösterilmeli. Her modelin çözünürlük, kamera, ölçeksellik ve etiketleri 1280×720 hedefinde okunmalı. Sayısal hesaplama, render/animasyon hızına bağlı olmamalı. Rota değiştiğinde aynı sahne uygun zorluk/kazanım altkümesini kullanmalı; eski TYT/AYT etiketleri yeni program kazanımlarıyla otomatik eşdeğer sayılmamalı.

## 8. Ölçme-değerlendirme ve öğretime gerçek katkı

Bir 3B sahnenin başarılı olduğuna yalnız oyuncunun istasyonu bitirmesinden karar verilmez. Her istasyonda:

- **Ön test:** 1–2 çoktan seçmeli kavram yanılgısı sorusu; ipucu gösterilmez.
- **Kontrollü keşif:** Oyuncu tek bir bağımsız değişkeni değiştirip gözlem kaydeder.
- **Aktarım testi:** Aynı sayıları/kabı tekrar etmeyen yeni örnek. İşlemi mümkün olduğunca kendi yapar.
- **Gecikmeli tekrar:** Geliştirme sonrasında imkân varsa başka oturumda aynı kavramı yeni bağlamda sorgula.
- **Telemetri:** Ön-test doğruluğu, ipucu sayısı, bağımsız test doğruluğu, yeniden deneme, tamamlanma ve kavram yanılgısı türü.
- **Karşılaştırma:** Statik görsel + açıklama ile 3B etkileşimli sürümü benzer öğrenme süresi ve aynı sorularla kıyasla; 3B'nin üstünlüğünü varsayma.
- **Erişilebilirlik:** Renk körlüğü için yalnız renge dayanmayan etiket/şekil; klavye erişimi; alt-mikro animasyonu durdurup adım adım ilerletme.

**Hedef öğrenme katkısı:** uzaysal yapı kurma (VSEPR/izomerler), çoklu temsil eşleştirme (gazlar/titrasyon), kontrol değişkeni farkındalığı (hız/denge), nedensel açıklama (çözünme/elektrokimya), güvenli deney tasarlama. Bunlar tasarım hipotezleridir; uygulamanın etkililiği henüz ölçülmemiştir.

## 9. Güvenlik ve bilimsel etik

- **Asit, baz, oksitleyici, solvent, yanma, gaz oluşumu, nanoparçacık sentezi, elektroliz/metal kaplama** gibi riskli düzeneklerde oyunun görevi sadece sanal deneydir. Belgede gerçek dünyaya yönelik kimyasal karışım, miktar, gerilim, ateşleme veya atık bertaraf tarifi bulunmaz.
- Öğrencilere temizlik maddelerini karıştırmak gibi tehlikeli ev deneyleri önerilmez; yanlış seçim güvenli bir açıklamayla engellenir.
- Nano malzemeleri ve mikroplastikleri zararsız parıldayan tanecikler olarak romantikleştirme; çevresel etkiler ve belirsizlikleri tartış.
- 'Model', 'ölçüm', 'öğretmen kontrollü gösteri' ve 'gerçek deney' ekran etiketleri birbirine karıştırılmaz.
- Kimyasal formüller ve olaylar alan öğretmeni tarafından bağımsız olarak kontrol edilmeden 'bilimsel olarak doğrulandı' durumuna alınmaz.

## 10. Önceliklendirme: nerede 3B şart, nerede 2B daha doğru?

| Sunum türü | En yararlı olduğu konular | Ürün kararı |
|---|---|---|
| **3B birincil** | VSEPR, polarite, kristaller, hidratasyon, organik izomerler, elektrokimyasal hücre | Tam etkileşimli 3B |
| **3B + grafik eş zamanlı** | Gaz yasaları, hız, denge, termokimya, titrasyon, çözünürlük | 3B makro/alt-mikro ve senkron 2B veri |
| **2B birincil + 3B tamamlayıcı** | Mol hesapları, denklem denkleştirme, periyodik trendler, Hess, hız denklemi | Etkileşimli 2B; 3B sadece kavramsal bağ |
| **Karar simülasyonu/akış diyagramı** | Yeşil kimya, enerji yaşam döngüsü, laboratuvar güvenliği | Basitleştirilmiş sanal tesis + çok ölçütlü karar |

**Önerilen geliştirme önceliği:** önceden onaylı [FIRST_MISSIONS.md](FIRST_MISSIONS.md) görevlerini tamamladıktan sonra kimyada K20 → K22 → K07. Bu üçlü, birbirini tekrar etmeyen üç öğretim biçimini gösterir: laboratuvar gözlemi, fiziksel parametre simülasyonu, uzaysal molekül modeli.

## 11. Kaynakça ve doğrulama statüsü

**Birincil program/sınav kaynakları**

1. [MEB TTKB — 2026 YKS konu ve kazanımları](https://ttkb.meb.gov.tr/www/osym-tarafindan-2026-yilinda-gerceklestirilecek-quotyuksekogretim-kurumlari-sinavi-yksquotna-esas-derslere-ait-konu-ve-kazanimlar/icerik/831/tr).
2. [MEB OGM — 2026–27 TYMM uygulaması ve taslak yıllık planlar](https://ogm.meb.gov.tr/www/2026-2027-egitim-ogretim-yili-turkiye-yuzyili-maarif-modeli-taslak-cerceve-planlar-yayimlandi/icerik/2633).
3. [MEB TYMM — Kimya öğretim programı 9–12](https://tymm.meb.gov.tr/ogretim-programlari/ders/kimya-dersi); her sınıf/tema bağlantısı 2. bölümde.
4. [MEB — 2028 YKS yeni müfredata uygun soru modeli duyurusu](https://www.meb.gov.tr/yks-ve-lgsde-yeni-mufredata-uyumlu-soru-modeli-2028de-hayata-gececek/haber/39265/tr).

**Konu sıra ve etkinlik referansları**

5. [MEB OGM — 11. sınıf eski konu sırası](https://ogmmateryal.eba.gov.tr/dersler-cepte-fasikul?d=46&k=0&s=8&u=0).
6. [MEB OGM — 12. sınıf eski konu sırası](https://ogmmateryal.eba.gov.tr/dersler-cepte-fasikul?d=47&k=0&s=9&u=0).
7. [MEB OGM — 12. sınıf beceri temelli etkinlikler](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/beceri_temelli/pdf/12/kimya.pdf).

**Doğrulama statüsü:** Resmî ders başlıkları ve TYMM tema/kazanım örnekleri yukarıdaki MEB kaynaklarıyla temellendirilmiştir. **41 deney grubu, 82 modelleme fikri, 17 istasyon adı, hikâyeler ve kabul testleri bu raporun ürün önerileridir.** YKS 2027'nin bağımsız konu listesi, fen lisesine özgü bütün yıldızlı uygulamalar ve laboratuvar deneylerinin tek tek zorunluluk statüsü ayrıca doğrulanmadan 'tam resmî envanter' olarak sunulmamalıdır.

---

### PR inceleme kontrol listesi

- [x] Mevcut Glitch Academy oyun döngüsüyle uyumlu rapor oluşturuldu.
- [x] Eski TYT/AYT sırası ile TYMM programları ayrıldı.
- [x] 41 grup × 2 fikir = 82 farklı model önerisi listelendi.
- [x] 17 kimya istasyonu sıralandı.
- [x] En az 3 istasyon için deney ve öğrenme akışı yazıldı.
- [x] Bilimsel hata ve güvenlik riskleri görünür kılındı.
- [ ] Kimya öğretmeniyle kazanım bazlı içerik incelemesi.
- [ ] 3B sahne/oynanış prototipleri.
- [ ] Gerçek kullanıcı öğrenme testi ve ölçümler.
