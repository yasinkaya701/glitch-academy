extends "res://scripts/mission.gd"
## Shared playable shell for the subject-specific YKS micro-missions.

const Definition = preload("res://stations/yks/yks_mission_definition.gd")
const Visual = preload("res://stations/yks/stage_visual.tscn")

const INK := Color("#e8f1f2")
const MUTED := Color("#9db1bb")
const ACCENT := Color("#72dfc4")
const DANGER := Color("#ff9d79")
const PANEL := Color("#101c27")

@export var mission_definition: Definition
@export var mission_data_path := ""

var last_feedback := ""
var _completed := false
var _selection_buttons: Array[Button] = []
var _sequence_order: PackedStringArray = PackedStringArray()
var _choice_order: PackedStringArray = PackedStringArray()
var _sequence_up_buttons: Array[Button] = []
var _sequence_down_buttons: Array[Button] = []
var _selected_choice := ""
var _pair_answers: Dictionary = {}
var _pair_right_order: PackedStringArray = PackedStringArray()
var _pair_selectors: Dictionary = {}
var _feedback_label: Label
var _feedback_tween: Tween
var _evidence_label: Label
var _prompt_label: Label
var _instruction_label: Label
var _answer_scroll: ScrollContainer
var _answer_area: Control
var _visual: Control
var _verify_button: Button
var _info_button: Button
var _info_dialog: AcceptDialog
var _last_layout_size := Vector2.ZERO
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


func _panel_layout() -> Dictionary:
	var panel_top := 56.0
	var panel_height := maxf(180.0, size.y - panel_top - 18.0)
	var gap := 14.0
	var available_width := maxf(160.0, size.x - 36.0 - gap)
	var left_width := available_width * 0.5
	var right_width := available_width - left_width
	var left := Rect2(Vector2(18, panel_top), Vector2(left_width, panel_height))
	var right := Rect2(Vector2(18.0 + left_width + gap, panel_top), Vector2(right_width, panel_height))
	return {"left": left, "right": right}


func try_answer(answer: Variant) -> bool:
	if _completed or mission_definition == null:
		return false
	if answer != mission_definition.correct_answer():
		last_feedback = mission_definition.feedback_wrong
		_set_feedback("↻  " + last_feedback, DANGER)
		if _visual != null and _visual.has_method("mark_result"):
			_visual.call("mark_result", false)
		return false
	_completed = true
	last_feedback = mission_definition.feedback_success
	_set_feedback("✓  " + last_feedback, ACCENT)
	_lock_interaction()
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
	overline.size = Vector2(minf(740.0, size.x - 92.0), 22)
	add_child(overline)
	_info_button = Button.new()
	_info_button.text = "ⓘ"
	_info_button.tooltip_text = "Kazanım ve kaynak"
	_info_button.custom_minimum_size = Vector2(40, 36)
	_info_button.position = Vector2(size.x - 58.0, 10)
	_info_button.size = Vector2(40, 36)
	_info_button.pressed.connect(_show_learning_note)
	add_child(_info_button)

	_visual = Visual.instantiate()
	_visual.diagram_id = mission_definition.visual_theme
	_visual.position = left_panel.position + Vector2(14, 14)
	_visual.size = left_panel.size - Vector2(28, 28)
	if mission_definition.id == &"tyt_biology":
		var campaign := get_node_or_null("/root/Campaign")
		if campaign != null and campaign.has_method("has_story_flag") and campaign.call("has_story_flag", &"life_protocol"):
			_visual.set("life_protocol", true)
	add_child(_visual)

	_evidence_label = _label("KAYIT", 11, ACCENT)
	_evidence_label.position = right_panel.position + Vector2(18, 14)
	_evidence_label.size = Vector2(right_panel.size.x - 36.0, 18)
	add_child(_evidence_label)
	_prompt_label = _label(mission_definition.prompt, 17, INK)
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.position = right_panel.position + Vector2(18, 36)
	_prompt_label.size = Vector2(right_panel.size.x - 36.0, 102)
	add_child(_prompt_label)
	_instruction_label = _label(mission_definition.instruction, 16, INK)
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.position = right_panel.position + Vector2(18, 145)
	_instruction_label.size = Vector2(right_panel.size.x - 36.0, 58)
	add_child(_instruction_label)

	_answer_scroll = ScrollContainer.new()
	_answer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_answer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_answer_scroll)
	_answer_area = Control.new()
	_answer_scroll.add_child(_answer_area)
	_feedback_label = _label("", 15, MUTED)
	_feedback_label.hide()
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_feedback_label)
	_last_layout_size = size
	resized.connect(_on_resized)
	_layout_interface()
	_build_interaction()


