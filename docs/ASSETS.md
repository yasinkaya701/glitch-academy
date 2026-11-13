# Yanlış Dünya · Varlık kılavuzu

Bir deney, gerçek görünen varlıkla kurulur. Varlığa iki yoldan ulaşılır ve ikisi de eşit derecede geçerlidir:

1. **Hazır varlık:** İnternette bulunan model, doku, fotoğraf, tarama ve ses.
2. **Kendi üretimimiz:** GitHub issue ile Codex'e (kota dolarsa Gemini'ye) üretilen varlık.

Hangi yoldan gelirse gelsin, her varlık aynı kabul kapısından geçer ([GAME_DESIGN.md](GAME_DESIGN.md) bölüm 9) ve kaynağı [ASSET_SOURCES.md](ASSET_SOURCES.md) içine yazılır. Görsel kurallar [DESIGN.md](DESIGN.md), sahne kuralları GAME_DESIGN.md bölüm 8 içindedir.

## Hangi yol ne zaman

| Durum | Yol |
|---|---|
| Gerçekte var olan, yaygın bir nesne (beher, mikroskop, terazi, masa lambası, el aleti) | Önce hazır varlık ara |
| Gerçek bir kişi, eser ya da belge (büst, el yazması, arşiv fotoğrafı, NASA görüntüsü) | Hazır varlık; üretim yasak ([GAME_DESIGN.md](GAME_DESIGN.md) bölüm 7) |
| Doku, zemin, HDRI, ortam sesi | Hazır varlık |
| Oyuna özgü bir düzenek (ayar plakası, çekim dengeleyici, kapsül, zaman çizelgesi rayı) | Kendi üretimimiz |
| Hazır model var ama parçaları ayrılmamış, ölçeği ya da malzemesi yanlış | Hazır modeli al, düzeltmeyi talep et ya da etkileşim katmanı kur |
| Etkileşimli parçası olan anatomik model | Hazır model ve üstüne etkileşim katmanı (Kalp Odası örneği) |

Arama 20 dakikada iyi bir sonuç vermediyse talep açılır. İkisi aynı anda da yürüyebilir: hazır bir model geçici olarak bağlanırken üretim talebi açılabilir.

## 1. Hazır varlık (internetten)

### Kaynaklar

