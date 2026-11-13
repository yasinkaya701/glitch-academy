extends SubViewportContainer
## Isometric 3D harbor view synchronized with the mission's existing vector model.

const CapsuleScene := preload("res://stations/vectors/assets/capsule.tscn")
const DockScene := preload("res://stations/vectors/assets/dock.tscn")
const INK := Color("#e9f1ee")
const GOLD := Color("#ffc082")
const JADE := Color("#77dfba")
const SKY := Color("#80b8e5")
const SCALE := 0.20

var _model: Node3D
var _capsule: Node3D
var _dock: Node3D
var _destination_label: Label3D
var _route_segments: Array[MeshInstance3D] = []
var _route_heads: Array[MeshInstance3D] = []
var _route_materials: Array[StandardMaterial3D] = []
var _current := Vector2.ZERO
var _destination := Vector2(3, 4)
var _attempt := Vector2.ZERO
var _stage := 0
var _method := 0
var _route_draw := 0.0
var _revealed := false
var _attempted := false
var _docked := false


func _ready() -> void:
	_model = get_node("Viewport/World/Model")
	_build_harbor()
	_sync_scene()


func set_mission_state(stage: int, destination: Vector2, current: Vector2,
		route_draw: float, revealed: bool, method: int, attempted: bool,
		attempt: Vector2, docked: bool) -> void:
	_stage = stage
	_destination = destination
	_current = current
	_route_draw = route_draw
	_revealed = revealed
	_method = method
	_attempted = attempted
	_attempt = attempt
	_docked = docked
	if is_node_ready():
		_sync_scene()


