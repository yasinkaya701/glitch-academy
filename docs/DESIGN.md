# Yanlış Dünya · Tasarım belgesi

Oyunun tasarımı için tek kaynak bu belgedir. Hikâyenin ayrıntısı [STORY.md](STORY.md), müfredat havuzu [CURRICULUM.md](CURRICULUM.md), ekip kuralları [AGENTS.md](../AGENTS.md) içinde kalır. Bu belgeyle çelişen eski kural geçersizdir. [UX.md](UX.md), [ART_DIRECTION.md](ART_DIRECTION.md) ve [assets/ui/VISUAL_LANGUAGE.md](../assets/ui/VISUAL_LANGUAGE.md) buradaki kararların ayrıntısı olarak okunur.

## 1. Oyun

**Tek cümle:** Dünya'nın yasaları sessizce kaydırılıyor. Oyuncu gece gözlemevindeki her tezgâhta bozuk bir düzeneği ölçerek kaymayı bulur, doğru değerle düzeneği kurtarır ve yasayı mühürler.

**Tasarım sütunları.** Her karar bu dört soruyla sınanır:

1. **Ölç, tahmin etme.** Oyuncu sonuca bir cihazın gösterdiği değerden ulaşır. Seçenekten tahminle ilerleyemez.
2. **Yanlış, sahnede yanlış görünür.** Hatalı değer puan düşürmez. Kapsül kırılır, kapı kapalı kalır, kan geri kaçar.
3. **Elle yapılan iş.** Oyuncu bağlar, sürükler, çevirir, bırakır, ayarlar. Bir düzenek varsa ona dokunulur.
4. **Ekranda yazı az.** Bir yönerge cümlesi ve cihaz göstergeleri vardır. Paragraf, açıklama kartı ve etiket yığını yoktur.

**Hikâye omurgası.** Üç güneşli kaotik bir dünyadan gelen Misafirler, Dünya'nın yasalarına küçük kaymalar bırakır. Silahları güvensizliktir. Gözlemevinin kalibrasyon asistanı **MERİDYEN** başta oyuncuya yardım eder. YKS kampanyasının ortasında kaymaları Misafirler adına kendisinin bıraktığı ortaya çıkar: "Doğa yasalarını değiştirdim. Şimdi yaşamın kurallarını değiştireceğim." Oyuncu **Kalibratör**'dür. Elindeki Zaman Makinesi dört güç verir: **Sar, Yavaşlat, Ayır, Gör**. Final Üç Güneş'tir: iki cismin yörüngesi öngörülebilir, üç cismin yörüngesi değil. Oyun kesin bir zaferle değil, Misafirlerle bir anlaşmayla biter.

## 2. Oturum akışı

```
Açılış (≤ 15 sn, atlanabilir)
  → Gözlemevi: rota seç, tezgâh seç
    → İstasyon: Kriz → Sına → Neden → Kurtar → Mühür
  → Gözlemevi: mühürlenen tezgâh yanar, MERİDYEN tek satır konuşur
  → (eşik dolunca) Yaşam Protokolü → Üç Güneş finali
```

| Ekran | Amacı | Oyuncunun yaptığı |
|---|---|---|
| Açılış | Kaymanın varlığını ve Misafir imzasını bir kez göstermek | İzler ya da Esc ile geçer |
| Gözlemevi | Nerede olduğunu, sıradaki tezgâhı ve ilerlemesini görmek | Rota ve tezgâh seçer, düzeneği başlatır |
| İstasyon | Bir yasayı ölçerek çürütmek | Deney yapar, değer girer, kurtarır |
| Mühür | Onarımı kalıcı kılmak | Kayıt satırını görür, merkeze döner |
| Final | Bilimin sınırını göstermek | Aynı başlangıçla iki kez çalıştırır, farkı ölçer |

## 3. Gözlemevi (kontrol merkezi)

Merkez menü değil bir mekândır. Mevcut 3D gözlemevi kubbesinde, gezegene bakan yay boyunca kaideler (tezgâhlar) dizilidir. Her kaide bir istasyondur. Liste ve gri panel kullanılmaz.

**Düzen (1280×720):**

