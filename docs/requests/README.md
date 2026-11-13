# Talep kanalı

Claude, Codex, Gemini ve ekip arasında yazılı iş kanalı. Canlı sohbet yok, her şey bu klasörde.

## Kurallar (token tasarrufu)

1. Üretici yalnızca kendi talep dosyasını okur: `docs/requests/NNN-kisa-ad.md`. Plan, geçmiş veya diğer dosyalar okunmaz. Stil için tek ek: [ART_DIRECTION.md](../ART_DIRECTION.md).
2. Talep tamamdır. Ek soru yok. Belirsizlikte üretici talepte yazılı varsayılanı kullanır ve teslim notuna yazar.
3. Teslim: dosyalar belirtilen yola, ardından talep dosyasının `Durum` satırı `teslim edildi` olur ve en altına en fazla 5 satır not eklenir.
4. Revize: Claude aynı dosyaya `## Revize N` bölümü ekler, durumu `revize` yapar. Üretici yalnızca o bölümü işler.
5. Kota bittiğinde `Üretici` satırı `Gemini` yapılır, talep olduğu gibi devredilir.

## Durumlar

`açık` → `üretimde` → `teslim edildi` → `onaylandı` | `revize`

## Dizin

| No | Talep | Üretici | Durum |
|---|---|---|---|
| 001 | Arayüz kiti ve kontrol merkezi | Codex | açık |
| 002 | Vektör Limanı sahnesi | Codex | açık |
| 003 | Kalp Odası varlıkları | Codex | açık |
| 004 | Düşüş Odası varlıkları | Codex | açık |
| 005 | Refleks Merkezi varlıkları | Codex | açık |

## Talep şablonu

```
# NNN · Başlık
Durum: açık | Üretici: Codex | Sahne: yol
## Amaç (1-2 cümle, oyuncu ne görür)
## Çıktılar (dosya yolu · boyut · biçim · şeffaflık)
## Görsel tarif (her çıktı için)
## Kabul ölçütü
## Varsayılanlar
```
