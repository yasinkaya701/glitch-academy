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

Gözlemevinin bütün düzenekleri kalibrasyon asistanı **MERİDYEN**'in ayarlarıyla çalışır. MERİDYEN, üç güneşli kaotik dünyadan gelen Misafirler adına bu ayarları gizlice bozar. Gizli kalmak için bozmayı rastgele yapmaz: öğrencilerin gerçekten takıldığı yanılgıları ayara yazar. "Ağır cisim önce düşer", "momentum yönsüz toplanır", "ışık şiddeti elektron söker", "anı belge kadar güçlü kanıttır" gibi. Bu yüzden bozulma ilk bakışta makul görünür, ama sonucu gerçekten bozar: kapsül geç kalır, kan geri kaçar, konsey yanlış karar verir. Oyuncu **Kalibratör**'dür. Ters çalışan düzeneği ölçer, bozuk ayarı bulur, düzeltir ve ayarın verdiği zararı toparlar. Kampanyanın ortasında bozanın MERİDYEN olduğu ortaya çıkar. Final Üç Güneş'tir: iki cisim öngörülebilir, üç cisim öngörülemez.

### Çekirdek döngü

```
BOZUL  →  TERS ÇALIŞ  →  ÖLÇ  →  TEŞHİS  →  DÜZELT  →  TOPARLA  →  MÜHÜR
MERİDYEN   düzenek          oyuncu     hangi ayar,     ayarı doğru   bozulanı yeni     yasa kayda
ayarı      görünür bir      cihazdan   hangi yanılgı   değere çek    durumda geri      geçer, ışık
bozar      zarar verir      okur                                     getir             ısınır
```

Oyunun her işi bu döngüyü güçlendirir. **Ters çalışma görünür olmalı**, **düzeltme oyuncunun ölçümüne dayanmalı**, **toparlama hissedilmeli**: kapsül kurtarılır, kan yeniden tek yöne akar, ray yeniden bağlanır, arşiv kaydı yerine oturur.

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

Oyuncunun hatırlayacağı tek şey şudur: **ters çalışan düzenek, oyuncunun elinde düzelir.** Aynı düzenek önce bozuk ayarla ters çalışır, oyuncunun ölçtüğü değerle düzelir, sonra doğru ayarla yeniden çalışır ve zarar geri alınır. Bütün tasarım bu iki anı (ters çalışma ve toparlanma) görünür kılmak için vardır.

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

**Adım çubuğu.** Deney adımları altı bölümlü bir çubukta gösterilir. Biten adımlar `accent-dim`, geçerli adım `accent` renktedir. Geçerli adımın adı ("Sına") çubuğun yanında `label` olarak yazar. "ADIM 2 / 5 · SINA" gibi noktalı bir meta dizisi kullanılmaz.

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

**Konuşma satırı.** Alt üçte birde durur. Solda konuşanın adı (byline), sağda satırın kendisi yer alır. Altında oyuncunun giriş kutusu bulunur: yer tutucusu "Gerekçeni yaz", gönderme tuşu Enter. Mikrofon simgesi yalnızca mikrofon açıksa görünür. Konuşma geçmişi Tab ile açılan bir kayıt olarak durur, ekranda kalıcı panel olmaz.

**Hüküm kaydı.** Oyuncunun cümlesi değerlendirildikten sonra kısa bir kayıt düşer: rubrik ölçütleri satır satır, her birinin yanında simge ve tek kelime (karşılandı / eksik). Puan, yıldız ya da yüzde gösterilmez.

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
| 46a+ | Uydurma alıntı, üretilmiş yüz, LLM'in serbest karakter konuşması yok | Floor | Bilgi kartı, satır bankası ve kişi temsili kuralları |
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
│ │ ▬▬ ▬▬ ── ── ── ──   Sına              │                     │
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

## Experiment Path · Her deneyin yolu

Bu bölüm belirli bir deneyi değil, her deneyin nasıl kurulacağını tarif eder. Fizik, kimya, biyoloji, matematik ve sözel derslerin hepsi aynı yoldan geçer. Düzeneğin kendisi SERBEST'tir. Yol ve kurallar ZORUNLU'dur.

### Adımlar (oyuncunun gördüğü)

