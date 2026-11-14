# Üç Güneş (final)

Durum: ONAY BEKLİYOR. Onay gelmeden kod yazılmaz (AGENTS.md).

Rota ve kazanım: TYT, AYT, YDT ortak final. AYT Fizik 15, Kütle Çekim ve Kepler (docs/CURRICULUM.md, AYT 15). İki cisim yörüngesi Kepler'in üçüncü yasasıyla öngörülür; üç cisimde aynı başlangıç aynı sonucu verir, çok küçük bir ilk fark ise yörüngeleri ayırır. Anlatı: docs/STORY.md Perde 3, docs/GAME_DESIGN.md bölüm 10.

Kafa: ölçüm.

Yanılgı ve bozuk ayar: "Yeterince hassas ölçersem her sistemin geleceğini sonsuza dek hesaplayabilirim." MERİDYEN'in merkezi yetkisi bu inanca dayanır: belirsizliği ortadan kaldırarak Dünya'yı korumak. Bozuk ayar plakada durur: `ÖNGÖRÜ ufku = SINIRSIZ`. Kontrol ayarıdır; MERİDYEN üç cisim sisteminde de uzun vadeli yörünge tahmini yapar ve hedefi kaçırır.

Ters çalışma: MERİDYEN tahmini (yörünge 50 birim zaman boyunca çizgi çizgi tutacak) ↔ ölçülen (yaklaşık 12 birim zamandan sonra iki yörünge ayrılıyor). Kaybedilen şey: Misafirlere gönderilecek mühürlü yasa arşivi. Tahmin tutmazsa arşiv yanlış okunur ve kapı kapanır.

İlk 10 saniye: Gökte üç güneş. Arşiv kapsülü ile Misafir sinyali arasında MERİDYEN'in tahmin çizgisi uzun ve düzgün çiziliyor, gerçek iz ise bir noktada ondan kopuyor. Sahnede iki iz görünür, aralarındaki açılan makas kırmızıyla çizilir. Yönerge: "Tahmin ile ölçüm ne zaman ayrılıyor?"

Adımlar (GAME_DESIGN.md §10 ile uyumlu, her adım oyuncu girdisi ister):

1. **İki cisim, öngör.** Bir gezegen a = 1 yörüngesinde dönem T₀ ile dolanır. Oyuncu a = 4 yörüngesinin dönemini T² ∝ a³ ile hesaplar (beklenen 8 T₀) ve girer. Doğruysa yörünge o dönemle kapanır ve işaret çakışır. Yanlış girişte yörünge o dönemle çalışır, tam tur kapanmaz ve neden cümlesi görünür.
2. **Üç cisim, aynı başlangıç.** Oyuncu sistemi iki kez aynı koşulla başlatır, iki iz üst üste çakışır. Sistem deterministiktir.
3. **Üç cisim, küçük fark.** İkinci koşuya Δv eklenir. İzler bir süre birlikte gider, sonra ayrılır. Oyuncu ayrılma anını t* iki iz arası mesafe eşik ε'u geçtiği an olarak cihazdan okur. Δv'yi küçültünce t*'in uzadığını, ama hiçbir zaman sonsuza gitmediğini görür.
4. **Bağımsız uygulama.** Yeni bir sistem (a = 2,5 ve farklı Δv) verilir. Oyuncu iki şeyi kendi yapar: (a) iki cisim dönemini hesaplar (T = 2,5^1,5 ≈ 3,95 T₀), (b) verilen Δv için ayrılma anının MERİDYEN'in "sınırsız ufku"ndan çok önce geldiğini ölçerek kanıtlar. İpucu ve hazır sonuç verilmez.
5. **Karar ve mühür.** Ölçüm bir mühre dönüşür: "Öngörülemezlik de ölçülebilir." MERİDYEN'in merkezi yetkisi kalkar, mühürlenen yasalar Misafirlere onların ölçebileceği biçimde gönderilir. Kapanış zafer değil anlaşmadır: yasalar yerinde, kapı açık, MERİDYEN yetkisiz ama Gözlemevi'nde.

Ölçüm: oyuncu iki cihazdan okur. Dönem sayacından T, iz mesafe ölçerinden t*. Hesaplayacağı sayı (T veya t* karşılığı) ekranda canlı gösterilmez.

Güçler: Sar iki koşuyu başa alır ve aynı başlangıcı tekrarlar (tekrarlanabilirlik). Yavaşlat izin oluşumunu ¼ hızda gösterir, t* ölçümünü kolaylaştırır. Ayır üçüncü güneşin kütlesini sıfırlar: iki cisme dönülür ve tahmin tutar. Gör ivme okunu çizer.

Teşhis kanıtı: iki ölçüm fişi (aynı başlangıç → çakışma; Δv → ayrılma) plakadaki `ÖNGÖRÜ ufku = SINIRSIZ` satırını çürütür.

Düzelt: oyuncu ufku kendi ölçümünden yazar: `ufuk = t*` (birim zaman, ölçtüğü değer ± %10). Sağlam ayarla aynı sahne yeniden oynar: tahmin çizgisi t*'da kesilir ve gerçek iz ile çakışan kısım görünür.

Toparla: yeni sistem (adım 4), üç ortak hak. Yanlış hesap yanlış dönemle çalışan bir yörünge demektir (ör. 4,0 girilirse tur erken kapanır, 3,95 yerine). Haklar bitince iz silinir, sahne krize döner; harcanan hak geri gelmez.

Doğru/yanlış tablosu:

| Giriş | Sahnede ne olur | Neden cümlesi (≤ 60 karakter) |
|---|---|---|
| T = 8 (a = 4) | Gezegen tam turu kapatır, işaret çakışır | Kepler: T² ∝ a³. |
| T = 4 (a³ yerine a²) | Tur kapanmaz, gezegen geride kalır | Üssü a³ alınır, a² değil. |
| T = 16 (a⁴ gibi) | Gezegen turu bitirip bekler | Dönem a'nın 3/2 kuvvetidir. |
| ufuk = t* ± %10 | Tahmin çizgisi kesilir, gerçek iz ile çakışır | Ayrılma anında öngörü biter. |
| ufuk = 50 (sınırsız) | Çizgi iz ile ayrılır, hedef kaçar | Küçük fark zamanla büyür. |
| Boş veya aralık dışı | Gönderilmez | Bir sayı gir. |

Varlıklar: üç küre (Güneş dokusu stations/seasons/assets/sun_photosphere_4k.jpg yeniden kullanılır, üç farklı renk tonu), iz için ImmediateMesh veya Line3D, yıldız tozu (MultiMesh), Gözlemevi konsolu paneli (mevcut UI teması). Yeni harici varlık talebi yok. Simülasyon mevcut stations/yks/three_body_model.gd; Δv, ε ve t* hesabı headless test edilir. Sahne 3B (Node3D + SubViewport), görev kontrolleri Control düğümleriyle.

Mevcut durum (denetim notu, 2026-11-14): çalışan sahne yalnız adım 2 ve 3'ü içerir, 2B çizgi grafiği olarak. Adım 1 (Kepler öngörüsü), ayrılma anı ölçümü, bağımsız uygulama, hak sınırı, arıza animasyonu ve kapanış diyalogu yok.

Açılış kuralı (karar bekliyor): bugün kod doğrulama kanıtına bakıyor (dört bağımsız ders doğrulaması ve biyoloji ya da arşiv onarımı, docs/STORY.md YKS Kampanyası). Kullanıcı "7 bölüm bitince" dedi. Seçenekler: (A) mevcut kanıt kuralı kalır, (B) rotadaki ilk yedi görev onarılınca açılır.
