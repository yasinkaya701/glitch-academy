# 006 · Fikir Meydanı (Felsefe) Karakter ve Mekân Görsel Dili
Durum: açık | Üretici: Codex | Sahne: `stations/philosophy/`

## Amaç
Oyuncu Fikir Meydanı'nda 8 filozofla (Sokrates, Platon, Aristoteles, Epiküros, el-Kindî, el-Fârâbî, İbn Sînâ, İbn Rüşd) Bannerlord diyalog ekranı tarzında yüz yüze konuşur; filozofun hafızası aşama aşama (`0..4`) canlanır veya sabrı taşarsa öfkelenip meydanı terk eder. Sekiz filozofun temel nötr tam boy kareleri (`base_neutral.jpg`) ve otomatik katmanlama/keying hattı (`tools/build_characters.py`) hazırdır; bu talep **eksik yüz/jest karelerini** ve **8 tarihsel mekân arka planını** tamamlar.

## Karakter Görsel Dili (Zorunlu Stil Sözleşmesi)
Detaylı teknik sözleşme: [stations/philosophy/CHARACTER_STYLE.md](../../stations/philosophy/CHARACTER_STYLE.md) ve genel palet: [docs/ART_DIRECTION.md](../ART_DIRECTION.md).
- **Tür ve Kadraj:** Tam boy (`head-to-toe`), ayakta, karşıdan 3/4 cephe (`frontal 3/4 view`), gözler kameraya odaklı, 2:3 dikey (`848×1264`), karakterin tepesinden ayak tabanına kadar tamamı kadraj içinde. Görsel dil elle boyanmış orta yüzyıl seyahat afişi ve litografidir.
- **Renk ve Malzeme:** Mat guaj, belirgin ama sade mürekkep konturları, seyrek tram noktaları ve hafif kâğıt greni. Soluk krem, oksitlenmiş teal, tuğla kırmızısı ve tütün amberi sınırlı paleti kullanılır.
- **Arka Plan (Karakter Kareleri):** Tamamen düz, gölgesiz, граdiyensiz saf yeşil (`#00FF00`) chroma-key perde.
- **Piksel Tutarlılığı (Image-to-Image / Edit Kuralı):** Her filozof için `stations/philosophy/source/<id>/base_neutral.jpg` dosyası **referans girdi** olarak kullanılır. Üretilen ifade karelerinde gövde, kıyafet kıvrımları, omuzlar, saç/sarık dış konturu, ışık ve boyut **`base_neutral.jpg` ile piksel düzeyinde aynı** kalmalı, yalnızca istenen yüz ifadesi (veya `pose_*` karelerinde yalnızca anlatım eli) değişmelidir.
- **Slop Yasakları:** Görsel içinde okunur veya uydurma yazı/kaligrafi, bozuk el/parmak anatomisi, neon/hologram parlama, parlak 3D, HDR, aşırı detay ve karikatür abartısı kesinlikle yasaktır.

## Çıktılar

### 1. Karakter İfade ve Duruş Kareleri (`848×1264` · JPG veya PNG · `#00FF00` düz yeşil perde)
Her filozof (`<id>` ∈ `{socrates, plato, aristotle, epicurus, kindi, farabi, ibn_sina, ibn_rushd}`) için `stations/philosophy/source/<id>/` klasöründe mevcut `base_neutral.jpg` referans alınarak aşağıdaki eksik dosyalar üretilir:

| Kare adı | Dosya yolu | Eksik olan karakterler (`<id>`) |
|---|---|---|
| `mouth_mid` | `stations/philosophy/source/<id>/mouth_mid.jpg` | `plato`, `aristotle`, `epicurus`, `kindi`, `farabi`, `ibn_sina`, `ibn_rushd` *(socrates hazır)* |
| `mouth_open` | `stations/philosophy/source/<id>/mouth_open.jpg` | `aristotle`, `epicurus`, `kindi`, `farabi`, `ibn_sina`, `ibn_rushd` *(socrates, plato hazır)* |
| `mouth_round` | `stations/philosophy/source/<id>/mouth_round.jpg` | Tümü (`8 filozof`) |
| `eyes_closed` | `stations/philosophy/source/<id>/eyes_closed.jpg` | `plato`, `aristotle`, `epicurus`, `kindi`, `farabi`, `ibn_sina`, `ibn_rushd` *(socrates hazır)* |
| `angry` | `stations/philosophy/source/<id>/angry.jpg` | `plato`, `aristotle`, `epicurus`, `kindi`, `farabi`, `ibn_sina`, `ibn_rushd` *(socrates hazır)* |
| `confused` | `stations/philosophy/source/<id>/confused.jpg` | Tümü (`8 filozof`) |
| `thinking` | `stations/philosophy/source/<id>/thinking.jpg` | Tümü (`8 filozof`) |
| `smile` | `stations/philosophy/source/<id>/smile.jpg` | Tümü (`8 filozof`) |
| `pose_hand_chin` | `stations/philosophy/source/<id>/pose_hand_chin.jpg` | Tümü (`8 filozof`, isteğe bağlı öncelik 2) |

### 2. Mekân Arka Planları (`1376×768` · PNG · Opak)
Orta yüzyıl seyahat afişi gibi mat guaj ve litografi dokulu, insansız 8 tarihsel sahne. Soluk krem kâğıt, oksitlenmiş teal, tuğla kırmızısı ve tütün amberi paleti; sade mimari kütleler, hafif kâğıt greni ve seyrek tram noktaları kullanılır. Sağ-orta zemin alanı (`x ≈ 0.55..0.75`) ayakta duran karakter için boş bırakılır:

| Filozof | Dosya yolu | Boyut · Biçim |
|---|---|---|
| Sokrates | `stations/philosophy/assets/backgrounds/agora_athens.png` | `1376×768` · PNG · Opak |
| Platon | `stations/philosophy/assets/backgrounds/academy_grove.png` | `1376×768` · PNG · Opak |
| Aristoteles | `stations/philosophy/assets/backgrounds/lyceum_peripatos.png` | `1376×768` · PNG · Opak |
| Epiküros | `stations/philosophy/assets/backgrounds/epicurus_garden.png` | `1376×768` · PNG · Opak |
| el-Kindî | `stations/philosophy/assets/backgrounds/house_of_wisdom_baghdad.png` | `1376×768` · PNG · Opak |
| el-Fârâbî | `stations/philosophy/assets/backgrounds/farabi_court_garden.png` | `1376×768` · PNG · Opak |
| İbn Sînâ | `stations/philosophy/assets/backgrounds/avicenna_study.png` | `1376×768` · PNG · Opak |
| İbn Rüşd | `stations/philosophy/assets/backgrounds/cordoba_courtyard.png` | `1376×768` · PNG · Opak |

## Görsel Tarif

### Karakter İfade Kareleri (`source/<id>/base_neutral.jpg` üzerinden yalnızca yüz düzenlemesi)
- **`mouth_mid`**: Ağız yarı açık, rahat konuşma ortası, dudaklar hafif ayrık, sakal/çene çok hafif aşağıda, gözler `base_neutral` ile aynı.
- **`mouth_open`**: Ağız açık ("aa" ünlüsü), sakal/bıyık arasından dişler hafif görünür, çene doğal açık, gözler `base_neutral` ile aynı.
- **`mouth_round`**: Dudaklar yuvarlak ("oo" / "uu" ünlüsü), dar açıklık, gözler `base_neutral` ile aynı.
- **`eyes_closed`**: Doğal göz kırpma; yalnızca üst göz kapakları kapalı, kaşlar ve kapalı ağız `base_neutral` ile birebir aynı.
- **`angry`**: Kaşlar çatık ve aşağı inik, gözler hafif kısık ve sert bakışlı, elmacık kemikleri/yanaklar hafif kızarmış, ağız sıkıca kapalı.
- **`confused`**: Hafıza kıpırtısı ("Aa… kafamın içinde bir şey kımıldadı"): kaşlar kalkık ve ortada hafif kırışık, gözler hafif yukarı-sola dalgın/şaşkın, dudaklar çok hafif aralık.
- **`thinking`**: Bir kaş hafif kalkık, gözler aşağı-sağa düşünceli odaklı, ağız kapalı.
- **`smile`**: Hatırlama/aydınlanma: göz çevresinde ve dudak kenarlarında sıcak, bilge ve huzurlu tebessüm, ağız kapalı.
- **`pose_hand_chin`**: Yüz `base_neutral` ile aynı; yalnızca anlatım eli çeneye/sakala götürülmüş düşünür duruşunda.

