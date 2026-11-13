extends "res://scripts/mission.gd"
## LGS simple-machines experiment: students repair acceleration labels sabotaged by MERİDYEN.

const ACCELERATIONS := ["a", "2a"]
const EXPERIMENT_3D := preload("res://scenes/experiment_3d.tscn")
const BG := Color("#09131e")
const TEXT := Color("#eef4f6")
const MUTED := Color("#a7bbc5")
const TEAL := Color("#6dd3c5")
const AMBER := Color("#f0bd70")
const RED := Color("#f17d72")

var _mode := 0 # 0: fixed pulley, 1: single movable pulley
var _stage := 0
var _load_choice := 1
var _rope_choice := 0
var _motion_time := 0.0
var _running := true
var _solved := false

var _viewport: SubViewport
var _experiment_view: Control
var _world: Node3D
var _camera: Camera3D
var _rig: Node3D
var _load_group: Node3D
var _free_end: Node3D
var _lower_pulley: Node3D
var _upper_pulley: Node3D
var _moving_link: MeshInstance3D
var _rope_segments: Array[MeshInstance3D] = []
var _load_choice_button: Button
var _rope_choice_button: Button
var _rule_label: Label
var _mode_buttons: Array[Button] = []
var _stage_label: Label
var _fault_label: Label
var _fault_panel: PanelContainer
var _feedback: Label
var _hint: Label
var _run_button: Button
var _repair_button: Button
var _interaction_label: Label
var _dragging_rig := false
var _dragging_rope := false
var _last_pointer := Vector2.ZERO


func _ready() -> void:
	_build_interface()
	_build_world()
	_update_interface()


func _process(delta: float) -> void:
	if not _running:
		return
	_motion_time += delta
	_update_motion()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 2)
	header.add_child(title_stack)
	var eyebrow := _label("LGS FEN  ·  BASİT MAKİNELER", 13, TEAL)
	title_stack.add_child(eyebrow)
	title_stack.add_child(_label("Palanga Atölyesi", 29, TEXT, true))
	var exit_button := _button("←  Kontrol merkezine dön", false)
	exit_button.pressed.connect(_request_exit)
	header.add_child(exit_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	layout.add_child(content)

	var visual_column := VBoxContainer.new()
	visual_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_column.add_theme_constant_override("separation", 10)
	content.add_child(visual_column)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	visual_column.add_child(mode_row)
	_mode_buttons = [
		_button("01  Sabit makara", true),
		_button("02  Hareketli makara", true),
	]
	for i in range(_mode_buttons.size()):
		_mode_buttons[i].pressed.connect(_select_mode.bind(i))
		mode_row.add_child(_mode_buttons[i])

	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", _panel_style(Color("#172633"), Color("#314958"), 1, 14))
	visual_column.add_child(frame)
	var experiment_view: Control = EXPERIMENT_3D.instantiate()
	experiment_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	experiment_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_experiment_view = experiment_view
	_experiment_view.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_experiment_view.gui_input.connect(_on_experiment_gui_input)
	frame.add_child(_experiment_view)
	_viewport = _experiment_view.get_node("Viewport") as SubViewport
	_viewport.msaa_3d = Viewport.MSAA_4X
	_world = experiment_view.get_node("Viewport/World") as Node3D

	var visual_footer := HBoxContainer.new()
	visual_footer.add_theme_constant_override("separation", 10)
	visual_column.add_child(visual_footer)
	_interaction_label = _label("Halat ucunu çek · Boş alandan döndür · Tekerlekle yakınlaş", 14, MUTED)
	_interaction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_footer.add_child(_interaction_label)
	_run_button = _button("Ⅱ  Durdur", false)
	_run_button.pressed.connect(_toggle_motion)
	visual_footer.add_child(_run_button)

	var lesson := PanelContainer.new()
	lesson.custom_minimum_size.x = 365
	lesson.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson.add_theme_stylebox_override("panel", _panel_style(Color("#101e2b"), Color("#253b4b"), 1, 14))
	content.add_child(lesson)
	var lesson_margin := MarginContainer.new()
	lesson_margin.add_theme_constant_override("margin_left", 19)
	lesson_margin.add_theme_constant_override("margin_right", 19)
	lesson_margin.add_theme_constant_override("margin_top", 18)
	lesson_margin.add_theme_constant_override("margin_bottom", 18)
	lesson.add_child(lesson_margin)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 11)
	lesson_margin.add_child(panel)
	_stage_label = _label("GÖZLEM 01 / 02", 12, AMBER)
	panel.add_child(_stage_label)
	var intro := _label("İdeal ipte ivme ilişkisini karşılaştır. Hareketli makara yükü iki ip parçasıyla taşır.", 15, TEXT)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(intro)
	var rule_box := PanelContainer.new()
	rule_box.add_theme_stylebox_override("panel", _panel_style(Color("#102d32"), Color("#2f7774"), 1, 10))
	panel.add_child(rule_box)
	var rule_margin := MarginContainer.new()
	rule_margin.add_theme_constant_override("margin_left", 12)
	rule_margin.add_theme_constant_override("margin_right", 12)
	rule_margin.add_theme_constant_override("margin_top", 10)
	rule_margin.add_theme_constant_override("margin_bottom", 10)
	rule_box.add_child(rule_margin)
	_rule_label = _label("SABİT MAKARA\na_yük = a_ip\n0,5 = 0,5 m/s²", 15, TEAL, true)
	_rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_margin.add_child(_rule_label)
	var fault_title := _label("MERİDYEN'İN BOZDUĞU KAYIT", 11, RED)
	panel.add_child(fault_title)
	_fault_panel = PanelContainer.new()
	_fault_panel.add_theme_stylebox_override("panel", _panel_style(Color("#351e25"), Color("#914e51"), 1, 9))
	panel.add_child(_fault_panel)
	var fault_margin := MarginContainer.new()
	fault_margin.add_theme_constant_override("margin_left", 12)
	fault_margin.add_theme_constant_override("margin_right", 12)
	fault_margin.add_theme_constant_override("margin_top", 9)
	fault_margin.add_theme_constant_override("margin_bottom", 9)
	_fault_panel.add_child(fault_margin)
	_fault_label = _label("Yük ivmesi: 2a     İp ucu: a", 15, TEXT, true)
	fault_margin.add_child(_fault_label)
	panel.add_child(_label("Düzeneğe uygun ivmeleri seç:", 14, MUTED))
	_load_choice_button = _button("Yük ivmesi  ·  2a", false)
	_load_choice_button.pressed.connect(_cycle_load_choice)
	panel.add_child(_load_choice_button)
	_rope_choice_button = _button("İp ucu ivmesi  ·  a", false)
	_rope_choice_button.pressed.connect(_cycle_rope_choice)
	panel.add_child(_rope_choice_button)
	_repair_button = _button("Fizik kuralını onar  →", true)
	_repair_button.pressed.connect(_repair_rule)
	panel.add_child(_repair_button)
	_feedback = _label("İp parçası sayısını ve hareket yönlerini gözlemle.", 14, MUTED)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_feedback)
	_hint = _label("İdeal düzende ip esnemez ve kaymaz; toplam ip uzunluğu sabittir.", 12, MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_hint)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)
	panel.add_child(_label("Yönü değiştiren sabit makara kuvvet kazancı sağlamaz. Hareketli makarada iki ip kolu yükü taşır.", 12, MUTED))


