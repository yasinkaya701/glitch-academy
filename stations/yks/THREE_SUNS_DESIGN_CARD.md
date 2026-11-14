# Üç Güneş (final)

Durum: UYGULANDI (2026-11-14). Kullanıcı "devam edin, hepsini bitirin" dedi; kart onaylanmış sayıldı. Kod: stations/yks/three_suns.gd, three_suns_stage.gd, three_body_model.gd. Test: tests/three_suns_flow_test.tscn.

Rota ve kazanım: TYT, AYT, YDT ortak final. AYT Fizik 15, Kütle Çekim ve Kepler (docs/CURRICULUM.md, AYT 15). İki cisim yörüngesi Kepler'in üçüncü yasasıyla öngörülür; üç cisimde aynı başlangıç aynı sonucu verir, çok küçük bir ilk fark ise yörüngeleri ayırır. Anlatı: docs/STORY.md Perde 3, docs/GAME_DESIGN.md bölüm 10.

Kafa: ölçüm.

Yanılgı ve bozuk ayar: "Yeterince hassas ölçersem her sistemin geleceğini sonsuza dek hesaplayabilirim." MERİDYEN'in merkezi yetkisi bu inanca dayanır: belirsizliği ortadan kaldırarak Dünya'yı korumak. Bozuk ayar plakada durur: `ÖNGÖRÜ ufku = 8,0` (modelin bütün süresi). Kontrol ayarıdır; MERİDYEN üç cisim sisteminde de uzun vadeli yörünge tahmini yapar ve hedefi kaçırır.

