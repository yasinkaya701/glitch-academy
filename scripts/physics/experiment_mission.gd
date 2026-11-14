extends "res://scripts/mission.gd"
## Fizik deneyleri için ortak görev iskeleti: sahne (Control), HUD, güç şeridi, sayı girişi, geri ve mühür.
## Alt sınıf `_make_stage()` ile sahneyi verir, `_begin()` ile akışı başlatır, `_on_action()` ile eylem düğmesini işler.
## Hikâye kuralı: docs/STORY.md. Her görev kayma → deney → uygulama → mühür sırasını izler.

const Hud = preload("res://scripts/mission_hud.gd")
const GOOD: Color = UITheme.GOOD
const BAD: Color = UITheme.DANGER
const MUTED: Color = UITheme.MUTED

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
	if is_instance_valid(_diagnosis_panel):
		remove_child(_diagnosis_panel)
		_diagnosis_panel.queue_free()
		_diagnosis_panel = null
	for child in tools.get_children():
		tools.remove_child(child)
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
	var value := text.to_float() if text.is_valid_float() else NAN
	return value if is_finite(value) else NAN


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

## Ayar plakasına kanıt taşıma. Düğmeler sürüklemenin klavye karşılığıdır.
class EvidenceSlip extends Button:
	var record_index := -1
	func _get_drag_data(_position: Vector2) -> Variant:
		var preview := Label.new()
		preview.text = text
		set_drag_preview(preview)
		return {"experiment_record": record_index}

class SettingTarget extends PanelContainer:
	signal record_dropped(index: int)
	func _can_drop_data(_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("experiment_record")
	func _drop_data(_position: Vector2, data: Variant) -> void:
		record_dropped.emit(int(data.experiment_record))

var evidence_verified := false
var _diagnosis_panel: PanelContainer
var _diagnosis_records: Array[String] = []
var _diagnosis_attached: Array[int] = []
var _diagnosis_valid_key: StringName
var _diagnosis_handler: Callable
var _diagnosis_selected := -1

func show_evidence_diagnosis(records: Array[String], settings: Dictionary, valid_key: StringName, handler: Callable) -> void:
	evidence_verified = false
	_diagnosis_records = records.duplicate()
	_diagnosis_attached.clear()
	_diagnosis_valid_key = valid_key
	_diagnosis_handler = handler
	_diagnosis_selected = -1
	_diagnosis_panel = PanelContainer.new()
	_diagnosis_panel.theme_type_variation = "ConsolePanel"
	_diagnosis_panel.position = Vector2((size.x - 700.0) * 0.5, 130)
	_diagnosis_panel.size = Vector2(700, 0)
	add_child(_diagnosis_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_diagnosis_panel.add_child(column)
	var hint := Label.new()
	hint.text = "Fişi seç, çeliştiği ayara uygula; ya da sürükleyip bırak."
	column.add_child(hint)
	for index in records.size():
		var slip := EvidenceSlip.new()
		slip.record_index = index
		slip.text = records[index]
		slip.custom_minimum_size.y = 44
		slip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slip.pressed.connect(func() -> void:
			_diagnosis_selected = index
			say("Kayıt %d seçildi; çeliştiği ayara uygula." % (index + 1)))
		column.add_child(slip)
	for key in settings:
		var target := SettingTarget.new()
		target.record_dropped.connect(apply_diagnosis_record.bind(key))
		var button := Button.new()
		button.text = settings[key]
		button.custom_minimum_size.y = 44
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func() -> void: apply_diagnosis_record(_diagnosis_selected, key))
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		target.add_child(button)
		column.add_child(target)

func apply_diagnosis_record(index: int, key: StringName) -> void:
	if index < 0 or index >= _diagnosis_records.size() or evidence_verified:
		return
	if key != _diagnosis_valid_key:
		_diagnosis_handler.call(key)
		return
	if not _diagnosis_attached.has(index):
		_diagnosis_attached.append(index)
	if _diagnosis_attached.size() == _diagnosis_records.size():
		evidence_verified = true
		_diagnosis_handler.call(key)
	else:
		say("Bir kayıt bağlandı; ikinci ölçümü de karşılaştır.")
