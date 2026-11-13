extends Control
## 3D measurement bench. Mission values still come from the mission's explicit calculation.

const INK := Color("#dce9e8")
const MINT := Color("#79e0bf")
const AMBER := Color("#ffad81")
const STEEL := Color("#405b60")
const RAIL := Color("#789395")

var instrument := &"fault"
var measured := false
var motion := 0.0
var test_state := &"fault"
var _world: Node3D
var _timer_hand: Node3D
var _title: Label3D
var _display: Label3D
var _ruler_group: Node3D
var _scale_group: Node3D
var _timer_group: Node3D
var _track_group: Node3D
var _cart_group: Node3D
var _coupler: MeshInstance3D
var _status_lamp: MeshInstance3D
var _cart_indicator: MeshInstance3D
var _sample_bar: MeshInstance3D
var _caliper_jaw: MeshInstance3D
var _scale_value: Label3D
var _ruler_readout: Label3D
var _timer_value: Label3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()
	_build_bench()
	show_state(instrument, measured, motion, test_state)


func show_state(kind: StringName, reading: bool, progress: float, state: StringName) -> void:
	var kind_changed := instrument != kind
	instrument = kind
	measured = reading
	motion = progress
	test_state = state
	if not is_node_ready():
		return
	if kind_changed:
		_apply_visibility()
	_update_instrument()
	_update_animation()


func _build_viewport() -> void:
	var container := SubViewportContainer.new()
	container.name = "ViewportContainer"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.name = "Viewport"
	viewport.own_world_3d = true
	viewport.size = Vector2i(900, 620)
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	container.add_child(viewport)
	_world = Node3D.new()
	_world.name = "World"
	viewport.add_child(_world)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#0a1720")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#9ebac6")
	environment.ambient_light_energy = 0.64
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_world.add_child(world_environment)
	var camera := Camera3D.new()
	camera.position = Vector3(4.0, 4.3, 6.0)
	camera.rotation_degrees = Vector3(-27, 34, 0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.1
	camera.current = true
	_world.add_child(camera)
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-48, -28, 0)
	key.light_energy = 1.3
	key.shadow_enabled = true
	_world.add_child(key)
	var fill := OmniLight3D.new()
	fill.name = "CoolFill"
	fill.position = Vector3(-2.8, 2.5, 2.8)
	fill.light_color = Color("#55c9ca")
	fill.light_energy = 0.65
	fill.omni_range = 8.0
	_world.add_child(fill)


func _build_bench() -> void:
	var stage := Node3D.new()
	stage.name = "MeasurementLab"
	_world.add_child(stage)
	_box(stage, "BenchTop", Vector3(0, -0.18, 0), Vector3(4.65, 0.25, 3.5), Color("#243a42"))
	_box(stage, "BenchInset", Vector3(0, -0.035, 0), Vector3(4.44, 0.055, 3.29), Color("#304a4e"))
	_box(stage, "FrontLip", Vector3(0, -0.19, 1.73), Vector3(4.7, 0.16, 0.08), Color("#172a32"))
	for x in [-1.8, 1.8]:
		for z in [-1.25, 1.25]:
			_box(stage, "BenchLeg", Vector3(x, -0.53, z), Vector3(0.16, 0.68, 0.16), Color("#22343a"))
	for i in range(7):
		_box(stage, "CalibrationStripe%d" % i, Vector3(-1.8 + i * 0.6, 0.0, -1.52), Vector3(0.38, 0.012, 0.025), Color("#5b797a"))
	_title = _label(stage, "BenchTitle", "ÖLÇÜM ATÖLYESİ", Vector3(-1.6, 0.05, -1.45), MINT, 46, 0.0055)

	_track_group = Node3D.new()
	_track_group.name = "TransportTrack"
	stage.add_child(_track_group)
	_box(_track_group, "RailBed", Vector3(0, 0.31, 0.0), Vector3(4.05, 0.12, 0.68), Color("#1c2b31"))
	for z in [-0.24, 0.24]:
		_box(_track_group, "Rail", Vector3(0, 0.45, z), Vector3(4.1, 0.075, 0.09), RAIL, true)
		for x in range(9):
			_box(_track_group, "Sleeper", Vector3(-1.8 + x * 0.45, 0.26, z * 1.72), Vector3(0.08, 0.13, 0.72), Color("#526a68"))
	for i in range(11):
		var x := -1.8 + i * 0.36
		_box(_track_group, "TrackMarker%d" % i, Vector3(x, 0.52, -0.37), Vector3(0.018, 0.025, 0.06), MINT if i % 5 == 0 else Color("#91a7a5"))
	_cart_group = Node3D.new()
	_cart_group.name = "Carrier"
	_track_group.add_child(_cart_group)
	_build_cart(_cart_group)
	_coupler = _box(_track_group, "FaultCoupler", Vector3(0.0, 0.49, 0), Vector3(0.34, 0.13, 0.22), AMBER, true)
	_status_lamp = _sphere(stage, "StatusLamp", Vector3(1.94, 0.32, -1.2), 0.09, AMBER, true)

	_ruler_group = Node3D.new()
	_ruler_group.name = "LengthRig"
	stage.add_child(_ruler_group)
	_build_ruler(_ruler_group)

	_scale_group = Node3D.new()
	_scale_group.name = "MassRig"
	stage.add_child(_scale_group)
	_build_scale(_scale_group)

	_timer_group = Node3D.new()
	_timer_group.name = "TimerRig"
	stage.add_child(_timer_group)
	_build_timer(_timer_group)

	_display = _label(stage, "Readout", "240 cm  →  240 m", Vector3(0.0, 1.05, 0.16), AMBER, 56, 0.0058)
	_apply_visibility()


