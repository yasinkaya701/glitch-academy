# Yeni deney tasarımları · AYT

Durum: taslak, Yasin onayı bekliyor. Her deney aynı akışı izler: arıza animasyonu → yönlendirmeli keşif → bağımsız uygulama → onarım. Genel kurallar [AGENTS.md](../AGENTS.md), görsel yön [ART_DIRECTION.md](ART_DIRECTION.md).

## 1. AYT Biyoloji · Sinir Sistemi (Refleks Merkezi)

**Kazanım:** 11. sınıf İnsan Fizyolojisi, sinir sistemi. Kaynak: [MEB İnsan Fizyolojisi](https://ogmmateryal.eba.gov.tr/dersler-cepte?ders=Biyoloji&sinif=11). Kazanım kodu ve alt konu sırası uygulama öncesi MEB programından doğrulanacak.

**Arıza:** Dünyanın bir sakinin eli sıcak yüzeye değiyor ama geri çekmiyor. Isı algılanıyor, tepki yok. Gecikme sayacı büyüyor, dokuda hasar bölgesi yayılıyor.

**Keşif (3 adım):**
1. *Nöron yapısı.* Gerçekçi bir nöron: dendrit, hücre gövdesi, akson, miyelin kılıf, Ranvier boğumu, akson ucu. Oyuncu parçaya dokunur, impuls yönü dendritten akson ucuna giden okla görünür.
2. *Impuls.* Uyaran şiddetini kaydırıcıyla ayarlar. Eşik altında impuls oluşmaz, eşik üstünde her seferinde aynı büyüklükte oluşur (ya hep ya hiç). Zar potansiyeli grafiği canlı çizilir: dinlenim yaklaşık −70 mV, eşik yaklaşık −55 mV, depolarizasyon, repolarizasyon. Miyelinli ve miyelinsiz akson aynı anda yarıştırılır, impuls miyelinlide boğumdan boğuma atlar ve önce varır.
3. *Sinaps.* Akson ucundan nörotransmitter salınır, yalnızca karşı hücrenin reseptörüne bağlanır. İmpuls bu yüzden tek yönlüdür.

**Uygulama:** Yeni arızada ısı impulsu omurilikte kayboluyor. Oyuncu yolu kurar: reseptör → duyu nöronu → omurilikte ara nöron → motor nöron → efektör kas. Hangi halkada kopukluk olduğunu impuls izinden bulur (örnek: motor nöronun sinapsı, ters yönlü bağlanmış nöron, miyelini hasarlı akson). Onarım doğru halkayı seçmeyi gerektirir. Beyne giden ikinci yol "acıyı hissetme", ayrı ve gecikmeli gösterilir, refleks beyni beklemez.

**Başarı:** Yol doğru sırada kurulur, impuls refleks süresi sınırı içinde efektöre ulaşır, el geri çekilir, doku hasarı durur.

**Yanlış girişte:** Sıra hatalıysa impuls o halkada durur ve neden yazılır ("sinaps tek yönlü, motor nörondan duyu nöronuna geçemez").

**Varlık ihtiyacı:** gerçekçi nöron (parçaları ayrı katman), omurilik kesiti, el ve kas görseli, miyelinli/miyelinsiz akson. Talep açılır, Codex üretir.

## 2. AYT Matematik · Türev ve optimizasyon (Depo Atölyesi)

**Seçim gerekçesi:** Türev AYT Matematik'in merkezinde, sınavda hem hız/eğim hem ekstremum sorularında çıkar. "Türev olmasaydı" sorusunun cevabı oyunda bire bir gösterilebilir: bir sınır içinde en iyi değeri bulmak.

**Arıza:** Depo, her yeni malzemeyle "tahminen" kutu üretiyor. Hacim sürekli beklenenden düşük, malzeme israfı artıyor.

**Kurgu:** Kenarı *a* olan kare levhanın köşelerinden *x* kadar kare kesilip katlanarak kutu yapılıyor. V(x) = x(a − 2x)².

**Keşif:**
1. Oyuncu *x*'i kaydırır. Kutu 3B katlanır, V değeri ve V(x) grafiği birlikte hareket eder (şekil, sayı, formül aynı renkte).
2. Oyuncu denemeyle tepeyi arar, ama küçük aralıkta tahmin güvenilmez olur.
3. Teğet çizgisi sürüklenir: eğim pozitifken hacim artıyor, negatifken azalıyor, tepede eğim sıfır. Bu, "türev = anlık değişim hızı" bağını kurar.

**Uygulama:** a = 12 için V(1) = 100, V(2) = 128, V(3) = 108. Eğimi sıfırlayan değer bulunur: V′(x) = (a − 2x)(a − 6x) = 0, x = a/6. Yeni levha a = 18 için oyuncu x'i hesaplar, girer. Doğru x = 3, V = 432. Yanlış x ile kutu daha küçük hacimli çıkar ve levha atığı gösterilir.

**Başarı:** x doğru girilir ve oyuncu eğimin sıfır olduğu noktayı grafikte işaretler.

**Doğrulama bekleyen:** ÖSYM'de bu tür optimizasyon (hacim, alan) sorularının AYT kapsamındaki yeri TTKB 2026 listesinden teyit edilecek.

**Varlık ihtiyacı:** neredeyse yok, 3B1B tarzı kodla çizim. Yalnızca levha ve kutu için hafif malzeme dokusu.

## 3. AYT Kimya · Modern Atom Teorisi, spin (Stern–Gerlach)

**Karar (Yasin):** Spin sınav rotasında yer alır, kazanım AYT Kimya "Modern Atom Teorisi" içinde. Bu deney görsel şov: oyunun en etkileyici sahnesi olacak. Stern–Gerlach ayrıntısı kazanımın ilerisinde olabilir, bu yüzden sınav etiketi spin kuantum sayısı için verilir, deney ek derinlik olarak sunulur ve uygulamada kazanım sınırı ekranda belirtilir.

**Arıza:** Cihaz, atomların yönünü "sürekli bir dağılım" sanıyor ve tek bir yayılmış leke bekliyor. Gerçekte iki ayrı iz çıkıyor, kalibrasyon bozuluyor.

**Keşif:**
1. Fırından atom demeti, eşit olmayan manyetik alandan geçip ekrana düşer. Klasik tahmin (sürekli leke) ile ölçüm (iki ayrı nokta) yan yana.
2. Oyuncu mıknatısı çevirir (z, sonra x). Her yönde yine iki sonuç çıkar, yön ölçümü yeniden tanımlıdır.
3. Ardışık ölçüm: z'de "yukarı" ayıklanır, sonra x ölçülür, sonuç yarı yarıya. Ardından yine z ölçülürse eski bilgi silinmiştir.

**Modelleme kuralı:** Spin dönen küre olarak çizilmez. Durum, ölçüm eksenine göre iki sonuçlu bir özellik olarak gösterilir (ok yok, "yukarı/aşağı" etiketli iki kanal).

**Uygulama:** Üç aşamalı bir düzenek için istenen sonuç oranını öngörme ve cihazı buna göre yönlendirme.

**Başarı:** Oyuncu ardışık ölçümlerde sonuç oranını doğru tahmin eder.

**Öncelik:** Yüksek görsel değer, fakat gerçekçi 3B atom düzeneği gerektirir, varlıklar hazır olunca kurulur.

## AYT Matematik · üç kavramın hepsi

Karar (Yasin): Türev, integral ve limit üçü de yapılır. Türev yukarıda tasarlandı. İntegral: değişen debiyle dolan havuz, eğri altındaki alan toplam birikimdir. Limit: köprüde boşluğa yaklaşan araç, sınır değer. Hepsi [CURRICULUM.md](CURRICULUM.md) havuzundaki sırayla ele alınır.

## Sıra

Ana sıra artık [CURRICULUM.md](CURRICULUM.md) içindeki A öncelikli konular. Bu dosya yalnızca ilk detaylı tasarımları tutar.
