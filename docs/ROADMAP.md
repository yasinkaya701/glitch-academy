# Yol haritası · İlk büyük teslim (Dalga 1)

[CURRICULUM.md](CURRICULUM.md) havuzundan A öncelikli, ders dengesi gözetilmiş 12 deney. Sahibi Claude (sahne ve mantık), varlık Codex veya Gemini ([talep kanalı](requests/README.md)).

| # | Deney | Rota | Durum | Varlık talebi |
|---|---|---|---|---|
| 1 | Vektör Limanı | AYT Fizik | Okların çizimi yenilendi, sahne yeniden tasarlanacak (3B motor) | 002 |
| 2 | Kalp Odası | AYT Biyoloji | **3B etkileşimli sahne çalışıyor** (kapak sürükle-çevir, damar bağla, hız hesabı, canlı monitör, ses). Görsel son kat: Codex #7 | 003, 006, 007 |
| 3 | Düşüş Odası | AYT Fizik | Tasarım hazır | 004 |
| 4 | Refleks Merkezi | AYT Biyoloji | Tasarım hazır | 005 |
| 5 | Depo Atölyesi (türev) | AYT Matematik | Tasarım hazır, varlık gerekmiyor | yok |
| 6 | Gösterge Laboratuvarı | LGS / TYT Kimya | Kayıt var | Dalga 2 talebi |
| 7 | Köprü Atölyesi | LGS Matematik | Kayıt var, kodla çizim | yok |
| 8 | Prizma Deposu | Sınıf / LGS | Kayıt var | Dalga 2 talebi |
| 9 | Basınç İstasyonu | LGS Fen / TYT | Kayıt var | Dalga 2 talebi |
| 10 | DNA ve Genetik Kod | LGS / AYT Biyoloji | Tasarım gerekli | Dalga 2 talebi |
| 11 | Stern–Gerlach (spin) | AYT Kimya | Tasarım var, görsel şov | Dalga 2 talebi |
| 12 | İntegral havuzu | AYT Matematik | Tasarım gerekli | yok |

Ortak parçalar (arayüz kiti, kontrol merkezi) talep 001. Önce 001 ve 002 teslim edilir, kalite çıtası onlarla belirlenir.

## Claude'un kodla yapabileceği ve varlık beklemeyen işler
Türev, integral, köprü: 3Blue1Brown çizgisi, Godot'ta çizim. Bunlar varlık gelmeden başlar.

## Motor ve sonraki deneyler
Ortak 3B çekirdek: [ENGINE.md](ENGINE.md). Kalp bittikten sonra aynı çekirdekle: **Kas Atölyesi** (izole kas, sarkomer, uzunluk–kuvvet eğrisi; `stations/muscle/` yarım), Refleks Merkezi, Düşüş Odası.
