extends Node
## Gemini TTS anlatıcısı (autoload `Narrator`): MERİDYEN, filozoflar ve tarihî kişiler için canlı Türkçe ses.
## Anahtar: GEMINI_API_KEY ortam değişkeni ya da user://llm_key.txt (depoya girmez). Anahtar yoksa `available()` false döner
## ve oyun sessiz yazıyla devam eder. Üretilen ses user://voice_cache/ altında saklanır; aynı cümle ikinci kez istenmez.
## Kullanım: Narrator.speak("metin", &"meridyen")  ya da  var stream = await Narrator.synthesize("metin", &"socrates")

signal speaking_changed(active: bool)

const MODEL := "gemini-2.5-flash-preview-tts"
const URL := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
const KEY_FILE := "user://llm_key.txt"
## Build'e gömülecek anahtar (depoya girmez, .gitignore'da): export'ta `llm_key.txt` dosyasını dahil et. Bkz. docs/BUILD.md.
const BUNDLED_KEY_FILE := "res://llm_key.txt"
const STT_MODEL := "gemini-2.5-flash"
const MIC_BUS := "MicRecord"
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
	for path in [KEY_FILE, BUNDLED_KEY_FILE]:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var raw := file.get_as_text().strip_edges()
				if raw.begins_with("AIza") or raw.begins_with("AQ."):
					return raw
	return ""


## LLM sohbet çağrıları için aynı anahtar.
func key() -> String:
	return _key


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
	var body := {
		"contents": [{"parts": [{"text": STYLE + text}]}],
		"generationConfig": {
			"responseModalities": ["AUDIO"],
			"speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}},
		},
	}
	var parsed: Dictionary = await _post(URL % MODEL, body)
	var encoded := _first_part(parsed, "inlineData")
	if encoded == "":
		return null
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = Marshalls.base64_to_raw(encoded)
	wav.save_to_wav(cache_path)
	return wav


## Sıradaki replikleri arka planda önceden üretir; oyuncu o satıra geldiğinde ses hazır olur.
func prefetch(texts: Array, speaker: StringName) -> void:
	for text in texts:
		if not available():
			return
		await synthesize(String(text), speaker)


## Mikrofondan `seconds` saniye dinler, Gemini ile Türkçe metne çevirir. Başarısızsa boş metin döner.
func listen(seconds: float = 4.2) -> String:
	if not available():
		return ""
	if AudioServer.get_bus_index(MIC_BUS) < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, MIC_BUS)
		AudioServer.set_bus_mute(bus, true)
		AudioServer.add_bus_effect(bus, AudioEffectRecord.new())
	var effect := AudioServer.get_bus_effect(AudioServer.get_bus_index(MIC_BUS), 0) as AudioEffectRecord
	var mic := AudioStreamPlayer.new()
	mic.stream = AudioStreamMicrophone.new()
	mic.bus = MIC_BUS
	add_child(mic)
	mic.play()
	effect.set_recording_active(true)
	await get_tree().create_timer(seconds).timeout
	effect.set_recording_active(false)
	mic.queue_free()
	var recording := effect.get_recording()
	if recording == null or recording.data.size() < 4000:
		return ""
	var wav_bytes := _wav_bytes(recording)
	var body := {"contents": [{"parts": [
		{"text": "Bu ses kaydında konuşulanı Türkçe olarak aynen yaz. Yalnızca konuşulan metni döndür; konuşma yoksa boş bırak."},
		{"inlineData": {"mimeType": "audio/wav", "data": Marshalls.raw_to_base64(wav_bytes)}},
	]}]}
	var parsed: Dictionary = await _post(URL % STT_MODEL, body)
	return _first_part(parsed, "text").strip_edges()


## Tek seferlik metin üretimi (LLM): MERİDYEN, filozof ya da tarih kişisi olarak kısa yanıt.
func ask(prompt: String, system_text: String = "") -> String:
	if not available():
		return ""
	var body := {"contents": [{"parts": [{"text": prompt}]}]}
	if system_text != "":
		body["systemInstruction"] = {"parts": [{"text": system_text}]}
	var parsed: Dictionary = await _post(URL % "gemini-2.5-flash", body)
	return _first_part(parsed, "text").strip_edges()


var _inflight := 0


## JSON isteği: en çok iki eşzamanlı çağrı, 429 ve 5xx'te kısa beklemeyle iki kez yeniden dener. Başarısızsa boş sözlük.
func _post(url: String, body: Dictionary) -> Dictionary:
	while _inflight >= 2:
		await get_tree().create_timer(0.2).timeout
	_inflight += 1
	var payload := JSON.stringify(body)
	var headers := PackedStringArray(["Content-Type: application/json", "x-goog-api-key: " + _key])
	var parsed := {}
	for attempt in 3:
		var http := HTTPRequest.new()
		http.timeout = 60.0
		add_child(http)
		if http.request(url, headers, HTTPClient.METHOD_POST, payload) != OK:
			http.queue_free()
			break
		var result: Array = await http.request_completed
		http.queue_free()
		if result[0] == HTTPRequest.RESULT_SUCCESS and result[1] == 200:
			var data: Variant = JSON.parse_string((result[3] as PackedByteArray).get_string_from_utf8())
			if data is Dictionary:
				parsed = data
			break
		if result[1] != 429 and result[1] < 500 and result[0] == HTTPRequest.RESULT_SUCCESS:
			push_warning("Gemini isteği başarısız: HTTP %d" % result[1])
			break
		await get_tree().create_timer(1.5 * (attempt + 1)).timeout
	_inflight -= 1
	return parsed


func _first_part(response: Dictionary, kind: String) -> String:
	for candidate in response.get("candidates", []):
		for part in candidate.get("content", {}).get("parts", []):
			if kind == "inlineData" and part.has("inlineData"):
				return String(part["inlineData"].get("data", ""))
			if kind == "text" and part.has("text"):
				return String(part["text"])
	return ""


func _wav_bytes(recording: AudioStreamWAV) -> PackedByteArray:
	var data := recording.data
	var out := PackedByteArray()
	out.append_array("RIFF".to_ascii_buffer())
	out.append_array(_u32(36 + data.size()))
	out.append_array("WAVEfmt ".to_ascii_buffer())
	out.append_array(_u32(16))
	out.append_array(_u16(1))
	var channels := 2 if recording.stereo else 1
	out.append_array(_u16(channels))
	out.append_array(_u32(recording.mix_rate))
	out.append_array(_u32(recording.mix_rate * channels * 2))
	out.append_array(_u16(channels * 2))
	out.append_array(_u16(16))
	out.append_array("data".to_ascii_buffer())
	out.append_array(_u32(data.size()))
	out.append_array(data)
	return out


func _u16(value: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(2)
	bytes.encode_u16(0, value)
	return bytes


func _u32(value: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, value)
	return bytes
