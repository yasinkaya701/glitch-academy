extends "res://stations/yks/mission.gd"
## Subject-specific presentation for the Fikir Meydanı argument exercise.

const TITLE_FONT := preload("res://fonts/CinzelDecorative-Bold.ttf")
const QUOTE_FONT := preload("res://fonts/Marcellus-Regular.ttf")

const TITLE_INK := Color("#f0d7a5")
const QUOTE_INK := Color("#e8e0d0")
const QUOTE_PANEL := Color("#111d29")
const QUOTE_EDGE := Color("#756044")


func _build_interface() -> void:
	super._build_interface()
	var overline := _find_subject_overline()
	if overline != null:
		overline.position = Vector2(28, 35)
		overline.size = Vector2(maxf(120.0, size.x - 112.0), 15)
		overline.add_theme_font_size_override("font_size", 10)
		overline.add_theme_color_override("font_color", Color("#b6a88e"))
	var title := Label.new()
	title.text = "Fikir Meydanı"
	title.position = Vector2(26, 4)
	title.size = Vector2(maxf(140.0, size.x - 108.0), 34)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 25 if size.x >= 600.0 else 21)
	title.add_theme_color_override("font_color", TITLE_INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func _find_subject_overline() -> Label:
	for child in get_children():
		if child is Label and "FELSEFE" in (child as Label).text.to_upper():
			return child as Label
	return null


func _build_pairs() -> void:
	if _pair_right_order.is_empty():
		var shuffled := Array(mission_definition.pair_right)
		shuffled.shuffle()
		_pair_right_order = PackedStringArray(shuffled)
	var row_width := maxf(72.0, _answer_scroll.size.x - 8.0)
	var row_y := _answer_controls_top + 3.0
	for index in mission_definition.pair_left.size():
		var left_value := mission_definition.pair_left[index]
		var quote_font_size := 17 if row_width > 280.0 else 15
		var quote := Label.new()
		quote.text = "“%s”" % left_value
		quote.add_theme_font_override("font", QUOTE_FONT)
		quote.add_theme_font_size_override("font_size", quote_font_size)
		quote.add_theme_color_override("font_color", QUOTE_INK)
		quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var quote_height := _measured_label_height(quote.text, row_width - 26.0, quote_font_size)
		quote.custom_minimum_size = Vector2(row_width - 26.0, quote_height)
		var card := PanelContainer.new()
		card.position = Vector2(3, row_y)
		card.size = Vector2(row_width, quote_height + 17.0)
		card.custom_minimum_size = card.size
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = QUOTE_PANEL
		card_style.border_color = QUOTE_EDGE
		card_style.content_margin_left = 13.0
		card_style.content_margin_right = 13.0
		card_style.content_margin_top = 8.0
		card_style.content_margin_bottom = 8.0
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(7)
		card.add_theme_stylebox_override("panel", card_style)
		card.add_child(quote)
		_answer_area.add_child(card)
		row_y += card.size.y + 5.0

		var right := OptionButton.new()
		right.focus_mode = Control.FOCUS_ALL
		right.set_meta("mission_focus_key", "pair:" + left_value)
		right.tooltip_text = "‘%s’ kaydının karşılığını seç" % left_value
		right.custom_minimum_size = Vector2(row_width, 44)
		right.size = Vector2(row_width, 44)
		right.position = Vector2(3, row_y)
		right.add_theme_font_size_override("font_size", 15 if row_width > 260.0 else 13)
		right.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		right.add_item("Karşılığı seç…")
		right.set_item_metadata(0, "")
		for target in _pair_right_order:
			right.add_item(target)
			right.set_item_metadata(right.get_item_count() - 1, target)
		right.item_selected.connect(_on_pair_selected.bind(left_value))
		right.disabled = _completed
		_pair_selectors[left_value] = right
		_answer_area.add_child(right)
		row_y += 55.0
	_refresh_pair_options()
	_set_answer_content_height(row_y + 3.0)


func _measured_label_height(text_value: String, width: float, font_size: int) -> float:
	var measured := QUOTE_FONT.get_multiline_string_size(
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		width,
		font_size
	)
	return maxf(float(font_size + 8), ceilf(measured.y) + 3.0)
