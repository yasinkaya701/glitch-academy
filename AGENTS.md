# Yanlış Dünya · Ekip çalışma kuralları

Yasin görevleri ve sahiplerini belirler. Yasin Codex ve Claude ile, ekip arkadaşı Codex ve Gemini ile çalışır. Ajan işlerini de görevi alan kişi kendi çalışma kopyasında koordine eder. Deney sırası ve oynanış kararları Yasin ile netleştirilir.

## Kalite ölçütleri

- Her bölüm kendi konusunu sıfırdan öğretebilmeli. Terimleri ve gözlemlenebilir ilişkileri tanıt, yönlendirmeli deney yaptır, sonra yeni bir durumda oyuncunun tek başına uygulamasını iste. Formül veya model düzeneğin davranışını belirlesin.
- Her deneyin başında, kural yanlış çalışırsa ortaya çıkabilecek bir sonucu kısa ve atlanabilir bir animasyonla göster. Kurmaca arıza durumunu sahnede anlaşılır kıl. Onarımdan sonra aynı düzenekte sonucun nasıl değiştiğini göster.
- Öğretim sırasını seçilen sınıfın veya sınav rotasının kazanımlarına göre kur. Kaynak, varsayım ve birimleri doğrula. Bir anlatım sadeleştirmesi yapıldığında ekrandaki şema ve etiketleri buna göre yaz.
- AI slop kabul edilmez. Her görsel, metin ve hareketin oyunda bir amacı olsun. Tekrarlı yapay zekâ metni, dekoratif etiket yığını, hatalı anatomi, çarpık geometri ve stil dışı varlık teslim edilmeden önce düzeltilir.
- Sahneyi Godot içinde hedef çözünürlükte incele. Kontroller, etiketler ve ölçümler okunmalı. Renkle verilen durumları yazı, sembol veya hareketle de göster. Doğru giriş, yanlış giriş, bağımsız uygulama ve yeniden deneme akışlarını dene.

## Çalışma alanı

Her görev için güncel `main` üzerinden ayrı bir dal aç. Örnek olarak Fizik istasyonu için `mission/free-fall` kullan. Birden fazla ajan aynı bilgisayarda eşzamanlı çalışacaksa her dalı ayrı klon veya worktree içinde aç. İstasyonun sahne ve mantığının tek yazarı olsun. Varlıklar ayrı dal ve dosyalarda paralel üretilebilir. [Varlık üretimi ve Claude talep şablonu](docs/ASSETS.md)

Örneğin bir kişi `mission/free-fall` dalında Düşüş Odası'nı geliştirirken diğeri `mission/heart` dalında Kalp Odası'nı geliştirebilir. İkisi de sahnesini kendi `mission.tres` dosyasına bağlar ve F5 ile kontrol merkezinden dener.

| İş | Hat | Yazma alanı |
|---|---|---|
| Mevsim Gözlemevi | LGS | `stations/seasons/` |
| Köprü Atölyesi | LGS | `stations/bridge/` |
| Prizma Deposu | LGS | `stations/prism/` |
| Basınç İstasyonu | LGS | `stations/pressure/` |
| Gösterge Laboratuvarı (LGS Fen) | LGS | `stations/indicator/` |
| Tarih Meydanı (LGS İnkılap Tarihi) | LGS | `stations/history/` |
| Ölçüm Atölyesi | YKS | `stations/measurement/` |
| Vektör Limanı | YKS | `stations/vectors/` |
| Depo Atölyesi (türev) | YKS | `stations/derivative/` |
| Düşüş Odası | YKS | `stations/free_fall/` |
| Newton Kızağı, Atış Alanı, Çarpışma Hattı | YKS | `stations/newton/`, `stations/projectile/`, `stations/collision/` |
| Dalga Girişimi, Fotoelektrik Kapısı, Spin Hattı | YKS | `stations/waves/`, `stations/photoelectric/`, `stations/spin/` |
| Kalp Odası, Kas Atölyesi | YKS | `stations/heart/`, `stations/muscle/` |
| Fikir Meydanı (felsefe) | YKS | `stations/philosophy/` |
| TYT, AYT ve YDT ders görevleri, Üç Güneş | YKS | `stations/yks/` |
| Kontrol merkezi ve ortak altyapı | Ortak | `scenes/`, `scripts/`, `project.godot`, `docs/DESIGN.md`, `docs/GAME_DESIGN.md` |

İstasyonun sahnesini, GDScript dosyalarını, varlıklarını ve yerel notlarını kendi klasörüne koy. Ortak dosya ihtiyacını görev tesliminde belirt. Ortak dosyaları yalnızca o iş için ayrılan entegrasyon dalında değiştir. Açılış çalışması ayrıca verildiğinde `scenes/intro/` altında yürütülür ve giriş noktasına entegrasyon dalında bağlanır. GitHub'da görevi kendi dalından `main` dalına açılan PR ile teslim et.

## Sahneyi bağla

1. İstasyon klasöründe bir `mission.tscn` oluştur. Kök `Control` düğümünün scripti `res://scripts/mission.gd` dosyasını genişletsin.
2. Klasördeki `mission.tres` kaydının `scene` alanına sahneyi bağla. Mevcut `id` değeri ilerleme anahtarıdır.
3. Merkez, aktif `route` değerini sahnenin `_ready()` çağrısından önce verir. Değer `class`, `lgs`, `tyt` veya `ayt` olur. Sahne F6 ile tek başına açıldığında boş değer için kendi varsayılan rotasını kullanır.
4. Oyuncu uygulama adımını başarıyla bitirdiğinde `completed.emit()` çağır. Merkez, onarımı görev kimliğine göre oturumda gösterir. Merkezdeki **Yeniden dene** yeni bir sahne örneği açar. **Kontrol merkezine dön** sahneyi kaldırır.
5. Oyuncu girdisini ve ölçüm hesabını animasyondan ayrı tut. Sahneyi F6 ile, ardından F5 üzerinden ilgili rotadan aç. Doğru ve hatalı giriş, yeniden deneme ve merkeze dönüşü doğrula.

