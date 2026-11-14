class_name HistoryActor
extends Node2D
## Archive artwork; colour, opacity and proportions stay independent of game state.

const CHAR_DATA := "res://stations/history/data/characters.json"

var philosopher_id: StringName = &"mete_han"
var memory_stage := 0
var anger := 0.0
var speaking := false
var mood: StringName = &"neutral"
var mouth_level := -1.0

var _body := Sprite2D.new()
var _body_size := Vector2.ONE
var _target_box := Vector2(440, 500)
var _all_meta: Dictionary = {}
var _exit_tween: Tween


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHAR_DATA))
	if parsed is Dictionary:
		_all_meta = parsed.get("figures", {})
	_body.centered = false
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_body)


func load_philosopher(id: StringName) -> bool:
	var meta: Dictionary = _all_meta.get(String(id), {})
	var path: String = meta.get("image", "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_body.texture = null
		push_warning("HistoryActor: missing archive image for %s" % id)
		return false
	philosopher_id = id
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()
	_body.texture = load(path) as Texture2D
	_body_size = _body.texture.get_size()
	_body.region_enabled = false
	# Reversible viewing crop; the museum photograph remains intact on disk.
	var region: Array = meta.get("view_region", [])
	if region.size() == 4:
		_body.region_enabled = true
		_body.region_rect = Rect2(region[0], region[1], region[2], region[3])
		_body_size = _body.region_rect.size
	modulate = Color.WHITE
	set_memory_stage(0, false)
	set_anger(0, false)
	_apply_scale()
	return true


func get_metadata() -> Dictionary:
	return _all_meta.get(String(philosopher_id), {})


func fit_to_box(box: Vector2) -> void:
	_target_box = box.max(Vector2.ONE)
	_apply_scale()


func fit_to_height(px: float) -> void:
	fit_to_box(Vector2(_target_box.x, px))


func get_height() -> float:
	return _body_size.y * scale.y


func _apply_scale() -> void:
	var ratio := minf(_target_box.x / _body_size.x, _target_box.y / _body_size.y)
	scale = Vector2.ONE * ratio
	_body.position = Vector2(-_body_size.x * 0.5, -_body_size.y)


func set_memory_stage(stage: int, _animate: bool = true) -> void:
	memory_stage = clampi(stage, 0, 4)


func set_anger(value: float, _animate: bool = true) -> void:
	anger = clampf(value, 0, 1)


func set_speaking(active: bool, level: float = -1.0) -> void:
	speaking = active
	mouth_level = level


func set_mood(next_mood: StringName) -> void:
	mood = next_mood


func play_reaction(_kind: StringName) -> void:
	pass # Historical artworks are not facial animation rigs.


func exit_angry(duration: float = 1.4) -> Tween:
	speaking = false
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()
	_exit_tween = create_tween()
	_exit_tween.tween_property(self, "modulate:a", 0.0, duration)
	return _exit_tween
