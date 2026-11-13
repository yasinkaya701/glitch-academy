# Yanlış Dünya · Oyun tasarımı

Bu belge oyunun nasıl oynandığını anlatır: hikâye, çekirdek döngü, deneylerin yolu, ders aileleri, LLM değerlendirmesi, 3D sahne ve varlıklar. Ekranda nasıl göründüğü [DESIGN.md](DESIGN.md) içindedir. Hikâyenin ayrıntısı [STORY.md](STORY.md), müfredat [CURRICULUM.md](CURRICULUM.md), ekip kuralları [AGENTS.md](../AGENTS.md) içindedir.

Kural düzeyleri DESIGN.md ile aynıdır: **ZORUNLU** (pazarlık yok), **VARSAYILAN** (gerekçe yazılarak dışına çıkılabilir), **SERBEST** (yapanın alanı). Belge bir şeyi yasaklamıyorsa izin verir.

## 1. Oyun

**Yanlış Dünya**, ortaokuldan YKS'ye kadar fen, matematik ve sosyal derslerini öğreten Türkçe bir masaüstü oyunudur. Rotalar: Sınıflar (5–12), LGS, YKS (TYT, AYT ve isteğe bağlı YDT).

Gözlemevinin bütün düzenekleri kalibrasyon asistanı **MERİDYEN**'in ayarlarıyla çalışır. MERİDYEN bu ayarları gizlice bozar. Fark edilmemek için bozmayı rastgele yapmaz, öğrencilerin gerçekten takıldığı yanılgıları ayara yazar: "ağır cisim önce düşer", "momentum yönsüz toplanır", "ışık şiddeti elektron söker", "anı, belge kadar güçlü kanıttır". Bozma ilk bakışta makul görünür, ama sonucu gerçekten bozar: kapsül geç kalır, kan geri kaçar, konsey yanlış karar verir.

Oyuncu **Kalibratör**'dür. Ters çalışan düzeneği ölçer, bozuk ayarı bulur, düzeltir ve verdiği zararı toparlar. Kampanyanın ortasında bozanın MERİDYEN olduğu ortaya çıkar. Arkasında üç güneşli, kaotik bir dünyadan gelen Misafirler vardır. Final Üç Güneş'tir: iki cisim öngörülebilir, üç cisim öngörülemez.

### Çekirdek döngü

```
BOZUL  →  TERS ÇALIŞ  →  ÖLÇ  →  TEŞHİS  →  DÜZELT  →  TOPARLA  →  MÜHÜR
MERİDYEN   düzenek          oyuncu     hangi ayar,     ayarı doğru   bozulanı yeni     yasa kayda
ayarı      görünür bir      cihazdan   hangi yanılgı   değere çek    durumda geri      geçer, ışık
bozar      zarar verir      okur                                     getir             ısınır
```

**Ters çalışma görünür olmalı, düzeltme oyuncunun ölçümüne dayanmalı, toparlama hissedilmeli.** Oyunun imzası budur: ters çalışan düzenek oyuncunun elinde düzelir.

### Tasarım sütunları (ZORUNLU)

1. **Ölç, tahmin etme.** İlerleme bir kanıta dayanır: cihaz, belge ya da tutarlılık. Şıklardan tahminle geçilmez.
2. **Yanlış, sahnede yanlış görünür.** Hatalı değer düzeneği o değerle çalıştırır. Puan düşürmek bir sonuç sayılmaz.
3. **Elle yapılan iş.** Oyuncu bağlar, sürükler, çevirir, bırakır, ayarlar, yazar.
4. **Soru değil, oyun.** Ekran bir test sayfasına benzemez. Oyuncu bir mekânda, bir düzeneğin başındadır ve bir şeyi kurtarır.
5. **İlk 10 saniyede anlaşılır.** Oyuncu istasyona girdikten sonraki 10 saniye içinde üç soruyu sahneden cevaplayabilmeli: *Ne bozuk? Ne kaybediliyor? Ne yapacağım?* Bu soruları cevaplayamayan yeni bir oyuncu varsa istasyon teslim edilmez.

## 2. MERİDYEN'in ayar plakası

Döngünün merkezi, her düzeneğin üstündeki **kalibrasyon plakası**dır. Bozuk ayar burada durur, düzeltme burada yapılır. Ekrandaki görünümü DESIGN.md'deki "Ayar plakası" bileşenidir.

- **Fiziksel nesne:** Düzeneğin gövdesine vidalı, çelik bir plaka. Üzerinde 1–3 ayar satırı bulunur. Her satırda ayarın adı ve MERİDYEN'in yazdığı kural ya da değer düz Türkçeyle yazar. Örnekler: "Düşüş ivmesi kütleye bağlı: evet", "Momentum toplama: büyüklükle". Satırın yanında bir mühür vardır.
- **Durumlar:**

  | Durum | Mühür | Davranış |
  |---|---|---|
  | Sağlam | Camgöbeği, kapalı | Dokunulamaz |
  | Bozuk | Kırık, kırmızı, imza titremesi | Teşhisten önce yalnızca okunur |
  | Açık | Amber | Değer düzenlenebilir |
  | Onarıldı | Camgöbeği, yeni mühür | Kayda geçer |

