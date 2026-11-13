extends Node3D
## Purpose-built 3D observatory rig for the free-fall experiment.
## Distances are visualized on the 5 m physical chamber scale; gameplay physics
## and readouts remain owned by fall_stage.gd.

const CHAMBER := preload("res://stations/free_fall/assets/chamber.glb")

var _apparatus: Node3D
var _glass: MeshInstance3D
var _sensor: MeshInstance3D
var _sensor_lights: Array[OmniLight3D] = []
var _fault_bars: Array[MeshInstance3D] = []
var _body_nodes: Dictionary = {}
var _body_trails: Dictionary = {}
var _pressure_core: MeshInstance3D
var _pressure_light: OmniLight3D
var _time := 0.0
var _pressure := 101.325
var _gravity_fixed := false
var _fault_visible := false
var _release_height := 20.0
var _flash := 0.0

const CHAMBER_HEIGHT := 4.72
const BODY_NAMES := [&"steel", &"foam", &"capsule"]


func _ready() -> void:
	_build_lighting()
	_build_stage_floor()
	_build_apparatus()
	_build_pressure_manifold()
	_build_readout_hardware()


func set_state(states: Dictionary, pressure_kpa: float, fixed: bool, fault: bool, height: float, flash: float) -> void:
	_pressure = pressure_kpa
	_gravity_fixed = fixed
	_fault_visible = fault
	_release_height = height
	_flash = flash
	for body in BODY_NAMES:
		var row: Dictionary = states.get(body, {})
		var active := bool(row.get("active", false))
		var landed := bool(row.get("landed", false))
		var selected := bool(row.get("visible", false))
		var depth := float(row.get("depth", 0.0))
		var speed := float(row.get("speed", 0.0))
		var mesh: MeshInstance3D = _body_nodes[body]
		var trail: MeshInstance3D = _body_trails[body]
		mesh.visible = selected and not landed
		trail.visible = active and not landed and speed > 0.25
		mesh.position.y = _visual_height(depth if active else 0.0)
		mesh.rotation.z = sin(_time * 1.7 + float(BODY_NAMES.find(body))) * 0.035
		trail.position.y = mesh.position.y + 0.34
		trail.scale.y = clampf(speed / 26.0, 0.1, 1.0)
	_update_materials()


func _process(delta: float) -> void:
	_time += delta
	for i in _sensor_lights.size():
		var lamp := _sensor_lights[i]
		lamp.light_energy = (1.6 if _flash > 0.05 else 0.5) + 0.08 * sin(_time * 3.0 + i)
	for index in _fault_bars.size():
		var bar := _fault_bars[index]
		bar.visible = _fault_visible
		if _fault_visible:
			bar.position.x = -0.11 if index % 2 == 0 else 0.11
			bar.position.z = 0.59 + 0.035 * sin(_time * 7.0 + index)
			bar.rotation.y = 0.05 * sin(_time * 5.0 + index)
	_update_materials()


func _visual_height(depth: float) -> float:
	var progress := clampf(depth / _release_height, 0.0, 1.0)
	return 0.84 + (1.0 - progress) * 4.02


func _update_materials() -> void:
	if _pressure_core == null:
		return
	var ratio := clampf(_pressure / 101.325, 0.0, 1.0)
	var core_mat := _pressure_core.material_override as StandardMaterial3D
	core_mat.emission_energy_multiplier = 0.55 + ratio * 0.8
	core_mat.albedo_color = Color("#62a8ba").lerp(Color("#6fe3c1"), 1.0 - ratio)
	if _pressure_light != null:
		_pressure_light.light_energy = 0.45 + (1.0 - ratio) * 1.35
		_pressure_light.light_color = Color("#5d91c8").lerp(Color("#73efd1"), 1.0 - ratio)
	if _glass != null:
		var glass := _glass.material_override as StandardMaterial3D
		glass.albedo_color = Color(0.31, 0.61, 0.77, 0.075 + ratio * 0.045)
		glass.emission_energy_multiplier = 0.14 if _fault_visible else (0.42 if _gravity_fixed else 0.22)
	if _sensor != null:
		var sensor_mat := _sensor.material_override as StandardMaterial3D
		sensor_mat.emission_energy_multiplier = 0.9 if _flash > 0.05 else (0.3 if _gravity_fixed else 0.16)
		if _flash > 0.05:
			sensor_mat.albedo_color = Color("#8dffe2")
		elif _gravity_fixed:
			sensor_mat.albedo_color = Color("#65e3bf")
		else:
			sensor_mat.albedo_color = Color("#db7f4d")


