# Yanlış Dünya · Ses varlıkları

Bu klasör, `Yanlış Dünya`nın ortak ses kimliği ve uzun vadeli istasyon sesleri içindir. Oyunun ses dili “uzay oyunu” ya da sürekli gerilim değil; öğrenci bir arızayı fark eder, değişkenleri deneyerek kuralı keşfeder, kuralı yeni durumda uygular ve sistemi onarır. Ses, bu öğrenme döngüsünü destekler; yönergenin, ölçümün veya düşünme süresinin önüne geçmez.

## Ses yönü

Müzik üç kullanım durumuna ayrılır: kontrol merkezinde merak ve keşif, deney sırasında odak, onarım sonrasında sakin çözülme. Arıza açılışı için kısa, hafifçe kararsız bir müzikal işaret vardır. Öğrenci adım adım işlem yaparken sürekli müzik değişimi veya her etkileşimde müzikal ödül verilmez.

Ortam sesleri, oyuncunun bulunduğu deney mekânını belli eder: gözlemevi/kontrol merkezi, fizik laboratuvarı, kimya laboratuvarı, biyoloji laboratuvarı, hava-gözlem bahçesi ve ileride tarih görevleri için arşiv odası. Bunlar düşük seviyeli, döngüye uygun taban katmanlarıdır. Ortam sesleri kavramı açıklamaz ve bilimsel bir sonucu tek başına temsil etmez.

Tek seferlik etkileşim sesleri ortak mekanik fiillere göre gruplanır: ölç, ayar değiştir, parçayı yerleştir, düzenek kolunu kullan, sınıflandır, grafiği çiz, akışı başlat ve sistemi onar. İstasyona özgü sesler yalnızca mekanik olarak anlamlı olduklarında kullanılır: örneğin düşen kütlenin sensöre gelişi, kapsülün kenetlenmesi, kimyasal numunenin aktarılması, elektrik devresinin kapanması veya kalp pompası döngüsü.

## Uygulama ilkeleri

- Ses yalnızca gerçekten durumu değiştiren veya anlamlı geri bildirim veren etkileşimlerde çalmalı. Sık değişen kaydırıcılarda her kare/ufak hareket için ses çalmak yerine son değer, eşik veya aralıklarla tetikleme kullanılmalı.
- Doğru/yanlış sesi yargılayıcı olmamalı. Yanlış deneme, yeniden deneme fırsatını açık bırakmalı; doğru ses kısa ve ölçülü olmalı.
- Bilimsel kavramın önemli sonucu ekranda da görünmeli. Ses hiçbir zaman tek başına “doğru” cevabı veya öğrenme bilgisini taşımamalı.
- Uzun süre çalan müzik ve ortam sesleri ayrı ses seviyelerine sahip olmalı. Önerilen bus’lar: `Master`, `Music`, `Ambience`, `SFX`, `UI`.
- Erişilebilirlik için tüm sesler sessize alınabilmeli; temel görev, durum ve sonuç bilgileri görsel/metinsel olarak da verilmelidir.
- Döngü işaretli dosyaların Godot import ayarlarında loop davranışını ayrıca etkinleştir. Üretilmiş MP3’ler kaynak dosyalardır; paketleme aşamasında Godot hedefi için Ogg Vorbis kopyaları üretmek ve kısa arayüz seslerini hedef cihazda test etmek uygundur.

## Klasörler

- `music/`: ana oyun bağlamları için müzikal katmanlar.
- `ambience/`: istasyon ailelerine göre düşük seviyeli ortam sesleri.
- `ui/`: ortak arayüz ve öğrenme geri bildirimi.
- `interaction/`: deney şablonları ve fiziksel etkileşim fiilleri.
- `science/`: disiplin/olay odaklı bilim sesleri.
- `world/`: gelecekteki tarih, arşiv ve belge görevleri.

Dosya kimlikleri, istenen kullanım, loop bilgisi ve üretim durumu `manifest.json` içindedir. Bu ilk paket bütün müfredatın her konusu için ayrı bir müzik parçası değildir; uzun vadeli konu kataloğunda tekrar kullanılabilecek ortak ses sistemidir. Yeni konu eklendikçe önce mevcut mekanik/ortam varlıkları yeniden kullanılır; gerçekten yeni ve anlamlı bir fiziksel olay varsa istasyona özgü yeni efekt eklenir.


## Kalp Odası için ek ses durumu seti

Kalp görevinde yalnızca tek bir dekoratif atış sesi kullanılmamalı. Dinlenme ve egzersiz ritmi, arızalı kapakta geri akış, kapağın yerine oturması ve onarım sonrası ileri akış ayrı varlıklardır. Atış hızı `heart_rate` ve pompa evresiyle eşleştirilmeli; geri akış sesi yalnızca ilgili kapak arızası ve fazında çalmalı. Başarı, pompaya bağlı animasyonla aynı anda duyulmalı. Böylece ses, ekrandaki bilim modelini tamamlar; tek başına tanı veya cevap vermez.


Bu paket sürümünde 57 MP3 var: 4 müzik, 6 ortam katmanı, 9 arayüz/geri bildirim, 13 ortak etkileşim, 23 bilimsel olay ve 2 arşiv sesi. Kalp sesleri dinlenme atışı, egzersiz atışı, pompa döngüsü, kapak geri kaçağı, kapak yerleşmesi ve onarım sonrası akış durumlarını ayrı ayrı kapsar.
