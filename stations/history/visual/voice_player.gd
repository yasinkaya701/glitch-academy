class_name HistoryVoicePlayer
extends Node
## Ses oynatıcısı (Gemini TTS) ve mikrofonla konuşma (Gemini STT) sürücüsü. Tüm replikler Narrator üzerinden canlı üretilir,
## user://voice_cache/ içinde saklanır; Python ya da dış program gerekmez, build'de de çalışır. Anahtar yoksa ağız hareketi ve yazı kalır.

signal line_started(line_id: StringName, text: String)
signal line_finished(line_id: StringName)
signal speech_recognized(ok: bool, text: String)

const LINES_PATH := "res://stations/history/data/lines.json"

var _player := AudioStreamPlayer.new()
var _actor: Node2D
var _active_id: StringName = &""
var _levels: Array = []
var _fps: float = 50.0
var _fallback_timer: float = 0.0
var _using_fallback: bool = false
var _db: Dictionary = {}
var _listening: bool = false
var _warmed: Dictionary = {}


func _ready() -> void:
	_player.bus = "Voice"
	add_child(_player)
	_player.finished.connect(_on_audio_finished)
	_load_db()


func bind_actor(actor: Node2D) -> void:
	_actor = actor


func get_line_text(figure_id: StringName, line_id: StringName) -> String:
	if _db.is_empty():
		_load_db()
	var p: Dictionary = _db.get("figures", {}).get(String(figure_id), {})
	return String(p.get("lines", {}).get(String(line_id), ""))


func get_lines(figure_id: StringName) -> Dictionary:
	if _db.is_empty():
		_load_db()
	var p: Dictionary = _db.get("figures", {}).get(String(figure_id), {})
	return p.get("lines", {})


func get_choices(figure_id: StringName) -> Array:
	if _db.is_empty():
		_load_db()
	var p: Dictionary = _db.get("figures", {}).get(String(figure_id), {})
	return p.get("choices", [])


## Hazır metin satırını Gemini sesiyle çalar ve metnini döndürür.
func play_line(philosopher_id: StringName, line_id: StringName) -> String:
	stop()
	var text: String = get_line_text(philosopher_id, line_id)
	_active_id = line_id
	_prewarm(philosopher_id)
	if text != "":
		speak_live(philosopher_id, text, line_id)
	return text


func is_listening() -> bool:
	return _listening


## Kişinin aşama repliklerini arka planda önceden seslendirir; sıra geldiğinde ses beklemeden çalar.
func _prewarm(philosopher_id: StringName) -> void:
	if _warmed.has(philosopher_id) or not Narrator.available():
		return
	_warmed[philosopher_id] = true
	var texts: Array = []
	var lines: Dictionary = get_lines(philosopher_id)
	for key in lines:
		if String(key).begins_with("stage_"):
			texts.append(String(lines[key]))
	Narrator.prefetch(texts, philosopher_id)


## Serbest metni Gemini TTS ile seslendirir (anahtar yoksa yalnızca ağız hareketi ve yazı).
func speak_live(philosopher_id: StringName, text: String, tag_id: StringName = &"live") -> void:
	stop()
	_active_id = tag_id
	if Narrator.available():
		_speak_gemini(philosopher_id, text, tag_id)
		return
	_start_fallback_speaking(text, clampf(float(text.length()) * 0.065, 1.8, 7.0))


## Gemini TTS: ses gelene kadar ağız prosedürel hareket eder, gelince sesle çalar.
func _speak_gemini(philosopher_id: StringName, text: String, tag_id: StringName) -> void:
	_start_fallback_speaking(text, 14.0)
	var stream: AudioStreamWAV = await Narrator.synthesize(text, philosopher_id)
	if _active_id != tag_id or not is_inside_tree():
		return
	_using_fallback = false
	if stream == null:
		_start_fallback_speaking(text, clampf(float(text.length()) * 0.065, 1.8, 7.0))
		return
	_levels = []
	_player.stream = stream
	_player.play()
	if _actor != null:
		_actor.set_speaking(true, -1.0)


## Mikrofondan oyuncunun sesini dinleyip Türkçe metne çevirir (Gemini) ve speech_recognized sinyali yayar.
func listen_microphone(seconds: float = 4.2) -> bool:
	if not Narrator.available():
		speech_recognized.emit(false, "")
		return false
	if _listening:
		return false
	_listening = true
	_listen_async(seconds)
	return true


func _listen_async(seconds: float) -> void:
	var recognized: String = await Narrator.listen(seconds)
	_listening = false
	speech_recognized.emit(recognized != "", recognized)


func stop() -> void:
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


func _load_db() -> void:
	var f := FileAccess.open(LINES_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_db = parsed