func _build_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#08101d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8295ae")
	environment.ambient_light_energy = 0.42
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment_node.environment = environment
	add_child(environment_node)

	var camera := Camera3D.new()
	camera.name = "FreeFallCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.8
	camera.position = Vector3(0.0, 6.25, 17.2)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 2.72, 0.0), Vector3.UP)

	var key := DirectionalLight3D.new()
	key.name = "SoftboxKey"
	key.rotation_degrees = Vector3(-43.0, -28.0, 0.0)
	key.light_energy = 1.25
	key.shadow_enabled = true
	add_child(key)
	var rim := OmniLight3D.new()
	rim.name = "CyanRim"
	rim.position = Vector3(-4.1, 4.1, -0.6)
	rim.light_color = Color("#60cfe2")
	rim.light_energy = 2.5
	rim.omni_range = 8.0
	add_child(rim)
	var warm := OmniLight3D.new()
	warm.name = "WarmInstrumentLight"
	warm.position = Vector3(-0.7, 1.35, 3.0)
	warm.light_color = Color("#efa56a")
	warm.light_energy = 1.2
	warm.omni_range = 7.0
	add_child(warm)


func _build_stage_floor() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "InstrumentFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(26.0, 20.0)
	floor.mesh = plane
	floor.position = Vector3(0.0, -0.22, -0.2)
	floor.material_override = _material(Color("#0a1420"), 0.5, 0.42)
	add_child(floor)

	var plinth := _box("ChamberPlinth", Vector3(4.6, 0.24, 2.2), Color("#1c2b3a"), 0.82, 0.28)
	plinth.position = Vector3(-3.2, -0.02, 0.0)
	add_child(plinth)
	var plinth_top := _box("PlinthSignalBand", Vector3(4.0, 0.025, 1.86), Color("#427b8a"), 0.72, 0.22, Color("#2a9cac"), 0.45)
	plinth_top.position = Vector3(-3.2, 0.112, 0.0)
	add_child(plinth_top)

	# Fine floor marks make the chamber feel calibrated and help show its scale.
	for i in range(-5, 6):
		var line := _box("FloorCalibration_%02d" % (i + 5), Vector3(0.012, 0.003, 7.0), Color("#264053"), 0.5, 0.3)
		line.position = Vector3(float(i) * 0.7, -0.205, 1.1)
		add_child(line)


func _build_apparatus() -> void:
	_apparatus = Node3D.new()
	_apparatus.name = "VacuumDropChamber"
	_apparatus.position = Vector3(-3.2, 0.0, 0.0)
	add_child(_apparatus)
	var chamber := CHAMBER.instantiate() as Node3D
	chamber.name = "VacuumChamberMesh"
	_apparatus.add_child(chamber)
	_glass = _find_mesh(chamber, "Glass")
	if _glass != null:
		var glass_material := _material(Color(0.31, 0.61, 0.77, 0.075), 0.0, 0.08, Color("#4db4d4"), 0.22)
		glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.material_override = glass_material
	_sensor = _find_mesh(chamber, "Sensor_Plate")
	if _sensor != null:
		_sensor.material_override = _material(Color("#d8754b"), 0.48, 0.25, Color("#d8754b"), 0.3)

	# A discrete gold marker rail and three collar details frame the measured path.
	for i in 5:
		var y := 0.45 + float(i) * 1.02
		var collar := _box("HeightCollar_%02d" % i, Vector3(1.35, 0.018, 0.035), Color("#8fbac4"), 0.68, 0.27)
		collar.position = Vector3(-0.03, y, 0.82)
		_apparatus.add_child(collar)

	var top_hatch := _cylinder("ReleaseMagnetRail", 0.73, 0.085, Color("#c68a4e"), 0.72, 0.24)
	top_hatch.position = Vector3(0.0, 4.87, 0.0)
	_apparatus.add_child(top_hatch)
	for i in 3:
		var magnet := _box("ReleaseMagnet_%d" % i, Vector3(0.18, 0.08, 0.16), Color("#65c0ca"), 0.38, 0.24, Color("#48bac8"), 0.8)
		magnet.position = Vector3(-0.44 + float(i) * 0.44, 4.72, 0.5)
		_apparatus.add_child(magnet)

	for i in 3:
		var lamp := OmniLight3D.new()
		lamp.name = "SensorPulse_%d" % i
		lamp.position = Vector3(-0.4 + float(i) * 0.4, 0.77, 0.64)
		lamp.light_color = Color("#69e5c5")
		lamp.light_energy = 0.5
		lamp.omni_range = 1.4
		_apparatus.add_child(lamp)
		_sensor_lights.append(lamp)

	# Glitch fragments appear only during the broken-gravity opening and investigation.
	for i in 5:
		var bar := _box("GuestInterference_%02d" % i, Vector3(0.75 - 0.07 * float(i), 0.025, 0.025), Color("#67e6ee" if i % 2 == 0 else "#e375bb"), 0.3, 0.2, Color("#67e6ee" if i % 2 == 0 else "#e375bb"), 1.4)
		bar.position = Vector3(0.0, 0.75 + float(i) * 0.78, 0.61)
		bar.visible = false
		_apparatus.add_child(bar)
		_fault_bars.append(bar)

	_build_drop_bodies()
	_build_orbit_rig()