Yeni bir görev klasörü eklenirse kayıt, entegrasyon dalında `scripts/control_center.gd` içindeki kataloğa bağlanır. İçerik kaynağını ve kazanım notunu `mission.tres` içinde koru. Birden fazla rota farklı görev gerektiriyorsa sahne, rota değerine göre deney verisini ve hedefi seçsin.

## 3D sahne ve varlıklar

3D deney için `res://scenes/experiment_3d.tscn` sahnesini görevindeki `Control` altına örnekle. `Viewport/World/Model` altında kendi `Node3D` sahneni kullan. Her örneğin kamerası, ışığı ve 3D dünyası ayrıdır. Kamera veya ışık üzerinde istasyona özgü değişiklikleri kendi sahnende override et. Etiketleri, formülü ve grafiği görev sahnesindeki `Control` düğümleriyle yerleştir.

Prizma, tank veya kiriş gibi modelleri Godot mesh'leriyle kurabilirsin. Blender modellerini `.glb` olarak istasyonun `assets/` klasörüne aktar. Bir modelin etkileşimli parçalarını ayrı ve anlaşılır isimli düğümler olarak kaydet. Modelin bağlantı, ölçek ve yönünü sahnede kontrol et.

## Örnek devir

> Düşüş Odası’nı tasarla. `docs/PLAN.md` içindeki fizik görevini oku. `mission/free-fall` dalında `stations/free_fall/` altında çalış. Deney akışını, görsel geri bildirimi ve kabul ölçütlerini bu klasörde hazırla. Oynanabilir sahneye geçersen yerel görev kaydına bağla. Teslimde sahneyi nasıl açacağımızı, test ettiğin örnekleri ve ortak dosya ihtiyacını yaz.

## Tasarım

Arayüz için [docs/DESIGN.md](docs/DESIGN.md), oyun ve deney tasarımı için [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) tek kaynaktır. İkisi de iki hat için bağlayıcıdır. Her istasyon koda başlamadan önce kendi klasörüne tasarım kartını (`DESIGN_CARD.md`, GAME_DESIGN.md bölüm 4) yazar ve onay alır. Mevcut istasyonların denetimi ve oyun testi notları [docs/review/2026-11-14-deney-denetimi.md](docs/review/2026-11-14-deney-denetimi.md) içindedir.

## İş bölümü: LGS ve YKS

LGS ve YKS iki ayrı kişinin sorumluluğundadır. Kimin hangi hattı yürüteceğini Yasin belirler. Her hat kendi istasyonlarının sahnesinin, mantığının, tasarım kartının ve varlık taleplerinin tek yazarıdır.

| | LGS hattı | YKS hattı |
|---|---|---|
| Rota | `lgs` ve Sınıflar rotasında 5–8. sınıf | `tyt`, `ayt`, `ydt` ve Sınıflar rotasında 9–12. sınıf |
| İstasyonlar | Yukarıdaki tabloda Hat sütunu LGS olanlar | Yukarıdaki tabloda Hat sütunu YKS olanlar |
| Dal adı | `lgs/<istasyon>` (örnek: `lgs/seasons`) | `yks/<istasyon>` (örnek: `yks/free-fall`) |
| Varlık talebi | Talep dosyasında `Hat: LGS` | Talep dosyasında `Hat: YKS` |

**Sınırlar.**

- Bir hat diğer hattın `stations/` klasörüne yazmaz. Diğer hattın istasyonunda bir hata görürsen issue açarsın.
- Aynı mekân iki rotada kullanılıyorsa (örneğin Tarih Meydanı hem LGS İnkılap Tarihi hem TYT/AYT Tarih) mekânın sahnesi tek hattındır. Diğer hat kendi görev verisini kendi klasöründe tutar ve o sahneyi örnekler.
- Bir istasyon iki rotaya açıksa (örneğin `routes = ["class", "lgs"]`) istasyonun sahibi tablodaki hattır. Diğer rotanın içeriği istasyonun sahibiyle konuşularak eklenir.

**Ortak alan.**

- `scripts/`, `scenes/`, `project.godot`, `docs/DESIGN.md` ve `docs/GAME_DESIGN.md` iki hattın ortak alanıdır. Ortak alanda değişiklik `integration/<konu>` dalında yapılır ve PR'ı diğer hattın sahibi onaylar.
- Ortak bileşenler (tema, HUD, ayar plakası, konuşma satırı, LLM değerlendiricisi, geçişler): İlk ihtiyaç duyan hat bir GitHub issue açar ve "üstlendim" yazar, bileşeni `integration/` dalında yapar. Aynı bileşeni iki hat aynı anda yazmaz.
- `scripts/control_center.gd` içindeki kataloğa her hat yalnızca kendi kayıtlarını, kendi bloğunun altına (`# LGS` ya da `# YKS` yorumu) ekler.
- DESIGN.md ya da GAME_DESIGN.md'de bir kuralın değişmesi gerekiyorsa değişiklik ayrı bir PR'dır ve iki hattın sahibi de onaylar.

**Teslim.** Her hat kendi istasyon PR'ını `main` dalına açar. PR açıklamasında tasarım kartı, 1280×720 ve %130 yazı boyutunda ekran görüntüleri, oyun testi notu ve test çıktısı bulunur. Kabul listeleri DESIGN.md ve GAME_DESIGN.md içindedir.
