---
version: alpha
name: 3 Cisim 1 Dünya
description: Gece gözlemevinde geçen Türkçe bilim oyununun arayüzü. Giriş katmanı zengin bir oyun menüsü, deney katmanı gerçekçi 3D sahnenin üstünde sade bir HUD.
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
  subtitle:
    fontFamily: Barlow
    fontSize: 20px
    fontWeight: 500
    lineHeight: 1.35
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
  compare-readout:
    predictedColor: "{colors.warm}"
    measuredColor: "{colors.accent}"
    mismatchColor: "{colors.danger}"
    typography: "{typography.readout}"
    labelTypography: "{typography.label}"
  calibration-plate:
    backgroundColor: "{colors.surface-sunken}"
    borderColor: "{colors.edge-strong}"
    rowTypography: "{typography.body-strong}"
    sealIntact: "{colors.accent}"
    sealBroken: "{colors.danger}"
    sealOpen: "{colors.warm}"
    rounded: "{rounded.sm}"
  input-number:
    backgroundColor: "{colors.surface-sunken}"
    borderColor: "{colors.edge}"
    focusBorderColor: "{colors.focus}"
    typography: "{typography.readout-sm}"
    rounded: "{rounded.md}"
    height: 44px
  dialogue-line:
    backgroundColor: "rgba(7,11,18,0.88)"
    speakerTypography: "{typography.label}"
    lineTypography: "{typography.subtitle}"
    rounded: "{rounded.chamfer}"
    maxChars: 140
  verdict-record:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.edge}"
    metColor: "{colors.accent}"
    missingColor: "{colors.warm}"
    typography: "{typography.body}"
    rounded: "{rounded.chamfer}"
  key-hint:
    borderColor: "{colors.edge-strong}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.key-hint}"
    rounded: "{rounded.sm}"
---

# 3 Cisim 1 Dünya · DESIGN.md

