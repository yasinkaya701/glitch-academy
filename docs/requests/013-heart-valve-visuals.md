# 013 · Kalp Odası kapakçık ve doku görselleri
Durum: açık | Üretici: Codex | Sahne: `stations/heart/` | Hat: YKS | Öncelik: yüksek | Kaynak: docs/STORY.md, docs/ART_DIRECTION.md

## Bağlam
Kalp Odası'nın oynanış mantığı onaylandı ve değişmeyecek: kapakları yuvaya yerleştirme, tek yönlü akış, damarları doğru girişlere bağlama, oksijenli/oksijence fakir kan. İstenen yalnızca **görsel katman**. Kod tarafı (`heart_stage.gd`, `valve_prosthesis.gd`, `heart_hud.gd`) hazır.

Kapakçık bilgisi sınav sorusu olarak sorulmaz. Kapakların tek yönlü akışı **görsel sonuçla** anlatılır: doğru takılı kapakta kan ileri akar, ters takılı kapakta kan geri kaçar ve odacıkta birikir. Bu farkın gözle okunabilmesi için kapak yaprakçıklarının açık/kapalı pozları net ayrışmalı.

## A. Kapakçık modelleri, `stations/heart/assets/valves/`
Dört kapak, her biri ayrı GLB: `tricuspid.glb`, `mitral.glb`, `aortic.glb`, `pulmonary.glb`.
- Triküspit ve mitral: yaprakçıklar ve kordat ipçikler (`Leaflet_*`, `Chordae_*`, `PapillaryMuscle_*`). Aort ve pulmoner: üç yarım ay yaprakçığı (`Cusp_1..3`).
- Her kapakta iki ayrı poz: `Open` ve `Closed` (shape key ya da ayrı düğüm). Geçiş yaprakçık menteşesinde pivotla yapılabilsin.
- Kapak halkası (`Annulus`) ayrı düğüm, yuvaya oturma ölçeği notta yazılı.
- Kod şu an düz geometriyle çiziyor. Amaç aynı yerleşimde gerçekçi doku: ince, yarı saydam, hafif ıslak yaprakçık; halkada lifli doku.

## B. Doku ve malzeme farkı
- Dört kapak birbirinden **ufak ama belirgin doku farkıyla** ayrılsın (yüzey kalınlığı, damar deseni, renk tonu). Oyuncu kapağı şekline bakmadan renk-doku ile de ayırt edebilmeli.
- Yaprakçıkta ters/doğru yön okunabilsin: akış tarafında ince ok izi ya da kenar kalınlığı farkı. Metin, etiket ve sayı gömülmez.
- Renkle verilen durum (doğru/yanlış) tek başına renge bağlanmasın: şekil ya da hareketle de okunsun.

## C. Odacık içi kan görünümü, `stations/heart/assets/chambers/`
- `blood_pool_clean.png` ve `blood_pool_dirty.png` (ya da tek shader materyali): oksijenli kan parlak kırmızı, oksijence fakir kan koyu bordo-mavimsi.
- Odacıkta geri akıp biriken kan için kabarcıksız, yoğun bir "birikim" görünümü: ters takılmış kapakta oyuncu odacığın dolduğunu **görsün**.

## D. Kabul
Her GLB Godot'a hatasız aktarılır, ölçek ve pivotlar notta yazıldığı gibi. Kalp sahnesinde 1280×720 ve %130 yazı boyutunda doğru takılı, ters takılı ve eksik kapak durumlarının üç ekran görüntüsü. Metin gömülmez. Kaynak ve lisans notu eklenir. Doku boyutu 2048, toplam ≤ 150 MB.
