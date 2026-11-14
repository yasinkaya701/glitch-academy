> **Geçersiz.** Arayüz kuralları artık [docs/DESIGN.md](DESIGN.md), oyun tasarımı [docs/GAME_DESIGN.md](GAME_DESIGN.md) içinde. Bu dosya yalnızca geçmiş için duruyor.

# Arayüz ilkeleri · yazı paneli yok

Yasin'in kararı: uzun başlık, paragraf ve açıklama panelleri "AI slop". Bilgi nesneler, göstergeler ve oyuncunun yaptığı işle verilir.

1. **Ekranda tek bir cümlelik yönerge.** En çok 90 karakter, emir kipi ("Kapağı yuvaya sürükle."). Paragraf yok, başlık-gövde-düğme üçlüsü yok.
2. **Öğretim eylemden gelir.** Kavram metinle anlatılmaz: oyuncu dener, düzenek tepki verir (gösterge, dalga, akış, ses), gerekirse tek satırlık geri bildirim çıkar.
3. **Geri bildirim sahnede.** Kısa balon (en çok 60 karakter), ilgili nesnenin yanında ve birkaç saniye sonra kaybolur. Sağ kenarda sabit metin paneli kullanılmaz.
4. **Veriyi cihaz gösterir.** Sayı ve grafik, deney düzeneğinin üzerindeki gerçek cihazlarda (manometre, monitör, ölçü kabı) görünür. Etiket yığını yok.
5. **Bilgi isteğe bağlı.** Ayrıntı için küçük bir "i" düğmesi, tek kısa not açar. Varsayılan ekran temiz kalır.
6. **Kontroller nesne üzerinde.** Düğme, kaydırıcı ve kelepçe düzeneğin parçası gibi görünür. Ortak `ui_theme.gd` stili korunur ama genel menü hissi verilmez.