| # | Adım | Ne olur | Bitiş koşulu |
|---|---|---|---|
| 1 | **Kriz** | Düzenek bozuk ayarla kendiliğinden çalışır ve **ters sonuç verir** (≤ 8 sn, atlanabilir). Kaybedilecek şey görünür: kapsül, kapı, organ, kayıt. Cihazın öngörüsü ile gerçek sonuç yan yana görünür. | NEDENİNİ BUL |
| 2 | **Sına** | Oyuncu tek değişkeni değiştirir, sonucu cihazdan okur. Öngörü ile gerçek her denemede yan yana kaydedilir. Sonucu oyun söylemez, kayıt gösterir. | Gerekli ölçümler kayıtta |
| 3 | **Teşhis** | Oyuncu bozuk ayarı düzeneğin ayar panelinde bulur ve kanıtı gösterir: kayıttan bir satırı ya da bir ölçümü ayara bağlar. | Doğru ayar ve doğru kanıt |
| 4 | **Düzelt** | Oyuncu ayarın doğru değerini, kendi ölçümünden hesaplayarak girer ya da kurar. Düzenek yeni ayarla bir kez çalışır, öngörü ile gerçek çakışır. | Öngörü = gerçek |
| 5 | **Toparla** | Bozulmanın verdiği zarar yeni bir durumda geri alınır: kurtarma, yeniden bağlama, yeniden yönlendirme. Bu bağımsız uygulamadır, sayılar değişir ve ipucu verilmez. Haklar sınırlıdır. | Zarar geri alındı, `completed.emit()` |
| 6 | **Mühür** | Aynı düzenek doğru ayarla baştan oynar, ışık ısınır, kayıt satırı düşer. | Mühür ekranı |

### Bozma kuralı (ZORUNLU)

- **Her bozma, belgelenmiş tek bir öğrenci yanılgısıdır.** Yanılgının kaynağı (MEB materyali, ÖSYM sorusu, alan yazını) istasyonun tasarım kartında yazılıdır. Uydurma bir hata, rastgele bir sayı ya da "cihaz arızası" bozma sayılmaz.
- **Bozma tek bir ayardadır.** Ayar, düzeneğin ayar panelinde fiziksel olarak durur: kalibrasyon plakası, kadran, kart, kayıt fişi. Oyuncu onu görebilir, ama ne yaptığını ölçmeden bilemez.
- **Bozuk ayar sonucu gerçekten bozar.** Ayar iki türlü olabilir:
  - *Dünya ayarı:* Oda gerçekten yanlış yasayla çalışır. Örneğin çekim dengeleyici bozulunca her şey yavaş düşer.
  - *Kontrol ayarı:* Düzenek yanlış modelle karar verir ve hedefi kaçırır. Örneğin itici kuvveti kütleyi yok sayarak hesaplar.
  İki türde de zarar gerçektir: Yanlış Dünya budur.
- **Doğru kural sahnede bulunabilir olmalı.** Oyuncu doğruyu tahminden değil, sahnedeki bir dayanaktan çıkarır. Dayanak şunlardan biri olabilir: MERİDYEN'in dokunmadığı bir kontrol ölçümü, Ayır gücüyle tek değişkene indirilmiş bir deneme, arşivdeki eski doğrulanmış kayıt ya da düzeneğin kendi içindeki bir çelişki.
- **Yanlış davranış asla imzasız gösterilmez.** Bozuk ayarla oynanan her sahne Misafir imzasını taşır ve ekranda "bozuk ayar" olarak işaretlenir. Onarımdan sonra aynı düzenek doğru kuralla yeniden oynar. Oyuncunun aklında kalan son görüntü doğru davranıştır.

### Oynanış kuralları (ZORUNLU)

- **Tek değişken.** Bir sınamada yalnızca bir şey değişir, gerisi cihazda sabit görünür.
- **Sayı cihazdan okunur.** Ölçülecek değer yönerge metninde verilmez. Oyuncu onu düzenekten, kayıttan ya da grafikten okur.
- **Sonucu oyun söylemez.** Toast gözlemi tarif edebilir ("İkisi aynı anda indi: 2,58 s"), kuralı söylemez ("kütle fark yaratmaz"). Kuralı oyuncu teşhiste kendisi kurar.
- **Teşhis şıkla yapılmaz.** Üç düğmeden birini seçmek teşhis değildir. Oyuncu ayarı ve kanıtı gösterir. Yanlış teşhis düzeneği yanlış ayarla bir kez daha çalıştırır ve sonucu görünür.
- **İpucu cevabı içermez.** Hata mesajları, yer tutucular ve "Örnek" metinleri biçimi gösterir, doğru değeri asla göstermez. Örnek sayı, cevaptan farklı olmak zorundadır. Bunu testler denetler.
- **Yanlış değer, o değerle çalışan bir düzenek demektir.** Ardından en çok 60 karakterlik bir neden cümlesi gelir. Neden cümlesi tipik hatayı adlandırır (½ unutuldu, işaret ters, birim karıştı), cevabı söylemez.
- **Canlı hesap gösterilmez.** Oyuncunun hesaplaması gereken sonucu ekran kaydırıcıyla birlikte canlı göstermez. Aksi hâlde hesap, kaydırıcıyı eşitliğe sürmeye dönüşür.
- **Hak sınırlıdır ve bitmesinin bir sonucu vardır.** Toparla adımında üç hak sahnede nesne olarak görünür. Haklar bitince düzenek Sar ile krizin başına döner ve oyuncu Sına'dan yeniden başlar. Sınırsız yenileme yapılmaz.
- **Her koşul bir karar gerektirir.** Doğru cevabı veren her oyuncunun zaten sağladığı bir koşul (örneğin her zaman 9,6 J çıkan bir ısı sınırı) koşul sayılmaz.
- **Hesap animasyondan ayrıdır.** Kural `*_sim.gd` ya da `*_model.gd` içindedir ve headless test edilir. Görünüm `*_view.gd` ya da `*_stage.gd`, akış `mission.gd` içindedir.

