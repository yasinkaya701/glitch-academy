extends Control
## Görevler için minimal arayüz. Metin paneli yok (docs/UX.md): tek cümlelik yönerge, adım noktaları,
## sahnede kısa balon, alt kenarda araç şeridi, sağ altta tek aksiyon düğmesi.

signal action_pressed
signal skip_pressed
signal pause_pressed

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const BG := Color("#070b12")

var directive: Label
var counter: Label
var toast: Label
var tools: HBoxContainer
var action: Button
var skip: Button
var pause: Button
var info_button: Button
var info_card: PanelContainer
var info_label: Label

var _steps_total := 0
var _steps_current := 0
var _toast_tween: Tween
var _note := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	directive = Label.new()
	directive.theme_type_variation = "HeadlineLabel"
	directive.add_theme_font_size_override("font_size", 19)
	directive.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	directive.add_theme_constant_override("shadow_offset_x", 0)
	directive.add_theme_constant_override("shadow_offset_y", 2)
	directive.mouse_filter = Control.MOUSE_FILTER_IGNORE
	directive.position = Vector2(28, 44)
	add_child(directive)

	counter = Label.new()
	counter.theme_type_variation = "SectionLabel"
	counter.position = Vector2(28, 22)
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(counter)

	toast = Label.new()
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_color_override("font_color", INK)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.modulate.a = 0.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var toast_box := StyleBoxFlat.new()
	toast_box.bg_color = Color(BG, 0.88)
	toast_box.border_color = Color("#41627f")
	toast_box.set_border_width_all(1)
	toast_box.set_corner_radius_all(14)
	toast_box.content_margin_left = 16
	toast_box.content_margin_right = 16
	toast_box.content_margin_top = 8
	toast_box.content_margin_bottom = 8
	toast.add_theme_stylebox_override("normal", toast_box)
	add_child(toast)

	tools = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 10)
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(tools)

	action = Button.new()
	action.theme_type_variation = "PrimaryButton"
	action.custom_minimum_size = Vector2(190, 46)
	action.pressed.connect(func() -> void: action_pressed.emit())
	add_child(action)

	skip = Button.new()
	skip.text = "Geç"
	skip.pressed.connect(func() -> void: skip_pressed.emit())
	add_child(skip)

	pause = Button.new()
	pause.text = "Duraklat"
	pause.pressed.connect(func() -> void: pause_pressed.emit())
	add_child(pause)

	info_button = Button.new()
	info_button.text = "i"
	info_button.custom_minimum_size = Vector2(36, 36)
	info_button.pressed.connect(_toggle_info)
	add_child(info_button)
	info_card = PanelContainer.new()
	info_card.theme_type_variation = "GlassPanel"
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(300, 0)
	info_card.add_child(info_label)
	info_card.hide()
	add_child(info_card)
	hide_all_buttons()


func _process(_delta: float) -> void:
	var size_now := size
	var bottom := size_now.y - 22.0
	tools.position = Vector2(28, bottom - 52.0)
	tools.size = Vector2(maxf(size_now.x - 28.0 - 240.0, 200.0), 46.0)
	action.position = Vector2(size_now.x - action.size.x - 28.0, bottom - 46.0)
	skip.position = Vector2(size_now.x - skip.size.x - 28.0, 22.0)
	pause.position = Vector2(size_now.x - pause.size.x - 28.0, 22.0)
	if skip.visible:
		pause.position.x = skip.position.x - pause.size.x - 8.0
	info_button.position = Vector2(size_now.x - 28.0 - info_button.size.x - (skip.size.x + 8.0 if skip.visible else 0.0) - (pause.size.x + 8.0 if pause.visible else 0.0) - 8.0, 22.0)
	info_card.position = Vector2(size_now.x - info_card.size.x - 28.0, 66.0)
	toast.position = Vector2((size_now.x - toast.size.x) * 0.5, bottom - 120.0)


func _draw() -> void:
	# Üstte ve altta yumuşak karartma: yönerge ve araçlar okunur kalır, panel yok.
	var dark := Color(BG, 0.78)
	var clear := Color(BG, 0.0)
	var top := minf(size.y * 0.22, 150.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, top), Vector2(0, top)]),
		PackedColorArray([dark, dark, clear, clear]))
	var bottom := minf(size.y * 0.24, 170.0)
	draw_polygon(PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y), Vector2(size.x, size.y - bottom), Vector2(0, size.y - bottom)]),
		PackedColorArray([dark, dark, clear, clear]))


func hide_all_buttons() -> void:
	action.hide()
	skip.hide()
	pause.hide()
	info_button.hide()
	info_card.hide()


func set_directive(text: String) -> void:
	directive.text = text


func set_steps(current: int, total: int, label: String = "") -> void:
	_steps_current = current
	_steps_total = total
	var dots := ""
	for i in total:
		dots += "●  " if i < current else "○  "
	counter.text = ("%s  %s" % [dots.strip_edges(), label]).strip_edges()


func set_action(text: String, enabled: bool = true) -> void:
	action.text = text
	action.visible = text != ""
	action.disabled = not enabled


func set_note(text: String) -> void:
	_note = text
	info_button.visible = text != ""
	info_card.hide()
	info_label.text = text


func _toggle_info() -> void:
	info_card.visible = not info_card.visible


func say(text: String, tone: StringName = &"neutral") -> void:
	toast.text = text
	var color := INK
	if tone == &"good":
		color = ACCENT
	elif tone == &"bad":
		color = WARM
	toast.add_theme_color_override("font_color", color)
	if _toast_tween != null:
		_toast_tween.kill()
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(4.5)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.6)


func clear_tools() -> void:
	for child in tools.get_children():
		child.queue_free()