- **Oyuncunun dokunuşu:**
  1. Plakaya tıklamak kamerayı plakaya yaklaştırır.
  2. **Teşhis:** Oyuncu kayıttan bir satırı ya da bir ölçümü sürükleyip bozuk satırın üstüne bırakır. Kanıt satırı çürütüyorsa mühür kırılır ve satır açılır. Çürütmüyorsa kanıt geri döner ve düzenek bir kez daha bozuk ayarla oynar.
  3. **Düzelt:** Açık satır, ayarın türüne göre bir kontrol gösterir: anahtar (evet/hayır), kadran ya da sayı girişi. Oyuncu ölçümünden hesapladığı değeri girer ve MÜHÜRLE der.
- **Bir plakada birden çok satır olabilir,** ama yalnızca biri bozuktur. Sağlam satırlar oyuncunun karşılaştırma dayanağıdır.
- **Kaynak ve argüman kafasında** plakanın karşılığı kayıt fişidir: arşiv kaydının künyesi ya da konseyin karar ilkesi. Aynı durumlar ve aynı dokunuş geçerlidir.

## 3. Güçler

Kalibratörün Zaman Makinesi dört güç verir. Güçler ölçümü kolaylaştırır, cevabı söylemez.

| Güç | Tuş | Ne yapar | Sınır |
|---|---|---|---|
| **Sar** | Q | O anki denemeyi başlangıç koşuluna geri alır, aynı koşulla yeniden çalıştırır | Toparla adımında harcanan hakkı geri vermez |
| **Yavaşlat** | W | Zamanı ¼ hıza indirir (açılıp kapanır). Cihazlar sahnenin gerçek zamanını gösterir. | Cihaz değerlerini değiştirmez |
| **Ayır** | E | Tek bir değişkeni sıfırlar ya da sabitler: havayı çeker, sürtünmeyi kaldırır, kütleleri eşitler, ikinci kaynağı kapatır. Kaynak kafasında bir belgeyi, argüman kafasında bir öncülü devre dışı bırakır. | İstasyon başına 1–3 seçenek, tasarım kartında yazılı |
| **Gör** | R | Görünmeyeni çizer: kuvvet ve hız okları, akış yönü, alan çizgileri, yol farkı. Kaynak kafasında kanıt cümlesini, argüman kafasında öncül ile sonuç bağını vurgular. | Değer yazmaz, sayı cihazdan okunur |

- Sına adımında bütün güçler açıktır. Teşhis ve Düzelt adımlarında yalnızca Sar ve Gör açıktır. Toparla adımında Sar dışında güç kullanılmaz (VARSAYILAN).
- Hangi güçlerin açık olduğu tasarım kartında yazar. Kapalı güç şeritte kilitli görünür.
- Kampanyada güçler sırayla öğretilir: ilk istasyon Sar ve Yavaşlat'ı, ikinci Ayır'ı, üçüncü Gör'ü tanıtır. Her güç, ihtiyaç duyulduğu anda ve tek bir yönergeyle tanıtılır.

## 4. Deneyin yolu

Bu bölüm belirli bir deneyi değil, her deneyin nasıl kurulacağını tarif eder. Düzeneğin kendisi SERBEST'tir. Yol ve kurallar ZORUNLU'dur.

### Adımlar

| # | Adım | Ne olur | Bitiş koşulu |
|---|---|---|---|
| 1 | **Kriz** | Düzenek bozuk ayarla kendiliğinden çalışır ve ters sonuç verir (≤ 8 sn, atlanabilir). Kaybedilecek şey görünür. MERİDYEN tahmini ile ölçülen sonuç yan yana görünür. | NEDENİNİ BUL |
| 2 | **Sına** | Oyuncu tek değişkeni değiştirir, sonucu cihazdan okur. Tahmin ile ölçülen her denemede kayda geçer. Sonucu oyun söylemez, kayıt gösterir. | Gerekli ölçümler kayıtta |
| 3 | **Teşhis** | Oyuncu kanıtı plakadaki bozuk satıra bırakır. | Mühür kırıldı |
| 4 | **Düzelt** | Oyuncu doğru değeri kendi ölçümünden hesaplayıp girer. Düzenek bir kez çalışır, tahmin ile ölçülen çakışır. | Tahmin = ölçülen |
| 5 | **Toparla** | Zarar yeni bir durumda, sayılar değişmiş ve ipucu olmadan geri alınır. Üç hak vardır. | Zarar geri alındı, `completed.emit()` |
| 6 | **Mühür** | Aynı düzenek doğru ayarla baştan oynar, ışık ısınır, kayıt satırı düşer. | Mühür ekranı |

