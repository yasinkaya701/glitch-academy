# 3 Cisim 1 Dünya · Varlık kılavuzu

**Hedef:** Oyuncu sahneye baktığında gece çalışan gerçek bir laboratuvar, arşiv ya da konsey odası görür. Nesneler elle tutulacak kadar inandırıcıdır ve oyuncunun dokunduğu her parça ne işe yaradığını belli eder.

Bu hedefe giden her yol serbesttir. İnternetten hazır varlık bulmak, GitHub üzerinden kendi varlığımızı üretmek, ikisini birleştirmek, hazır bir modeli düzenlemek, Blender betiği yazmak, Godot'ta mesh kurmak, görsel üretimi ya da tarama kullanmak: hangisi en iyi sonucu veriyorsa o. Bu belge yöntem dayatmaz; kaynakları, iş akışını ve sonucun nasıl kontrol edileceğini anlatır.

Görsel dil [DESIGN.md](DESIGN.md), sahne ve ışık [GAME_DESIGN.md](GAME_DESIGN.md) bölüm 8 içindedir.

## Kalite soruları

Bir varlık, hangi yoldan gelirse gelsin, sahnenin içinde, hedef kamerayla ve 1280×720'de şu sorularla kontrol edilir:

1. **Gerçek bir nesne gibi mi görünüyor?** Malzeme, oran ve ayrıntı, gece laboratuvarı ışığında inandırıcı mı?
2. **Ölçeği doğru mu?** Tezgâha, ele ve diğer nesnelere göre gerçek boyutunda mı?
3. **Oyuncunun işine yarıyor mu?** Dokunulacak, çevrilecek ya da sürüklenecek parçalar ayrı ve anlaşılır adlı düğümler mi? Oyuncu neye dokunacağını görebiliyor mu?
4. **Sahnenin diline uyuyor mu?** Işık, renk ve malzeme olarak diğer nesnelerle aynı dünyada mı duruyor?
5. **Yazılar okunuyor mu?** Ekranda okunması gereken her yazı Godot'ta canlı metin olarak duruyor mu?
6. **Nereden geldiği belli mi?** Kaynak ve lisans [ASSET_SOURCES.md](ASSET_SOURCES.md) içinde mi?

Altı soruya "evet" diyen varlık kullanılır. "Hayır" çıkan soru varsa varlık düzeltilir, değiştirilir ya da revize istenir. Karar istasyonun sahibinindir.

Tek bir ilke sabittir: **gerçek kişiler ve gerçek eserler, onlardan kalan gerçek izle gösterilir** (büst, el yazması, arşiv fotoğrafı; GAME_DESIGN.md bölüm 7). Gerçek bir insanın yerine yeni bir yüz koymak, oyunun güvenilirliğini bozar.

## 1. Hazır varlık (internetten)

Gerçekte var olan nesneler, dokular, ortam ışığı, sesler, gerçek kişiler ve eserler için çoğu zaman en hızlı ve en gerçekçi yol budur.