func _build_world() -> void:
	var environment := _world.get_node("WorldEnvironment") as WorldEnvironment
	var env := environment.environment.duplicate(true) as Environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#263742")
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#263742")
	sky_material.sky_horizon_color = Color("#344854")
	sky_material.ground_bottom_color = Color("#19272f")
	sky_material.ground_horizon_color = Color("#263742")
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a9c5d0")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.18
	environment.environment = env
	_camera = _world.get_node("Camera3D") as Camera3D
	_camera.position = Vector3(4.8, 3.8, 8.6)
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 38
	_camera.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
	_camera.current = true
	_build_workshop_environment()
	_rig = Node3D.new()
	_rig.name = "PalangaRig"
	_world.get_node("Model").add_child(_rig)
	_build_rig()


func _build_workshop_environment() -> void:
	var wall := _material(Color("#263742"), 0.02, 0.92)
	var wall_panel := _material(Color("#344854"), 0.04, 0.78)
	var dark_panel := _material(Color("#1d2a32"), 0.16, 0.66)
	var warm_trim := _material(Color("#bd8e54"), 0.62, 0.36)
	var bench_top := _material(Color("#51463b"), 0.08, 0.72)
	var bench_edge := _material(Color("#27333a"), 0.48, 0.48)
	var soft_light := _material(Color("#ffd5a0"), 0.0, 0.4)
	soft_light.emission_enabled = true
	soft_light.emission = Color("#ffd5a0")
	soft_light.emission_energy_multiplier = 1.35
	var ground := _material(Color("#17232a"), 0.08, 0.9)

	# A continuous work surface carries the model plinth; the legs and drawer fronts
	# extend below it so the apparatus reads as part of a real laboratory bench.
	_add_box(_world, Vector3(0.0, -0.33, -0.15), Vector3(7.5, 0.28, 6.0), bench_top)
	_add_box(_world, Vector3(0.0, -0.50, 2.68), Vector3(7.18, 0.08, 0.16), bench_edge)
	_add_box(_world, Vector3(0.0, -0.50, -2.98), Vector3(7.18, 0.08, 0.16), bench_edge)
	for x in [-3.38, 3.38]:
		for z in [-2.66, 2.48]:
			_add_box(_world, Vector3(x, -1.22, z), Vector3(0.17, 1.44, 0.17), bench_edge)
			_add_box(_world, Vector3(x, -1.84, z), Vector3(0.25, 0.10, 0.25), warm_trim)
	for x in [-2.15, 0.0, 2.15]:
		_add_box(_world, Vector3(x, -0.88, 2.58), Vector3(1.86, 0.48, 0.07), dark_panel)
		_add_box(_world, Vector3(x, -0.77, 2.535), Vector3(0.52, 0.045, 0.035), warm_trim)
		_add_cylinder(_world, Vector3(x, -0.77, 2.50), 0.035, 0.06, warm_trim, Vector3(90, 0, 0), 20)
	var floor := _add_box(_world, Vector3(0.0, -1.93, 0.0), Vector3(36.0, 0.12, 36.0), ground)
	floor.name = "WorkshopFloor"

	# The back wall, tool boards, and lighting stay fixed as the pulley rig rotates.
	_add_box(_world, Vector3(0.0, 2.03, -3.56), Vector3(24.0, 7.8, 0.24), wall)
	_add_box(_world, Vector3(0.0, 2.03, -3.76), Vector3(40.0, 10.0, 0.18), wall)
	_add_box(_world, Vector3(0.0, 4.70, -3.40), Vector3(8.8, 0.12, 0.18), bench_edge)
	for side in [-1.0, 1.0]:
		var board_x: float = side * 3.05
		_add_box(_world, Vector3(board_x, 2.45, -3.405), Vector3(1.62, 3.7, 0.08), wall_panel)
		for row in range(9):
			for column in range(4):
				_add_sphere(_world, Vector3(board_x - 0.48 + column * 0.32, 0.95 + row * 0.36, -3.345), 0.026, dark_panel)
		for rail_y in [0.62, 4.28]:
			_add_box(_world, Vector3(board_x, rail_y, -3.34), Vector3(1.72, 0.055, 0.07), warm_trim)
	# Slim utility shelves and a warm task light tie the background to the bench.
	for side in [-1.0, 1.0]:
		_add_box(_world, Vector3(side * 3.25, 4.02, -3.02), Vector3(1.75, 0.09, 0.62), bench_edge)
		_add_box(_world, Vector3(side * 3.25, 3.94, -2.74), Vector3(1.48, 0.035, 0.035), warm_trim)
	_add_box(_world, Vector3(0.0, 4.58, -3.25), Vector3(4.8, 0.055, 0.075), soft_light)
	var task_light := OmniLight3D.new()
	task_light.position = Vector3(0.0, 4.45, -2.85)
	task_light.light_color = Color("ffd19a")
	task_light.light_energy = 1.3
	task_light.omni_range = 9.0
	_world.add_child(task_light)
	var key := SpotLight3D.new()
	key.position = Vector3(-0.5, 5.8, 3.6)
	key.light_color = Color("fff0da")
	key.light_energy = 2.2
	key.spot_range = 11.0
	key.spot_angle = 48.0
	key.shadow_enabled = true
	_world.add_child(key)
	key.look_at(Vector3(0.0, 1.5, 0.0), Vector3.UP)


