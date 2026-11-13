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
| Oksijenli / oksijensiz kan | `#D8352F` / `#4A5FA8` |

Durum asla yalnızca renkle verilmez, yanına simge veya yazı gelir.

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
