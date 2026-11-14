# Oyuna Ses Ekleme · Tek Seferlik Ses Paketi Promptu

Aşağıdaki promptu ses dosyalarını hazırlayacak ajana/modela tek parça halinde gönder:

```text
Bu Godot 4.7 projesi “Yanlış Dünya” adlı, görev istasyonlarından oluşan Türkçe bir eğitim oyunu. Oyuna eksiksiz ses desteği ekleyeceğiz. Önce depodaki proje yapısını, scenes/, scripts/, stations/ klasörlerini ve mevcut AudioStreamPlayer/AudioServer kullanımlarını incele.

ÖNEMLİ: Bu ilk aşamada koda veya dosyalara dokunma, ses üretme ve mevcut dosyaları değiştirme. Bana oyunda gerçekten kullanılan tüm ses ihtiyaçlarını çıkaran TEK bir toplu teslim listesi hazırla. Listeyi verdikten sonra ses dosyalarını tek seferde sağlayacağım; dosyalar geldikten sonra entegrasyonu yap.

İnceleme sonunda:
1. Açılış, kontrol merkezi, görev geçişleri ve oynanabilir tüm istasyonları tara. Ses gerektiren gerçek oyuncu eylemlerini ve oyun sonuçlarını bul; var olmayan olay uydurma.
2. Her ses dosyasına benzersiz, kısa ve İngilizce bir dosya adı ver. Her satırda dosya adı, sesin duyulacağı olay, tür (müzik / ortam / UI / oyun efekti / seslendirme), önerilen format, örnekleme hızı, mono/stereo, yaklaşık süre ve ses karakteri bulunsun.
3. Aynı işlevi gören sesleri istasyonlara göre kopyalama; ortak sesleri bir kez listele. Birbirinden farklı fiziksel olayları (ör. kapak, makara, optik ışın, sıvı akışı) yalnızca oyunda karşılığı varsa ayrı ayrı belirt.
4. Her müzik/ortam parçası için döngü davranışını, başlangıç/bitiş geçişini ve duygu tarifini yaz. Efektlerin kısa, temiz, konuşma ve arayüzü örtmeyecek düzeyde olmasını belirt. Her ses oyun dünyasının ölçülü, merak uyandıran eğitim tonu ve grafit, kırık beyaz, adaçayı, amber görsel paletiyle uyumlu olsun; korku, aşırı arcade, jenerik epik trailer veya dikkat dağıtan sürekli efekt kullanma.
5. Felsefe istasyonunda mevcut stations/philosophy/audio/<filozof>/ altındaki MP3 ve ağız zamanlama JSON dosyalarını incele. Sokrates, Platon, Aristoteles, Epiküros, el-Kindî, el-Fârâbî, İbn Sînâ ve İbn Rüşd için hazır konuşma dosyalarını yeniden isteme veya listeye ekleme. Eksik olan ortak ortam/arayüz seslerini listele; ileride konuşma sesleri AudioServer içindeki ayrı Voice bus üzerinden çalınabilsin.
6. Çıktı tesliminde gerekli klasör yapısını ve dosya adlarını birebir öner (ör. res://assets/audio/music/, res://assets/audio/ambience/, res://assets/audio/ui/, istasyona özel efektler için uygun stations/<id>/assets/audio/ yolu). Bir dosya tekrar kullanılacaksa manifestte tek satırda tanımla.
7. Sonunda en az dosya sayısıyla anlamlı ses kapsamı sağlayan tek bir zorunlu paket ve isteğe bağlı ekleri ayır. Tahmini toplam dosya sayısını ver. Ses üreten araçlar için tek seferde kullanılabilecek kısa mastering/teknik şartname ekle: WAV, 48 kHz, PCM 16-bit veya 24-bit, clipping yok, efekt başlarında gereksiz sessizlik yok, loop noktaları temiz. Müzik ve ortam loop'larında geçiş tıklaması/ani seviye farkı olmasın.

Sonuç biçimi:
- Önce kapsam özeti ve oyunda bulduğun istasyon listesi.
- Ardından numaralı, tek ve konsolide dosya manifesti.
- Sonra ortak ses üretim/mastering şartnamesi.
- En sonda, dosyaları tek seferde hangi klasör yapısıyla teslim etmem gerektiği.

Bu aşamada dosyaları ben sağlayana kadar entegrasyona başlama. Dosyaları sağladığım ikinci aşamada, mevcut seslendirmeyi bozmadan Godot AudioServer bus yapısını kur; müzik, ortam, efekt ve seslendirme ses düzeylerini ayrı yönet; ses düzeylerini kullanıcı ayarında sakla; sessize alma ve sahne değişiminde güvenli geçişleri ekle. Her olayın sesini doğru sahne/istasyon koduna bağla, dosya yollarını ResourceLoader ile doğrula, yüklenmeyen dosyada oyunun çalışmasını sürdür, aynı sesi üst üste kontrolsüz başlatma ve müziği döngüye al. Sahnelerdeki tek tek olayları kod tabanındaki gerçek davranışla eşleştir. Godot 4.7 ile uyumlu, küçük ve merkezi bir AudioManager kullan; gizli anahtar, internet servisi veya runtime ses üretimi ekleme. Mevcut filozof ses oynatıcısını ayrı Voice bus'a bağla.

Entegrasyon sonunda değişen dosyaları, ses dosyalarının beklenen yollarını ve nasıl deneneceğini kısa bir özetle bildir. Kullanılmayan veya kopya ses bırakma.
```