func _build_rig() -> void:
	for child in _rig.get_children():
		child.queue_free()
	_rope_segments.clear()
	var steel := _material(Color("#81939d"), 0.82, 0.26)
	var dark_steel := _material(Color("#293b49"), 0.86, 0.31)
	var blue := _material(Color("#2c7890"), 0.78, 0.24)
	var brass := _material(Color("#d2a256"), 0.8, 0.23)
	var rope_mat := _material(Color("#d6d2c2"), 0.86, 0.12)
	var rubber := _material(Color("#17222b"), 0.15, 0.58)
	_add_box(_rig, Vector3(0, 3.92, 0), Vector3(3.25, 0.16, 0.28), steel)
	_add_box(_rig, Vector3(-1.48, 2.0, 0), Vector3(0.16, 4.0, 0.28), dark_steel)
	_add_box(_rig, Vector3(1.48, 2.0, 0), Vector3(0.16, 4.0, 0.28), dark_steel)
	_add_box(_rig, Vector3(0, 0.12, 0), Vector3(3.3, 0.18, 0.36), steel)
	for x in [-1.48, 1.48]:
		for y in [0.28, 3.72]:
			_add_cylinder(_rig, Vector3(x, y, 0.18), 0.055, 0.035, brass, Vector3(90, 0, 0))
	_add_box(_rig, Vector3(0, 3.78, 0), Vector3(0.92, 0.20, 0.22), blue)
	_add_box(_rig, Vector3(0, 3.61, 0), Vector3(0.22, 0.16, 0.18), brass)
	_add_box(_rig, Vector3(0, 0.27, 0), Vector3(1.04, 0.09, 0.40), rubber)

	_upper_pulley = Node3D.new()
	_upper_pulley.position = Vector3(0.18, 3.28, 0)
	_rig.add_child(_upper_pulley)
	_add_sheave(_upper_pulley, blue, steel, brass)
	for z in [-0.24, 0.24]:
		_rig.add_child(_beam(Vector3(-0.03, 3.78, z), Vector3(0.18, 3.38, z), 0.035, Color("#aebdc0")))
		_rig.add_child(_beam(Vector3(0.39, 3.78, z), Vector3(0.18, 3.38, z), 0.035, Color("#aebdc0")))
	_lower_pulley = Node3D.new()
	_lower_pulley.position = Vector3(-0.35, 1.72, 0.04)
	_rig.add_child(_lower_pulley)
	_add_sheave(_lower_pulley, blue, steel, brass)
	for z in [-0.25, 0.25]:
		_lower_pulley.add_child(_beam(Vector3(0.0, 0.42, z), Vector3(0.0, -0.48, z), 0.028, Color("#c0c9c3")))
		_add_cylinder(_lower_pulley, Vector3(0.0, 0.44, z), 0.045, 0.035, brass, Vector3(90, 0, 0), 20)
		_add_cylinder(_lower_pulley, Vector3(0.0, -0.48, z), 0.045, 0.035, brass, Vector3(90, 0, 0), 20)

	_load_group = Node3D.new()
	_load_group.name = "LoadAndHook"
	_rig.add_child(_load_group)
	_add_load(_load_group, rubber, brass, steel)
	_free_end = Node3D.new()
	_free_end.name = "FreeEndWeight"
	_rig.add_child(_free_end)
	_add_cylinder(_free_end, Vector3.ZERO, 0.085, 0.24, brass)
	_add_cylinder(_free_end, Vector3(0, -0.16, 0), 0.05, 0.10, steel)
	_add_torus(_free_end, Vector3(0, -0.28, 0), 0.09, 0.02, brass)
	_moving_link = MeshInstance3D.new()
	_moving_link.name = "MovingPulleyLink"
	var link_mesh := CylinderMesh.new()
	link_mesh.top_radius = 0.035
	link_mesh.bottom_radius = 0.035
	link_mesh.height = 1.0
	_moving_link.mesh = link_mesh
	_moving_link.material_override = steel
	_rig.add_child(_moving_link)
	for i in range(4):
		var segment := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.025
		mesh.bottom_radius = 0.025
		mesh.height = 1.0
		mesh.radial_segments = 12
		segment.mesh = mesh
		segment.material_override = rope_mat
		_rig.add_child(segment)
		_rope_segments.append(segment)
	_add_measurement_marks(steel, brass)
	_update_motion()


