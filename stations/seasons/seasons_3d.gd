extends Node3D
## Mevsimler gözlemevi (3B): Güneş, Dünya, yörünge ve iki enlemdeki öğle ışınları.
## Dünya'nın ekseni yörünge boyunca aynı yöne bakar; tarih değişince Dünya yarım çember boyunca gezer.
## Işın açıları seasons_model.gd ile aynı formülden gelir, sahnedeki geometri aynı sonucu gösterir.

const Model = preload("res://stations/seasons/seasons_model.gd")
const EARTH_TEXTURE = preload("res://stations/seasons/assets/earth_albedo_4k.jpg")
const SUN_TEXTURE = preload("res://stations/seasons/assets/sun_photosphere_4k.jpg")

const ORBIT_RADIUS := 3.1
const SUN_RADIUS := 0.78
const EARTH_RADIUS := 0.7
const TRAVEL_SPEED := 0.8

const SAGE := Color("8fbea0")
const AMBER := Color("dfae63")
const PAPER := Color("e9e5db")
const ALERT := Color("d9705f")

var _december := false
var _tilt := Model.AXIAL_TILT
var _show_greenhouse := true
var _repaired := false
var _time := 0.0
var _progress := 0.0  ## 0 = 21 Haziran konumu, 1 = 21 Aralık konumu

var _earth: Node3D
var _earth_mesh: MeshInstance3D
var _axis_beam: MeshInstance3D
var _tilt_label: Label3D
var _ghosts := {}
var _markers := {}
var _greenhouse: Node3D
var _greenhouse_label: Label3D
var _greenhouse_scale := 1.7
var _greenhouse_core: StandardMaterial3D
var _camera: Camera3D


func _ready() -> void:
	_clear_studio_stage()
	_build_sun()
	_build_orbit()
	_build_stars()
	_build_earth()
	_build_ghosts()
	_build_markers()
	_build_greenhouse()
	_camera = Camera3D.new()
	_camera.fov = 44.0
	_camera.position = Vector3(0.0, 2.7, 8.4)
	add_child(_camera)
	_camera.look_at(Vector3(0.0, -0.1, 0.4), Vector3.UP)
	_camera.current = true
	_apply_state(true)


## Ortak deney sahnesinin masa, zemin ve ölçüm ızgarası uzayda süzülen gözlemevini kesmesin.
func _clear_studio_stage() -> void:
	var world := get_parent().get_parent() if get_parent() != null else null
	if world == null:
		return
	var environment := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment != null and environment.environment != null:
		environment.environment = environment.environment.duplicate()
		environment.environment.fog_enabled = false
		environment.environment.background_color = Color("0b0e14")
	for node_name in ["StudioFloor", "StageTop", "StageRim", "MeasurementGrid"]:
		var stage := world.get_node_or_null(node_name)
		if stage is Node3D:
			(stage as Node3D).visible = false


func set_state(is_december: bool, axial_tilt: float, show_greenhouse: bool, is_repaired: bool, time: float) -> void:
	_december = is_december
	_tilt = axial_tilt
	_show_greenhouse = show_greenhouse
	_repaired = is_repaired
	_time = time
	if _earth != null:
		_apply_state(false)


func _process(delta: float) -> void:
	var goal := 1.0 if _december else 0.0
	_progress = move_toward(_progress, goal, delta * TRAVEL_SPEED)
	_apply_state(false)


# --- Durum ----------------------------------------------------------------------------

func _axis() -> Vector3:
	return Vector3(sin(deg_to_rad(_tilt)), cos(deg_to_rad(_tilt)), 0.0).normalized()


func _earth_position(progress: float) -> Vector3:
	var smooth := smoothstep(0.0, 1.0, progress)
	return Vector3(-cos(PI * smooth), 0.0, sin(PI * smooth)) * ORBIT_RADIUS


func _apply_state(force: bool) -> void:
	if _earth == null:
		return
	var axis := _axis()
	var position := _earth_position(_progress)
	_earth.position = position
	_orient_y(_earth_mesh, axis)
	_place_axis(_axis_beam, position, axis, EARTH_RADIUS + 0.55)
	_ghosts["june"].visible = _progress > 0.03
	_ghosts["december"].visible = _progress < 0.97
	for key in _ghosts:
		var ghost: Node3D = _ghosts[key]
		_place_axis(ghost.get_node("Axis"), ghost.position, axis, EARTH_RADIUS + 0.5)
		_orient_y(ghost.get_node("Mesh"), axis)
	_tilt_label.text = "EKSEN %s°" % _decimal(_tilt) if _tilt > 0.05 else "EKSEN EĞİK DEĞİL · 0°"
	_tilt_label.position = position + Vector3(0.0, EARTH_RADIUS + 0.95, 0.0)
	var settled := absf(_progress - (1.0 if _december else 0.0)) < 0.02
	_update_marker(&"north", 40.0, position, axis, settled)
	_update_marker(&"south", -40.0, position, axis, settled)
	_update_greenhouse(position, axis, settled)


