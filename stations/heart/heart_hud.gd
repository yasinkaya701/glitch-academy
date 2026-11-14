extends "res://scripts/mission_hud.gd"
## Kalp görevi için okunaklı, istasyona özel görev arayüzü.

const PAPER := Color("#f1ede3")
const MUTED_INK := Color("#b9b8a8")
const SAGE := Color("#a5ad84")
const AMBER := Color("#d4a15f")
const CHARCOAL := Color("#10110f")
const RAISED := Color("#191a17")
const HEART_EDGE := Color("#47483f")

var _header_panel: PanelContainer
var _controls_panel: PanelContainer
var _dock_panel: PanelContainer
var _status_label: Label


func _ready() -> void:
	super._ready()
	directive.add_theme_font_size_override("font_size", 19)
	directive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	directive.add_theme_color_override("font_color", PAPER)
	counter.add_theme_font_size_override("font_size", 13)
	counter.add_theme_color_override("font_color", SAGE)
	action.custom_minimum_size = Vector2(218, 48)
	info_button.custom_minimum_size = Vector2(42, 42)
	tools.add_theme_constant_override("separation", 10)
	tools.alignment = BoxContainer.ALIGNMENT_BEGIN
	directive.add_theme_stylebox_override("normal", _surface_style(RAISED, HEART_EDGE, 8))
	_header_panel = _make_panel()
	_controls_panel = _make_panel()
	_dock_panel = _make_panel()
	_style_button(action, SAGE, CHARCOAL, SAGE)
	for button in [back, skip, pause, view_button, info_button]:
		_style_button(button, RAISED, PAPER, HEART_EDGE)
	var toast_style := _surface_style(RAISED, HEART_EDGE, 12)
	toast.add_theme_stylebox_override("normal", toast_style)
	toast.add_theme_color_override("font_color", PAPER)
	info_label.add_theme_color_override("font_color", PAPER)
	var info_surface := _surface_style(RAISED, HEART_EDGE, 12)
	info_card.add_theme_stylebox_override("panel", info_surface)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _surface_style(CHARCOAL, HEART_EDGE, 12))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	move_child(panel, 0)
	return panel


func hide_all_buttons() -> void:
	super.hide_all_buttons()
	view_button.show()


func bind_status(label: Label) -> void:
	_status_label = label
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", MUTED_INK)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.clip_text = true