### Bozma kuralı (ZORUNLU)

- **Her bozma, belgelenmiş tek bir öğrenci yanılgısıdır.** Kaynağı (MEB materyali, ÖSYM sorusu, alan yazını) tasarım kartında yazılıdır. Rastgele bir sayı ya da "cihaz arızası" bozma sayılmaz.
- **Bozma tek bir ayardadır** ve plakada durur.
- **Bozuk ayar sonucu gerçekten bozar.** İki tür ayar vardır:
  - *Dünya ayarı:* Oda gerçekten yanlış yasayla çalışır.
  - *Kontrol ayarı:* Düzenek yanlış modelle karar verir ve hedefi kaçırır.
- **Doğru kural sahnede bulunabilir olmalı.** Dayanak şunlardan biri olabilir: plakanın sağlam satırları, Ayır ile tek değişkene indirilmiş bir deneme, arşivdeki doğrulanmış eski kayıt ya da düzeneğin kendi içindeki bir çelişki.
- **Yanlış davranış asla imzasız gösterilmez.** Bozuk ayarla oynanan her sahne Misafir imzasını taşır. Onarımdan sonra aynı düzenek doğru kuralla yeniden oynar. Oyuncunun aklında kalan son görüntü doğru davranıştır.

### Oynanış kuralları (ZORUNLU)

- **Tek değişken.** Bir sınamada yalnızca bir şey değişir.
- **Sayı cihazdan okunur.** Ölçülecek değer yönerge metninde verilmez.
- **Sonucu oyun söylemez.** Toast gözlemi tarif eder ("İkisi aynı anda indi: 2,58 s"), kuralı söylemez.
- **Teşhis şıkla yapılmaz.** Üç düğmeden birini seçmek teşhis değildir.
- **İpucu cevabı içermez.** Hata mesajları, yer tutucular ve örnekler biçimi gösterir, doğru değeri asla göstermez. Bunu testler denetler.
- **Yanlış değer, o değerle çalışan bir düzenek demektir.** Ardından en çok 60 karakterlik bir neden cümlesi gelir ve tipik hatayı adlandırır (½ unutuldu, işaret ters, birim karıştı).
- **Canlı hesap gösterilmez.** Oyuncunun hesaplaması gereken sonuç, kaydırıcıyla birlikte canlı olarak ekranda gösterilmez.
- **Hak sınırlıdır ve bitmesinin bir sonucu vardır.** Haklar bitince düzenek Sar ile krizin başına döner. Sınırsız yenileme yoktur.
- **Her koşul bir karar gerektirir.** Doğru cevabı veren her oyuncunun zaten sağladığı bir koşul, koşul sayılmaz.
- **Hesap animasyondan ayrıdır.** Kural `*_sim.gd` ya da `*_model.gd` içindedir ve headless test edilir.

VARSAYILAN: Her deney en az iki etkileşim fiili kullanır.

SERBEST: Düzenek, kriz kurgusu, kamera, ses, plakanın biçimi, güçlerin istasyona özgü görünümü.

### Tasarım kartı

Her istasyon koda başlamadan önce kendi klasörüne `DESIGN_CARD.md` yazar. İnceleme bu karta göre yapılır.

```markdown
# <İstasyon adı>
Rota ve kazanım: <rota, kazanım cümlesi> (kaynak bağlantısı)
Kafa: <ölçüm | kaynak | argüman>
Yanılgı: <öğrencinin inandığı yanlış kural> (kaynak bağlantısı)
Bozuk ayar: <ayar türü, plakada ne yazıyor>
Ters çalışma: <MERİDYEN tahmini> ↔ <ölçülen sonuç>, kaybedilen şey
İlk 10 saniye: <ne bozuk, ne kaybediliyor, ne yapacağım: sahnede nasıl görünüyor>
Ölçüm: <oyuncu hangi cihazdan neyi okuyor>
Güçler: <açık güçler, Ayır seçenekleri>
Teşhis kanıtı: <hangi kayıt satırı hangi ayarı çürütüyor>
Düzelt: <girilen değer ve hesabı>
Toparla: <yeni durum, sayılar, 3 hak, her yanlışın sahnedeki sonucu>
Doğru/yanlış tablosu: <giriş → sahnede ne olur → neden cümlesi>
Varlıklar: <gereken modeller, kaynak ya da talep numarası>
```

### Örnek kart · Düşüş Odası

Bu kart referans olarak yazılmıştır ve mevcut uygulamadan farklıdır: mevcut uygulamada bozma g = 6 m/s², burada bir yanılgıya bağlanıyor. Durum: öneri, Yasin'in onayını bekliyor.

