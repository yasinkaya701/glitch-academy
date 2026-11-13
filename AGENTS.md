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

| İş | Yazma alanı |
|---|---|
| Mevsim Gözlemevi | `stations/seasons/` |
| Ölçüm Atölyesi | `stations/measurement/` |
| Vektör Limanı | `stations/vectors/` |
| Köprü Atölyesi | `stations/bridge/` |
| Prizma Deposu | `stations/prism/` |
| Düşüş Odası | `stations/free_fall/` |
| Gösterge Laboratuvarı | `stations/indicator/` |
| Kalp Odası | `stations/heart/` |
| Basınç İstasyonu | `stations/pressure/` |
| Kontrol merkezi ve ortak altyapı | `scenes/`, `scripts/`, `project.godot` |

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

Arayüz için [docs/DESIGN.md](docs/DESIGN.md), oyun ve deney tasarımı için [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) tek kaynaktır. Her istasyon koda başlamadan önce tasarım kartını yazar.
