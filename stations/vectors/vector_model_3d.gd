extends Node3D

const Capsule = preload("res://stations/vectors/assets/capsule.tscn")
const Dock = preload("res://stations/vectors/assets/dock.tscn")

var _components: Node3D
var _capsule: Node3D
var _dock: Node3D
var _scale := 0.32
var _method := 0
var _stage := 0
var _revealed := false
var _route_draw := 0.0
var _attempted := false
var _attempt := Vector2.ZERO
var _position := Vector2.ZERO
var _docked := false

func _ready() -> void:
	_build_deck()
	_components = Node3D.new()
	_components.name = "Components"
	add_child(_components)
	_dock = Dock.instantiate()
	_dock.name = "Dock"
	_dock.scale = Vector3(0.55, 0.55, 0.55)
	add_child(_dock)
	_capsule = Capsule.instantiate()
	_capsule.name = "CargoCapsule"
	_capsule.scale = Vector3(0.43, 0.43, 0.43)
	add_child(_capsule)
	_update()

func set_state(stage: int, method: int, revealed: bool, route_draw: float, attempted: bool, attempt: Vector2, position: Vector2, docked: bool) -> void:
	_stage = stage
	_method = method
	_revealed = revealed
	_route_draw = route_draw
	_attempted = attempted
	_attempt = attempt
	_position = position
	_docked = docked
	_update()

func _build_deck() -> void:
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(9.2, 9.2)
	floor.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("#152635")
	floor_mat.roughness = 0.8
	floor.material_override = floor_mat
	floor.position.y = -0.06
	add_child(floor)
	for i in range(-6, 7):
		var color := Color("#375063") if i == 0 else Color("#263b4a")
		_line(Vector3(i * 0.65, 0.005, -3.9), Vector3(i * 0.65, 0.005, 3.9), color, 0.007 if i != 0 else 0.015)
		_line(Vector3(-3.9, 0.006, i * 0.65), Vector3(3.9, 0.006, i * 0.65), color, 0.007 if i != 0 else 0.015)
	_line(Vector3(-4.1, 0.008, 0), Vector3(4.1, 0.008, 0), Color("#a4bac2"), 0.018)
	_line(Vector3(0, 0.008, -4.1), Vector3(0, 0.008, 4.1), Color("#a4bac2"), 0.018)

func _update() -> void:
	if _components == null:
		return
	for child in _components.get_children():
		_components.remove_child(child)
		child.free()
	var target := Vector2(5, -12) if _stage == 2 else Vector2(3, 4)
	var end := _xyz(target)
	_dock.position = end + Vector3(0, 0.04, 0)
	var dock_script := _dock
	if dock_script.has_method("set_docked"):
		dock_script.call("set_docked", _docked)
	_capsule.position = _xyz(_position) + Vector3(0, 0.24, 0)
	_capsule.visible = _attempted or _stage == 0
	if _stage == 0:
		_add_arrow(_components, Vector3.ZERO, _xyz(Vector2(7, 0)), Color("#ffc082"))
	elif _stage == 1:
		if _method == 0:
			_add_arrow(_components, Vector3.ZERO, _xyz(Vector2(3, 0)), Color("#77dfba"))
			_add_arrow(_components, _xyz(Vector2(3, 0)), end, Color("#80b8e5"))
		else:
			_add_arrow(_components, Vector3.ZERO, _xyz(Vector2(3, 0)), Color("#77dfba"))
			_add_arrow(_components, Vector3.ZERO, _xyz(Vector2(0, 4)), Color("#80b8e5"))
			_line(_xyz(Vector2(3, 0)), end, Color("#80b8e5", 0.55), 0.018)
			_line(_xyz(Vector2(0, 4)), end, Color("#77dfba", 0.55), 0.018)
		if _revealed and _route_draw > 0.0:
			_add_arrow(_components, Vector3.ZERO, end * _route_draw, Color("#ffc082"))
	elif _attempted:
		_add_arrow(_components, Vector3.ZERO, _xyz(_attempt), Color("#77dfba") if _docked else Color("#ffc082"))

func _xyz(point: Vector2) -> Vector3:
	return Vector3(point.x * _scale, 0.0, -point.y * _scale)

func _add_arrow(parent: Node3D, start: Vector3, finish: Vector3, color: Color) -> void:
	var direction := finish - start
	if direction.length() < 0.04:
		return
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.025
	shaft_mesh.bottom_radius = 0.025
	shaft_mesh.height = maxf(direction.length() - 0.12, 0.01)
	shaft.mesh = shaft_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.18
	shaft.material_override = mat
	shaft.position = start.lerp(finish, 0.5)
	shaft.position.y = 0.1
	shaft.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	parent.add_child(shaft)
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.085
	cone.height = 0.18
	tip.mesh = cone
	tip.material_override = mat
	tip.position = finish + Vector3(0, 0.1, 0)
	tip.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	parent.add_child(tip)

func _line(start: Vector3, finish: Vector3, color: Color, radius: float) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(finish)
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	instance.position = (start + finish) * 0.5
	instance.basis = Basis(Quaternion(Vector3.UP, (finish - start).normalized()))
	add_child(instance)
