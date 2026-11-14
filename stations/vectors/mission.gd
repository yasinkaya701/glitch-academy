extends "res://scripts/mission.gd"

const Plot = preload("res://stations/vectors/route_plot.gd")
const Experiment3D = preload("res://scenes/experiment_3d.tscn")
const VectorModel = preload("res://stations/vectors/vector_model_3d.gd")
const INTRO := 0
const EXPLORE := 1
const APPLY := 2
const EXPECTED := Vector2(5, -12)
const MAGNITUDE := 13.0
const TEXT := Color("#eeeae0")
const MUTED := Color("#b1ac9e")
const ACCENT := Color("#8fbea0")
const WARNING := Color("#dfae63")
const SURFACE := Color("#191a17")
const SURFACE_RAISED := Color("#242520")
const EDGE := Color("#3b3d35")

var _stage := INTRO
var _plot: Plot
var _world_view: SubViewportContainer
var _vector_model: Node3D
var _view_toggle: Button
var _plot_caption: Label
var _heading: Label
var _stage_title: Label
var _explanation: Label
var _feedback: Label
var _skip: Button
var _explore: VBoxContainer
var _reveal: Button
var _methods: Array[Button] = []
var _next: Button
var _apply: VBoxContainer
var _inputs: Array[LineEdit] = []
var _launch: Button
var _animation: Tween
var _intro_timer: SceneTreeTimer


