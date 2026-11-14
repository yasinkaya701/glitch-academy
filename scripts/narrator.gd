extends Node
## Gemini TTS anlatıcısı (autoload `Narrator`): MERİDYEN, filozoflar ve tarihî kişiler için canlı Türkçe ses.
## Anahtar: GEMINI_API_KEY ortam değişkeni ya da user://llm_key.txt (depoya girmez). Anahtar yoksa `available()` false döner
## ve oyun sessiz yazıyla devam eder. Üretilen ses user://voice_cache/ altında saklanır; aynı cümle ikinci kez istenmez.
## Kullanım: Narrator.speak("metin", &"meridyen")  ya da  var stream = await Narrator.synthesize("metin", &"socrates")

signal speaking_changed(active: bool)

const MODEL := "gemini-2.5-flash-preview-tts"
const URL := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
const KEY_FILE := "user://llm_key.txt"
const CACHE_DIR := "user://voice_cache/"
const SAMPLE_RATE := 24000
const STYLE := "Yavaş, sakin ve bilge bir sesle, düzgün Türkçe telaffuzla söyle: "
const DEFAULT_VOICE := "Gacrux"
## Her kişiye ayrı, olgun ve ağırbaşlı bir Gemini sesi.
const VOICES := {
	&"meridyen": "Gacrux",
	&"socrates": "Sadaltager",
	&"plato": "Charon",
	&"aristotle": "Rasalgethi",
	&"epicurus": "Algieba",
	&"kindi": "Iapetus",
	&"farabi": "Schedar",
	&"ibn_sina": "Orus",
	&"ibn_rushd": "Alnilam",
	&"mete_han": "Alnilam",
	&"alparslan": "Orus",
	&"fatih": "Rasalgethi",
	&"kanuni": "Schedar",
	&"mimar_sinan": "Sadaltager",
	&"ataturk": "Gacrux",
}

var enabled := true
var _player: AudioStreamPlayer
var _key := ""
var _serial := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Voice"
	add_child(_player)
	_player.finished.connect(func() -> void:
		Audio.duck(false)
		speaking_changed.emit(false))
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	_key = _resolve_key()


func available() -> bool:
	return enabled and _key != ""


func _resolve_key() -> String:
	var env := OS.get_environment("GEMINI_API_KEY").strip_edges()
	if env != "":
		return env
	if FileAccess.file_exists(KEY_FILE):
		var file := FileAccess.open(KEY_FILE, FileAccess.READ)
		if file != null:
			var raw := file.get_as_text().strip_edges()
			if raw.begins_with("AIza") or raw.begins_with("AQ."):
				return raw
	return ""


func voice_for(speaker: StringName) -> String:
	return VOICES.get(speaker, DEFAULT_VOICE)


## Metni seslendirir ve çalar. Yeni bir konuşma eskisinin yerini alır.
func speak(text: String, speaker: StringName = &"meridyen") -> void:
	if not available() or text.strip_edges() == "":
		return
	stop()
	_serial += 1
	var mine := _serial
	var stream: AudioStream = await synthesize(text, speaker)
	if stream == null or mine != _serial:
		return
	_player.stream = stream
	_player.play()
	Audio.duck(true)
	speaking_changed.emit(true)


func stop() -> void:
	_serial += 1
	if _player != null and _player.playing:
		_player.stop()
		Audio.duck(false)
		speaking_changed.emit(false)


## Sesi üretir (ya da önbellekten okur). Başarısızsa null döner.
func synthesize(text: String, speaker: StringName = &"meridyen") -> AudioStreamWAV:
	if not available():
		return null
	var voice := voice_for(speaker)
	var signature := (voice + ":" + text).sha256_text().substr(0, 20)
	var cache_path := CACHE_DIR + "gemini_" + signature + ".wav"
	if FileAccess.file_exists(cache_path):
		return AudioStreamWAV.load_from_file(cache_path)
	var http := HTTPRequest.new()
	http.timeout = 40.0
	add_child(http)
	var body := JSON.stringify({
		"contents": [{"parts": [{"text": STYLE + text}]}],
		"generationConfig": {
			"responseModalities": ["AUDIO"],
			"speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}},
		},
	})
	var headers := PackedStringArray(["Content-Type: application/json", "x-goog-api-key: " + _key])
	if http.request(URL % MODEL, headers, HTTPClient.METHOD_POST, body) != OK:
		http.queue_free()
		return null
	var result: Array = await http.request_completed
	http.queue_free()
	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] != 200:
		push_warning("Gemini TTS başarısız: HTTP %d" % result[1])
		return null
	var parsed: Variant = JSON.parse_string((result[3] as PackedByteArray).get_string_from_utf8())
	if not (parsed is Dictionary):
		return null
	var encoded := _first_audio(parsed)
	if encoded == "":
		return null
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = Marshalls.base64_to_raw(encoded)
	wav.save_to_wav(cache_path)
	return wav


func _first_audio(response: Dictionary) -> String:
	for candidate in response.get("candidates", []):
		for part in candidate.get("content", {}).get("parts", []):
			var inline: Dictionary = part.get("inlineData", {})
			if inline.has("data"):
				return String(inline["data"])
	return ""
