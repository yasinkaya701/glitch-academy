extends Control

const NewtonSim = preload("res://stations/newton/newton_sim.gd")
const DISTANCE_M := 40.0
const START_X := 178.0
const FINISH_X := 785.0
const SLED_Y := 242.0
const SLED_SIZE := Vector2(346.0, 173.0)

const BG_PATH := "res://stations/newton/assets/rail_bg.png"
const SLED_LIGHT := "res://stations/newton/assets/sled_light.png"
const SLED_HEAVY := "res://stations/newton/assets/sled_heavy.png"
const THRUSTER := "res://stations/newton/assets/thruster_glow.png"
const GATE_CLOSED := "res://stations/newton/assets/finish_gate_closed.png"
const GATE_OPEN := "res://stations/newton/assets/finish_gate_open.png"

const INK := Color("#e8f1f2")
const MUTED := Color("#adc1c4")
const MINT := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const PANEL := Color("#0b1420", 0.94)
const EDGE := Color("#48606b", 0.82)

var background: TextureRect
var sled: TextureRect
var thruster: TextureRect
var finish_gate: TextureRect
var force_slider: HSlider
var force_value: Label
var mass_picker: OptionButton
var run_button: Button
var reset_button: Button
var comparison: Label
var result: Label
var progress_label: Label

var running := false
var elapsed := 0.0
var duration := 0.0
var active_force := 4.0
var active_mass := 1.0
var active_acceleration := 0.0
var active_time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_experiment()
	_build_interface()
	_update_comparison()
	_reset_run()


func _process(delta: float) -> void:
	if not running:
		return
	elapsed = minf(elapsed + delta, duration)
	var state: Dictionary = NewtonSim.state_at(active_acceleration, elapsed)
	var progress := clampf(float(state.position) / DISTANCE_M, 0.0, 1.0)
	sled.position.x = lerpf(START_X, FINISH_X, progress)
	progress_label.text = "%s m   ·   %s m/s" % [_number(float(state.position)), _number(float(state.speed))]
	thruster.modulate.a = 0.58 + 0.30 * sin(elapsed * 17.0)
	if elapsed >= duration:
		running = false
		thruster.hide()
		finish_gate.texture = load(GATE_OPEN)
		progress_label.text = "40,0 m   ·   Varış çizgisine ulaştı"
		result.text = "%s kg kızak  ·  a = %s m/s²  ·  t = %s s" % [_number(active_mass), _number(active_acceleration), _number(active_time)]
		result.add_theme_color_override("font_color", MINT)
		run_button.disabled = false
		force_slider.editable = true
		mass_picker.disabled = false
		reset_button.disabled = false


func _build_experiment() -> void:
	background = TextureRect.new()
	background.name = "RailLaboratory"
	background.texture = load(BG_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

	# Sensor gate is a separate game object; the matching cyan finish line remains in the backdrop.
	finish_gate = TextureRect.new()
	finish_gate.name = "FinishGate"
	finish_gate.texture = load(GATE_CLOSED)
	finish_gate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	finish_gate.stretch_mode = TextureRect.STRETCH_SCALE
	finish_gate.position = Vector2(760.0, 222.0)
	finish_gate.size = Vector2(198.0, 198.0)
	finish_gate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(finish_gate)

	thruster = TextureRect.new()
	thruster.name = "ImpulseGlow"
	thruster.texture = load(THRUSTER)
	thruster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thruster.stretch_mode = TextureRect.STRETCH_SCALE
	thruster.size = SLED_SIZE
	thruster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thruster.hide()
	add_child(thruster)

	sled = TextureRect.new()
	sled.name = "NewtonSled"
	sled.texture = load(SLED_LIGHT)
	sled.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sled.stretch_mode = TextureRect.STRETCH_SCALE
	sled.position = Vector2(START_X, SLED_Y)
	sled.size = SLED_SIZE
	sled.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sled)
	move_child(thruster, get_child_count() - 1)
	_update_sled_variant()