func _build_drop_bodies() -> void:
	for body in BODY_NAMES:
		var shell := MeshInstance3D.new()
		shell.name = "Drop_%s" % String(body)
		var material: StandardMaterial3D
		if body == &"steel":
			shell.mesh = _sphere(0.155, 24, 16)
			material = _material(Color("#b7c3ce"), 0.92, 0.16)
		elif body == &"foam":
			shell.mesh = _sphere(0.19, 24, 16)
			material = _material(Color("#e6bf69"), 0.12, 0.55)
		else:
			var capsule := CapsuleMesh.new()
			capsule.radius = 0.13
			capsule.height = 0.62
			capsule.radial_segments = 24
			shell.mesh = capsule
			material = _material(Color("#d88745"), 0.64, 0.22, Color("#75411d"), 0.35)
		shell.material_override = material
		shell.visible = false
		_apparatus.add_child(shell)
		_body_nodes[body] = shell

		var trail := MeshInstance3D.new()
		trail.name = "AirTrail_%s" % String(body)
		var trail_mesh := CylinderMesh.new()
		trail_mesh.top_radius = 0.012
		trail_mesh.bottom_radius = 0.11 if body == &"foam" else 0.072
		trail_mesh.height = 0.65
		trail.mesh = trail_mesh
		trail.position.z = -0.3
		trail.material_override = _material(Color(0.38, 0.75, 0.82, 0.26), 0.0, 0.1, Color("#5ab4cb"), 0.24)
		var trail_material := trail.material_override as StandardMaterial3D
		trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail.visible = false
		_apparatus.add_child(trail)
		_body_trails[body] = trail
		if body == &"steel":
			shell.position.x = -0.32
			trail.position.x = -0.32
		elif body == &"foam":
			shell.position.x = 0.32
			trail.position.x = 0.32

		var glow := OmniLight3D.new()
		glow.name = "PayloadAccent_%s" % String(body)
		glow.light_color = Color("#8ac5da") if body == &"steel" else (Color("#e6c879") if body == &"foam" else Color("#e87948"))
		glow.light_energy = 0.55
		glow.omni_range = 1.2
		shell.add_child(glow)


func _build_orbit_rig() -> void:
	for ring_index in 2:
		var ring := MeshInstance3D.new()
		ring.name = "ChamberStabilizerRing_%d" % ring_index
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.98 + float(ring_index) * 0.2
		mesh.outer_radius = mesh.inner_radius + 0.018
		mesh.rings = 48
		mesh.ring_segments = 8
		ring.mesh = mesh
		ring.position = Vector3(0.0, 2.72, 0.0)
		ring.rotation.x = PI / 2.0
		ring.material_override = _material(Color("#356373") if ring_index == 0 else Color("#a77a4c"), 0.76, 0.23, Color("#376e7a"), 0.22)
		_apparatus.add_child(ring)
	for i in 4:
		var arm := _box("RingSupport_%d" % i, Vector3(0.035, 4.25, 0.04), Color("#526d78"), 0.7, 0.3)
		arm.position = Vector3(-1.15 + float(i % 2) * 2.3, 2.42, -0.16 + float(i / 2) * 0.32)
		_apparatus.add_child(arm)


