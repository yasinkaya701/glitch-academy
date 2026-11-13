extends "res://scripts/mission.gd"
## Shared playable shell for the subject-specific YKS micro-missions.

const Definition = preload("res://stations/yks/yks_mission_definition.gd")
const Visual = preload("res://stations/yks/stage_visual.tscn")

const INK := Color("#e8f1f2")
const MUTED := Color("#9db1bb")
const ACCENT := Color("#72dfc4")
const DANGER := Color("#ff9d79")
const PANEL := Color("#101c27")

class ReorderGlyph extends Control:
	var direction := -1

	func _draw() -> void:
		var center := size * 0.5
		var ink := Color("#e8f1f2")
		var tip := center + Vector2(0, 7 * direction)
		var stem_start := center - Vector2(0, 7 * direction)
		draw_line(stem_start, tip, ink, 2.0, true)
		draw_line(tip, tip + Vector2(-5, -5 * direction), ink, 2.0, true)
		draw_line(tip, tip + Vector2(5, -5 * direction), ink, 2.0, true)

@export var mission_definition: Definition
@export var mission_data_path := ""

var last_feedback := ""
var _completed := false
var _selection_buttons: Array[Button] = []
var _sequence_order: PackedStringArray = PackedStringArray()
var _sequence_up_buttons: Array[Button] = []
var _sequence_down_buttons: Array[Button] = []
var _pair_selection := ""
var _pair_answers: Dictionary = {}
var _pair_left_buttons: Dictionary = {}
var _feedback_label: Label
var _feedback_tween: Tween
var _answer_area: Control
var _visual: Control
var _verify_button: Button
var _interface_built := false


func _ready() -> void:
	if mission_definition == null and not mission_data_path.is_empty():
		mission_definition = load(mission_data_path) as Definition
	if mission_definition == null:
		push_error("YKS mini-görevi için mission_definition veya mission_data_path atanmalı.")
		return
	if not mission_definition.has_valid_answer_set():
		push_error("YKS mini-görev tanımı geçersiz: %s" % mission_definition.id)
		return
	call_deferred("_build_interface_after_layout")


func _build_interface_after_layout() -> void:
	if _interface_built:
		return
	if size.x <= 0.0 or size.y <= 0.0:
		await get_tree().process_frame
	if size.x <= 0.0 or size.y <= 0.0:
		push_error("YKS mini-görev sahnesi yerleşim almadan başlatıldı.")
		return
	_interface_built = true
	_build_interface()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#080e16"), true)
	draw_rect(Rect2(Vector2(18, 18), size - Vector2(36, 36)), Color("#0c1520"), true)
	var layout := _panel_layout()
	draw_line(Vector2(24, 54), Vector2(size.x - 24, 54), Color("#334651"), 1.0)
	for panel in [layout["left"], layout["right"]]:
		draw_rect(panel, PANEL, true)
		draw_rect(panel, Color("#344b58"), false, 1.0)
	draw_rect(Rect2(Vector2(18, size.y - 40), Vector2(size.x - 36, 1)), Color("#334651"), true)


func _panel_layout() -> Dictionary:
	var panel_top := 64.0
	var footer_line_y := size.y - 40.0
	var panel_height := maxf(180.0, footer_line_y - panel_top - 12.0)
	var panel_width := maxf(280.0, (size.x - 54.0) * 0.5)
	var left := Rect2(Vector2(18, panel_top), Vector2(panel_width, panel_height))
	var right := Rect2(Vector2(36.0 + panel_width, panel_top), Vector2(panel_width, panel_height))
	return {"left": left, "right": right}


func try_answer(answer: Variant) -> bool:
	if _completed or mission_definition == null:
		return false
	if answer != mission_definition.correct_answer():
		last_feedback = mission_definition.feedback_wrong
		_set_feedback(last_feedback, DANGER)
		if _visual != null and _visual.has_method("mark_result"):
			_visual.call("mark_result", false)
		return false
	_completed = true
	last_feedback = mission_definition.feedback_success
	_set_feedback(last_feedback, ACCENT)
	if _visual != null and _visual.has_method("mark_result"):
		_visual.call("mark_result", true)
	completed.emit()
	return true


