# YKS Kampanyası ve Kontrol Merkezi — Tasarım

## Niyet

Glitch Academy'nin mevcut fizik, matematik ve biyoloji deneyimlerini bozmadan YKS kapsamını tek, anlaşılır bir kampanya girişinde toplamak. Öğrenci ilk ekranda hangi rotada olduğunu, sıradaki oynanabilir görevi ve TYT/AYT/YDT'nin nasıl ayrıldığını anlamalı. Dünya ve cihaz dili mevcut gece gözlemevi görsel yönünü sürdürür.

## Hedefler

- TYT ve AYT'yi aynı YKS kampanyasının bağımsız rotaları olarak sunmak; YDT'yi isteğe bağlı ayrı yol yapmak.
- Mevcut oynanabilir deneyim kaynaklarını ve bilimsel mantığı korumak.
- Brief'te listelenen Türkçe, edebiyat, geometri, kimya, biyoloji, tarih, coğrafya, felsefe, din kültürü, psikoloji, sosyoloji, mantık ve YDT İngilizcesi için özgün etkileşimli kısa görevler tanımlamak.
- Rota panosunda kilit, oynanabilir, onarılmış durumlarını ikon ve metinle göstermek; alan dışı görevleri final için zorunlu tutmamak.
- MERİDYEN arızalarını ve ihanet/Yaşam Protokolü/son hesaplaşma hikâye adımlarını oyun içi başarıya bağlamak.
- UI'ı kısa eylem cümleleri ve sahne içi geri bildirimle kurmak; uzun açıklama ve genel kart ızgaralarından kaçınmak.

## Kapsam dışı

- Mevcut fizik ve anatomi simülasyonlarının bilimsel mekaniklerini yeniden yazmak.
- Her YKS konu başlığını bu teslimde üretmek; hedef, brief'te belirtilen ders başına en az bir özgün bölüm.
- Tam Üç Cisim Problemi simülasyonu veya yeni biyolojik organ sistemleri.
- Web/mobil arayüzü; proje Godot masaüstü uygulamasıdır.

## Yaklaşımlar

1. **Yalnız rota seçimi:** TYT/AYT/YDT ekranı ekleyip var olan görev listesini korumak. Düşük riskli fakat kampanya ve ilerleme hissi zayıf.
2. **Birleşik, rota odaklı görev panosu (seçilen):** Ortak gözlemevinde TYT, AYT ve isteğe bağlı YDT aynı kampanya girişinde net biçimde ayrılır. Alana göre filtrelenmiş görev sırası, durum işaretleri ve sıradaki oynanabilir görev aynı yüzeyde görülür. Mevcut `MissionDefinition` kataloğu, görev sahneleri ve tema korunur.
3. **Her ders için ayrı özel sahne:** En derin ve görsel olarak zengin seçenek; 15'e yakın sahne entegrasyonu, hikâye ve kalite turu bu teslim için fazla geniş, ayrıca mevcut ortak altyapıda büyük değişiklik ister.

## UX ve görsel kararlar

- Kontrol merkezi 3D gözlemevi üzerinde kalır. YKS seçildiğinde TYT, AYT ve isteğe bağlı YDT ayrı rotalar olarak görünür.
- AYT görevleri alan filtresiyle daraltılır; sıradaki tamamlanmamış görev otomatik seçilir ve eylem düğmesi tek hedef olarak kalır.
- Ders başına etkileşim, o derse özgü model ve sonuç taşır: metin anlamı, anlatı kaydı, geometri rotası, numune, dolaşım, kronoloji/kaynak, koordinat, argüman, kavram eşleme, İngilizce çıkarım. Ortak altyapı kullanılabilir ama cevap ve içerikler tekrar edilmez.
- Hâlihazırda eksik sahnesi olan görevler, açıkça "hazırlanıyor" görünür; tamamlanma ve kampanya sonucu yalnız gerçek görev koşullarıyla tetiklenir.
- Menü ve görev ekranları ortak `scripts/ui_theme.gd`, `assets/ui/` ve durum ikonlarını kullanır. Yeni görseller bilimsel anlam taşımıyorsa üretilmez.

## Uygulama kararı

Rota odaklı görev panosu, sınıf/LGS akışına dokunmadan YKS rotasını ekler. `MissionDefinition` rota, alan ve hikâye metaverisini taşır. Mevcut katalog ve tamamlanma bağlantıları tek kaynaktan yönetilir. Eksik ders görevleri için kısa, farklı etkileşim türlerini destekleyen görev altyapısı kurulur; hikâye tetikleri bu görev kimliklerine bağlanır. TYT/AYT dışı görev zorunluluğu alan rotası seçimiyle çözülür. YDT kendi başına tamamlanabilir ve TYT/AYT finaline engel olmaz.

## Kabul ölçütleri

- Yedi brief'te adı geçen YKS deneyinin sahne ve mantığı korunur; mevcut kayıtlar çalışır.
- TYT, AYT ve YDT listeleri/öğrenme hedefleri açıkça ayrılır.
- Her brief dersi en az bir oynanabilir, kendine özgü hedefli göreve sahiptir.
- Hikâye sahneleri/tepkileri tamamlanan görevlere bağlıdır; MERİDYEN'in kırılma anı görünürdür.
- Kalp Odası mevcut dolaşım ve kapakçık deneyimidir ve Yaşam Protokolü'ne bağlanır.
- Her alan dışındaki dersi bitirmeden uygun kampanya finali açılabilir.
- 1280×720 ana ekranda kısa metinler okunur; aktif/bozuk/tamam durumları sadece renkle ifade edilmez.
