# İlk üç deney

LGS, TYT ve AYT kendi konu sırasını izler. Her bölümde kısa ve atlanabilir bir arıza animasyonu, yönlendirmeli keşif, bağımsız uygulama ve gözle görülen onarım vardır. İlk sahne kurmaca arızayı açıkça gösterir. Son sahne oyuncunun girdisiyle aynı sistemi yeniden çalıştırır.

Bu üretim turunda üç Codex ajanı ayrı istasyon klasörlerinde çalışır. Codex varlık üretimini üstlenir. Claude sahneye bağlayacağı varlık için talep açabilir. Codex kotası dolarsa Gemini açık talebi devralır. [Varlık iş akışı](ASSETS.md)

## LGS Fen · Mevsim Gözlemevi

- **Arıza** · Gözlemevi iki yarımküreye aynı mevsim uyarısını yollar. Güneydeki sera kış ayarına geçer ve yaz koşullarında aşırı ısınır.
- **Deney** · Güneş ve Dünya modelinde eksenin yörünge boyunca uzaydaki yönü sabit kalır. Öğrenci Haziran ve Aralık konumları arasında geçer. Aynı enlemin iki yarımkürede ışın açısı ve gündüz süresi karşılaştırılır. Sabit enerjiyle ışın demeti daha geniş yüzeye yayıldığında birim alana düşen enerjinin azaldığı görünür.
- **Uygulama** · Aralık konumunda güney serasının yaz ayarını ve kuzey istasyonunun kış ayarını birlikte seç. Ters eşleştirme hatalı uyarıyı sürdürür. Doğru eşleştirme seranın yaz havalandırmasını devreye alır.
- **Kabul** · Haziran ve Aralık ters mevsim çiftlerini verir. Işın açısı ve gündüz süresi modelde birbiriyle tutarlıdır. F.8.1.1.1 hedefi Dünya'nın eksen eğikliği ve dolanma hareketiyle açıklanır. [MEB Fen Bilimleri programı](https://mufredat.meb.gov.tr/Dosyalar/201812312311937-FEN%20B%C4%B0L%C4%B0MLER%C4%B0%20%C3%96%C4%9ERET%C4%B0M%20PROGRAMI2018.pdf)

## TYT Fizik · Ölçüm Atölyesi

- **Arıza** · Kontrol cihazı santimetreyi metre olarak okur. Rayın bağlantı parçası yuvaya sığmaz ve taşıyıcı durur.
- **Deney** · Cetvelle uzunluğu, teraziyle kütleyi, sayaçla süreyi ölç. Bu temel büyüklükleri uygun SI birimleriyle eşleştir. Yol ve süreden ortalama sürati çıkar. Sürat göstergesi ve yönlü hız oku, skaler ve vektörel farkı aynı hareket üzerinde gösterir.
- **Uygulama** · 240 cm uzunluğundaki yeni parçayı metre cinsinden gir. 2,4 m bağlantıyı tamamlar. 24 m fiziksel olarak sığmaz. İkinci adımda 6 m yolu 3 s’de alan taşıyıcının ortalama süratini 2 m/s olarak gir.
- **Kabul** · Ondalık virgül ve nokta aynı değeri verir. Ölçüler, birimler ve sonuç animasyonu tutarlıdır. Yanlış değerle taşıyıcı çalışmaz. [MEB 9. sınıf Fizik Bilimine Giriş](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/beceri_temelli/9/fizik/files/basic-html/page29.html)

## AYT Fizik · Vektör Limanı

- **Arıza** · Yönler silindiği için kontrol cihazı iki yer değiştirmeyi yalnızca büyüklükleriyle toplar. Kargo kapsülü yanaşma noktasını kaçırır.
- **Deney** · Koordinat düzleminde bileşenleri, yönü ve büyüklüğü incele. 3 birim doğu ve 4 birim kuzey oklarını uç uca ekle. Aynı bileşkeyi paralelkenarla gör. Son nokta (3, 4), büyüklük 5 birimdir. Yer değiştirme ve alınan yolu ayrı göster.
- **Uygulama** · Yeni rota 5 birim doğu ve 12 birim güneye gider. Bileşke (5, −12), büyüklük 13 birimdir. Giriş doğrulandığında kapsül hedefe gider. Yanlış işaret kapsülü karşı tarafta bırakır.
- **Kabul** · İki çizim yöntemi aynı sonucu verir. Godot ekran koordinatlarına dönüşüm kuzey ve güneyi ters göstermez. Son görev bileşen, yön ve büyüklük doğrulandığında biter. [MEB AYT Fizik, vektörlerin bileşkesi](https://ogmmateryal.eba.gov.tr/panel/upload/etkilesimli/kitap/fizik/11/unite1/icerik/FI11S19/index.html)
