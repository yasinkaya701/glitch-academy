# Mevsim Gözlemevi

Rota ve kazanım: LGS Fen Bilimleri, F.8.1.1.1 · Mevsimlerin oluşumu ve Dünya'nın hareketleri. Bu kod `mission.tres` içindeki mevcut 2026–2027 LGS eşlemesidir; yeni öğretim programı kodu değildir. [MEB 8. sınıf Fen Bilimleri örnek soruları](https://odsgm.meb.gov.tr/www/8-sinif-fen-bilimleri-unitelendirilmis-ornek-sorular/icerik/676), [NASA · Seasons](https://science.nasa.gov/helio-and-you-seasons-on-earth-mars-and-beyond/).

Kafa: ölçüm.

Yanılgı: Mevsimlerin nedeni Dünya'nın Güneş'e olan uzaklığıdır. Tasarım dayanağı: [GAME_DESIGN.md · Coğrafya](../../docs/GAME_DESIGN.md). NASA'nın eğitim kaynağı mevsimleri eksen eğimi ve yörünge boyunca değişen yönelimle ilişkilendirir.

Bozuk ayar: Kontrol ayarı. Kalibrasyon plakası “Mevsim kaynağı: Dünya-Güneş uzaklığı” gösterir.

Ters çalışma: Mevsim uyarısı iki yarımküreye uzaklığa göre gönderilir. Güney serası 21 Aralık'ta kış uyarısı aldığı için havalandırmayı kapatır ve sıcaklık alarmı yükselir.

İlk 10 saniye: Sera alarmı ve kapalı havalandırma görünür. Yönerge “Güney serası neden kış uyarısı aldı?” Kriz en çok 7 saniye oynar ve atlanabilir.

Ölçüm: 21 Haziran ve 21 Aralık'ta, 40° kuzey/güney için gündüz süresi. Tarih dışında enlem ve eksen açısı sabittir. Model iki yörünge konumunu Güneş'e eşit uzaklıkta gösterir.

Güçler: Sar ve Gör. Ayır/Yavaşlat bu kısa LGS denemesinde kullanılmaz.

Teşhis kanıtı: İki gündönümünün gündüz kayıtlarını “mevsim kaynağı: uzaklık” satırına sürükle. Eşit yörünge uzaklığına rağmen karşıt yarımküre ölçümleri değişir.

Düzelt: Kalibrasyon plakasındaki mevsim kaynağını “eksen eğimi”ne al. Modelin ışın açıları ve gündüz kayıtlarıyla uyarılar tutarlı hâle gelir.

Toparla: 21 Haziran'da yeni enlemlerde (50° kuzey/güney) gündüz ölçümlerini oku. Kuzeye yaz, güneye kış uyarısı gönder. Üç hak vardır; yanlış eşleştirmede sera alarmı yükselir, haklar biterse kriz baştan oynatılır.

Doğru/yanlış tablosu:

| Girdi | Sahne sonucu | Neden |
|---|---|---|
| Mevsim kaynağı “uzaklık” | Güney serasına yanlış kış uyarısı gider | Aynı yörünge uzaklığı yarımküre mevsimlerini açıklamaz |
| Kayıtlar plakaya bırakılır | Mühür açılır | Gündüz süresi iki yarımkürede farklılaşır |
| Mevsim kaynağı “uzaklık” olarak bırakılır | Mühür açılmaz | Kural ölçüm kayıtlarıyla çelişiyor |
| Mevsim kaynağı “eksen eğimi” yapılır | Uyarı kuralı ölçümlerle tutarlı çalışır | Eksenin Güneş'e yönelmesi ışın açısını değiştirir |
| Haziran'da kuzey kış / güney yaz | Uyarı yanlış gider, sera alarmı yükselir | Mevsim eşleştirmesi ters |
| Haziran'da kuzey yaz / güney kış | Sera havalandırması açılır; mühür ekranı gelir | Eksen eğimi iki yarımkürede ters mevsimler oluşturur |

Varlıklar: Var olan 3D yörünge/sera sahnesi ve `seasons_model.gd`; yeni harici varlık gerekmez.
