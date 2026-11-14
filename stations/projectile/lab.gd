extends Control
## Scene presentation for the horizontal-launch asset set. The physics model remains
## in projectile_sim.gd; this script maps its state onto the illustrated 45 m range.

const ProjectileSim = preload("res://stations/projectile/projectile_sim.gd")
const BG := preload("res://stations/projectile/assets/range_bg.png")
const LAUNCHER := preload("res://stations/projectile/assets/launcher.png")
const BALL_LAUNCH := preload("res://stations/projectile/assets/ball_launch.png")
const BALL_DROP := preload("res://stations/projectile/assets/ball_drop.png")
const TARGET_OFF := preload("res://stations/projectile/assets/target_ring.png")
const TARGET_ON := preload("res://stations/projectile/assets/target_ring_on.png")

const HEIGHT_M := 45.0
const TARGET_M := 60.0
const PIXELS_PER_METER := 10.67
const MUZZLE := Vector2(310.0, 154.0)
const DROP_POINT := Vector2(365.0, 154.0)
const TARGET_CENTER := Vector2(963.0, 652.0)
const GROUND_Y := 652.0
const BALL_SIZE := Vector2(38.0, 38.0)

var speed_mps := 20.0
var flight_elapsed := 0.0
var is_running := false
var has_landed := false
var has_hit := false

var launch_ball: TextureRect
var drop_ball: TextureRect
var target_ring: TextureRect
var trajectory: Line2D
var drop_guide: Line2D
var speed_slider: HSlider
var speed_value: Label
var range_readout: Label
var time_readout: Label
var status_readout: Label
var launch_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_stage()
	_build_hud()
	_update_prediction()
	_reset_run()


func _process(delta: float) -> void:
	if not is_running:
		return
	flight_elapsed = minf(flight_elapsed + delta, ProjectileSim.fall_time(HEIGHT_M))
	var state: Dictionary = ProjectileSim.state_at(speed_mps, flight_elapsed)
	_place_center(launch_ball, MUZZLE + Vector2(state["x"], state["drop"]) * PIXELS_PER_METER)
	var dropped: Dictionary = ProjectileSim.state_at(0.0, flight_elapsed)
	_place_center(drop_ball, DROP_POINT + Vector2(dropped["x"], dropped["drop"]) * PIXELS_PER_METER)
	_update_live_readouts(state)
	if flight_elapsed >= ProjectileSim.fall_time(HEIGHT_M):
		_finish_run()


