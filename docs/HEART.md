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

Gerçekçi görsel hazır modelden gelir (`stations/heart/assets/model/heart_cutaway_light.glb`, CC0). Model tek parça ve tek malzeme, kapakçıklar ayrı düğüm değil, topolojiyle ayrılamıyor. Oyuncunun yaptığı iş bu yüzden modelin üstündeki etkileşim katmanında yaşar:

- Dört kapak yuvası ve oyuncunun yerleştirdiği kapakçık parçaları Godot'ta ayrı `Node3D` olarak, model koordinatında kurulur (açık ve kapalı animasyon, hasarlı hâl).
- Akış parçacıkları kalbin içinde sabit yollar boyunca ilerler. Geri kaçışta ters döner. Oksijen düzeyi renkle ve etiketle.
- Damar uçları tıklanabilir bağlantı noktalarıdır. Oyuncu yolu bağlar, tam tur kapanınca oksijen vücuda ulaşır.
- Model koordinatı: boyut yaklaşık 0,083 × 0,13 × 0,07 birim, merkez (0, 0,065, 0).
