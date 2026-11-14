# Kalp kapakları

Kalp sahnesinin etkileşimli dört kapak modeli. Dosyalar GLB, birim yarıçapı 1 ve akış ekseni +Y olacak şekilde hazırlandı; sahne bunları yuvanın ölçüsüne göre ölçekler.

| Dosya | Anatomik parçalar |
|---|---|
| `tricuspid.glb` | AnnulusTricuspid, LeafletTricuspid1–3, PapillaryTricuspid1–3, ChordaeTricuspid* |
| `mitral.glb` | AnnulusMitral, LeafletMitral1–2, PapillaryMitral1–2, ChordaeMitral* |
| `aortic.glb` | AnnulusAortic, LeafletAortic1–3, CommissureAortic1–3 |
| `pulmonary.glb` | AnnulusPulmonary, LeafletPulmonary1–3, CommissurePulmonary1–3 |

Triküspit ve mitral kapaklarda yaprakçıklar, kordalar ve papiller kaslar bulunur. Aort ve pulmoner kapaklarda üç yarım ay yaprakçığı bulunur. Sahne `valve_prosthesis.gd` içinden uygun GLB'yi yükleyip yaprakçıkları döngü evresine göre oynatır. Harici model veya doku kullanılmamıştır.