func _build_stage() -> void:
	var background := _texture_rect(BG, Vector2.ZERO, Vector2(1280, 720))
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.z_index = -20

	# The cutaway launcher sits on the rendered platform; keep the photograph visible around it.
	var launcher := _texture_rect(LAUNCHER, Vector2(57, 4), Vector2(390, 234))
	launcher.stretch_mode = TextureRect.STRETCH_SCALE
	launcher.z_index = -5

	target_ring = _texture_rect(TARGET_OFF, Vector2(868, 628), Vector2(190, 50))
	target_ring.stretch_mode = TextureRect.STRETCH_SCALE
	target_ring.z_index = 1

	trajectory = Line2D.new()
	trajectory.name = "Trajectory"
	trajectory.width = 2.0
	trajectory.default_color = Color("#6fe3c1", 0.64)
	trajectory.antialiased = true
	trajectory.z_index = 3
	add_child(trajectory)

	drop_guide = Line2D.new()
	drop_guide.name = "DropGuide"
	drop_guide.width = 1.0
	drop_guide.default_color = Color("#a7c8d2", 0.25)
	drop_guide.antialiased = true
	drop_guide.z_index = 2
	drop_guide.points = PackedVector2Array([DROP_POINT, Vector2(DROP_POINT.x, GROUND_Y)])
	add_child(drop_guide)

	launch_ball = _texture_rect(BALL_LAUNCH, Vector2.ZERO, BALL_SIZE)
	launch_ball.name = "LaunchedSphere"
	launch_ball.stretch_mode = TextureRect.STRETCH_SCALE
	launch_ball.z_index = 6

	drop_ball = _texture_rect(BALL_DROP, Vector2.ZERO, BALL_SIZE)
	drop_ball.name = "DroppedSphere"
	drop_ball.stretch_mode = TextureRect.STRETCH_SCALE
	drop_ball.z_index = 6


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "RangeConsole"
	panel.position = Vector2(823, 34)
	panel.size = Vector2(414, 510)
	panel.theme_type_variation = "GlassPanel"
	panel.z_index = 12
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	margin.add_child(stack)

	_add_label(stack, "BALLISTICS / 011.B", "SectionLabel")
	var title := _add_label(stack, "Yatay Atış", "HeadlineLabel")
	title.add_theme_font_size_override("font_size", 26)
	var intro := _add_label(stack, "İki kürenin düşüşü yatay hızdan etkilenir mi?", "MutedLabel")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.y = 39

	_add_label(stack, "DENEY KOŞULLARI", "SectionLabel")
	var conditions := HBoxContainer.new()
	conditions.add_theme_constant_override("separation", 8)
	stack.add_child(conditions)
	conditions.add_child(_fact_card("YÜKSEKLİK", "45 m"))
	conditions.add_child(_fact_card("HEDEF", "60 m"))

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	stack.add_child(speed_row)
	var speed_title := _add_label(speed_row, "Yatay başlangıç hızı", "Label")
	speed_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_value = _add_label(speed_row, "20 m/s", "SectionLabel")
	speed_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_slider = HSlider.new()
	speed_slider.min_value = 5.0
	speed_slider.max_value = 28.0
	speed_slider.step = 1.0
	speed_slider.value = speed_mps
	speed_slider.custom_minimum_size = Vector2(0, 24)
	speed_slider.value_changed.connect(_on_speed_changed)
	stack.add_child(speed_slider)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	stack.add_child(button_row)
	launch_button = Button.new()
	launch_button.text = "FIRLAT"
	launch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	launch_button.theme_type_variation = "PrimaryButton"
	launch_button.pressed.connect(_launch)
	button_row.add_child(launch_button)
	var reset_button := Button.new()
	reset_button.text = "SIFIRLA"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.pressed.connect(_reset_run)
	button_row.add_child(reset_button)

	stack.add_child(HSeparator.new())
	_add_label(stack, "ÖLÇÜM", "SectionLabel")
	var measure_row := HBoxContainer.new()
	measure_row.add_theme_constant_override("separation", 8)
	stack.add_child(measure_row)
	time_readout = _metric_card(measure_row, "DÜŞÜŞ SÜRESİ", "3,00 s")
	range_readout = _metric_card(measure_row, "YATAY MENZİL", "60,0 m")
	status_readout = _add_label(stack, "Hazır · hedef halkasını vurmak için hızı ayarla.", "MutedLabel")
	status_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_readout.custom_minimum_size.y = 38



