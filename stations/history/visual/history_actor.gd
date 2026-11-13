class_name HistoryActor
extends Node2D
## Tarihî şahsiyet sahne aktörü.
## Doğal yağlıboya portre tablosu ve nefes mikro-hareketi.

const CHAR_DIR := "res://stations/history/assets/characters/"
const CHAR_DATA := "res://stations/history/data/characters.json"
const CHIAROSCURO_SHADER := preload("res://stations/history/visual/chiaroscuro.gdshader")

const BREATH_SPEED := 1.35

var philosopher_id: StringName = &"socrates"
var memory_stage: int = 0
var anger: float = 0.0
var speaking: bool = false
var mood: StringName = &"neutral"
var mouth_level: float = -1.0

var _rig := Node2D.new()
var _body := Sprite2D.new()

var _body_size := Vector2(896, 1280)
var _base_scale: float = 1.0
var _target_height: float = 640.0
var _clock: float = 0.0
var _speak_energy: float = 0.0
var _tween: Tween
var _all_meta: Dictionary = {}


func _ready() -> void:
	_load_manifest()
	add_child(_rig)
	_body.centered = false
	var mat := ShaderMaterial.new()
	mat.shader = CHIAROSCURO_SHADER
	_body.material = mat
	_rig.add_child(_body)


func load_philosopher(id: StringName) -> bool:
	philosopher_id = id
	var meta: Dictionary = _all_meta.get(String(id), {})
	var base_dir: String = CHAR_DIR + String(id) + "/"
	var body_path: String = base_dir + "body.png"
	if meta.is_empty() or not ResourceLoader.exists(body_path):
		push_warning("PhilosopherActor: '%s' için varlık bulunamadı." % id)
		return false

	_body.texture = load(body_path) as Texture2D
	var bs: Array = meta.get("body_size", [896, 1280])
	_body_size = Vector2(float(bs[0]), float(bs[1]))

	_rig.position = Vector2(-_body_size.x * 0.5, -_body_size.y)
	_apply_scale()
	set_memory_stage(0, false)
	set_anger(0.0, false)
	return true


func fit_to_height(px: float) -> void:
	_target_height = px
	_apply_scale()


func get_height() -> float:
	return _target_height


func set_memory_stage(stage: int, animate: bool = true) -> void:
	var prev: int = memory_stage
	memory_stage = clampi(stage, 0, 4)
	# Doğal müze/tablo ışığı: çamurumsu mavi ton yerine sıcak, temiz chiaroscuro aydınlatma
	var tint := Color(0.96, 0.95, 0.93).lerp(Color(1.03, 1.01, 0.98), float(memory_stage) / 4.0)
	if animate:
		create_tween().tween_property(_rig, "modulate", tint, 0.45)
		if memory_stage > prev:
			play_reaction(&"recalled" if memory_stage >= 4 else &"stir")
	else:
		_rig.modulate = tint


func set_anger(value: float, animate: bool = true) -> void:
	anger = clampf(value, 0.0, 1.0)
	var base_tint := Color(0.96, 0.95, 0.93).lerp(Color(1.03, 1.01, 0.98), float(memory_stage) / 4.0)
	var tint := base_tint.lerp(Color(1.04, 0.90, 0.86), anger * 0.45)
	if animate:
		create_tween().tween_property(_rig, "modulate", tint, 0.25)
	else:
		_rig.modulate = tint


func set_speaking(active: bool, level: float = -1.0) -> void:
	speaking = active
	mouth_level = level


func set_mood(next_mood: StringName) -> void:
	mood = next_mood


func play_reaction(kind: StringName) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var base_pos := Vector2(-_body_size.x * 0.5, -_body_size.y)
	match kind:
		&"stir", &"glimmer", &"dawn":
			_tween.tween_property(_rig, "position:y", base_pos.y - 6.0, 0.18).set_trans(Tween.TRANS_SINE)
			_tween.tween_property(_rig, "position:y", base_pos.y, 0.26).set_trans(Tween.TRANS_SINE)
		&"recalled":
			_tween.tween_property(_rig, "position:y", base_pos.y - 10.0, 0.22).set_trans(Tween.TRANS_BACK)
			_tween.tween_property(_rig, "position:y", base_pos.y, 0.32).set_trans(Tween.TRANS_SINE)
		&"refuse":
			_tween.tween_property(_rig, "position:x", base_pos.x - 8.0, 0.08)
			_tween.tween_property(_rig, "position:x", base_pos.x + 8.0, 0.08)
			_tween.tween_property(_rig, "position:x", base_pos.x, 0.10)


func exit_angry(duration: float = 1.4) -> Tween:
	speaking = false
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position:x", position.x + 420.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, duration * 0.85)
	return t


func _process(delta: float) -> void:
	_clock += delta
	var target_e: float = 0.0
	if speaking:
		target_e = clampf(mouth_level, 0.15, 1.0) if mouth_level >= 0.0 else (0.35 + 0.25 * absf(sin(_clock * 6.5)))
	_speak_energy = lerpf(_speak_energy, target_e, 1.0 - exp(-delta * 10.0))

	var breath: float = sin(_clock * BREATH_SPEED) * 1.8
	var talk_lift: float = -_speak_energy * 3.2
	_rig.position = Vector2(-_body_size.x * 0.5, -_body_size.y + breath + talk_lift)
	_rig.rotation = sin(_clock * 0.7) * 0.0025


func _apply_scale() -> void:
	_base_scale = _target_height / maxf(_body_size.y, 1.0)
	scale = Vector2(_base_scale, _base_scale)


func _load_manifest() -> void:
	if not FileAccess.file_exists(CHAR_DATA):
		return
	var f := FileAccess.open(CHAR_DATA, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		var d := parsed as Dictionary
		if d.has("philosophers"):
			_all_meta = d.get("philosophers", {})
		elif d.has("figures"):
			_all_meta = d.get("figures", {})
		else:
			_all_meta = d