func _build_ruler(parent: Node3D) -> void:
	var center := Vector3(0, 0.48, 1.0)
	_box(parent, "RulerBase", center, Vector3(2.55, 0.07, 0.35), Color("#63897e"))
	_box(parent, "RulerScale", center + Vector3(0, 0.045, 0), Vector3(2.5, 0.018, 0.3), Color("#afc9a4"))
	for i in range(25):
		var x := -1.2 + float(i) * 0.1
		var tall := i % 5 == 0
		_box(parent, "Tick%d" % i, center + Vector3(x, 0.06, 0.1 - (0.11 if tall else 0.04)), Vector3(0.016, 0.012, 0.22 if tall else 0.08), Color("#20363c"))
		if tall:
			_label(parent, "Centimeter%d" % i, "%d" % (i * 10), center + Vector3(x, 0.075, -0.15), Color("#1d3437"), 23, 0.004)
	_sample_bar = _box(parent, "SampleBar", center + Vector3(-0.95, 0.15, -0.08), Vector3(1.8, 0.14, 0.11), Color("#bd7957"), true)
	_box(parent, "CaliperRail", center + Vector3(0.0, 0.18, 0.02), Vector3(2.7, 0.045, 0.06), STEEL)
	_box(parent, "CaliperJawLeft", center + Vector3(-1.2, 0.23, 0.02), Vector3(0.055, 0.28, 0.12), Color("#bac8c3"))
	_caliper_jaw = _box(parent, "CaliperJawRight", center + Vector3(-0.65, 0.23, 0.02), Vector3(0.055, 0.28, 0.12), Color("#bac8c3"))
	_ruler_readout = _label(parent, "RulerReadout", "SIFIR NOKTASI", center + Vector3(0.0, 0.42, -0.02), MINT, 33, 0.005)


func _build_scale(parent: Node3D) -> void:
	var pos := Vector3(-0.8, 0.48, -0.72)
	_box(parent, "ScaleBody", pos + Vector3(0, 0.12, 0), Vector3(1.3, 0.24, 0.9), STEEL)
	_box(parent, "ScaleTop", pos + Vector3(0, 0.27, 0), Vector3(1.18, 0.07, 0.76), Color("#a4b4af"))
	_box(parent, "ScaleDisplay", pos + Vector3(0, 0.45, -0.27), Vector3(0.7, 0.22, 0.055), Color("#102525"), true)
	_scale_value = _label(parent, "ScaleValue", "— kg", pos + Vector3(0, 0.48, -0.22), MINT, 38, 0.005)
	_box(parent, "SampleMass", pos + Vector3(0, 0.51, 0.05), Vector3(0.38, 0.42, 0.38), Color("#bd7957"), true)
	_label(parent, "MassTag", "M = 1,2 kg", pos + Vector3(0, 1.08, 0.08), MINT, 31, 0.005)
	for x in [-0.44, 0.44]:
		_sphere(parent, "ScaleFoot", pos + Vector3(x, -0.03, 0.31), 0.065, Color("#11252c"))


