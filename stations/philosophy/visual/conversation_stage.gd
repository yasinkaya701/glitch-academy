class_name ConversationStage
extends Control
## Fikir Meydanı sahnesi — Edebi/sinematik ışıklandırma ve klasik serif tipografi.
## Yapay toz zerreleri ve çene bozan yüz yamaları kaldırıldı; doğal chiaroscuro ışık
## ve editoryal tipografi kullanıldı.

const MemoryRingScript = preload("res://stations/philosophy/visual/memory_ring.gd")
const ActorScript = preload("res://stations/philosophy/visual/philosopher_actor.gd")
const VoicePlayerScript = preload("res://stations/philosophy/visual/voice_player.gd")
const BACKDROP_SHADER = preload("res://stations/philosophy/visual/backdrop_fallback.gdshader")
const VIGNETTE_SHADER = preload("res://stations/philosophy/visual/vignette.gdshader")
const STAGE_DATA := "res://stations/philosophy/data/stage.json"
const BACKGROUND_DIR := "res://stations/philosophy/assets/backgrounds/"

const ACTOR_HEIGHT_RATIO := 0.92
const ACTOR_X_RATIO := 0.73
const FEET_Y_RATIO := 0.99
const MAX_LINE_LENGTH := 95
const ISLAMIC_IDS := [&"kindi", &"farabi", &"ibn_sina", &"ibn_rushd"]

var actor: PhilosopherActor
var ring: MemoryRing
var voice: VoicePlayer
var choice_slot: VBoxContainer

var _backdrop_rect := ColorRect.new()
var _backdrop_tex := TextureRect.new()
var _vignette := ColorRect.new()
var _floor_shadow := Control.new()
var _speaker_label := Label.new()
var _rule_line := ColorRect.new()
var _line_label := Label.new()
var _line_group := VBoxContainer.new()
var _line_tween: Tween
var _clock: float = 0.0
var _cam_zoom: float = 1.0
var _stage_data: Dictionary = {}
var _current_id: StringName = &"socrates"
const FONT_CINZEL := preload("res://fonts/Cinzel-Regular.ttf")
const FONT_CINZEL_BOLD := preload("res://fonts/CinzelDecorative-Bold.ttf")
const FONT_MARCELLUS := preload("res://fonts/Marcellus-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/Inter.ttf")

var _serif_font: Font = FONT_CINZEL
var _serif_italic: Font = FONT_MARCELLUS
var _sans_font: Font = FONT_BODY
var _compact := false
var _dialogue_width: float = 640.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_fonts()
	_load_stage_data()

	_backdrop_rect.material = _make_material(BACKDROP_SHADER)
	_backdrop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop_rect)

	_backdrop_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_tex.modulate = Color(1.03, 0.99, 0.95, 1.0)
	_backdrop_tex.visible = false
	add_child(_backdrop_tex)

	_floor_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_shadow.draw.connect(_draw_floor_shadow)
	add_child(_floor_shadow)

	ring = MemoryRingScript.new()
	ring.visible = false
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


func _init_fonts() -> void:
	_serif_font = FONT_CINZEL_BOLD
	_serif_italic = FONT_MARCELLUS
	_sans_font = FONT_BODY


func set_dialogue_layout(compact: bool, width: float) -> void:
	_compact = compact
	_dialogue_width = width
	var compact_size := 17 if size.y < 460.0 else 19
	_line_label.add_theme_font_size_override("font_size", compact_size if compact else 23)
	_speaker_label.add_theme_font_size_override("font_size", 19 if compact else 22)
	_line_label.max_lines_visible = (2 if size.y < 460.0 else 3) if compact else 4
	_layout()


func dialogue_line_bottom() -> float:
	return _line_group.position.y + _line_group.size.y


func show_philosopher(id: StringName, star_count: int = 4) -> bool:
	_current_id = id
	voice.stop()
	var ok: bool = actor.load_philosopher(id)
	_set_backdrop(id)
	ring.count = star_count
	ring.set_lit_count(0, false)
	ring.set_repaired(false, false)
	_set_vignette(0.0, 0.0)
	_cam_zoom = 1.0
	_layout()
	return ok