func _add_sheave(parent: Node3D, face: Material, rim: Material, hub: Material) -> void:
	_add_cylinder(parent, Vector3.ZERO, 0.42, 0.16, face, Vector3(90, 0, 0), 64)
	_add_torus(parent, Vector3(0, 0, 0.094), 0.36, 0.045, rim)
	_add_torus(parent, Vector3(0, 0, -0.094), 0.36, 0.045, rim)
	var groove := _material(Color("#18252c"), 0.62, 0.42)
	_add_torus(parent, Vector3.ZERO, 0.355, 0.018, groove)
	var face_trim := _material(Color("#bbc3bd"), 0.44, 0.48)
	_add_torus(parent, Vector3(0, 0, 0.09), 0.285, 0.014, face_trim)
	_add_torus(parent, Vector3(0, 0, -0.09), 0.285, 0.014, face_trim)
	var spoke_material := _material(Color("#c9d1cb"), 0.48, 0.42)
	for z in [-0.091, 0.091]:
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var spoke := _add_box(parent, Vector3(cos(angle) * 0.205, sin(angle) * 0.205, z), Vector3(0.26, 0.038, 0.025), spoke_material)
			spoke.rotation.z = angle
	_add_cylinder(parent, Vector3(0, 0, 0.12), 0.125, 0.10, hub, Vector3(90, 0, 0), 48)
	_add_cylinder(parent, Vector3(0, 0, -0.12), 0.125, 0.10, hub, Vector3(90, 0, 0), 48)
	_add_torus(parent, Vector3(0, 0, 0.177), 0.105, 0.015, face_trim)
	_add_torus(parent, Vector3(0, 0, -0.177), 0.105, 0.015, face_trim)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		for side in [-1.0, 1.0]:
			_add_cylinder(parent, Vector3(cos(angle) * 0.25, sin(angle) * 0.25, side * 0.112), 0.022, 0.028, hub, Vector3(90, 0, 0), 16)