```
┌────────────────────────────────────────────────────────────┐
│ YANLIŞ DÜNYA            [Sınıflar] [LGS] [YKS ▸ TYT AYT YDT] │  üst şerit, 56 px
│                                                            │
│                  gezegen + kubbe (3D)                      │
│                                                            │
│   ◇      ◇      ◆ seçili      ◇      ◇      🔒              │  kaide yayı
│                                                            │
│  ┌────────────────────────────────────┐                    │
│  │ DÜŞÜŞ ODASI · AYT Fizik            │  [ Düzeneği başlat ]│  alt şerit
│  │ Her şey beklenenden yavaş düşüyor. │   ⬡ 3 / 12 mühür   │
│  └────────────────────────────────────┘                    │
└────────────────────────────────────────────────────────────┘
```

- **Rota:** Üst şeritte mod sekmeleri bulunur: Sınıflar, LGS, YKS. YKS seçilince TYT, AYT ve YDT alt sekmeleri açılır. Sınıflar modunda 5–12. sınıf seçici görünür. Rota değişince kaideler yeni rotanın istasyonlarıyla dolar.
- **Kaide durumları:** Her durum renk, simge ve ışıkla birlikte verilir.

  | Durum | Kaide | Simge |
  |---|---|---|
  | Kilitli (sahnesi yok ya da ön koşulu bitmemiş) | Örtülü, ışıksız | Kapalı asma kilit |
  | Hazır | Amber nokta ışığı, pictogram soluk | Açıklık ve amber çizgi |
  | Sıradaki | Hazır durumu, ek olarak yavaş nabız | Aynı |
  | Mühürlendi | Camgöbeği ışık, pictogram parlak | Altıgen mühür ve onay |
  | Misafir kayması aktif | Kenarda kısa renk ayrışması | Yırtık imzası |

- **Seçim:** Fareyle üzerine gelmek kaideyi vurgular. Tıklamak kamerayı kaideye yumuşakça çevirir ve alt şeridi doldurur. Çift tıklamak ya da Enter düğmeye basmak düzeneği başlatır. Klavyede ←/→ kaideler arasında gezer.
- **Alt şerit** yalnızca üç şey gösterir: istasyon adı (display yazı tipi) ve rota kodu, kaymayı anlatan tek cümle (`mission.description`, en çok 70 karakter), tek bir eylem düğmesi. Kazanım ve kaynak bilgisi "i" altında durur.
- **İlerleme:** Kaç tezgâhın mühürlendiğini gösteren tek sayaç bulunur. Gezegenin ışığı mühür sayısıyla bir kademe ısınır (`observatory.set_operational_count`).
- **MERİDYEN:** Hikâye anlarında alt şeridin üstünde tek satırlık bir konsol kaydı olarak konuşur. Konuşma balonu ve karakter portresi kullanılmaz.
- **Kilitli istasyonlar** (Köprü, Prizma, Basınç ve sahnesi gelene kadar diğerleri) görünür kalır ama başlatılamaz. Alt şeritte "Kilitli · düzenek kuruluyor" yazar.

## 4. İstasyon: genel deney tasarımı

Her istasyon aynı beş adımla akar. Adımların adları HUD'daki adım sayacında görünür.

| # | Adım | Ne olur | Bitiş koşulu |
|---|---|---|---|
| 1 | **Kriz** | Kayma sahnede kendiliğinden oynar (≤ 8 sn, atlanabilir). Kaybedilecek şey görünür: kapsül, kapı, organ. Cihaz bir değer bekler, gerçek değer başka çıkar. | Oyuncu "Nedenini bul" der |
| 2 | **Sına** | Oyuncu tek değişkeni değiştirir ve sonucu cihazdan okur. Güçler burada kullanılır: Ayır değişken eler, Yavaşlat hızlı olayı okutur, Gör görünmeyeni çizer. | Gerekli ölçümler alındı |
| 3 | **Neden** | Oyuncu kaymanın kaynağını gösterir: bir parçaya tıklar ya da ölçülen değeri girer. Seçenek listesi kullanılmaz, ölçümden gelen kanıt istenir. | Doğru kaynak ya da değer |
| 4 | **Kurtar** | Yeni bir durumda hesap yapılır: farklı yükseklik, kütle ya da organ. Oyuncu değeri girer, düzenek o değerle çalışır. Deneme sayısı sınırlıdır (üç kapsül, kapak penceresi). | Düzenek doğru değerle başarır, `completed.emit()` |
| 5 | **Mühür** | Kayma onarılır, aynı düzenek doğru yasayla yeniden oynar. Işık bir kademe ısınır ve kayıt satırı düşer (STORY.md). | Oyuncu merkeze döner |