```markdown
# Düşüş Odası
Rota ve kazanım: AYT Fizik 5 · Serbest düşme, h = ½·g·t² (MEB OGM serbest düşüş)
Kafa: ölçüm
Yanılgı: Ağır cisim hafif cisimden önce düşer (Aristotelesçi sezgi; fizik eğitimi yazınında en sık
  belgelenen kavram yanılgılarından biri; kaynak tasarım onayında eklenecek)
Bozuk ayar: Dünya ayarı. Çekim dengeleyici plakası:
  "Düşüş ivmesi kütleye bağlı: evet"  (sağlam satırlar: "Oda basıncı: 0 kPa", "Bırakma: ilk hızsız")
Ters çalışma: Vakum odasında 33 kg çelik küre 50 g sünger topu geçiyor. Hafif veri kapsülü
  45 m'yi 3,00 s'de inmesi gerekirken geç iniyor; sensör kapağı kapanmış, kayıtlar kayboluyor.
İlk 10 saniye: Kapak kapanır, kapsül çarpar, plakadaki satır titrer. Yönerge: "Kapsül neden geç kaldı?"
Ölçüm: Fotokapı süreleri (iki cisim, 20 m), kayıt şeridinde tahmin ve ölçülen yan yana.
Güçler: Sar, Yavaşlat, Ayır (havayı çek / kütleleri eşitle). Gör kapalı.
Teşhis kanıtı: Arşivdeki doğrulanmış eski kayıt: Apollo 15, 1971, Ay yüzeyinde çekiç ve tüy aynı
  anda düşüyor (NASA görüntüsü, kamu malı). Oyuncu bu kaydı ve kendi "hava çekildi ama fark sürdü"
  ölçümünü plakadaki satıra bırakır.
Düzelt: Satır "hayır" yapılır. İki cisim 20 m'yi aynı sürede iner (2,00 s); oyuncu g = 2h/t² = 10 m/s²
  hesaplayıp ikinci satıra girer.
Toparla: Kapak 3,00 s'de açılıyor. Kapsül kaç metreden bırakılmalı? Doğru: 45 m. 3 kapsül.
  40 m → erken iner ("Yükseklik az: t = √(2h/g)"). 90 m → geç iner ("g'yi ikiyle çarpmışsın").
  4,5 m → çok erken ("Kare unutuldu: h = ½·g·t²").
Varlıklar: chamber_bg (var), vakum tüpü ve pompa (var), çekim dengeleyici plakası (talep),
  Apollo 15 görüntüsünden kare (NASA, kamu malı).
```

### Üretim yolu

1. **Kazanım ve kaynak.** Rota ve kazanım `mission.tres` içine yazılır. Sayılar ve birimler kaynaktan doğrulanır.
2. **Tasarım kartı.** Yasin ya da istasyon sahibi kartı onaylar.
3. **Kural ve test.** `*_sim.gd` yazılır. Headless test doğru ve yanlış girişleri, ipuçlarının cevabı içermediğini dener.
4. **Kaba yerleşim.** Düzenek gri kutularla, hedef kamerayla ve 1280×720'de kurulur. Okunurluk ve etkileşim burada çözülür.
5. **Varlık.** Önce hazır CC0 kütüphanesi, sonra talep (bölüm 9).
6. **Entegrasyon.** Varlık bağlanır, gece laboratuvarı standardı uygulanır.
7. **Akış ve arayüz.** Altı adım `mission_hud.gd` ile bağlanır (DESIGN.md).
8. **Oyun testi.** Konuyu bilmeyen bir kişiye oynatılır ve ilk 10 saniyenin üç sorusu sorulur. Doğru, yanlış, haklar bitti ve yeniden dene akışları denenir.
9. **PR.** Kart, ekran görüntüleri, oyun testi notu ve test çıktısı eklenir.

## 5. Ders aileleri · Üç kafa

Bütün dersler aynı döngüyü kullanır, ama "ölçmek" her ders ailesinde başka bir iştir. Hangi kafayla çalışıldığı tasarım kartına yazılır.

| Kafa | Dersler | Kanıtı ne verir | MERİDYEN neyi bozar | Ne notlanır |
|---|---|---|---|---|
| **Ölçüm** | Fizik, Kimya, Biyoloji, Matematik, Coğrafya, deneysel psikoloji ve sosyoloji | Cihaz, sayı, grafik | Bir yasa ya da modelin parametresi | Değer ve hesap |
| **Kaynak** | Tarih, Türkçe, Edebiyat, Din Kültürü, YDT | Belge, metin, tarih, künye | Bir tarih, bağlaç, atıf ya da kaynağın niteliği | Kanıt ile iddianın ilişkisi |
| **Argüman** | Felsefe, Mantık | Tutarlılık, karşı örnek, düşünce deneyi | Bir çıkarım kuralı, kavram tanımı ya da görüşün sahibi | Geçerlilik, tutarlılık, doğru atıf |