func _on_experiment_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.double_click:
				_rig.rotation = Vector3.ZERO
				_dragging_rig = false
				_dragging_rope = false
				return
			if mouse_button.pressed:
				_begin_pointer_interaction(mouse_button.position)
			else:
				_dragging_rig = false
				_dragging_rope = false
			_last_pointer = mouse_button.position
			return
		if mouse_button.pressed and mouse_button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_camera.fov = clampf(_camera.fov + (-2.0 if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP else 2.0), 28.0, 50.0)
			return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if not _dragging_rig and not _dragging_rope:
			_experiment_view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _pointer_hits_rope_end(motion.position) else Control.CURSOR_MOVE
			return
		var pointer_delta := motion.position - _last_pointer
		_last_pointer = motion.position
		if _dragging_rope:
			_pull_rope(pointer_delta)
		else:
			_rig.rotation.y -= pointer_delta.x * 0.009
			_rig.rotation.x = clampf(_rig.rotation.x - pointer_delta.y * 0.006, -0.75, 0.75)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_pointer_interaction(touch.position)
		else:
			_dragging_rig = false
			_dragging_rope = false
		_last_pointer = touch.position
	if event is InputEventScreenDrag and _dragging_rig:
		var drag := event as InputEventScreenDrag
		_rig.rotation.y -= drag.relative.x * 0.009
		_rig.rotation.x = clampf(_rig.rotation.x - drag.relative.y * 0.006, -0.75, 0.75)
	if event is InputEventScreenDrag and _dragging_rope:
		var drag := event as InputEventScreenDrag
		_pull_rope(drag.relative)


func _begin_pointer_interaction(pointer: Vector2) -> void:
	_dragging_rope = _pointer_hits_rope_end(pointer)
	_dragging_rig = not _dragging_rope
	_last_pointer = pointer
	if _dragging_rope:
		_running = false
		_run_button.text = "▶  Başlat"
		_interaction_label.text = "Halat çekiliyor · Yükün hareketini gözlemle"


func _viewport_pointer(pointer: Vector2) -> Vector2:
	var view_size := _experiment_view.size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return Vector2.ZERO
	return pointer * Vector2(_viewport.size) / view_size


func _pointer_hits_rope_end(pointer: Vector2) -> bool:
	if not is_instance_valid(_free_end) or not is_instance_valid(_camera):
		return false
	var endpoint := _free_end.global_position
	if _camera.is_position_behind(endpoint):
		return false
	var endpoint_screen := _camera.unproject_position(endpoint)
	var pointer_screen := _viewport_pointer(pointer)
	return pointer_screen.distance_to(endpoint_screen) <= 34.0