### Mekân Arka Planları (`assets/backgrounds/*.png`)
Ortak stil: Gece gözlemevi paleti (`#070B12`..`#0F1824` koyu lacivert gölgeler), soldan tek sıcak amber ışık kaynağı (`#F2A65A`: kandil/meşale/son gün ışığı), sağdan soğuk camgöbeği dolgu, hafif arka plan bulanıklığı (f/2.8 portre arka planı hissi), insan figürü ve yazı/kaligrafi yok.
1. **`agora_athens.png`**: MÖ 5. yy Atina Agorası; mermer stoa sütun dizisi, alacakaranlıkta yanan birkaç meşale, uzakta silik Akropolis silüeti, taş zemin.
2. **`academy_grove.png`**: Platon'un Akademia zeytinliği; yaşlı zeytin ağaçları, alçak taş duvar, sade mermer eksedra bankı, ağaçların arasından süzülen kehribar akşam ışığı.
3. **`lyceum_peripatos.png`**: Aristoteles'in Lykeion'u (Peripatos); Dor sütunlu üstü kapalı yürüyüş revakı, defne ağaçları, taş döşeme üzerinde sıcak kandil ışığı.
4. **`epicurus_garden.png`**: Epiküros'un Bahçesi; taş duvarla çevrili sakin Atina bahçesi, incir ağaçları, sade taş bank, küçük pişmiş toprak kandil, huzurlu akşam.
5. **`house_of_wisdom_baghdad.png`**: 9. yy Abbâsî Bağdat Beytü'l-Hikme; kemerli kütüphane salonu, deri ciltli yazmalar ve parşömen rulolarıyla dolu ahşap raflar, tavandan sarkan pirinç kandil, kemer arkasında avlu havuzu (yazı/hat yok).
6. **`farabi_court_garden.png`**: 10. yy Halep/Şam revaklı avlu bahçesi; ortada ince su kanalı ve küçük taş havuz, turunç ağaçları, sade kesme taş kemerler, tek asma fener.
7. **`avicenna_study.png`**: 11. yy Buhara/Hemedan hekim-filozof çalışma odası; oymalı ahşap rahle/masa üzerinde ciltli kitaplar, pirinç usturlap, cam imbik ve şifalı bitkiler, kemerli pencereden gece göğü, tek yağ kandili, İran halısı.
8. **`cordoba_courtyard.png`**: 12. yy Kurtuba (Endülüs) avlusu; kırmızı-beyaz at nalı kemerler, portakal ağaçları, taş zeminde su yansıması, asma pirinç kandil.

## Kabul Ölçütü
1. Tüm yeni karakter kareleri `stations/philosophy/source/<id>/` altına konulduktan sonra şu komut hatasız çalışmalı:
   ```sh
   python3 stations/philosophy/tools/build_characters.py
   ```
2. Komut çıktısında her karakterin `face_<ifade>.png` ve `up_<ifade>.png` yamaları `stations/philosophy/assets/characters/<id>/` altında oluşmalı; `body.png` üzerinde yama sınırlarında dikiş izi veya omuz kayması olmamalı.
3. `godot --path . res://stations/philosophy/visual/preview.tscn` ile `1–8` tuşlarıyla tüm filozoflar gezildiğinde arka planlar yüklenmeli, `Boşluk` (konuşma), `M` (hafıza aşamaları) ve `A` (öfke) tuşlarında mimikler doğal çalışmalı.

## Varsayılanlar
- Kota kısıtlıysa üretim sırası:
  1. Önce 8 filozofun `mouth_open`, `mouth_mid`, `eyes_closed`, `angry`, `confused`, `smile` kareleri (Sokrates ve Platon'da mevcut olanlar atlanır).
  2. Ardından 8 mekân arka planı (`assets/backgrounds/*.png`).
  3. Son olarak `thinking`, `mouth_round` ve `pose_hand_chin` kareleri.
