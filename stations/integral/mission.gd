extends "res://scripts/mission.gd"
## AYT · İntegral. Fiziksel tank + debi grafiği + deneme/yanılma ile onarım.
## Gösterilen debi q(t)=2+t L/s, hacim V(T)=integral_0^T q(t)dt.

const Sim = preload("res://stations/integral/integral_model.gd")
const LAB = preload("res://scenes/experiment_3d.tscn")
const INK := Color("#e8f1f2")
const MUTED := Color("#a7bbc5")
const MINT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const WRONG := Color("#e5645a")
const BLUE := Color("#7fb6f5")
const TANK_CAPACITY := 36.0
const TARGET_VOLUME := 30.0

var _phase := 0    # 0: keşif, 1: bağımsız onarım, 2: onarıldı
var _observed: Array[bool] = [false, false]
var _time := 2.0
var _revealed := false
var _water: MeshInstance3D
var _graph: Control
var _slider: HSlider
var _counter: Label
var _feedback: Label
var _instruction: Label
var _readout: Label
var _advance: Button
var _test_button: Button
var _sample_buttons: Array[Button] = []


func _ready() -> void:
	_build_ui()
	_build_tank()
	_set_time(2.0)
	_feedback.text = "MERİDYEN'in sayaç arızası: son debiyi süreyle çarpıp toplam hacim sanıyor."


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#070b12")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)
	outer.add_child(_label("AYT / MATEMATİK / BELİRLİ İNTEGRAL", 13, MINT))
	outer.add_child(_label("Akış Laboratuvarı", 27, INK, true))
	_instruction = _label("Debi zamanla artıyor. Anlık debiyle biriken toplam su aynı şey değildir.", 16, INK)
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_instruction)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 14)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(main)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.45
	left.add_theme_constant_override("separation", 10)
	main.add_child(left)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "GlassPanel"
	frame.custom_minimum_size = Vector2(420, 220)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(frame)
	var stage := LAB.instantiate() as Control
	stage.name = "TankPreview"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(stage)

	var graph_frame := PanelContainer.new()
	graph_frame.theme_type_variation = "GlassPanel"
	graph_frame.custom_minimum_size.y = 190
	left.add_child(graph_frame)
	_graph = Control.new()
	_graph.custom_minimum_size = Vector2(420, 190)
	_graph.draw.connect(_draw_graph)
	graph_frame.add_child(_graph)

	var right := PanelContainer.new()
	right.theme_type_variation = "ConsolePanel"
	right.custom_minimum_size.x = 350
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	right.add_child(panel)
	_counter = _label("KANIT 0 / 2", 13, WARM)
	panel.add_child(_counter)
	panel.add_child(_label("DEBİ  q(t) = 2 + t  L/s", 17, MINT))
	panel.add_child(_label("TOPLAM  V(T) = ∫₀ᵀ q(t)dt", 16, INK))
	_readout = _label("", 16, INK)
	_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readout.custom_minimum_size.y = 78
	panel.add_child(_readout)
	panel.add_child(_label("SÜRE  T  (s)", 13, MUTED))
	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 8.0
	_slider.step = 0.25
	_slider.value = 2.0
	_slider.custom_minimum_size.y = 32
	_slider.value_changed.connect(_on_time_changed)
	panel.add_child(_slider)
	_feedback = _label("", 15, INK)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size.y = 86
	panel.add_child(_feedback)
	_sample_buttons.append(_button(panel, "Ölçüm 01  ·  T = 2 s", _observe.bind(0)))
	_sample_buttons.append(_button(panel, "Ölçüm 02  ·  T = 4 s", _observe.bind(1)))
	_advance = _button(panel, "Yeni tankı onar", _enter_application, true)
	_advance.disabled = true
	_test_button = _button(panel, "Seçilen süreyi test et", _submit, true)
	_test_button.hide()
	var note := _label("Grafik altındaki alan L cinsinden hacimdir. Tank kapasitesi 36 L.", 12, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)


func _build_tank() -> void:
	var stage := find_child("TankPreview", true, false) as Control
	var model := stage.get_node("Viewport/World/Model") as Node3D
	# İnce cam duvarlar, tankın ölçeğini belirleyen sabit fiziksel hacim.
	_box(model, Vector3(-1.08, 1.32, 0), Vector3(0.07, 2.65, 1.20), Color(0.58, 0.83, 0.90, 0.28), true)
	_box(model, Vector3(1.08, 1.32, 0), Vector3(0.07, 2.65, 1.20), Color(0.58, 0.83, 0.90, 0.28), true)
	_box(model, Vector3(0, 1.32, -0.61), Vector3(2.19, 2.65, 0.07), Color(0.58, 0.83, 0.90, 0.25), true)
	_box(model, Vector3(0, 0.045, 0), Vector3(2.18, 0.10, 1.22), Color("#4c6a7f"))
	_box(model, Vector3(-0.88, 2.91, 0), Vector3(0.24, 0.54, 0.22), Color("#bac9d1"))
	_box(model, Vector3(-0.44, 2.66, 0), Vector3(1.03, 0.18, 0.22), Color("#bac9d1"))
	_water = _box(model, Vector3(0, 0.12, 0), Vector3(2.03, 2.45, 1.08), Color(0.25, 0.68, 0.82, 0.76), true)