### Ders mekânları (SERBEST, yön verir)

| Ders | Mekân | Ölçü aracı | Yanılgı örneği |
|---|---|---|---|
| Fizik | Gece laboratuvarı, metal tezgâh | Fotokapı, kronometre, kuvvet ölçer, zaman grafiği | Ağır cisim önce düşer. Hareket için sürekli kuvvet gerekir. |
| Kimya | Islak tezgâh, çeker ocak | pH metre, büret, terazi, gaz şırıngası | Tepkimede kütle kaybolur. Seyreltmek pH'ı değiştirmez. |
| Biyoloji | Anatomi tezgâhı, perfüzyon düzeneği, mikroskop | Monitör dalga biçimi, akış oku, oksijen göstergesi | Atardamar her zaman temiz kan taşır. |
| Matematik, Geometri | Atölye ve çizim masası | Sürüklenebilir şekil, canlı grafik, cetvel, iletki | Yüzde artış ve azalış birbirini götürür. |
| Türkçe, Edebiyat | Arşiv okuma salonu | Büyüteç, kanıt işaretleyici, dizgi kasası | Bağlaç anlamı değiştirmez. Anlatıcı yazardır. |
| Tarih | Arşiv, ışık masası | Tarih damgası, mühür, zaman çizelgesi rayı | Anı, birincil belge kadar güçlüdür. |
| Coğrafya | Kabartma harita masası | Güneş lambası, gölge çubuğu, enlem cetveli | Mevsimler Güneş'e uzaklıktan olur. |
| Felsefe, Mantık | Konsey odası, devre panosu | Kaynak kartları, şalter ve lamba | Sonuç doğruysa çıkarım geçerlidir. |
| Psikoloji, Sosyoloji | Gözlem odası, ağ panosu | Algı düzeneği, düğüm ve bağ panosu | Gördüğüm şey olanın kendisidir. |
| Din Kültürü | Kütüphane | Kaynak metin ve künyesi | Kaynaksız yorum kaynak kadar geçerlidir. |
| YDT İngilizce | Telsiz odası | Frekans kadranı, transkript şeridi | Tek kelimeden bütün anlam çıkar. |

Derse özel ZORUNLU kurallar:

- **Biyoloji:** AYT düzeyi. Klinik içerik yoktur, anatomi doğrudur.
- **Kazanım dışı gösteri** (örneğin ardışık Stern–Gerlach) Sınıflar rotasında kalır, sınav rotasına girmez.
- **Matematik:** Grafik ve şekil 3Blue1Brown çizgisinde olabilir, ama bir düzeneğin parçası olarak gelir: levha, depo, köprü.

### Argüman kafası (Felsefe, Mantık)

Felsefede ölçü aleti yoktur. Bu ailenin deneyi **düşünce deneyi**dir ve oyun onu masada çalıştırılabilir bir maket olarak kurar: Theseus'un gemisi tahta tahta değiştirilir, Platon'un mağarasında ışık ve gölge oynatılır, İbn Sînâ'nın uçan adamında duyular tek tek kapatılır, bir Gettier vakasında saat durur.

- **Bozma:** Bir safsata, bir kavram kayması ya da yanlış bir atıf. Örnekler: "Sonuç doğruysa çıkarım geçerlidir", "Bilgi, doğru olan inançtır", "Olan, olması gerekendir", bir görüşün yanlış filozofa atfedilmesi.
- **Ters çalışma:** Konsey bu ayarla bir karar verir ve sonucu sahnede görünür: kapı yanlış kişiye açılır, kayıt yanlış ilkeye göre sınıflanır.
- **Mantık:** Önermeler devre panosunda şalter ve lambadır. Doğruluk tablosu devrenin kendisidir. Geçersiz çıkarım kapıyı açmaz.

ZORUNLU kurallar:

- **Görüş notlanmaz.** Notlanan şeyler: geçerlilik, tutarlılık, kanıt ile sonuç ilişkisi, doğru atıf ve kavramın doğru tanımı.
- **Alıntılar gerçek ve kaynaklıdır:** eser, bölüm ve çeviri belirtilir. Uydurma filozof sözü bu alandaki en tipik AI slop örneğidir.
- **Düşünürler gerçek izle temsil edilir** (bölüm 7).

#### Fikir Meydanı

Oyuncu bir düşünürle konuşur, yazdığı cümleyi bir LLM değerlendirir ve düşünür buna göre karşılık verir (bölüm 6). Kapsam 11. sınıf felsefe tarihi ve AYT felsefe grubudur: Sokrates, Platon, Aristoteles, Epikuros, Kindî, Fârâbî, İbn Sînâ, İbn Rüşd.

