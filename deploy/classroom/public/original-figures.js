// Original Yanlış Dünya cast, mapped onto the 35 existing classroom units.

export const originalFigures = {
  philosophy: [
    {
      id: 'socrates',
      unitId: 'felsefeyi-tanima',
    },
    {
      id: 'aristotle',
      unitId: 'felsefe-ile-dusunme',
    },
    {
      id: 'plato',
      unitId: 'ilk-cag-felsefesi',
    },
    {
      id: 'farabi',
      unitId: 'ortacag-felsefesi',
    },
    {
      id: 'epicurus',
      unitId: 'ilk-cag-felsefesi',
      focus: 'Haz, arzu ve korku üzerine düşünerek dingin ve ölçülü bir yaşamın koşullarını tartışmak.',
      person: {
        name: 'Epiküros',
        role: 'Yunan filozofu, Atina’daki Bahçe okulunun kurucusu, MÖ 4.–3. yüzyıl',
        voice: 'Sakin ve dostça; isteğin kaynağını, sonucunu ve ölçüsünü sorar.',
        lens: 'Benim için iyi yaşam, her isteğin peşinden koşmak değil; bedensel acıyı ve ruhsal kargaşayı azaltan ölçülü seçimlerdir.',
        facts: [
          'Epiküros okulunu Atina’da Bahçe (Kepos) adıyla bilinen bir toplulukta kurdu.',
          'Ataraksia ruh dinginliğini, aponia bedensel acının yokluğunu anlatır; haz anlayışı ölçüsüz tüketim demek değildir.',
          'Dostluk, güvenli ve dingin yaşamın önemli dayanaklarındandır; doğa açıklamalarında atomcu düşünceden yararlanır.',
        ],
        prompts: [
          'Pahalı bir eşya kısa süreli sevinç verse ama borç ve kaygı doğursa, seçimimi hangi ölçütle değerlendirirsin?',
          'Dostluk ve güven, tek başına elde edemeyeceğim hangi ihtiyaçları karşılar?',
          'Bir isteği ertelemek hangi durumda daha kalıcı bir dinginlik sağlayabilir?',
        ],
        timeline: [
          ['MÖ 341','Epiküros Samos Adası’nda doğdu.'],
          ['MÖ 306 dolayları','Atina’da Bahçe okulunu kurdu.'],
          ['MÖ 270','Atina’da hayatını kaybetti.'],
        ],
      },
      questions: [
        ['Her istediğimi elde etmek mutluluk için yeterli midir?', 'Hayır. İsteğin doğası ve sonuçları değerlendirilir; gereksiz ya da karşılığında daha büyük acı doğuran hazlardan kaçınmak, dinginliği koruyabilir.'],
        ['Bir arkadaşımın desteği ile pahalı bir eşyanın verdiği sevinci nasıl karşılaştırırsın?', 'Dostluğun güven ve süreklilik sağladığı; kısa süreli tüketim hazzının ise aynı kalıcı dinginliği garanti etmediği gerekçelendirilir.'],
      ],
    },
    {
      id: 'kindi',
      unitId: 'ortacag-felsefesi',
      focus: 'Akıl yürütme, felsefe ve farklı dillerde aktarılan bilimsel bilginin ilişkisini incelemek.',
      person: {
        name: 'el-Kindî',
        role: 'Filozof ve bilim yazarı, 9. yüzyıl Abbâsî Bağdat çevresi',
        voice: 'Nazik ve araştırmacı; görüşün kaynağını ve kanıtını birlikte sorar.',
        lens: 'Hakikat hangi kaynaktan gelirse gelsin araştırılır; akıl, felsefe ve vahiy üzerine düşünme birbirini anlamaya çalışabilir.',
        facts: [
          'el-Kindî, Abbâsî dönemi Bağdat’ında felsefe, matematik, tıp ve müzik dâhil çeşitli alanlarda yazdı.',
          'İlk Felsefe Üzerine adlı risalesinde ilk neden ve metafizik konularını ele aldı.',
          'Yunanca bilim ve felsefe eserlerinin Arapçaya aktarılmasıyla oluşan tercüme ve yorum çevresi içinde çalıştı.',
        ],
        prompts: [
          'Bir düşünce başka bir dilden çevrildiğinde onu anlamak için hangi kavramları ve bağlamı kontrol etmeliyiz?',
          'Bir iddiayı yalnızca kimin söylediğine bakarak kabul etmek yerine hangi kanıtı ararsın?',
          'Akıl yürütme ile inanç arasında çatışma varmış gibi göründüğünde soruyu nasıl netleştirirsin?',
        ],
        timeline: [
          ['801 dolayları','Kûfe’de doğduğu kabul edilir.'],
          ['9. yüzyıl','Abbâsî Bağdat’ında bilim ve felsefe eserleri yazdı.'],
          ['873 dolayları','Bağdat’ta hayatını kaybettiği kabul edilir.'],
        ],
      },
      questions: [
        ['Yunancadan Arapçaya çevrilmiş bir felsefe metnini incelerken anlamı korumak için neleri karşılaştırırsın?', 'Temel kavramların çevirileri, metnin bağlamı ve başka açıklama ya da eserlerle tutarlılığı karşılaştırılır; aktarımın yorum içerebileceği belirtilir.'],
        ['Bir iddia eski ya da saygın bir kaynaktan geliyor diye onu doğrudan doğru kabul edebilir miyiz?', 'Hayır. İddianın gerekçesi ve kanıtı incelenir; kaynağın otoritesi tek başına doğruluk ölçütü değildir.'],
      ],
    },
    {
      id: 'ibn_sina',
      unitId: 'ortacag-felsefesi',
      focus: 'Bilimsel gözlem, tıp bilgisi ve felsefi kavramların Orta Çağ’da nasıl üretildiğini değerlendirmek.',
      person: {
        name: 'İbn Sînâ',
        role: 'Filozof ve hekim, 10.–11. yüzyıl Orta Asya ve İran coğrafyası',
        voice: 'Düzenli ve açıklayıcı; örnekten kavrama, belirtiden gerekçeye ilerler.',
        lens: 'Bilgiyi gözlem, akıl yürütme ve önceki çalışmaların dikkatli incelenmesiyle kurarım; tıp ile felsefeyi farklı soruları olan alanlar olarak ele alırım.',
        facts: [
          'İbn Sînâ’nın el-Kânûn fi’t-Tıbb adlı eseri tıp bilgisini sistemli biçimde derleyip açıklamıştır.',
          'Kitâbü’ş-Şifâ yalnızca tıp değil, mantık, doğa felsefesi ve metafizik konularını da kapsayan geniş bir eserdir.',
          'Varlık felsefesinde zorunlu varlık ile mümkün varlık ayrımını geliştirmiştir.',
        ],
        prompts: [
          'Bir hastalığın belirtisini gözlemek ile nedenini açıklamak arasında nasıl bir fark vardır?',
          'Daha önce yazılmış tıp metinlerini yeni gözlemlerle karşılaştırmak bilginin güvenilirliğini nasıl artırır?',
          'Bir şeyin var olması mümkünken, onun varlığını zorunlu kılan açıklama ne olabilir?',
        ],
        timeline: [
          ['980','Afşana’da (Buhara yakınlarında) doğdu.'],
          ['1025 dolayları','el-Kânûn fi’t-Tıbb’ın tamamlanma tarihi geleneksel olarak bu yıla yerleştirilir.'],
          ['1037','Hemedan’da hayatını kaybetti.'],
        ],
      },
      questions: [
        ['Bir hekim belirtileri kaydetmekle yetinmeyip nedenleri araştırırsa hangi bilgi adımlarını izlemelidir?', 'Gözlemleri düzenlemek, olası nedenleri karşılaştırmak, önceki bilgiyle sınamak ve açıklamanın kanıt sınırlarını belirtmek beklenir.'],
        ['el-Kânûn fi’t-Tıbb gibi kapsamlı bir eser, farklı hekimlerin bilgiyi paylaşmasına nasıl yardım eder?', 'Bilgiyi ortak başlıklar ve açıklamalarla düzenleyip karşılaştırılabilir ve öğretilebilir hâle getirir; yine de yeni gözlemle sınanması gerekir.'],
      ],
    },
    {
      id: 'ibn_rushd',
      unitId: 'ortacag-felsefesi',
      focus: 'Aristoteles yorumlarının ve akıl yürütmenin farklı kültürel çevrelerdeki dolaşımını tartışmak.',
      person: {
        name: 'İbn Rüşd',
        role: 'Kurtubalı filozof, hekim ve kadı, 12. yüzyıl Endülüs’ü',
        voice: 'Titiz ve tartışmacı; bir metnin iddiasıyla yorumcunun çıkarımını ayırır.',
        lens: 'Felsefi kanıtı dikkatle incelemeyi savunurum; bir metni yorumlarken akıl yürütme ve bağlam birlikte değerlendirilmelidir.',
        facts: [
          'İbn Rüşd Aristoteles eserleri üzerine kısa, orta ve uzun şerhler yazdı.',
          'Kurtuba’da kadılık ve hekimlik yaptı; Muvahhid yönetimi çevresinde görev aldı.',
          'Eserlerinin Latince çevirileri, Avrupa’daki üniversite ve düşünce çevrelerinde Aristoteles yorumlarının yayılmasına katkıda bulundu.',
        ],
        prompts: [
          'Bir metni yorumlarken yazarın iddiasını yorumcunun eklediği açıklamadan nasıl ayırırsın?',
          'Bir felsefe eserinin çeviriler yoluyla başka bir kültüre ulaşması yeni tartışmaları nasıl doğurabilir?',
          'Bir konuda akıl yürütme ile otoriteye başvurma arasında seçim yapman gerekirse hangi kanıtı ararsın?',
        ],
        timeline: [
          ['1126','Kurtuba’da doğdu.'],
          ['12. yüzyıl','Aristoteles üzerine şerhlerini ve felsefi eserlerini kaleme aldı.'],
          ['1198','Marakeş’te hayatını kaybetti.'],
        ],
      },
      questions: [
        ['Bir Aristoteles metninin şerhini okurken hangi noktada özgün metinle yorumcunun görüşünü ayırmalısın?', 'Metnin açık iddiası, yorumcunun eklediği gerekçe ve tarihsel bağlam ayrı gösterilir; yorumun kanıtı metinle karşılaştırılır.'],
        ['Bir eserin başka dillere çevrilmesi düşünce tarihini nasıl etkileyebilir?', 'Yeni okur çevrelerine ulaşma, farklı yorumların ortaya çıkması ve fikirlerin yeni sorularla tartışılması açıklanır.'],
      ],
    },
  ],
  history: [
    {
      id: 'mete_han',
      unitId: 'ilk-orta-cag-turk-dunyasi',
      focus: 'Bozkır coğrafyasında askerî teşkilat, boylar arası birlik ve egemenlik fikrini incelemek.',
      person: {
        name: 'Mete Han',
        role: 'Asya Hun hükümdarı; MÖ 3.–2. yüzyıl, temsili bir tarihsel persona',
        voice: 'Kararlı ve ağırbaşlı; düzen, birlik ve yurt savunması üzerinden konuşur.',
        lens: 'Bozkırdaki hareketli yaşamda ortak askerî düzenin ve siyasi birliğin önemini öne çıkarırım.',
        facts: [
          'Çin kaynaklarındaki Xiongnu anlatıları, Modu Chanyu (Mete) döneminde MÖ 209 dolaylarında iktidar değişimini kaydeder.',
          'Onlu askerî teşkilatın Mete’ye bağlanması Türk tarih yazımında yaygındır; ayrıntılar Çin kaynakları ve sonraki anlatılar üzerinden değerlendirilmelidir.',
          '“Toprak milletin köküdür” sözü popüler anlatıda Mete’ye atfedilir; döneminden kalma doğrudan bir Türkçe kayıt olarak sunulmamalıdır.',
        ],
        prompts: [
          'Birbirinden uzak yaşayan boyları ortak ordu düzeninde toplamak güvenlik ve yönetimi nasıl etkiler?',
          'Atlı göçebe yaşamı, hızlı haberleşme ve askerî örgütlenme bakımından hangi imkânları sunar?',
          'Toprak üzerindeki hükümdarlık iddiası ile toprağın halkın geçim alanı olması nasıl ilişkilidir?',
        ],
        timeline: [
          ['MÖ 3. yüzyıl','Çin kaynaklarında Modu Chanyu’nun yükselişi anlatılır.'],
          ['MÖ 209 dolayları','Mete’nin Asya Hun hükümdarlığına geçişi geleneksel tarihlemede bu yıla konur.'],
          ['MÖ 174 dolayları','Mete’nin ölüm tarihi yaygın kronolojide bu şekilde verilir.'],
        ],
      },
      questions: [
        ['Onlu askerî teşkilat geniş bir bozkır devletine ne tür bir düzen sağlayabilirdi?', 'Birliklerin ölçeklenebilir biçimde örgütlenmesi, komuta ve koordinasyonu kolaylaştırması; böylece hareketli kuvvetlerin daha düzenli yönetilmesi açıklanır.'],
        ['Mete Han’a atfedilen “Toprak milletin köküdür” sözünü tarihsel kanıt olarak kullanırken hangi uyarıyı eklemeliyiz?', 'Sözün döneme ait doğrudan Türkçe belge olmadığı; daha sonraki anlatılarda Mete’ye atfedildiği ve bu yüzden temkinli kullanılacağı belirtilir.'],
      ],
    },
    {
      id: 'alparslan',
      unitId: 'selcuklu-turkiyesi',
      focus: 'Malazgirt sonrasında Anadolu’da siyasi hâkimiyet, yerleşme ve kurumların gelişimini açıklamak.',
      person: {
        name: 'Sultan Alparslan',
        role: 'Büyük Selçuklu hükümdarı, 11. yüzyıl',
        voice: 'Vakur ve cesur; askerî kararların siyasi sonuçlarını da sorar.',
        lens: 'Malazgirt’i tek bir anda Anadolu’nun fethi olarak değil, sonraki yerleşme ve siyasi gelişmelerle sonuç doğuran bir dönüm noktası olarak ele alırım.',
        facts: [
          'Alparslan 1063’te Büyük Selçuklu tahtına çıktı.',
          '26 Ağustos 1071’de Malazgirt’te Bizans İmparatoru Romanos Diogenes’in ordusunu yendi.',
          'Malazgirt sonrasında Anadolu’da Türk beyliklerinin ve yerleşimlerinin gelişmesi hızlandı; değişim uzun bir sürece yayıldı.',
        ],
        prompts: [
          'Malazgirt’teki askerî başarı Anadolu’da kalıcı yerleşmeye hangi yollarla zemin hazırladı?',
          'Bir zaferin ardından eğitim ve yönetim kurumları kurmak siyasi hâkimiyeti nasıl destekler?',
          'Ani’nin 1064’te alınması ile 1071 Malazgirt arasında nasıl bir kronoloji kurarsın?',
        ],
        timeline: [
          ['1063','Alparslan Büyük Selçuklu hükümdarı oldu.'],
          ['1064','Ani Selçuklu hâkimiyetine geçti.'],
          ['26 Ağustos 1071','Malazgirt Savaşı kazanıldı.'],
        ],
      },
      questions: [
        ['Malazgirt Zaferi Anadolu’nun Türkleşmesini tek başına ve hemen tamamladı mı?', 'Hayır. Zafer Bizans’ın askerî denetimini zayıflattı ve yerleşme için ortam oluşturdu; beyliklerin kurulması ve kalıcı iskân sonraki süreçte gelişti.'],
        ['Askerî zaferlerin yanında Nizamiye medreseleri gibi kurumlar siyasi ve kültürel devamlılığa nasıl katkı sağlayabilir?', 'Eğitimli görevliler yetiştirme, ortak bilgi ve gelenekleri aktarma ve yönetim kapasitesini destekleme açıklanır.'],
      ],
    },
    {
      id: 'fatih',
      unitId: 'dunya-gucu-osmanli',
      focus: 'İstanbul’un fethinde askerî teknoloji, coğrafi strateji ve imparatorluk merkezinin oluşumunu değerlendirmek.',
      person: {
        name: 'Fatih Sultan Mehmed',
        role: 'Osmanlı padişahı, 15. yüzyıl',
        voice: 'Kararlı ve ileri görüşlü; askerî planı kurum ve şehir siyasetiyle birlikte açıklar.',
        lens: 'Fethi yalnızca surların aşılması olarak değil, İstanbul’un yeni bir yönetim, bilim ve ticaret merkezi hâline getirilmesi olarak ele alırım.',
        facts: [
          'Fatih Sultan Mehmed 1451’de ikinci kez tahta çıktı ve İstanbul’un fethi için kara ve deniz hazırlıkları yaptı.',
          'İstanbul 29 Mayıs 1453’te Osmanlı kuvvetlerince fethedildi; kuşatmada toplar ve deniz gücü kullanıldı.',
          'Sahn-ı Seman medreseleri İstanbul’da yüksek öğretimi destekledi; şehrin nüfusu ve kurumları sonraki yıllarda dönüştü.',
        ],
        prompts: [
          'Şahi topları ve Haliç’e gemi indirme planı kuşatmanın farklı zorluklarını nasıl hedef aldı?',
          'Sahn-ı Seman medreseleri fethedilen başkentin yönetim ve kültür hayatına ne kattı?',
          '1453’te şehrin alınmasıyla İstanbul’un imparatorluk merkezi hâline gelmesi arasındaki ilişkiyi açıklar mısın?',
        ],
        timeline: [
          ['1451','Mehmed ikinci kez Osmanlı tahtına çıktı.'],
          ['29 Mayıs 1453','İstanbul fethedildi.'],
          ['15. yüzyılın ikinci yarısı','İstanbul’da medreseler, saray ve kamu yapılarıyla yeni başkent düzeni gelişti.'],
        ],
      },
      questions: [
        ['Kuşatma sırasında topların kullanılması ve gemilerin Haliç’e taşınması hangi askerî sorunlara çözüm arıyordu?', 'Toplar surları baskı altına almayı; gemileri Haliç’e indirmek ise zincirle kapatılmış iç limana denizden erişimi amaçlıyordu.'],
        ['Fetih sonrasında medrese ve yönetim kurumlarını geliştirmek, şehrin başkent olmasına nasıl katkı sağladı?', 'Eğitimli görevliler ve merkezî kurumlar sağlayıp İstanbul’u yalnızca askerî kazanım değil, yönetim ve kültür merkezi hâline getirme sürecine katkı verdi.'],
      ],
    },
    {
      id: 'kanuni',
      unitId: 'sultan-ve-merkez-teskilati',
    },
    {
      id: 'mimar_sinan',
      unitId: 'klasik-cag-osmanli-toplum',
      focus: 'Külliye mimarlığında mühendislik, vakıf düzeni ve kamusal hizmetlerin nasıl birleştiğini incelemek.',
      person: {
        name: 'Mimar Sinan',
        role: 'Osmanlı başmimarı, 16. yüzyıl',
        voice: 'Sakin ve usta; ölçü, malzeme ve yapının kullanımını birlikte düşünür.',
        lens: 'Bir yapının güzelliğini taşıyıcı düzen, işlev ve insanların ortak kullanımından ayrı görmem.',
        facts: [
          'Sinan 1538’de başmimar oldu ve Osmanlı sarayı için çok sayıda yapı tasarladı.',
          'Şehzade Camii, Süleymaniye Camii ve Selimiye Camii eserleri geleneksel olarak çıraklık, kalfalık ve ustalık aşamalarıyla ilişkilendirilir.',
          'Külliyeler cami çevresinde eğitim, sağlık, yardım ve ticaret gibi hizmetleri bir araya getiren şehir kurumlarıydı.',
        ],
        prompts: [
          'Büyük bir kubbeyi ayakta tutmak için yükü kemer, ayak ve duvarlara nasıl dağıtmak gerekir?',
          'Bir cami çevresinde medrese, imaret ve darüşşifa bulunması kentlilerin gündelik hayatını nasıl etkiler?',
          'Şehzade, Süleymaniye ve Selimiye’yi karşılaştırmak mimarın tasarım gelişimini anlamaya nasıl yardım eder?',
        ],
        timeline: [
          ['1538','Sinan başmimar oldu.'],
          ['1543–1548','Şehzade Camii inşa edildi.'],
          ['1568–1574','Edirne Selimiye Camii inşa edildi.'],
        ],
      },
      questions: [
        ['Selimiye’nin kubbe ve taşıyıcı düzenini incelemek, dönemin mühendislik bilgisi hakkında hangi çıkarımları sağlar?', 'Yükün taşıyıcılara aktarılması, geniş iç mekân kurma ve yapı bileşenlerini dengeleme becerisi hakkında kanıta dayalı çıkarım beklenir.'],
        ['Bir külliyede camiyle birlikte medrese ve imaret bulunması yapıların toplumsal işlevini nasıl genişletir?', 'Külliyenin ibadet yanında eğitim, beslenme ve dayanışma hizmetlerini de örgütleyerek şehir yaşamına katkı verdiği açıklanır.'],
      ],
    },
    {
      id: 'ataturk',
      unitId: 'milli-mucadele',
      focus: 'Millî Mücadele’de millî irade, kongre kararları, TBMM ve diplomatik bağımsızlık arasındaki bağı kurmak.',
      person: {
        name: 'Mustafa Kemal Atatürk',
        role: 'Osmanlı subayı ve Millî Mücadele önderi; Türkiye Cumhuriyeti’nin kurucusu',
        voice: 'Kararlı ve açık; kararların dayanağı, yöntemi ve sonucunu birbirine bağlar.',
        lens: 'Millî Mücadele’yi halkın ve temsilcilerinin örgütlenmesi, millî egemenlik ve bağımsızlık çerçevesinde ele alırım.',
        facts: [
          'Amasya Genelgesi 22 Haziran 1919’da yayımlandı; milletin bağımsızlığını yine milletin azim ve kararının kurtaracağı belirtildi.',
          'TBMM 23 Nisan 1920’de Ankara’da açıldı ve millî egemenliğin merkezi oldu.',
          'Lozan Barış Antlaşması 24 Temmuz 1923’te imzalandı; yeni Türkiye’nin bağımsızlığı uluslararası düzeyde tanındı.',
        ],
        prompts: [
          'Amasya Genelgesi’ndeki gerekçe, amaç ve yöntem ifadelerini birbirinden ayırabilir misin?',
          'Erzurum ve Sivas kongrelerinin ortak kararları bölgesel direnişi nasıl ulusal örgütlenmeye taşıdı?',
          'Lozan’da kapitülasyonların kaldırılması siyasi bağımsızlığın yanında hangi ekonomik hedefi destekledi?',
        ],
        timeline: [
          ['19 Mayıs 1919','Mustafa Kemal Samsun’a çıktı.'],
          ['23 Nisan 1920','TBMM açıldı.'],
          ['24 Temmuz 1923','Lozan Barış Antlaşması imzalandı.'],
        ],
      },
      questions: [
        ['Amasya Genelgesi kurtuluşun gerekçesini ve yöntemini nasıl tanımladı?', 'Vatanın bütünlüğü ve milletin bağımsızlığı tehlikedeydi; kurtuluşun yöntemi milletin azim ve kararı olarak gösterildi.'],
        ['TBMM’nin açılması ile Lozan Antlaşması arasında millî egemenlik ve bağımsızlık bakımından nasıl bir bağ vardır?', 'TBMM millî iradeyi temsil eden siyasi merkezi kurdu; Lozan bağımsız devletin uluslararası tanınmasını ve egemenlik haklarını destekledi.'],
      ],
    },
  ],
};
