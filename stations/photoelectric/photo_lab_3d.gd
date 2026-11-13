extends Node3D
## A vacuum tube makes photon threshold, electron flow, current and gate response visible.

const Photo = preload("res://stations/photoelectric/photo_sim.gd")

var frequency := 4.3e14
var intensity := 1.0
var current_ua := 0.0
var electron_energy := 0.0
var metal: StringName = &"cesium"
var faulty_display := false
var door_open := false
var door_burned := false

var _clock := 0.0
var _bulb: MeshInstance3D
var _beam: MeshInstance3D
var _beam_material: StandardMaterial3D
var _cathode: MeshInstance3D
var _meter_needle: Node3D
var _gate: Node3D
var _gate_leaf: MeshInstance3D
var _gate_lamp: MeshInstance3D
var _gate_material: StandardMaterial3D
var _door_material: StandardMaterial3D
var _photon_nodes: Array[MeshInstance3D] = []
var _electron_nodes: Array[MeshInstance3D] = []


func _ready() -> void:
	_build_scene()
	_sync_materials()


func set_conditions(next_frequency: float, next_intensity: float, next_current: float, next_energy: float,
		next_metal: StringName, faulty: bool, opened: bool, burned: bool, electron_positions: Array) -> void:
	frequency = next_frequency
	intensity = next_intensity
	current_ua = next_current
	electron_energy = next_energy
	metal = next_metal
	faulty_display = faulty
	door_open = opened
	door_burned = burned
	_sync_materials()
	_sync_particles(electron_positions)
	_sync_gate()


func _process(delta: float) -> void:
	_clock += delta
	var phi: float = Photo.METALS[metal]["phi"]
	var active := Photo.photon_energy(frequency) > phi
	var photon_count := int(lerpf(2.0, 12.0, clampf(intensity, 0.0, 1.0)))
	while _photon_nodes.size() < photon_count:
		var photon := _sphere("Photon_%02d" % _photon_nodes.size(), Vector3.ZERO, 0.045, Color.WHITE, true)
		_photon_nodes.append(photon)
	for i in _photon_nodes.size():
		var photon := _photon_nodes[i]
		photon.visible = i < photon_count and active
		if photon.visible:
			var u := fposmod(float(i) / float(maxi(photon_count, 1)) + _clock * (0.8 + frequency / 2e15), 1.0)
			photon.position = Vector3(-2.38 + u * 1.15, 0.18 + sin(u * TAU + _clock * 3.0) * 0.05, 0.06 + sin(i * 2.1) * 0.3)
	for i in _electron_nodes.size():
		var electron := _electron_nodes[i]
		electron.rotation.y = _clock * 2.0
		electron.scale = Vector3.ONE * (0.8 + 0.2 * sin(_clock * 5.0 + i))
	var pulse := 0.93 + 0.07 * sin(_clock * 5.0)
	if _bulb:
		_bulb.scale = Vector3.ONE * pulse
	if _gate_lamp:
		_gate_lamp.scale = Vector3.ONE * (0.94 + 0.06 * sin(_clock * (3.0 if door_open else 1.2)))