func _build_timer(parent: Node3D) -> void:
	var pos := Vector3(1.2, 0.48, -0.8)
	_box(parent, "TimerBase", pos + Vector3(0, 0.1, 0), Vector3(0.95, 0.2, 0.72), STEEL)
	_cylinder(parent, "TimerDial", pos + Vector3(0, 0.37, 0), 0.38, 0.09, Color("#17282d"), 48)
	for i in 12:
		var angle := TAU * float(i) / 12.0
		var tick_pos := pos + Vector3(cos(angle) * 0.31, 0.43, sin(angle) * 0.31)
		_box(parent, "TimerTick%d" % i, tick_pos, Vector3(0.025, 0.025, 0.08), Color("#87aaa1"), false, Vector3(0, -angle, 0))
	_timer_hand = Node3D.new()
	_timer_hand.name = "TimerHand"
	_timer_hand.position = pos + Vector3(0, 0.45, 0)
	parent.add_child(_timer_hand)
	_box(_timer_hand, "Needle", Vector3(0.0, 0.015, 0.13), Vector3(0.035, 0.035, 0.28), MINT, true)
	_sphere(_timer_hand, "NeedleHub", Vector3(0, 0.035, 0), 0.06, Color("#e6efdf"))
	_box(parent, "TimerScreen", pos + Vector3(0, 0.43, -0.42), Vector3(0.58, 0.2, 0.05), Color("#101e24"), true)
	_timer_value = _label(parent, "TimerValue", "00,0 s", pos + Vector3(0, 0.45, -0.38), MINT, 35, 0.005)
	_label(parent, "TimerTitle", "OLAY SÜRESİ", pos + Vector3(0, 0.76, 0.15), INK, 27, 0.0045)


func _build_cart(parent: Node3D) -> void:
	_box(parent, "CarrierChassis", Vector3(0, 0.12, 0), Vector3(0.62, 0.26, 0.43), Color("#4e7570"))
	_box(parent, "CarrierTop", Vector3(0, 0.28, 0), Vector3(0.46, 0.1, 0.36), Color("#8bad9f"))
	for x in [-0.22, 0.22]:
		for z in [-0.25, 0.25]:
			_cylinder(parent, "Wheel", Vector3(x, 0.03, z), 0.105, 0.07, Color("#17262c"), 20, Vector3(PI / 2, 0, 0))
	_cart_indicator = _sphere(parent, "CarrierLamp", Vector3(0.22, 0.34, 0), 0.045, MINT, true)


func _apply_visibility() -> void:
	if _ruler_group == null:
		return
	var show_ruler := instrument == &"length" or instrument == &"convert"
	var show_scale := instrument == &"mass"
	var show_timer := instrument == &"time"
	var show_transport := instrument == &"fault" or instrument == &"guided" or instrument == &"speed" or instrument == &"running" or instrument == &"complete"
	_ruler_group.visible = show_ruler
	_scale_group.visible = show_scale
	_timer_group.visible = show_timer
	_track_group.visible = show_transport
	if _title:
		_title.text = {
			"fault":"SİSTEM ARIZASI", "length":"CETVEL  /  cm", "mass":"TERAZİ  /  kg",
			"time":"SAYAÇ  /  s", "guided":"SÜRAT VE YÖN", "speed":"UYGULAMA  /  m/s",
			"running":"TAŞIYICI ÇALIŞIYOR", "complete":"RAY ONARILDI", "convert":"DÖNÜŞÜM  /  1 m = 100 cm"
		}.get(String(instrument), "ÖLÇÜM ATÖLYESİ")