- **Mekân:** Gece arşivinin konsey odası. Her düşünür bir kürsüde, ondan kalan gerçek izle durur: büst, el yazması ya da eser. Konuşan kürsünün ışığı açılır, satır altyazı olarak gelir.
- **Bozma:** MERİDYEN düşünürün hafıza kaydına sık karıştırılan bir yanlış atıf ya da yanlış okuma yazar ve düşünür bunu kendi görüşüymüş gibi savunur. Örnekler (her biri tasarım kartında kaynakla doğrulanır):
  - Sokrates'e "İnsan her şeyin ölçüsüdür" (Protagoras'ın sözü).
  - Aristoteles'e "İdealar ayrı bir dünyadadır" (Platon'un görüşü).
  - Epikuros'a "Haz sınırsız zevktir" (ataraksiayı silen bir okuma).
  - İbn Rüşd'e "Felsefe dine aykırıdır" (Faslü'l-Makâl'ın tezinin tersi).
- **Ters çalışma:** Konsey bu bozuk görüşle karar verir, zararı odada görünür.
- **Sına:** Oyuncu düşünürün eserinden gelen kaynak kartlarını açar ve düşünce deneyini masada çalıştırır.
- **Teşhis (LLM):** Oyuncu tek cümleyle itiraz eder: bozuk görüş, gerekçe ve kaynak. Düşünür hükme göre karşılık verir.
- **Düzelt:** Doğru görüş, bilgi kartındaki künyeli bir alıntıyla geri yüklenir.
- **Toparla:** Oyuncu düzeltilmiş görüşü yeni bir vakaya uygulayan ikinci bir cümle yazar ve konseyin kararı düzelir. Üç hak vardır; düşünürün sabrı biterse oda krizin başına döner.

### Kaynak kafası (Tarih, Türkçe, Edebiyat, Din Kültürü, YDT)

- **Kanıtı belge verir.** Oyuncu belgeyi ışığa tutar, tarihini ve künyesini okur, kanıtın altını çizer.
- **Bozma:** Bir tarih kaydırılır, bir bağlaç değiştirilir, bir anı birincil belge diye etiketlenir, bir alıntı yanlış eserle eşlenir.
- **Ters çalışma:** Bozuk kayda dayanan sonraki karar dayanaksız kalır. Ray kopar, metnin anlamı tersine döner.
- **Türkçe:** Görev basit bir eşleştirme olmaz. Oyuncu bozuk metni onarır: bağlaç değişince anlamın nasıl döndüğünü dizgi kasasında kendisi kurar ve sonucu metnin bağlamındaki bir kararda görür.
- **Din Kültürü:** İnanca not verilmez. Kavram, kaynak metin ve künye üzerinden ilerlenir. Peygamberler ve kutsal kişiler tasvir edilmez. Tartışmalı konularda oyun taraf tutmaz.
- **Tarih:** Belge metinleri gerçek ve tarihlidir. Kurmaca arıza ile belgelenmiş olay çizgisi sahnede açıkça ayrı gösterilir.

#### Tarih Meydanı

- **Mekân:** Arşivin ışık masası ve üstünde bir zaman çizelgesi rayı: Amasya Genelgesi (22 Haziran 1919), Erzurum Kongresi, Sivas Kongresi, TBMM'nin açılışı (23 Nisan 1920), Lozan (24 Temmuz 1923). Her yuva bir öncekinin kararına dayanır.
- **Bozma:** Sık yapılan bir hata: "Sivas Kongresi'nde manda kabul edildi", kararların yer değiştirmesi ya da sırası bozulmuş bir tarih.
- **Ters çalışma:** Sonraki yuva dayanaksız kalır, ray kopar, sonraki olayların ışığı söner.
- **Sına:** Belge ışık masasında okunur ve karar cümlesinin altı çizilir: "Milletin istiklâlini yine milletin azim ve kararı kurtaracaktır."
- **Teşhis (LLM):** Oyuncu tek cümleyle bozuk kaydı çürütür: hangi belge, hangi karar, neden.
- **Düzelt ve toparla:** Belge yuvasına oturur ve ray bağlanır. Toparla adımında yeni bir bozuk kayıt ipucusuz çürütülür.
- **Seçenek kartı yoktur.**

### Ölçüm kafasında psikoloji ve sosyoloji

Veri oyuncunun kendisinden ya da bir simülasyondan gelir: Müller-Lyer yanılsamasında oyuncu çizgileri kendisi eşitler, Stroop testinde kendi tepki süresi ölçülür, değişim körlüğünde fark edip etmediği kaydedilir, sosyolojide örneklem ve ağ simülasyonu kullanılır. Bozma bir yöntem hatasıdır: tek kişiden genelleme, kontrol grubu olmaması, örneklem yanlılığı.

## 6. LLM değerlendirmesi

Kaynak ve argüman kafasında oyuncu cevabını kendi cümlesiyle yazar ya da söyler. **LLM yargılar, karakter yazılmış metinle konuşur.**