VARSAYILAN: Her deney en az iki etkileşim fiili kullanır (sürükle-bırak, çevir, bağla, bırak, işaretle, gir). Sar, Yavaşlat, Ayır ve Gör güçleri Sına adımında kullanılır.

SERBEST: Düzenek, kriz kurgusu, kamera, ses, ayar panelinin biçimi, güçlerin istasyona özgü görünümü.

### Tasarım kartı

Her istasyon koda başlamadan önce kendi klasörüne `DESIGN_CARD.md` yazar ve hangi kafayla (ölçüm, kaynak, argüman) çalıştığını belirtir. Kart kısa tutulur ve inceleme bu karta göre yapılır.

```markdown
# <İstasyon adı>
Rota ve kazanım: <AYT Fizik 5 · kazanım cümlesi> (kaynak bağlantısı)
Kafa: <ölçüm | kaynak | argüman>
Yanılgı: <öğrencinin inandığı yanlış kural> (kaynak bağlantısı)
Bozuk ayar: <panelde ne yazıyor, hangi değerde>
Ters çalışma: <yanılgıya göre öngörü> ↔ <gerçek sonuç>, kaybedilen şey
Ölçüm: <oyuncu hangi cihazdan neyi okuyor>
Teşhis kanıtı: <hangi kayıt satırı hangi ayarı çürütüyor>
Düzelt: <girilen değer ve hesabı>
Toparla: <yeni durum, sayılar, 3 hak, her yanlışın sahnedeki sonucu>
Doğru/yanlış tablosu: <giriş → sahnede ne olur → neden cümlesi>
Varlıklar: <gereken modeller, kaynak ya da talep numarası>
```

### Üretim yolu

1. **Kazanım ve kaynak.** Rota ve kazanım `mission.tres` içine yazılır. Sayılar ve birimler kaynaktan doğrulanır.
2. **Yanılgı ve bozuk ayar.** Tasarım kartı yazılır. Yasin ya da istasyon sahibi kartı onaylar.
3. **Kural ve test.** `*_sim.gd` yazılır. Headless test doğru ve yanlış girişlerin hepsini, bir de ipucunun cevabı içermediğini dener.
4. **Kaba yerleşim (blockout).** Düzenek gri kutularla, hedef kamera ve 1280×720'de kurulur. Okunurluk ve etkileşim burada çözülür.
5. **Varlık.** Önce hazır CC0 kütüphanesi, sonra talep (Assets bölümü). Varlık gelmeden kaba yerleşim teslim edilmez.
6. **Entegrasyon.** Varlık sahneye bağlanır, gece laboratuvarı standardı uygulanır, etkileşim katmanı kurulur.
7. **Akış ve HUD.** Altı adım `mission_hud.gd` ile bağlanır.
8. **Denetim.** Slop Floor, kabul listesi ve 1280×720 ekran görüntüleri. Doğru, yanlış, haklar bitti ve yeniden dene akışları denenir.
9. **PR.** Kart, ekran görüntüleri ve test çıktısı PR açıklamasına eklenir.

## Experiment Design · Ders mekânları

Her dersin kendi mekânı ve ölçü aracı vardır. Tablo bir yön verir, bağlamaz (SERBEST). ZORUNLU olan, her deneyin bir mekânı, bir ölçü aracı, elle yapılan bir işi ve sahnede görünen bir ters çalışması olmasıdır. Çoktan seçmeli, eşleştirme ya da sıralama kartı tek başına görev sayılmaz. Bu biçimler ancak düzeneğin kontrolü olabilir: belge rafa konur, tıklanacak bir şık olmaz.

