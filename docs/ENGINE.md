# Anatomi motoru

Bütün 3B anatomi deneyleri (kalp, kas, sinir...) aynı çekirdeği kullanır. Bu dosya kısa sözleşmedir.

## Katmanlar
- `scripts/anatomy/anatomy_view.gd` · **AnatomyView**: SubViewport, yörünge kamerası, ışık ve gökyüzü, zemin, model yerleştirme, seçilebilir noktalar (tıkla, sürükle-bırak), 3B etiketler, vurgu. Her deney bunu genişletir.
- `scripts/anatomy/anatomy_util.gd`: sınır kutusu, boru meshi, Bezier, akış parçacıkları.
- `scripts/anatomy/waveform_monitor.gd`: çok kanallı dalga monitörü (EKG, basınç, kuvvet). SubViewport'ta çizilir, 3B ekranda gösterilir.
- `scripts/mission_hud.gd`: tek cümlelik yönerge, adım noktaları, sahnede kaybolan balon, araç şeridi, aksiyon. Yazı paneli yok (docs/UX.md).
- `scripts/ui_theme.gd`: ortak tema.

## Deney = sahne + kural + görev
- **Kural** (çizimden bağımsız, test edilebilir): `heart_model.gd`, `heart_network.gd`, `muscle_sim.gd`.
- **Sahne**: `AnatomyView` alt sınıfı, nesneleri kurar, kural durumunu çizer, girdiyi sinyale çevirir.
- **Görev**: `mission.gd`, adımları ve geri bildirimi yönetir. HUD kullanır.

## Yeni deney eklemek
1. Kuralı yaz ve headless test et.
2. `AnatomyView` alt sınıfı: `_build()` ile nesneleri kur, `add_pickable`, `_update(delta)` ile durumu çiz.
3. Görev: adımlar, `hud.say`, `completed.emit()`.
4. `mission.tres` kaydı ve `control_center.gd` kataloğu.

## Ölçülmüş koordinatlar
Hazır GLB'ler tek parçadır. Nokta konumları GPU derinlik okumasıyla bulunur (derinlik gölgelendiricisi, gamma 2,227 ile çözülür). `TriangleMesh` ışın testi 400k üçgenli modelde takılır, kullanma.
