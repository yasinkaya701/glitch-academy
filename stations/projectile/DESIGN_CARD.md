# Atış Alanı

Rota ve kazanım: Sınıflar, 11. sınıf Fizik. Yatay ve düşey hareketlerin bağımsızlığı. Kazanım kapsamı mevcut `*_sim.gd` ve proje müfredatından korunur; sınav sırasına ekleme yapılmaz.

Kafa: ölçüm.
Yanılgı ve bozuk ayar: MERİDYEN kontrol modeli “Yatay hız arttıkça düşüş süresi uzar”. Dünya fiziği doğru çalışır; kontrolcü yanlış tahminle hedefi kaçırır.
İlk 10 saniye: Arızalı plaka, hedef çizgisi ve gerçekleşen hareket aynı sahnede görünür. Tek eylem “Nedenini bul”.
Ölçüm: Aynı 45 m yükseklikte 10 ve 20 m/s atış karşılaştırılır; süre ve menzil ölçülür. Ölçümler koşu bitmeden kayda geçmez.
Teşhis kanıtı: İki ölçüm fişi bozuk kontrol satırına taşınır; klavyeyle fişi seçip “Kanıtı uygula” aynı işi yapar.
Düzelt: Oyuncu kuralı kendi yazar: t = √(2h/g). Sağlam ayarla aynı hareket tekrar oynar; tahmin ve ölçüm eşleşir.
Toparla: 80 m yükseklikten 64 m uzaktaki halkaya atış hızını kur; ardından 20 m yükseklikten 30 m hedefini vur. Önceden sonuç veya yörünge verilmez. Üç ortak hak; bitince tüm kanıtlar silinerek krize dönülür.
Güçler: Sar koşuyu başa alır, Yavaşlat süreyi değil görsel oynatımı değiştirir. Toparla sırasında harcanan hak geri gelmez.
Doğru/yanlış: Boş veya aralık dışı giriş gönderilmez. Yanlış sayıda verilen ayar gerçekten çalışır, hedef kaçırılır; iki yeni durum başarıyla tamamlanmadan `completed` çıkmaz.
Varlıklar: İstasyonun mevcut arka planı ve ayrı nesne PNG'leri kullanılır. Yeni harici varlık yok.

Bu kart, mevcut deneyleri onarım ve bağımsız uygulamayla düzeltme isteği kapsamında uygulanmıştır.
