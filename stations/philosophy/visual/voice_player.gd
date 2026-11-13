class_name VoicePlayer
extends Node
## Filozof ses oynatıcısı, canlı TTS/dudak senkronu ve mikrofon STT (sesle konuşma) sürücüsü.
##
## 1. Önceden üretilmiş mod: stations/philosophy/audio/<id>/<line_id>.mp3 ve .json (50 Hz dudak eğrisi)
##    dosyalarını doğrudan çalar; internet veya API anahtarı gerekmez.
## 2. Canlı ElevenLabs API modu: ELEVEN_API_KEY ortam değişkeni veya user://elevenlabs_key.txt varsa,
##    önbellekte olmayan metinleri /v1/text-to-speech/{voice_id}/with-timestamps uç noktasından canlı çeker,
##    user://voice_cache/ altına kaydeder ve harf zamanlamasıyla filozofun ağzını senkron oynatır.
## 3. Canlı yerel TTS yedeği: Anahtar yoksa serbest LLM yanıtlarını arka plan iş parçacığında
##    gen_voices.py (--who, --text, --out) ile MP3 + 50 Hz dudak eğrisine dönüştürüp seslendirir.
## 4. Mikrofonla konuşma (STT): listen_microphone() arka planda voice_listen.py çalıştırarak
##    oyuncunun sesini Türkçe metne çevirir.

signal line_started(line_id: StringName, text: String)
signal line_finished(line_id: StringName)
signal speech_recognized(ok: bool, text: String)

const AUDIO_DIR := "res://stations/philosophy/audio/"
const LINES_PATH := "res://stations/philosophy/data/lines.json"
const GEN_VOICES_SCRIPT := "res://stations/philosophy/tools/gen_voices.py"
const LISTEN_SCRIPT := "res://stations/philosophy/tools/voice_listen.py"
const CACHE_DIR := "user://voice_cache/"
const KEY_FILE := "user://elevenlabs_key.txt"

var _player := AudioStreamPlayer.new()
var _http := HTTPRequest.new()
var _actor: PhilosopherActor
var _active_id: StringName = &""
var _levels: Array = []
var _fps: float = 50.0
var _fallback_timer: float = 0.0
var _using_fallback: bool = false
var _db: Dictionary = {}
var _pending_live_hash: String = ""
var _pending_live_text: String = ""
var _tts_thread: Thread
var _stt_thread: Thread
var _listening: bool = false


func _ready() -> void:
	add_child(_player)
	add_child(_http)
	_player.finished.connect(_on_audio_finished)
	_http.request_completed.connect(_on_live_tts_completed)
	_load_db()
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)


func _exit_tree() -> void:
	if _tts_thread != null and _tts_thread.is_started():
		_tts_thread.wait_to_finish()
	if _stt_thread != null and _stt_thread.is_started():
		_stt_thread.wait_to_finish()


func bind_actor(actor: PhilosopherActor) -> void:
	_actor = actor


func is_listening() -> bool:
	return _listening


func get_line_text(philosopher_id: StringName, line_id: StringName) -> String:
	var p: Dictionary = _db.get("philosophers", {}).get(String(philosopher_id), {})
	return String(p.get("lines", {}).get(String(line_id), ""))


func get_lines(philosopher_id: StringName) -> Dictionary:
	var p: Dictionary = _db.get("philosophers", {}).get(String(philosopher_id), {})
	return p.get("lines", {})


func get_choices(philosopher_id: StringName) -> Array:
	var p: Dictionary = _db.get("philosophers", {}).get(String(philosopher_id), {})
	return p.get("choices", [])


## Önceden üretilmiş satırı çalar; yoksa canlı ElevenLabs API'yi veya yerel TTS'i dener.
func play_line(philosopher_id: StringName, line_id: StringName) -> String:
	stop()
	var text: String = get_line_text(philosopher_id, line_id)
	_active_id = line_id
	var base_path: String = AUDIO_DIR + String(philosopher_id) + "/" + String(line_id)
	var mp3_path: String = base_path + ".mp3"
	var json_path: String = base_path + ".json"

	if FileAccess.file_exists(mp3_path):
		var stream := _load_mp3(mp3_path)
		if stream != null:
			_load_track_json(json_path)
			_start_stream(stream, text)
			return text

	if text != "":
		speak_live(philosopher_id, text, line_id)
	return text


