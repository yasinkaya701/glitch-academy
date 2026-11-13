# Felsefe İstasyonu · Görsel ve Animasyon Katmanı

Kapsam: 8 filozofun (Sokrates, Platon, Aristoteles, Epiküros, el-Kindî, el-Fârâbî, İbn Sînâ, İbn Rüşd) ayakta tam boy görünümü, doğal yüz/mimik/duruş animasyonu ve Bannerlord tarzı konuşma sahnesi. Diyalog akışı, kart mantığı, ses ve `mission.tscn`/`mission.tres` entegrasyonu bu kapsamın dışındadır.

- **Sonraki ajanlar için karakter görsel dili ve kare sözleşmesi:** [CHARACTER_STYLE.md](CHARACTER_STYLE.md)
- **Codex varlık tamamlama talebi:** [docs/requests/006-philosophy.md](../../docs/requests/006-philosophy.md)

## Hızlı Kullanım

```gdscript
var stage := ConversationStage.new()
add_child(stage)
stage.show_philosopher(&"socrates")                    # mekân + karakter + yıldız halkası
stage.show_line("Sokrates", "Bilmediğimi biliyorum.")  # tek satır altyazı (≤90 karakter)
stage.actor.set_speaking(true)                         # konuşurken ağız, çene ve baş onayı oynar
stage.set_memory_stage(1)                              # 0..4: "kafamın içinde bir şey kımıldadı" (stir)
stage.set_anger(0.6)                                   # yanaklar kızarır, kaşlar çatılır, >0.7 titrer
stage.actor.set_pose(&"pose_hand_chin")                # el-kol duruşu yaması (varsa)
stage.actor.exit_angry()                               # başarısızlık: öfkeyle meydandan çekilir
stage.actor.slump_defeated()                           # başarısızlık: fikrinden dönemedi, söner
```

F6 ile `visual/preview.tscn`: `1–8` filozof, `Boşluk` konuş, `M/N` hafıza aşaması, `A/S` öfke, `R` kıpırtı tepkisi (`stir`), `E` öfkeyle çıkış, `X` yenile.

## Canlı Mimik ve Hareket Mimarisi

1. **Üç Katmanlı Yüz Birleşimi (`PhilosopherActor`):**
   - **Alt yüz / ağız (`face_mouth_mid`, `face_mouth_open`, `face_mouth_round`):** Ses genliğine göre 55 ms çapraz solma ile değişir.
   - **Üst yüz (`up_angry`, `up_eyes_closed`, `up_confused`, `up_thinking`, `up_smile`):** Ağız çizgisinin üstünü korur; karakter **konuşurken aynı anda** kaşlarını çatabilir, göz kırpabilir veya şaşırabilir.
   - **Organik mikro-deformasyon shader'ı (`visual/face_live.gdshader`):** Yama sınırlarında deformasyonu sıfır tutarak gövdeyle dikişsiz birleşir; iç bölgede boyun pivotlu baş eğimi (`head_tilt`), konuşma onayı (`head_shift`), kesintisiz çene/sakal esnemesi (`jaw_open`), kaş kuşağı hareketi (`brow_lift`), göz kısılması (`eye_squint`) ve elmacık kızarması (`cheek_blush`) uygular.
2. **Sakkadik Bakış, Çift Göz Kırpma ve Tepkiler:**
   - Sabit sinüs salınımı yerine sakkadik odak değişimi, %22 olasılıklı doğal çift göz kırpma (`double-blink`), nefes faz farkı ve hafıza aşamasına göre çökük/soluk (`0`) → dik/sıcak (`4`) duruş geçişi çalışır.
   - `stir` (Aşama 1: *"Aa… kafamın içinde bir şey kımıldadı"*): ani hafif irkilme + çift göz kırpma + şaşkın/düşünceli kaş ve baş eğimi.

## Varlık Üretim Hattı

Ham kareler `stations/philosophy/source/<id>/` altında tutulur. Yeni kare eklendiğinde repo kökünden tek komut çalıştırılır:

```sh
python3 stations/philosophy/tools/build_characters.py
```

Betik yeşil perdeyi temizler, eliptik yüz maskesiyle `body.png`, `head.png`, `face_*.png`, `up_*.png`, `pose_*.png` dosyalarını ve `data/characters.json` meta verisini üretir.

## Kaynak ve Not

- Karakterler yapay zekâ ile üretilmiş tarihsel olarak makul temsili görsellerdir; hiçbirinin hayattayken yapılmış portresi yoktur. Oyunda "temsili görsel" olarak etiketlenmelidir.
- Ortak dosya ihtiyacı (entegrasyon dalı): `docs/ASSET_SOURCES.md` kaynak satırı ve `scripts/control_center.gd` kataloğu.