func _build_interface() -> void:
	var layout := _panel_layout()
	var left_panel: Rect2 = layout["left"]
	var right_panel: Rect2 = layout["right"]
	var displayed_route := String(route) if not String(route).is_empty() else mission_definition.routes[0]
	var overline := _label("%s  ·  %s" % [mission_definition.subject.to_upper(), displayed_route.to_upper()], 13, ACCENT)
	overline.position = Vector2(26, 18)
	overline.size = Vector2(minf(740.0, size.x - 52.0), 22)
	add_child(overline)

	_visual = Visual.instantiate()
	_visual.diagram_id = mission_definition.visual_theme
	_visual.position = left_panel.position + Vector2(14, 14)
	_visual.size = left_panel.size - Vector2(28, 28)
	if mission_definition.id == &"tyt_biology":
		var campaign := get_node_or_null("/root/Campaign")
		if campaign != null and campaign.has_method("has_story_flag") and campaign.call("has_story_flag", &"life_protocol"):
			_visual.set("life_protocol", true)
	add_child(_visual)

	var prompt := _label(mission_definition.prompt, 18, INK)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.position = right_panel.position + Vector2(18, 14)
	prompt.size = Vector2(right_panel.size.x - 36.0, 145)
	add_child(prompt)
	var instruction := _label("KONTROL  ·  " + _interaction_hint(), 14, MUTED)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.position = right_panel.position + Vector2(18, 170)
	instruction.size = Vector2(right_panel.size.x - 36.0, 52)
	add_child(instruction)

	_answer_area = Control.new()
	_answer_area.position = right_panel.position + Vector2(14, 230)
	_answer_area.size = Vector2(right_panel.size.x - 28.0, right_panel.size.y - 244.0)
	_answer_area.clip_contents = true
	add_child(_answer_area)
	_build_interaction()
	_feedback_label = _label("", 15, MUTED)
	_feedback_label.hide()
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.position = right_panel.position + Vector2(18, right_panel.size.y - 36.0)
	_feedback_label.size = Vector2(right_panel.size.x - 36.0, 28)
	add_child(_feedback_label)


func _interaction_hint() -> String:
	match mission_definition.mode:
		"choice":
			return "En uygun yanıtı seç."
		"sequence":
			return "Öğeleri sırala, ardından doğrula."
		"pair":
			return "Soldan ve sağdan birer öğe eşleştir."
	return "Yanıtını seç ve doğrula."


func _build_interaction() -> void:
	match mission_definition.mode:
		"choice":
			_build_choice()
		"sequence":
			_build_sequence()
		"pair":
			_build_pairs()


func _build_choice() -> void:
	for index in mission_definition.options.size():
		var option := mission_definition.options[index]
		var button_width := _answer_area.size.x - 10.0
		var button := _button("%02d   %s" % [index + 1, option], Vector2(button_width, 45))
		button.position = Vector2(5, 4 + index * 53)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(try_answer.bind(option))
		_answer_area.add_child(button)
		_selection_buttons.append(button)


func _build_sequence() -> void:
	_sequence_order = mission_definition.sequence_items.duplicate()
	var row_width := _answer_area.size.x - 8.0
	var item_width := row_width - 160.0
	for index in _sequence_order.size():
		var row := Control.new()
		row.position = Vector2(2, 2 + index * 45)
		row.size = Vector2(row_width, 40)
		_answer_area.add_child(row)
		var item := _button("%02d  ·  %s" % [index + 1, _sequence_order[index]], Vector2(item_width, 38))
		item.position = Vector2.ZERO
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(item)
		var up := _button("", Vector2(72, 38))
		up.tooltip_text = "Önceki sıraya taşı"
		up.position = Vector2(item_width + 4.0, 0)
		var up_glyph := ReorderGlyph.new()
		up_glyph.direction = -1
		up_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		up_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		up_glyph.modulate = Color(1, 1, 1, 0.35) if index == 0 else Color.WHITE
		up.add_child(up_glyph)
		up.pressed.connect(_move_sequence.bind(index, -1))
		up.disabled = index == 0
		row.add_child(up)
		_sequence_up_buttons.append(up)
		var down := _button("", Vector2(72, 38))
		down.tooltip_text = "Sonraki sıraya taşı"
		down.position = Vector2(item_width + 82.0, 0)
		var down_glyph := ReorderGlyph.new()
		down_glyph.direction = 1
		down_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		down_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		down_glyph.modulate = Color(1, 1, 1, 0.35) if index == _sequence_order.size() - 1 else Color.WHITE
		down.add_child(down_glyph)
		down.pressed.connect(_move_sequence.bind(index, 1))
		down.disabled = index == _sequence_order.size() - 1
		row.add_child(down)
		_sequence_down_buttons.append(down)
		_selection_buttons.append(item)
	_verify_button = _button("Sıralamayı ölç", Vector2(180, 38))
	_verify_button.position = Vector2(4, _sequence_order.size() * 45 + 8)
	_verify_button.pressed.connect(func() -> void: try_answer(_sequence_order))
	_answer_area.add_child(_verify_button)