func _pull_rope(pointer_delta: Vector2) -> void:
	var viewport_delta := pointer_delta * Vector2(_viewport.size) / _experiment_view.size
	var depth := _camera.global_position.distance_to(_free_end.global_position)
	var world_per_pixel := 2.0 * depth * tan(deg_to_rad(_camera.fov * 0.5)) / float(_viewport.size.y)
	var screen_up_alignment := _camera.global_transform.basis.y.normalized().dot(_rig.global_transform.basis.y.normalized())
	if absf(screen_up_alignment) < 0.25:
		return
	var requested_delta := -viewport_delta.y * world_per_pixel * screen_up_alignment
	var free_y := _free_end.position.y
	var load_y := _load_group.position.y
	var load_ratio := 1.0 if _mode == 0 else 0.5
	var free_min := 0.92 if _mode == 0 else 1.20
	var free_max := 1.56 if _mode == 0 else 2.28
	var load_min := 0.92
	var load_max := 1.56 if _mode == 0 else 1.46
	var delta_min := maxf(free_min - free_y, (load_y - load_max) / load_ratio)
	var delta_max := minf(free_max - free_y, (load_y - load_min) / load_ratio)
	var actual_delta := clampf(requested_delta, delta_min, delta_max)
	if is_zero_approx(actual_delta):
		_interaction_label.text = "Halat ucunu daha fazla çekemezsin · düzeneğin sınırına ulaştı"
		return
	_free_end.position.y += actual_delta
	_load_group.position.y -= actual_delta * load_ratio
	if _mode == 0:
		_upper_pulley.rotation.z -= actual_delta / 0.36
	else:
		_lower_pulley.position.y = _load_group.position.y + 0.20
		_moving_link.position = Vector3(-0.35, _load_group.position.y + 0.04, 0.05)
		_lower_pulley.rotation.z += actual_delta / 0.72
		_upper_pulley.rotation.z -= actual_delta / 0.36
	_sync_mechanism_geometry()
	var free_direction := "aşağı" if actual_delta < 0.0 else "yukarı"
	var load_direction := "yukarı" if actual_delta < 0.0 else "aşağı"
	_interaction_label.text = "İp ucu %.2f m %s · yük %.2f m %s" % [absf(actual_delta), free_direction, absf(actual_delta) * load_ratio, load_direction]


func _sync_mechanism_geometry() -> void:
	var load_y := _load_group.position.y
	var end_y := _free_end.position.y
	if _mode == 0:
		_upper_pulley.position = Vector3(0.0, 3.18, 0.0)
		_set_rope_segment(0, Vector3(-0.80, end_y + 0.24, 0.0), Vector3(-0.36, 3.18, 0.0))
		_set_rope_segment(1, Vector3(0.36, 3.18, 0.0), Vector3(0.80, load_y + 0.08, 0.0))
	else:
		_lower_pulley.position = Vector3(-0.35, load_y + 0.20, 0.04)
		_upper_pulley.position = Vector3(0.30, 3.30, 0.0)
		_moving_link.scale.y = 0.30
		_set_rope_segment(0, Vector3(-0.74, 3.72, 0.04), Vector3(-0.74, load_y + 0.20, 0.04))
		_set_rope_segment(1, Vector3(0.04, load_y + 0.20, 0.04), Vector3(-0.12, 3.30, 0.04))
		_set_rope_segment(2, Vector3(0.72, 3.30, 0.04), Vector3(0.80, end_y + 0.24, 0.04))


func _add_load(parent: Node3D, body: Material, trim: Material, steel: Material) -> void:
	_add_torus(parent, Vector3(0, 0.05, 0), 0.11, 0.025, trim)
	_add_cylinder(parent, Vector3(0, -0.08, 0), 0.045, 0.23, steel)
	_add_box(parent, Vector3(0, -0.50, 0), Vector3(0.76, 0.64, 0.60), body)
	_add_box(parent, Vector3(0, -0.18, 0), Vector3(0.80, 0.07, 0.64), trim)
	_add_box(parent, Vector3(0, -0.82, 0), Vector3(0.86, 0.08, 0.68), steel)
	for x in [-0.30, 0.30]:
		for z in [-0.25, 0.25]:
			_add_cylinder(parent, Vector3(x, -0.48, z), 0.032, 0.025, trim, Vector3(90, 0, 0), 16)


func _add_measurement_marks(steel: Material, brass: Material) -> void:
	for i in range(9):
		var y := 0.62 + float(i) * 0.34
		_add_box(_rig, Vector3(-1.30, y, 0.19), Vector3(0.12 if i % 2 == 0 else 0.07, 0.018, 0.025), brass if i % 2 == 0 else steel)
	var floor_ring := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 1.22
	ring.outer_radius = 1.235
	ring.rings = 12
	ring.ring_segments = 96
	floor_ring.mesh = ring
	floor_ring.position = Vector3(0, 0.05, 0)
	floor_ring.material_override = _material(Color("#315263"), 0.48, 0.4)
	_rig.add_child(floor_ring)


