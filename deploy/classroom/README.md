# Yanlış Dünya Sınıf Sohbetleri

[Fikir Meydanı – Felsefe](https://yanlis-dunya-sinif-sohbetleri.vercel.app/felsefe) ve [Zaman Arşivi – Tarih](https://yanlis-dunya-sinif-sohbetleri.vercel.app/tarih) doğrudan figürle sohbeti açar ve sınıfın ortak ekranında çalışır. Oyun kuralları her iki dersin üst menüsünde bulunur.

- **Serbest sohbet.** Bir YKS ünitesi seçin ve figüre doğrudan sorun. Düşünürler görüşlerini ve karşı örnekleri tartışır. Tarihî figürler olayları kronoloji ve dönemlerinin toplumsal yaşamıyla ilişkilendirir. Destekleyen tarayıcılarda sesle yazdırabilir ve son figür mesajını sesli dinleyebilirsiniz.
- **Yarışma.** Aynı sohbet ekranında figür iki takıma sırayla soru sorar ve yanıtını kendi üslubuyla değerlendirir. Ana fikir 5, doğru ve gerekçeli yanıt 10 puan. Figür doğru ve yeni hafıza bilgisi başına 5 puan verir, o bilgiyi sonraki konuşmaya taşır.
- **Üniteler.** [MEB 2026 YKS başlıkları](https://ttkb.meb.gov.tr/meb_iys_dosyalar/2025_11/26164023_2026_yks.pdf) 9 felsefe ve 26 tarih/inkılap kartına bağlanır. Her kart üniteden bir öğrenme örneği, bir figür ve iki soru içerir.
- **Veri.** Takım adları ve puanlar sekmede tutulur. Girilen sorular, yarışma yanıtları ve hafıza notları yanıt üretmek için modele gönderilir. Sesle yazdırma için tarayıcı kendi ses tanıma hizmetini kullanabilir.

## Doğrulama ve yayın

Bu dizinde Node.js 22 ile `npm test` çalıştırılır. Vercel statik dosyaları sunar ve aynı alan adındaki `/api/chat` işlevi sohbeti aktarır. Cloudflare Worker, Vercel üzerinden çağrılan Gemma 4 yedeğini ve bağımsız bir yedek siteyi sunar.

1. Cloudflare Worker için bu dizinde `wrangler deploy` çalıştırın. Vercel’de gerekirse `BACKUP_ORIGIN` değişkenini yayınlanan Worker adresiyle ayarlayın.
2. Vercel projesini bu dizine bağlayıp `vercel deploy --prod` çalıştırın. `public/` çıktısı ile Frankfurt bölgesi `vercel.json` içinde ayarlıdır.
3. Vercel üretim işlevi GPT-6 Luna için Vercel OIDC kullanır. AI Gateway erişimi hazır olduğunda yeni sohbette kaynak etiketi **GPT-6 Luna** görünür. Uygun bir OpenAI projesi anahtarını Vercel’de sunucu sırrı olarak `OPENAI_API_KEY` adıyla eklemek doğrudan API yolunu açar. Anahtarı kaynak koduna veya tarayıcıya koymayın.
4. Gateway erişimi yoksa Gemma 4 yanıtları kaynak etiketiyle görünür. İki sağlayıcı da yanıt veremezse sohbet ünitenin **Hazır tartışma kartı**na döner. Yarışmada aynı yanıt yeniden gönderilebilir veya puansız geçilebilir. Değerlendirilmemiş tur kaldığında kazanan ilan edilmez.

Başarı ve gecikme kontrolü için ayrı ders bağlantılarını taze tarayıcıda açın. Felsefede güncel bir örnek ve takip sorusu, tarihte kronoloji ve toplumsal etki sorun. Sonuçta yanıtın kaynak etiketini ve doğru zamanda ulaştığını kontrol edin.
