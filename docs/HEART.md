# Kalp Odası · Öğrenme akışı

Oyuncu sanal bir insan modeline oksijen taşınmasını geri kazandırır. AYT görevinde kalbin yapısını ve çalışmasını, kapakçıkların tek yönlü akıştaki rolünü ve küçük ile büyük kan dolaşımını öğrenir. Sınıf keşfi, seçilen programın düzeyine uygun bir dolaşım modeli kullanır.

## Oynanış

1. **Yapıyı tanı.** Şematik kesitte sağ ve sol kulakçığı, sağ ve sol karıncığı seç. Üst ve alt ana toplardamarı, akciğer atardamarını, akciğer toplardamarlarını ve aortu bağla. Modeldeki sağ ve sol yönler anatomik olarak etiketlenir.
2. **Dolaşımı kur.** Oksijence fakir kan, vücuttan ana toplardamarlarla sağ kulakçığa ve sağ karıncığa gider. Akciğer atardamarı kanı akciğere taşır. Oksijence zengin kan, akciğer toplardamarlarıyla sol kulakçığa ve sol karıncığa gelir. Aort, kanı vücuda taşır. Oyuncu akış oklarından atardamarın kalpten uzaklaştığını, toplardamarın kalbe döndüğünü görür. Oksijen düzeyi renk ve metinle görünür.
3. **Pompayı çalıştır.** Triküspit sağ, mitral sol kulakçık ve karıncık arasına yerleşir. Pulmoner kapak sağ karıncığın, aort kapağı sol karıncığın çıkışındadır. Oyuncu dolum, basınç geçişi ve kanın atılması adımlarını ilerletir. Basitleştirilmiş modelde kapaklar basınç farkıyla açılır veya kapanır. Oyuncu tek tek kapakları zamanlamaz, yerleşimi ve arıza durumunu düzeltir.
4. **Arızayı teşhis et.** İlk örnekte sol karıncık kasılırken mitralden sol kulakçığa geri kaçış görünür. Bağımsız uygulamada açık takılan aort kapağı, gevşeme sırasında aorttan sol karıncığa ters akış oluşturur. Oyuncu akış ve pompa evresini gözleyip doğru kapağı onarır.
5. **Sonucu doğrula.** İki dolaşım yolu tamamlanır, ters akış durur ve oksijence zengin kan vücut dokularına ulaşır. Vücut paneli, birim içermeyen oyun göstergesiyle oksijen iletimindeki toparlanmayı gösterir.

## Kabul ölçütleri

- Öğrenci bir damarı akış yönünden tanır ve akciğer damarlarında oksijen düzeyini doğru yorumlar.
- Yanlış kapak veya ters bağlantı, ilgili akışın durmasına ya da geri kaçışa yol açar. Geri bildirim yönü ve evreyi gösterir.
- Rehberli örneğin ardından yeni arıza gerekçeli olarak onarılır. Başarı iki döngünün ve dokuya oksijen iletiminin modelde çalışmasına bağlıdır.
- Görsel kontrol dört odacığı, dört kapakçığı ve ana damarları ayrı etiketlerle doğrular. Akış animasyonu, görev kurallarıyla aynı veriyi kullanır.