func _on_resized() -> void:
	if not _interface_built or size.distance_to(_last_layout_size) < 1.0:
		return
	_last_layout_size = size
	_layout_interface()
	_rebuild_interaction()


func _layout_interface() -> void:
	var layout := _panel_layout()
	var left_panel: Rect2 = layout["left"]
	var right_panel: Rect2 = layout["right"]
	_visual.position = left_panel.position + Vector2(14, 14)
	_visual.size = left_panel.size - Vector2(28, 28)
	_evidence_label.position = right_panel.position + Vector2(18, 14)
	_evidence_label.size = Vector2(right_panel.size.x - 36.0, 18)
	var text_width := right_panel.size.x - 36.0
	var prompt_height := _estimated_text_height(mission_definition.prompt, text_width, 17, 42.0)
	_prompt_label.position = right_panel.position + Vector2(18, 36)
	_prompt_label.size = Vector2(text_width, prompt_height)
	var instruction_top := 36.0 + prompt_height + 10.0
	var instruction_height := _estimated_text_height(mission_definition.instruction, text_width, 16, 38.0)
	_instruction_label.position = right_panel.position + Vector2(18, instruction_top)
	_instruction_label.size = Vector2(text_width, instruction_height)
	var answers_top := instruction_top + instruction_height + 10.0
	_answer_scroll.position = right_panel.position + Vector2(14, answers_top)
	_answer_scroll.size = Vector2(right_panel.size.x - 28.0, maxf(64.0, right_panel.size.y - answers_top - 52.0))
	_feedback_label.position = right_panel.position + Vector2(18, right_panel.size.y - 34.0)
	_feedback_label.size = Vector2(right_panel.size.x - 36.0, 26)
	_info_button.position = Vector2(size.x - 58.0, 10)


func _estimated_text_height(text_value: String, width: float, font_size: int, minimum_height: float) -> float:
	var characters_per_line := maxf(12.0, width / (float(font_size) * 0.52))
	var line_count := 0
	for line in text_value.split("\n"):
		line_count += maxi(1, ceili(float(line.length()) / characters_per_line))
	return maxf(minimum_height, line_count * (float(font_size) + 5.0) + 4.0)


func _rebuild_interaction() -> void:
	for child in _answer_area.get_children():
		_answer_area.remove_child(child)
		child.queue_free()
	_selection_buttons.clear()
	_sequence_up_buttons.clear()
	_sequence_down_buttons.clear()
	_pair_selectors.clear()
	_verify_button = null
	_build_interaction()


func _show_learning_note() -> void:
	if _info_dialog == null:
		_info_dialog = AcceptDialog.new()
		_info_dialog.title = "Öğrenme notu"
		_info_dialog.dialog_text = "%s\n%s\n%s" % [mission_definition.learning_target, mission_definition.curriculum, mission_definition.source_note]
		add_child(_info_dialog)
	_info_dialog.popup_centered(Vector2i(560, 220))


func _build_interaction() -> void:
	_answer_area.position = Vector2.ZERO
	_answer_area.size = Vector2(_answer_scroll.size.x, 1.0)
	match mission_definition.mode:
		"choice":
			_build_choice()
		"sequence":
			_build_sequence()
		"pair":
			_build_pairs()