func _ready() -> void:
	_build_interface()
	_show_stage(INTRO)
	_animation = create_tween()
	_animation.tween_method(_set_capsule, Vector2.ZERO, Vector2(7, 0), 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro_timer = get_tree().create_timer(2.9)
	_intro_timer.timeout.connect(_skip_intro)


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#10110f")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var inset := MarginContainer.new()
	add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		inset.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 18)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 13)
	inset.add_child(page)

	var mast := HBoxContainer.new()
	mast.add_theme_constant_override("separation", 12)
	page.add_child(mast)
	_heading = _label(mast, "Vektör Limanı", 28)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skip = _button(mast, "Açılışı geç")
	_skip.pressed.connect(_skip_intro)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 7)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	var display := VBoxContainer.new()
	display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(display)
	var display_bar := HBoxContainer.new()
	display_bar.add_theme_constant_override("separation", 6)
	display.add_child(display_bar)
	_view_toggle = _button(display_bar, "3B deney")
	_view_toggle.toggle_mode = true
	_view_toggle.button_pressed = true
	_view_toggle.pressed.connect(_toggle_view)
	var graph_toggle := _button(display_bar, "2B grafik")
	graph_toggle.toggle_mode = true
	graph_toggle.pressed.connect(func() -> void:
		_view_toggle.set_pressed_no_signal(false)
		_toggle_view())
	_world_view = Experiment3D.instantiate() as SubViewportContainer
	_world_view.custom_minimum_size = Vector2(410, 270)
	_world_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.add_child(_world_view)
	_vector_model = VectorModel.new()
	_world_view.get_node("Viewport/World/Model").add_child(_vector_model)
	_plot = Plot.new()
	_plot.custom_minimum_size = Vector2(410, 295)
	_plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.add_child(_plot)
	_plot.visible = false
	_plot_caption = _label(display, "", 13, MUTED)
	_plot_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var side := PanelContainer.new()
	side.custom_minimum_size.x = 340
	side.add_theme_stylebox_override("panel", _panel_style())
	columns.add_child(side)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var steps := VBoxContainer.new()
	steps.add_theme_constant_override("separation", 12)
	steps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(steps)
	_stage_title = _label(steps, "", 21, ACCENT)
	_stage_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_explanation = _label(steps, "", 16, TEXT)
	_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_explore = VBoxContainer.new()
	_explore.add_theme_constant_override("separation", 10)
	steps.add_child(_explore)
	var methods := HBoxContainer.new()
	methods.add_theme_constant_override("separation", 8)
	_explore.add_child(methods)
	var group := ButtonGroup.new()
	for index in 2:
		var mode := _button(methods, "Uç uca" if index == 0 else "Paralelkenar")
		mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode.toggle_mode = true
		mode.button_group = group
		mode.button_pressed = index == 0
		mode.pressed.connect(_set_method.bind(index))
		_methods.append(mode)
	_reveal = _button(_explore, "Bileşkeyi çiz")
	_reveal.pressed.connect(_reveal_result)
	_next = _button(_explore, "Yeni rotayı hesapla")
	_next.disabled = true
	_next.pressed.connect(_show_stage.bind(APPLY))

	_apply = VBoxContainer.new()
	_apply.add_theme_constant_override("separation", 8)
	steps.add_child(_apply)
	_add_input("Doğu–batı bileşeni", "Örn. 3")
	_add_input("Kuzey–güney bileşeni", "Örn. −4")
	_add_input("Bileşke büyüklüğü", "Örn. 5")
	_launch = _button(_apply, "Kapsülü gönder")
	_launch.pressed.connect(_launch_capsule)

	_feedback = _label(steps, "", 15, MUTED)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _show_stage(stage: int) -> void:
	_stop_animation()
	_stage = stage
	_plot.route_stage = stage
	_plot.capsule = Vector2.ZERO
	_plot.route_draw = 0.0
	_plot.attempted = false
	_plot.queue_redraw()
	_sync_3d()
	_explore.visible = stage == EXPLORE
	_apply.visible = stage == APPLY
	_skip.visible = stage == INTRO
	_heading.visible = get_parent() == get_tree().root
	_skip.get_parent().visible = _skip.visible or _heading.visible
	_feedback.text = ""
	_feedback.modulate = Color.WHITE

	match stage:
		INTRO:
			_stage_title.text = "Kapsül hedefi kaçırdı"
			_explanation.text = "Yön bilgisi silindi. Cihaz 3 birim doğu ile 4 birim kuzeyi toplayıp kapsülü 7 birim doğuya gönderdi."
			_plot_caption.text = "Turuncu ok cihazın hatalı komutunu gösterir."
		EXPLORE:
			_stage_title.text = "İki oku birleştir"
			_explanation.text = "3 birim doğu ve 4 birim kuzey. İki çizim yöntemini dene ve başlangıçtan son noktaya uzanan oku incele."
			_plot_caption.text = "Yatay eksende doğu, dikey eksende kuzey pozitif."
		APPLY:
			_stage_title.text = "Yeni yanaşma rotası"
			_explanation.text = "Yanaşma noktası 5 birim doğuda ve 12 birim güneyde. İşaretli bileşenleri ve büyüklüğü gir."
			_plot_caption.text = "Kapsül, girdiğin bileşenlerin belirlediği noktaya hareket eder."
			_inputs[0].grab_focus()


func _skip_intro() -> void:
	if _stage == INTRO:
		_show_stage(EXPLORE)


func _set_method(method: int) -> void:
	_plot.method = method
	_methods[method].set_pressed_no_signal(true)
	_plot.queue_redraw()
	_sync_3d()
	if _plot.revealed:
		_update_result_feedback()


func _reveal_result() -> void:
	_stop_animation()
	_plot.revealed = true
	_next.disabled = false
	_update_result_feedback()
	_animation = create_tween()
	_animation.tween_method(_set_route_draw, 0.0, 1.0, 0.48).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _update_result_feedback() -> void:
	var explanation := "Uç uca çizimde ikinci ok, ilk okun ucundan başlar." if _plot.method == 0 else "Paralelkenarın köşegeni başlangıçtan aynı noktaya gider."
	_feedback.text = explanation + "\n\nBileşenler (3, 4)\nBüyüklük √(3² + 4²) = 5 birim\nAlınan yol 3 + 4 = 7 birim"