| Ders | Mekân | Ölçü aracı | Yanılgı örneği |
|---|---|---|---|
| Fizik | Gece laboratuvarı, metal tezgâh | Fotokapı, kronometre, kuvvet ölçer, zaman grafiği | Ağır cisim önce düşer. Hareket için sürekli kuvvet gerekir. |
| Kimya | Islak tezgâh, çeker ocak | pH metre, büret, terazi, gaz şırıngası | Tepkimede kütle kaybolur. Seyreltmek pH'ı değiştirmez. |
| Biyoloji | Anatomi tezgâhı, perfüzyon düzeneği, mikroskop | Monitör dalga biçimi, akış oku, oksijen göstergesi | Atardamar her zaman temiz kan taşır. |
| Matematik, Geometri | Atölye ve çizim masası, grafik düzeneğin parçası | Sürüklenebilir şekil, canlı grafik, cetvel, iletki | Yüzde artış ve azalış birbirini götürür. |
| Türkçe, Edebiyat | Arşiv okuma salonu | Büyüteç, kanıt işaretleyici, dizgi kasası | Bağlaç anlamı değiştirmez. Anlatıcı yazardır. |
| Tarih | Arşiv, ışık masası | Tarih damgası, mühür, zaman çizelgesi rayı | Anı, birincil belge kadar güçlüdür. |
| Coğrafya | Kabartma harita masası | Güneş lambası, gölge çubuğu, enlem cetveli | Mevsimler Güneş'e uzaklıktan olur. |
| Felsefe, Mantık | Konsey odası, devre panosu | Öncül kartları, şalter ve lamba | Sonuç doğruysa çıkarım geçerlidir. |
| Psikoloji, Sosyoloji | Gözlem odası, ağ panosu | Algı düzeneği, düğüm ve bağ panosu | Gördüğüm şey olanın kendisidir. |
| Din Kültürü | Kütüphane | Kaynak metin ve künyesi | Kaynaksız yorum kaynak kadar geçerlidir. |
| YDT İngilizce | Telsiz odası | Frekans kadranı, transkript şeridi | Tek kelimeden bütün anlam çıkar. |

Derse özel ZORUNLU kurallar:

- **Biyoloji:** AYT düzeyi. Klinik içerik yoktur, anatomi doğrudur.
- **Sözel dersler:** İnsan figürü yüzsüz silüet ya da arkadan çekim olur. Üretilmiş yüz kullanılmaz. Alıntı ve tarih kaynağıyla verilir.
- **Kazanım dışı gösteri** (örneğin ardışık Stern–Gerlach) Sınıflar rotasında kalır, sınav rotasına girmez.

## Experiment Design · Üç kafa

Bütün dersler aynı döngüyü kullanır, ama "ölçmek" her ders ailesinde başka bir iştir. Bir deneyi tasarlamadan önce hangi kafayla çalışıldığı seçilir ve tasarım kartına yazılır.

| Kafa | Dersler | Kanıtı ne verir | MERİDYEN neyi bozar | Ne notlanır |
|---|---|---|---|---|
| **Ölçüm** | Fizik, Kimya, Biyoloji, Matematik, Coğrafya, Psikoloji ve Sosyolojinin deneysel konuları | Cihaz, sayı, grafik | Bir yasa ya da modelin parametresi | Değer ve hesap |
| **Kaynak** | Tarih, Türkçe, Edebiyat, Din Kültürü, YDT | Belge, metin, tarih, künye | Bir tarih, bağlaç, atıf ya da kaynağın niteliği | Kanıt ile iddianın ilişkisi |
| **Argüman** | Felsefe, Mantık | Tutarlılık, karşı örnek, düşünce deneyi | Bir çıkarım kuralı, bir kavram tanımı ya da bir görüşün sahibi | Geçerlilik, tutarlılık, doğru atıf |

### Argüman kafası (Felsefe, Mantık)

Felsefede ölçü aleti yoktur. Bu ders ailesinin deneyi **düşünce deneyi**dir ve oyun onu sahnede çalıştırılabilir bir düzenek olarak kurar.