func show_line(speaker: String, text: String) -> void:
	if text.length() > MAX_LINE_LENGTH:
		push_warning("ConversationStage: altyazı %d karakteri aşıyor." % MAX_LINE_LENGTH)
	_speaker_label.text = speaker
	_line_label.text = "“" + text + "”"
	_line_label.visible_ratio = 0.22
	if _line_tween != null and _line_tween.is_valid():
		_line_tween.kill()
	_line_group.modulate.a = 0.0
	_line_group.visible = true
	_line_tween = create_tween().set_parallel(true)
	_line_tween.tween_property(_line_group, "modulate:a", 1.0, 0.20)
	_line_tween.tween_property(_line_label, "visible_ratio", 1.0, 0.42)


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
	var bmat := _backdrop_rect.material as ShaderMaterial
	if bmat != null:
		bmat.set_shader_parameter("repair_warmth", float(s) / 4.0)


func set_anger(value: float, animate: bool = true) -> void:
	var a: float = clampf(value, 0.0, 1.0)
	actor.set_anger(a, animate)
	_set_vignette(a, 1.0 if actor.memory_stage >= 4 else 0.0)


func _build_line_ui() -> void:
	_line_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_group.add_theme_constant_override("separation", 8)
	_line_group.clip_contents = true

	_speaker_label.add_theme_font_override("font", _serif_font)
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_color", Color("#d8b97a"))
	_speaker_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_speaker_label.add_theme_constant_override("shadow_offset_x", 0)
	_speaker_label.add_theme_constant_override("shadow_offset_y", 2)

	_rule_line.custom_minimum_size = Vector2(68, 1)
	_rule_line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_rule_line.color = Color(0.85, 0.72, 0.48, 0.55)

	_line_label.add_theme_font_override("font", _serif_italic)
	_line_label.add_theme_font_size_override("font_size", 23)
	_line_label.add_theme_color_override("font_color", Color("#f3eee2"))
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_line_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	_line_label.add_theme_constant_override("shadow_offset_x", 0)
	_line_label.add_theme_constant_override("shadow_offset_y", 2)

	_line_group.add_child(_speaker_label)
	_line_group.add_child(_rule_line)
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
	var actor_height := h * ACTOR_HEIGHT_RATIO
	if _compact:
		actor_height = minf(actor_height, w * 0.58)
	actor.fit_to_height(actor_height * _cam_zoom)

	var safe_left := minf(32.0, w * 0.045)
	var line_width := minf(w * 0.47, 760.0)
	var line_y := clampf(h * 0.40, 190.0, h * 0.48)
	var line_height := clampf(h * 0.20, 118.0, 210.0)
	if _compact:
		line_width = minf(maxf(w - safe_left * 2.0, 220.0), 560.0)
		line_y = clampf(h * 0.28, 112.0, 180.0)
		line_height = clampf(h * 0.20, 76.0, 142.0)
	_line_group.position = Vector2(safe_left, line_y)
	_line_group.size = Vector2(line_width, line_height)
	if choice_slot.size.x <= 0.0:
		choice_slot.position = Vector2(safe_left, h * 0.64)
		choice_slot.size = Vector2(_dialogue_width, minf(h * 0.22, 220.0))
	choice_slot.position.x = safe_left
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
	_floor_shadow.draw_colored_polygon(pts, Color(0, 0, 0, 0.45))


func _process(delta: float) -> void:
	_clock += delta
	var target_zoom: float = 1.045 if (actor != null and actor.speaking) else 1.0 + 0.008 * sin(_clock * 0.40)
	_cam_zoom = lerpf(_cam_zoom, target_zoom, 1.0 - exp(-delta * 2.6))
	if actor != null and size.y > 0.0:
		var actor_height := size.y * ACTOR_HEIGHT_RATIO
		if _compact:
			actor_height = minf(actor_height, size.x * 0.58)
		actor.fit_to_height(actor_height * _cam_zoom)

	if _backdrop_tex.visible:
		var z: float = 1.02 + 0.015 * (_cam_zoom - 1.0)
		_backdrop_tex.pivot_offset = _backdrop_tex.size * 0.5
		_backdrop_tex.scale = Vector2(z, z)
		_backdrop_tex.position = Vector2(sin(_clock * 0.12) * 5.0, 0.0)
		_backdrop_tex.size = size


func _set_backdrop(id: StringName) -> void:
	var bmat := _backdrop_rect.material as ShaderMaterial
	if bmat != null:
		bmat.set_shader_parameter("era_mode", 1.0 if ISLAMIC_IDS.has(id) else 0.0)
		bmat.set_shader_parameter("repair_warmth", 0.0)
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
