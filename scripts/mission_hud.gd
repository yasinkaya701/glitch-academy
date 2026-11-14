extends Control
## Görevler için minimal arayüz. Metin paneli yok (docs/UX.md): tek cümlelik yönerge, adım noktaları,
## sahnede kısa balon, alt kenarda araç şeridi, sağ altta tek aksiyon düğmesi.

signal action_pressed
signal skip_pressed
signal pause_pressed
signal back_pressed
signal view_pressed

const INK := Color("#eeeae0")
const MUTED := Color("#b1ac9e")
const ACCENT := Color("#8fbea0")
const WARM := Color("#dfae63")
const DANGER := Color("#b85f56")
const BG := Color("#191a17")
const EDGE := Color("#3b3d35")

var directive: Label
var counter: Label
var toast: Label
var tools: HBoxContainer
var action: Button
var skip: Button
var pause: Button
var back: Button
var info_button: Button
var view_button: Button
## Yönergenin hemen altına dizilen istasyon okumaları (ölçüm satırı gibi); yönergenin üstüne binmez.
var below_directive: Array[Control] = []
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
	# Yönerge bir talimat cümlesidir: gövde yazı tipi ve yumuşak açık gölge.
	directive.add_theme_font_size_override("font_size", 20)
	directive.add_theme_color_override("font_color", INK)
	var reading_surface := StyleBoxFlat.new()
	reading_surface.bg_color = Color("#191a17", 0.97)
	reading_surface.border_color = EDGE
	reading_surface.set_border_width_all(1)
	reading_surface.set_corner_radius_all(8)
	reading_surface.content_margin_left = 14
	reading_surface.content_margin_right = 14
	reading_surface.content_margin_top = 10
	reading_surface.content_margin_bottom = 10
	directive.add_theme_stylebox_override("normal", reading_surface)
	directive.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0))
	directive.add_theme_constant_override("shadow_offset_x", 0)
	directive.add_theme_constant_override("shadow_offset_y", 1)
	directive.mouse_filter = Control.MOUSE_FILTER_IGNORE
	directive.position = Vector2(28, 48)
	directive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var toast_box := StyleBoxFlat.new()
	toast_box.bg_color = Color(BG, 0.88)
	toast_box.border_color = EDGE
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
	tools.alignment = BoxContainer.ALIGNMENT_BEGIN
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

	back = Button.new()
	back.text = "Merkeze dön"
	back.tooltip_text = "Kontrol merkezine dön (Esc)"
	back.pressed.connect(func() -> void: back_pressed.emit())
	add_child(back)

	info_button = Button.new()
	info_button.text = "Bilgi"
	info_button.tooltip_text = "Düzeneğin açıklaması"
	info_button.custom_minimum_size = Vector2(36, 36)
	info_button.pressed.connect(_toggle_info)
	add_child(info_button)
	view_button = Button.new()
	view_button.text = "Geniş görünüm"
	view_button.tooltip_text = "Tüm sahneyi göster (Home)"
	view_button.pressed.connect(func() -> void: view_pressed.emit())
	add_child(view_button)
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
	_layout_hud()
	queue_redraw()