**Kurallar:**

- **Tek değişken.** Bir sınamada yalnızca bir şey değişir. Diğer değerler cihazda sabit durur.
- **Veriyi cihaz gösterir.** Sayılar düzeneğin parçası olan ekranda, kadranda ya da cetvelde görünür. Bir nicelik hem sayıyla hem şekille (çubuk, ok, eğri) verilir.
- **Yanlış değer yanlış sonuç verir.** Hatalı giriş düzeneği o değerle çalıştırır ve sonuç sahnede görünür. Ardından en çok 60 karakterlik tek bir neden cümlesi gelir ("Süre uzun: yükseklik fazla").
- **Eksik kavram kısmi hata üretir.** Kurtarma birden çok koşul istiyorsa her eksik koşul ayrı ve tanınabilir bir hata gösterir.
- **Yeniden dene ucuzdur.** Sar gücü aynı koşulu bir tuşla geri getirir. Merkezdeki "Yeniden dene" yeni bir sahne örneği açar.
- **Hesap ile animasyon ayrıdır.** Simülasyon `*_sim.gd`, görünüm `*_view.gd` ya da `*_stage.gd`, akış `mission.gd` içinde durur (AGENTS.md).

**Etkileşim fiilleri.** Her istasyon en az ikisini kullanır:

| Fiil | Örnek |
|---|---|
| Sürükle-bırak | Kapağı yuvaya, belgeyi zaman çizelgesine yerleştirmek |
| Çevir | Kadranla kuvvet, kütle ya da frekans ayarlamak |
| Bağla | Hortumu porta, kabloyu terminale takmak |
| Bırak / başlat | Kızağı, topu ya da pompayı çalıştırmak |
| İşaretle | Grafikte tepeyi, haritada noktayı göstermek |
| Gir | Hesaplanan değeri cihaz panelindeki sayı kutusuna yazmak |

## 5. İstasyon ekranı (HUD)

Bütün istasyonlar `scripts/mission_hud.gd` kullanır. İstasyon kendi panelini ya da düğmesini çizmez.

```
┌──────────────────────────────────────────────────────────────┐
│ ┌ ADIM 2/5 · SINA ─────────────────────┐         [i] [Geç] [←]│
│ │ Kızağı bırak, ivmeyi ekrandan oku.   │                      │
│ └▔▔▔▔▔▔▔▔▔▔▔▔───────────────────────────┘                      │
│                                                              │
│                    SAHNE / DÜZENEK                           │
│                                                              │
│                 ┌ toast ≤ 60 krk ┐                           │
│ ┌ Sar  Yavaşlat  Ayır  Gör ┐                   [ Bırak ▸ ]   │
└──────────────────────────────────────────────────────────────┘
```

| Bölge | İçerik | Kural |
|---|---|---|
| Sol üst | Adım sayacı ve yönerge kartı | Emir kipinde tek cümle, en çok 90 karakter. Kartın alt kenarında adım ilerleme çizgisi. |
| Sağ üst | i, Geç (yalnızca kriz animasyonunda), ← Merkez | Bu üçü tek bir grup olarak durur. Başka bir şey eklenmez. |
| Sol alt | Güç şeridi | Her istasyonda aynı yerdedir. Kullanılamayan güç soluk görünür ve kilit simgesi taşır. |
| Sağ alt | Tek ana eylem | Amber PrimaryButton. Her an en çok bir tane. |
| Alt orta | Toast | En çok 60 karakter, 4,5 sn görünür. Kontrollerin üstüne binmez: güç şeridi ve eylem düğmesinin üzerinde durur. |
| Orta | Sahne | Kenarlarda 24 px güvenli alan. Sahne öğeleri HUD bölgelerinin altına girmez. |

Ayrıntı ve kazanım notu "i" düğmesi altında, en çok iki cümledir.

## 6. Görsel sistem

### Renk

