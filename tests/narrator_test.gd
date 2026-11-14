extends Node
## Gemini ses, LLM ve ses oynatıcıları. Anahtar yoksa atlar. Kullanım: godot --headless --path . tests/narrator_test.tscn

var failures := 0


func _ready() -> void:
	var philosophy_voice := load("res://stations/philosophy/visual/voice_player.gd")
	var history_voice := load("res://stations/history/visual/voice_player.gd")
	_check(philosophy_voice != null and history_voice != null, "ses oynatıcıları derleniyor")
	if not Narrator.available():
		print("ATLANDI: anahtar yok (GEMINI_API_KEY, user://llm_key.txt ya da res://llm_key.txt)")
		get_tree().quit(failures)
		return
	var stream: AudioStreamWAV = await Narrator.synthesize("Ölçmeden bilmek tahmindir; ölçünce kural kendini gösterir.", &"meridyen")
	_check(stream != null and stream.data.size() > 20000, "MERİDYEN sesi üretildi")
	var philosopher: AudioStreamWAV = await Narrator.synthesize("Bildiğim tek şey, hiçbir şey bilmediğimdir.", &"socrates")
	_check(philosopher != null and philosopher.data.size() > 20000, "Sokrates sesi üretildi")
	var answer: String = await Narrator.ask("Sokrates olarak tek cümleyle cevap ver: erdem nedir?")
	_check(answer.length() > 10, "LLM yanıt verdi: " + answer.left(60))
	print("BAŞARISIZ: %d" % failures)
	get_tree().quit(failures)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		failures += 1
