extends "res://scripts/mission.gd"
## Fizik deneyleri için ortak görev iskeleti: sahne (Control), HUD, güç şeridi, sayı girişi, geri ve mühür.
## Alt sınıf `_make_stage()` ile sahneyi verir, `_begin()` ile akışı başlatır, `_on_action()` ile eylem düğmesini işler.
## Hikâye kuralı: docs/STORY.md. Her görev kayma → deney → uygulama → mühür sırasını izler.

const Hud = preload("res://scripts/mission_hud.gd")
const GOOD := Color("#a0dfbc")
const BAD := Color("#ffb093")
const MUTED := Color("#b0c4bf")

var stage: Control
var hud: Hud
var tools: HBoxContainer
var entry: LineEdit
var step_total := 5
var _sealed := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = _make_stage()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action)
	hud.skip_pressed.connect(_on_skip)
	hud.back_pressed.connect(go_back)
	tools = hud.tools
	_begin()


## Alt sınıflar geçersiz kılar.
func _make_stage() -> Control:
	return Control.new()


func _begin() -> void:
	pass


func _on_action() -> void:
	pass


func _on_skip() -> void:
	pass


func go_back() -> void:
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/control_center.tscn")
	else:
		exit_requested.emit()


func clear_tools() -> void:
	for child in tools.get_children():
		child.queue_free()
	entry = null


func screen(index: int, label: String, directive: String, action_text: String = "", note: String = "") -> void:
	hud.set_steps(index, step_total, label)
	hud.set_directive(directive)
	hud.set_note(note)
	hud.set_action(action_text, action_text != "")
	hud.skip.hide()
	clear_tools()


func say(text: String, color: Color = MUTED) -> void:
	var tone: StringName = &"neutral"
	if color == GOOD:
		tone = &"good"
		Sfx.play(&"click", -12.0)
	elif color == BAD:
		tone = &"bad"
		Sfx.play(&"buzz", -14.0)
	hud.say(text, tone)


func add_entry(placeholder: String) -> LineEdit:
	entry = LineEdit.new()
	entry.placeholder_text = placeholder
	entry.custom_minimum_size = Vector2(190, 0)
	entry.text_submitted.connect(func(_text: String) -> void: _on_action())
	tools.add_child(entry)
	entry.grab_focus()
	return entry


func read_number() -> float:
	if entry == null or entry.text.strip_edges() == "":
		return NAN
	var text := entry.text.strip_edges().replace(",", ".")
	return text.to_float() if text.is_valid_float() else NAN


func add_power(title: String, hint: String, callback: Callable, toggle: bool = false) -> Button:
	var button := Button.new()
	button.text = title
	button.tooltip_text = hint
	button.toggle_mode = toggle
	if toggle:
		button.toggled.connect(callback)
	else:
		button.pressed.connect(callback)
	tools.add_child(button)
	return button


func add_slider(title: String, low: float, high: float, value: float, step: float, on_change: Callable, width: float = 240.0) -> HSlider:
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", MUTED)
	tools.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(width, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	tools.add_child(slider)
	return slider


func add_gap(width: float = 18.0) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(width, 0)
	tools.add_child(gap)


## Mühür: yasa mühürlenir, kayıt satırı yazılır, görev tamamlanır.
func seal(record: String, directive: String) -> void:
	if _sealed:
		return
	_sealed = true
	screen(step_total, "MÜHÜR", directive, "", "Kayıt: %s" % record)
	hud.set_steps(step_total, step_total, "MÜHÜR")
	say("Mühürlendi. " + record, GOOD)
	Sfx.play(&"chime")
	completed.emit()