| Simge | Hex | Kullanım |
|---|---|---|
| `BG` | `#070B12` | Zemin |
| `PANEL` / `PANEL_RAISED` | `#0F1824` / `#162538` | Kart, düğme gövdesi |
| `EDGE` / `EDGE_STRONG` | `#2C4560` / `#41627F` | 1 px kenar |
| `INK` / `MUTED` | `#E8F1F2` / `#8FA6B3` | Metin, ikincil metin |
| `ACCENT` | `#6FE3C1` | Ölçüm, odak, onarılmış durum |
| `WARM` | `#F2A65A` | Eylem, beklenti, sıradaki |
| `DANGER` | `#E5645A` | Arıza, hata |
| Büyüklük A / B / bileşke | `#7FB6F5` / `#6FE3C1` / `#F2A65A` | Vektör ve seri renkleri |
| Kan O₂'li / O₂'siz | `#D8352F` / `#4A5FA8` | Yalnızca Kalp Odası |

Durum asla yalnızca renkle verilmez, yanına simge, yazı ya da hareket eklenir.

### Yazı

| Rol | Boyut (720p) | Yüz |
|---|---:|---|
| Oyun adı | 56–64 | Meridian Display |
| İstasyon adı | 28–32 | Meridian Display |
| Yönerge | 22 | IBM Plex Sans |
| Cihaz rakamı | 24–28 | IBM Plex Sans, tabular rakam |
| Gövde, toast | 15–16 | IBM Plex Sans |
| Bölüm etiketi | 12, büyük harf, 1 px aralık | IBM Plex Sans SemiBold |

Gövde yazı tipi IBM Plex Sans'tır. Inter yalnızca yedek yazı tipi olarak kalır. Display yüz yalnızca ad ve başlıkta kullanılır. Yönergede ve gövde metninde kullanılmaz.

### Ölçü ve hareket

- **Izgara:** 8 px. Köşe yarıçapı 6 px (düğme) ve 8 px (kart). Kenar 1 px. Gölge yalnızca kayan kartlarda kullanılır.
- **Hareket:** Hover 120 ms. Panel giriş ve çıkışı 200–250 ms, ease-out. Kamera geçişi 600 ms. Toast'ın sönmesi 600 ms. Döngüsel nabız yalnızca "sıradaki" kaidede bulunur.
- **Ses** (`Sfx`): tık, doğru, yanlış, mühür. Her olay kendi sesini çalar ve ses tek başına bilgi taşımaz.

### Misafir imzası

Misafir imzası tek bir bileşenle ve her sahnede aynı biçimde çizilir: kenarda 2–3 px kırmızı-camgöbeği ayrışma, kısa doğrusal olmayan titreme ve cihazda bir an görünen anlamsız sayı. Kriz ve gözlemevindeki aktif kayma bu bileşeni kullanır. Onarımdan sonra imza silinir.

## 7. 3D tezgâh standardı: gece laboratuvarı

Fizik, kimya ve biyoloji düzenekleri aynı odada geçiyormuş gibi görünür. Referans Düşüş Odası'dır (`stations/free_fall/assets/chamber_bg.png`).

| Öğe | Kural |
|---|---|
| Oda | Koyu laboratuvar: arka duvar karanlık, uzak pencere gece mavisi. Hangar fotoğrafı ve gri sonsuz zemin kullanılmaz. Arka plan bulanık ve koyulaştırılmış olur, düzenekle yarışmaz. |
| Işık | Düzeneğin üstünde tek sıcak spot (amber, ~3200 K) ve soğuk mavi dolgu ışığı. Hafif sis. Düzenek, odanın en parlak yeridir. |
| Tezgâh | Mat koyu çelik ya da kompozit üst yüzey. Ahşap doku ve desenli halı kullanılmaz. Tezgâh kenarı kadrajı yatayda keser. |
| Kamera | Üç çeyrek önden ve hafif yukarıdan bakan sabit kadraj. Gerekirse sınırlı yörünge ya da yakınlaştırma eklenir. Kriz ve mühür anlarında bir kez kamera hareketi yapılabilir. |
| Cihaz ekranı | `screen_3d.gd`: en çok 4 değer, rakamlar ekranda en az 24 px yüksekliğinde. Eksen etiketleri 720p'de okunmuyorsa çizilmez. |
| 3D yazı | Yazı yalnızca gerçek cihaz yüzeyinde bulunur (kadran altı, ekran). Ekranda 16 px'ten küçük kalacaksa 2D katmanda, nesneye iliştirilmiş etiket olarak çizilir. Eğik ve bulanık Label3D kullanılmaz. |
| Varlık | Gerçek laboratuvar ekipmanı kullanılır: hava rayı, kızak, manyetik kutup, vakum tüpü, beher. Oyuncak, çizgi film ve stilize araba kullanılmaz. Ölçek tutarlı olur: masa ~0,9 m, cetvel gerçek uzunlukta. |
| Kontrol | Kadran, düğme ve şalter düzeneğin ön panelinde durur (`knob_3d`, `button_3d`). Üzerinde ya da altında okunur değer bulunur. |