| Tür | Kaynak | Not |
|---|---|---|
| 3D model | [Poly Haven](https://polyhaven.com/models), [Grab3D](https://grab3d.com/models/), [Sketchfab](https://sketchfab.com) (indirilebilir, lisans filtresiyle), [NASA 3D Resources](https://nasa3d.arc.nasa.gov), [Smithsonian 3D](https://3d.si.edu) | Sketchfab'da lisans modelden modele değişir; sayfadaki lisans yazılır |
| Müze taramaları ve eserler | [Smithsonian Open Access](https://www.si.edu/openaccess), [The Met Open Access](https://www.metmuseum.org/about-the-met/policies-and-documents/open-access), [Scan the World](https://www.myminifactory.com/scantheworld/) | Büstler ve antik eserler için |
| Doku ve malzeme | [Poly Haven](https://polyhaven.com/textures), [ambientCG](https://ambientcg.com) | PBR set (renk, normal, pürüzlülük) olarak indirilir |
| HDRI ve ortam ışığı | [Poly Haven](https://polyhaven.com/hdris) | Gece laboratuvarına uygun, karanlık iç mekânlar |
| Fotoğraf, belge, el yazması | [Wikimedia Commons](https://commons.wikimedia.org), kütüphane ve arşiv dijital koleksiyonları, NASA görüntü arşivi | Künyesi (arşiv, eser, tarih) birlikte yazılır |
| Ses | [Freesound](https://freesound.org) (CC0 filtresi), Poly Haven dışı kayıtlar | Her olaya tek ses |

### Kurallar

- **Kaynak kaydı ZORUNLU.** Her dosya için [ASSET_SOURCES.md](ASSET_SOURCES.md) içine yol, kaynak bağlantısı, lisans ve yazar yazılır. Proje ticari değildir ve lisans bir engel değildir, ama kim neyi nereden aldı her zaman bellidir. Atıf isteyen lisanslarda (CC BY) atıf jeneriğe de eklenir.
- **İndirilen dosya kabul kapısından geçer.** Bulunmuş olması kullanılacağı anlamına gelmez. Oyuncak görünüm, çizgi film stili, düz renkli plastik yüzey ve gömülü yazı varsa kullanılmaz.
- **Hafif sürüm alınır.** Disk sınırlıdır. 1K–2K doku, mümkünse 50 MB altı model. Büyük kaynak dosyalar repoya konmaz.
- **Yer:** Ortak kullanılacaksa `assets/models/`, `assets/polyhaven/` ya da `assets/world/`. Tek istasyona özgüyse `stations/<istasyon>/assets/`. Aynı model iki klasöre kopyalanmaz.
- **Godot'ta kontrol:** Ölçek (metre), yön, pivot ve malzeme Godot'ta açılıp kontrol edilir. Ölçek tezgâha göre doğrulanır (masa yaklaşık 0,9 m).
- **Tek parça model:** Etkileşimli parçalar modelin içinden ayrılamıyorsa üstüne ayrı `Node3D` olarak kurulur. Konumlar ölçülerek bulunur.

## 2. Kendi üretimimiz (GitHub ile)

Oyuna özgü düzenekler, hazırı olmayan parçalar ve hazır bir modelin düzeltilmesi Codex'e (kota dolarsa Gemini'ye) yaptırılır. Talep her zaman yazılıdır ve bir GitHub issue ile açılır.

### Akış

1. **Talep.** İstasyonun sahibi `docs/requests/NNN-kisa-ad.md` dosyasını aşağıdaki şablonla yazar ve aynı başlıkla bir GitHub issue açar. Issue'ya talep dosyasının bağlantısı ve `Hat: LGS` ya da `Hat: YKS` etiketi konur.
2. **Üretim.** Üretici `asset/<istasyon>/<varlık>` dalını açar ve dosyaları `stations/<istasyon>/assets/<varlık>/` altına koyar. Üretim yöntemi serbesttir: Blender betiği, Godot'ta kurulan mesh, doku üretimi ya da hazır bir modelin düzenlenmesi. Üretimde kullanılan her hazır parçanın kaynağı da yazılır.
3. **Teslim.** Üretici, istasyon dalını hedefleyen bir PR açar. PR açıklamasında dosya yolları, düğüm adları, ölçek, poligon ve doku boyutu ile Godot içinde alınmış bir ekran görüntüsü bulunur. Kaynak ya da önizleme panosu (asset board) yeterli değildir; görüntü sahnenin içinden alınır.
4. **Kabul.** İstasyon sahibi varlığı kendi sahnesinde, hedef kamerayla ve 1280×720'de açar. Kabul kapısından geçmezse talep dosyasına `## Revize N` bölümü eklenir ve durum `revize` olur.
5. **Bağlama.** Kabul edilen varlık istasyon dalında sahneye bağlanır ve ASSET_SOURCES.md'ye yazılır.

### Talep şablonu

```markdown
# NNN · Başlık
Durum: açık | Üretici: Codex | Hat: LGS/YKS | İstasyon: <klasör>

## Oyuncu ne görür ve ne yapar
<1–2 cümle: nesne sahnede ne işe yarar, oyuncu neyi tutar, çevirir, sürükler>

## Gerçek dünya referansı
<referans fotoğraf bağlantısı ya da ürün adı; düzenek gerçekte nasıl görünüyor>

## Çıktılar
<dosya yolu · biçim (.glb / .png) · 3D ya da 2D · boyut>
Deney nesnesi her zaman 3D'dir. 2D yalnızca uzak arka plan, doku ve arayüz simgesi için istenir.

## Ölçü ve yapı
<gerçek ölçek (metre), pivot, ayrı hareket eden parçaların düğüm adları, poligon ve doku bütçesi>

## Kamera ve ışık
<hedef kamera açısı ve kadraj; gece laboratuvarı ışığı (GAME_DESIGN.md bölüm 8)>

## Kabul ölçütü
<sahnede hangi koşulda kabul edilir; kabul kapısı (GAME_DESIGN.md bölüm 9) geçerli>

## Varsayılanlar
<belirsiz bir durumda üreticinin seçeceği yol>
```

### Üretimde ZORUNLU olanlar

- **Referansa sadakat.** Düzenek gerçek bir laboratuvar ekipmanına benzer: oranlar, malzemeler ve bağlantılar gerçekçi olur.
- **Üretilmiş görsel sınırlıdır.** Görsel üretimi yalnızca uzak arka plan ve doku için kullanılır. Etkileşimli nesneler, insan figürleri, yüzler ve okunur metin üretilmiş görselden gelmez.
- **Yazı Godot'ta yazılır.** Plaka satırları, ölçek çizgilerinin rakamları ve etiketler dokuya gömülmez; sahnede canlı metin olarak çizilir.
- **Parçalar adlandırılır.** Etkileşimli her parça (kapak, kadran, plaka satırı, mühür) ayrı ve anlaşılır adlı bir düğümdür.
- **Düz 2D çizimle düzenek teslim edilmez.** Pillow ya da `_draw()` ile çizilmiş bir terazi ya da ray, 3D düzeneğin yerine geçmez.

## Teslim kontrolü (iki yol için ortak)

- [ ] Godot'a aktarıldı. Eksik doku, ölçek ya da yön sorunu yok.
- [ ] Hedef kamerayla 1280×720'de sahnenin içinden ekran görüntüsü alındı.
- [ ] Kabul kapısını geçiyor (GAME_DESIGN.md bölüm 9).
- [ ] Kaynak ve lisans ASSET_SOURCES.md'de.
- [ ] Ayrı parçalar ve pivotlar doğru adlandırılmış.

## YKS kampanya simgeleri

`assets/ui/icons/yks/` dil, geometri, arşiv, pusula, akıl yürütme ve YDT için elle çizilmiş SVG simgeleri içerir. Ortak açık çizgiyi ve camgöbeği/amber anlam renklerini kullanırlar; etiketler canlı Godot metnidir.
