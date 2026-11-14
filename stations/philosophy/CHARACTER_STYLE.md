# Felsefe İstasyonu · Karakter Görsel Dili ve Animasyon Sözleşmesi

Bu belge, `stations/philosophy/` altındaki filozofların görsel dilini, kare üretim kurallarını ve yüz/duruş animasyon katmanlarını sabitler. Sonraki tüm ajanlar (Codex, Gemini, Claude) yeni kare veya yeni filozof üretirken bu kurallara birebir uyar. Genel renk paleti için [ART_DIRECTION.md](../../docs/ART_DIRECTION.md) geçerlidir.

---

## 1. Karakter Görsel Dili (Retro Baskı Portreleri)

1. **Tür ve Duruş:**
   - Tam boy (`head-to-toe`), ayakta duran; elle çizilmiş orta yüzyıl seyahat afişi ve litografi hissinde karakter.
   - Karşıdan **3/4 cephe** açısı (`frontal 3/4 view`), gözler doğrudan kameraya (oyuncuya) bakar.
   - Bir el hafifçe açık, konuşmanın ortasında doğal bir anlatım jestinde; diğer el yanda rahat veya döneme uygun tek bir nesne (parşömen rulosu, deri ciltli yazma) tutar.
2. **Tarihsel ve Kültürel Doğruluk (AI Slop Yasakları):**
   - Hiçbir filozofun hayattayken yapılmış fotoğrafı/portresi olmadığından tüm karakterler **tarihsel olarak makul temsili görsellerdir**.
   - **Yunan filozofları (MÖ 5.–3. yy):** Dokuma yün *khiton* ve *himation*, yalınayak veya deri sandalet; Roma/Helenistik büst oranlarına uygun yüz hatları.
   - **İslam dünyası filozofları (9.–12. yy, Bağdat / Halep / Buhara-Hemedan / Kurtuba):** Dönem ve coğrafyaya uygun *imâme* (sarık) veya bilgin başlığı, keten/yün *cübbe*, *kaba* veya *taylasan/burnus*; yüz hatları coğrafyaya uygun (Kindî: Abbâsî Bağdat; Fârâbî: Orta Asya Türkistan / Otrar; İbn Sînâ: Buhara-Horasan; İbn Rüşd: Endülüs-Muvahhidî Kurtuba kadısı).
   - **Kesin Yasaklar:** Kumaş veya kitap üzerinde okunur ya da uydurma yazı/kaligrafi, modern kıyafet dikişi, fantezi/büyücü parlaması, bozuk el/parmak anatomisi, karikatür abartısı.
3. **Işık ve Renk:**
   - Soluk krem kâğıt, oksitlenmiş teal, tuğla kırmızısı ve tütün amberinden oluşan sınırlı baskı paleti.
   - Mat guaj ve mürekkep dokusu; seyrek tram noktaları, sade gölge kütleleri ve hafif kâğıt greni. Fotoğraf gerçekçiliği, parlak 3D, HDR, neon ve aşırı detay yok.
4. **Kadraj ve Yeşil Perde (Chroma Key):**
   - Tuval oranı **2:3 dikey** (`848×1264` veya `1024×1536`).
   - Karakterin başının tepesinden ayak tabanına kadar tamamı görünür; üstte ve altta en az `%4` boşluk kalır, hiçbir uzuv kadrajdan kesilmez.
   - Arka plan **tamamen düz, gölgesiz, граdiyensiz saf yeşil (`#00FF00`)** olmalıdır.

---

## 2. Kare (Frame) Sözlüğü ve Piksel Tutarlılığı

Her filozof `stations/philosophy/source/<id>/` klasöründe **aynı `base_neutral` karesinden referansla düzenlenmiş (img2img / edit)** karelerden oluşur.

> [!IMPORTANT]
> **Piksel Tutarlılığı Kuralı:** `base_neutral` dışındaki tüm yüz karelerinde gövde, kıyafet kıvrımları, omuz hizası, saç/sarık dış konturu, ışık ve tuval boyutu **`base_neutral` ile piksel düzeyinde aynı** kalmalıdır; yalnızca belirtilen yüz bölgesi (veya `pose_*` karelerinde yalnızca kol/el) değişir.

### A. Temel Kare (8 filozof için mevcut)
| Kare adı | Dosya | Açıklama |
|---|---|---|
| `base_neutral` | `source/<id>/base_neutral.jpg` | Nötr, sakin ifade, **ağız kapalı**, gözler açık ve oyuncuya odaklı. |

### B. Ağız / Konuşma Kareleri (Alt Yüz)
| Kare adı | Dosya | Açıklama |
|---|---|---|
| `mouth_mid` | `source/<id>/mouth_mid.jpg` | Ağız yarı açık, rahat konuşma ortası, sakal/çene çok hafif aşağıda. |
| `mouth_open` | `source/<id>/mouth_open.jpg` | Ağız açık ("aa" / "ee" ünlüsü), üst/alt dişler sakal/bıyık arasından hafif görünür. |
| `mouth_round` | `source/<id>/mouth_round.jpg` | Dudaklar yuvarlak ("oo" / "uu" ünlüsü), dar açıklık. |

