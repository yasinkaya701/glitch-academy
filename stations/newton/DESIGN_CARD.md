# Newton Kızağı

Rota ve kazanım: Sınıflar, 11. sınıf Fizik. Sabit kuvvet altında ivme ve kütle ilişkisi. Kazanım kapsamı mevcut `*_sim.gd` ve proje müfredatından korunur; sınav sırasına ekleme yapılmaz.

Kafa: ölçüm.
Yanılgı ve bozuk ayar: MERİDYEN kontrol modeli “Kütle ivmeyi değiştirmez; a = F”. Dünya fiziği doğru çalışır; kontrolcü yanlış tahminle hedefi kaçırır.
İlk 10 saniye: Arızalı plaka, hedef çizgisi ve gerçekleşen hareket aynı sahnede görünür. Tek eylem “Nedenini bul”.
Ölçüm: Aynı 8 N kuvvetle 1 kg ve 4 kg kızak çalışır. Süreler cihazdan okunur. Ölçümler koşu bitmeden kayda geçmez.
Teşhis kanıtı: İki ölçüm fişi bozuk kontrol satırına taşınır; klavyeyle fişi seçip “Kanıtı uygula” aynı işi yapar.
Düzelt: Oyuncu kuralı kendi yazar: a = F / m. Sağlam ayarla aynı hareket tekrar oynar; tahmin ve ölçüm eşleşir.
Toparla: 6 kg kargoyu 40 m uzaktaki kapıya 4 s içinde ulaştıracak kuvvet; ardından 3 kg kargoyu 18 m boyunca 3 s içinde taşı. Önceden sonuç veya yörünge verilmez. Üç ortak hak; bitince tüm kanıtlar silinerek krize dönülür.
Güçler: Sar koşuyu başa alır, Yavaşlat süreyi değil görsel oynatımı değiştirir. Toparla sırasında harcanan hak geri gelmez.
Doğru/yanlış: Boş veya aralık dışı giriş gönderilmez. Yanlış sayıda verilen ayar gerçekten çalışır, hedef kaçırılır; iki yeni durum başarıyla tamamlanmadan `completed` çıkmaz.
Varlıklar: İstasyonun mevcut arka planı ve ayrı nesne PNG'leri kullanılır. Yeni harici varlık yok.

Bu kart, mevcut deneyleri onarım ve bağımsız uygulamayla düzeltme isteği kapsamında uygulanmıştır.
