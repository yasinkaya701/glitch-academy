# 003 · Kalp Odası varlıkları
Durum: açık | Üretici: Codex | Sahne: `stations/heart/mission.tscn`

## Amaç
AYT Dolaşım: oyuncu kalbin yapısını, dört kapakçığı ve iki dolaşımı öğrenir. Gerçekçi, bilimsel olarak doğru anatomi. Akış, kapakçık durumu ve oksijen düzeyi Godot'ta çizilir, görsele işlenmez.

## Çıktılar (`stations/heart/assets/`, hepsi aynı 2048×2048 tuval, aynı hizada, şeffaf PNG)
| Dosya | İçerik |
|---|---|
| `heart_base.png` | Kalbin ön kesiti, anatomik yönde (hastanın sağı görüntünün solunda). Kas duvarı, dört odacık iç boşluğu açık, boş (kan yok), iç yüzey dokusu. |
| `valve_tricuspid_open.png` `_closed.png` | Sağ kulakçık–karıncık arası, 3 yaprakçıklı. Aynı konumda iki durum. |
| `valve_mitral_open.png` `_closed.png` | Sol taraf, 2 yaprakçıklı. |
| `valve_pulmonary_open.png` `_closed.png` | Sağ karıncık çıkışı, 3 yarım ay. |
| `valve_aortic_open.png` `_closed.png` | Sol karıncık çıkışı, 3 yarım ay. |
| `vessels.png` | Üst ve alt ana toplardamar, akciğer atardamarı, 4 akciğer toplardamarı, aort ve kavsi. Atardamar ve toplardamar ayırt edilir (duvar kalınlığı). Renk nötr gri-pembe, oksijen rengi Godot'ta verilir. |
| `lungs.png` | İki akciğer, alveol detayı olan büyütülmüş bir kesit ek olarak `alveoli.png` (1024×1024). |
| `body_silhouette.png` | İnsan gövde ve damar ağı, dokulara dağılan kılcal bölge işaretli. |

## Görsel tarif
Tıbbi illüstrasyon kalitesi, yumuşak stüdyo ışığı, tek ana ışık üst solda, koyu zemin uyumu. Yüzey: ıslak doku parlaklığı hafif. Oran ve odacık sayısı doğru: 2 kulakçık, 2 karıncık, sol karıncık duvarı sağdan kalın.

## Kabul ölçütü
- Katmanlar üst üste konunca kayma yok, kapakçık durumları aynı noktada.
- Anatomi hatası yok: yaprakçık sayısı, damar sayısı, taraf.
- Görselde yazı yok.

## Varsayılanlar
Stil [ART_DIRECTION.md](../ART_DIRECTION.md). Beyaz zeminli ders kitabı stili üretme.
