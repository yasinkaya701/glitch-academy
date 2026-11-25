# Kalp Odası web derlemesi

Kalp Odası'nı kontrol merkezi olmadan, tek başına açılan bir web sayfası olarak derler. Canlı sürüm: <https://kalp-odasi.vercel.app>

```sh
tools/web_heart/build.sh                 # çıktı: build/web-heart (git'e girmez)
cd build/web-heart && npx vercel deploy --prod
```

Script repo kopyasını geçici bir klasörde değiştirir, çalışma klasörüne dokunmaz. Gerekenler: Godot 4.7.2, web dışa aktarma şablonları, Node (npx) ve rsync.

Kopyada yaptığı değişiklikler:

- Ana sahne `stations/heart/mission.tscn` olur. Kontrol merkezi bu derlemede olmadığı için **Merkeze dön** görevi baştan başlatır.
- Kalp sahnesinin yüklemediği dosyalar çıkarılır: segmentli kalp modelleri ve arşivleri, `art/`, kontrol merkezi, açılış ve diğer istasyonların model ve malzemeleri.
- Modeller sadeleştirilir: kalp kesiti 800 binden 200 bin üçgene, kas modeli 300 binden 60 bine, akciğer 205 binden 41 bine iner. Godot'nun LOD ve gölge mesh kopyaları kapatılır. Kalp, kas ve akciğer dokuları 2048, Metal009 dokuları 1024 pikselle sınırlanır.
- Thread desteği kapalıdır. Bu sayede sayfa COOP/COEP başlıkları olmayan sunucularda da çalışır.

Sonuç: oyun paketi yaklaşık 36 MB, motorla birlikte sıkıştırılmış indirme yaklaşık 41 MB. Sadeleştirmeden önce bu boyut 100 MB'ın üzerindeydi. Bu boyutta Vercel'in dosya başına 100 MB sınırına takılıyordu ve yavaş bağlantılarda açılmıyordu.