func _update_marker(key: StringName, latitude: float, center: Vector3, axis: Vector3, settled: bool) -> void:
	var marker: Dictionary = _markers[key]
	var to_sun := (-center).normalized()
	var perpendicular := to_sun - axis * to_sun.dot(axis)
	if perpendicular.length() < 0.001:
		perpendicular = Vector3.FORWARD
	perpendicular = perpendicular.normalized()
	var normal := (perpendicular * cos(deg_to_rad(latitude)) + axis * sin(deg_to_rad(latitude))).normalized()
	var point := center + normal * (EARTH_RADIUS + 0.012)
	var pin: Node3D = marker["pin"]
	pin.position = point
	var horizon: MeshInstance3D = marker["horizon"]
	horizon.position = point + normal * 0.006
	_orient_y(horizon, normal)
	var start := Vector3.ZERO + (point - Vector3.ZERO).normalized() * SUN_RADIUS
	_place_beam(marker["ray"], start, point)
	var sample := Model.sample(latitude, _december, _tilt)
	var label: Label3D = marker["label"]
	label.position = point + normal * 0.4 + Vector3(0.0, 0.06 if latitude > 0.0 else 0.22, 0.0)
	label.text = "%s · %s°" % ["40° K" if latitude > 0.0 else "40° G", _decimal(sample.x)]
	label.visible = settled
	var lit := normal.dot(to_sun) > 0.0
	marker["ray"].visible = lit
	pin.visible = true


func _update_greenhouse(center: Vector3, axis: Vector3, settled: bool) -> void:
	if _greenhouse == null:
		return
	_greenhouse.visible = _show_greenhouse
	_greenhouse_label.visible = _show_greenhouse and settled
	if not _show_greenhouse:
		return
	var to_sun := (-center).normalized()
	var perpendicular := (to_sun - axis * to_sun.dot(axis)).normalized()
	var latitude := -40.0
	var normal := (perpendicular * cos(deg_to_rad(latitude)) + axis * sin(deg_to_rad(latitude))).normalized()
	var offset_normal := (perpendicular * cos(deg_to_rad(latitude - 7.0)) + axis * sin(deg_to_rad(latitude - 7.0))).normalized()
	_greenhouse.position = center + offset_normal * (EARTH_RADIUS + 0.02)
	_orient_y(_greenhouse, offset_normal)
	_greenhouse.scale = Vector3.ONE * _greenhouse_scale
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	if _repaired:
		_greenhouse_core.albedo_color = SAGE
		_greenhouse_core.emission = SAGE
		_greenhouse_label.text = "SERA ÇALIŞIYOR"
		_greenhouse_label.modulate = SAGE
	else:
		var warn := ALERT.lerp(Color("f2a98f"), pulse)
		_greenhouse_core.albedo_color = warn
		_greenhouse_core.emission = warn
		_greenhouse_label.text = "KIŞ UYARISI"
		_greenhouse_label.modulate = warn
	_greenhouse_label.position = _greenhouse.position + Vector3(0.0, -0.46, 0.0)


# --- Kurulum --------------------------------------------------------------------------

func _build_sun() -> void:
	var sun := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = SUN_RADIUS
	mesh.height = SUN_RADIUS * 2.0
	mesh.radial_segments = 64
	mesh.rings = 32
	var material := StandardMaterial3D.new()
	material.albedo_texture = SUN_TEXTURE
	material.emission_enabled = true
	material.emission_texture = SUN_TEXTURE
	material.emission_energy_multiplier = 1.6
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	sun.mesh = mesh
	sun.name = "Sun"
	add_child(sun)
	var light := OmniLight3D.new()
	light.light_color = Color("fff1d2")
	light.light_energy = 5.5
	light.omni_range = 16.0
	light.omni_attenuation = 0.35
	add_child(light)
	var label := _label("GÜNEŞ", 26, AMBER)
	label.position = Vector3(0.0, SUN_RADIUS + 0.34, 0.0)
	add_child(label)


func _build_orbit() -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = ORBIT_RADIUS - 0.012
	mesh.outer_radius = ORBIT_RADIUS + 0.012
	mesh.rings = 96
	mesh.ring_segments = 6
	ring.mesh = mesh
	ring.material_override = _flat(Color("5b6a66"), 0.55)
	ring.name = "Orbit"
	add_child(ring)


func _build_stars() -> void:
	var stars := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := SphereMesh.new()
	mesh.radius = 0.018
	mesh.height = 0.036
	mesh.radial_segments = 6
	mesh.rings = 3
	multi.mesh = mesh
	multi.instance_count = 160
	var rng := RandomNumberGenerator.new()
	rng.seed = 2111
	for index in multi.instance_count:
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.55, 1), rng.randf_range(-1, 0.25)).normalized()
		multi.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.6, 1.5)), direction * rng.randf_range(11.0, 15.0)))
	stars.multimesh = multi
	stars.material_override = _flat(Color("e8f1f2"), 0.7)
	stars.name = "Stars"
	add_child(stars)


func _earth_material(alpha := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = EARTH_TEXTURE
	material.roughness = 0.88
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1, 1, 1, alpha)
	return material