func _surface_style(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	return style


func _style_button(button: Button, fill: Color, text_color: Color, edge: Color) -> void:
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_stylebox_override("normal", _surface_style(fill, edge, 8))
	button.add_theme_stylebox_override("hover", _surface_style(fill.lightened(0.1), SAGE, 8))
	button.add_theme_stylebox_override("pressed", _surface_style(fill.darkened(0.08), AMBER, 8))
	button.add_theme_stylebox_override("focus", _surface_style(Color(0, 0, 0, 0), AMBER, 8))


func style_control(button: Button, primary: bool = false) -> void:
	_style_button(button, SAGE if primary else RAISED, CHARCOAL if primary else PAPER, SAGE if primary else HEART_EDGE)


func say(text: String, tone: StringName = &"neutral") -> void:
	super.say(text, tone)
	var color := PAPER
	if tone == &"good":
		color = SAGE
	elif tone == &"bad":
		color = Color("#d58d79")
	toast.add_theme_color_override("font_color", color)


func _process(delta: float) -> void:
	super._process(delta)
	_layout_heart_hud()


func _layout_heart_hud() -> void:
	if _header_panel == null or _controls_panel == null or _dock_panel == null:
		return
	var margin := clampf(size.x * 0.028, 14.0, 26.0)
	var w := size.x
	var h := size.y
	var compact := w < 900.0 or h < 620.0
	var header_top := 70.0 if compact else 18.0
	var header_width := w - margin * 2.0 if compact else minf(440.0, maxf(360.0, w * 0.32))
	var header_height := 142.0 if compact else 154.0
	var inner_left := margin + 16.0
	var inner_width := maxf(header_width - 32.0, 160.0)
	_header_panel.position = Vector2(margin, header_top)
	_header_panel.size = Vector2(header_width, header_height)
	counter.position = Vector2(inner_left, header_top + 12.0)
	counter.size = Vector2(inner_width, 24.0)
	counter.add_theme_font_size_override("font_size", 12 if compact else 13)
	directive.position = Vector2(inner_left, header_top + 42.0)
	directive.size = Vector2(inner_width, 62.0 if compact else 56.0)
	directive.add_theme_font_size_override("font_size", 16)
	if _status_label != null:
		_status_label.position = Vector2(inner_left, header_top + (108.0 if compact else 116.0))
		_status_label.size = Vector2(inner_width, 28.0)
		_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var x := w - margin
	var control_y := 20.0
	back.position = Vector2(x - back.size.x, control_y)
	x = back.position.x - (8.0 if back.visible else 0.0)
	if skip.visible:
		skip.position = Vector2(x - skip.size.x, control_y)
		x = skip.position.x - 8.0
	if pause.visible:
		pause.position = Vector2(x - pause.size.x, control_y)
		x = pause.position.x - 8.0
	if view_button.visible:
		view_button.size = view_button.get_combined_minimum_size().max(Vector2(44, 40))
		view_button.position = Vector2(x - view_button.size.x, control_y)
		x = view_button.position.x - 8.0
	info_button.position = Vector2(maxf(margin, x - info_button.size.x), control_y)
	var controls_left := maxf(header_width + margin * 2.0 + 12.0, info_button.position.x - 10.0)
	_controls_panel.position = Vector2(controls_left, control_y - 4.0)
	_controls_panel.size = Vector2(maxf(w - controls_left - margin + 4.0, 0.0), 50.0)
	info_card.size.x = minf(maxf(w - margin * 2.0, 220.0), 380.0)
	info_card.size.y = minf(info_card.get_minimum_size().y, maxf(h * 0.32, 100.0))
	info_card.position = Vector2(maxf(margin, w - info_card.size.x - margin), 76.0)

	var has_tools := false
	for group in tools.get_children():
		var content_count := group.get_child_count()
		if group is ScrollContainer and content_count > 0:
			var content := group.get_child(0)
			content_count = 0
			for item in content.get_children():
				if not item.is_queued_for_deletion():
					content_count += 1
			group.visible = content_count > 0
		if group.visible:
			group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			group.size_flags_stretch_ratio = 1.0
			group.custom_minimum_size = Vector2(0.0, 42.0)
		has_tools = has_tools or content_count > 0
	_dock_panel.visible = has_tools or action.visible
	if compact:
		var dock_height := 112.0 if action.visible else 74.0
		var dock_y := h - dock_height - maxf(margin * 0.6, 8.0)
		_dock_panel.position = Vector2(margin, dock_y)
		_dock_panel.size = Vector2(w - margin * 2.0, dock_height)
		tools.position = Vector2(margin + 12.0, dock_y + 4.0)
		tools.size = Vector2(maxf(w - margin * 2.0 - 24.0, 120.0), 42.0 if action.visible else 56.0)
		if action.visible:
			action.custom_minimum_size.x = maxf(w - margin * 2.0 - 24.0, 180.0)
			action.size = Vector2(maxf(w - margin * 2.0 - 24.0, 180.0), 42.0)
			action.position = Vector2(margin + 12.0, dock_y + 58.0)
	else:
		var dock_y := h - 96.0
		_dock_panel.position = Vector2(margin, dock_y)
		_dock_panel.size = Vector2(w - margin * 2.0, 80.0)
		var action_width := minf(maxf(action.get_combined_minimum_size().x, 200.0), maxf(w * 0.30, 220.0)) if action.visible else 0.0
		tools.position = Vector2(margin + 16.0, dock_y + 4.0)
		tools.size = Vector2(maxf(w - margin * 2.0 - action_width - (36.0 if action.visible else 0.0), 180.0), 68.0)
		if action.visible:
			action.custom_minimum_size.x = 218.0
			action.size = Vector2(action_width, 48.0)
			action.position = Vector2(w - margin - action_width - 12.0, dock_y + 16.0)
	toast.position = Vector2((w - toast.size.x) * 0.5, 130.0)


func set_steps(current: int, total: int, label: String = "") -> void:
	var count := maxi(total, 1)
	var visible_step := clampi(current, 0, count)
	_steps_total = count
	_steps_current = visible_step
	var dots := ""
	for i in count:
		dots += "● " if i < visible_step else ("◉ " if i == visible_step and visible_step < count else "○ ")
	var display_step := count if visible_step >= count else visible_step + 1
	counter.text = "%s  %02d / %02d   ·   %s" % [dots.strip_edges(), display_step, count, label]
	queue_redraw()


func _progress_track_y() -> float:
	return 218.0 if size.x < 900.0 or size.y < 620.0 else 208.0


func _draw_step_track() -> void:
	# Adım noktaları sayaçta zaten var; ortada asılı ikinci bir çubuk sahneyi örtüyordu.
	pass