### C. Duygu ve Bakış Kareleri (Üst Yüz + Tam Yüz)
`tools/build_characters.py` bu karelerden hem tam yüz yamasını (`face_<ad>.png`) hem de ağız çizgisinin üstünü koruyan **üst yüz yamasını (`up_<ad>.png`)** otomatik üretir. Böylece karakter konuşurken aynı anda kızabilir, göz kırpabilir veya şaşırabilir.

| Kare adı | Dosya | Açıklama |
|---|---|---|
| `eyes_closed` | `source/<id>/eyes_closed.jpg` | Doğal göz kırpma: yalnızca göz kapakları kapalı, kaş ve ağız `base_neutral` ile aynı. |
| `angry` | `source/<id>/angry.jpg` | Kaşlar çatık ve inik, gözler hafif kısık ve sert, elmacık kemikleri/yanaklar hafif kızarmış, ağız sıkı kapalı. |
| `confused` | `source/<id>/confused.jpg` | Hafıza kıpırtısı / şaşkınlık ("kafamın içinde bir şey kımıldadı"): kaşlar kalkık ve ortada hafif kırışık, bakış hafif yukarı-sola dalgın, dudaklar çok hafif aralık. |
| `thinking` | `source/<id>/thinking.jpg` | Derin düşünme: bir kaş hafif kalkık, gözler aşağı-sağa odaklı, ağız kapalı. |
| `smile` | `source/<id>/smile.jpg` | Hatırlama / aydınlanma: göz çevresinde sıcak tebessüm, yanaklar ve dudak kenarları hafif yukarıda, bilge ve huzurlu ifade. |

### D. İsteğe Bağlı El/Kol Jest Kareleri (`pose_*`)
Yüz `base_neutral` ile aynı kalır, yalnızca anlatım eli değişir:
- `pose_hand_chin`: Eli çenesine/sakalına götürmüş düşünür duruşu (`stir` ve `glimmer` aşamalarında).
- `pose_point_up`: İşaret parmağıyla hafif yukarı/ileri vurgu (`dawn` aşamasında: "Dur, söyleme, hatırlıyorum!").

---

## 3. Otomatik İşleme Hattı (`tools/build_characters.py`)

Yeni kareler `stations/philosophy/source/<id>/` altına konulduktan sonra tek komut çalıştırılır:

```sh
python3 stations/philosophy/tools/build_characters.py
```

Betik şunları otomatik yapar:
1. Kenar piksellerinden yeşil perdeyi ölçer, yeşil sızıntıyı (spill) bastırır ve alfa kanalını yumuşatır.
2. Nötr gövdeyi `assets/characters/<id>/body.png`, boyundan ayrı hareket eden baş katmanını `head.png` olarak kaydeder.
3. İfade farkı kutusunu ve ağız tepe çizgisini (`mouth_y`) bulur; her ifade için `face_<ad>.png` ve ağız dışı ifadeler için üst yüz `up_<ad>.png` yamalarını üretir.
4. `pose_*` karelerinden yalnızca kol/el fark bölgesini kırpıp yumuşak kenarlı yama olarak kaydeder.
5. Tüm koordinatları `stations/philosophy/data/characters.json` içine yazar.

---

## 4. Canlı Mimik ve Hareket Mimarisi (`PhilosopherActor`)

Kod (`visual/philosopher_actor.gd` + `visual/face_live.gdshader`), ayrık kareleri robotik slayt gösterisi gibi değiştirmek yerine **3 katmanlı organik birleşim** kullanır:

1. **Ayrık Yama Geçişi (`_under`/`_over` + `_up_under`/`_up_over`):**
   - Alt yüzde konuşma (`mouth_mid`, `mouth_open`, `mouth_round`) 55 ms çapraz solma ile akarken, üst yüzde duygu (`up_angry`, `up_confused`, `up_thinking`, `up_smile`) ve göz kırpma (`_blink_layer`) bağımsız çalışır.
2. **Organik Mikro-Deformasyon Shader'ı (`face_live.gdshader`):**
   - `jaw_open`: Ses genliğiyle (`_mouth_smooth`) çene ve sakalı milimetrik esnetir; ayrık kareler arasındaki geçişi 60 FPS sürekli harekete bağlar.
   - `brow_lift` ve `eye_squint`: Ruh haline ve hece vurgusuna göre kaş kuşağını ve göz kapaklarını yumuşakça oynatır.
   - `cheek_blush`: Öfke (`anger`) arttıkça yalnızca sıcak ten piksellerinde doğal kızarma verir.
3. **Sakkadik Baş, Bakış ve Nefes Fiziği:**
   - Sabit sinüs salınımı yerine rastgele aralıklı sakkadik bakış hedefleri (`_gaze_target`), konuşma vurgusunda baş onayı (`_nod_phase`), %22 olasılıklı doğal çift göz kırpma (`_pending_double_blink`) ve hafıza düzeyine göre çökük/soluk (`stage 0`) → dik/sıcak (`stage 4`) duruş geçişi uygulanır.