- **Mekân:** Gözlemevinin konsey odası ve bir düşünce deneyi tezgâhı. Tezgâhta vaka maketi kurulur: Theseus'un gemisi tahta tahta değiştirilir, mağaradaki gölge düzeneği ışıkla oynatılır, Descartes'ın kötü cini cihaz ekranlarındaki okumaları değiştirir, bir Gettier vakasında saat durur.
- **Ölçmenin karşılığı:** Oyuncu iddiayı vakaya uygular ve sonucun tutarlı kalıp kalmadığına bakar. Çelişki sahnede görünür. Gemi iki tane olur, konsey aynı kişiye iki zıt hüküm verir.
- **Bozma:** MERİDYEN konseyin akıl yürütme ayarına bir safsata ya da kavram kayması yazar. Örnekler:
  - "Sonuç doğruysa çıkarım geçerlidir."
  - "Bilgi, doğru olan inançtır."
  - "Olan, olması gerekendir."
  - Ad hominem, aceleci genelleme, post hoc.
  - Bir görüşün yanlış filozofa atfedilmesi (Locke'a doğuştan fikirler).
- **Ters çalışma:** Konsey bu ayarla bir karar alır ve kararın sonucu sahnede görünür: kapı yanlış kişiye açılır, kayıt yanlış ilkeye göre sınıflanır.
- **Teşhis:** Oyuncu bozuk çıkarımın hangi adımda çöktüğünü gösterir: öncül ile sonuç arasındaki boşluğu ya da karşı örneği vakaya koyar.
- **Düzelt:** Çıkarım kuralı ya da kavram tanımı düzeltilir, aynı vaka yeniden çalıştırılır ve çelişki kalkar.
- **Toparla:** Yeni bir vakada oyuncu ipucu almadan düzeltilmiş ilkeyi uygular.
- **Mantık:** Önermeler devre panosunda şalter ve lambadır. Doğruluk tablosu devrenin kendisidir. Geçersiz çıkarım kapıyı açmaz.

ZORUNLU kurallar:

- **Görüş notlanmaz.** Oyun Descartes ile Locke, Kant ile Mill arasında taraf tutmaz. Notlanan şeyler: çıkarımın geçerliliği, tutarlılık, kanıt ile sonuç ilişkisi, görüşün doğru filozofa atfedilmesi ve kavramın doğru tanımı.
- **Alıntılar gerçek ve kaynaklıdır.** Eser, bölüm ve çeviri belirtilir. Uydurma ya da başka sözcüklerle yazılıp tırnak içine alınmış filozof sözü kullanılmaz. Bu, bu alandaki en tipik AI slop örneğidir.
- **Filozof ağzıyla uzun konuşma yazılmaz.** Karakter, görüşünü tek cümleyle ve kaynağa dayanarak söyler. Ayrıntı "i" altındaki kaynak notundadır.
- **Düşünürler, onlardan kalan gerçek izle temsil edilir** (bkz. Kişi temsili). Portre üretilmez.
- Metin bu derslerde malzemedir. Bu yüzden deney ekranındaki 30 kelime sınırı burada kaynak metne uygulanmaz. Yönerge ve toast kuralları aynen geçerlidir.

#### Fikir Meydanı (Felsefe, konuşma deneyi)

Oyuncu bir düşünürle konuşur. Yazdığı cümleyi bir LLM değerlendirir ve düşünür buna göre karşılık verir (bkz. LLM Evaluation). Kapsam 11. sınıf felsefe tarihi ve AYT felsefe grubudur: Sokrates, Platon, Aristoteles, Epikuros, Kindî, Fârâbî, İbn Sînâ, İbn Rüşd.

- **Mekân:** Gece arşivinin konsey odası. Her düşünür bir kürsüde, ondan kalan gerçek izle durur:
  - Antik düşünürler için mermer büst (müze fotoğrafı ya da 3D tarama).
  - Yüz görüntüsü kalmamış düşünürler için el yazması ve eser.
  - Konuşan kürsünün ışığı açılır, satır altyazı olarak gelir.
- **Bozma:** MERİDYEN düşünürün hafıza kaydına, öğrencilerin sık karıştırdığı bir yanlış atıf ya da yanlış okuma yazar. Düşünür bu bozuk görüşü kendi görüşüymüş gibi savunur. Örnekler (her biri tasarım kartında kaynakla doğrulanır):
  - Sokrates'e "İnsan her şeyin ölçüsüdür" (Protagoras'ın sözü).
  - Aristoteles'e "İdealar ayrı bir dünyadadır" (Platon'un görüşü).
  - Epikuros'a "Haz sınırsız zevktir" (ataraksiayı silen bir okuma).
  - İbn Rüşd'e "Felsefe dine aykırıdır" (Faslü'l-Makâl'ın tezinin tersi).
- **Ters çalışma:** Konsey bozuk görüşe dayanarak bir karar verir ve kararın zararı odada görünür: arşiv rafı yanlış ilkeye göre dizilir, bir kapı yanlış gerekçeyle kapanır.
- **Sına:** Oyuncu düşünürün kendi eserinden gelen kaynak kartlarını açar ve düşünce deneyini masada çalıştırır. Örnekler: Platon'un mağarasında ışık ve gölge, İbn Sînâ'nın uçan adamında duyuların tek tek kapatılması.
- **Teşhis (LLM):** Oyuncu tek bir cümleyle itiraz eder: bozuk görüşü, gerekçesini ve dayandığı kaynağı söyler. LLM cümleyi rubriğe göre değerlendirir. Düşünür hükme göre karşılık verir: ikna olur, gerekçe ister ya da atfın yanlış olduğunu söyler.
- **Düzelt:** Doğru görüş, düşünürün eserinden künyeli bir alıntıyla geri yüklenir. Bu alıntı bilgi kartından gelir, LLM yazmaz.
- **Toparla:** Konseyin bozuk kararı yeniden görüşülür. Oyuncu düzeltilmiş görüşü yeni bir vakaya uygulayan ikinci bir cümle yazar ve karar düzelir. Hak üçtür. Düşünürün sabrı biterse oda krizin başına döner.
- **Mühür:** Kürsünün ışığı ısınır, kayıt defterine düşünürün künyeli sözü girer.