Bu dosya oyunun **arayüzü** için tek kaynaktır: renk, yazı, yerleşim, bileşenler, ekranlar, geçişler ve erişilebilirlik. Biçimi [Google Stitch DESIGN.md](https://github.com/google-labs-code/design.md) standardını izler: üstteki YAML ölçülebilir değerleri verir, metin gerekçeyi ve kullanım kuralını anlatır. Yapay zekâ izine karşı taban kuralları [Hallmark](https://github.com/nutlope/hallmark) kural setinden Godot'a uyarlanmıştır.

Oyunun nasıl oynandığı (döngü, deney yolu, ders aileleri, LLM değerlendirmesi, 3D sahne, varlıklar) [GAME_DESIGN.md](GAME_DESIGN.md) içindedir. Bu belge `docs/UX.md`, `docs/ART_DIRECTION.md` ve `assets/ui/VISUAL_LANGUAGE.md` dosyalarının yerine geçer.

**Kural düzeyleri.**

- **ZORUNLU**: Pazarlık yoktur. Kural ihlal edilirse teslim geri döner.
- **VARSAYILAN**: Kural uygulanır. Daha iyi bir çözüm varsa ondan ayrılınabilir, ama gerekçesi PR açıklamasına bir cümleyle yazılır.
- **SERBEST**: Yapanın alanı. Belge yalnızca hedefi söyler.

Belge bir şeyi yasaklamıyorsa izin verir.

## Overview

### İki katman

| Katman | Ekranlar | Karakter |
|---|---|---|
| **Giriş katmanı** | Başlık ekranı, gözlemevi (kampanya), kayıt defteri, ayarlar, hikâye iletimleri, mühür ve final ekranları | **Zengin oyun arayüzü.** Bir AAA oyun menüsü gibi yoğun ve katmanlıdır: sekmeler, ilerleme, gerçek istatistik, durum simgeleri, tuş ipuçları, düzenek önizlemesi. Yoğunluğu kelimeden değil veriden gelir. |
| **Deney katmanı** | İstasyonlar | **Sade HUD.** Gerçekçi 3D sahnenin üstünde bir yönerge, güç şeridi, tek eylem düğmesi ve sahneye iliştirilmiş göstergeler. Bilgiyi düzenek verir. |

Bu ayrım ZORUNLU'dur. Giriş katmanının yoğunluğu deneye taşınmaz. Deneyin sadeliği de girişi boş bırakmaya gerekçe olamaz.

### Arayüzün üç sözü (ZORUNLU)

1. **Oyuncu her an nerede olduğunu, ne yapacağını ve sonra nereye gideceğini bilir.** Hiçbir ekran çıkışsız bitmez.
2. **Yazı okunur.** Hiçbir metin kırpılmaz, üst üste binmez, bulanık ya da eğik durmaz.
3. **Göz yorulmaz.** Sakin zemin, sınırlı vurgu, yanıp sönme yok.

### Atmosfer

Gece gözlemevi. Lacivert-siyah bir boşlukta tek bir sıcak ışık (amber) ve ölçümü işaret eden soğuk camgöbeği. Arayüz, onarılan hassas bir cihazın kontrol panelidir: mat yüzey, ince çizgi, kesik köşe. Neon, siberpunk, çizgi film ve "yapay zekâ fütürizmi" bu dünyanın parçası değildir.

## Colors

Palet YAML'dadır. Her rengin bir rolü vardır ve renkler rolleri dışında kullanılmaz. Kodda renk yalnızca `scripts/ui_theme.gd` sabitlerinden okunur. Dosya içine `Color("#…")` yazılmaz (ZORUNLU, Hallmark 48).

- **`bg` ve `surface*`**: Zemin ve paneller. Saf siyah ve saf beyaz kullanılmaz. Panel zeminden yalnızca bir ton açıktır.
- **`accent` (camgöbeği)**: Ölçülen değer, seçili öğe, onarılmış durum. Bir görünümde arayüz alanının en çok %5'ini kaplar (Hallmark 23).
- **`warm` (amber)**: Eylem ve MERİDYEN tahmini: ana eylem düğmesi, sıradaki görev, tahmin edilen değer. **Bir ekranda tek amber düğme bulunur** (ZORUNLU).
- **`danger`**: Arıza, bozuk ayar, tahmin ile ölçülen arasındaki fark. Geniş alanlara dolgu olarak kullanılmaz.
- **`focus`**: Yalnızca klavye ve kumanda odak halkası.
- **Seri renkleri**: Vektörler, iki cisim ve bileşke. Aynı nicelik şekilde, sayıda ve formülde aynı rengi taşır.
- **Kan renkleri**: Yalnızca dolaşım sahnelerinde.

ZORUNLU: Hiçbir durum yalnızca renkle verilmez; yanında simge, yazı, şekil ya da hareket bulunur. Gradyan yalnızca tek tonlu okunurluk örtüsünde (`bg` → saydam) kullanılır. Mor-mavi ve camgöbeği gradyan, metin arkasında parlayan leke ve renkli halo kullanılmaz (Hallmark 2a, 29).

## Typography

İki aile kullanılır:

- **Rajdhani** (Indian Type Foundry, OFL): Başlık, ekran adı, düğme. Köşeli, teknik ve oyun HUD'larında çok kullanılan bir yüz. Yalnızca büyük harfle ve kısa metinlerde.
- **Barlow** (Jeremy Tankard, OFL): Gövde ve altyazı. **Barlow Semi Condensed** etiket ve ölçüm sayıları için.

Seçim beş adayın (Teko, Rajdhani, Tektur, Antonio, Oxanium) Godot'ta 1280×720'de aynı metinle dizilmesiyle yapıldı. Barlow Condensed, Hallmark'ın Piste teması kullandığı için elendi. Dosyalar `assets/fonts/rajdhani/` ve `assets/fonts/barlow/` altında, Türkçe karakterlerin tamamı doğrulandı. Rajdhani'de `²` yoktur, bu yüzden sayı ve birim her zaman Barlow Semi Condensed ile yazılır.

| Ad | Kullanım | Kural |
|---|---|---|
| `hero` | Oyun adı, final başlığı | Büyük harf, ekranda tek |
| `screen-title` | Ekran ve istasyon adı | Büyük harf, tek satır |
| `section` | Panel ve sütun başlığı | Kısa ad, cümle değil |
| `button` | Düğme ve sekme | Büyük harf, en çok 3 kelime, aralık ≤ 0,04em |
| `directive` | Deney yönergesi | Emir kipi, en çok 90 karakter |
| `subtitle` | Konuşma ve iletim satırı | Cümle düzeni, en çok 140 karakter, iki satır |
| `body`, `body-strong` | Künye, toast, açıklama | Cümle düzeni, en az 16 px |
| `label` | Gösterge etiketi, durum, tablo başı | Cümle düzeni, harf aralığı yok |
| `readout`, `readout-sm` | Ölçüm sayıları | `tnum` açık, birim ince boşlukla, ondalık virgül (`9,81 m/s²`) |
| `key-hint` | Tuş ipucu | Tuş kutu içinde, eylem yanında |

ZORUNLU kurallar:

- **Aralıklı büyük harf etiket kullanılmaz** (Hallmark 67). 15 px ve altındaki hiçbir metin büyük harfle ya da 0,03em'den geniş aralıkla yazılmaz.
- **Başlık üstü kicker kullanılmaz** (Hallmark 54). Sekme adı, birim, konuşmacı adı ve canlı durum bu kuralın dışındadır.
- Başlık tek ağırlıkta ve tek renktedir; tek kelime ayrıca vurgulanmaz (Hallmark 38iii).
- Inter, Roboto, Arial, Open Sans, IBM Plex, Space Grotesk, Montserrat, Poppins, Cinzel ve Godot'un varsayılan yazı tipi hiçbir ekranda görünmez. Tema her `Control` ağacına ulaşır ve `ThemeDB.fallback_font` ile çizim yapılmaz.
- Türkçe büyük harf: `i → İ`, `ı → I`. Büyük harfli metin kaynakta büyük harfle yazılır.
- Satır uzunluğu en çok 65 karakter, çok satırlı metnin satır aralığı en az 1,3.

## Layout

Temel tuval 1280×720'dir (`canvas_items` germe).

- **Izgara:** 4 px taban, 8 px ritim. Ekran kenarında `safe` = 24 px, buraya hiçbir arayüz öğesi girmez.
- **Hizalama:** Ortak sol kenar çizgisi. Ortalanmış metin yalnızca toast, altyazı ve tam ekran iletimde kullanılır.
- **Kap:** Kart içinde kart yoktur (Hallmark 4).
- **Yoğunluk:** Giriş katmanında düz yazı ekran başına 40 kelimeyi geçmez. Deney katmanında görünür arayüz kelimesi 30'u, arayüz alanı ekranın %22'sini geçmez (VARSAYILAN).
- **Taşma ve çakışma (ZORUNLU):** 1280×720'de hiçbir metin kırpılmaz, hiçbir panel kaydırma çubuğu göstermez ve **görünür iki metin ya da kontrolün dikdörtgeni kesişmez**. Bunu `tests/ui_overlap_test` her ekranda denetler. Sayı doğrusu, eksen ve grafik etiketleri sığmıyorsa seyreltilir; üst üste yazılmaz.
- 1920×1080'de kenar boşlukları büyür, satır uzunluğu büyümez.

## Elevation & Depth

1. **Dünya**: 3D sahne.
2. **Örtü**: Giriş katmanında sol kenardan `bg` %85 → %0 tek tonlu gradyan, okunurluk için.
3. **Panel**: `surface`, 1 px `edge`, gölgesiz.
4. **Kayan öğe** (toast, iletim, açılır künye, mühür paneli): `panel-floating`, ofsetli ve bulanık gölge.
5. **Odak**: 2 px `focus` halkası, 2 px boşlukla, anında görünür, arka plana karşı en az 3:1 (Hallmark 26a). Odakta öğe büyümez ve parlamaz.

Arayüzde bulanık cam ve sıfır ofsetli renkli parıltı kullanılmaz (Hallmark 29).

## Shapes

- **Kesik köşe (`chamfer`)**: Panel ve düğmelerin sağ üst ve sol alt köşeleri 10 px kesiktir. Oyunun imza biçimidir. 9 dilimli `panel_glass.png` bu biçimi taşır.
- Yuvarlak köşe en çok 4 px'tir. Hap düğme ve büyük yuvarlak kart kullanılmaz (ZORUNLU).
- **Çizgi:** 1 px. Vurgu çizgisi 2 px.
- **Seçim çentiği:** Seçili satırın ya da sekmenin solunda 3×16 px `warm` dikey çentik. Satırın tamamı boyanmaz.

## Components

YAML'daki bileşenler `scripts/ui_theme.gd` içinde tema türü olarak bulunur (`PrimaryButton`, `SecondaryButton`, `QuietButton`, `ModeTab`, `RouteTab`, `Panel`, `FloatingPanel`, `ReadoutLabel`, `KeyHint`…). İstasyon kendi düğme ya da panel stilini çizmez (ZORUNLU).

**Düğmeler.** Her kontrolün sekiz durumu vardır: normal, hover, odak, basılı, pasif, yükleniyor, seçili, hata.

- Hover: kenar açılır (120 ms).
- Basılı: yüz 1 px içe iner.
- Pasif: kenar kesikli, yazı %40.
- Metin bir fiildir: DÜZENEĞİ BAŞLAT, BIRAK, MÜHÜRLE, SIRADAKİ DÜZENEK. TAMAM, DEVAM ve BAŞLA gibi boş metinler kullanılmaz. Metne yapışık ok konmaz (Hallmark 63).

**Sekme.** Etkin sekme `ink` renginde ve altında 2 px `accent` çizgiyle gösterilir. Rota sekmesinin ilerlemesi altında ayrı satırda yazar ("4 / 9 mühür").

**Gösterge.** Etiket üstte, sayı ve birim altta.

**Tahmin ve ölçülen (`compare-readout`).** Deneylerin ana göstergesidir. İki satır yan yana durur: "MERİDYEN tahmini" (`warm`) ve "Ölçülen" (`accent`). Değerler farklıysa aralarında `danger` renkli bir fark çubuğu ve farkın sayısı görünür, eşitse çubuk kaybolur ve onay simgesi çıkar. "Cihaz beklentisi" gibi ne olduğu belli olmayan adlar kullanılmaz.

**Ayar plakası (`calibration-plate`).** MERİDYEN'in bozduğu ayarın arayüzdeki karşılığıdır (mekaniği GAME_DESIGN.md bölüm 2). Plakaya yaklaşıldığında satırlar 2D katmanda, düz Türkçeyle ve en az 18 px okunur. Her satırın solunda ayar adı, sağında değer ve bir mühür simgesi bulunur:

| Durum | Mühür simgesi | Renk | Ek işaret |
|---|---|---|---|
| Sağlam | Kapalı altıgen | `accent` | Yok |
| Bozuk | Kırık altıgen | `danger` | Misafir imzası titremesi ve "bozuk ayar" yazısı |
| Açık | Açık altıgen | `warm` | Satırda anahtar, kadran ya da sayı girişi |
| Onarıldı | Yeni altıgen ve onay | `accent` | Kısa mühür animasyonu |

Kanıt sürüklenirken bırakılabilecek satır kesikli kenarla belirir.

**Sayı girişi.** Birim kutunun içinde, sağda sabit durur. Virgül de nokta da kabul edilir, değer Enter ile gönderilir. Yer tutucu biçimi gösterir ("0,0"), örnek değer göstermez.

**Adım çubuğu.** Altı bölümlü bir çubuktur: Kriz, Sına, Teşhis, Düzelt, Toparla, Mühür. Biten bölümler `accent-dim`, geçerli bölüm `accent` renktedir. Geçerli adımın adı çubuğun yanında `label` olarak yazar. Noktalı meta dizisi kullanılmaz.

**Toast.** Tek cümle, en çok 60 karakter, 4,5 sn görünür. Tonunu soldaki çizilmiş simge ve kenar rengi verir. Emoji ve metin simgesi kullanılmaz.

**İletim (MERİDYEN).** Alt üçte birde tam genişlikte bir şerit. Solda konuşmacı adı, sağda tek satır, harf harf yazılır. Esc ile geçilir.

**Konuşma satırı (`dialogue-line`).** Alt üçte birde durur. Solda konuşanın adı, yanında satır (`subtitle`, en çok iki satır). Altında oyuncunun giriş kutusu bulunur: yer tutucu "Gerekçeni yaz", gönderme tuşu Enter. Mikrofon simgesi yalnızca mikrofon açıkken görünür. LLM yanıtı beklenirken "Kayıt inceleniyor" yazan tek satır ve ince bir ilerleme çizgisi gösterilir; dönen halka kullanılmaz. Konuşma geçmişi Tab ile açılır, ekranda kalıcı panel olmaz.

**Hüküm kaydı (`verdict-record`).** Değerlendirmeden sonra kısa bir kayıt düşer: rubrik ölçütleri satır satır, her birinin yanında simge ve tek kelime (karşılandı / eksik). Puan, yıldız ya da yüzde gösterilmez.

**Tuş ipucu.** `[Enter] Başlat   [Esc] Geri   [← →] Seç`. Giriş katmanında alt şeritte durur, kumanda bağlıysa kumanda simgeleriyle değişir. Tuşlar ayarlardan yeniden atanırsa ipuçları da değişir.

**Durum simgeleri.** `assets/ui/` altındaki çizilmiş simgeler kullanılır, Unicode ya da emoji kullanılmaz (Hallmark 30a).

| Durum | Simge |
|---|---|
| Kilitli | Kapalı asma kilit |
| Hazır | Açıklık ve amber çentik |
| Sıradaki | Hazır simgesi ve yavaş nabız |
| Mühürlendi | Altıgen mühür ve onay |
| Kayma aktif | Kırık çizgi |

**Veri bölgeleri.** Veri gösteren her bölgenin dört hâli vardır: yükleniyor, boş, hata, dolu. Örneğin kayıt defteri boşken "Henüz mühür yok. İlk düzeneği onar." yazar ve tek bir eylem sunar.

## Do's and Don'ts

**Yap**

- Bir değeri hem sayıyla hem şekille göster: çubuk, ok, eğri, dolum.
- Düğme metnini fiille, yönergeyi emir kipinde ve tek cümleyle yaz.
- Giriş katmanını oyuncunun gerçek verisiyle doldur. Veri yoksa boş durum göster.
- Her ekranı teslimden önce 1280×720'de ekran görüntüsü alarak incele.
- Bir ekran bittiğinde oyuncuya sıradaki yeri tek bir birincil düğmeyle göster.

**Yapma**

- Başlık, paragraf ve düğmeden oluşan kartları ızgara hâlinde tekrarlama.
- Meta bilgiyi noktalarla birleştirme ("AYT · Fizik · 5"). Satır, sütun ya da çizgi kullan.
- Uydurma sayı koyma: sahte istatistik, örnek skor.
- Mor-mavi gradyan, neon, emoji, stok hologram, süs amaçlı dönen halka kullanma.
- 3D sahnede eğik, bulanık ya da küçük yazı bırakma. Okunamayan etiket 2D katmana taşınır.
- Gerçek nesneyi `_draw()` ile 2D çizerek taklit etme. Çizim yalnızca gerçek veri grafiği ve şema içindir (Hallmark 47c, 80).
- Aynı bilgiyi iki yerde tekrar etme.
- Sürüm rozeti, "BETA" etiketi ve dekoratif sayaç kullanma (Hallmark 66).

---

Aşağıdaki bölümler oyuna özeldir ve standart bölümleri tamamlar.

## Slop Floor

Hallmark'ın taban (Floor) ve refleks (Reflex) kapıları Godot'a şöyle uyarlanmıştır. Floor ZORUNLU'dur. Reflex VARSAYILAN'dır, PR açıklamasında gerekçe yazılarak kaldırılabilir.

| # | Kural | Düzey | Godot karşılığı |
|---|---|---|---|
| 48 | Renk ve yazı tipi yalnızca tasarım değerinden okunur | Floor | `UITheme` sabitleri. Dosyada `Color("#…")` ve font yolu yok. |
| 10a | Boyut yerine dönüşüm canlandırılır | Floor | Tween ile `scale`, `position`, `modulate`. `size` canlandırılmaz. |
| 26a | Her etkileşimli öğenin anında görünen odak halkası vardır | Floor | Bütün ekranlar klavye ve kumandayla dolaşılabilir. |
| 27 | Her hareketin azaltılmış hareket karşılığı vardır | Floor | Ayarlar: Hareketi azalt. |
| 46a | Uydurma sayı, alıntı, yüz ya da logo kullanılmaz | Floor | İstatistik yalnızca kayıttan. Kişiler GAME_DESIGN.md bölüm 7'ye göre. |
| 54, 67 | Kicker ve aralıklı büyük harf etiket kullanılmaz | Floor | `label` cümle düzeninde, aralıksız. |
| 63 | Noktalı meta dizisi, metne yapışık ok, süs nokta kullanılmaz | Floor | Bilgi satıra ya da sütuna bölünür. |
| 2a, 30a, 4 | Mor-mavi gradyan, emoji simge, kart içinde kart kullanılmaz | Floor | |
| 19 | Yapay zekâ ağzı kullanılmaz | Floor | Dil bölümü |
| 23 | Accent alanı en çok %5 | Reflex | |
| 29 | Arayüzde parıltı ve halo kullanılmaz | Reflex | 3D sahne ışığı bu kuralın dışındadır. |
| 37 | En çok iki aile | Reflex | Rajdhani ve Barlow |
| 47c, 80 | Gerçek nesne çizimle taklit edilmez | Reflex | |
| 66 | Süs yazısı kullanılmaz | Reflex | |
| 69 | Bir bilgi tek yerde söylenir | Reflex | |

## Language · Dil (ZORUNLU)

Oyundaki her metin Türkçe, kısa ve somuttur.

- **Her ad, oyuncunun bildiği bir şeyi anlatır.** İç terim ve teknik jargon ekrana çıkmaz. "Cihaz beklentisi" yerine "MERİDYEN tahmini", "verdict" yerine "hüküm", "trigger" yerine hiçbir şey. Yeni bir terim ilk göründüğü yerde kendini açıklar ya da hiç kullanılmaz.
- Uzun tire (—) ve aralık tiresi (–) metin içinde kullanılmaz; sayı aralıkları bunun dışındadır.
- Şu kalıplar kullanılmaz: "Harika!", "Hadi başlayalım!", "Tebrikler!", "Bu deneyde … keşfedeceksin", "Yolculuğun başlıyor", "Bilimin büyüleyici dünyası", üç sıfatlı diziler, tekrarlanan "Değil X, Y" kalıbı.
- Doğru cevaba övgü yazılmaz. Sonucu sahne gösterir, metin nedeni söyler: "Mühürlendi. Çekimin kendisi kaymıştı."
- Sayılar Türkçe yazılır: ondalık virgül, binlik nokta.

## Screens · Giriş katmanı

Giriş katmanı `scenes/` ve `scripts/control_center.gd` altındadır. Burada uygulama ekranı kuralları geçerlidir: yoğunluk tasarımın kendisidir, bilinen kalıplar (sekme, liste, künye) icat edilen kalıplardan iyidir, hareket yalnızca durumu anlatır.

### Başlık ekranı

3D gözlemevi açılır, kamera gezegene doğru yavaşça kayar. Solda `hero` "YANLIŞ DÜNYA", altında tek bir cümle. Altında dikey menü:

- DEVAM ET (kayıt varsa birincil)
- YENİ KAMPANYA
- ROTALAR
- AYARLAR
- ÇIKIŞ

Sağ altta tuş ipuçları durur.

### Açılış

En çok 15 sn sürer, Esc ile atlanır (içeriği GAME_DESIGN.md bölüm 10). Arayüz yalnızca ara yazıları (`subtitle`, ekranın alt üçte birinde, sol hizalı) ve sağ altta "Esc Geç" ipucunu gösterir. Son kare başlık ekranına kesintisiz bağlanır.

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
│ ▌[sıra]  Düşüş Odası   │      seçili kaide aydınlık     │ Kapsül kapak    │
│  [hazır] Newton Kızağı │                                │ kapandıktan     │
│  [hazır] Atış Alanı    │                                │ sonra iniyor.   │
│  [kilit] Köprü         │                                │ Deneme   2      │
│ ───────────────        │                                │ En iyi   1:42   │
│ BÖLÜM II  YAŞAM        │                                │[DÜZENEĞİ BAŞLAT]│
├───────────────────────┴────────────────────────────────┴─────────────────┤
│ MERİDYEN   Ölçüm değişmiş. Bu sonuç başlangıç verilerimde yok.             │
│ [Enter] Başlat   [← →] İstasyon   [Tab] Rota   [L] Kayıt defteri   [Esc]   │
└──────────────────────────────────────────────────────────────────────────┘
```

- **Üst şerit:** Wordmark, mod sekmeleri, rota sekmeleri ve ilerleme, ayarlar.
- **Sol sütun:** Rotanın bölümleri, altında görevler ve durum simgeleri. Seçili satırda amber çentik. Alan ve sınıf seçici bu sütunun başında açılır menüdür.
- **Orta (3D):** Kaideler. Listedeki seçim kamerayı kaideye çevirir, kaideye tıklamak listeyi seçer; ikisi her zaman aynı durumdadır. Kilitli kaide örtülüdür, mühürlü kaide camgöbeği ışıkla yanar.
- **Sağ sütun (künye):** İstasyon adı, ders, kazanım kodu, düzenek önizlemesi, ne bozulduğunu anlatan tek cümle (en çok 70 karakter), oyuncunun gerçek istatistiği ve tek birincil düğme. Kaynak "i" ile açılır.
- **Alt şerit:** MERİDYEN iletimi ve tuş ipuçları.
- **Kilitli istasyonlar** görünür, künyede "Düzenek kuruluyor" yazar ve başlatılamaz.

SERBEST: kamera yolları, kaide modelleri, gezegenin mühür sayısına göre değişimi.

### Kayıt defteri

L tuşuyla gözlemevinin üstüne kayan tam yükseklikte bir panel açılır. Solda rota ve bölüm sekmeleri, sağda mühürlenen yasaların listesi bulunur. Her satır üç sütundur: kayıt cümlesi, istasyon, tarih. Satıra tıklamak o istasyonun kaidesine gider. Boş durum: "Henüz mühür yok. İlk düzeneği onar."

### Ayarlar

Başlık ekranından ve gözlemevinden açılır. Sol sütunda bölümler, sağda kontroller yer alır. Her değişiklik anında uygulanır ve kaydedilir.

| Bölüm | Kontroller |
|---|---|
| Ses | Ana ses, efektler, iletim sesi, sessiz |
| Görüntü | Yazı boyutu (%100, %115, %130), hareketi azalt, yüksek kontrast |
| Kontroller | Tuş atama (güçler, eylem, geri, kayıt defteri), fare hassasiyeti, kumanda |
| Erişilebilirlik | Altyazı her zaman açık, altyazı boyutu, renk körlüğü modu (simgeler zaten renkten bağımsızdır, bu mod seri renklerini ayrıştırır) |
| Konuşma deneyleri | LLM sağlayıcısı ve anahtar durumu ("bağlı" / "çevrimdışı"), mikrofon izni |

### Mühür ekranı ve istasyon sonu

Deney sahnesinin üstüne kayan bir panel açılır:

- "MÜHÜRLENDİ" (`screen-title`).
- Kayıt cümlesi.
- Üç gerçek istatistik: deneme, süre, kullanılan güç.
- **SIRADAKİ DÜZENEK** (birincil düğme): Rotadaki bir sonraki istasyonun adı düğmenin altında yazar. Basınca geçiş doğrudan o istasyona yapılır.
- GÖZLEMEVİNE DÖN (ikincil) ve YENİDEN DENE (sessiz).

Oyuncu 10 sn boyunca hiçbir şey seçmezse panel olduğu yerde kalır; oyun oyuncuyu kendiliğinden bir yere götürmez. Rotanın son istasyonundaysa birincil düğme GÖZLEMEVİNE DÖN olur ve gözlemevinde bölüm tamamlanma iletimi oynar.

### Final ekranı (Üç Güneş)

Tam ekran 3D gökyüzü ve üç güneş. Sol altta tek bir ölçüm paneli bulunur: "Ayrılma süresi" (`readout`), "Başlangıç farkı Δv" (`readout-sm`) ve iki yörüngenin renk anahtarı (`series-a`, `series-b`). Sağ altta tek eylem düğmesi. Final mührü düştüğünde ekran `hero` "ANLAŞMA" başlığına ve oyuncunun bütün mühürlerinin kısa listesine geçer. Jenerik ve teşekkür bu listenin altında akar.

## Screens · Deney katmanı (HUD)

Bütün istasyonlar `scripts/mission_hud.gd` kullanır.

```
┌──────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────┐          [i]  [Esc] │
│ │ Kapsül neden geç kaldı?              │                     │
│ │ ▬▬ ▬▬ ── ── ── ──   Sına              │  MERİDYEN tahmini   │
│ └──────────────────────────────────────┘  3,00 s             │
│                                            Ölçülen  3,87 s   │
│              3D DÜZENEK ve cihaz ekranları                   │
│                                                              │
│                  ┌ [simge] toast ≤ 60 ┐                      │
│ [Q] Sar  [W] Yavaşlat  [E] Ayır  [R] Gör        [ BIRAK ]    │
└──────────────────────────────────────────────────────────────┘
```

| Bölge | İçerik | Düzey |
|---|---|---|
| Sol üst | Yönerge ve altında adım çubuğu ile adım adı | ZORUNLU |
| Sağ üst | i, Geç (yalnızca kriz animasyonunda), Esc | ZORUNLU, başka bir şey eklenmez |
| Sağ üst altı | Tahmin ve ölçülen göstergesi, yalnızca kıyas gerektiğinde | VARSAYILAN |
| Sol alt | Güç şeridi ve kısayol tuşları. Kapalı güç soluk ve kilitli. | Yeri ZORUNLU |
| Sağ alt | Tek birincil eylem | ZORUNLU |
| Alt orta | Toast, güç şeridinin ve eylemin üstünde. Kontrollerin üstüne binmez. | ZORUNLU |
| Sahne | Sayılar cihaz ekranlarında ya da nesneye iliştirilmiş 2D etiketlerde. Kenar paneli yok. | VARSAYILAN |

Deney katmanında paragraf, açıklama kartı ve sabit metin paneli bulunmaz (ZORUNLU). Ayrıntı "i" altında, en çok iki cümledir.

**Konuşma deneylerinde** (Fikir Meydanı, Tarih Meydanı) alt orta bölge konuşma satırına, sağ üst altı ise hüküm kaydına ayrılır. Güç şeridi ve eylem düğmesi aynı yerde kalır.

**Ayar plakası yakın görünümü:** Kamera plakaya yaklaştığında HUD yalnızca yönergeyi ve Esc'i tutar. Plaka satırları 2D katmanda okunur. Kayıt şeridi sol kenardan açılır ve kanıt satırları buradan sürüklenir.

## Transitions · Geçişler

Her ekran değişimi bir geçişle olur. Kesintisiz, siyah kare ya da yükleme ekranı olmadan. Notlardaki "geçişlere animasyon gelmeli" isteğinin karşılığı budur.

| Geçiş | Hareket | Süre |
|---|---|---|
| Başlık → gözlemevi | Kamera kubbeye iner, menü sola kayarak çıkar, sütunlar 8 px kayarak girer | 700 ms |
| Gözlemevi → istasyon | Kamera seçili kaideye dalar, ekran `bg` rengine kararır, istasyon sahnesi düzenekten geri çekilen bir kamerayla açılır | 600 + 250 + 600 ms |
| Adım → adım | Yönerge metni çapraz geçer, adım çubuğu bir bölüm dolar | 250 ms |
| Kriz → Sına | Sar gücünün geri sarma efekti (kısa ters oynatma), sonra sahne durur | 600 ms |
| Mühür | Plaka mührü kapanır, sahne ışığı bir kademe ısınır, mühür paneli aşağıdan kayar | 900 ms |
| İstasyon → sıradaki istasyon | Kamera tavana çıkar, gözlemevi kubbesinden yeni kaideye iner | 1200 ms |
| İstasyon → gözlemevi | Gözlemevi → istasyon geçişinin tersi | 850 ms |
| Panel aç/kapa (kayıt defteri, ayarlar) | 8 px kayma ve saydamlık | 220 ms |

- Geçiş sırasında girdi alınmaz, ama Esc geçişi hemen bitirir.
- Sahne yüklemesi geçişin karartma kısmında yapılır. Yükleme 250 ms'yi aşarsa karartma ekranında yalnızca ince bir ilerleme çizgisi görünür.
- Hareketi azalt açıkken bütün geçişler 200 ms'lik saydamlık geçişine döner.

## Motion & Sound

| Olay | Süre | Eğri |
|---|---|---|
| Hover, odak | 120 ms | ease-out |
| Panel giriş ve çıkışı | 220 ms | ease-out, 8 px kayma |
| Sekme ve liste değişimi | 160 ms | çapraz geçiş |
| Kameranın kaideye dönüşü | 600 ms | ease-in-out |
| Toast | giriş 160 ms, kalış 4,5 sn, çıkış 600 ms | |
| İletim ve altyazı | saniyede 28 karakter | |
| Misafir imzası | 0,4–0,8 sn kesik titreme, 2–3 px kırmızı ve camgöbeği ayrışma | |

- Hareket durumu anlatır, süs değildir. Döngüsel hareket yalnızca sıradaki görevin nabzında ve Yaşam Protokolü alarmında bulunur.
- **Ses** (`Sfx`): tık, doğru, yanlış, mühür, kayma, iletim, geçiş. Her olayın tek bir sesi vardır ve ses bilgiyi tek başına taşımaz. Ses seviyesi ayarlardan yönetilir. Konuşma ve iletim sırasında ortam sesi kısılır.

## Comfort & Accessibility · Göz rahatlığı ve erişilebilirlik (ZORUNLU)

- **Yanıp sönme yok.** Saniyede 3'ten hızlı parlaklık değişimi kullanılmaz (WCAG 2.3.1). Misafir imzası bu sınırın altında kalır.
- **Göz yorgunluğu.** Yüksek kontrastlı periyodik desen (çizgili dalga, ızgara, şerit) ekranın %40'ından fazlasını kaplamaz. Dalga gibi alanlar tek tonun parlaklık değişimiyle çizilir; iki doygun rengin keskin şeritleri kullanılmaz. Hareket eden desenler yavaştır (≤ 1 Hz görsel periyot), Yavaşlat bunu daha da yavaşlatır.
- **Kontrast.** Gövde metni zemine karşı en az 4,5:1, büyük metin ve simge en az 3:1.
- **Yazı boyutu.** Ayarlarda %100, %115 ve %130. Yerleşim %130'da da kırpılmadan ve çakışmadan çalışır; bu, kabul testinin parçasıdır.
- **Altyazı.** Her iletim, konuşma ve sesli olay altyazılıdır. Altyazı alt üçte birde, `subtitle` tipinde, yarı saydam zemin üstünde durur.
- **Girdi.** Her eylem klavyeyle yapılabilir; sürükle-bırak işlemlerinin klavye karşılığı vardır (seç, taşı, bırak). Tuşlar yeniden atanabilir. Kumanda desteklenir.
- **Renk.** Hiçbir durum yalnızca renkle verilmez. Renk körlüğü modu seri renklerini birbirinden ayrıştırır.

## Agent Guide

Bu belgeyle çalışan her ajan (Claude, Codex, Gemini) ve insan için:

1. Önce işin katmanını belirle: giriş mi, deney mi. Oyun mantığı için GAME_DESIGN.md'yi oku.
2. Değerleri YAML'daki adıyla kullan. Yeni bir değer gerekiyorsa önce buraya ekle, sonra koda.
3. Floor ve ZORUNLU kurallar sınırdır. SERBEST alanlarda kendi en iyi fikrini uygula.
4. VARSAYILAN ya da Reflex kuralından ayrılırsan gerekçeyi PR açıklamasına bir cümleyle yaz.
5. Teslimden önce 1280×720'de ve %130 yazı boyutunda ekran görüntüsü al, kabul listesini işaretle, görüntüleri PR'a ekle.
6. Ortak dosyalar (`scripts/`, `scenes/`, `project.godot`) entegrasyon dalında değişir (AGENTS.md).

## Acceptance · Kabul listesi

- [ ] 1280×720'de ve %130 yazı boyutunda incelendi. Kırpılan metin, kaydırma çubuğu, çakışan öğe ve Godot varsayılan yazı tipi yok. `tests/ui_overlap_test` geçiyor.
- [ ] Renk ve yazı yalnızca tasarım değerlerinden geliyor. Ekranda tek amber düğme var.
- [ ] Aralıklı büyük harf etiket, kicker, noktalı meta dizisi, emoji simge, uzun tire ve iç terim yok.
- [ ] Her durum renk dışında bir işaretle de veriliyor. Odak halkası klavyeyle görünüyor.
- [ ] Yönerge ≤ 90, toast ≤ 60, altyazı ≤ 140 karakter. Deney ekranında paragraf yok.
- [ ] Bu ekrana giriş ve çıkış geçişlerle oluyor. Ekran bitince sıradaki yer tek birincil düğmeyle gösteriliyor.
- [ ] Saniyede 3'ten hızlı yanıp sönme ve ekranın %40'ından büyük yüksek kontrastlı desen yok.
- [ ] Oyun mantığı GAME_DESIGN.md kabul ölçütlerini karşılıyor.

## Known Gaps · Bilinen açıklar

Mevcut ekranların ve istasyonların denetimi ve oyun testi notları ayrı tutulur: [docs/review/2026-11-14-deney-denetimi.md](review/2026-11-14-deney-denetimi.md).

**Uygulama sırası:** Tema ve yazı tipleri → HUD v2 (adım çubuğu, tahmin/ölçülen, toast) → Geçişler → Başlık ekranı ve gözlemevi → Mühür ekranı ve SIRADAKİ DÜZENEK akışı → Ayarlar ve erişilebilirlik → Konuşma ekranı → Final ekranı.