func _build_choice() -> void:
	if _choice_order.is_empty():
		var shuffled := Array(mission_definition.options)
		shuffled.shuffle()
		_choice_order = PackedStringArray(shuffled)
	var spacing := 7.0
	var button_y := 4.0
	for index in _choice_order.size():
		var option := _choice_order[index]
		var button_width := _answer_scroll.size.x - 10.0
		var usable_text_width := maxf(120.0, button_width - 58.0)
		var estimated_line_width := maxf(18.0, usable_text_width / 8.0)
		var estimated_lines := maxi(1, ceili(float(option.length()) / estimated_line_width))
		var button_height := maxf(56.0, estimated_lines * 22.0 + 20.0)
		var button := _button(option, Vector2(button_width, button_height))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.position = Vector2(5, button_y)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.button_pressed = option == _selected_choice
		button.pressed.connect(_select_choice.bind(option, button))
		button.disabled = _completed
		_answer_area.add_child(button)
		_selection_buttons.append(button)
		button_y += button_height + spacing
	var verify_y := button_y + 2.0
	_verify_button = _button("Yanıtı kontrol et", Vector2(210, 44))
	_verify_button.theme_type_variation = "PrimaryButton"
	_verify_button.position = Vector2(5, verify_y)
	_verify_button.disabled = _selected_choice.is_empty() or _completed
	_verify_button.pressed.connect(func() -> void: try_answer(_selected_choice))
	_answer_area.add_child(_verify_button)
	_set_answer_content_height(verify_y + 50.0)


func _select_choice(option: String, selected_button: Button) -> void:
	if _completed:
		return
	_selected_choice = option
	for button in _selection_buttons:
		button.set_pressed_no_signal(button == selected_button)
	_clear_feedback_and_result()
	_verify_button.disabled = false


func _build_sequence() -> void:
	if _sequence_order.is_empty():
		_sequence_order = mission_definition.sequence_items.duplicate()
	var row_width := _answer_scroll.size.x - 8.0
	var row_height := 54.0
	var row_gap := 8.0
	var item_width := row_width - 204.0
	for index in _sequence_order.size():
		var row := Control.new()
		row.position = Vector2(2, 2 + index * (row_height + row_gap))
		row.size = Vector2(row_width, row_height)
		_answer_area.add_child(row)
		var item := _button("%02d  ·  %s" % [index + 1, _sequence_order[index]], Vector2(item_width, row_height))
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.position = Vector2.ZERO
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.disabled = _completed
		row.add_child(item)
		var up := _button("↑ Yukarı", Vector2(94, row_height))
		up.tooltip_text = "Önceki sıraya taşı"
		up.position = Vector2(item_width + 4.0, 0)
		up.pressed.connect(_move_sequence.bind(index, -1))
		up.disabled = _completed or index == 0
		row.add_child(up)
		_sequence_up_buttons.append(up)
		var down := _button("↓ Aşağı", Vector2(94, row_height))
		down.tooltip_text = "Sonraki sıraya taşı"
		down.position = Vector2(item_width + 102.0, 0)
		down.pressed.connect(_move_sequence.bind(index, 1))
		down.disabled = _completed or index == _sequence_order.size() - 1
		row.add_child(down)
		_sequence_down_buttons.append(down)
		_selection_buttons.append(item)
	_verify_button = _button("Sıralamayı kontrol et", Vector2(230, 44))
	_verify_button.theme_type_variation = "PrimaryButton"
	_verify_button.position = Vector2(4, _sequence_order.size() * (row_height + row_gap) + 8)
	_verify_button.pressed.connect(func() -> void: try_answer(_sequence_order))
	_verify_button.disabled = _completed
	_answer_area.add_child(_verify_button)
	_set_answer_content_height(_verify_button.position.y + _verify_button.size.y + 8.0)


