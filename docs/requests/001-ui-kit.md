# 001 · Arayüz kiti ve kontrol merkezi
Durum: açık | Üretici: Codex | Sahne: `scenes/control_center.tscn`

## Amaç
Kontrol merkezi şu an düz koyu paneller ve sıradan bir liste. Dünya manzarası güzel ama arayüz ona ait görünmüyor. Oyuncu bir gözlemevinin konsolunu kullanıyormuş gibi hissetmeli.

## Çıktılar
Hepsi `assets/ui/` altında, şeffaf PNG, 9-slice için kenarlar net.

| Dosya | Boyut | İçerik |
|---|---|---|
| `panel_glass.png` | 512×512 | Cam konsol paneli. Koyu yarı saydam iç (`#0F1824`, %80), 1 px camgöbeği kenar, sol üst ve sağ alt köşe kesik, içeride çok hafif iç ışıma. 9-slice kenar payı 24 px. |
| `btn_normal.png` `btn_hover.png` `btn_pressed.png` `btn_disabled.png` | 256×64 | Aynı düğme, 4 durum. Hover: kenar camgöbeği parlar. Pressed: iç gölge, hafif koyu. Disabled: soluk, kenar kesikli. |
| `tab_active.png` `tab_idle.png` | 192×48 | Rota sekmesi (LGS, TYT, AYT). Aktif: alt kenarda 3 px amber çizgi. |
| `list_row_idle.png` `list_row_selected.png` | 512×56 | Görev satırı. Seçili: sol kenarda dikey amber şerit + hafif ışıma. |
| `badge_done.png` `badge_locked.png` `badge_ready.png` | 48×48 | Durum rozetleri. Done: tik, ready: nokta ışık, locked: kilit. Şekilleri farklı olsun, yalnız renk değil. |
| `icons/` içinde 9 istasyon ikonu | 128×128 | seasons, measurement, vectors, bridge, prism, free_fall, indicator, heart, pressure. Tek renkli çizgi stil, 2 px çizgi, `#E8F1F2`. Bilimsel olarak tanınır: eğik eksenli küre, cetvel, ok bileşkesi, üçgen+kareler, prizma, düşen top, deney tüpü, kalp, basınç göstergesi. |
| `world/station_plinth.png` | 1024×1024 | Dünya halkasındaki istasyon kürsüsü, üstten 3/4 görünüm. Mat metal, üstünde ince amber ışık hattı. Şeffaf zemin. |

### Ek çıktılar (açılış ve görev ekranı)

| Dosya | Boyut | İçerik |
|---|---|---|
| `bg_mission_frame.png` | 1920×1080 | Görev ekranı çerçevesi: ortası şeffaf, kenarlarda gözlemevi konsolu gövdesi (metal ayrıntı, vida, ince ışık hattı). Sol büyük alan sahneye, sağ dar alan bilgi paneline ayrılmış. |
| `panel_info.png` | 512×768 | Sağ bilgi paneli. `panel_glass.png` ile aynı dil, üstte başlık şeridi. 9-slice. |
| `btn_primary_*.png` (4 durum) | 320×72 | Ana eylem düğmesi (Görevi aç, Hesapla). Amber vurgulu, normal düğmeden belirgin şekilde ayrışır. |
| `btn_skip_*.png` (2 durum) | 160×44 | "Açılışı geç" düğmesi. Sade, köşede durur, dikkat dağıtmaz. |
| `intro_title_plate.png` | 1280×360 | Açılışta oyun adının arkasındaki plaka. Arızalı konsol hissi: bir kenarı çatlak, üstünde kırmızı arıza ışığı. Yazı yok. |

## Görsel tarif
Referans his: gece rasathanesi komuta masası. Soğuk metal, cam, tek sıcak ışık. Parlak neon, hologram sis veya cyberpunk yok. Yüzeyde ince çizik ve mat doku olsun, düz gradyan olmasın. Panel ve düğmeler aynı ışık yönünü kullansın (üst sol).

## Kabul ölçütü
- 1280×720 ve 1920×1080 çözünürlükte Godot'ta kenar bozulması yok.
- Tüm durumlar ayırt edilir, rozetler gri tonda bile birbirinden farklı.
- İkonlar 48 px'e küçülünce okunur.
- Görselde metin yok.

## Varsayılanlar
Renkler [ART_DIRECTION.md](../ART_DIRECTION.md) paletinden. Belirsiz durumda koyu ve sade tarafı seç.
