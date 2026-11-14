# Son Mesaj

Rota ve kazanım: LGS 8. sınıf İngilizce — günlük bağlamda okuma/dinleme, iletişim amacını ve uygun yanıtı çıkarma. Kaynak: [MEB 8. sınıf İngilizce ünitelendirilmiş örnek sorular](https://odsgm.meb.gov.tr/www/8-sinif-ingilizce-unitelendirilmis-ornek-sorular/icerik/673) ve [2026 LGS örnek soru duyurusu](https://odsgm.meb.gov.tr/www/lgs039ye-yonelik-birinci-ornek-soru-kitapciklari-mebi039de-yayimlandi/icerik/1512).

Kafa: Kaynak.

Yanılgı: Tek bir tanıdık kelime, iletinin tüm amacını belirlemeye yeter.

Bozuk ayar: Telsiz yanıtlayıcısı, mesajın bağlamını atıp anahtar kelimeye göre yanıt yollar.

Ters çalışma: Yardım ekibi yanlış malzemeyi alır ve köprü kontrol noktasında bekler.

İlk 10 saniye: Telsiz kaydı okunur/çalınır, yanlış yanıt gider ve görev ekranında yardım ekibinin yanlış konumu görünür. Yönerge: “İsteği, gerekçeyi ve doğru yanıtı kayıttan eşleştir.”

Ölçüm: Oyuncu üç özgün kısa mesajdaki amaç ve bağlam ipuçlarını transkript şeridinde işaretler; İngilizce metin oyuna özgüdür.

Güçler: Sar, Yavaşlat, Gör. Ayır kullanılmaz.

Teşhis kanıtı: Mesaj, bağlam notu ve yanıtın iletişim amacına göre eşleşmesi.

Düzelt: Telsiz ayarını anahtar kelime yerine tüm mesaj ve bağlamı kullanacak şekilde değiştir.

Toparla: Yeni bir kısa mesajda isteği ve uygun yanıtı eşleştir; üç sınırlı hak, yanlış yanıt ekipte gözle görülür gecikme yaratır.

Doğru/yanlış tablosu: Bağlamla uyumlu yanıt yardım ekibini doğru noktaya taşır; anahtar kelimeye dayanan yanıt yanlış noktaya gönderir. Geri bildirim anlamı açıklar ama doğru seçeneği işaretlemez.

Varlıklar: Mevcut telsiz istasyonu dioraması, transkript şeridi ve frekans kontrolü.

## 3D uygulaması (14 Kasım 2026)

Ortak `lgs_story_stage_3d.gd`, ayrı `experiment_3d.tscn` dünyasında göreve özel meshler kurar. Doğru onarım kapıyı menteşesinden açar, sevkiyatı teslim alanına taşır veya destek paketini ihtiyaç noktasına ulaştırır. Yanlış denemede fiziksel düzenek kapanır ya da teslimat yanlış noktada kalır. Mevcut kanıt, düzeltme, yeni durum ve üç hak akışı korunur. Fare ve klavye kamera kontrolleri vardır.
