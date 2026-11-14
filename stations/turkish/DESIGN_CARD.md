# Bozuk Talimat

Rota ve kazanım: LGS 8. sınıf Türkçe — paragrafta iddia, dayanak, çıkarım ve bağlamı yorumlama. Kaynak: [MEB 8. sınıf Türkçe örnek soruları](https://odsgm.meb.gov.tr/www/8-sinif-turkce-unitelendirilmis-ornek-sorular/icerik/678).

Kafa: Kaynak.

Yanılgı: Bir cümlenin anlamı bağlamdan ve olumsuzluk ifadesinden bağımsızdır.

Bozuk ayar: Güvenlik talimatının anlam bağlantısı; MERİDYEN “kapıyı açık bırakmayın” kaydını ters yorumlar.

Ters çalışma: Tahliye yolu kapanır, saha ekibi güvenli bölgeye ulaşamaz.

İlk 10 saniye: Çelişkili iki talimat ekranda belirir ve kapı yolu kapanır. Yönerge: “Kayıt hangi talimatın güvenli olduğunu kanıtlıyor?”

Ölçüm: Oyuncu kısa, özgün olay metninde iddia, bağlaç/olumsuzluk ve dayanak cümlesini işaretler; metin oyuna özgüdür, gerçek kaynak alıntısı değildir.

Güçler: Sar, Yavaşlat, Gör. Ayır kullanılmaz.

Teşhis kanıtı: Olay kaydı ile komut fişindeki anlam çelişkisini eşleştir.

Düzelt: İddia ile kanıtın anlam yönünü ve güvenli eylemi birlikte düzelterek komut fişini mühürle.

Toparla: Kişi ve yer bilgileri değiştirilmiş yeni bir kısa metinde aynı çıkarımı kur; üç sınırlı hak, yanlış işarette yanlış kapı açılır.

Doğru/yanlış tablosu: Bağlamla tutarlı çıkarım doğru yolu açar; bağlam dışı veya olumsuzluğu atlayan seçim kapıyı kapatır. Geri bildirim hangi anlam ilişkisinin uyuşmadığını söyler, cevabı vermez.

Varlıklar: Mevcut güvenlik kapısı dioraması, metin fişi ve kanıt işaretleyicisi.

## 3D uygulaması (14 Kasım 2026)

Ortak `lgs_story_stage_3d.gd`, ayrı `experiment_3d.tscn` dünyasında göreve özel meshler kurar. Doğru onarım kapıyı menteşesinden açar, sevkiyatı teslim alanına taşır veya destek paketini ihtiyaç noktasına ulaştırır. Yanlış denemede fiziksel düzenek kapanır ya da teslimat yanlış noktada kalır. Mevcut kanıt, düzeltme, yeni durum ve üç hak akışı korunur. Fare ve klavye kamera kontrolleri vardır.