## Serbest metni canlı ElevenLabs API veya yerel gen_voices.py ile seslendirir.
func speak_live(philosopher_id: StringName, text: String, tag_id: StringName = &"live") -> void:
	stop()
	_active_id = tag_id
	var voice_id: String = _get_voice_id(philosopher_id)
	var sig: String = (String(philosopher_id) + ":" + voice_id + ":" + text).sha256_text().substr(0, 16)
	var cache_mp3: String = CACHE_DIR + sig + ".mp3"
	var cache_json: String = CACHE_DIR + sig + ".json"

	if FileAccess.file_exists(cache_mp3):
		var stream := _load_mp3(cache_mp3)
		if stream != null:
			_load_track_json(cache_json)
			_start_stream(stream, text)
			return

	var api_key: String = _resolve_api_key()
	if api_key != "" and voice_id != "":
		_pending_live_hash = sig
		_pending_live_text = text
		var url: String = "https://api.elevenlabs.io/v1/text-to-speech/%s/with-timestamps" % voice_id
		var headers := PackedStringArray(["xi-api-key: " + api_key, "Content-Type: application/json"])
		var body := JSON.stringify({
			"text": text,
			"model_id": "eleven_multilingual_v2",
			"voice_settings": {"stability": 0.52, "similarity_boost": 0.78, "style": 0.22, "use_speaker_boost": true}
		})
		if _http.request(url, headers, HTTPClient.METHOD_POST, body) == OK:
			_start_fallback_speaking(text, 10.0)
			return

	# Yerel Python TTS (gen_voices.py --who --text --out) ile arka planda gerçek ses + 50 Hz zarf üret
	var py_bin: String = _resolve_python()
	if py_bin != "" and (_tts_thread == null or not _tts_thread.is_alive()):
		if _tts_thread != null and _tts_thread.is_started():
			_tts_thread.wait_to_finish()
		_tts_thread = Thread.new()
		var abs_script: String = ProjectSettings.globalize_path(GEN_VOICES_SCRIPT)
		var abs_mp3: String = ProjectSettings.globalize_path(cache_mp3)
		var who_str: String = String(philosopher_id)
		_start_fallback_speaking(text, 8.0)
		_tts_thread.start(_run_local_tts_job.bind(py_bin, abs_script, who_str, text, abs_mp3, cache_mp3, cache_json))
		return

	var est_duration: float = clampf(float(text.length()) * 0.065, 1.8, 7.0)
	_start_fallback_speaking(text, est_duration)


## Mikrofondan oyuncunun sesini dinleyip Türkçe metne çevirir ve speech_recognized sinyali yayar.
func listen_microphone(seconds: float = 4.2) -> bool:
	if _listening:
		return false
	var py_bin: String = _resolve_python()
	if py_bin == "":
		speech_recognized.emit(false, "")
		return false
	if _stt_thread != null and _stt_thread.is_started():
		_stt_thread.wait_to_finish()
	_listening = true
	_stt_thread = Thread.new()
	var abs_script: String = ProjectSettings.globalize_path(LISTEN_SCRIPT)
	_stt_thread.start(_run_stt_job.bind(py_bin, abs_script, seconds))
	return true


func _run_local_tts_job(
	py_bin: String,
	abs_script: String,
	who_str: String,
	text: String,
	abs_mp3: String,
	cache_mp3: String,
	cache_json: String
) -> void:
	var out := []
	var args := PackedStringArray([
		abs_script,
		"--who=" + who_str,
		"--text=" + text,
		"--out=" + abs_mp3,
	])
	var code: int = OS.execute(py_bin, args, out, true)
	if code == 0:
		call_deferred("_on_local_tts_ready", cache_mp3, cache_json, text)


func _on_local_tts_ready(cache_mp3: String, cache_json: String, text: String) -> void:
	if not FileAccess.file_exists(cache_mp3):
		return
	var stream := _load_mp3(cache_mp3)
	if stream == null:
		return
	_load_track_json(cache_json)
	_start_stream(stream, text)


func _run_stt_job(py_bin: String, abs_script: String, seconds: float) -> void:
	var out := []
	var args := PackedStringArray([abs_script, "--seconds=%.1f" % seconds])
	OS.execute(py_bin, args, out, true)
	var raw: String = "\n".join(PackedStringArray(out)).strip_edges()
	var lines_arr: PackedStringArray = raw.split("\n", false)
	var last_line: String = lines_arr[lines_arr.size() - 1] if not lines_arr.is_empty() else ""
	var parsed: Variant = JSON.parse_string(last_line)
	var ok: bool = false
	var recognized: String = ""
	if parsed is Dictionary:
		ok = bool((parsed as Dictionary).get("ok", false))
		recognized = String((parsed as Dictionary).get("text", "")).strip_edges()
	call_deferred("_on_stt_done", ok, recognized)


func _on_stt_done(ok: bool, recognized: String) -> void:
	_listening = false
	speech_recognized.emit(ok, recognized)


func stop() -> void:
	_http.cancel_request()
	_player.stop()
	_using_fallback = false
	_levels.clear()
	if _actor != null:
		_actor.set_speaking(false, -1.0)


