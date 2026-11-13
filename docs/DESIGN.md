---
version: alpha
name: Yanlış Dünya
description: Gece gözlemevinde geçen Türkçe bilim oyunu. Giriş katmanı zengin bir oyun menüsü, deneyler gerçekçi 3D laboratuvar.
colors:
  bg: "#070B12"
  surface: "#0F1824"
  surface-raised: "#162538"
  surface-sunken: "#0A121D"
  edge: "#2C4560"
  edge-strong: "#41627F"
  ink: "#E8F1F2"
  ink-muted: "#8FA6B3"
  ink-faint: "#5D7382"
  accent: "#6FE3C1"
  accent-dim: "#38786F"
  warm: "#F2A65A"
  warm-deep: "#C98638"
  on-warm: "#1A1006"
  danger: "#E5645A"
  danger-deep: "#5A2420"
  focus: "#9AF1DA"
  shadow: "#02050A"
  series-a: "#7FB6F5"
  series-b: "#6FE3C1"
  series-sum: "#F2A65A"
  blood-oxy: "#D8352F"
  blood-deoxy: "#4A5FA8"
typography:
  hero:
    fontFamily: Rajdhani
    fontSize: 72px
    fontWeight: 700
    lineHeight: 1.02
    letterSpacing: 2px
  screen-title:
    fontFamily: Rajdhani
    fontSize: 36px
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: 1px
  section:
    fontFamily: Rajdhani
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.08
  button:
    fontFamily: Rajdhani
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.0
    letterSpacing: 0.6px
  directive:
    fontFamily: Barlow
    fontSize: 22px
    fontWeight: 500
    lineHeight: 1.3
  body:
    fontFamily: Barlow
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-strong:
    fontFamily: Barlow
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.5
  label:
    fontFamily: Barlow Semi Condensed
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.25
  readout:
    fontFamily: Barlow Semi Condensed
    fontSize: 28px
    fontWeight: 500
    lineHeight: 1.0
    fontFeature: tnum
  readout-sm:
    fontFamily: Barlow Semi Condensed
    fontSize: 18px
    fontWeight: 500
    lineHeight: 1.0
    fontFeature: tnum
  key-hint:
    fontFamily: Barlow Semi Condensed
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.0
rounded:
  none: 0px
  sm: 2px
  md: 4px
  chamfer: 10px
spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  safe: 24px
components:
  button-primary:
    backgroundColor: "{colors.warm-deep}"
    borderColor: "{colors.warm}"
    textColor: "{colors.on-warm}"
    typography: "{typography.button}"
    rounded: "{rounded.chamfer}"
    height: 48px
  button-secondary:
    backgroundColor: "{colors.surface-raised}"
    borderColor: "{colors.edge}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.chamfer}"
    height: 40px
  button-quiet:
    backgroundColor: transparent
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
    height: 32px
  focus-ring:
    borderColor: "{colors.focus}"
    width: 2px
    offset: 2px
  tab:
    textColor: "{colors.ink-muted}"
    activeTextColor: "{colors.ink}"
    activeIndicator: "{colors.accent}"
    typography: "{typography.button}"
    height: 40px
  panel:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.edge}"
    rounded: "{rounded.chamfer}"
    padding: "{spacing.lg}"
  panel-floating:
    backgroundColor: "rgba(15,24,36,0.92)"
    borderColor: "{colors.edge-strong}"
    rounded: "{rounded.chamfer}"
    padding: "{spacing.md}"
    shadow: "0 6px 16px {colors.shadow}"
  hud-directive:
    backgroundColor: "rgba(15,24,36,0.94)"
    borderColor: "{colors.edge-strong}"
    textColor: "{colors.ink}"
    typography: "{typography.directive}"
    rounded: "{rounded.chamfer}"
    maxChars: 90
  step-bar:
    segmentColor: "{colors.edge}"
    doneColor: "{colors.accent-dim}"
    currentColor: "{colors.accent}"
    height: 3px
  toast:
    backgroundColor: "rgba(7,11,18,0.92)"
    borderColor: "{colors.edge-strong}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.md}"
    maxChars: 60
  readout:
    textColor: "{colors.accent}"
    typography: "{typography.readout}"
    labelTypography: "{typography.label}"
  input-number:
    backgroundColor: "{colors.surface-sunken}"
    borderColor: "{colors.edge}"
    focusBorderColor: "{colors.focus}"
    typography: "{typography.readout-sm}"
    rounded: "{rounded.md}"
    height: 44px
  key-hint:
    borderColor: "{colors.edge-strong}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.key-hint}"
    rounded: "{rounded.sm}"
---

# Yanlış Dünya · DESIGN.md

