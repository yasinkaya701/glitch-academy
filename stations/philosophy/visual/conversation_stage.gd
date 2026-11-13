class_name ConversationStage
extends Control
## Fikir Meydanı sahnesi (docs/UX.md uyumlu: yazı paneli veya etiket yığını yok).
## Filozof sağ-ortada ayakta durur, başının arkasında fikir yıldızları (MemoryRing) parlar,
## konuşma cümlesi kutusuz/panelsiz doğrudan sahnede belirir, ses 50 Hz dudak senkronuyla (VoicePlayer) çalar.

const MemoryRingScript = preload("res://stations/philosophy/visual/memory_ring.gd")
const ActorScript = preload("res://stations/philosophy/visual/philosopher_actor.gd")
const VoicePlayerScript = preload("res://stations/philosophy/visual/voice_player.gd")
const BACKDROP_SHADER = preload("res://stations/philosophy/visual/backdrop_fallback.gdshader")
const VIGNETTE_SHADER = preload("res://stations/philosophy/visual/vignette.gdshader")
const STAGE_DATA := "res://stations/philosophy/data/stage.json"
const BACKGROUND_DIR := "res://stations/philosophy/assets/backgrounds/"

const ACTOR_HEIGHT_RATIO := 0.86
const ACTOR_X_RATIO := 0.64
const FEET_Y_RATIO := 0.91
const MAX_LINE_LENGTH := 95

var actor: PhilosopherActor
var ring: MemoryRing
var voice: VoicePlayer
var choice_slot: VBoxContainer

var _backdrop_rect := ColorRect.new()
var _backdrop_tex := TextureRect.new()
var _vignette := ColorRect.new()
var _floor_shadow := Control.new()
var _speaker_label := Label.new()
var _line_label := Label.new()
var _line_group := VBoxContainer.new()
var _line_tween: Tween
var _clock: float = 0.0
var _stage_data: Dictionary = {}
var _current_id: StringName = &"socrates"


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_stage_data()

	_backdrop_rect.material = _make_material(BACKDROP_SHADER)
	_backdrop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop_rect)

	_backdrop_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_tex.visible = false
	add_child(_backdrop_tex)

	_floor_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_shadow.draw.connect(_draw_floor_shadow)
	add_child(_floor_shadow)

	ring = MemoryRingScript.new()
	add_child(ring)

	actor = ActorScript.new()
	add_child(actor)

	var vmat := _make_material(VIGNETTE_SHADER)
	vmat.set_shader_parameter("anger", 0.0)
	vmat.set_shader_parameter("repaired", 0.0)
	_vignette.material = vmat
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	voice = VoicePlayerScript.new()
	add_child(voice)
	voice.bind_actor(actor)

	_build_line_ui()
	resized.connect(_layout)
	_layout()


func show_philosopher(id: StringName, star_count: int = 4) -> bool:
	_current_id = id
	voice.stop()
	var ok: bool = actor.load_philosopher(id)
	_set_backdrop(id)
	ring.count = star_count
	ring.set_lit_count(0, false)
	ring.set_repaired(false, false)
	_set_vignette(0.0, 0.0)
	_layout()
	return ok


func show_line(speaker: String, text: String) -> void:
	if text.length() > MAX_LINE_LENGTH:
		push_warning("ConversationStage: altyazı %d karakteri aşıyor." % MAX_LINE_LENGTH)
	_speaker_label.text = speaker
	_line_label.text = "“" + text + "”"
	if _line_tween != null and _line_tween.is_valid():
		_line_tween.kill()
	_line_group.modulate.a = 0.0
	_line_group.visible = true
	_line_tween = create_tween()
	_line_tween.tween_property(_line_group, "modulate:a", 1.0, 0.22)


func speak_line(speaker: String, line_id: StringName) -> void:
	var text: String = voice.play_line(_current_id, line_id)
	if text != "":
		show_line(speaker, text)


func hide_line() -> void:
	if _line_tween != null and _line_tween.is_valid():
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_property(_line_group, "modulate:a", 0.0, 0.22)
	_line_tween.tween_callback(func() -> void: _line_group.visible = false)


func set_memory_stage(stage: int, animate: bool = true) -> void:
	var s: int = clampi(stage, 0, 4)
	actor.set_memory_stage(s, animate)
	ring.set_lit_count(s * ring.count / 4, animate)
	ring.set_repaired(s >= 4, animate)
	_set_vignette(actor.anger, 1.0 if s >= 4 else 0.0)