func _build_pairs() -> void:
	var column_gap := 16.0
	var column_width := (_answer_area.size.x - column_gap) * 0.5
	var left_title := _label("GÖZLEM", 12, ACCENT)
	left_title.position = Vector2(4, 0)
	left_title.size = Vector2(column_width, 22)
	_answer_area.add_child(left_title)
	var right_title := _label("KURAL", 12, ACCENT)
	right_title.position = Vector2(column_width + column_gap, 0)
	right_title.size = Vector2(column_width, 22)
	_answer_area.add_child(right_title)
	for index in mission_definition.pair_left.size():
		var y := 27 + index * 46
		var left := _button(mission_definition.pair_left[index], Vector2(column_width, 39))
		left.add_theme_font_size_override("font_size", 12)
		left.position = Vector2(0, y)
		left.pressed.connect(_choose_pair_left.bind(mission_definition.pair_left[index]))
		_pair_left_buttons[mission_definition.pair_left[index]] = left
		_answer_area.add_child(left)
		var right := _button(mission_definition.pair_right[index], Vector2(column_width, 39))
		right.add_theme_font_size_override("font_size", 12)
		right.position = Vector2(column_width + column_gap, y)
		right.pressed.connect(_choose_pair_right.bind(mission_definition.pair_right[index]))
		_answer_area.add_child(right)
		_selection_buttons.append(left)
		_selection_buttons.append(right)
	_verify_button = _button("Eşleşmeleri doğrula", Vector2(210, 38))
	_verify_button.position = Vector2(4, 27 + mission_definition.pair_left.size() * 46)
	_verify_button.pressed.connect(func() -> void: try_answer(_pair_answers))
	_verify_button.disabled = true
	_answer_area.add_child(_verify_button)


func _move_sequence(index: int, direction: int) -> void:
	var target := index + direction
	if target < 0 or target >= _sequence_order.size():
		return
	var item := _sequence_order[index]
	_sequence_order[index] = _sequence_order[target]
	_sequence_order[target] = item
	_refresh_sequence_labels()


func _refresh_sequence_labels() -> void:
	for index in _selection_buttons.size():
		_selection_buttons[index].text = "%02d  ·  %s" % [index + 1, _sequence_order[index]]
		_sequence_up_buttons[index].disabled = index == 0
		_sequence_down_buttons[index].disabled = index == _sequence_order.size() - 1
		_sequence_up_buttons[index].get_child(0).modulate = Color(1, 1, 1, 0.35) if index == 0 else Color.WHITE
		_sequence_down_buttons[index].get_child(0).modulate = Color(1, 1, 1, 0.35) if index == _sequence_order.size() - 1 else Color.WHITE


func _choose_pair_left(value: String) -> void:
	for button in _pair_left_buttons.values():
		(button as Button).add_theme_color_override("font_color", INK)
	_pair_selection = value
	(_pair_left_buttons[value] as Button).add_theme_color_override("font_color", ACCENT)
	_set_feedback("Şimdi bu gözleme uyan kuralı seç.", ACCENT)


func _choose_pair_right(value: String) -> void:
	if _pair_selection.is_empty():
		_set_feedback("Önce soldaki gözlemlerden birini seç.", DANGER)
		return
	_pair_answers[_pair_selection] = value
	(_pair_left_buttons[_pair_selection] as Button).add_theme_color_override("font_color", INK)
	_pair_selection = ""
	_verify_button.disabled = _pair_answers.size() != mission_definition.pair_left.size()
	var progress_text := "%d / %d eşleşme kuruldu." % [_pair_answers.size(), mission_definition.pair_left.size()]
	_set_feedback(progress_text, ACCENT)


func _set_feedback(message: String, color: Color) -> void:
	if _feedback_label == null:
		return
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_label.text = message
	_feedback_label.add_theme_color_override("font_color", color)
	if message.is_empty():
		_feedback_label.hide()
		return
	_feedback_label.modulate.a = 0.0
	_feedback_label.show()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.12)
	_feedback_tween.tween_interval(3.0)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.28)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text_value: String, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = text_value
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.custom_minimum_size = button_size
	button.size = button_size
	button.add_theme_font_size_override("font_size", 14)
	return button
