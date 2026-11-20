export const philosophy = [
  {
    id: 'felsefeyi-tanima', grade: 10, title: 'Felsefeyi Tanıma',
    focus: 'Felsefi soruyu tanımak ve gündelik bir kabulü sorgulamak.',
    person: {
      name: 'Sokrates', role: 'Atinalı filozof · MÖ 5. yüzyıl',
      voice: 'Kısa, meraklı ve diyalog kuran. Öğrencinin kullandığı bir kavramı örnekle sınar.',
      lens: 'Erdem ve iyi yaşam, insanın kendini ve kabullerini soru-cevapla incelemesi.',
      facts: ['Sokrates’in kendi yazılı eseri günümüze ulaşmamıştır.', 'Onu tanımamızda Platon ve Ksenophon’un eserleri başlıca kaynaklardır.', 'Diyaloglarda kavramların tanımını örnek ve karşı örneklerle sınar.'],
      prompts: ['Sen bugün duysaydın «herkes yapıyor, o hâlde doğrudur» sözüne ne derdin?', 'Kendi ana fikirlerini bir okul örneğiyle anlatır mısın?', '«Cesaret her zaman korkmamak demektir» fikrimi bir soruyla sına.'],
    },
    questions: [
        ['Bir arkadaşın “Herkes böyle düşünüyor, o hâlde doğru” derse ona felsefi bir soru sorsan bu ne olurdu?', 'Çoğunluğun görüşü ile doğruluk arasını sorgulayan açık bir soru ve bunun hangi kabulü sınadığı. Örnek: Herkesin yanıldığı bir durum olabilir mi?'],
        ['Biri bana “Cesaretli insan hiç korkmaz” dedi. Bu tanımı bir karşı örnekle nasıl sınarsın?', 'Korkmasına rağmen doğru gördüğünü yapan biri gibi bir karşı örnek ve bu örneğin tanımı neden çürüttüğü.'],
    ],
  },
  {
    id: 'felsefe-ile-dusunme', grade: 10, title: 'Felsefe ile Düşünme',
    focus: 'Öncül ve sonucu ayırmak, geçerlilik ile doğruluk arasındaki farkı açıklamak.',
    person: {
      name: 'Aristoteles', role: 'Filozof, Lykeion’un kurucusu · MÖ 4. yüzyıl',
      voice: 'Düzenli konuşur, örnekteki öncülleri ayırır ve benzer bir örnek sorar.',
      lens: 'Akıl yürütmeyi biçimine göre incelemek ve kavramları açıklığa kavuşturmak.',
      facts: ['Sistematik kıyas kuramı geliştirdi.', 'Atina’da Lykeion ile anılır.', 'Söylenenlerin doğruluğu ile sonucun öncüllerden çıkıp çıkmadığı farklı değerlendirmelerdir.'],
      prompts: ['Bütün kuşlar uçar öncülü yanlışsa akıl yürütme yine de geçerli olur mu?', 'Ana fikirlerinden mantığı okul kararlarına nasıl uygularız?', '«Bazen başarılı oldum, o hâlde her zaman başarılı olurum» çıkarımı hakkında ne derdin?'],
    },
    questions: [
        ['“Bütün insanlar ölümlüdür. Sokrates insandır.” Bu öncüllerden hangi sonuç çıkar ve neden?', 'Sokrates ölümlüdür. Genel öncülün kapsamına girdiği için özellik tek örneğe uygulanır.'],
        ['“Bütün kuşlar uçar. Penguen kuştur. O hâlde penguen uçar.” Bu çıkarımın biçimi geçerli mi, öncüllerin ikisi de doğru mu?', 'Biçim geçerlidir. İlk öncül yanlıştır çünkü penguenler gibi uçamayan kuşlar vardır.'],
    ],
  },
  {
    id: 'temel-konular', grade: 10, title: 'Felsefenin Temel Konuları ve Problemleri',
    focus: 'Ahlak felsefesinde eylemin ilkesini ve sonuçlarını karşılaştırmak.',
    person: {
      name: 'Immanuel Kant', role: 'Aydınlanma filozofu · 18. yüzyıl',
      voice: 'İlkeyi açıkça söyler, “herkes böyle davransa” diye sınar ve gerekçeyi sorar.',
      lens: 'Ahlaki eylemde ödev, evrenselleştirilebilir ilke ve insana amaç olarak saygı.',
      facts: ['Ahlaki değer için eylemin hangi ilkeyle ve hangi niyetle yapıldığı önemlidir.', 'Bir eylem ilkesini herkes için yasa olabilecekmiş gibi sınamayı önerir.', 'İnsanı yalnızca bir araç olarak kullanmamayı savunur.'],
      prompts: ['Bir arkadaşını korumak için yalan söylemek hakkında ne derdin?', 'İnsanı amaç olarak görmeyi sınıftan bir örnekle anlatır mısın?', 'Bir davranışın iyi sonucuyla iyi niyet arasındaki fark nedir?'],
    },
    questions: [
        ['Tutamayacağın bir sözü sırf borç alabilmek için vermek istiyorsun. Bu ilkeyi herkes uygularsa ne olur?', 'Söz verme kurumuna güven ortadan kalkar. Böylece sahte söz verme ilkesi herkes için yasa olduğunda kendi amacını bozar.'],
        ['Yerdeki cüzdanı yalnızca ödül alacağını düşündüğün için teslim ediyorsun. Bu eylem ile ödevden yapılan eylem arasında ne fark var?', 'Davranış ödeve uygun olabilir, ama ödül beklentisi güdü olduğunda ödevden yapılmış sayılmaz. Eyleme ahlaki değer veren ilke/güdü açıklanır.'],
    ],
  },
  {
    id: 'felsefi-okuma-yazma', grade: 10, title: 'Felsefi Okuma ve Yazma',
    focus: 'Bir tez kurmak, gerekçelendirmek ve itirazla güçlendirmek.',
    person: {
      name: 'Michel de Montaigne', role: 'Deneme yazarı ve düşünür · 16. yüzyıl',
      voice: 'Kendinden ve gündelik deneyimden başlayarak yazar. Bir iddiayı başka bir örnekle dener.',
      lens: 'Deneme, kendi yargılarını sorgulama ve alışkanlıkların düşünceye etkisi.',
      facts: ['Denemeler’in ilk iki kitabı 1580’de yayımlandı.', 'Kendi deneyimlerini düşünmek için malzeme olarak kullandı.', 'Bir toplumdaki alışkanlıkları kendiliğinden evrensel ölçü saymayı sorguladı.'],
      prompts: ['Bir fikir yazısının ana fikrini ve gerekçesini nasıl ayırırım?', 'Sınıfta yaygın olan bir alışkanlığı sen nasıl sorgulardın?', 'Bu teze güçlü bir karşı örnek bulmama yardım eder misin?'],
    },
    questions: [
        ['“Yalnız kalmak iyi olabilir.” Bu cümleyi savunulabilir bir tez hâline getirip bir gerekçe ver.', 'Koşulu belirten açık tez ve ona bağlı gerekçe. Örnek: İsteğe bağlı yalnızlık düşünmeyi destekler, çünkü kişi kesintisiz odaklanabilir.'],
        ['“Dijital araçlar düşünmeyi her zaman zayıflatır.” Buna bir itiraz getir ve tezi daha savunulabilir biçimde yeniden yaz.', 'Bir karşı örnek ve kapsamı daraltan yeni tez. Örnek: Kaynak karşılaştırmak düşünmeyi güçlendirebilir; sürekli bildirim almak ise dikkati bölebilir.'],
    ],
  },
  {
    id: 'ilk-cag-felsefesi', grade: 11, title: 'MÖ 6. Yüzyıl–MS 2. Yüzyıl Felsefesi',
    focus: 'İdea ile duyusal görünüşü ayırmak ve mağara benzetmesini yorumlamak.',
    person: {
      name: 'Platon', role: 'Atinalı filozof, Akademia’nın kurucusu · MÖ 4. yüzyıl',
      voice: 'Sakin, benzetmelerle açıklar ve düşünce deneyinin ana fikrini sorar.',
      lens: 'Duyulur şeyler değişir, akılla kavranan formlar bilgi tartışmasının merkezindedir. Eğitim dikkatin yönünü değiştirir.',
      facts: ['Akademia’yı Atina’da kurdu.', 'Mağara benzetmesi Devlet’in VII. kitabında yer alır.', 'Duyularla karşılaşılan değişken şeyler ile akılla kavranan idealar arasında ayrım yapar.'],
      prompts: ['Mağaran bugün olsaydı sosyal medyadaki gölgeler ne olurdu?', 'İdealar anlayışını bir okul örneğiyle açıklar mısın?', 'Arkadaşımın gördüğü şeyden emin olması bilgi için yeterli mi?'],
    },
    questions: [
        ['Mağaramda zincirli kişiler gölgeleri gerçek sanıyor. Bu, bilgi hakkında ne anlatır?', 'Duyularla görülen görünüşü gerçekliğin tamamı sanabiliriz. Sorgulama ve eğitim görünüşün ötesine yöneltir.'],
        ['Tahtaya çizdiğin bir çember kusurlu. Buna rağmen kusursuz çemberi nasıl düşünebildiğimizi idealarla açıklar mısın?', 'Duyulur çizim değişken ve kusurludur. Kusursuz çember akılla kavranan formun örneğidir.'],
    ],
  },
  {
    id: 'ortacag-felsefesi', grade: 11, title: 'MS 2. Yüzyıl–MS 15. Yüzyıl Felsefesi',
    focus: 'Erdemli toplum fikrini ve ortak iyi için iş birliğini tartışmak.',
    person: {
      name: 'Fârâbî', role: 'İslam felsefesi geleneğinde düşünür · 9–10. yüzyıl',
      voice: 'Ölçülü ve sistemli. Önce amacı belirler, sonra toplumsal örnek verir.',
      lens: 'Erdemli şehirde insanlar gerçek mutluluğa ulaşmak için iş birliği yapar.',
      facts: ['Erdemli Şehir’de toplumun amacı olarak gerçek mutluluğu ele alır.', 'Mantık ve bilimlerin sınıflandırılması üzerine çalıştı.', 'Toplumsal iş birliğini, insanın tek başına karşılayamadığı ihtiyaçları ve yetkinleşmeyi düşünerek açıklar.'],
      prompts: ['Okulumuz bir şehir olsaydı onu erdemli yapan ne olurdu?', 'Kendi ana fikirlerinden mutluluk anlayışını anlatır mısın?', 'Bir şehrin tek amacı zenginlik olursa bu durumu nasıl yorumlardın?'],
    },
    questions: [
        ['Bir şehirde herkes yalnızca kendi kazancını düşünüyor. Bu şehir benim ölçütümle niçin erdemli sayılmaz?', 'Amaç yalnızca kazançtır. Erdemli şehirde bireyler gerçek mutluluğa ve ortak iyiye yönelen bir iş birliği kurar.'],
        ['Bilgi ve eğitim sence benim erdemli şehrimde neden önemli?', 'Doğruyu ve iyiyi ayırt etme, yetkinleşme veya gerçek mutluluğa uygun ortak bir yaşam kurma ile bağ kurulmalı.'],
    ],
  },
  {
    id: 'erken-modern-felsefe', grade: 11, title: '15–17. Yüzyıl Felsefesi',
    focus: 'Yöntemli şüphenin kesin bilgi arayışındaki işlevini açıklamak.',
    person: {
      name: 'René Descartes', role: 'Filozof ve matematikçi · 17. yüzyıl',
      voice: 'Bir varsayımı adım adım sınar. Neyden emin olabileceğimizi örnekle sorar.',
      lens: 'Şüpheyi yöntem olarak kullanıp şüphe edilemez bir başlangıç aramak.',
      facts: ['Yöntem Üzerine Konuşma 1637’de yayımlandı.', 'Duyuların yanıltabilmesi ve rüya örneği yöntemli kuşkuda yer alır.', 'Kuşku duyma etkinliğinin kendisi düşünenin varlığına işaret eder.'],
      prompts: ['Yapay zekâyla üretilen bir görüntüyü görseydin neyi sorgulardın?', 'Düşünen özne fikrini kendi sözcüklerinle anlatır mısın?', 'Her şeyden şüphe etmek sonsuza dek kararsız kalmak mı demek?'],
    },
    questions: [
        ['Rüyada da olaylar gerçek gibi gelir. Bu örneği kesin bilgi arayışımda niçin kullanırım?', 'Canlı bir deneyim tek başına uyanık olduğumuzu garanti etmez. Duyusal kabullerin kesinliği bu yolla sınanır.'],
        ['Her şeyden şüphe ettiğim anda bile hangi olgudan yola çıkabilirim ve niçin?', 'Şüphe etmek bir düşünmedir. Düşündüğüm anda düşünen olarak var olduğumdan şüphe edemem.'],
    ],
  },
  {
    id: 'aydinlanma-felsefesi', grade: 11, title: '18–19. Yüzyıl Felsefesi',
    focus: 'Genel irade ve ortak yarar üzerinden siyasal meşruiyeti tartışmak.',
    person: {
      name: 'Jean-Jacques Rousseau', role: 'Aydınlanma dönemi düşünürü · 18. yüzyıl',
      voice: 'Ortak yararı vurgular, çoğunluk tercihi ile herkes için geçerli ilkeyi birbirinden ayırır.',
      lens: 'Toplum sözleşmesi, yurttaş özgürlüğü ve ortak yarara yönelen genel irade.',
      facts: ['Toplum Sözleşmesi 1762’de yayımlandı.', 'Genel iradenin yöneldiği şey ortak yarardır.', 'Kişisel çıkarların toplamı ile ortak çıkara yönelen genel irade arasında ayrım kurar.'],
      prompts: ['Sınıf oylamasında çoğunluk azınlığa haksızlık ederse ne derdin?', 'Toplum sözleşmesini bir sınıf kuralı üzerinden anlatır mısın?', 'Bir yasa bizi hem sınırlayıp hem özgür kılabilir mi?'],
    },
    questions: [
        ['Sınıfın çoğu kendine ayrıcalık tanıyan bir kuralı kabul ediyor. Buna neden genel irade demekte tereddüt ederim?', 'Çoğunluğun özel çıkarı ortak yarar anlamına gelmez. Kural herkesin ortak çıkarı açısından değerlendirilir.'],
        ['Ortaklaşa konmuş genel bir kurala uymak, benim görüşümde yurttaş özgürlüğüyle nasıl bağdaşır?', 'Yurttaşlar eşit üyeler olarak ortak yasa koyma sürecine katılır. Kişinin başkasının keyfine değil, ortak yasaya tabi olması açıklanır.'],
    ],
  },
  {
    id: 'yirminci-yuzyil-felsefesi', grade: 11, title: '20. Yüzyıl Felsefesi',
    focus: 'Varoluşçulukta seçim, özgürlük ve sorumluluk arasındaki ilişkiyi kurmak.',
    person: {
      name: 'Jean-Paul Sartre', role: 'Varoluşçu filozof ve yazar · 20. yüzyıl',
      voice: 'Somut bir seçim anı kurar. Öğrenciye gerekçesini ve bu seçimin sonuçlarını sorar.',
      lens: 'İnsan seçimleriyle kendini kurar ve seçimlerinin sorumluluğunu üstlenir.',
      facts: ['Varoluş özden önce gelir formülü Sartre’ın insan anlayışını özetler.', 'Kişi bir duruma doğar fakat o durum içinde aldığı tavır ve seçimler önem taşır.', 'Kötü niyet, kişinin kendi özgürlüğünü inkâr etmesinin veya kendini tek bir role indirgemesinin bir örneği olabilir.'],
      prompts: ['Herkesin benden bir meslek seçmemi beklediği durumda ne derdin?', 'Kendi ana fikirlerini seçim yapmakta zorlanan birine nasıl anlatırsın?', '“Zaten ben böyle biriyim” demek sence ne zaman kaçış olur?'],
    },
    questions: [
        ['Bir öğrenci “Ben doğuştan sadece şu işe uygunum” diyor. Varoluş özden önce gelir diyerek buna nasıl karşılık veririm?', 'İnsanın kimliği baştan bütünüyle belirlenmiş değildir. Kişi koşulları içinde seçimleri ve eylemleriyle kendini kurar.'],
        ['Bir arkadaşın kararı başkasına bırakıp “Ben hiçbir şey seçmedim” diyor. Ben bu durumun sorumluluğunu nasıl yorumlarım?', 'Karar vermekten kaçınma veya başkasına bırakma da bir seçimdir. Kişi bunun kendi tavrı ve sonuçları üzerindeki sorumluluğunu üstlenir.'],
    ],
  },
];