func _build_harbor() -> void:
	var pier := _box("DockPlatform", Vector3(2.35, 0.18, 2.85), Vector3.ZERO, Color("#536e79"), _model, 0.35)
	pier.position = Vector3(0.0, -0.04, 0.0)
	_box("PlatformStripe", Vector3(2.02, 0.025, 2.51), Vector3(0.0, 0.064, 0.0), Color("#78919a"), _model, 0.15)
	var launch_pad := _cylinder("LaunchPad", 0.52, 0.60, 0.08, _model, Color("#435f69"))
	launch_pad.position = Vector3(0.0, -0.005, 0.0)
	_torus("LaunchRing", Vector3(0.0, 0.04, 0.0), 0.40, 0.47, Color("#76c6bc"), _model)
	var launch_beacon := _sphere("LaunchBeacon", 0.095, 0.095, _model, Color("#e5e5bd"), true)
	launch_beacon.position = Vector3(0, 0.12, 0)
	for x in [-0.92, 0.92]:
		for z in [-1.13, 1.13]:
			var pile := _cylinder("Pile", 0.11, 0.09, 0.92, _model, Color("#3c5965"))
			pile.position = Vector3(x, -0.5, z)
			var cap := _cylinder("PileCap", 0.13, 0.13, 0.06, _model, Color("#91a8ae"))
			cap.position = Vector3(x, -0.02, z)
			var lamp := _sphere("MooringLamp", 0.08, 0.08, _model, GOLD, true)
			lamp.position = Vector3(x, 0.1, z)

	# Numbered waypoints and coordinate axes keep the 3D view tied to the vector lesson.
	for index in range(-3, 4):
		var gx := float(index) * 0.5
		var grid_x := _box("EastGrid", Vector3(0.012, 0.008, 7.6), Vector3(gx, -0.045, 0), Color(INK, 0.085), _model)
		(grid_x.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var grid_z := _box("NorthGrid", Vector3(7.6, 0.008, 0.012), Vector3(0, -0.044, gx), Color(INK, 0.085), _model)
		(grid_z.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var x_axis := _box("EastAxis", Vector3(7.8, 0.019, 0.03), Vector3(0, -0.025, 0), SKY, _model, 0.0, true)
	var north_axis := _box("NorthAxis", Vector3(0.03, 0.02, 7.8), Vector3(0, -0.023, 0), JADE, _model, 0.0, true)
	_label("EastLabel", "DOĞU  +x", Vector3(2.95, 0.01, -0.18), SKY, _model)
	_label("NorthLabel", "KUZEY  +y", Vector3(0.12, 0.01, -3.12), JADE, _model)
	_label("OriginLabel", "KALKIŞ  (0, 0)", Vector3(-1.05, 0.10, 0.24), INK, _model)

	for index in 5:
		var material := StandardMaterial3D.new()
		material.albedo_color = GOLD if index % 2 == 0 else JADE
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.05
		_route_materials.append(material)
		var segment := MeshInstance3D.new()
		segment.name = "CourseSegment%d" % index
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.025
		cylinder.bottom_radius = 0.025
		cylinder.height = 1.0
		cylinder.radial_segments = 10
		segment.mesh = cylinder
		segment.material_override = material
		_model.add_child(segment)
		_route_segments.append(segment)
		var head := MeshInstance3D.new()
		head.name = "CourseHead%d" % index
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.085
		cone.height = 0.18
		cone.radial_segments = 12
		head.mesh = cone
		head.material_override = material
		_model.add_child(head)
		_route_heads.append(head)

	_dock = DockScene.instantiate()
	_dock.name = "DestinationDock"
	_dock.scale = Vector3.ONE * 0.38
	_model.add_child(_dock)
	_capsule = CapsuleScene.instantiate()
	_capsule.name = "RescueCapsule"
	_capsule.scale = Vector3.ONE * 0.40
	_model.add_child(_capsule)
	_destination_label = _label("TargetReadout", "", Vector3.ZERO, GOLD, _model)
	_add_buoy("BuoyWest", Vector3(-2.9, 0.0, 1.75), Color("#f0a26e"))
	_add_buoy("BuoyEast", Vector3(2.85, 0.0, -1.85), Color("#70c5bc"))


func _add_buoy(id: String, position: Vector3, color: Color) -> void:
	var float_base := _cylinder(id + "Foot", 0.13, 0.18, 0.08, _model, Color("#25434f"))
	float_base.position = position + Vector3(0, -0.01, 0)
	var body := _cylinder(id + "Body", 0.075, 0.12, 0.36, _model, color)
	body.position = position + Vector3(0, 0.2, 0)
	var lamp := _sphere(id + "Light", 0.075, 0.075, _model, color, true)
	lamp.position = position + Vector3(0, 0.43, 0)


func _sync_scene() -> void:
	if _dock == null or _capsule == null:
		return
	var dock_position := _world_point(_destination)
	_dock.position = dock_position
	_dock.position.y = 0.02
	if _dock.has_method("set_docked"):
		_dock.set_docked(_docked)
	_destination_label.text = "HEDEF  (%s, %s)" % [_format(_destination.x), _format(_destination.y)]
	_destination_label.position = dock_position + Vector3(0.20, 0.58, -0.30)
	var capsule_position := _world_point(_current)
	_capsule.position = capsule_position + Vector3(0, 0.05, 0)
	var heading := _destination - _current
	if heading.length_squared() > 0.001:
		var direction := Vector3(heading.x, 0, -heading.y).normalized()
		_capsule.rotation.y = atan2(direction.x, -direction.z)
	_update_course()


func _update_course() -> void:
	for index in _route_segments.size():
		_route_segments[index].visible = false
		_route_heads[index].visible = false
	var route_starts: Array[Vector2] = []
	var route_ends: Array[Vector2] = []
	var route_colors: Array[Color] = []
	if _stage == 0:
		route_starts.append(Vector2.ZERO)
		route_ends.append(Vector2(7, 0))
		route_colors.append(GOLD)
	elif _stage == 1 and _revealed:
		var east := Vector2(3, 0)
		var north := Vector2(0, 4)
		if _method == 0:
			route_starts.append(Vector2.ZERO)
			route_ends.append(east)
			route_colors.append(JADE)
			route_starts.append(east)
			route_ends.append(_destination)
			route_colors.append(SKY)
			route_starts.append(Vector2.ZERO)
			route_ends.append(_destination)
			route_colors.append(GOLD)
		else:
			route_starts.append(Vector2.ZERO)
			route_ends.append(east)
			route_colors.append(JADE)
			route_starts.append(Vector2.ZERO)
			route_ends.append(north)
			route_colors.append(SKY)
			route_starts.append(east)
			route_ends.append(_destination)
			route_colors.append(Color("#4c8d8c"))
			route_starts.append(north)
			route_ends.append(_destination)
			route_colors.append(Color("#4c819a"))
		route_starts.append(Vector2.ZERO)
		route_ends.append(_destination)
		route_colors.append(GOLD)
	elif _stage >= 2 and _attempted:
		route_starts.append(Vector2.ZERO)
		route_ends.append(_attempt)
		route_colors.append(JADE if _docked else GOLD)
	var segment_count := mini(route_starts.size(), _route_segments.size())
	for index in segment_count:
		var from_point := _world_point(route_starts[index])
		var to_point := _world_point(route_ends[index])
		if _stage == 1 and index == segment_count - 1:
			to_point = from_point.lerp(to_point, _route_draw)
		if from_point.distance_squared_to(to_point) < 0.005:
			continue
		var line := _route_segments[index]
		var delta := to_point - from_point
		line.visible = true
		var head := _route_heads[index]
		head.visible = true
		line.material_override = _route_materials[index]
		line.material_override.albedo_color = route_colors[index]
		line.material_override.emission = route_colors[index]
		head.material_override = line.material_override
		line.position = (from_point + to_point) * 0.5 + Vector3(0, 0.12, 0)
		line.scale.y = delta.length()
		line.quaternion = Quaternion(Vector3.UP, delta.normalized())
		head.position = to_point + Vector3(0, 0.12, 0)
		head.quaternion = Quaternion(Vector3.UP, delta.normalized())


func _world_point(vector: Vector2) -> Vector3:
	return Vector3(vector.x * SCALE, 0.0, -vector.y * SCALE)


func _format(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _mat(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	material.metallic = 0.22
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	return material


func _box(id: String, size: Vector3, position: Vector3, color: Color, parent: Node3D, yaw := 0.0, glow := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = position
	instance.rotation.y = yaw
	instance.material_override = _mat(color, glow)
	parent.add_child(instance)
	return instance


func _cylinder(id: String, top_radius: float, bottom_radius: float, height: float, parent: Node3D, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.material_override = _mat(color)
	parent.add_child(instance)
	return instance


func _sphere(id: String, radius: float, height: float, parent: Node3D, color: Color, glow := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.material_override = _mat(color, glow)
	parent.add_child(instance)
	return instance


func _torus(id: String, position: Vector3, inner_radius: float, outer_radius: float, color: Color, parent: Node3D) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 48
	mesh.ring_segments = 8
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = position
	instance.scale.y = 0.24
	instance.material_override = _mat(color, true)
	parent.add_child(instance)
	return instance


func _label(id: String, value: String, position: Vector3, color: Color, parent: Node3D) -> Label3D:
	var label := Label3D.new()
	label.name = id
	label.text = value
	label.position = position
	label.font_size = 26
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("#06151e")
	parent.add_child(label)
	return label