func _process(delta: float) -> void:
	if _actor == null:
		return
	if _player.playing:
		var pos: float = _player.get_playback_position()
		var idx: int = int(pos * _fps)
		if idx >= 0 and idx < _levels.size():
			var a: float = float(_levels[idx])
			var b: float = float(_levels[mini(idx + 1, _levels.size() - 1)])
			var frac: float = fmod(pos * _fps, 1.0)
			_actor.set_speaking(true, lerpf(a, b, frac))
		else:
			_actor.set_speaking(true, -1.0)
	elif _using_fallback:
		_fallback_timer -= delta
		if _fallback_timer <= 0.0:
			_using_fallback = false
			_actor.set_speaking(false, -1.0)
			line_finished.emit(_active_id)


func _start_stream(stream: AudioStreamMP3, text: String) -> void:
	_using_fallback = false
	_player.stream = stream
	_player.play()
	if _actor != null:
		_actor.set_speaking(true, 0.0)
	line_started.emit(_active_id, text)


func _start_fallback_speaking(text: String, duration: float) -> void:
	_using_fallback = true
	_fallback_timer = duration
	if _actor != null:
		_actor.set_speaking(true, -1.0)
	line_started.emit(_active_id, text)


func _on_audio_finished() -> void:
	if _actor != null:
		_actor.set_speaking(false, -1.0)
	line_finished.emit(_active_id)


func _on_live_tts_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("ElevenLabs TTS hatası: result=%d, code=%d, yanit=%s" % [result, response_code, body.get_string_from_utf8()])
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		return
	var dict := parsed as Dictionary
	var b64: String = String(dict.get("audio_base64", ""))
	if b64 == "":
		return
	var mp3_bytes: PackedByteArray = Marshalls.base64_to_raw(b64)
	var cache_mp3: String = CACHE_DIR + _pending_live_hash + ".mp3"
	var cache_json: String = CACHE_DIR + _pending_live_hash + ".json"
	var f := FileAccess.open(cache_mp3, FileAccess.WRITE)
	if f != null:
		f.store_buffer(mp3_bytes)
		f.close()
	var track: Dictionary = _alignment_to_track(dict.get("alignment", {}))
	var jf := FileAccess.open(cache_json, FileAccess.WRITE)
	if jf != null:
		jf.store_string(JSON.stringify(track))
		jf.close()
	var stream := AudioStreamMP3.new()
	stream.data = mp3_bytes
	_levels = track.get("levels", [])
	_fps = float(track.get("fps", 50.0))
	_start_stream(stream, _pending_live_text)


func _alignment_to_track(alignment: Dictionary) -> Dictionary:
	var chars: Array = alignment.get("characters", [])
	var starts: Array = alignment.get("character_start_times_seconds", [])
	var ends: Array = alignment.get("character_end_times_seconds", [])
	if chars.is_empty() or starts.size() != chars.size() or ends.size() != chars.size():
		return {"fps": 50, "levels": []}
	var total_sec: float = float(ends[ends.size() - 1]) + 0.1
	var total_frames: int = maxi(int(total_sec * 50.0), 1)
	var out: Array = []
	out.resize(total_frames)
	out.fill(0.0)
	var vowels := "aAeEıIoOöÖuUüÜ"
	var closed := "bBmMpP"
	for i in chars.size():
		var ch: String = String(chars[i])
		var f0: int = clampi(int(float(starts[i]) * 50.0), 0, total_frames - 1)
		var f1: int = clampi(int(float(ends[i]) * 50.0) + 1, 0, total_frames)
		var v: float = 0.12 if closed.contains(ch) else (0.82 if vowels.contains(ch) else 0.42)
		if ch == " " or ch == "." or ch == "," or ch == "…":
			v = 0.0
		for k in range(f0, f1):
			out[k] = v
	return {"fps": 50, "levels": out}


func _load_mp3(path: String) -> AudioStreamMP3:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var stream := AudioStreamMP3.new()
	stream.data = bytes
	return stream


func _load_track_json(path: String) -> void:
	_levels.clear()
	_fps = 50.0
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_levels = (parsed as Dictionary).get("levels", [])
		_fps = float((parsed as Dictionary).get("fps", 50.0))


func _get_voice_id(philosopher_id: StringName) -> String:
	var v: Dictionary = _db.get("voices", {}).get(String(philosopher_id), {})
	return String(v.get("elevenlabs_voice_id", ""))


func _resolve_python() -> String:
	for candidate in ["/opt/anaconda3/bin/python3", "/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]:
		if FileAccess.file_exists(candidate):
			return candidate
	return "python3"


func _resolve_api_key() -> String:
	var env_key: String = OS.get_environment("ELEVEN_API_KEY")
	if env_key == "":
		env_key = OS.get_environment("ELEVENLABS_API_KEY")
	if env_key == "":
		env_key = OS.get_environment("XI_API_KEY")
	if env_key != "":
		return env_key.strip_edges()
	if FileAccess.file_exists(KEY_FILE):
		var f := FileAccess.open(KEY_FILE, FileAccess.READ)
		if f != null:
			return f.get_as_text().strip_edges()
	return ""


func _load_db() -> void:
	var f := FileAccess.open(LINES_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_db = parsed