func _fact_card(title: String, value: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = "ConsolePanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)
	_add_label(vbox, title, "SectionLabel")
	var value_label := _add_label(vbox, value, "HeadlineLabel")
	value_label.add_theme_font_size_override("font_size", 25)
	return card


func _metric_card(parent: Control, title: String, initial: String) -> Label:
	var card := PanelContainer.new()
	card.theme_type_variation = "ConsolePanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)
	_add_label(vbox, title, "SectionLabel")
	var value_label := _add_label(vbox, initial, "HeadlineLabel")
	value_label.add_theme_font_size_override("font_size", 25)
	return value_label


func _add_label(parent: Control, content: String, variation: String) -> Label:
	var label := Label.new()
	label.text = content
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


func _texture_rect(texture: Texture2D, at: Vector2, dimensions: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.position = at
	rect.size = dimensions
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _on_speed_changed(value: float) -> void:
	speed_mps = value
	speed_value.text = "%.0f m/s" % value
	_update_prediction()
	if not is_running:
		_reset_run()


func _update_prediction() -> void:
	if range_readout != null:
		range_readout.text = _decimal(ProjectileSim.range_for(HEIGHT_M, speed_mps), 1) + " m"
	if trajectory == null:
		return
	trajectory.clear_points()
	var total_time := ProjectileSim.fall_time(HEIGHT_M)
	for sample in range(41):
		var t := total_time * float(sample) / 40.0
		var state: Dictionary = ProjectileSim.state_at(speed_mps, t)
		trajectory.add_point(MUZZLE + Vector2(state["x"], state["drop"]) * PIXELS_PER_METER)
	trajectory.default_color = Color("#6fe3c1", 0.22 if not is_running else 0.72)


func _update_live_readouts(state: Dictionary) -> void:
	time_readout.text = _decimal(flight_elapsed, 2) + " s"
	range_readout.text = _decimal(float(state["x"]), 1) + " m"


func _launch() -> void:
	if is_running:
		return
	_reset_run()
	is_running = true
	has_landed = false
	has_hit = false
	trajectory.default_color = Color("#6fe3c1", 0.78)
	status_readout.text = "Ölçülüyor · iki kürenin düşüşü eşzamanlı başladı."
	launch_button.disabled = true


func _finish_run() -> void:
	if has_landed:
		return
	is_running = false
	has_landed = true
	var predicted_range: float = ProjectileSim.range_for(HEIGHT_M, speed_mps)
	has_hit = absf(predicted_range - TARGET_M) <= 3.0
	target_ring.texture = TARGET_ON if has_hit else TARGET_OFF
	launch_button.disabled = false
	time_readout.text = _decimal(ProjectileSim.fall_time(HEIGHT_M), 2) + " s"
	range_readout.text = _decimal(predicted_range, 1) + " m"
	if has_hit:
		status_readout.text = "Hedef vuruldu · yatay hız menzili değiştirdi, düşüş süresi aynı kaldı."
	else:
		status_readout.text = "Hedefin %s m %s · düşüş süresi yatay hızdan bağımsız kaldı." % [_decimal(absf(predicted_range - TARGET_M), 1), "ötesinde" if predicted_range > TARGET_M else "gerisinde"]
	trajectory.default_color = Color("#6fe3c1", 0.46) if has_hit else Color("#ffad81", 0.48)


func _reset_run() -> void:
	is_running = false
	has_landed = false
	has_hit = false
	flight_elapsed = 0.0
	if launch_ball != null:
		_place_center(launch_ball, MUZZLE)
	if drop_ball != null:
		_place_center(drop_ball, DROP_POINT)
	if target_ring != null:
		target_ring.texture = TARGET_OFF
	if launch_button != null:
		launch_button.disabled = false
	if status_readout != null:
		status_readout.text = "Hazır · hedef halkasını vurmak için hızı ayarla."
	if time_readout != null:
		time_readout.text = _decimal(ProjectileSim.fall_time(HEIGHT_M), 2) + " s"
	if range_readout != null:
		range_readout.text = _decimal(ProjectileSim.range_for(HEIGHT_M, speed_mps), 1) + " m"
	_update_prediction()


func _place_center(rect: TextureRect, center: Vector2) -> void:
	rect.position = center - rect.size * 0.5


func _decimal(value: float, digits: int) -> String:
	var out := ("%%.%df" % digits) % value
	return out.replace(".", ",")


# Used by the capture script to produce a finished, still-readable mission frame.
func capture_finished_state(test_speed: float) -> void:
	if speed_slider != null:
		speed_slider.set_value_no_signal(test_speed)
	speed_mps = test_speed
	speed_value.text = "%.0f m/s" % test_speed
	_update_prediction()
	_launch()
	flight_elapsed = ProjectileSim.fall_time(HEIGHT_M)
	var launch_state: Dictionary = ProjectileSim.state_at(speed_mps, flight_elapsed)
	_place_center(launch_ball, MUZZLE + Vector2(launch_state["x"], launch_state["drop"]) * PIXELS_PER_METER)
	var drop_state: Dictionary = ProjectileSim.state_at(0.0, flight_elapsed)
	_place_center(drop_ball, DROP_POINT + Vector2(drop_state["x"], drop_state["drop"]) * PIXELS_PER_METER)
	_finish_run()