func _update_instrument() -> void:
	if _display:
		_display.text = _readout_for_state()
		_display.modulate = AMBER if test_state == &"fault" or test_state == &"too_long" or test_state == &"too_short" else MINT
	if _coupler:
		var connected := test_state == &"connected" or instrument == &"complete"
		_coupler.visible = not connected
		_coupler.material_override = _material(MINT if connected else AMBER, true)
	if _status_lamp:
		_status_lamp.material_override = _material(AMBER if test_state == &"fault" or test_state == &"too_long" or test_state == &"too_short" else MINT, true)
	if _cart_indicator:
		_cart_indicator.material_override = _material(AMBER if test_state == &"fault" else MINT, true)


func _update_animation() -> void:
	if _cart_group:
		var start_x := -1.68
		var end_x := 1.68
		var range := 0.31 if instrument == &"fault" else 0.68
		_cart_group.position.x = start_x + motion * (end_x - start_x) * range
		_cart_group.position.y = 0.0
	if _timer_hand:
		_timer_hand.rotation.y = motion * TAU * 0.75
	if _display:
		_display.text = _readout_for_state()
		_display.modulate = AMBER if test_state == &"fault" or test_state == &"too_long" or test_state == &"too_short" else MINT
	if _scale_value:
		_scale_value.text = "1,2 kg" if measured else "— kg"
	if _sample_bar and _caliper_jaw:
		var ruler_center := Vector3(0, 0.48, 1.0)
		_sample_bar.position = ruler_center + Vector3(-0.3 if measured else -0.95, 0.15, -0.08)
		_caliper_jaw.position.x = ruler_center.x + (0.6 if measured else -0.65)
	if _ruler_readout:
		_ruler_readout.text = "180 cm  /  1,8 m" if measured else "SIFIR NOKTASI"
	if _timer_value:
		var value := ("%.1f" % (1.5 * motion)).replace(".", ",")
		_timer_value.text = "%s s" % value if measured else "%s s" % ("00,0" if motion == 0.0 else value)


func _readout_for_state() -> String:
	match instrument:
		&"fault":
			return "240 cm  →  240 m"
		&"length":
			return "180 cm  =  1,8 m" if measured else "SIFIR HİZASI"
		&"mass":
			return "1,2 kg" if measured else "KÜTLEYİ ÖLÇ"
		&"time":
			return "%.1f s" % (1.5 * motion) if not measured else "1,5 s"
		&"guided":
			return "3,0 m  /  %.1f s" % (2.0 * motion)
		&"speed":
			return "6 m  /  3 s  =  2 m/s"
		&"running", &"complete":
			return "6 m  /  3 s  =  2 m/s"
		&"convert":
			if test_state == &"too_long":
				return "PARÇA UZUN  /  YUVA DIŞI"
			if test_state == &"too_short":
				return "PARÇA KISA  /  BOŞLUK AÇIK"
			return "240 cm  →  m cinsinden gir"
	return "ÖLÇÜM ATÖLYESİ"


func _material(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	material.metallic = 0.24
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	return material


func _box(parent: Node3D, id: String, position: Vector3, size: Vector3, color: Color, glow := false, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.position = position
	instance.rotation = rotation
	instance.mesh = mesh
	instance.material_override = _material(color, glow)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func _sphere(parent: Node3D, id: String, position: Vector3, radius: float, color: Color, glow := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var instance := _box_mesh(parent, id, position, mesh, color, glow)
	return instance


func _box_mesh(parent: Node3D, id: String, position: Vector3, mesh: PrimitiveMesh, color: Color, glow := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.position = position
	instance.mesh = mesh
	instance.material_override = _material(color, glow)
	parent.add_child(instance)
	return instance


func _cylinder(parent: Node3D, id: String, position: Vector3, radius: float, height: float, color: Color, segments := 20, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var instance := _box_mesh(parent, id, position, mesh, color)
	instance.rotation = rotation
	return instance


func _label(parent: Node3D, id: String, value: String, position: Vector3, color: Color, size: int, pixel_size := 0.005) -> Label3D:
	var label := Label3D.new()
	label.name = id
	label.text = value
	label.position = position
	label.font_size = size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("#07131b")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label
