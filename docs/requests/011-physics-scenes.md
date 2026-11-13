# 011 · Fizik sahneleri: Newton Kızağı, Atış Alanı, Çarpışma Hattı (+ Ölçüm, Vektör cilası)
Durum: açık | Üretici: Codex | Öncelik: yüksek | Kaynak: docs/FIZIK_KAYMALARI.md, docs/STORY.md

Düşüş Odası'ndaki yaklaşım (Codex'in `chamber_bg.png` görseli üstünde Godot'ta çizilen hareket) bu üç sahnede de kullanılacak. Her sahne için **bir ana arka plan** (1920×1080, sağ yarı ölçü yazıları için sade koyu duvar, sol yarı deney düzeneği), **şeffaf sprite'lar** ve gerektiğinde **boş arka plan varyantı**. Tümü fotogerçekçi laboratuvar, tek sıcak ana ışık + soğuk dolgu, metinsiz. Stil: docs/ART_DIRECTION.md.

## A. Newton Kızağı, `stations/newton/assets/`
- `rail_bg.png`: hava yastıklı ray, 40 m'yi ifade eden uzun yatay ray perspektifle, sağda varış çizgisi ışığı, gece laboratuvarı.
- `sled_light.png`, `sled_heavy.png` (şeffaf, 512×256, yandan): aynı itici kızak, ağır olanın üstünde ağırlık blokları. `thruster_glow.png` itici ışıması. `finish_gate.png` varış kapısı (kapalı ve açık iki durum).

## B. Atış Alanı, `stations/projectile/assets/`
- `range_bg.png`: 45 m yükseklikte platform, aşağıda uzanan zemin ve 60 m'lik hedef halkası, gece. Yandan görünüm, parabol çizilebilecek açık gökyüzü.
- `ball_launch.png`, `ball_drop.png` (iki ayrı renk, şeffaf 128×128), `launcher.png` (platformdaki fırlatıcı ve bırakma mıknatısı), `target_ring.png` (zeminde ışıklı hedef, söner ve yanar iki durum).

## C. Çarpışma Hattı, `stations/collision/assets/`
- `track_bg.png`: hava yastıklı düz ray, ortada çarpışma noktası, iki yanda sensör kapıları.
- `cart_a.png`, `cart_b.png` (şeffaf, 384×192, yandan, farklı boyut ve renk; kütle çıkarsanabilsin diye B daha büyük), `cart_stuck.png` (iki arabanın yapışmış hâli), `bumper_spring.png` (esnek çarpışma için yaylı tampon).

## D. Ölçüm Atölyesi ve Vektör Limanı cilası
- `stations/measurement/assets/`: `bench_bg.png` (cetvel, terazi, kronometre olan tezgâh), `ruler.png`, `balance.png`, `stopwatch.png`, `rail_piece.png` (bağlantı parçası), `rail_slot.png` (yuva). Metinsiz, gerçek ölçüm aletleri.
- Vektör Limanı için PR #10 paketi kullanılıyor, eksik parça olursa bildirilecek.

## Kabul
Her PNG Godot'a hatasız aktarılır, adlar yukarıdaki gibi, aynı sahnedeki parçalar aynı ışık yönünde. Teslimde sahneden iki ekran görüntüsü, kaynak ve lisans notu.