func _build_pairs() -> void:
	if _pair_right_order.is_empty():
		var shuffled := Array(mission_definition.pair_right)
		shuffled.shuffle()
		_pair_right_order = PackedStringArray(shuffled)
	var row_width := _answer_scroll.size.x - 8.0
	var row_y := 27.0
	var left_title := _label("KAYIT", 12, ACCENT)
	left_title.position = Vector2(4, 0)
	left_title.size = Vector2(row_width, 22)
	_answer_area.add_child(left_title)
	for index in mission_definition.pair_left.size():
		var left_value := mission_definition.pair_left[index]
		var left := _label(left_value, 15, INK)
		left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var left_height := _estimated_text_height(left_value, row_width, 15, 24.0)
		left.position = Vector2(4, row_y)
		left.size = Vector2(row_width, left_height)
		_answer_area.add_child(left)
		var right := OptionButton.new()
		right.custom_minimum_size = Vector2(row_width, 42)
		right.size = Vector2(row_width, 42)
		right.position = Vector2(4, row_y + left_height + 4.0)
		right.add_theme_font_size_override("font_size", 15)
		right.add_item("Karşılığı seç…")
		right.set_item_metadata(0, "")
		for target in _pair_right_order:
			right.add_item(target)
			right.set_item_metadata(right.get_item_count() - 1, target)
		right.item_selected.connect(_on_pair_selected.bind(left_value))
		right.disabled = _completed
		_pair_selectors[left_value] = right
		_answer_area.add_child(right)
		row_y += left_height + 50.0
	_verify_button = _button("Eşleşmeleri kontrol et", Vector2(230, 44))
	_verify_button.theme_type_variation = "PrimaryButton"
	_verify_button.position = Vector2(4, row_y + 4.0)
	_verify_button.pressed.connect(func() -> void: try_answer(_pair_answers))
	_verify_button.disabled = _pair_answers.size() != mission_definition.pair_left.size() or _completed
	_answer_area.add_child(_verify_button)
	_refresh_pair_options()
	_set_answer_content_height(_verify_button.position.y + _verify_button.size.y + 8.0)


func _on_pair_selected(index: int, left_value: String) -> void:
	if _completed:
		return
	var selector: OptionButton = _pair_selectors[left_value]
	var target := String(selector.get_item_metadata(index))
	if target.is_empty():
		_pair_answers.erase(left_value)
	else:
		var previous_target := String(_pair_answers.get(left_value, ""))
		for other_left in _pair_answers.keys():
			if String(other_left) != left_value and String(_pair_answers[other_left]) == target:
				if previous_target.is_empty():
					_pair_answers.erase(other_left)
				else:
					_pair_answers[other_left] = previous_target
				break
		_pair_answers[left_value] = target
	_clear_feedback_and_result()
	_refresh_pair_options()
	_set_feedback("%d / %d eşleşme kuruldu." % [_pair_answers.size(), mission_definition.pair_left.size()], ACCENT)


func _refresh_pair_options() -> void:
	for left_value in _pair_selectors:
		var selector: OptionButton = _pair_selectors[left_value]
		var assigned_target := String(_pair_answers.get(left_value, ""))
		for index in range(1, selector.get_item_count()):
			var target := String(selector.get_item_metadata(index))
			selector.set_item_disabled(index, false)
			if target == assigned_target:
				selector.select(index)
		if assigned_target.is_empty():
			selector.select(0)
		selector.disabled = _completed
	if _verify_button != null:
		var distinct: Dictionary = {}
		for target in _pair_answers.values():
			distinct[target] = true
		_verify_button.disabled = _completed or _pair_answers.size() != mission_definition.pair_left.size() or distinct.size() != mission_definition.pair_left.size()


func _set_answer_content_height(content_height: float) -> void:
	_answer_area.custom_minimum_size = Vector2(_answer_scroll.size.x, content_height)
	_answer_area.size = _answer_area.custom_minimum_size


func _move_sequence(index: int, direction: int) -> void:
	if _completed:
		return
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
		_sequence_up_buttons[index].disabled = _completed or index == 0
		_sequence_down_buttons[index].disabled = _completed or index == _sequence_order.size() - 1
	_clear_feedback_and_result()


func _set_feedback(message: String, color: Color) -> void:
	if _feedback_label == null:
		return
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_label.text = message
	_feedback_label.add_theme_color_override("font_color", color)
	if message.is_empty():
		_feedback_label.modulate.a = 1.0
		_feedback_label.hide()
		return
	_feedback_label.modulate.a = 1.0
	_feedback_label.show()
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(4.0)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.25)


func _clear_feedback_and_result() -> void:
	_set_feedback("", MUTED)
	if _visual != null and _visual.has_method("clear_result"):
		_visual.call("clear_result")


func _lock_interaction() -> void:
	for button in _selection_buttons:
		button.disabled = true
	for button in _sequence_up_buttons + _sequence_down_buttons:
		button.disabled = true
	for selector in _pair_selectors.values():
		(selector as OptionButton).disabled = true
	if _verify_button != null:
		_verify_button.disabled = true


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
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.custom_minimum_size = button_size
	button.size = button_size
	button.add_theme_font_size_override("font_size", 16)
	return button