func _update_motion() -> void:
	if not is_instance_valid(_rig):
		return
	var phase := (sin(_motion_time * TAU / 3.8 - PI / 2.0) + 1.0) * 0.5 if _running else 0.5
	if _mode == 0:
		var load_y := lerpf(0.92, 1.56, phase)
		var end_y := lerpf(1.56, 0.92, phase)
		_load_group.position = Vector3(0.80, load_y, 0)
		_free_end.position = Vector3(-0.80, end_y, 0)
		_upper_pulley.position = Vector3(0, 3.18, 0)
		_lower_pulley.hide()
		_moving_link.hide()
		_set_rope_segment(0, Vector3(-0.80, end_y + 0.24, 0), Vector3(-0.36, 3.18, 0))
		_set_rope_segment(1, Vector3(0.36, 3.18, 0), Vector3(0.80, load_y + 0.08, 0))
		_rope_segments[2].hide()
		_rope_segments[3].hide()
		_upper_pulley.rotation.z = (phase - 0.5) * 1.5
	else:
		var load_y := lerpf(0.92, 1.46, phase)
		var end_y := lerpf(2.28, 1.20, phase)
		_load_group.position = Vector3(-0.35, load_y, 0)
		_free_end.position = Vector3(0.80, end_y, 0)
		_lower_pulley.position = Vector3(-0.35, load_y + 0.20, 0.04)
		_upper_pulley.position = Vector3(0.30, 3.30, 0)
		_lower_pulley.show()
		_moving_link.show()
		_moving_link.position = Vector3(-0.35, load_y + 0.04, 0.05)
		_moving_link.scale.y = 0.30
		_set_rope_segment(0, Vector3(-0.74, 3.72, 0.04), Vector3(-0.74, load_y + 0.20, 0.04))
		_set_rope_segment(1, Vector3(0.04, load_y + 0.20, 0.04), Vector3(-0.12, 3.30, 0.04))
		_set_rope_segment(2, Vector3(0.72, 3.30, 0.04), Vector3(0.80, end_y + 0.24, 0.04))
		_rope_segments[3].hide()
		_lower_pulley.rotation.z = (phase - 0.5) * 1.7
		_upper_pulley.rotation.z = (phase - 0.5) * 0.85


func _set_rope_segment(index: int, from: Vector3, to: Vector3) -> void:
	var segment := _rope_segments[index]
	segment.show()
	var direction := to - from
	segment.position = (from + to) * 0.5
	segment.scale.y = direction.length()
	segment.quaternion = Quaternion(Vector3.UP, direction.normalized())


func _select_mode(mode: int) -> void:
	_mode = mode
	_dragging_rope = false
	_dragging_rig = false
	_motion_time = 0.0
	_update_motion()
	_update_interface()
	_run_button.text = "Ⅱ  Durdur" if _running else "▶  Başlat"
	_interaction_label.text = "Halat ucunu çek · Boş alandan döndür · Tekerlekle yakınlaş"


func _cycle_load_choice() -> void:
	_load_choice = (_load_choice + 1) % ACCELERATIONS.size()
	_update_interface()


func _cycle_rope_choice() -> void:
	_rope_choice = (_rope_choice + 1) % ACCELERATIONS.size()
	_update_interface()


func _repair_rule() -> void:
	if _solved:
		return
	var correct := _load_choice == 0 and (_rope_choice == 0 if _mode == 0 else _rope_choice == 1)
	if not correct:
		_feedback.text = "İlişki hâlâ ters. Sabit makarada yük ile ip ucu eşit ivmeli; hareketli makarada yükü taşıyan iki ip kolunun toplam uzunluğu sabittir."
		_feedback.add_theme_color_override("font_color", RED)
		return
	if _mode == 0:
		_feedback.text = "Doğru. Sabit makara yalnızca yönü değiştirir: yük a ile yükselirken serbest ip ucu a ile aşağı iner."
		_feedback.add_theme_color_override("font_color", TEAL)
		_stage = 1
		_load_choice = 1
		_rope_choice = 0
		_mode = 1
		_motion_time = 0.0
		_update_motion()
		_update_interface()
		return
	_solved = true
	_running = true
	_feedback.text = "Onarım tamamlandı. Yük a ile yükseliyor; serbest ip ucu 2a ile aşağı iniyor. Toplam ip boyu sabit kaldı."
	_feedback.add_theme_color_override("font_color", TEAL)
	_fault_label.text = "Yük: a     İp ucu: 2a  ✓"
	_fault_panel.add_theme_stylebox_override("panel", _panel_style(Color("#12302e"), Color("#3c8c79"), 1, 9))
	_repair_button.text = "✓  Kural onarıldı"
	_repair_button.disabled = true
	completed.emit()


func _toggle_motion() -> void:
	if not _running:
		var phase := inverse_lerp(1.56, 0.92, _free_end.position.y) if _mode == 0 else inverse_lerp(2.28, 1.20, _free_end.position.y)
		_motion_time = (asin(clampf(phase * 2.0 - 1.0, -1.0, 1.0)) + PI * 0.5) * 3.8 / TAU
	_running = not _running
	_run_button.text = "Ⅱ  Durdur" if _running else "▶  Başlat"
	_update_motion()