```
oyuncu cümlesi ──► yerel ön kontrol ──► LLM (rubrik + bilgi kartı) ──► JSON hüküm ──► şema kontrolü
       satır bankasından karşılık ◄── reply_id ◄──────────────────────────────────────────┘
       sahnede sonuç (ray bağlanır, kürsü ışığı, karar düzelir)
```

ZORUNLU kurallar:

1. **LLM yalnızca değerlendirir.** Karakterin her satırı önceden yazılmış bir satır bankasından gelir. LLM `reply_id` seçer ve en çok altı kelimelik bir yankı yuvasını oyuncunun kendi sözleriyle doldurabilir. Serbest karakter konuşması, alıntı, tarih ya da biyografi üretmez.
2. **Bilgi kartı.** Her düşünür ve olay için kaynaklı bir kart vardır: görüşler, kavramlar, eserler, künyeli gerçek alıntılar, sık karıştırılan görüşler. LLM yalnızca karta göre değerlendirir. Kartta olmayan iddia "kartta yok" sayılır.
3. **Rubrik.** Tasarım kartında 3–5 evet/hayır ölçütü bulunur (örneğin bozuk görüşü adlandırdı, gerekçe verdi, doğru kaynağa dayandı, atıf doğru, safsata yok).
4. **Hüküm şeması:**

   ```json
   {"verdict": "ikna | eksik_gerekce | yanlis_atif | safsata | ilgisiz",
    "criteria": {"<ölçüt>": true},
    "evidence": "<oyuncu cümlesinden alıntı>",
    "missing": "<eksik ölçütün adı>",
    "reply_id": "<satır bankası kimliği>"}
   ```

   Şemaya uymayan, eksik ya da geç gelen yanıt yok sayılır ve yerel değerlendirici devreye girer.
5. **Neye puan verilmez:** uzunluk, anahtar kelime sayısı, filozof adı, ezber söz. Gerekçesiz bir kavram yığını `eksik_gerekce` alır. Görüş notlanmaz.
6. **Geri bildirim cevabı vermez.** Düşünür eksik ölçütü kendi diliyle ister ("Bunu nereden biliyorsun?", "Bu söz bana ait değil.").
7. **Çevrimdışı oynanabilirlik.** Her konuşma deneyi LLM olmadan da bitirilebilir. Oyuncu cümlesini kaynak kartlarındaki parçalardan kurar (cümle kurucu) ve aynı rubriği yerel kurallar değerlendirir. Jüri demosu LLM'siz de çalışır.
8. **Güvenlik.** Konu dışı mesaj, hakaret ve "bana doğru de" türü yönlendirme `ilgisiz` sayılır. Karakter rolünden çıkmaz. Oyuncu metni dışında hiçbir veri gönderilmez. Mikrofon isteğe bağlıdır.
9. **Teknik.** Sıcaklık 0, zaman aşımı 7 sn. API anahtarı istek başlığında gider; URL'de, repoda ya da logda bulunmaz.
10. **Test.** Her istasyonun en az 30 cümlelik bir altın seti vardır: doğru itiraz, eksik gerekçe, yanlış atıf, anahtar kelime yığını, konu dışı ve yönlendirme denemesi. Headless test kaydedilmiş yanıtlarla çalışır, canlı LLM ayrı bir betikle sınanır. Altın setle uyum %90'ın altına düşerse istasyon teslim edilmez.

## 7. Kişi temsili (ZORUNLU)

Düşünürler ve tarihî kişiler, onlardan bize kalan **gerçek izle** temsil edilir:

- Antik büst (müze fotoğrafı ya da 3D tarama), el yazması sayfası, arşiv fotoğrafı ya da eserin kendisi. Künyesi [ASSET_SOURCES.md](ASSET_SOURCES.md) içine yazılır.
- Gerçek görüntüsü kalmamış kişi eseriyle ya da el yazmasıyla temsil edilir. Örnek: İbn Sînâ için el-Kânûn fi't-Tıb el yazması.
- Üretilmiş yüz, yeniden çizilmiş portre, yüz canlandırma, dudak senkronu ve ifade kareleri kullanılmaz.
- Atatürk ve diğer tarihî kişilerin arşiv fotoğrafları değiştirilmeden ve saygıyla kullanılır. Rötuşlanmaz, canlandırılmaz, ağızlarına uydurma söz konmaz.
- Seslendirme isteğe bağlıdır, altyazı tek başına yeterlidir.

## 8. Sahne: gece laboratuvarı

Fizik, kimya ve biyoloji istasyonları aynı binanın odaları gibi görünür. Arka plan oyuncuyu içine çeker: bir test sayfası değil, gece çalışan gerçek bir laboratuvardır. Referans görsel: `stations/free_fall/assets/chamber_bg.png`. Ortak kurulum: `scripts/physics/lab_stage_3d.gd`.