func _box(parent: Node3D, pos: Vector3, dimensions: Vector3, tint: Color, glass: bool = false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.35 if glass else 0.64
	if glass:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _on_time_changed(value: float) -> void:
	if _phase == 1:
		_revealed = false
	_set_time(value)


func _set_time(value: float) -> void:
	_time = clampf(value, 0.0, 8.0)
	var visible_volume := Sim.volume_at(_time) if _revealed else 0.0
	var fraction := clampf(visible_volume / TANK_CAPACITY, 0.0, 1.0)
	if _water != null:
		_water.scale.y = maxf(fraction, 0.001)
		_water.position.y = 0.10 + 1.225 * fraction
	var flow := Sim.flow_at(_time)
	_readout.text = "T = %s s    q(T) = %s L/s\n%s" % [_number(_time), _number(flow),
		"Biriken: %s L%s" % [_number(Sim.volume_at(_time)), "  ·  TAŞMA" if Sim.volume_at(_time) > TANK_CAPACITY else ""] if _revealed else "Biriken hacmi görmek için ölçüm yap."]
	if _graph != null:
		_graph.queue_redraw()


func _observe(index: int) -> void:
	if _phase != 0:
		return
	_observed[index] = true
	_revealed = true
	_slider.value = 2.0 if index == 0 else 4.0
	_set_time(_slider.value)
	var actual := Sim.volume_at(_time)
	var broken := Sim.broken_volume_at(_time)
	_feedback.text = "%s s: alan %s L. Arızalı sayaç %s L diyor; çünkü yalnızca son debiyi kullanıyor." % [
		_number(_time), _number(actual), _number(broken)]
	_feedback.add_theme_color_override("font_color", MINT)
	_counter.text = "KANIT %d / 2" % (int(_observed[0]) + int(_observed[1]))
	_advance.disabled = not (_observed[0] and _observed[1])


func _enter_application() -> void:
	if _phase != 0 or not (_observed[0] and _observed[1]):
		return
	_phase = 1
	_instruction.text = "Kurtarma tankı tam 30 L almalı. q(t)=2+t ise akışı kaç saniye açık tutarsın?"
	_counter.text = "UYGULAMA / BAĞIMSIZ TAHMİN"
	_revealed = false
	_slider.value = 4.0
	_set_time(4.0)
	_feedback.text = "V(T) = ∫₀ᵀ (2+t) dt. Süreyi seç, sonra deneyi çalıştır."
	_feedback.add_theme_color_override("font_color", INK)
	for sample_button in _sample_buttons:
		sample_button.hide()
	_advance.hide()
	_test_button.show()


func _submit() -> void:
	if _phase != 1:
		return
	_revealed = true
	_set_time(_time)
	var actual := Sim.volume_at(_time)
	if absf(actual - TARGET_VOLUME) <= 0.5:
		_phase = 2
		_feedback.text = "ONARILDI  ·  6 saniyede 30 L. Anlık debi 8 L/s olsa da toplam hacim integralden gelir."
		_feedback.add_theme_color_override("font_color", MINT)
		_counter.text = "AKIŞ SİSTEMİ DÜZELTİLDİ"
		_instruction.text = "Debinin zamana göre toplamı, eğri altında biriken alandır."
		_test_button.disabled = true
		completed.emit()
	else:
		_feedback.text = "%s s'de %s L birikti; hedef 30 L. İntegrali hesaplayıp süreyi yeniden ayarla." % [
			_number(_time), _number(actual)]
		_feedback.add_theme_color_override("font_color", WRONG)


func _draw_graph() -> void:
	var width := _graph.size.x
	var height := _graph.size.y
	var rect := Rect2(46, 22, maxf(110.0, width - 70.0), maxf(85.0, height - 58.0))
	var font := ThemeDB.fallback_font
	_graph.draw_line(Vector2(rect.position.x, rect.end.y), rect.end, MUTED, 1.0)
	_graph.draw_line(Vector2(rect.position.x, rect.end.y), rect.position, MUTED, 1.0)
	_graph.draw_string(font, Vector2(rect.position.x + 5, 16), "q(t)  L/s", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)
	_graph.draw_string(font, Vector2(rect.end.x - 48, rect.end.y + 18), "t (s)", HORIZONTAL_ALIGNMENT_LEFT, 52, 12, MUTED)
	if _revealed and _time > 0.0:
		var area := PackedVector2Array()
		area.append(_graph_point(0.0, 0.0, rect))
		for i in range(33):
			var t := _time * float(i) / 32.0
			area.append(_graph_point(t, Sim.flow_at(t), rect))
		area.append(_graph_point(_time, 0.0, rect))
		_graph.draw_colored_polygon(area, Color(MINT, 0.19))
		var dt := _time / 8.0
		for i in range(8):
			var start_t := dt * float(i)
			var stop_t := dt * float(i + 1)
			var top := Sim.flow_at(start_t)
			_graph.draw_rect(Rect2(_graph_point(start_t, top, rect),
				Vector2(maxf(1.0, rect.size.x * dt / 8.0), rect.end.y - _graph_point(start_t, top, rect).y)),
				Color(BLUE, 0.12), true)
	var curve := PackedVector2Array()
	for i in range(65):
		var t := 8.0 * float(i) / 64.0
		curve.append(_graph_point(t, Sim.flow_at(t), rect))
	_graph.draw_polyline(curve, BLUE, 2.3, true)
	var marker := _graph_point(_time, Sim.flow_at(_time), rect)
	_graph.draw_circle(marker, 5.0, WARM)
	_graph.draw_string(font, Vector2(rect.position.x - 13, rect.end.y + 16), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)
	_graph.draw_string(font, Vector2(rect.end.x - 3, rect.end.y + 16), "8", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)


func _graph_point(time: float, flow: float, rect: Rect2) -> Vector2:
	return Vector2(rect.position.x + (time / 8.0) * rect.size.x,
		rect.end.y - (flow / 10.0) * rect.size.y)


func _number(value: float) -> String:
	return str(snappedf(value, 0.01)).replace(".", ",")


func _label(value: String, font_size: int, tint: Color, heading: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	if heading:
		label.theme_type_variation = "HeadlineLabel"
	return label


func _button(parent: Container, title: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 43
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
