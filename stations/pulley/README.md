# Palanga Atölyesi

LGS Fen Bilimleri, 8. sınıf basit makineler için etkileşimli görev. MERİDYEN ivme etiketlerini ters gösterir. Oyuncu önce sabit makarayı (`a` ve `a`), ardından tek hareketli makarayı (`a` yük, `2a` serbest ip ucu) düzeltir.

Hareketli makarada yük iki ip kolu tarafından taşınır. İdeal, esnemeyen ve kaymayan ip için toplam uzunluk sabittir: yükün yer değiştirmesinin iki katı kadar ip serbest uçtan alınır. Bu nedenle ivmelerin büyüklükleri `a_yük = a_ip / 2` olur. Animasyon bu oranı korur; sabit makarada yük ve serbest uç eşit miktarda, zıt yönde hareket eder.

Model Godot Mesh düğümlerinden üretilir: metal taşıyıcı, işlenmiş yanaklı kasnaklar, göbekler, bağlantı cıvataları, kılavuz ölçü çizgileri ve halat. Düzenek bir laboratuvar tezgâhına bağlanır; arka duvar, pegboard, çekmeceler ve görev ışığı aynı 3B ortamda modellenir. `mission.tscn` sahnesi doğrudan F6 ile, LGS kampanyası ve sınıf keşfi üzerinden F5 ile açılabilir.

Halatın serbest ucundaki tutamağı sürükleyerek bağlı yükün hareketini gözlemleyebilirsin. Sabit makarada yük, ipin ucu kadar; hareketli makarada ipin ucu kadar yolun yarısı kadar hareket eder. Düzenekte boş bir alana basılı tutup sürüklemek modeli döndürür; tekerlek yakınlaştırır, çift tıklama görünümü sıfırlar. Halatı elle çekmeye başlayınca animasyon durur; “Başlat” düğmesi hareketi sürdürür.

Müfredat referansı: 2018 Fen Bilimleri öğretim programı, F.8.5.1 Basit Makineler. Görev, ideal ip ve makara varsayımını ekranda açıkça söyler.