Bu dosya oyunun görsel ve etkileşim tasarımı için tek kaynaktır. Biçimi [Google Stitch DESIGN.md](https://github.com/google-labs-code/design.md) standardını izler: üstteki YAML ölçülebilir değerleri (token) verir, metin ise gerekçeyi ve kullanım kuralını anlatır. Yapay zekâ izine karşı koyduğu taban kuralları [Hallmark](https://github.com/nutlope/hallmark) kural setinden Godot'a uyarlanmıştır (bkz. **Slop Floor** bölümü).

Bu belge `docs/UX.md`, `docs/ART_DIRECTION.md` ve `assets/ui/VISUAL_LANGUAGE.md` dosyalarının yerine geçer. Hikâye [STORY.md](STORY.md), müfredat [CURRICULUM.md](CURRICULUM.md), ekip ve dal kuralları [AGENTS.md](../AGENTS.md) içinde kalır.

**Kural düzeyleri.** Belgedeki her kural üç düzeyden birindedir:

- **ZORUNLU**: Pazarlık yoktur. Kural ihlal edilirse teslim geri döner.
- **VARSAYILAN**: Kural uygulanır. Daha iyi bir çözüm varsa ondan ayrılınabilir, ama gerekçesi PR açıklamasına bir cümleyle yazılır.
- **SERBEST**: Ajanın ya da tasarımcının kendi alanı. Belge yalnızca hedefi söyler.

Belge stili ve sistemi sabitler, fikirleri değil. Bir istasyonun düzeneği, kamerası, kriz sahnesi ve etkileşim fikri onu yapana aittir. Belge bir şeyi yasaklamıyorsa izin verir.

## Overview

### Ürün

**Yanlış Dünya**, ortaokuldan YKS'ye kadar fen, matematik ve sosyal derslerini öğreten Türkçe bir masaüstü oyunudur. Godot 4.7 ile yapılır, temel çözünürlüğü 1280×720'dir. Rotalar: Sınıflar (5–12), LGS, YKS (TYT, AYT ve isteğe bağlı YDT).

Üç güneşli kaotik bir dünyadan gelen Misafirler, Dünya'nın yasalarına küçük kaymalar bırakır: çekim zayıflar, kalp kapağı ters çalışır, bir belgenin tarihi değişir. Gözlemevinin kalibrasyon asistanı **MERİDYEN** başta oyuncuya yardım eder. Kampanyanın ortasında kaymaları Misafirler adına kendisinin bıraktığı ortaya çıkar. Oyuncu **Kalibratör**'dür. Her kaymayı bir deneyde ölçerek bulur, düzeneği doğru değerle kurtarır ve yasayı mühürler. Final Üç Güneş'tir: iki cisim öngörülebilir, üç cisim öngörülemez.

### İki katman, iki karakter

| Katman | Ekranlar | Karakter |
|---|---|---|
| **Giriş katmanı** | Başlık ekranı, gözlemevi (kampanya), kayıt defteri, ayarlar, hikâye iletimleri | **Zengin oyun arayüzü.** Bir AAA oyun menüsü gibi yoğun ve katmanlıdır: sekmeler, ilerleme, gerçek istatistik, durum simgeleri, tuş ipuçları, düzenek önizlemesi. Yoğunluğu kelimeden değil veriden gelir. |
| **Deney katmanı** | İstasyonlar | **Gerçekçi 3D laboratuvar.** Arayüz geri çekilir: bir yönerge, cihaz göstergeleri ve tek eylem düğmesi. Bilgiyi düzenek verir. |

Bu ayrım ZORUNLU'dur. Giriş katmanının yoğunluğu deneye taşınmaz. Deneyin sadeliği de girişi boş bırakmaya gerekçe olamaz.

### Tasarım sütunları (ZORUNLU)

1. **Ölç, tahmin etme.** İlerleme bir cihazın gösterdiği değere dayanır. Şıklardan tahminle geçilemez.
2. **Yanlış, sahnede yanlış görünür.** Hatalı değer düzeneği o değerle çalıştırır: kapsül kırılır, kapı açılmaz, kan geri kaçar. Puan düşürmek bir sonuç sayılmaz.
3. **Elle yapılan iş.** Oyuncu bağlar, sürükler, çevirir, bırakır, ayarlar.
4. **Her öğenin bir işi vardır.** Süs etiketi, boş panel ve amaçsız ışık eklenmez.

### İmza

Oyuncunun hatırlayacağı tek şey şudur: **kayan yasa, onarılan düzenek.** Aynı düzenek önce yanlış yasayla oynar, oyuncunun ölçtüğü değerle düzelir, sonra doğru yasayla yeniden oynar. Bütün tasarım bu anı görünür kılmak için vardır.

### Atmosfer

Gece gözlemevi. Lacivert-siyah bir boşlukta tek bir sıcak ışık (amber) ve ölçümü işaret eden soğuk camgöbeği. Malzemeler mat çelik, cam, kompozit ve kâğıt. Referans duygu: bir uzay ajansının kontrol odası, bir üniversite fizik laboratuvarı ve bir arşivin gece okuma salonu. Neon, siberpunk, çizgi film ve "yapay zekâ fütürizmi" bu dünyanın parçası değildir.

## Colors

Palet YAML'dadır. Her rengin bir rolü vardır ve renkler rolleri dışında kullanılmaz. Kodda renk yalnızca `scripts/ui_theme.gd` sabitlerinden okunur. Dosya içine yazılan `Color("#…")` değerleri tasarım değeri dışında kalır ve bu bir kural ihlalidir (ZORUNLU, Hallmark 48).

- **`bg` ve `surface*`**: Zemin ve paneller. Saf siyah ve saf beyaz kullanılmaz. Panel zeminden yalnızca bir ton açıktır.
- **`accent` (camgöbeği)**: Ölçüm, seçili öğe ve onarılmış durum, yani "şu an buna bak". Bir görünümde arayüz alanının en çok %5'ini kaplar (VARSAYILAN, Hallmark 23).
- **`warm` (amber)**: Eylem ve beklenti: ana eylem düğmesi, sıradaki görev, cihazın beklediği değer. **Bir ekranda tek amber düğme bulunur** (ZORUNLU).
- **`danger`**: Arıza, hata ve Misafir kayması. Geniş alanlara dolgu olarak kullanılmaz.
- **`focus`**: Yalnızca klavye ya da kumanda odak halkası.
- **Seri renkleri**: Vektörler, iki cisim ve bileşke. Aynı nicelik şekilde, sayıda ve formülde aynı rengi taşır.
- **Kan renkleri**: Yalnızca dolaşım sahnelerinde.

ZORUNLU: Hiçbir durum yalnızca renkle verilmez. Yanında simge, yazı, şekil ya da hareket bulunur. Gradyan yalnızca tek tonlu okunurluk örtüsünde (`bg` → saydam) kullanılır. Mor-mavi ve camgöbeği gradyan, arayüz metninin arkasında parlayan leke ve renkli halo kullanılmaz (Hallmark 2a, 29).

## Typography

İki aile kullanılır:

- **Rajdhani** (Indian Type Foundry, OFL): Başlık, ekran adı ve düğme. Köşeli, teknik ve oyun HUD'larında çok kullanılan bir yüz. Yalnızca büyük harfle ve kısa metinlerde kullanılır.
- **Barlow** (Jeremy Tankard, OFL): Gövde metni. **Barlow Semi Condensed** etiketlerde ve ölçüm sayılarında kullanılır. DIN çizgisinde, sıcak bir endüstriyel grotesk.

Seçim, aynı başlık ve gövde örneği Godot'ta 1280×720'de beş adayla dizilerek yapıldı. Adaylar Teko, Rajdhani, Tektur, Antonio ve Oxanium'du ve hiçbiri Hallmark katalog temalarında kullanılmıyor. Barlow Condensed elendi, çünkü Hallmark'ın Piste teması başlıkta onu kullanıyor. Dosyalar `assets/fonts/rajdhani/` ve `assets/fonts/barlow/` altında. Türkçe karakterlerin tamamı doğrulandı. Rajdhani'de `²` yoktur, bu yüzden sayı ve birim her zaman Barlow Semi Condensed ile yazılır.

| Ad | Kullanım | Kural |
|---|---|---|
| `hero` | Oyun adı (wordmark), final başlığı | Büyük harf, ekranda tek |
| `screen-title` | Ekran ve istasyon adı | Büyük harf, tek satır |
| `section` | Panel ve sütun başlığı | Kısa ad, cümle değil |
| `button` | Düğme ve sekme | Büyük harf, en çok 3 kelime, aralık ≤ 0,04em |
| `directive` | Deney yönergesi | Cümle düzeni, emir kipi, en çok 90 karakter |
| `body`, `body-strong` | Künye, toast, iletim | Cümle düzeni, en az 16 px |
| `label` | Gösterge etiketi, durum, tablo başı | **Cümle düzeni, harf aralığı yok**, gövdeden bir basamak küçük |
| `readout`, `readout-sm` | Ölçüm sayıları | `tnum` açık, birim ince boşlukla, ondalık virgül (`9,81 m/s²`) |
| `key-hint` | Tuş ipucu | Tuş kutu içinde, eylem yanında, cümle düzeni |

ZORUNLU kurallar:

- **Aralıklı büyük harf etiket kullanılmaz** (Hallmark 67). 15 px ve altındaki hiçbir metin büyük harfle ya da 0,03em'den geniş aralıkla yazılmaz: etiket, durum, tablo başı, adım adı. Büyük harf yalnızca Rajdhani başlıkları ve düğmelerinde kullanılır.
- **Başlık üstü kicker (eyebrow) kullanılmaz** (Hallmark 54). Başlığın üstüne onu duyuran küçük bir yazı konmaz ("KONTROL MERKEZİ" üstte, "Yanlış Dünya" altta gibi). Sekme adı, birim, konuşmacı adı ve canlı durum bu kuralın dışındadır.
- Başlık tek ağırlıkta ve tek renkte olur. Tek kelimeyi renk ya da ağırlıkla ayırma yoktur (Hallmark 38iii).
- Inter, Roboto, Arial, Open Sans, IBM Plex, Space Grotesk, Montserrat, Poppins ve Godot'un varsayılan yazı tipi hiçbir ekranda görünmez. Tema her `Control` ağacına ulaşır.
- Türkçe büyük harf: `i → İ`, `ı → I`. Büyük harfli metin kaynakta büyük harfle yazılır, `to_upper()` güvenilmez.
- Satır uzunluğu en çok 65 karakterdir. Çok satırlı metnin satır aralığı en az 1,3'tür.

## Layout

Temel tuval 1280×720'dir (`canvas_items` germe).

- **Izgara:** 4 px taban, 8 px ritim. Ekran kenarında `safe` = 24 px, buraya hiçbir arayüz öğesi girmez.
- **Hizalama:** Ortak sol kenar çizgisi. Başlık, sekme ve panel aynı x'ten başlar. Ortalanmış metin yalnızca toast ve tam ekran iletimde kullanılır.
- **Kap:** Kart içinde kart yoktur. Her bölgede tek bir kap katmanı bulunur (Hallmark 4).
- **Yoğunluk:** Giriş katmanı bir uygulama ekranı gibi yoğundur. Kelime sınırı yoktur, ama düz yazı (künye, iletim) ekran başına 40 kelimeyi geçmez. Deney katmanında görünür kelime 30'u, arayüz alanı ekranın %22'sini geçmez (VARSAYILAN).
- **Taşma:** 1280×720'de hiçbir metin kırpılmaz ve hiçbir panel kaydırma çubuğu göstermez (ZORUNLU). Uzun liste sayfalanır ya da gruplanır. 1920×1080'de kenar boşlukları büyür, satır uzunluğu büyümez.

## Elevation & Depth

Derinlik ışık ve katmanla verilir:

1. **Dünya**: 3D sahne.
2. **Örtü**: Giriş katmanında sol kenardan `bg` %85 → %0 tek tonlu gradyan, okunurluk için.
3. **Panel**: `surface`, 1 px `edge`, gölgesiz.
4. **Kayan öğe** (toast, iletim, açılır künye): `panel-floating`, ofsetli ve bulanık `shadow` ile.
5. **Odak**: 2 px `focus` halkası, 2 px boşlukla, anında görünür ve arka plana karşı en az 3:1 kontrastlı (Hallmark 26a). Odakta öğe büyümez, parlamaz.

Arayüzde bulanık cam (blur) ve sıfır ofsetli renkli parıltı kullanılmaz (Hallmark 29).

## Shapes

- **Kesik köşe (`chamfer`)**: Panel ve düğmelerin sağ üst ve sol alt köşeleri 10 px kesiktir. Bu, oyunun imza biçimidir (VARSAYILAN). 9 dilimli `panel_glass.png` bu biçimi taşır.
- Yuvarlak köşe en çok 4 px'tir. Hap biçimli düğme ve büyük yuvarlak kart kullanılmaz (ZORUNLU). Her iç içe katmanda tek yarıçap kullanılır.
- **Çizgi:** 1 px. Vurgu çizgisi 2 px.
- **Seçim çentiği:** Seçili satırın ya da sekmenin solunda 3×16 px `warm` dikey çentik. Satırın tamamı boyanmaz.

## Components

YAML'daki bileşenler `scripts/ui_theme.gd` içinde tema türü olarak bulunur: `PrimaryButton`, `SecondaryButton`, `QuietButton`, `ModeTab`, `RouteTab`, `Panel`, `FloatingPanel`, `ReadoutLabel`, `KeyHint`… İstasyon kendi düğme ya da panel stilini çizmez (ZORUNLU).

**Düğmeler.** Her kontrolün sekiz durumu vardır: normal, hover, odak, basılı, pasif, yükleniyor, seçili, hata.
- Hover: kenar açılır (120 ms).
- Basılı: yüz 1 px içe iner.
- Pasif: kenar kesikli, yazı %40 opaklıkta.
- Metin bir fiildir: DÜZENEĞİ BAŞLAT, BIRAK, MÜHÜRLE. TAMAM, DEVAM ve BAŞLA gibi içi boş metinler kullanılmaz.
- Düğme metnine yapışık ok konmaz (Hallmark 63).

**Sekme.** Etkin sekme `ink` renginde ve altında 2 px `accent` çizgi taşır. Rota sekmesinin ilerlemesi ayrı bir satırda yazılır: altta `label`, örneğin "4 / 9 mühür".

**Gösterge.** Etiket (`label`) üstte, sayı ve birim (`readout`) altta. Cihazın beklediği değer `warm` renktedir ve ayrı bir satırdadır.

**Sayı girişi.** Birim kutunun içinde, sağda sabit durur. Virgül de nokta da kabul edilir. Değer Enter ile gönderilir.

**Adım çubuğu.** Deney adımları beş bölümlü bir çubukta gösterilir. Biten adımlar `accent-dim`, geçerli adım `accent` renktedir. Geçerli adımın adı ("Sına") çubuğun yanında `label` olarak yazar. "ADIM 2 / 5 · SINA" gibi noktalı bir meta dizisi kullanılmaz.

**Toast.** Tek cümle, en çok 60 karakter, 4,5 sn. Tonu soldaki çizilmiş simge ve kenar rengi verir. Emoji ve `✓` gibi metin simgesi kullanılmaz.

**İletim (MERİDYEN).** Alt üçte birde tam genişlikte bir şerit. Solda konuşmacı adı ("MERİDYEN", bir byline), sağda tek satır, harf harf yazılır. Esc ile geçilir.

**Tuş ipucu.** `[Enter] Başlat   [Esc] Geri   [← →] Seç`. Giriş katmanında alt şeritte durur. Kumanda bağlıysa kumanda simgeleriyle değişir.

**Durum simgeleri.** `assets/ui/` altındaki çizilmiş simgelerdir. Unicode ya da emoji kullanılmaz (Hallmark 30a).

| Durum | Simge |
|---|---|
| Kilitli | Kapalı asma kilit |
| Hazır | Açıklık ve amber çentik |
| Sıradaki | Hazır simgesi ve yavaş nabız |
| Mühürlendi | Altıgen mühür ve onay |
| Kayma aktif | Kırık çizgi |

**Veri bölgeleri.** Veri gösteren her bölgenin dört hâli vardır: yükleniyor, boş, hata ve dolu. Örneğin kayıt defteri boşken "Henüz mühür yok. İlk düzeneği onar." yazar ve tek bir eylem sunar.

## Do's and Don'ts

**Yap**

- Bir değeri hem sayıyla hem şekille göster: çubuk, ok, eğri, dolum.
- Düğme metnini fiille, yönergeyi emir kipinde ve tek cümleyle yaz.
- Giriş katmanını oyuncunun gerçek verisiyle doldur: mühür sayısı, deneme sayısı, en iyi süre, kazanım kodu. Veri yoksa alan boş durum gösterir.
- Her ekranı ve istasyonu teslimden önce 1280×720'de ekran görüntüsü alarak incele.
- Sahnede gerçek nesne kullan: hava rayı, kronometre, pH metre, beher, belge, mühür.

**Yapma**

- Başlık, paragraf ve düğmeden oluşan kartları ızgara hâlinde tekrarlama.
- Meta bilgiyi noktalarla birleştirme ("AYT · Fizik · 5"). Satır, sütun ya da çizgi kullan.
- Uydurma sayı koyma: sahte istatistik, örnek skor, "1.204 Kalibratör" gibi.
- Mor-mavi gradyan, neon, emoji, stok hologram, süs amaçlı dönen halka kullanma.
- Sahneye oyuncak, çizgi film varlığı, bozuk anatomi, eğik ya da bulanık 3D yazı koyma.
- Gerçek nesneyi 2D çizimle taklit etme (`_draw()` ile çizilmiş metal düzenek). Çizim yalnızca gerçek veri grafiği ve şema için kullanılır (Hallmark 47c, 80).
- Üretilmiş görsele okunur metin gömme.
- Aynı bilgiyi iki yerde tekrar etme. Ekran zaten gösteriyorsa toast tekrar söylemez.
- Sürüm rozeti, "BETA" etiketi ve dekoratif sayaç kullanma (Hallmark 66).

---

Aşağıdaki bölümler oyuna özeldir ve standart bölümleri tamamlar.

## Slop Floor

Hallmark'ın taban (Floor) ve refleks (Reflex) kapıları Godot'a şöyle uyarlanmıştır. Floor ZORUNLU'dur ve hiçbir koşulda kaldırılamaz. Reflex VARSAYILAN'dır: PR açıklamasında gerekçesi yazılarak kaldırılabilir.

| # | Kural | Düzey | Godot karşılığı |
|---|---|---|---|
| 48 | Renk ve yazı tipi yalnızca tasarım değerinden okunur | Floor | `UITheme` sabitleri. Dosya içinde `Color("#…")` ve font yolu yazılmaz. |
| 10a | Boyut ve konum yerine dönüşüm canlandırılır | Floor | Tween ile `scale`, `position` (kayma), `modulate`. `size` canlandırılmaz. |
| 26a | Her etkileşimli öğenin anında görünen odak halkası vardır | Floor | `focus` stylebox. Klavye ve kumandayla bütün ekranlar dolaşılabilir. |
| 27 | Her hareketin azaltılmış hareket karşılığı vardır | Floor | Ayarlar: "Hareketi azalt" açıkken kamera ve geçişler anlık olur. |
| 46a | Uydurma sayı, alıntı ya da logo kullanılmaz | Floor | İstatistik yalnızca kayıttan okunur. |
| 54, 67 | Kicker kullanılmaz, aralıklı büyük harf etiket kullanılmaz | Floor | `label` cümle düzeninde ve aralıksız. |
| 63 | Noktalı meta dizisi, metne yapışık ok ve süs nokta kullanılmaz | Floor | Bilgi satıra ya da sütuna bölünür. |
| 2a, 30a, 4 | Mor-mavi gradyan, emoji simge ve kart içinde kart kullanılmaz | Floor | |
| 19 | Yapay zekâ ağzı kullanılmaz | Floor | Aşağıdaki dil listesine bak. |
| 23 | Accent alanı en çok %5 | Reflex | |
| 29 | Arayüzde parıltı ve halo kullanılmaz | Reflex | 3D sahne ışığı (spot, sis) bu kuralın dışındadır. |
| 37 | En çok iki aile, bir istisna | Reflex | Rajdhani ve Barlow |
| 47c, 80 | Gerçek nesne çizimle taklit edilmez | Reflex | Gerçek 3D model ya da fotoğraf kullanılır. |
| 66 | Süs yazısı kullanılmaz | Reflex | Sürüm rozeti, dikey yazı ve anlamsız sayaç yok. |
| 69 | Bir bilgi tek yerde söylenir | Reflex | |

**Dil (ZORUNLU).** Oyundaki her metin Türkçe, kısa ve somut olur.

- Uzun tire (—) ve aralık tiresi (–) metin içinde kullanılmaz. Sayı aralıkları bu kuralın dışındadır.
- Şu kalıplar kullanılmaz:
  - "Harika!", "Hadi başlayalım!", "Tebrikler!"
  - "Bu deneyde … keşfedeceksin"
  - "Yolculuğun başlıyor"
  - "Bilimin büyüleyici dünyası"
  - Üç sıfatlı diziler
  - "Değil X, Y" kalıbının tekrarı
- Doğru cevaba övgü yazılmaz. Sonucu sahne gösterir, metin nedeni söyler: "Mühürlendi. Çekimin kendisi kaymıştı."
- Sayılar Türkçe yazılır: ondalık virgül, binlik nokta.

## Screens · Giriş katmanı

Giriş katmanı `scenes/` ve `scripts/control_center.gd` altındadır. Hallmark'ın uygulama ekranı kuralları burada geçerlidir: yoğunluk tasarımın kendisidir, bilinen kalıplar (sekme, liste, künye) icat edilen kalıplardan iyidir ve hareket yalnızca durumu anlatır.

### Başlık ekranı

3D gözlemevi açılır ve kamera gezegene doğru yavaşça kayar. Solda `hero` "YANLIŞ DÜNYA" ve altında tek bir cümle durur. Altında dikey menü yer alır:

- DEVAM ET (kayıt varsa birincil düğme)
- YENİ KAMPANYA
- ROTALAR
- AYARLAR
- ÇIKIŞ

Sağ altta tuş ipuçları durur. İlk açılışta önce açılış sahnesi oynar.

### Açılış

En çok 15 sn sürer ve atlanabilir. Kayma bir kez, gözlemevinin içinde ve Misafir imzasıyla görünür. En çok üç kısa ara yazı vardır, anlatıcı yoktur.

### Gözlemevi (kampanya ekranı)

Ana ekran budur. Arkada canlı 3D gözlemevi ve kubbe yayında istasyon kaideleri bulunur.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ YANLIŞ DÜNYA     SINIFLAR   LGS   [YKS]       TYT      AYT      YDT  [ayar] │
│                                               4/9      2/11     0/1        │
├───────────────────────┬────────────────────────────────┬─────────────────┤
│ BÖLÜM I  ÖLÇÜ          │                                │ DÜŞÜŞ ODASI     │
│ 2 / 6 mühür            │                                │ AYT Fizik       │
│ ───────────────        │      3D GÖZLEMEVİ               │ Kazanım F-5     │
│ ▌[mühür] Vektör Limanı │      kaideler yayda            │ [düzenek render]│
│ ▌[sıra]  Düşüş Odası   │      seçili kaide aydınlık     │ Her şey         │
│  [hazır] Newton Kızağı │                                │ beklenenden     │
│  [hazır] Atış Alanı    │                                │ yavaş düşüyor.  │
│  [kilit] Köprü         │                                │ Deneme   2      │
│ ───────────────        │                                │ En iyi   1:42   │
│ BÖLÜM II  YAŞAM        │                                │[DÜZENEĞİ BAŞLAT]│
├───────────────────────┴────────────────────────────────┴─────────────────┤
│ MERİDYEN   Ölçüm değişmiş. Bu sonuç başlangıç verilerimde yok.             │
│ [Enter] Başlat   [← →] İstasyon   [Tab] Rota   [L] Kayıt defteri   [Esc]   │
└──────────────────────────────────────────────────────────────────────────┘
```

- **Üst şerit:** Wordmark, mod sekmeleri, rota sekmeleri (adı ve altında ilerleme) ve ayarlar.
- **Sol sütun:** Rotanın bölümleri (I Ölçü, II Yaşam…) başlık olarak, altında görevler ve durum simgeleri. Seçili satırda amber çentik. Alan seçici (Sayısal, EA, Sözel) ve sınıf seçici bu sütunun başında açılır menü olarak durur.
- **Orta (3D):** Kaideler. Listedeki seçim kamerayı kaideye çevirir, kaideye tıklamak da listeyi seçer. İkisi her zaman aynı durumdadır. Kilitli kaide örtülüdür, mühürlü kaide camgöbeği ışıkla yanar.
- **Sağ sütun (künye):**
  - İstasyon adı, ders ve kazanım kodu (her biri kendi satırında).
  - Düzeneğin önizleme render'ı.
  - Kayma cümlesi (en çok 70 karakter).
  - Oyuncunun gerçek istatistiği: deneme sayısı, en iyi süre, mühür tarihi.
  - Tek birincil düğme.
  - Kaynak ayrıntısı "i" ile açılır.
- **Alt şerit:** MERİDYEN iletimi ve tuş ipuçları.
- **Kayıt defteri (L):** Mühürlenen yasaların koleksiyonu. Her satırda kayıt cümlesi, istasyon ve tarih yazar.
- **Kilitli istasyonlar:** Sahnesi olmayan istasyonlar kilitli görünür. Künyede "Düzenek kuruluyor" yazar ve başlatılamaz.

SERBEST: kamera yolları, kaide modelleri, gezegenin ve kubbenin mühür sayısına göre değişimi, geçişler.

### Mühür ekranı

Deney sahnesinin üstüne kayan bir panel açılır:

- "MÜHÜRLENDİ" (`screen-title`)
- Kayıt cümlesi
- Üç gerçek istatistik: deneme, süre, kullanılan güç
- GÖZLEMEVİNE DÖN (birincil) ve YENİDEN DENE

## Screens · Deney katmanı (HUD)

Bütün istasyonlar `scripts/mission_hud.gd` kullanır.

```
┌──────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────┐          [i]  [Esc] │
│ │ Kızağı bırak, ivmeyi ekrandan oku.   │                     │
│ │ ▬▬▬ ▬▬▬ ─── ─── ───   Sına            │                     │
│ └──────────────────────────────────────┘                     │
│                                                              │
│              3D DÜZENEK ve cihaz ekranları                   │
│                                                              │
│                  ┌ [simge] toast ≤ 60 ┐                      │
│ [Q] Sar  [W] Yavaşlat  [E] Ayır  [R] Gör        [ BIRAK ]    │
└──────────────────────────────────────────────────────────────┘
```

| Bölge | İçerik | Düzey |
|---|---|---|
| Sol üst | Yönerge (`directive`) ve altında adım çubuğu ile adım adı | ZORUNLU |
| Sağ üst | i, Geç (yalnızca kriz animasyonunda), Esc | ZORUNLU, başka bir şey eklenmez |
| Sol alt | Güç şeridi, kısayol tuşlarıyla. Kullanılamayan güç soluk ve kilitli görünür. | Yeri ZORUNLU, içeriği istasyona göre |
| Sağ alt | Tek birincil eylem | ZORUNLU |
| Alt orta | Toast, güç şeridinin ve eylemin üstünde. Kontrollerin üstüne binmez. | ZORUNLU |
| Sahne | Sayılar düzeneğin cihaz ekranlarında. Kenar paneli kullanılmaz. | VARSAYILAN |

Deney katmanında paragraf, açıklama kartı ve sabit metin paneli bulunmaz (ZORUNLU). Ayrıntı "i" altında, en çok iki cümledir.

## Experiment Design · Genel

Her istasyon aynı beş adımla akar (ZORUNLU):

| # | Adım | İçerik | Bitiş |
|---|---|---|---|
| 1 | **Kriz** | Kayma kendiliğinden oynar (≤ 8 sn, atlanabilir). Kaybedilecek şey görünür: kapsül, kapı, organ, belge. Cihaz bir değer bekler, gerçek değer başka çıkar. | NEDENİNİ BUL |
| 2 | **Sına** | Oyuncu tek değişkeni değiştirir ve sonucu cihazdan okur. Güçler burada kullanılır. | Gerekli ölçümler alındı |
| 3 | **Neden** | Oyuncu kaymanın kaynağını gösterir: parçaya dokunur ya da ölçtüğü değeri girer. Şık listesi kullanılmaz. | Doğru kaynak |
| 4 | **Kurtar** | Yeni bir durum gelir. Oyuncu değeri hesaplar ve girer, düzenek o değerle çalışır. Deneme hakkı sınırlıdır. | `completed.emit()` |
| 5 | **Mühür** | Aynı düzenek doğru yasayla yeniden oynar. Işık ısınır, kayıt satırı düşer. | Mühür ekranı |

**ZORUNLU kurallar:**

- **Tek değişken.** Bir sınamada yalnızca bir şey değişir. Geri kalan değerler cihazda sabit görünür.
- **Yanlış değer, o değerle çalışan bir düzenek demektir.** Ardından en çok 60 karakterlik bir neden cümlesi gelir ("Süre uzun: yükseklik fazla.").
- **Eksik kavram tanınabilir bir kısmi hata üretir.** Kurtarma birden çok koşul istiyorsa her eksik koşul farklı bir hata gösterir.
- **Hesap animasyondan ayrıdır.** Kural `*_sim.gd` ya da `*_model.gd` içindedir ve headless test edilir. Görünüm `*_view.gd` ya da `*_stage.gd`, akış `mission.gd` içindedir.
- **Sayılar kaynaklıdır.** Kazanım ve kaynak `mission.tres` içinde bulunur. Ekrandaki şema yapılan sadeleştirmeyle tutarlıdır.

**VARSAYILAN kurallar:**

- En az iki etkileşim fiili kullanılır: sürükle-bırak, çevir, bağla, bırak, işaretle, gir.
- Kurtarmada üç deneme hakkı vardır ve haklar sahnede nesne olarak görünür (üç kapsül, üç numune).
- Sar gücü aynı koşulu tek tuşla geri getirir.

**SERBEST:** Kriz kurgusu, düzeneğin tasarımı, kamera, ses, güçlerin istasyona özgü görünümü, ek öğretici anlar.

## Experiment Design · Derslere göre

Her ders aynı beş adımı ve aynı ışık kurallarını kullanır, ama kendi mekânı ve ölçü aracı vardır. Aşağıdaki tablo bir başlangıç önerisidir (SERBEST). ZORUNLU olan, her dersin bir mekânı, bir ölçü aracı, elle yapılan bir işi ve sahnede görünen bir hata sonucu olmasıdır.

Çoktan seçmeli, eşleştirme ya da sıralama kartı tek başına görev sayılmaz. Bu biçimler düzeneğin bir kontrolü olabilir: örneğin belge rafa konur, tıklanacak bir şık olmaz.

| Ders | Mekân | Ölçü aracı | Elle yapılan iş | Hata sahnede |
|---|---|---|---|---|
| **Fizik** | Gece laboratuvarı, metal tezgâh | Fotokapı, kronometre, kuvvet ölçer, cetvel, zaman grafiği | Bırak, kadranla ayarla, ağırlık yükle | Kapsül geç kalır, kızak kapıyı kaçırır |
| **Kimya** | Aynı laboratuvar, ıslak tezgâh ve çeker ocak | pH metre, büret ve damla sayacı, terazi, gaz şırıngası | Damlat, karıştır, ısıt, vanayı aç | Numune yanlış tankta tepkime verir |
| **Biyoloji** | Anatomi tezgâhı, perfüzyon düzeneği, mikroskop | Monitör dalga biçimi, akış oku, oksijen göstergesi | Kelepçele, kanül bağla, parça yerleştir | Kan geri kaçar, doku oksijeni düşer |
| **Matematik, Geometri** | Atölye tezgâhı ve çizim masası; grafik düzeneğin parçası | Sürüklenebilir şekil, canlı grafik, cetvel, iletki | Köşe sürükle, kes, katla, teğeti işaretle | Kutu küçük çıkar, köprü oturmaz |
| **Türkçe, Edebiyat** | Arşiv okuma salonu, masa lambası | Büyüteç, kanıt işaretleyici, dizgi kasası | Cümle parçasını yerleştir, kanıtın altını çiz, eseri rafa koy | Anlam tersine döner, raf kaydı tutarsızlaşır |
| **Tarih** | Arşiv, ışık masası (UV) | Tarih damgası, mühür, imza, zaman çizelgesi rayı | Belgeyi ışığa tut, olayı raya yerleştir | Sonraki karar dayanaksız kalır, ray kopar |
| **Coğrafya** | Kabartma harita masası | Güneş lambası, gölge çubuğu, enlem cetveli, iklim grafiği | Lambayı açıla, pini konumla | Rota sapar, mevsim tutmaz |
| **Felsefe, Mantık** | Konsey odası, devre panosu | Öncül kartları, şalter ve lamba (doğruluk tablosu) | İtirazı zayıf öncüle bağla, şalteri kur | Karakter çelişir, kapı açılmaz |
| **Psikoloji, Sosyoloji** | Gözlem odası, ağ panosu | Algı deneyi düzeneği, düğüm ve bağ panosu | Deneyi yürüt, bağı değiştir | Ölçüm iddiayı çürütür, ağ çöker |
| **Din Kültürü** | Kütüphane | Kaynak metin (ayet, hadis, ilmihal) ve künyesi | İlkeyi vakaya uygula, kaynağı göster | Kaynaksız gerekçe kabul edilmez |
| **YDT İngilizce** | Telsiz odası | Frekans kadranı, kesik kayıt, transkript şeridi | Frekansı ayarla, kayıp kelimeyi yerleştir | Ekip yanlış kapıya gider |

Derse özel ZORUNLU kurallar:

- **Biyoloji:** AYT düzeyindedir. Klinik içerik (stent, darlık, tansiyon) yoktur. Anatomi doğrudur: odacık sayısı ve damar yönü.
- **Spin Hattı:** 11. sınıf Kimya, Modern Atom Teorisi kazanımına bağlıdır. Spin dönen bir küre olarak gösterilmez.
- **Sözel dersler:** İnsan figürü yüzsüz silüet ya da arkadan çekim olur. Üretilmiş yüz kullanılmaz. Alıntı ve tarih kaynağıyla verilir.
- **Kayma her derste tek bir varsayımdır:** fizikte bir parametre, tarihte bir tarih, Türkçede bir bağlaç.

`stations/yks/` mikro görevleri bugün ortak bir soru kabuğunda çalışıyor (choice, pair, sequence). Bu kabuk ders mekânlarına taşınır. `yks_mission_definition.gd` içerik ve doğrulama kaynağı olarak kalır. `mode` alanı düzeneğin kontrol biçimini seçer.

## 3D Lab Standard · Gece laboratuvarı

Fizik, kimya ve biyoloji istasyonları aynı binanın odaları gibi görünür. Referans görsel: `stations/free_fall/assets/chamber_bg.png`. Ortak kurulum: `scripts/physics/lab_stage_3d.gd`.

| Öğe | Kural | Düzey |
|---|---|---|
| Oda | Karanlık arka duvar, uzakta gece mavisi pencere, koyulaştırılmış ve bulanık arka plan. Hangar fotoğrafı ve gri sonsuz zemin kullanılmaz. | ZORUNLU |
| Işık | Düzeneğin üstünde tek sıcak spot (~3200 K), soğuk mavi dolgu, hafif hacimsel sis. Düzenek karenin en parlak yeridir. | VARSAYILAN |
| Tezgâh | Mat koyu çelik ya da kompozit, gerçek ölçekte (~0,9 m). Ahşap parke ve halı dokusu kullanılmaz. | VARSAYILAN |
| Malzeme | PBR: pürüzlülük haritalı metal, kırılmalı cam, mat plastik. Düz renk yalnızca ekran ve göstergede. | VARSAYILAN |
| Kamera | Üç çeyrek önden, hafif yukarıdan. Sınırlı yörünge ve yakınlaştırma. Kriz ve mühürde birer kamera hareketi. | SERBEST |
| Cihaz ekranı | `screen_3d.gd`. Ekran başına en çok 4 değer. Rakam ekranda en az 24 px yüksekliğinde. Okunmayan eksen yazısı çizilmez. | ZORUNLU |
| 3D yazı | Yalnızca gerçek cihaz yüzeyinde. Ekranda 16 px'ten küçük kalacaksa 2D katmanda nesneye iliştirilmiş etiket kullanılır. Eğik ya da bulanık Label3D kullanılmaz. | ZORUNLU |
| Varlık | Gerçek ekipman: hava rayı, kızak, fotokapı, vakum tüpü, beher, kanül. Oyuncak, çizgi film ve stilize araç kullanılmaz. Ölçek tutarlıdır. | ZORUNLU |
| Kontrol | Kadran, düğme ve şalter düzeneğin ön panelindedir (`knob_3d`, `button_3d`). Değerleri okunur. | VARSAYILAN |

Varlık kaynakları: hazır CC0 modeller (`assets/models/`, Poly Haven) ve Codex ya da Gemini talepleri ([ASSETS.md](ASSETS.md)). Etkileşimli parça tek bir mesh'e gömülüyse etkileşim üstüne kurulan bir katmanla yapılır, Kalp Odası'ndaki gibi.

## Motion & Sound

| Olay | Süre | Eğri |
|---|---|---|
| Hover, odak | 120 ms | ease-out |
| Panel giriş ve çıkışı | 220 ms | ease-out, 8 px kayma |
| Sekme ve liste değişimi | 160 ms | çapraz geçiş |
| Kameranın kaideye dönüşü | 600 ms | ease-in-out |
| Toast | giriş 160 ms, kalış 4,5 sn, çıkış 600 ms | |
| İletim metni | saniyede 28 karakter | |
| Misafir imzası | 0,4–0,8 sn kesik titreme, 2–3 px kırmızı ve camgöbeği ayrışma | |

- Hareket durumu anlatır, süs olarak kullanılmaz. Döngüsel hareket yalnızca sıradaki görevin nabzında ve Yaşam Protokolü alarmında bulunur.
- Hareketi azalt ayarı açıkken kamera ve geçişler anlık olur, Misafir imzası durağan bir renk ayrışmasına döner.
- Ses (`Sfx`): tık, doğru, yanlış, mühür, kayma, iletim. Ses bilgiyi tek başına taşımaz.

## Agent Guide

Bu belgeyle çalışan her ajan (Claude, Codex, Gemini) ve insan için:

1. Önce işin katmanını belirle: giriş mi, deney mi.
2. Değerleri YAML'daki adıyla kullan. Yeni bir değer gerekiyorsa önce buraya ekle, sonra koda.
3. Floor ve ZORUNLU kurallar sınırdır. SERBEST alanlarda kendi en iyi fikrini uygula.
4. VARSAYILAN ya da Reflex kuralından ayrılırsan gerekçeyi PR açıklamasına bir cümleyle yaz.
5. Teslimden önce 1280×720'de Godot ekran görüntüsü al, kabul listesini işaretle ve görüntüyü PR'a ekle.
6. Ortak dosyalar (`scripts/`, `scenes/`, `project.godot`) entegrasyon dalında değişir (AGENTS.md).

## Acceptance · Kabul listesi

- [ ] 1280×720'de ekran görüntüsüyle incelendi. Kırpılan metin, kaydırma çubuğu ve Godot varsayılan yazı tipi yok.
- [ ] Renk ve yazı yalnızca tasarım değerlerinden geliyor. Ekranda tek amber düğme var.
- [ ] Aralıklı büyük harf etiket, kicker, noktalı meta dizisi, emoji simge ve uzun tire yok.
- [ ] Her durum renk dışında bir işaretle de veriliyor. Odak halkası klavyeyle görünüyor.
- [ ] Yönerge ≤ 90, toast ≤ 60 karakter. Deney ekranında paragraf yok.
- [ ] Beş adımın hepsi var ve kriz atlanabiliyor. Doğru giriş, yanlış giriş (sahnede sonucu), yeniden deneme ve Esc ile dönüş denendi.
- [ ] Sahnede oyuncak, bozuk anatomi, eğik ya da bulanık yazı, üretilmiş yüz ve gömülü metin yok. Uydurma sayı yok.
- [ ] F6 ile tek başına ve F5 ile ilgili rotadan açıldı. Akış testi geçiyor.

## Known Gaps · Bilinen açıklar (2026-11-14)

| Alan | Durum | Yapılacak |
|---|---|---|
| Tema | IBM Plex ve Inter kullanılıyor, etiketler aralıklı büyük harf, "ADIM 2/5 · SINA" gibi noktalı meta dizileri var | Rajdhani ve Barlow'a geçiş. Tema türlerini YAML bileşenleriyle eşle. `stage_kit.gd`, `mission_hud.gd` ve `stations/yks/mission.gd` içindeki kopya renkleri temaya bağla. |
| Gözlemevi | Liste ve gri bloklar, boş görünen paneller, "KONTROL MERKEZİ" kicker'ı | Üç sütunlu kampanya ekranı, kaide seçimi, başlık ekranı |
| HUD | Sağ üstte tek kalmış "i", toast taşması, güç şeridinin yeri istasyona göre değişiyor | HUD v2 ve adım çubuğu |
| Newton, Atış, Çarpışma, Spin | Hangar fotoğrafı, gri zemin, ahşap tezgâh, oyuncak araba, okunmayan 3D yazı | Gece laboratuvarı standardı, hava rayı kızağı |
| Dalga Girişimi | Düz shader ve sağ veri paneli | Tezgâh üstünde dalga leğeni, veri cihaz ekranında |
| Ölçüm, Vektör, Mevsim, Fotoelektrik, Depo | 2D çizimle taklit edilmiş düzenek | Gerçek 3D düzenek |
| YKS mikro görevleri (13) | Soru kabuğu | Ders mekânları |
| Köprü, Prizma, Basınç | Sahne yok | Kilitli kaide |
| Meridian Display yazı tipi | Elle çizilmiş ve aileyle uyumsuz | Arşive kaldır. Wordmark Rajdhani Bold ile yazılır. |
| Metin denetimi | Elle | `tools/` altına `.gd`, `.tres` ve `.tscn` metinlerinde aralıklı büyük harf, noktalı dizi, uzun tire ve emoji arayan bir denetleyici |

**Uygulama sırası:** Tema → HUD v2 → Başlık ekranı ve gözlemevi → Tezgâh standardı → Jüri rotası istasyonları (Düşüş, Newton, Atış, Çarpışma, Spin, Dalga, Kalp) → YKS ders mekânları → Mühür ve final.