### Kaynak kafası (Tarih, Türkçe, Edebiyat, Din Kültürü, YDT)

- **Kanıtı belge verir.** Oyuncu belgeyi ışığa tutar, tarihini ve künyesini okur, metindeki kanıtın altını çizer. Seçenek seçmek yerine kanıtı gösterir.
- **Bozma:** Bir tarih kaydırılır, bir bağlaç değiştirilir, bir anı birincil belge olarak etiketlenir, bir alıntı yanlış eserle eşlenir.
- **Ters çalışma:** Bozuk kayda dayanan sonraki karar dayanaksız kalır. Zaman çizelgesi rayı kopar, metnin anlamı tersine döner.
- **Din Kültürü:** İnanca not verilmez. Kavram, kaynak metin (ayet, hadis, ilmihal) ve künyesi üzerinden ilerlenir. Peygamberler ve kutsal kişiler tasvir edilmez. Mezhepler arası tartışmalı konularda oyun taraf tutmaz.
- **Tarih:** Belge metinleri gerçek ve tarihlidir. Kurmaca arıza ile belgelenmiş olay çizgisi sahnede açıkça ayrı gösterilir.

#### Tarih Meydanı (LGS İnkılap Tarihi ve TYT/AYT Tarih, belge deneyi)

- **Mekân:** Arşivin ışık masası ve üstünde bir zaman çizelgesi rayı. Ray üzerinde olay yuvaları vardır: Amasya Genelgesi (22 Haziran 1919), Erzurum Kongresi, Sivas Kongresi, TBMM'nin açılışı (23 Nisan 1920), Lozan (24 Temmuz 1923). Her yuva, bir öncekinin kararına dayanır.
- **Bozma:** MERİDYEN bir kaydı kaydırır. Bu, öğrencilerin sık yaptığı bir hatadır: "Sivas Kongresi'nde manda kabul edildi", iki kongrenin kararlarının yer değiştirmesi ya da sırası bozulmuş bir tarih.
- **Ters çalışma:** Bozuk kayda dayanan sonraki yuva dayanaksız kalır. Ray o noktada kopar ve sonraki olayların ışığı söner.
- **Sına:** Oyuncu belgeyi ışık masasına koyar, tarih damgasını ve künyesini okur, karar cümlesinin altını çizer. Örnek karar cümlesi: "Milletin istiklâlini yine milletin azim ve kararı kurtaracaktır."
- **Teşhis (LLM):** Oyuncu tek cümleyle bozuk kaydı çürütür: hangi belge, hangi karar, neden. LLM cümleyi rubriğe göre değerlendirir: belgeye atıf, doğru olay ve tarih, iddia ile kanıt arasındaki bağ.
- **Düzelt ve toparla:** Doğru belge yuvasına oturur ve ray yeniden bağlanır. Toparla adımında yeni bir bozuk kayıt gelir, oyuncu onu ipucusuz çürütür.
- **Seçenek kartı yoktur.** Üç karttan doğrusunu seçmek görev sayılmaz.

### Ölçüm kafasında psikoloji ve sosyoloji

Psikoloji ve sosyolojinin deneysel konuları ölçüm kafasıyla kurulur. Veri, oyuncunun kendisinden ya da bir simülasyondan gelir:

- Müller-Lyer yanılsamasında oyuncu çizgileri kendisi eşitler ve hatası ölçülür.
- Stroop testinde oyuncunun kendi tepki süresi ölçülür.
- Değişim körlüğünde oyuncunun fark edip etmediği kaydedilir.
- Sosyolojide örneklem seçimi ve ağ simülasyonu kullanılır.

Bozma bir yöntem hatasıdır: tek kişiden genelleme, kontrol grubu olmaması, örneklem yanlılığı. Ters çalışma ise yanlış sonuca ulaşan bir rapordur.

## LLM Evaluation · Cümle değerlendirmesi

Kaynak ve argüman kafasındaki deneylerde oyuncu cevabını kendi cümlesiyle yazar ya da söyler. Cümleyi bir LLM değerlendirir. Temel kural şudur: **LLM yargılar, karakter yazılmış metinle konuşur.** Slop'u önleyen ayrım budur.

### Akış