func set_anger(value: float, animate: bool = true) -> void:
	var a: float = clampf(value, 0.0, 1.0)
	actor.set_anger(a, animate)
	_set_vignette(a, 1.0 if actor.memory_stage >= 4 else 0.0)


func _build_line_ui() -> void:
	_line_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_group.add_theme_constant_override("separation", 4)
	_speaker_label.theme_type_variation = &"SectionLabel"
	_line_label.add_theme_font_size_override("font_size", 22)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	_line_label.add_theme_constant_override("shadow_offset_x", 0)
	_line_label.add_theme_constant_override("shadow_offset_y", 2)
	_line_group.add_child(_speaker_label)
	_line_group.add_child(_line_label)
	_line_group.visible = false
	add_child(_line_group)

	choice_slot = VBoxContainer.new()
	choice_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	choice_slot.add_theme_constant_override("separation", 8)
	add_child(choice_slot)


func _layout() -> void:
	if actor == null:
		return
	var w: float = size.x
	var h: float = size.y
	_backdrop_rect.position = Vector2.ZERO
	_backdrop_rect.size = size
	_vignette.position = Vector2.ZERO
	_vignette.size = size
	_floor_shadow.position = Vector2.ZERO
	_floor_shadow.size = size
	var feet := Vector2(w * ACTOR_X_RATIO, h * FEET_Y_RATIO)
	actor.position = feet
	actor.fit_to_height(h * ACTOR_HEIGHT_RATIO)
	ring.position = feet + actor.head_offset() + Vector2(0.0, h * 0.19)
	ring.radius = h * 0.36
	_line_group.position = Vector2(28.0, h * 0.52)
	_line_group.size = Vector2(w * 0.44, h * 0.18)
	choice_slot.position = Vector2(28.0, h * 0.68)
	choice_slot.size = Vector2(w * 0.44, h * 0.16)
	_floor_shadow.queue_redraw()


func _draw_floor_shadow() -> void:
	if actor == null:
		return
	var feet: Vector2 = actor.position
	var rx: float = actor.get_height() * 0.22
	var pts := PackedVector2Array()
	for i in 40:
		var a: float = TAU * float(i) / 40.0
		pts.append(feet + Vector2(cos(a) * rx, sin(a) * rx * 0.13))
	_floor_shadow.draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
	var pts2 := PackedVector2Array()
	for i in 40:
		var a2: float = TAU * float(i) / 40.0
		pts2.append(feet + Vector2(cos(a2) * rx * 1.5, sin(a2) * rx * 1.5 * 0.13))
	_floor_shadow.draw_colored_polygon(pts2, Color(0, 0, 0, 0.22))


func _process(delta: float) -> void:
	_clock += delta
	if _backdrop_tex.visible:
		var z: float = 1.04 + 0.012 * sin(_clock * 0.18)
		_backdrop_tex.pivot_offset = _backdrop_tex.size * 0.5
		_backdrop_tex.scale = Vector2(z, z)
		_backdrop_tex.position = Vector2(sin(_clock * 0.11) * 10.0, 0.0)
		_backdrop_tex.size = size


func _set_backdrop(id: StringName) -> void:
	var bg_name: String = String(_stage_data.get(String(id), ""))
	var path: String = BACKGROUND_DIR + bg_name + ".png"
	if bg_name != "" and ResourceLoader.exists(path):
		_backdrop_tex.texture = load(path) as Texture2D
		_backdrop_tex.visible = _backdrop_tex.texture != null
	else:
		_backdrop_tex.texture = null
		_backdrop_tex.visible = false
	_backdrop_rect.visible = not _backdrop_tex.visible


func _set_vignette(anger: float, repaired: float) -> void:
	var mat := _vignette.material as ShaderMaterial
	var from_a: float = float(mat.get_shader_parameter("anger"))
	var from_r: float = float(mat.get_shader_parameter("repaired"))
	create_tween().set_parallel(true)\
		.tween_method(func(v: float) -> void: mat.set_shader_parameter("anger", v), from_a, anger, 0.5)
	create_tween().tween_method(func(v: float) -> void: mat.set_shader_parameter("repaired", v), from_r, repaired, 1.2)


func _make_material(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


func _load_stage_data() -> void:
	var f := FileAccess.open(STAGE_DATA, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_stage_data = parsed