func _globe(radius: float, material: Material) -> MeshInstance3D:
	var globe := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 64
	mesh.rings = 32
	mesh.material = material
	globe.mesh = mesh
	return globe


func _build_earth() -> void:
	_earth = Node3D.new()
	_earth.name = "Earth"
	add_child(_earth)
	_earth_mesh = _globe(EARTH_RADIUS, _earth_material())
	_earth.add_child(_earth_mesh)
	_axis_beam = _beam_node(PAPER, 0.018)
	add_child(_axis_beam)
	_tilt_label = _label("", 24, PAPER)
	add_child(_tilt_label)


func _build_ghosts() -> void:
	for key in ["june", "december"]:
		var ghost := Node3D.new()
		ghost.position = _earth_position(0.0 if key == "june" else 1.0)
		var mesh := _globe(EARTH_RADIUS, _earth_material(0.3))
		mesh.name = "Mesh"
		ghost.add_child(mesh)
		var axis := _beam_node(Color(PAPER, 0.5), 0.012)
		axis.name = "Axis"
		ghost.add_child(axis)
		var label := _label("21 HAZİRAN" if key == "june" else "21 ARALIK", 26, Color(PAPER, 0.85))
		label.position = Vector3(0.0, -EARTH_RADIUS - 0.42, 0.0)
		ghost.add_child(label)
		add_child(ghost)
		_ghosts[key] = ghost


func _build_markers() -> void:
	for entry in [[&"north", SAGE], [&"south", AMBER]]:
		var tint: Color = entry[1]
		var pin := MeshInstance3D.new()
		var pin_mesh := SphereMesh.new()
		pin_mesh.radius = 0.045
		pin_mesh.height = 0.09
		pin.mesh = pin_mesh
		pin.material_override = _glow(tint)
		add_child(pin)
		var horizon := MeshInstance3D.new()
		var horizon_mesh := CylinderMesh.new()
		horizon_mesh.top_radius = 0.24
		horizon_mesh.bottom_radius = 0.24
		horizon_mesh.height = 0.004
		horizon_mesh.radial_segments = 40
		horizon.mesh = horizon_mesh
		var horizon_material := _flat(tint, 0.32)
		horizon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		horizon.material_override = horizon_material
		add_child(horizon)
		var ray := _beam_node(tint, 0.014)
		ray.material_override = _glow(tint)
		add_child(ray)
		var label := _label("", 28, tint)
		add_child(label)
		_markers[entry[0]] = {"pin": pin, "horizon": horizon, "ray": ray, "label": label}


func _build_greenhouse() -> void:
	_greenhouse_label = _label("", 26, ALERT)
	add_child(_greenhouse_label)
	_greenhouse = Node3D.new()
	_greenhouse.name = "Greenhouse"
	add_child(_greenhouse)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.66, 0.86, 0.82, 0.34)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.12
	glass.metallic = 0.2
	_greenhouse_core = _glow(ALERT)
	var parts := [
		["Walls", BoxMesh.new(), Vector3(0.0, 0.065, 0.0), Vector3(0.36, 0.13, 0.24), glass],
		["Roof", PrismMesh.new(), Vector3(0.0, 0.175, 0.0), Vector3(0.36, 0.09, 0.24), glass],
		["Core", BoxMesh.new(), Vector3(0.0, 0.05, 0.0), Vector3(0.26, 0.07, 0.16), _greenhouse_core],
		["Frame", BoxMesh.new(), Vector3(0.0, 0.222, 0.0), Vector3(0.37, 0.012, 0.012), _flat(PAPER, 1.0)],
	]
	for part in parts:
		var node := MeshInstance3D.new()
		node.name = part[0]
		var mesh: Mesh = part[1]
		if mesh is BoxMesh:
			(mesh as BoxMesh).size = part[3]
		elif mesh is PrismMesh:
			(mesh as PrismMesh).size = part[3]
		node.mesh = mesh
		node.position = part[2]
		node.material_override = part[4]
		_greenhouse.add_child(node)


# --- Geometri yardımcıları ------------------------------------------------------------

func _orient_y(node: Node3D, direction: Vector3) -> void:
	var up := direction.normalized()
	var basis := Basis(Quaternion(Vector3.UP, up))
	node.basis = basis * Basis.IDENTITY.scaled(node.scale)


func _beam_node(color: Color, thickness: float) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = thickness
	mesh.bottom_radius = thickness
	mesh.height = 1.0
	mesh.radial_segments = 8
	beam.mesh = mesh
	beam.material_override = _flat(color, 1.0)
	return beam


func _place_beam(beam: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.001:
		beam.visible = false
		return
	(beam.mesh as CylinderMesh).height = length
	beam.position = (from + to) * 0.5
	var direction := (to - from).normalized()
	beam.basis = Basis(Quaternion(Vector3.UP, direction))


func _place_axis(beam: MeshInstance3D, center: Vector3, axis: Vector3, half_length: float) -> void:
	var local_center := center if beam.get_parent() == self else Vector3.ZERO
	_place_beam(beam, local_center - axis * half_length, local_center + axis * half_length)


func _flat(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _glow(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _label(text: String, font_size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.0075
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color("10110f")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	return label


func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")