| Tür | Başlangıç noktaları |
|---|---|
| 3D model | [Poly Haven](https://polyhaven.com/models), [Grab3D](https://grab3d.com/models/), [Sketchfab](https://sketchfab.com), [NASA 3D Resources](https://nasa3d.arc.nasa.gov), [Smithsonian 3D](https://3d.si.edu) |
| Müze taramaları ve eserler | [Smithsonian Open Access](https://www.si.edu/openaccess), [The Met Open Access](https://www.metmuseum.org/about-the-met/policies-and-documents/open-access), [Scan the World](https://www.myminifactory.com/scantheworld/) |
| Doku ve malzeme | [Poly Haven](https://polyhaven.com/textures), [ambientCG](https://ambientcg.com) |
| HDRI ve ortam ışığı | [Poly Haven](https://polyhaven.com/hdris) |
| Fotoğraf, belge, el yazması | [Wikimedia Commons](https://commons.wikimedia.org), kütüphane ve arşiv dijital koleksiyonları, NASA görüntü arşivi |
| Ses | [Freesound](https://freesound.org) |

Liste bir başlangıçtır; daha iyi bir kaynak bulunursa o kullanılır.

**İş akışı:**

- İndir, Godot'ta aç, kalite sorularıyla kontrol et.
- Kaynağı, lisansı ve yazarı [ASSET_SOURCES.md](ASSET_SOURCES.md) içine yaz. Proje ticari değildir ve lisans bir engel değildir, ama kim neyi nereden aldı her zaman bellidir. Atıf isteyen lisanslarda atıf jeneriğe de eklenir.
- Ortak kullanılacaksa `assets/models/`, `assets/polyhaven/` ya da `assets/world/` altına, tek istasyona özgüyse `stations/<istasyon>/assets/` altına koy. Aynı dosyayı iki yere kopyalamak yerine aynı yoldan örnekle.
- Disk sınırlı olduğu için genelde hafif sürüm (1K–2K doku) yeterlidir.
- Hazır model tek parça ise, etkileşimli parçalar modelin üstüne ayrı `Node3D` olarak kurulabilir (Kalp Odası örneği).

## 2. Kendi üretimimiz (GitHub ile)

Oyuna özgü düzenekler (ayar plakası, çekim dengeleyici, zaman çizelgesi rayı), hazırı olmayan parçalar ya da hazır bir modelin uyarlanması için Codex'e (kota dolarsa Gemini'ye) üretim yaptırılır. Üretici yöntemini kendisi seçer.

**Akış:**

1. **Talep.** İstasyonun sahibi `docs/requests/NNN-kisa-ad.md` dosyasını yazar ve aynı başlıkla bir GitHub issue açar. Issue'ya talep dosyasının bağlantısı ve hattı (`Hat: LGS` ya da `Hat: YKS`) eklenir.
2. **Üretim.** Üretici `asset/<istasyon>/<varlık>` dalında çalışır ve dosyaları `stations/<istasyon>/assets/<varlık>/` altına koyar.
3. **Teslim.** Üretici istasyon dalına bir PR açar. PR açıklamasında dosya yolları, düğüm adları, ölçek, poligon ve doku boyutu ile sahnenin içinden alınmış bir ekran görüntüsü bulunur.
4. **Kabul.** İstasyon sahibi varlığı kalite sorularıyla kendi sahnesinde kontrol eder. Gerekirse talep dosyasına `## Revize N` bölümü ekler.
5. **Bağlama.** Kabul edilen varlık sahneye bağlanır ve ASSET_SOURCES.md'ye yazılır.

**Talep şablonu:**

```markdown
# NNN · Başlık
Durum: açık | Üretici: Codex | Hat: LGS/YKS | İstasyon: <klasör>

## Oyuncu ne görür ve ne yapar
<nesne sahnede ne işe yarar, oyuncu neyi tutar, çevirir, sürükler>

## Gerçek dünya referansı
<referans fotoğraf ya da ürün adı>

## Çıktılar
<dosya yolu, biçim (.glb / .png), boyut>

## Ölçü ve yapı
<gerçek ölçek (metre), pivot, ayrı parçaların düğüm adları, poligon ve doku bütçesi>

## Kamera ve ışık
<hedef kamera açısı; gece laboratuvarı ışığı (GAME_DESIGN.md bölüm 8)>

## Başarı
<sahnede nasıl görünürse iş tamamdır; kalite soruları>

## Varsayılanlar
<belirsiz durumda üreticinin seçebileceği yol>
```

Talep, ne istendiğini ve neyin başarı sayılacağını söyler. Nasıl yapılacağı üreticinin kararıdır.

## Teslim kontrolü

- [ ] Godot'a aktarıldı, sahnenin içinde hedef kamerayla 1280×720'de görüldü.
- [ ] Kalite sorularının altısı da "evet".
- [ ] Kaynak ve lisans ASSET_SOURCES.md'de.

## YKS kampanya simgeleri

`assets/ui/icons/yks/` dil, geometri, arşiv, pusula, akıl yürütme ve YDT için elle çizilmiş SVG simgeleri içerir. Ortak açık çizgiyi ve camgöbeği/amber anlam renklerini kullanırlar; etiketler canlı Godot metnidir.
