# Build ve yayın notları

## Gemini anahtarı (ses ve LLM)
Oyun Gemini'yi üç yerde kullanır: MERİDYEN ve kişilerin sesi (TTS), mikrofonla konuşma (STT) ve filozof/tarih sohbeti (LLM). Hepsi `scripts/narrator.gd` ve `*_brain.gd` üzerinden aynı anahtarı okur. Anahtar sırası:

1. `GEMINI_API_KEY` ortam değişkeni
2. `user://llm_key.txt` (macOS: `~/Library/Application Support/Godot/app_userdata/3 Cisim 1 Dünya/llm_key.txt`)
3. `res://llm_key.txt` — build'e gömülü anahtar. Dosya `.gitignore`'dadır, depoya girmez.

Anahtar yoksa oyun çalışmaya devam eder: ses yerine yazı ve ağız hareketi, sohbette yerel anahtar sözcük çözümleyici kalır.

**Export:** Export önayarında "Resources → Filters to export non-resource files" alanına `llm_key.txt` ekle ve dosyayı proje köküne koy. Gömülü anahtar, build'i alan herkes tarafından çıkarılabilir; yayında kota ve alan kısıtlı (HTTP referrer ya da uygulama kısıtlı) bir anahtar kullan, ya da isteği kendi sunucundan geçir.

## Python gerekmez
Ses ve mikrofon artık Python ya da dış program çağırmaz; build içinde olduğu gibi çalışır. `assets/audio/` MP3'leri, `assets/fonts/` yazı tipleri ve Godot'un ürettiği ses önbelleği (`user://voice_cache/`) yeterlidir.

## Mikrofon
`project.godot` içinde `audio/driver/enable_input=true`. macOS export'ta önayarın "Privacy → Microphone Usage Description" alanını doldur ("Sesinle filozoflarla konuşmak için."), Windows ve Linux'ta ek ayar gerekmez.

## Ses önbelleği
Üretilen her replik `user://voice_cache/gemini_<özet>.wav` olarak saklanır; aynı cümle ikinci kez istenmez. Filozof ve tarih kişilerinin aşama repliklerini ilk konuşmada arka planda önceden üretir.