func _launch_capsule() -> void:
	if _launch.disabled:
		return
	var x_text := _number_text(_inputs[0].text)
	var y_text := _number_text(_inputs[1].text)
	var length_text := _number_text(_inputs[2].text)
	if not x_text.is_valid_float() or not y_text.is_valid_float() or not length_text.is_valid_float():
		_feedback.text = "Üç alana da birer sayı gir. Virgül veya nokta kullanabilirsin."
		return

	var submitted := Vector2(x_text.to_float(), y_text.to_float())
	var magnitude := length_text.to_float()
	if not submitted.is_finite() or not is_finite(magnitude):
		_feedback.text = "Sonlu sayılar gir."
		return
	var correct := submitted.is_equal_approx(EXPECTED) and is_equal_approx(magnitude, MAGNITUDE)
	_plot.attempt = submitted.clamp(Vector2(-20, -13), Vector2(20, 13))
	_plot.attempted = true
	_plot.docked = false
	_set_capsule(Vector2.ZERO)
	_launch.disabled = true
	_feedback.text = "Kapsül hareket ediyor…" if correct else "Girdiğin rotayı deniyoruz…"
	_stop_animation()
	_animation = create_tween()
	_animation.tween_method(_set_capsule, Vector2.ZERO, _plot.attempt, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_callback(_landing_result.bind(correct, submitted))


func _landing_result(correct: bool, submitted: Vector2) -> void:
	_plot.docked = correct
	_plot.queue_redraw()
	_sync_3d()
	if correct:
		_feedback.text = "Yanaşma tamamlandı.\n(5, −12) · 13 birim"
		_feedback.modulate = ACCENT
		for input in _inputs:
			input.editable = false
		completed.emit()
		return

	_launch.disabled = false
	if submitted.is_equal_approx(EXPECTED):
		_feedback.text = "Kapsül doğru konuma geldi. Yanaşma için büyüklüğü de doğrula."
	elif submitted.y > 0:
		_feedback.text = "Kapsül kuzeye gitti. Güney bileşeninin işaretini kontrol et."
	else:
		_feedback.text = "Kapsül hedefe ulaşmadı. İki bileşeni yeniden kontrol et."


func _set_capsule(value: Vector2) -> void:
	_plot.in_motion = (value != Vector2.ZERO and not _plot.docked)
	_plot.capsule = value
	_plot.queue_redraw()
	_sync_3d()


func _set_route_draw(value: float) -> void:
	_plot.route_draw = value
	_plot.queue_redraw()
	_sync_3d()


func _toggle_view() -> void:
	var show_3d := _view_toggle.button_pressed
	_world_view.visible = show_3d
	_plot.visible = not show_3d
	_sync_3d()


func _sync_3d() -> void:
	if _vector_model == null:
		return
	_vector_model.set_state(_stage, _plot.method, _plot.revealed, _plot.route_draw, _plot.attempted, _plot.attempt, _plot.capsule, _plot.docked)


func _stop_animation() -> void:
	if _animation != null and _animation.is_valid():
		_animation.kill()
	if _plot != null:
		_plot.in_motion = false


func _number_text(value: String) -> String:
	return value.strip_edges().replace(",", ".").replace("−", "-")


func _add_input(title: String, example: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_apply.add_child(row)
	var caption := _label(row, title, 14, MUTED)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var input := LineEdit.new()
	input.custom_minimum_size = Vector2(106, 35)
	input.placeholder_text = example
	input.max_length = 16
	input.text_submitted.connect(func(_value: String) -> void: _launch_capsule())
	row.add_child(input)
	_inputs.append(input)


func _label(parent: Control, value: String, font_size: int, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Control, title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 36
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.28))
	button.add_theme_stylebox_override("normal", _button_box(SURFACE_RAISED, EDGE))
	button.add_theme_stylebox_override("hover", _button_box(Color("#30312b"), Color("#8fbea0")))
	button.add_theme_stylebox_override("pressed", _button_box(Color("#34483a"), Color("#8fbea0")))
	button.add_theme_stylebox_override("disabled", _button_box(Color("#20211e"), Color("#34352f")))
	button.add_theme_stylebox_override("focus", _button_box(SURFACE_RAISED, WARNING, 2))
	parent.add_child(button)
	return button


func _button_box(fill: Color, edge: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE
	style.border_color = EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 17
	style.content_margin_bottom = 17
	return style