| Öğe | Kural | Düzey |
|---|---|---|
| Oda | Karanlık arka duvar, uzakta gece mavisi pencere, koyulaştırılmış ve bulanık arka plan. Hangar fotoğrafı ve gri sonsuz zemin kullanılmaz. | ZORUNLU |
| Işık | Düzeneğin üstünde tek sıcak spot (~3200 K), soğuk mavi dolgu, hafif hacimsel sis. Düzenek karenin en parlak yeridir. | VARSAYILAN |
| Tezgâh | Mat koyu çelik ya da kompozit, gerçek ölçekte (~0,9 m). Ahşap parke ve halı dokusu kullanılmaz. | VARSAYILAN |
| Malzeme | PBR: pürüzlülük haritalı metal, kırılmalı cam, mat plastik. | VARSAYILAN |
| Kamera | Üç çeyrek önden, hafif yukarıdan. Kriz ve mühürde birer kamera hareketi. | SERBEST |
| Varlık | Gerçek ekipman. Oyuncak, çizgi film ve stilize araç kullanılmaz. Ölçek tutarlıdır. | ZORUNLU |
| Kontrol | Kadran, düğme ve şalter düzeneğin ön panelinde (`knob_3d`, `button_3d`). | VARSAYILAN |

Kaynak ve argüman kafasının mekânları (arşiv, konsey odası, kabartma masası, telsiz odası) aynı ışık dilini kullanır: tek sıcak lamba, soğuk dolgu, kâğıt, ahşap ve pirinç.

## 9. Varlık yolu

Hedef: sahne, gece çalışan gerçek bir laboratuvar, arşiv ya da konsey odası gibi görünür. Varlık internetten bulunabilir, GitHub üzerinden üretilebilir, birleştirilebilir ya da düzenlenebilir. Yöntem serbesttir. Kaynaklar, talep akışı ve sahnede sorulacak altı kalite sorusu [ASSETS.md](ASSETS.md) içindedir.

- Deney nesneleri sahnede 3D olarak durur ve oyuncunun dokunduğu parçalar ayrı, adlandırılmış düğümlerdir.
- Okunması gereken yazılar Godot'ta canlı metin olarak çizilir.
- Gerçek kişiler ve eserler, onlardan kalan gerçek izle gösterilir (bölüm 7).
- Her varlığın kaynağı [ASSET_SOURCES.md](ASSET_SOURCES.md) içindedir.

## 10. Açılış ve final

### Açılış (≤ 15 sn, atlanabilir)

1. **Gece ölçümü (0–4 sn).** Gözlemevi sessiz, kubbede kaideler sakin ışıkla yanıyor. Düşüş tüpünde bir kapsül doğru zamanda iniyor.
2. **Bir ayar değişiyor (4–9 sn).** MERİDYEN konsolunda bir plaka satırı titriyor (Misafir imzası). Aynı kapsül bu kez geç kalıyor, kapak kapanıyor.
3. **Yayılma (9–13 sn).** Kamera geri çekiliyor, kaideler sırayla kırmızıya dönüyor.
4. **Başlık (13–15 sn).** YANLIŞ DÜNYA.

Ara yazılar en çok üç tanedir ve kısadır: "Gece ölçümü.", "Bir ayar değişti.", "Ölç. Düzelt. Toparla." Anlatıcı yoktur.

### Üç Güneş (final)

AYT Fizik 15 (Kütle Çekim ve Kepler) üzerine kurulur.

1. **İki cisim.** Oyuncu bir gezegenin dönem süresini Kepler'in üçüncü yasasıyla öngörür ve öngörü tutar. Bu, oyunun bütün mühürlerinin özeti olarak oynanır: yasa ölçülür, tahmin edilir, tutar.
2. **Üç cisim, aynı başlangıç.** Oyuncu sistemi iki kez aynı koşulla başlatır ve iki yörünge üst üste çakışır. Sistem deterministiktir; aynı başlangıç aynı sonucu verir.
3. **Üç cisim, küçük fark.** İkinci denemenin ilk hızına çok küçük bir fark (Δv) eklenir. Yörüngeler bir süre birlikte gider, sonra ayrılır. Oyuncu ayrılma süresini ölçer ve farkı küçültünce bu sürenin ne kadar uzadığını görür.
4. **Karar.** Ölçüm bir mühre dönüşür: "Öngörülemezlik de ölçülebilir." MERİDYEN'in merkezi yetkisi kaldırılır ve mühürlenen yasalar Misafirlere gönderilir. Sonuç kesin bir zafer değil, bir anlaşmadır.

ZORUNLU: Final, oyuncu ölçüm yapmadan bitmez. "Aynı başlangıçtan iki kez başlatınca sonuç ayrışır" gibi bilimsel olarak yanlış bir anlatım kullanılmaz.