Ters çalışma: MERİDYEN tahmini (yörünge 8 birim zaman boyunca çizgi çizgi tutacak) ↔ ölçülen (Δv'ye göre 1,6 ile 7 birim zaman arasında iki iz ayrılıyor). Kaybedilen şey: Misafirlere gönderilecek mühürlü yasa arşivi. Tahmin tutmazsa arşiv yanlış okunur ve kapı kapanır.

İlk 10 saniye: Gökte üç güneş. Arşiv kapsülü ile Misafir sinyali arasında MERİDYEN'in tahmin çizgisi uzun ve düzgün çiziliyor, gerçek iz ise bir noktada ondan kopuyor. Sahnede iki iz görünür, aralarındaki açılan makas kırmızıyla çizilir. Yönerge: "Tahmin ile ölçüm ne zaman ayrılıyor?"

Adımlar (GAME_DESIGN.md §10 ile uyumlu, her adım oyuncu girdisi ister):

1. **İki cisim, öngör.** Bir gezegen a = 1 yörüngesinde dönem T₀ ile dolanır. Oyuncu a = 4 yörüngesinin dönemini T² ∝ a³ ile hesaplar (beklenen 8 T₀) ve girer. Doğruysa yörünge o dönemle kapanır ve işaret çakışır. Yanlış girişte yörünge o dönemle çalışır, tam tur kapanmaz ve neden cümlesi görünür.
2. **Üç cisim, aynı başlangıç.** Oyuncu sistemi iki kez aynı koşulla başlatır, iki iz üst üste çakışır. Sistem deterministiktir.
3. **Üç cisim, küçük fark.** İkinci koşuya Δv eklenir. İzler bir süre birlikte gider, sonra ayrılır. Oyuncu ayrılma anını t* (iki iz arası en büyük mesafe d, eşik ε = 0,1'i geçtiği an) cihazdan okur, ±%12 ya da ±0,25 tolerans. Δv'yi en az %30 küçültüp yeniden ölçer: t* uzar, ama sınırsız olmaz. İki ölçüm doğrulanmadan ilerlenmez.
4. **Bağımsız uygulama.** Yeni bir sistem (a = 2,5 ve Δv = 0,030) verilir. Oyuncu iki şeyi kendi yapar: (a) iki cisim dönemini hesaplar (T = 2,5^1,5 ≈ 3,95 T₀), (b) verilen Δv için ayrılma anını ölçerek MERİDYEN'in 8,0'lık ufkunun içinde kaldığını kanıtlar. İpucu ve hazır sonuç verilmez.
5. **Karar ve mühür.** Ölçüm bir mühre dönüşür: "Öngörülemezlik de ölçülebilir." MERİDYEN'in merkezi yetkisi kalkar, mühürlenen yasalar Misafirlere onların ölçebileceği biçimde gönderilir. Kapanış zafer değil anlaşmadır: yasalar yerinde, kapı açık, MERİDYEN yetkisiz ama Gözlemevi'nde.

Ölçüm: oyuncu iki cihazdan okur. Dönem sayacından T, iz mesafe ölçerinden t*. Hesaplayacağı sayı (T veya t* karşılığı) ekranda canlı gösterilmez.

Güçler: Sar iki koşuyu başa alır ve aynı başlangıcı tekrarlar (tekrarlanabilirlik). Yavaşlat izin oluşumunu ¼ hızda gösterir, t* ölçümünü kolaylaştırır. Ayır ve Gör bu görevde yoktur: model denemesinde üçüncü güneşi sıfırlamak temiz bir iki cisim sistemi vermedi (bu başlangıç koşullarında iki cisim de sapıyor), bu yüzden "iki cisimde ayrılma yok" gibi yanlış bir anlatım kurulmadı. İki cismin öngörülebilirliği Kepler adımında gösterilir.

Teşhis kanıtı: iki ölçüm fişi (aynı başlangıç → çakışma; Δv → ayrılma) plakadaki `ÖNGÖRÜ ufku = 8,0` (modelin bütün süresi) satırını çürütür.

Düzelt: oyuncunun ölçtüğü t* MERİDYEN'in ufkunu çürütür; mühürde ufuk t* ile sınırlanır. (Uygulamada ufuk ayrıca bir giriş olarak istenmez; ölçüm kendisi düzeltmedir.)

Toparla: yeni sistem (adım 4), üç ortak hak. Yanlış hesap yanlış dönemle çalışan bir yörünge demektir (ör. 4,0 girilirse tur erken kapanır, 3,95 yerine). Haklar bitince iz silinir, sahne krize döner; harcanan hak geri gelmez.

Doğru/yanlış tablosu:

| Giriş | Sahnede ne olur | Neden cümlesi (≤ 60 karakter) |
|---|---|---|
| T = 8 (a = 4) | Gezegen tam turu kapatır, işaret çakışır | Kepler: T² ∝ a³. |
| T = 4 (a³ yerine a²) | Tur kapanmaz, gezegen geride kalır | Üssü a³ alınır, a² değil. |
| T = 16 (a⁴ gibi) | Gezegen turu bitirip bekler | Dönem a'nın 3/2 kuvvetidir. |
| t* doğru (±%12) | Ölçüm kayıtlı, sıradaki adım açılır | Ayrılma anında öngörü biter. |
| t* = 7,9 (süre sonu) | Ölçüm sayılmaz | İlk ayrıldığı anı oku (d > ε). |
| t* ayrılmadan önce | Ölçüm sayılmaz | Bu anda d henüz ε'un altında. |
| Boş veya aralık dışı | Gönderilmez | Bir sayı gir. |

Varlıklar: üç küre (Güneş dokusu stations/seasons/assets/sun_photosphere_4k.jpg yeniden kullanılır, üç farklı renk tonu), iz için ImmediateMesh veya Line3D, yıldız tozu (MultiMesh), Gözlemevi konsolu paneli (mevcut UI teması). Yeni harici varlık talebi yok. Simülasyon mevcut stations/yks/three_body_model.gd; Δv, ε ve t* hesabı headless test edilir. Sahne 3B (Node3D + SubViewport), görev kontrolleri Control düğümleriyle.

Mevcut durum (denetim notu, 2026-11-14): çalışan sahne yalnız adım 2 ve 3'ü içerir, 2B çizgi grafiği olarak. Adım 1 (Kepler öngörüsü), ayrılma anı ölçümü, bağımsız uygulama, hak sınırı, arıza animasyonu ve kapanış diyalogu yok.

Açılış kuralı (karar bekliyor): bugün kod doğrulama kanıtına bakıyor (dört bağımsız ders doğrulaması ve biyoloji ya da arşiv onarımı, docs/STORY.md YKS Kampanyası). Kullanıcı "7 bölüm bitince" dedi. Seçenekler: (A) mevcut kanıt kuralı kalır, (B) rotadaki ilk yedi görev onarılınca açılır.
