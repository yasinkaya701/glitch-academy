# Çarpışma Hattı

Rota ve kazanım: Sınıflar, 11. sınıf Fizik. Bir boyutta momentumun korunumu ve yönü. Kazanım kapsamı mevcut `*_sim.gd` ve proje müfredatından korunur; sınav sırasına ekleme yapılmaz.

Kafa: ölçüm.
Yanılgı ve bozuk ayar: MERİDYEN kontrol modeli “Momentumlar yön gözetmeden büyüklükleriyle toplanır”. Dünya fiziği doğru çalışır; kontrolcü yanlış tahminle hedefi kaçırır.
İlk 10 saniye: Arızalı plaka, hedef çizgisi ve gerçekleşen hareket aynı sahnede görünür. Tek eylem “Nedenini bul”.
Ölçüm: 3 kg araba +2 m/s, 2 kg araba önce −1 sonra −2 m/s ile çarpışır. Yalnız B hızı değişir. Ölçümler koşu bitmeden kayda geçmez.
Teşhis kanıtı: İki ölçüm fişi bozuk kontrol satırına taşınır; klavyeyle fişi seçip “Kanıtı uygula” aynı işi yapar.
Düzelt: Oyuncu kuralı kendi yazar: p = m₁v₁ + m₂v₂. Sağlam ayarla aynı hareket tekrar oynar; tahmin ve ölçüm eşleşir.
Toparla: Yeni kütle ve hızlarda yakalayıcıyı ortak hıza kur; ikinci durumda yön değişsin. Önceden sonuç veya yörünge verilmez. Üç ortak hak; bitince tüm kanıtlar silinerek krize dönülür.
Güçler: Sar koşuyu başa alır, Yavaşlat süreyi değil görsel oynatımı değiştirir. Toparla sırasında harcanan hak geri gelmez.
Doğru/yanlış: Boş veya aralık dışı giriş gönderilmez. Yanlış sayıda verilen ayar gerçekten çalışır, hedef kaçırılır; iki yeni durum başarıyla tamamlanmadan `completed` çıkmaz.
Varlıklar: İstasyonun mevcut arka planı ve ayrı nesne PNG'leri kullanılır. Yeni harici varlık yok.

Bu kart, mevcut deneyleri onarım ve bağımsız uygulamayla düzeltme isteği kapsamında uygulanmıştır.
