# Yanlış Dünya Sınıf Sohbetleri

[Fikir Meydanı – Felsefe](https://yanlis-dunya-sinif-sohbetleri.vercel.app/felsefe), [Zaman Arşivi – Tarih](https://yanlis-dunya-sinif-sohbetleri.vercel.app/tarih) ve [Coğrafya Atlası](https://yanlis-dunya-sinif-sohbetleri.vercel.app/cografya) doğrudan figürle sohbeti açar ve sınıfın ortak ekranında çalışır. Oyun kuralları her iki dersin üst menüsünde bulunur.

- **Serbest sohbet.** Bir YKS ünitesi seçin ve figüre doğrudan sorun. Düşünürler görüşlerini ve karşı örnekleri tartışır. Tarihî figürler olayları kronoloji ve dönemlerinin toplumsal yaşamıyla ilişkilendirir. Mikrofona basıp konuştuğunuzda kısa bekleme aralığı kaydı bitirir. Yanıtı cihazın Türkçe tarayıcı sesi okur ve figürün ağzı okuma sırasında hareket eder. Yarışmada sesle yazılan yanıtı göndermeden önce kontrol edebilirsiniz.
- **Yarışma.** Aynı sohbet ekranında figür iki takıma sırayla soru sorar ve yanıtını kendi üslubuyla değerlendirir. Ana fikir 5, doğru ve gerekçeli yanıt 10 puan. Figür doğru ve yeni hafıza bilgisi başına 5 puan verir, o bilgiyi sonraki konuşmaya taşır.
- **Üniteler.** [MEB 2026 YKS başlıkları](https://ttkb.meb.gov.tr/meb_iys_dosyalar/2025_11/26164023_2026_yks.pdf) 9 felsefe, 26 tarih/inkılap ve seçilmiş 7 coğrafya kartına bağlanır. Her kart üniteden bir öğrenme örneği, bir figür ve iki soru içerir.
- **Veri.** Takım adları ve puanlar sekmede tutulur. Girilen sorular, yarışma yanıtları ve hafıza notları yanıt üretmek için modele gönderilir. Kısa ses kayıtları aynı alan adındaki `/api/transcribe` üzerinden işlenir ve kalıcı olarak saklanmaz. Desteklenmeyen eski cihazlarda tarayıcının ses tanıma seçeneği kullanılabilir.

## Doğrulama ve yayın

Bu dizinde Node.js 22 ile `npm test` çalıştırılır. Vercel statik dosyaları sunar ve aynı alan adındaki `/api/chat` işlevi sohbeti aktarır. Cloudflare Worker, Vercel üzerinden çağrılan Gemma 4 yedeğini ve bağımsız bir yedek siteyi sunar.

1. Cloudflare Worker için bu dizinde `wrangler deploy` çalıştırın. Vercel’de gerekirse `BACKUP_ORIGIN` değişkenini yayınlanan Worker adresiyle ayarlayın.
2. Vercel projesini bu dizine bağlayıp `vercel deploy --prod` çalıştırın. `public/` çıktısı ile Frankfurt bölgesi `vercel.json` içinde ayarlıdır.
3. Vercel üretim işlevi GPT-6 Luna için Vercel OIDC kullanır. AI Gateway erişimi hazır olduğunda yeni sohbette kaynak etiketi **GPT-6 Luna** görünür. Uygun bir OpenAI projesi anahtarını Vercel’de sunucu sırrı olarak `OPENAI_API_KEY` adıyla eklemek doğrudan API yolunu açar. Anahtarı kaynak koduna veya tarayıcıya koymayın.
4. Gateway erişimi yoksa Gemma 4 yanıtları kaynak etiketiyle görünür. İki sağlayıcı da yanıt veremezse sohbet ünitenin **Hazır tartışma kartı**na döner. Yarışmada aynı yanıt yeniden gönderilebilir veya puansız geçilebilir. Değerlendirilmemiş tur kaldığında kazanan ilan edilmez.

Başarı ve gecikme kontrolü için ayrı ders bağlantılarını taze tarayıcıda açın. Felsefede güncel bir örnek ve takip sorusu, tarihte kronoloji ve toplumsal etki sorun. Sonuçta yanıtın kaynak etiketini ve doğru zamanda ulaştığını kontrol edin.

## Yanlış Dünya sahneleri

**Figürler** menüsündeki 14 karakterin görselleri ve mekânları özgün Godot istasyonlarından gelir. Aynı figürler serbest sohbette ve takım yarışmasında kullanılır. Felsefe figürleri düşünürken ve konuşurken istasyonun mimik karelerini kullanır. Tarih figürlerinin ağız katmanlarını yenilemek için `python3 tools/export_history_motion.py` çalıştırılır. YKS ünitelerinde ayrıca özgün kadronun dışındaki profiller seçilebilir.

WebP dosyalarını özgün istasyon kaynaklarından yeniden çıkarmak için Pillow ile `python3 tools/export_stage_art.py --source /yanlis-dunya-deposu` çalıştırılır. Canlı sahneler sürümlenen `public/stage/` dosyalarından yüklenir.

Coğrafya atlasında kullanılan uydu görseli [NASA/GSFC Scientific Visualization Studio, Blue Marble](https://svs.gsfc.nasa.gov/2915/) kaynağından alınmıştır.