[MEB kalp anatomisi](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/biyoloji/11/unite1/bolum4567/files/basic-html/page4.html), [MEB kalp döngüsü](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/konu-pekistirme/ayt/biyoloji/files/basic-html/page80.html), [ÖSYM 2026 AYT Fen, soru 32](https://dokuman.osym.gov.tr/pdfdokuman/2026/yks/tsk/yks_ayt_2026_kitapcik_kt12.pdf)

## Uygulama notu · hazır model ve etkileşim katmanı

Gerçekçi kalp görseli hazır modelden gelir (`stations/heart/assets/model/heart_cutaway.glb`, CC0). Kalp tek parça olsa da kapak modelleri etkileşim katmanında ayrı GLB varlıklarıdır (`stations/heart/assets/segmented/valves/`); odacık ve damar müdahaleleri sahne üstündeki etkileşim katmanında kalır:

- Dört kapak varlığı ayrı yaprakçık, annulus ve destek parçalarına sahiptir. Triküspit ve mitral modellerde kordatlar ile papiller kaslar da bulunur. Yaprakçıklar sahnede açılma animasyonu alır.
- Dolaşım görünümünde `assets/segmented/blood/red_blood_cell.glb` eritrosit modeli akış doğrultusunda döner. Oksijence fakir ve zengin kan, koyu bordo ile canlı kırmızı tonları ve metinle ayrılır.
- Akış parçacıkları kalbin içinde sabit yollar boyunca ilerler. Geri kaçışta ters döner. Oksijen düzeyi renkle ve etiketle.
- Dış dolaşım damarları gövde ve akciğer GLB'lerinin yüzey noktalarına oturur; uçları doku içine hafifçe girer ve ana çaplarından yumuşakça daralır. Gövdeye giden aort ve ana toplardamar yolları kesişmeyecek yüksekliklerde kıvrılır. Büyük metal kelepçeler yerine küçük, doku tonunda bağlantı halkaları kullanılır.
- Damar uçları tıklanabilir bağlantı noktalarıdır. Oyuncu yolu bağlar, tam tur kapanınca oksijen vücuda ulaşır. İşaretçiler yalnız bağlantı etkileşimi sırasında görünür.
- Gövde ve akciğer port merkezleri, iç içe model dönüşümleri hesaba katılarak gerçek mesh üçgenlerine izdüşürülür; portlar yüzeyden 2 mm dışarı yerleştirilir. Böylece damar ağızlarında görünür boşluk kalmaz.
- Damarı sürüklerken mevcut bağlantı bırakılana kadar korunur. Boş hedefe bırakma bağlantıyı taşır; dolu giriş reddedilir ve eski yol yerinde kalır. Shift+tık bağlantıyı söker; son yol sökülünce pompa durur.
- Aort kapağı müdahalesinde arızalı parça sahneden ve yuvasından çıkarılır. Yeni aort kapağı yönü kontrol edilerek takılır ve bir tam pompa atımıyla sınanır; yalnız başarılı akışta görev sonraki adıma geçer.
- Akciğer GLB'sinin renk atlası kalp sahnesinde mozaik yamalara dönüştüğü için yalnız bu sahne örneğinde metalik olmayan, mat akciğer dokusu malzemesi kullanılır.
- Kalp görevinin özel HUD'si aşama ve yönergeyi üstte, kontrolleri üst sağda, araçları alt dock'ta toplar; diğer görevlerin ortak HUD düzeni değişmez.
- HUD 640×480, 800×600, 1024×720 ve 1280×720 görünümlerinde sınanır. Dar ekranda tanı yönergesi kontrollerin altına alınır; araç ve soru satırları yatay kaydırılır.
- Tıklanabilir hedefler 3B görünümün üstündeki ayrı bir üst katmanda çizilir (üst Control'ün çizimi SubViewport'un altında kalır). Şekil anlam taşır: odacık ve damar bölgesi daire, kapak yuvası ok işaretli kare, damar çıkışı baklava, damar girişi çerçeveli nokta.
- Kapak ters, yanlış yuvada ya da kusurluysa kan o kapağın önündeki odacıkta birikir: odacık şişer, nabız gibi atar, kırmızı halka ve "Kan birikti" etiketi çıkar. Sonuç pompa durduktan sonra da 6 sn görünür kalır; yeni pompa denemesinde silinir. Doku oksijeni göstergesi, görünüm örtülmesin diye başın üstü yerine ayak hizasındadır.
- Başlık paneli 700 px altı dar ekranda kontrollerin altına yığılır; daha geniş ekranda (%130 yazı boyutu dahil) kontrollerin soluna oturur. Uyarı satırı panele binmez.
- Model koordinatı: boyut yaklaşık 0,083 × 0,13 × 0,07 birim, merkez (0, 0,065, 0).
