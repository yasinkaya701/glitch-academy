# Yanlış Dünya · Glitch Academy

Türkçe, masaüstü bir eğitim oyunu. Oyuncu bozulan bir dünya kuralını deneyle keşfeder, ölçüm veya modelden çıkardığı kuralı yeni bir durumda kullanır ve istasyonu onarır. 3D deney sahneleri, 2D grafik ve formül panelleriyle aynı arayüzde çalışır.

## Başlat

1. Godot **4.7.2 Standard** sürümünde proje yöneticisinden `project.godot` dosyasını içe aktar.
2. Kontrol merkezini açmak için editörden **F5** tuşuna bas.
3. Sınıf veya sınav rotası seç ve istasyonun görev özetine bak.

Terminalden açmak için repo kökünde şunu çalıştır.

```sh
godot --path .
```

Kontrol merkezi, 5–12. sınıf filtresi, LGS/TYT/AYT rotaları ve altı istasyonun kayıtları hazır. İstasyonlar sahneleri bağlandıkça oynanabilir olur.

`scenes/experiment_3d.tscn` her istasyonda kullanılabilen bir 3D sahne alanı sunar. Kamera ve ışık hazır gelir. Godot mesh'lerini veya Blender'dan dışa aktardığın `.glb` modellerini istasyonun kendi klasöründe tut.

## Ekipçe geliştirme

- [Oyun, müfredat ve 24 saatlik plan](docs/PLAN.md)
- [İstasyon sözleşmesi ve görev devri](AGENTS.md)

GitHub reposu özeldir. Repo sahibi, ekip arkadaşının GitHub kullanıcı adına **Settings → Collaborators** üzerinden erişim verir.

## Kontrol

```sh
godot --headless --path . --editor --import
godot --headless --path . --quit-after 2
```

Masaüstü demo için Godot sürümüyle eşleşen macOS dışa aktarma şablonunu kur, macOS presetini oluştur ve paketi sunum bilgisayarında çevrimdışı dene. Editörden F5 ile açılan proje de sunum bilgisayarında hazır bulunsun.