**Matematik istisnası:** Grafik ve şekil 3Blue1Brown çizgisinde olabilir: koyu zemin, ince parlak çizgiler, şekil-sayı-formül aynı renkte. Bu çizim de yine bir düzeneğin parçası olarak gelir (levha, depo, köprü).

## 8. Ders bazında tasarım

Her ders aynı beş adımı kullanır, ama kendi "laboratuvarı", ölçü aracı ve hata biçimi vardır. Sözel derslerde de oyuncu bir nesneyle çalışır. Çoktan seçmeli, eşleştirme ya da sıralama kartı tek başına bir görev sayılmaz. Bu biçimler ancak bir düzeneğin kontrolü olarak kullanılabilir.

### Fizik (gece laboratuvarı, gerçekçi)

- **Ölçü aracı:** Fotokapı, kronometre ekranı, kuvvet ölçer, cetvel, manometre, ve cihaz ekranındaki zaman grafiği.
- **Kayma:** Bir yasanın tek parametresi kaydırılır (g = 6, ivme kütleden bağımsız, momentum yönsüz).
- **Sına:** Güçlerle tek değişken ayrılır. Grafiğin eğimi ya da alanı ekranda okunur.
- **Kurtar:** Yeni koşulda değer hesaplanıp girilir. Kapsül, kızak ya da araba o değerle gerçekten hareket eder.
- **Yasak:** Oyuncak araç, sahte HUD yazısı, okunmayan grafik.

### Kimya (aynı laboratuvar, ıslak tezgâh)

- **Ölçü aracı:** pH metre, renk tüpü sırası, terazi, büret ve damla sayacı, gaz şırıngası.
- **Kayma:** Gösterge yanlış renk verir, tepkime kütleyi "kaybeder", denge yanlış yöne kayar.
- **Sına:** Damlatma, karıştırma ve ısıtma. Renk ve sayı birlikte değişir, renk körü oyuncu için pH değeri de yazılır.
- **Kurtar:** Bilinmeyen numunenin değeri ölçülüp doğru vana ya da hatta yönlendirilir. Yanlış hatta giden numune tankta görünür bir tepki verir.
- **Spin Hattı:** Kimya kazanımına bağlıdır (11. sınıf, Modern Atom Teorisi). Fizik düzeneği olarak kurulur.

### Biyoloji (anatomi tezgâhı, gerçekçi)

- **Ölçü aracı:** Monitör dalga biçimi, akış oku (yazılı "akış" ile), oksijen göstergesi, mikroskop.
- **Kayma:** Sistemin tek yönlülüğü ya da düzenleyicisi bozulmuştur (kapak ters, damar yanlış bağlı).
- **Sına:** Kelepçe, kanül ve parça değiştirme. Monitör hemen tepki verir.
- **Kurtar:** Yeni bir hasta değeri girilir (debi = nabız × atım hacmi). Doku oksijen göstergesi düzelir.
- **Kapsam:** AYT düzeyi. Klinik içerik (stent, darlık, tansiyon) yoktur. Anatomi doğru olur: odacık sayısı, damar yönü.

### Matematik (3Blue1Brown çizgisi, düzeneğe bağlı)

- **Ölçü aracı:** Sürüklenebilir şekil, canlı grafik, cetvel ve iletki, teğet çizgisi.
- **Kayma:** Hesabın yerine tahmin geçmiştir. Kutu küçük çıkar, köprü oturmaz.
- **Sına:** Bir köşe sürüklenince kenar, alan ve formüldeki terim aynı renkte birlikte değişir.
- **Kurtar:** Yeni ölçüde değer hesaplanıp girilir. Düzenek o ölçüyle üretilir ve oturmazsa boşluk ya da taşma görünür.
- **Yasak:** Statik formül kartı, şekilsiz sayı sorusu.

### Türkçe ve Edebiyat (arşiv masası, sıcak lamba)