func _build_interface() -> void:
	var section := _label("NEWTON  /  AIR-TRACK LAB", 13, AMBER)
	section.position = Vector2(52, 35)
	section.size = Vector2(600, 22)
	section.add_theme_font_size_override("font_size", 13)
	section.add_theme_color_override("font_color", AMBER)
	section.theme_type_variation = "SectionLabel"
	add_child(section)

	var title := _label("Aynı itiş, farklı hızlanma", 30, INK)
	title.position = Vector2(52, 59)
	title.size = Vector2(620, 45)
	title.add_theme_font_size_override("font_size", 30)
	title.theme_type_variation = "HeadlineLabel"
	add_child(title)

	var subtitle := _label("40 m hava rayında aynı kuvveti hafif ve yüklü kızakta dene.", 16, MUTED)
	subtitle.position = Vector2(54, 108)
	subtitle.size = Vector2(620, 28)
	subtitle.add_theme_font_size_override("font_size", 16)
	add_child(subtitle)

	var panel := PanelContainer.new()
	panel.name = "ExperimentConsole"
	panel.position = Vector2(930, 38)
	panel.size = Vector2(320, 626)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, EDGE, 12, 18))
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var heading := _label("RUN CONTROL   /   01", 12, MINT)
	heading.add_theme_font_size_override("font_size", 12)
	content.add_child(heading)
	var panel_title := _label("İtişi ayarla", 23, INK)
	panel_title.add_theme_font_size_override("font_size", 23)
	content.add_child(panel_title)
	var hint := _label("Kütle değişsin; uygulanan kuvvet aynı kalsın.", 14, MUTED)
	hint.add_theme_font_size_override("font_size", 14)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var force_row := HBoxContainer.new()
	force_row.add_theme_constant_override("separation", 6)
	var force_title := _label("İtiş kuvveti", 15, INK)
	force_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	force_row.add_child(force_title)
	force_value = _label("4 N", 15, AMBER)
	force_row.add_child(force_value)
	content.add_child(force_row)

	force_slider = HSlider.new()
	force_slider.min_value = 2.0
	force_slider.max_value = 8.0
	force_slider.step = 1.0
	force_slider.value = 4.0
	force_slider.custom_minimum_size = Vector2(0, 28)
	force_slider.value_changed.connect(_on_force_changed)
	content.add_child(force_slider)

	var mass_title := _label("Kızak kütlesi", 15, INK)
	content.add_child(mass_title)
	mass_picker = OptionButton.new()
	mass_picker.add_item("Hafif kızak · 1 kg", 0)
	mass_picker.add_item("Yüklü kızak · 4 kg", 1)
	mass_picker.select(0)
	mass_picker.item_selected.connect(_on_mass_selected)
	content.add_child(mass_picker)

	var run_row := HBoxContainer.new()
	run_row.add_theme_constant_override("separation", 8)
	run_button = Button.new()
	run_button.name = "RunButton"
	run_button.text = "Kızağı çalıştır"
	run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_button.theme_type_variation = "PrimaryButton"
	run_button.pressed.connect(_start_run)
	run_row.add_child(run_button)
	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "Sıfırla"
	reset_button.pressed.connect(_reset_run)
	run_row.add_child(reset_button)
	content.add_child(run_row)

	progress_label = _label("Kızak hazır · 0,0 m", 14, MUTED)
	progress_label.custom_minimum_size = Vector2(0, 28)
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(progress_label)
	result = _label("Bir koşu başlatıp sonucu kaydet.", 14, AMBER)
	result.custom_minimum_size = Vector2(0, 45)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(result)

	var divider := HSeparator.new()
	content.add_child(divider)
	var compare_title := _label("AYNI KUVVETTE KARŞILAŞTIR", 12, MINT)
	compare_title.add_theme_font_size_override("font_size", 12)
	content.add_child(compare_title)
	comparison = _label("", 14, INK)
	comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison.custom_minimum_size = Vector2(0, 94)
	content.add_child(comparison)

	var law := _label("a = F / m", 22, AMBER)
	law.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	law.add_theme_font_size_override("font_size", 22)
	content.add_child(law)
	var explanation := _label("Kütle arttıkça, aynı kuvvetin oluşturduğu ivme azalır.", 14, MUTED)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)


func _on_force_changed(value: float) -> void:
	force_value.text = "%d N" % int(value)
	_update_comparison()
	if not running:
		result.text = "Kuvvet ayarlandı. İki kızağı aynı koşulda karşılaştır."
		result.add_theme_color_override("font_color", AMBER)


func _on_mass_selected(_index: int) -> void:
	_update_sled_variant()
	_reset_run()
	_update_comparison()


func _update_sled_variant() -> void:
	if sled == null:
		return
	var heavy := mass_picker != null and mass_picker.selected == 1
	sled.texture = load(SLED_HEAVY if heavy else SLED_LIGHT)
	if thruster != null:
		thruster.position = Vector2(sled.position.x - 21.0, sled.position.y)


func _update_comparison() -> void:
	if comparison == null or force_slider == null:
		return
	var force := force_slider.value
	var light_a := NewtonSim.acceleration(force, 1.0)
	var heavy_a := NewtonSim.acceleration(force, 4.0)
	var light_t := NewtonSim.time_to_cover(DISTANCE_M, light_a)
	var heavy_t := NewtonSim.time_to_cover(DISTANCE_M, heavy_a)
	comparison.text = "1 kg  ·  %s m/s²  ·  %s s\n4 kg  ·  %s m/s²  ·  %s s" % [_number(light_a), _number(light_t), _number(heavy_a), _number(heavy_t)]


func _start_run() -> void:
	if running:
		return
	active_force = force_slider.value
	active_mass = 1.0 if mass_picker.selected == 0 else 4.0
	active_acceleration = NewtonSim.acceleration(active_force, active_mass)
	active_time = NewtonSim.time_to_cover(DISTANCE_M, active_acceleration)
	duration = active_time
	elapsed = 0.0
	running = true
	sled.position.x = START_X
	thruster.position = Vector2(START_X - 21.0, SLED_Y)
	thruster.modulate.a = 0.85
	thruster.show()
	finish_gate.texture = load(GATE_CLOSED)
	progress_label.text = "Kızak hareket ediyor · 0,0 m"
	result.text = "F = %s N   /   m = %s kg" % [_number(active_force), _number(active_mass)]
	result.add_theme_color_override("font_color", AMBER)
	run_button.disabled = true
	force_slider.editable = false
	mass_picker.disabled = true
	reset_button.disabled = false


func _reset_run() -> void:
	running = false
	elapsed = 0.0
	if sled != null:
		sled.position.x = START_X
	if thruster != null:
		thruster.hide()
	if finish_gate != null:
		finish_gate.texture = load(GATE_CLOSED)
	if progress_label != null:
		progress_label.text = "Kızak hazır · 0,0 m"
	if result != null:
		result.text = "Bir koşu başlatıp sonucu kaydet."
		result.add_theme_color_override("font_color", AMBER)
	if run_button != null:
		run_button.disabled = false
	if force_slider != null:
		force_slider.editable = true
	if mass_picker != null:
		mass_picker.disabled = false
	if reset_button != null:
		reset_button.disabled = false


func _number(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text_value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


func _panel_style(fill: Color, border: Color, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
