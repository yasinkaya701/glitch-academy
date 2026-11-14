extends Node
## Gemini TTS ve LLM anahtarı denetimi. Anahtar yoksa atlar. Kullanım: godot --headless --path . tests/narrator_test.tscn

func _ready() -> void:
	if not Narrator.available():
		print("ATLANDI: anahtar yok (GEMINI_API_KEY ya da user://llm_key.txt)")
		get_tree().quit(0)
		return
	var stream: AudioStreamWAV = await Narrator.synthesize("Ölçmeden bilmek tahmindir; ölçünce kural kendini gösterir.", &"meridyen")
	var ok := stream != null and stream.data.size() > 20000
	print(("ok   " if ok else "FAIL ") + "Gemini TTS ses üretti (%d bayt)" % (stream.data.size() if stream != null else 0))
	get_tree().quit(0 if ok else 1)
