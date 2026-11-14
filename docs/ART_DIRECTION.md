> **Geçersiz.** Arayüz kuralları artık [docs/DESIGN.md](DESIGN.md), oyun tasarımı [docs/GAME_DESIGN.md](GAME_DESIGN.md) içinde. Bu dosya yalnızca geçmiş için duruyor.

# Yanlış Dünya · Görsel yön

Tüm görsel üretimin tek kaynağı. Her talep bu dosyaya referans verir, stili tekrar yazmaz.

## Ruh

Gece gözlemevi: koyu lacivert uzay zemini, tek sıcak ışık kaynağı (amber), bilgi vurgusu için soğuk camgöbeği. Dünya bozuk bir cihaz gibi tamir ediliyor. Her deneyde dünya bir şeyi yanlış yapar, oyuncu düzeltir, ışık ve renk "onarılmış" duruma geçer.

## Palet (hex)

| Rol | Renk |
|---|---|
| Zemin | `#070B12`, panel `#0F1824` |
| Ana metin | `#E8F1F2` |
| Vurgu (onarım, doğru) | `#6FE3C1` |
| Sıcak ışık (uyarı, odak) | `#F2A65A` |
| Hata, arıza | `#E5645A` |
| Büyüklük A / B / bileşke | `#7FB6F5` / `#6FE3C1` / `#F2A65A` |
| Oksijenli / oksijensiz kan | `#D8352F` / `#6D2C3D` |

Durum asla yalnızca renkle verilmez, yanına simge veya yazı gelir.

## Arayüz ve deney ayrımı

- **Arayüz sabit:** düğme, panel, yazı tipi, kaydırıcı, giriş kutusu hepsi `scripts/ui_theme.gd` temasından gelir. İstasyonlar kendi düğme veya panel stilini çizmez.
- **Deney dünyası serbest:** her deney kendi gerçek ortamına sahip olur (atölye, vakum odası, limanda iskele, anatomi laboratuvarı). Ortam ve düzenek gerçek bir deney gibi hissettirir: fiziksel nesneler, ışık, malzeme, oyuncunun ellerle yaptığı iş. Düz diyagram ve etiket yığını "slop" sayılır.
- Matematik 3Blue1Brown çizgisinde ayrı stil kullanabilir, ama grafik yine bir deney düzeneğinin (3B nesne) parçası olarak gelir.

## Sahne dili

- **Biyoloji, fizik:** gerçekçi. Fiziksel malzeme (PBR), tek ana ışık + soğuk dolgu, hafif derinlik bulanıklığı. Bilimsel olarak doğru anatomi ve cihaz oranları.
- **Matematik:** 3Blue1Brown çizgisi. Koyu zemin, ince net çizgiler, parlak renk vurgusu. Şekil, sayı ve formül aynı renkle bağlanır.
- **Arayüz:** cam panel görünümü, ince 1 px kenar çizgisi, köşe kesikleri, sade tipografi. Etiket yığını yok.

## Yasaklar (slop kontrolü)

- Yüzü, eli, yazısı bozuk üretim. Görselde okunur metin üretilmez, metin Godot'ta yazılır.
- Anatomi veya cihaz hatası: yanlış odacık sayısı, ters damar, anlamsız düğme.
- Stil dışı parça: çizgi film, 90'lar neon, aşırı parlama, rastgele hologram.
- Amacı olmayan süs. Her öğe oyunda bir iş yapar.

## Teknik

- Çıktı: PNG (RGBA, şeffaf), 3D için `.glb`. Doku: 2048 px, PBR (albedo, normal, roughness).
- Katmanlı varlıklar ayrı PNG olarak, aynı tuval boyutunda ve aynı hizada.
- Dosya adı: `stations/<istasyon>/assets/<varlik>/<katman>.png`; ortak varlık: `assets/ui/` veya `assets/world/`.