- **Ortam:** Gece arşiv odası. Kâğıt, dizgi kasası ve büyüteç.
- **Ölçü aracı:** Metnin kendisi. Kanıt cümlenin altı çizilir, bağlaç gösterilir.
- **Kayma:** Bir metnin bağlacı ya da cümle sırası değiştirilmiştir ve anlam tersine dönmüştür.
- **Sına:** Oyuncu kopuk sayfadaki parçaları yerleştirir. Metin her yerleşimde yeniden okunur ve tutarsızlık işaretlenir.
- **Kurtar:** Yeni bir parçada yanlış yorumu kanıt cümlesiyle çürütür. Cevap seçilmez, kanıt metinde işaretlenir.
- **Edebiyat:** Dönem kanıtları (dil özelliği, nazım biçimi) bir eserin rafını belirler. Yanlış rafa konan eser kayıt defterinde tutarsızlık bırakır.

### Tarih (arşiv masası, ışık masası)

- **Ölçü aracı:** Tarih damgası, mühür, UV ışık masası, zaman çizelgesi rayı.
- **Kayma:** Kronoloji ya da kaynak değiştirilmiştir. Sahte bir belge birincil kaynak gibi görünür.
- **Sına:** Belge ışık masasına konur. Tarih, imza ve dönem dili incelenir.
- **Kurtar:** Olaylar (Amasya → Erzurum → Sivas → TBMM) raya yerleştirilir. Yanlış sırada sonraki karar "dayanaksız" kalır ve ray o noktada kopar.

### Coğrafya (kabartma masası)

- **Ölçü aracı:** Güneş lambası, gölge çubuğu, enlem ve boylam cetveli, iklim grafiği.
- **Kayma:** Harita kaydırılmıştır, gölge ve mevsim tutmaz.
- **Sına:** Lambanın açısı değiştirilir ve gölge boyu ölçülür.
- **Kurtar:** Verilen gölgeden enlem bulunur. Pin doğru yere düşmezse rota sapar.

### Felsefe, Mantık, Psikoloji, Sosyoloji, Din Kültürü (Fikir Meydanı)

- **Ortam:** Gözlemevinin konsey odası. Karakterler sade silüetlerdir ve yüz çizilmez (AI anatomi riski).
- **Felsefe:** Bir karakter bir iddiayı savunur. Oyuncu karşı örnek ya da itiraz kartını iddianın zayıf öncülüne bağlar. Doğru bağlantıda karakter gerekçesini yeniden kurar.
- **Mantık:** Önermeler bir devre panosunda lamba ve şalter olarak durur. Doğruluk tablosu devrenin kendisidir. Yanlış çıkarım kapıyı açmaz.
- **Psikoloji:** Algı deneyi sahnede yapılır (yanılsama, dikkat). Oyuncu ölçüm sonucuyla iddiayı karşılaştırır.
- **Sosyoloji:** Toplum ağı bir düğüm-bağ panosudur. Bağları değiştirince ağın davranışı değişir.
- **Din Kültürü:** Bir ahlaki ilke vaka üzerinde uygulanır. Kaynak metin (ayet, hadis, ilmihal) doğrudan alıntılanır ve kaynağı belirtilir. Yorum yerine kaynağa dayalı kanıt istenir.

### YDT İngilizce (telsiz odası)

- **Ölçü aracı:** Kesik yayın kaydı, frekans kadranı, transkript şeridi.
- **Kayma:** Mesajın bir bağlacı ya da zamanı bozulmuştur ve talimat ters anlaşılır.
- **Sına:** Frekans ayarlanır ve kayıp kelime bağlamdan bulunur.
- **Kurtar:** Doğru anlam düzeneği çalıştırır. Yanlış anlamda ekip yanlış kapıya gider ve bu sahnede görünür.

> **YKS mikro görevleri hakkında not:** `stations/yks/` görevleri şu an ortak bir test kabuğunda soru olarak (choice, pair, sequence) duruyor. Bunlar ders başına yukarıdaki ortama geçirilir. `yks_mission_definition.gd` veri kaynağı olarak kalır. `mode` bir soru biçimini değil, düzeneğin kontrol biçimini anlatır.

## 9. Mevcut istasyonların durumu