func _layout_hud() -> void:
	var edge := 24.0
	var right := size.x - edge
	for button in [back, skip, pause, view_button, info_button]:
		if button.visible:
			button.size = button.get_combined_minimum_size().max(Vector2(44, 40))
			button.position = Vector2(right - button.size.x, 18)
			right = button.position.x - 8.0
	counter.position = Vector2(edge, 16)
	counter.size = Vector2(maxf(right - edge - 12, 120), 24)
	var directive_top := 78.0 if right - edge < 300.0 else 70.0
	directive.position = Vector2(edge, directive_top)
	# Yönerge sahnenin sağındaki grafik ve panelleri örtmesin: en fazla 620 px.
	directive.size = Vector2(minf(maxf(right - edge, minf(size.x - edge * 2, 260)), 620.0), 0)
	directive.size.y = maxf(directive.get_combined_minimum_size().y, 30.0)
	var below_y := directive.position.y + directive.size.y + 10.0
	for item in below_directive:
		item.position = Vector2(edge + 2.0, below_y)
		below_y += item.get_combined_minimum_size().y + 4.0
	var action_width := action.get_combined_minimum_size().x if action.visible else 0.0
	var tool_width := maxf(size.x - edge * 2 - action_width - (16 if action.visible else 0), 0)
	var tool_height := maxf(tools.get_combined_minimum_size().y, 46)
	var action_height := maxf(action.get_combined_minimum_size().y, 46)
	var row_height := maxf(tool_height, action_height)
	tools.position = Vector2(edge, size.y - edge - row_height)
	tools.size = Vector2(tool_width, row_height)
	action.size = Vector2(action_width, row_height)
	action.position = Vector2(size.x - edge - action_width, tools.position.y)
	var toast_width := minf(size.x - edge * 2, 720)
	toast.size.x = toast_width
	toast.size.y = toast.get_minimum_size().y
	toast.position = Vector2((size.x - toast_width) * 0.5, tools.position.y - toast.size.y - 16)
	info_card.size.x = minf(size.x - edge * 2, 380)
	info_card.size.y = info_card.get_minimum_size().y
	info_card.position = Vector2(size.x - info_card.size.x - edge, 112)


func _draw() -> void:
	# Üstte ve altta açık okuma zemini: yönerge ve araçlar okunur kalır, panel yok.
	var dark := Color("#10110f", 0.92)
	var clear := Color(BG, 0.0)
	var top := minf(size.y * 0.22, 150.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, top), Vector2(0, top)]),
		PackedColorArray([dark, dark, clear, clear]))
	var bottom := minf(size.y * 0.24, 170.0)
	draw_polygon(PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y), Vector2(size.x, size.y - bottom), Vector2(0, size.y - bottom)]),
		PackedColorArray([dark, dark, clear, clear]))
	_draw_step_track()


const PHASES: Array[String] = ["Tanı", "Tahmin", "Dene", "Gözle", "Çıkarım"]


## Her deneyde aynı beş aşama: istasyonun adım sayısı bu beş aşamaya orantılanır.
func current_phase() -> int:
	if _steps_total <= 0:
		return 0
	if _steps_current >= _steps_total:
		return PHASES.size()
	return clampi(int(float(_steps_current) * PHASES.size() / _steps_total), 0, PHASES.size() - 1)


func _draw_step_track() -> void:
	if _steps_total <= 1 or size.x <= 0.0:
		return
	var font := get_theme_default_font()
	var font_size := 13
	var phase := current_phase()
	var compact := size.x < 560.0
	var x := 24.0
	var y := _progress_track_y() + 12.0
	for index in PHASES.size():
		var done := index < phase
		var now := index == phase
		if compact and not now:
			continue
		var mark: String = "✓ " if done else ("▸ " if now else "")
		var text: String = mark + String(PHASES[index])
		var color := Color("#8fbea0") if done else Color("#dfae63") if now else Color("#b1ac9e")
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_line(Vector2(x, y + 5.0), Vector2(x + width, y + 5.0), color, 2.0 if now else 1.0)
		x += width + 18.0


func _progress_track_y() -> float:
	return 47.0


func _standalone() -> bool:
	## Kontrol merkezinde kendi geri düğmesi var, burada yalnızca tek başına açılan sahnede gösterilir.
	return get_parent() != null and get_parent().get_parent() == get_tree().root


func _unhandled_key_input(event: InputEvent) -> void:
	if back.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		back_pressed.emit()
		get_viewport().set_input_as_handled()


func hide_all_buttons() -> void:
	action.hide()
	skip.hide()
	pause.hide()
	back.visible = _standalone()
	info_button.hide()
	view_button.hide()
	info_card.hide()


func set_directive(text: String) -> void:
	directive.text = text


func set_steps(current: int, total: int, label: String = "") -> void:
	_steps_total = maxi(total, 0)
	_steps_current = clampi(current, 0, _steps_total)
	counter.text = "%d / %d   %s" % [mini(current + 1, _steps_total), _steps_total, label.capitalize()]
	queue_redraw()


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
		color = DANGER
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
