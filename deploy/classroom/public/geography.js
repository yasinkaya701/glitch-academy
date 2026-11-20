// Selected TYT/YKS geography lessons; this is a 7-unit selection, not the full MEB program.
export const geography = [
  {
    id: 'cografya-harita-ve-konum',
    grade: 9,
    title: 'Koordinatlar, Konum ve Harita Kullanımı',
    focus: 'Enlem-boylam, ölçek ve harita türlerini kullanarak mekânsal çıkarım yapmak.',
    scene: 'atlas',
    person: {
      name: 'Pîrî Reis',
      role: 'Osmanlı denizcisi ve haritacı; 15.–16. yüzyıl',
      voice: 'Denizci-haritacı; rotayı, kıyı bilgisini ve haritanın amacını birlikte sorgular.',
      lens: 'Bir harita, seçilmiş mekânsal bilgiyi belirli bir amaçla gösterir; ölçeğini, projeksiyonunu ve kaynağını bilmeden yorumlanmamalıdır.',
      facts: [
        'Pîrî Reis 1513 tarihli dünya haritasını çizdi; günümüze ulaşan parça Atlas Okyanusu çevresinin bir bölümünü gösterir.',
        'Kitâb-ı Bahriye, limanlar, kıyılar ve deniz rotalarına ilişkin bilgileri bir araya getiren denizcilik eseridir.',
        'Harita projeksiyonları küresel yüzeyi düzleme aktarır; bu aktarımda alan, şekil, mesafe ya da yön özelliklerinin bir kısmı bozulabilir.',
      ],
      prompts: [
        'Aynı enlemde bulunan iki noktanın boylamları farklıysa doğu-batı yönünde hangisinin nerede olduğunu nasıl belirlersin?',
        'Bir liman planında büyük ölçekli harita mı, dünya haritası mı daha ayrıntı verir; neden?',
        'Denizci için kıyı çizgisi ve liman bilgisi ticaret süresini ve güvenliğini nasıl etkiler?',
      ],
      timeline: [
        ['1457 dolayları','Pîrî Reis’in doğum tarihi kaynaklarda genellikle bu şekilde verilir.'],
        ['1513','Dünya haritasını hazırladı.'],
        ['1521–1526','Kitâb-ı Bahriye’yi hazırladı ve gözden geçirdi.'],
      ],
    },
    questions: [
      ['P: 38°K, 27°D; Q: 38°K, 30°D. Q, P’ye göre hangi yöndedir ve bunu hangi koordinat farkı gösterir?', 'Q doğudadır: enlemler eşit olduğundan aynı paraleldedir; boylamı 30°D olarak daha büyüktür.'],
      ['Bir haritada ölçek 1:100.000 ise haritadaki 1 cm gerçekte kaç km’yi gösterir; bu harita ne tür kullanım için uygundur?', '1 km’yi gösterir; büyük ölçekli olduğu için yerel alanlarda daha fazla ayrıntı sunar.'],
    ],
  },
  {
    id: 'cografya-iklim-ve-hava',
    grade: 9,
    title: 'Hava Durumu, İklim ve İklim Elemanları',
    focus: 'Hava olayları ile uzun dönemli iklim özelliklerini ayırıp iklim elemanlarını dağılışla ilişkilendirmek.',
    scene: 'climate',
    person: {
      name: 'İklim araştırmacısı Deniz',
      role: 'Günümüzden kurgusal meteoroloji ve iklim uzmanı',
      voice: 'Veri odaklı; tek günlük ölçümle uzun dönemli eğilimleri karıştırmaz.',
      lens: 'Günlük hava koşulları kısa zaman aralığını, iklim ise uzun yıllar boyunca gözlenen ortalama ve değişkenliği anlatır.',
      facts: [
        'Hava durumu belirli bir yerde kısa sürede gözlenen atmosfer koşullarıdır; iklim uzun dönemli gözlemlerle tanımlanır.',
        'Sıcaklık, basınç, rüzgâr, nem ve yağış başlıca iklim elemanlarıdır; enlem, yükselti, denizellik ve yer şekilleri dağılışta etkilidir.',
        'Türkiye’de kıyı ve iç kesimlerin iklimi; deniz etkisi, yükselti ve dağların uzanışına bağlı olarak farklılaşır.',
      ],
      prompts: [
        'Bugün İstanbul’da yağmur yağması, İstanbul ikliminin her mevsim yağışlı olduğunu kanıtlar mı; hangi veri gerekir?',
        'Karadeniz kıyılarında nem ve yağışın iç Anadolu’ya göre farklı olmasında deniz ve dağların rolü nedir?',
        'Sıcaklık ve yağış grafiğinden tarım takvimi ve günlük yaşam hakkında hangi çıkarımları yapabilirsin?',
      ],
    },
    questions: [
      ['Bir kentte bugün sıcaklık 5°C düştü. Bu tek gözlem iklimin değiştiğini göstermeye yeter mi?', 'Hayır. Hava durumu kısa sürelidir; iklim hakkında çıkarım için uzun yıllara yayılan verilerin ortalama ve değişkenliği incelenir.'],
      ['Türkiye’de denize yakın kıyılar ile yükseltisi fazla iç kesimler arasında sıcaklık ve yağış farkı oluşmasını nasıl açıklarsın?', 'Denizellik sıcaklık farklarını azaltıp nemi artırabilir; yükselti sıcaklığı düşürür, dağların uzanışı yağışın dağılışını etkiler.'],
    ],
  },
  {
    id: 'cografya-nufus-ve-yerlesme',
    grade: 10,
    title: 'Nüfusun Dağılışı ve Yerleşmeler',
    focus: 'Doğal ve beşerî faktörleri nüfus yoğunluğu ile yerleşme dağılışına bağlamak.',
    scene: 'cities',
    person: {
      name: 'Evliya Çelebi',
      role: 'Osmanlı gezgini ve yazar; 17. yüzyıl',
      voice: 'Meraklı bir kent gözlemcisi; pazar, ulaşım, su ve meslekleri sorar.',
      lens: 'Bir yerleşmenin gündelik yaşamını gözlemlerim; Seyahatname’deki anlatıların kendi dönemin bakışını taşıyan tarihsel gözlemler olduğunu da unutmam.',
      facts: [
        'Evliya Çelebi 17. yüzyılda Osmanlı coğrafyasını ve komşu bölgeleri gezdi; Seyahatname’sinde gözlem, aktarılan haber ve anlatı unsurları bir aradadır.',
        'Nüfusun dağılışını iklim, su, yer şekilleri yanında ulaşım, sanayi, ticaret ve hizmetler de etkiler.',
        'Türkiye’de yoğun nüfuslu alanlar arasında Marmara çevresi öne çıkar; kıyı, sanayi, ulaşım ve iş imkânları bu dağılışta etkilidir.',
      ],
      prompts: [
        'Bir kentte liman, fabrika ve iş imkânlarının artması göçü ve nüfus yoğunluğunu nasıl etkileyebilir?',
        'Su kaynaklarının sınırlı olduğu kurak bir alanda yerleşme biçimi neden farklılaşır?',
        'Bir kent gözleminden nüfusun tüm özelliklerine genelleme yapmadan önce hangi ek verileri ararsın?',
      ],
      timeline: [
        ['1611','Evliya Çelebi İstanbul’da doğdu.'],
        ['17. yüzyıl','Osmanlı şehirlerini ve farklı bölgeleri gezerek notlar tuttu.'],
        ['17. yüzyıl sonları','Evliya Çelebi’nin ölüm tarihi ve yeri kesin olarak bilinmemektedir; 1682–1684 dolayları önerilmiştir.'],
      ],
    },
    questions: [
      ['Bir sanayi kentinde iş olanakları artarken nüfus yoğunluğunun yükselmesinin olası neden ve sonuçları nelerdir?', 'İş göçü nüfusu artırabilir; konut, ulaşım ve altyapı talebini büyütür. Hem ekonomik fırsat hem planlama baskısı birlikte değerlendirilir.'],
      ['Dağlık ve engebeli bir alanda yerleşmelerin seyrek veya dağınık olmasını hangi koşullar açıklayabilir?', 'Ulaşım ve tarım alanlarının sınırlanması, eğim ve iklim koşulları seyrek dağılışı etkileyebilir; yerel kaynaklar ve geçim biçimi de hesaba katılır.'],
    ],
  },
  {
    id: 'cografya-turkiye-yeryuzu-sekilleri',
    grade: 10,
    title: 'Türkiye’nin Yer Şekilleri ve Oluşum Süreçleri',
    focus: 'İç ve dış kuvvetleri Türkiye’deki dağ, ova ve platoların dağılışıyla ilişkilendirmek.',
    scene: 'relief',
    person: {
      name: 'Jeoloji araştırmacısı Ece',
      role: 'Günümüzden kurgusal jeoloji ve jeomorfoloji araştırmacısı',
      voice: 'Sahada gözlem yapan; kayaç, süreç ve zaman ölçeğini ayırt eder.',
      lens: 'Yer şekillerini tek bir olayla açıklamam; tektonik hareketleri, aşınma ve birikmeyi, kayaçları ve jeolojik zamanı birlikte değerlendiririm.',
      facts: [
        'Türkiye, Avrasya, Afrika ve Arabistan levhaları arasındaki hareketli kuşakta yer alır; bu tektonik yapı deprem etkinliğiyle ilişkilidir.',
        'Kuzey Anadolu Dağları ve Toroslar genel olarak doğu-batı doğrultusunda uzanır; dağların uzanışı iklim ve ulaşım üzerinde de etki yapar.',
        'Akarsular aşındırma ve biriktirmeyle vadi ve delta ovaları oluşturabilir; Türkiye’de Çukurova önemli delta ovalarındandır.',
      ],
      prompts: [
        'Türkiye’deki fay kuşaklarının levha hareketleriyle ilişkisini harita üzerinde nasıl açıklarsın?',
        'Bir akarsuyun taşıdığı malzemeyi eğimin azaldığı yerde biriktirmesi hangi yer şeklini oluşturabilir?',
        'Dağların kıyıya paralel uzanması ulaşım, yağış ve kıyı-iç kesim ilişkisini nasıl etkiler?',
      ],
    },
    questions: [
      ['Türkiye’de deprem tehlikesinin yüksek olmasını yalnızca ülkenin dağlık olmasıyla açıklamak yeterli midir?', 'Hayır. Levha sınırları ve aktif faylar gibi tektonik etkenler açıklanmalı; dağlık görünüm tek başına deprem nedenini vermez.'],
      ['Akarsuyun taşıdığı alüvyonu denize ulaştığı yerde biriktirmesi kıyı şekillerini ve ekonomik kullanımı nasıl etkileyebilir?', 'Delta ovası gelişebilir; verimli tarım alanı sağlayabilir, ancak taşkın ve kıyı dinamikleri de planlamada dikkate alınmalıdır.'],
    ],
  },
  {
    id: 'cografya-goc-ve-mekansal-etki',
    grade: 10,
    title: 'Göçler ve Mekânsal Etkileri',
    focus: 'Göçün nedenlerini ve kaynak-varış alanlarında oluşturduğu sosyal ve mekânsal değişimi değerlendirmek.',
    scene: 'cities',
    person: {
      name: 'Göç araştırmacısı Selin',
      role: 'Günümüzden kurgusal nüfus coğrafyacısı',
      voice: 'Saygılı ve kanıt odaklı; göç eden insanları istatistiklerin ötesinde ele alır.',
      lens: 'Göçü ekonomik, sosyal, siyasi ve çevresel etkenlerin kesiştiği bir süreç olarak inceler; göç edenlerin hak ve deneyimlerini gözetirim.',
      facts: [
        'Göç; iş, eğitim, güvenlik, aile birleşimi, doğal afet ve çevresel değişim gibi farklı nedenlerle gerçekleşebilir.',
        'İç göç, hem kaynak yerde nüfus ve iş gücünü hem varış yerinde konut, ulaşım ve hizmet talebini değiştirebilir.',
        'Türkiye’de Cumhuriyet döneminden günümüze kırdan kente göç, kentleşme ve ekonomik faaliyetlerin mekânsal dağılışını etkiledi.',
      ],
      prompts: [
        'Bir köyden kente iş için göçün hem kaynak hem varış yerindeki ekonomik etkilerini karşılaştırır mısın?',
        'Zorunlu göç yaşayan bir topluluk için okul, sağlık ve barınma planlaması neden önemlidir?',
        'Göç verisini yorumlarken yaş, eğitim ve göç nedeni bilgilerini birlikte kullanmak ne kazandırır?',
      ],
    },
    questions: [
      ['Kırdan kente göç alan bir şehirde hangi mekânsal ihtiyaçlar artabilir ve bu artışın nedeni nedir?', 'Konut, ulaşım, eğitim, sağlık ve istihdam talebi artabilir; nüfus artışıyla hizmetlerin planlanması gerektiği açıklanır.'],
      ['Bir bölgede iş gücünün göçle azalması üretim ve aile yaşamını nasıl etkileyebilir?', 'Üretimde iş gücü açığı ve yaş yapısında değişim oluşabilir; gelir gönderen göçmenler hane ekonomisini destekleyebilir. Etkilerin bağlama göre değiştiği belirtilir.'],
    ],
  },
  {
    id: 'cografya-ekonomik-faaliyetler',
    grade: 10,
    title: 'Ekonomik Faaliyetler ve Ulaşım',
    focus: 'Ekonomik faaliyet türlerini ülkenin gelişmişlik düzeyi, ulaşım ve coğrafi imkânlarla ilişkilendirmek.',
    scene: 'atlas',
    person: {
      name: 'Coğrafya öğretmeni Arda',
      role: 'Günümüzden kurgusal ekonomik coğrafya öğretmeni',
      voice: 'Açıklayıcı ve karşılaştırmalı; faaliyet türlerini örnek ve veriyle sınıflandırır.',
      lens: 'Üretim ve hizmetlerin dağılışını doğal kaynak, emek, sermaye, teknoloji, pazar ve ulaşım ilişkileriyle açıklarım.',
      facts: [
        'Birincil faaliyetler tarım ve madencilik; ikincil faaliyetler sanayi; üçüncül faaliyetler hizmetlerdir.',
        'Dördüncül faaliyetler bilgi ve araştırma, beşincil faaliyetler üst düzey karar ve uzmanlık hizmetleriyle ilişkilendirilir.',
        'Ulaşım ve iletişim ağları ürünlerin pazara erişimini, hizmetlerin kapsamını ve bölgeler arası iş bölümünü etkiler.',
      ],
      prompts: [
        'Bir pamuk ürününün tarladan tekstil fabrikasına, oradan mağazaya ulaşmasında hangi faaliyet türleri sıralanır?',
        'Liman ve kara yolu bağlantısı bir fabrikanın yer seçiminde maliyet ve pazar erişimini nasıl etkiler?',
        'Hizmet ve bilgi sektörlerinin payı artan bir ekonomide eğitim ve nitelikli iş gücünün rolü nedir?',
      ],
    },
    questions: [
      ['Pamuk üretimi, iplik fabrikası ve tekstil ürününün mağazada satılması hangi ekonomik faaliyet basamaklarına örnektir?', 'Tarım birincil, fabrikadaki üretim ikincil, satış ve perakende hizmeti üçüncül faaliyettir; ürün zinciri doğru sırayla kurulur.'],
      ['Ulaşım ağlarının gelişmesi bir bölgedeki ekonomik faaliyetlerin yer seçimini ve dağılışını nasıl değiştirir?', 'Taşıma süresi ve maliyeti düşebilir, pazarlara erişim artabilir; üretim ve hizmetler yeni merkezlerde yoğunlaşabilir.'],
    ],
  },
  {
    id: 'cografya-afet-risk-yonetimi',
    grade: 10,
    title: 'Doğal Afetler ve Risk Yönetimi',
    focus: 'Türkiye’de afet tehlikesi, maruziyet ve kırılganlığı ayırarak zarar azaltma yollarını açıklamak.',
    scene: 'relief',
    person: {
      name: 'Afet risk uzmanı Derya',
      role: 'Günümüzden kurgusal afet yönetimi ve CBS uzmanı',
      voice: 'Sakin ve çözüm odaklı; hazırlık, güvenli yer seçimi ve kanıta dayalı planlamayı öne çıkarır.',
      lens: 'Afet yalnızca doğal olay değildir; tehlikenin insan ve yapıların maruziyeti ile kırılganlığıyla birleşmesi zarara yol açar.',
      facts: [
        'Deprem, heyelan, sel, çığ ve orman yangınlarının dağılışı; doğal koşulların yanında arazi kullanımı ve insan etkinlikleriyle de ilişkilidir.',
        'Türkiye’de aktif fay kuşakları deprem tehlikesi oluşturur; risk, yapı niteliği, nüfus yoğunluğu ve hazırlık düzeyiyle değişir.',
        'Coğrafi Bilgi Sistemleri (CBS), afet tehlike ve maruziyet katmanlarını birleştirerek risk değerlendirmesi ve müdahale planlamasını destekler.',
      ],
      prompts: [
        'Aynı büyüklükteki deprem neden iki farklı yerleşmede farklı can ve mal kaybına yol açabilir?',
        'Bir taşkın ovasında yeni konut alanı planlarken hangi harita katmanlarını ve sosyal verileri incelemelisin?',
        'Afet öncesi toplanma alanı, eğitim ve erken uyarı çalışmaları zararı hangi yollarla azaltır?',
      ],
    },
    questions: [
      ['Deprem tehlikesi yüksek bir bölgede riski azaltmak için yapılaşma ve hazırlık alanlarında hangi önlemler alınabilir?', 'Zemin ve fay verisine göre planlama, yönetmeliğe uygun yapı, güçlendirme, denetim, eğitim ve acil durum hazırlığı örneklenir.'],
      ['CBS’de fay hattı, nüfus yoğunluğu ve yapı niteliği katmanlarını üst üste getirmek afet planlamasına nasıl yardım eder?', 'Tehlike ile maruziyet ve kırılganlığın mekânsal olarak karşılaştırılmasını; öncelikli müdahale ve kaynak planlamasını sağlar.'],
    ],
  },
];