func _build_scene() -> void:
	_add_floor()
	# Source housing and frequency filter.
	_box("LampHousing", Vector3(-2.45, 0.2, 0.0), Vector3(0.7, 0.9, 0.75), Color("#263b4b"))
	_box("LampBase", Vector3(-2.45, -0.27, 0.0), Vector3(0.88, 0.12, 0.86), Color("#8194a1"))
	_cylinder("FilterWheel", Vector3(-1.7, 0.2, 0.0), 0.27, 0.1, Color("#7e91a0"), 24, Vector3(0, 0, PI / 2.0))
	for i in 3:
		_sphere("FilterIndex%d" % i, Vector3(-1.7, 0.48 - i * 0.27, 0.08), 0.045, [Color("#e55242"), Color("#f0af4b"), Color("#5799ea")][i])
	_add_text("FilterLabel", "FİLTRE  /  λ", Vector3(-1.7, -0.52, 0.08), Color("#b9ced6"), 22)
	_bulb = _sphere("EmissiveLamp", Vector3(-2.0, 0.2, 0.0), 0.21, Color.WHITE, true)
	_add_text("LampLabel", "LAMBA  /  f", Vector3(-2.45, 0.86, 0.03), Color("#dfeaf0"), 30)
	# Sealed chamber: transparent tube barrel with clear, separate vacuum ends.
	_cylinder("VacuumTube", Vector3(-0.05, 0.18, 0), 0.67, 2.05, Color(0.3, 0.73, 0.89, 0.13), 48, Vector3(0, 0, PI / 2.0), true)
	for x in [-1.08, 0.98]:
		_cylinder("TubeRim", Vector3(x, 0.18, 0), 0.67, 0.12, Color("#8dbac8"), 48, Vector3(0, 0, PI / 2.0))
	# Cathode is the left plate receiving photons; anode collects emitted electrons.
	_cathode = _box("CesiumCathode", Vector3(-0.74, 0.18, 0), Vector3(0.1, 0.98, 0.82), Color("#e6b46e"))
	_box("CathodeBackContact", Vector3(-0.84, 0.18, 0), Vector3(0.11, 1.14, 0.92), Color("#677f8d"))
	_box("AnodeCollector", Vector3(0.74, 0.18, 0), Vector3(0.12, 0.98, 0.82), Color("#85b7c6"))
	_box("CathodeWire", Vector3(-0.72, -0.58, 0), Vector3(0.055, 0.95, 0.06), Color("#e4ac60"))
	_box("AnodeWire", Vector3(0.74, -0.58, 0), Vector3(0.055, 0.95, 0.06), Color("#65aab8"))
	_add_text("CathodeLabel", "KATOT  /  Cs", Vector3(-0.77, 0.92, 0), Color("#f5d79e"), 25)
	_add_text("AnodeLabel", "ANOT", Vector3(0.76, 0.92, 0), Color("#b7e6ea"), 25)
	# Beam is active only when a photon can exceed the work function.
	_beam_material = _material(Color("#f6c45f"), true)
	_beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam = _box("PhotonBeam", Vector3(-1.42, 0.18, 0), Vector3(1.16, 0.035, 0.035), Color.WHITE, Vector3.ZERO, true)
	_beam.material_override = _beam_material
	# Ruler marks on the optical axis show source-to-cathode alignment.
	for i in 5:
		_box("AxisMark%d" % i, Vector3(-2.0 + i * 0.25, -0.37, 0.55), Vector3(0.025, 0.13, 0.025), Color("#7f99a8"))
	# Current meter is an instrument panel, not a decorative icon.
	_box("MeterBody", Vector3(-0.04, 1.18, 0.0), Vector3(1.05, 0.42, 0.22), Color("#1c2a38"))
	_box("MeterFace", Vector3(-0.04, 1.18, 0.13), Vector3(0.84, 0.29, 0.035), Color("#d5e2df"))
	for i in 5:
		_box("MeterTick%d" % i, Vector3(-0.34 + i * 0.15, 1.14, 0.158), Vector3(0.018, 0.06, 0.015), Color("#344b58"))
	_meter_needle = Node3D.new()
	_meter_needle.name = "MeterNeedlePivot"
	_meter_needle.position = Vector3(-0.04, 1.18, 0.19)
	add_child(_meter_needle)
	_box("MeterNeedle", Vector3(0.0, 0.09, 0), Vector3(0.018, 0.19, 0.015), Color("#cf603e"), Vector3(0, 0, -0.55), false, _meter_needle)
	_add_text("MeterLabel", "µA  /  AMPERMETRE", Vector3(-0.04, 1.55, 0.13), Color("#e2eff2"), 24)
	# Stopping-voltage control and the archival interlock door.
	_cylinder("VoltageDial", Vector3(0.72, -0.81, 0.0), 0.2, 0.08, Color("#dfaa56"), 32)
	_add_text("VoltageLabel", "V_durdurma", Vector3(0.72, -1.1, 0.05), Color("#f0ca86"), 22)
	_gate = Node3D.new()
	_gate.name = "ArchiveGate"
	_gate.position = Vector3(1.92, 0.15, -0.06)
	add_child(_gate)
	_box("GateLeftPost", Vector3(-0.38, 0.56, 0), Vector3(0.12, 1.18, 0.16), Color("#708696"), Vector3.ZERO, false, _gate)
	_box("GateRightPost", Vector3(0.38, 0.56, 0), Vector3(0.12, 1.18, 0.16), Color("#708696"), Vector3.ZERO, false, _gate)
	_box("GateHeader", Vector3(0, 1.14, 0), Vector3(0.88, 0.13, 0.18), Color("#708696"), Vector3.ZERO, false, _gate)
	_gate_leaf = _box("DoorLeaf", Vector3(0, 0.52, 0.05), Vector3(0.62, 1.0, 0.08), Color("#506b7c"), Vector3.ZERO, false, _gate)
	_gate_lamp = _sphere("GateStatus", Vector3(0, 1.32, 0.02), 0.1, Color("#df5f54"), true, _gate)
	_gate_material = _gate_lamp.material_override as StandardMaterial3D
	_door_material = _gate_leaf.material_override as StandardMaterial3D
	_add_text("GateLabel", "ARSİV", Vector3(0, 1.52, 0.08), Color("#d7e5e9"), 25, _gate)
	# Plinth makes the glass tube and grounded leads read as one apparatus.
	_box("InstrumentBase", Vector3(-0.05, -1.0, 0.0), Vector3(4.6, 0.13, 1.5), Color("#10202e"))
	_box("BaseAccent", Vector3(-0.05, -0.92, 0.0), Vector3(4.2, 0.025, 1.22), Color("#245164"), Vector3.ZERO, true)
	var camera := get_node("Camera3D") as Camera3D
	camera.look_at(Vector3(-0.12, 0.24, 0), Vector3.UP)


