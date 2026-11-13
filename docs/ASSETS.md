# Yanlış Dünya · Varlık üretimi

Varlık üretimini Codex ajanları üstlenir. Codex kotası dolarsa açık talebi Gemini devralır. Claude, sahnede ihtiyaç duyduğu varlık için aşağıdaki şablonla talep açabilir. İstasyonun sahibi teslimi kendi görev dalında sahneye bağlar.

## Paralel çalışma

1. İstasyon sahibi kendi `mission/<istasyon>` dalında sahneyi ve oyun mantığını geliştirir. Claude veya istasyon sahibi, gereken varlığı ekipçe kullanılan görev kaydında tarif eder.
2. Üretici, istasyon dalından ayrı bir worktree veya klonda `asset/<istasyon>/<varlik>` dalı açar. Teslim dosyalarını `stations/<istasyon>/assets/<varlik>/` altında tutar. İstasyon sahibi ve üretici farklı dosyalarda çalışır. Her varlık klasörünü aynı anda bir üretici düzenler.
3. İstasyon sahibi görev dalını GitHub'a gönderir. Üretici dosyaları bu dalı hedefleyen bir PR ile teslim eder. Codex kotası nedeniyle devir gerekiyorsa Gemini, aynı talep ve varsa çalışma dalıyla devam eder. İstasyon sahibi teslimi birleştirir, varlığı kendi sahnesine bağlar ve istasyon PR'ını `main` dalına açar.

İstasyon kimlikleri `stations/` altındaki klasör adlarıdır. Örneğin bir istasyon için `stations/seasons/assets/<varlik>/` altında üretim sürerken diğer istasyon kendi klasöründe bağımsız ilerler. Ortak kamera, ışık ve 3D sahne sözleşmesi [AGENTS.md](../AGENTS.md) içinde.

## Claude’un kullanabileceği talep şablonu

```markdown
### Varlık talebi

- İstasyon ve varlık kimliği
- Oyuncunun ekranda neyi görmesi veya hareket ettirmesi gerekiyor?
- Çıktı biçimi ve hedef klasör
- Varsa referans, ölçü, kamera açısı, pivot ve ayrı hareket edecek parçalar
- Hangi sahnede ve hangi koşulda kabul edilecek?
- Üretici, dal ve durum
```

3D modelleri `.glb`, şeffaf 2D görselleri `.png` olarak teslim et. Etkileşimli 3D parçaları isimli düğümlere ayır. Harici referans veya varlık kullandıysan kaynağını ve lisansını talebe ekle.

## Teslim kontrolü

- Dosyaları Godot'a aktar ve eksik doku, ölçek veya yön sorunu varsa düzelt.
- Talepte belirtilen ayrı parçaları ve pivotları editörde kontrol et. 3D modeli gerekirse `scenes/experiment_3d.tscn` ile kurduğun geçici sahnede dene.
- PR açıklamasına teslim yollarını, önizlemeyi ve sahneye bağlayan kişinin bilmesi gereken düğüm adlarını ekle. İstasyon sahibi varlığı kendi sahnesinde açıp hedef kamera ve etkileşimle doğrular.