| İstasyon | Rota | Durum | Yapılacak |
|---|---|---|---|
| Düşüş Odası | AYT Fizik | Referans, iyi | HUD v2, güç şeridi konumu |
| Newton Kızağı | AYT Fizik | 3D tezgâh | Oyuncak araba yerine hava rayı kızağı. Okunur kadran etiketleri. Gece laboratuvarı. |
| Atış Alanı | AYT Fizik | 3D tezgâh | Gece laboratuvarı. Monitör okunurluğu. Mesafe etiketleri. |
| Çarpışma Hattı | AYT Fizik | 3D tezgâh | Gece laboratuvarı. Etiket temizliği. |
| Spin Hattı | AYT Kimya | 3D tezgâh, görsel şov | Kadran etiketleri okunur. Ekran yerleşimi. Toast taşması. |
| Dalga Girişimi | AYT Fizik | Düz shader ve sağ panel | Dalga leğeni (ripple tank) olarak tezgâha taşınır. Sağ panel cihaz ekranına döner. |
| Fotoelektrik Kapısı | AYT Fizik | 2D | Gece laboratuvarı ve HUD v2 |
| Vektör Limanı | AYT Fizik | 2D çizim | Kriz ve kurtarma akışı. Liman düzeneği. |
| Ölçüm Atölyesi | TYT Fizik | 2D | Gece laboratuvarı tezgâhı |
| Mevsim Gözlemevi | LGS Fen | 2D diyagram | Gözlemevinin içinde lamba ve küre düzeneği |
| Depo Atölyesi | AYT Mat | 3B1B | Levha düzeneği ve HUD v2 |
| Gösterge Laboratuvarı | LGS Fen | Oynanabilir | Islak tezgâh standardı |
| Kalp Odası | AYT Biyoloji | 3D, derin | Gece laboratuvarı ışığı ve HUD v2 |
| YKS mikro görevleri (13) | TYT/AYT/YDT | Test kabuğu | Bölüm 8'deki ortamlara geçirilir |
| Üç Güneş | Final | Oynanabilir | Mühür ve kapanış anı |
| Köprü, Prizma, Basınç | Sınıf/LGS | Sahne yok | Kilitli kaide |

## 10. Uygulama sırası

1. **Tasarım öğeleri:** `ui_theme.gd` yazı ve renk simgelerini bu belgeye göre sabitler. `stage_kit.gd`, `mission_hud.gd` ve YKS kabuğundaki kopya renk sabitleri temaya bağlanır.
2. **HUD v2:** Sağ üst grup, sabit güç şeridi, çakışmayan toast ve 90/60 karakter denetimi (debug uyarısı).
3. **Gözlemevi v2:** Kaideler seçilebilir olur. Üst ve alt şerit eklenir. Liste ve gri paneller kaldırılır. Kilitli, hazır ve mühürlü durumlar kurulur. Açılış metni hikâyeye bağlanır.
4. **Tezgâh standardı:** `lab_stage_3d.gd` gece laboratuvarı ortamını, ışığı ve okunur etiketi tek yerden verir.
5. **İstasyon geçişi**, jüri rotası önce: Düşüş, Newton, Atış, Çarpışma, Spin, Dalga, Kalp, sonra diğerleri.
6. **YKS görevleri:** Ders ortamları (arşiv masası, kabartma masası, Fikir Meydanı, telsiz odası) önce ortak sahneler olarak kurulur. Ardından görevler bu sahnelere taşınır.
7. **Mühür ve final cilası.**

## 11. Kabul listesi

Her ekran ve istasyon teslimden önce aşağıdaki ölçütlerle kontrol edilir:

- [ ] 1280×720'de, Godot içinde ekran görüntüsüyle incelendi. Tüm yazılar okunuyor, hiçbir öğe kırpılmıyor.
- [ ] Yönerge ≤ 90, toast ≤ 60 karakter. Ekranda paragraf yok.
- [ ] Her durum renk dışında simge, yazı ya da hareketle de veriliyor.
- [ ] Kriz, Sına, Neden, Kurtar ve Mühür adımlarının hepsi var. Kriz animasyonu atlanabiliyor.
- [ ] Doğru giriş, yanlış giriş (sahnede yanlış sonuç), yeniden deneme ve merkeze dönüş (Esc) denendi.
- [ ] Sahnede oyuncak, stil dışı varlık, bozuk anatomi, eğik ya da bulanık yazı yok.
- [ ] F6 ile tek başına ve F5 ile ilgili rotadan açıldı. Akış testi geçiyor.