func _sync_materials() -> void:
	if not is_instance_valid(_bulb):
		return
	var color: Color = Photo.light_color(frequency)
	var bulb_material := _bulb.material_override as StandardMaterial3D
	bulb_material.albedo_color = color
	bulb_material.emission = color
	bulb_material.emission_energy_multiplier = 0.25 + intensity * 2.0
	_bulb.scale = Vector3.ONE * (0.48 + intensity * 0.52)
	var beam_color := color
	beam_color.a = 0.08 + intensity * 0.26 if Photo.photon_energy(frequency) <= Photo.METALS[metal]["phi"] else 0.24 + intensity * 0.55
	_beam_material.albedo_color = beam_color
	_beam_material.emission = color
	_beam_material.emission_energy_multiplier = 0.25 + intensity * 1.5
	for photon in _photon_nodes:
		var photon_material := photon.material_override as StandardMaterial3D
		photon_material.albedo_color = color
		photon_material.emission = color
		photon_material.emission_energy_multiplier = 1.8
	var cathode_material := _cathode.material_override as StandardMaterial3D
	cathode_material.albedo_color = Color("#c7a56e") if metal == &"cesium" else Color("#9ba9b4")
	var meter_angle := lerpf(-1.05, 1.05, clampf(current_ua / 8.0, 0.0, 1.0))
	_meter_needle.rotation.z = meter_angle * 0.55


func _sync_particles(positions: Array) -> void:
	while _electron_nodes.size() < positions.size():
		var node := _sphere("Electron_%02d" % _electron_nodes.size(), Vector3.ZERO, 0.06, Color("#6fe3c1"), true)
		_electron_nodes.append(node)
	for i in _electron_nodes.size():
		var node := _electron_nodes[i]
		if i >= positions.size():
			node.visible = false
			continue
		var data: Dictionary = positions[i]
		node.visible = true
		node.position = Vector3(-0.62 + clampf(float(data.x), 0.0, 1.0) * 1.26, 0.18 + float(data.y) * 0.58, sin(i * 1.7 + _clock) * 0.17)


func _sync_gate() -> void:
	if not is_instance_valid(_gate_leaf):
		return
	var target_y := 0.98 if door_open else 0.52
	_gate_leaf.position.y = lerpf(_gate_leaf.position.y, target_y, 0.25)
	var color := Color("#69ddb9") if door_open else Color("#e05c55") if door_burned else Color("#d89f52")
	_gate_material.albedo_color = color
	_gate_material.emission = color
	_door_material.albedo_color = Color("#315e63") if door_open else Color("#804a42") if door_burned else Color("#506b7c")


func _add_floor() -> void:
	_box("Backdrop", Vector3(0, -1.26, -0.55), Vector3(5.7, 0.12, 3.4), Color("#0b1b29"))
	for i in 7:
		_box("FloorLine%d" % i, Vector3(-2.55 + i * 0.82, -1.185, -0.55), Vector3(0.018, 0.012, 3.2), Color("#183648"))
	for i in 4:
		_box("FloorCross%d" % i, Vector3(0, -1.184, -1.7 + i * 0.78), Vector3(5.3, 0.012, 0.018), Color("#183648"))


func _material(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.24
	material.roughness = 0.4
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.15
	return material


func _box(id: String, position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO,
		glow := false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = _material(color, glow)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	(parent if parent != null else self).add_child(instance)
	return instance


func _sphere(id: String, position: Vector3, radius: float, color: Color, glow := false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color, glow)
	(parent if parent != null else self).add_child(instance)
	return instance


func _cylinder(id: String, position: Vector3, radius: float, height: float, color: Color, segments := 24,
		rotation := Vector3.ZERO, transparent := false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = _material(color)
	if transparent:
		var material := instance.material_override as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if transparent else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)
	return instance


func _add_text(id: String, value: String, position: Vector3, color: Color, font_size: int, parent: Node3D = null) -> void:
	var label := Label3D.new()
	label.name = id
	label.text = value
	label.position = position
	label.font_size = font_size
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color("#07111a")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	(parent if parent != null else self).add_child(label)