func _build_pressure_manifold() -> void:
	var housing := _cylinder("VacuumPumpHousing", 0.48, 1.16, Color("#1c3545"), 0.79, 0.28)
	housing.position = Vector3(-6.3, 0.86, 0.0)
	add_child(housing)
	var core := _cylinder("PressureIndicatorCore", 0.19, 0.74, Color("#62a8ba"), 0.0, 0.2, Color("#4e9ab1"), 0.55)
	core.position = Vector3(-6.3, 1.13, 0.03)
	add_child(core)
	_pressure_core = core
	var cap := _cylinder("PumpTopCap", 0.32, 0.09, Color("#c7945d"), 0.65, 0.24)
	cap.position = Vector3(-6.3, 1.49, 0.0)
	add_child(cap)
	var pipe := _cylinder("VacuumPipe", 0.045, 2.0, Color("#5ea0ab"), 0.82, 0.22)
	pipe.rotation.z = PI / 2.0
	pipe.position = Vector3(-4.95, 1.12, -0.08)
	add_child(pipe)
	var valve := _torus("IsolationValve", 0.25, 0.026, Color("#d9a365"))
	valve.position = Vector3(-5.05, 1.12, 0.15)
	add_child(valve)
	var crossbar := _box("ValveHandle", Vector3(0.045, 0.48, 0.045), Color("#dfaa6c"), 0.7, 0.22)
	crossbar.position = Vector3(-5.05, 1.12, 0.15)
	add_child(crossbar)
	_pressure_light = OmniLight3D.new()
	_pressure_light.name = "VacuumStatusGlow"
	_pressure_light.position = Vector3(-6.3, 1.02, 0.58)
	_pressure_light.light_color = Color("#6ddfc5")
	_pressure_light.light_energy = 0.6
	_pressure_light.omni_range = 2.5
	add_child(_pressure_light)


func _build_readout_hardware() -> void:
	var board := _box("ReadoutConsole", Vector3(4.0, 1.72, 0.16), Color("#162837"), 0.88, 0.25)
	board.position = Vector3(2.4, 1.28, -0.62)
	add_child(board)
	var edge := _box("ReadoutConsoleEdge", Vector3(4.04, 0.035, 0.18), Color("#528b98"), 0.72, 0.25, Color("#3b8791"), 0.28)
	edge.position = Vector3(2.4, 2.14, -0.51)
	add_child(edge)
	for row in 3:
		var slot := _box("ReadoutSlot_%d" % row, Vector3(3.35, 0.018, 0.012), Color("#354d5b"), 0.4, 0.45)
		slot.position = Vector3(2.4, 1.9 - float(row) * 0.42, -0.51)
		add_child(slot)
	var arm := _box("ConsoleSupport", Vector3(0.07, 1.0, 0.09), Color("#283e4d"), 0.76, 0.3)
	arm.position = Vector3(2.4, 0.4, -0.62)
	add_child(arm)


func _find_mesh(root: Node, node_name: String) -> MeshInstance3D:
	if root is MeshInstance3D and root.name == node_name:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_mesh(child, node_name)
		if found != null:
			return found
	return null


func _material(color: Color, metallic: float = 0.0, roughness: float = 0.35, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


func _box(node_name: String, dimensions: Vector3, color: Color, metallic: float = 0.0, roughness: float = 0.35, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.material_override = _material(color, metallic, roughness, emission, emission_energy)
	return node


func _sphere(radius: float, radial: int, rings: int) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = radial
	mesh.rings = rings
	return mesh


func _cylinder(node_name: String, radius: float, height: float, color: Color, metallic: float = 0.0, roughness: float = 0.35, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	node.mesh = mesh
	node.material_override = _material(color, metallic, roughness, emission, emission_energy)
	return node


func _torus(node_name: String, inner: float, outer: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 40
	mesh.ring_segments = 8
	node.mesh = mesh
	node.material_override = _material(color, 0.8, 0.22)
	return node