```
oyuncu cümlesi ──► yerel ön kontrol ──► LLM (rubrik + bilgi kartı) ──► JSON hüküm ──► şema kontrolü
                                                                                         │
       satır bankasından karşılık ◄── reply_id ◄─────────────────────────────────────────┘
       sahnede sonuç (ray bağlanır, kürsü ışığı, karar düzelir)
```

### Kurallar (ZORUNLU)

1. **LLM yalnızca değerlendirir.** Karakterin söylediği her satır yazılmış bir satır bankasından gelir. Banka, her adım ve her hüküm için önceden hazırlanır. LLM yalnızca `reply_id` seçer ve isterse oyuncunun cümlesinden en çok altı kelimelik bir yankı yuvasını doldurur ("Gemiyi iki kez saydın diyorsun…"). LLM serbest karakter konuşması, alıntı, tarih ya da biyografi üretmez.
2. **Bilgi kartı.** Her düşünür ve her olay için kaynaklı bir kart vardır: görüşler, kavramlar, eserler, künyeli gerçek alıntılar, sık karıştırılan görüşler ve sahipleri. LLM'e kart verilir ve LLM yalnızca karta göre değerlendirir. Kartta olmayan bir iddiayı doğru saymaz, "kartta yok" olarak işaretler.
3. **Rubrik.** İstasyonun tasarım kartında 3–5 evet/hayır ölçütü bulunur. Örnek: *bozuk görüşü adlandırdı*, *gerekçe verdi*, *doğru kaynağa dayandı*, *atıf doğru*, *safsata yok*. LLM her ölçütü ayrı işaretler.
4. **Hüküm şeması.** LLM şu biçimde JSON döndürür:

   ```json
   {"verdict": "ikna | eksik_gerekce | yanlis_atif | safsata | ilgisiz",
    "criteria": {"<ölçüt>": true},
    "evidence": "<oyuncu cümlesinden alıntı>",
    "missing": "<eksik ölçütün adı>",
    "reply_id": "<satır bankası kimliği>"}
   ```

   Şemaya uymayan, eksik ya da zaman aşımına uğrayan yanıt yok sayılır ve yerel değerlendirici devreye girer.
5. **Neye puan verilmez.** Uzunluk, anahtar kelime sayısı, filozof adı ya da ezber söz tek başına puan getirmez. Gerekçesiz bir kavram yığını `eksik_gerekce` alır. Görüş notlanmaz: oyuncu düşünüre katılmak zorunda değildir, doğru temsil etmek ve gerekçelendirmek zorundadır.
6. **Geri bildirim cevabı vermez.** Düşünür eksik ölçütü kendi diliyle ister ("Bunu nereden biliyorsun?", "Bu söz bana ait değil."). Doğru görüşü hazır cümle olarak söylemez.
7. **Çevrimdışı oynanabilirlik.** Her konuşma deneyi LLM olmadan da baştan sona bitirilebilir. Çevrimdışı modda oyuncu cümlesini kaynak kartlarındaki parçalardan kurar (cümle kurucu) ve aynı rubriği yerel kurallar değerlendirir. Jüri demosu LLM'siz de çalışır.
8. **Güvenlik.** Konu dışı mesajlar, hakaret ve "bana doğru de" türü yönlendirmeler `ilgisiz` sayılır. Karakter rolünden çıkmaz. Oyuncu metni dışında hiçbir kişisel veri gönderilmez. Mikrofon isteğe bağlıdır ve açıkken bu ekranda görünür.
9. **Teknik.**
   - Sıcaklık 0, zaman aşımı 7 sn.
   - API anahtarı istek başlığında gider; URL'de, repoda ya da logda bulunmaz.
   - Kullanılan sağlayıcı ayarlar ekranında görünür.
   - Bekleme sırasında "Kayıt inceleniyor" yazan tek bir satır ve ince bir ilerleme çizgisi gösterilir. Dönen halka kullanılmaz.
10. **Test.**
    - Her istasyonun en az 30 cümlelik bir altın seti vardır: doğru itiraz, eksik gerekçe, yanlış atıf, anahtar kelime yığını, konu dışı ve yönlendirme denemesi. Her cümlenin beklenen hükmü yazılıdır.
    - Headless test kaydedilmiş yanıtlarla çalışır. Canlı LLM ile ayrı bir değerlendirme betiği koşulur.
    - Hükümlerin altın setle uyumu %90'ın altına düşerse istasyon teslim edilmez.

### Kişi temsili (ZORUNLU)

Düşünürler ve tarihî kişiler, onlardan bize kalan **gerçek izle** temsil edilir:

- Antik büst, el yazması sayfası, arşiv fotoğrafı ya da eserin kendisi.
- Her görselin künyesi (müze ya da arşiv, eser, lisans) [ASSET_SOURCES.md](ASSET_SOURCES.md) içine yazılır.
- Gerçek görüntüsü kalmamış kişi eseriyle ya da el yazmasıyla temsil edilir. Örnek: İbn Sînâ için el-Kânûn fi't-Tıb el yazması.
- Üretilmiş yüz, yeniden çizilmiş portre, yüz canlandırma, dudak senkronu ve ifade kareleri kullanılmaz.
- Atatürk ve diğer tarihî kişilerin arşiv fotoğrafları değiştirilmeden ve saygıyla kullanılır. Rötuşlanmaz, canlandırılmaz, ağızlarına uydurma söz konmaz.
- Seslendirme isteğe bağlıdır. Altyazı tek başına yeterlidir.

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

Varlıklar **Assets** bölümündeki yoldan gelir.

## Assets · Varlık yolu

Gerçekçi bir deney gerçek görünen varlıkla kurulur. Varlık istemek ve kullanmak beklenen bir iştir. Kötü varlıkla teslim etmek ise kabul edilmez.

**Kaynak sırası:**

1. **Hazır CC0 kütüphane:** `assets/models/` (Grab3D), `assets/polyhaven/` (model, doku, HDRI), ambientCG dokuları. Kayıt [ASSET_SOURCES.md](ASSET_SOURCES.md) içinde tutulur.
2. **Yeni CC0 indirme:** Poly Haven, ambientCG, Grab3D ve benzeri kaynaklardan istasyonun ihtiyacına göre. Kaynak ve lisans aynı kayda yazılır.
3. **Talep:** Hazırı yoksa ya da yetmiyorsa `docs/requests/NNN-ad.md` şablonuyla ve bir GitHub issue ile Codex'e açılır. Codex'in kotası dolarsa talep Gemini'ye geçer. Talep bu belgenin ilgili bölümüne bağlantı verir, stili yeniden tarif etmez.
4. **Godot ile kurulan geometri:** Ray, kutu, kablo, tüp gibi basit parçalar mesh olarak kurulur ve PBR malzeme alır.

**Talepte bulunması ZORUNLU olanlar:**

- Oyuncunun ne gördüğü ve neyi hareket ettirdiği.
- Gerçek dünyadan bir referans fotoğrafı ya da ürün adı.
- Ölçek (metre), pivot, ayrı hareket eden parçaların düğüm adları.
- Kamera açısı ve hedef kare, poligon ve doku bütçesi.
- Kabul koşulu.

**Varlık kabul kapısı (ZORUNLU).** Aşağıdakilerden biri bile varsa varlık sahneye girmez, revize istenir:

- Oyuncak, çizgi film ya da stilize görünüm. Yanlış oran ya da ölçek.
- Bozuk anatomi, yanlış odacık ya da damar. Eğri, akan ya da erimiş geometri.
- Okunur metin gömülmüş doku. Üretilmiş yüz.
- Düz renkli, pürüzlülük haritası olmayan "plastik" yüzey (cihaz ekranı hariç).
- Gece laboratuvarı ışığıyla uyumsuz pişmiş (baked) aydınlatma.
- Kaynağı ya da lisansı bilinmeyen dosya.

**Görüntü üretimi.** Üretilmiş 2D görsel yalnızca uzak arka plan ve doku için kullanılır (örneğin `chamber_bg.png`). Ön plandaki etkileşimli nesneler, insan figürleri ve okunur metin üretilmiş görselden gelmez.

**Etkileşim katmanı.** Hazır model tek parçaysa etkileşimli parçalar onun üstüne ayrı `Node3D` olarak kurulur. Konumlar ölçülerek bulunur, Kalp Odası'ndaki gibi.

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
- [ ] Altı adımın hepsi var ve kriz atlanabiliyor. Tasarım kartı klasörde. İpucu ve örnekler cevabı içermiyor. Doğru giriş, yanlış giriş (sahnede sonucu), yeniden deneme ve Esc ile dönüş denendi.
- [ ] Sahnede oyuncak, bozuk anatomi, eğik ya da bulanık yazı, üretilmiş yüz ve gömülü metin yok. Uydurma sayı yok.
- [ ] F6 ile tek başına ve F5 ile ilgili rotadan açıldı. Akış testi geçiyor.

## Known Gaps · Bilinen açıklar

Mevcut ekranların ve istasyonların bu belgeye göre denetimi ayrı tutulur, çünkü değişir: [docs/review/2026-11-14-deney-denetimi.md](review/2026-11-14-deney-denetimi.md).

**Uygulama sırası:** Tema → HUD v2 → Başlık ekranı ve gözlemevi → Tezgâh standardı → Jüri rotası istasyonları (Düşüş, Newton, Atış, Çarpışma, Spin, Dalga, Kalp) → YKS ders mekânları → Mühür ve final.