func _request_exit() -> void:
	exit_requested.emit()


func _update_interface() -> void:
	for i in range(_mode_buttons.size()):
		_mode_buttons[i].button_pressed = i == _mode
		_mode_buttons[i].disabled = _solved or (_stage == 0 and i == 1) or (_stage == 1 and i == 0)
	_stage_label.text = ("GÖZLEM 01 / 02  ·  SABİT MAKARA" if _mode == 0 else "GÖZLEM 02 / 02  ·  HAREKETLİ MAKARA")
	_rule_label.text = "SABİT MAKARA\na_yük = a_ip\n0,5 = 0,5 m/s²" if _mode == 0 else "HAREKETLİ MAKARA\na_ip = 2 × a_yük\n1,0 = 2 × 0,5 m/s²"
	if _solved:
		_load_choice_button.text = "Yük ivmesi  ·  a"
		_rope_choice_button.text = "İp ucu ivmesi  ·  2a"
	else:
		_load_choice_button.text = "Yük ivmesi  ·  %s" % ACCELERATIONS[_load_choice]
		_rope_choice_button.text = "İp ucu ivmesi  ·  %s" % ACCELERATIONS[_rope_choice]
	if _mode == 0 and _stage == 0:
		_fault_label.text = "Yük ivmesi: 2a     İp ucu: a"
		_hint.text = "Tek ve sabit bir ip boyunca iki uç aynı miktarda yer değiştirir."
	elif _mode == 1 and not _solved:
		_fault_label.text = "Yük ivmesi: 2a     İp ucu: a"
		_hint.text = "Yükü taşıyan iki ip kolu kısalır; serbest uç bunun iki katı yol alır."
	else:
		_hint.text = "İdeal düzende ip esnemez ve kaymaz; toplam ip uzunluğu sabittir."
	if _solved:
		_feedback.text = "Onarım tamamlandı. Yük a ile yükseliyor; serbest ip ucu 2a ile aşağı iniyor. Toplam ip boyu sabit kaldı."
		_feedback.add_theme_color_override("font_color", TEAL)
	elif _stage == 0:
		_feedback.text = "Önce eşit kollu sabit düzeneğin hareketini kontrol et."
		_feedback.add_theme_color_override("font_color", MUTED)
	elif _stage == 1 and _mode == 1:
		_feedback.text = "Şimdi hareketli makarada iki taşıyıcı ip kolunun etkisini düşün."
		_feedback.add_theme_color_override("font_color", MUTED)
	_repair_button.disabled = _solved
	if is_instance_valid(_rig):
		_update_motion()


func _label(value: String, size: int, color: Color, bold := false) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	if bold:
		item.theme_type_variation = &"HeadlineLabel"
		item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.2))
	return item


func _button(value: String, toggle: bool) -> Button:
	var item := Button.new()
	item.text = value
	item.toggle_mode = toggle
	item.custom_minimum_size = Vector2(0, 42)
	item.add_theme_font_size_override("font_size", 14)
	item.add_theme_color_override("font_color", TEXT)
	item.add_theme_color_override("font_hover_color", Color.WHITE)
	item.add_theme_stylebox_override("normal", _panel_style(Color("#1b2e3c"), Color("#365365"), 1, 9))
	item.add_theme_stylebox_override("hover", _panel_style(Color("#254456"), TEAL, 1, 9))
	item.add_theme_stylebox_override("pressed", _panel_style(Color("#17403f"), TEAL, 2, 9))
	item.add_theme_stylebox_override("focus", _panel_style(Color("#1b2e3c"), AMBER, 1, 9))
	return item


func _panel_style(fill: Color, border: Color, border_size: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_size)
	style.set_corner_radius_all(radius)
	return style


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = material
	parent.add_child(item)
	return item


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	item.mesh = mesh
	item.position = pos
	item.material_override = material
	parent.add_child(item)
	return item


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, rotation := Vector3.ZERO, sides := 32) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	item.mesh = mesh
	item.position = pos
	item.rotation_degrees = rotation
	item.material_override = material
	parent.add_child(item)
	return item


func _add_torus(parent: Node3D, pos: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 24
	mesh.ring_segments = 64
	item.mesh = mesh
	item.position = pos
	item.rotation_degrees.x = 90
	item.material_override = material
	parent.add_child(item)
	return item


func _beam(from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 24
	beam.mesh = mesh
	beam.material_override = _material(color, 0.42, 0.34)
	beam.position = (from + to) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return beam
