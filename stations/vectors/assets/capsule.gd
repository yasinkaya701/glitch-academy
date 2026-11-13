@tool
extends Node3D

@export var ceramic: Material
@export var frame: Material
@export var glass: Material
@export var amber: Material

const SEGMENTS := 12
const BODY_Y := 0.77
const VERTICAL_SCALE := 0.78


func _ready() -> void:
	if ceramic == null or frame == null or glass == null or amber == null:
		return
	_shell("Nose", -0.98, 0.17, -0.78, 0.38, ceramic)
	_shell("Collar", -0.78, 0.38, -0.59, 0.52, ceramic)
	_shell("ForwardSeal", -0.59, 0.52, -0.545, 0.537, frame)
	_shell("Cabin", -0.545, 0.537, -0.24, 0.61, ceramic)
	_shell("CabinBelt", -0.24, 0.61, -0.188, 0.61, frame)
	_shell("PressureVessel", -0.188, 0.61, 0.52, 0.565, ceramic)
	_shell("AftSeal", 0.52, 0.565, 0.56, 0.555, frame)
	_shell("ThermalCover", 0.56, 0.555, 0.79, 0.46, ceramic)
	_shell("EngineCowl", 0.79, 0.46, 0.91, 0.33, frame)
	_face("ProbeFace", -0.981, 0.17, frame, true)
	_face("EngineBulkhead", 0.91, 0.33, frame, false)

	var cockpit := PackedVector3Array([
		Vector3(-0.26, 1.076, -0.625), Vector3(-0.15, 1.110, -0.646),
		Vector3(0.15, 1.110, -0.646), Vector3(0.26, 1.076, -0.625),
		Vector3(0.33, 1.150, -0.318), Vector3(0.18, 1.239, -0.302),
		Vector3(-0.18, 1.239, -0.302), Vector3(-0.33, 1.150, -0.318)
	])
	_patch("CanopyFrame", cockpit, frame)
	var canopy := PackedVector3Array()
	var center := Vector3(0.0, 1.16, -0.47)
	for point in cockpit:
		canopy.append(center.lerp(point, 0.81) + Vector3(0, 0.005, 0))
	_patch("Canopy", canopy, glass)

	for side in [-1.0, 1.0]:
		var x := float(side)
		var window := PackedVector3Array([
			Vector3(x * 0.390, 1.078, -0.407), Vector3(x * 0.423, 1.026, -0.419),
			Vector3(x * 0.512, 0.986, -0.277), Vector3(x * 0.477, 1.074, -0.244)
		])
		_patch("SideWindow", window, glass)
		var skid := _box("LandingRail", Vector3(0.14, 0.13, 0.93), Vector3(x * 0.43, 0.39, 0.05), frame)
		skid.rotation_degrees.y = x * 3.0
		for depth in [-0.28, 0.33]:
			var mount := _box("LandingMount", Vector3(0.13, 0.20, 0.13), Vector3(x * 0.40, 0.48, depth), ceramic)
			mount.rotation_degrees.z = x * 18.0
		_box("ServiceStripe", Vector3(0.094, 0.018, 0.20), Vector3(x * 0.29, 1.181, 0.23), amber).rotation_degrees.z = x * -28.0
		_box("AftThruster", Vector3(0.14, 0.11, 0.12), Vector3(x * 0.17, BODY_Y - 0.08, 0.96), frame)
	_box("DorsalHatch", Vector3(0.25, 0.021, 0.31), Vector3(0, 1.238, 0.25), frame)
	_box("HatchPanel", Vector3(0.195, 0.024, 0.26), Vector3(0, 1.245, 0.25), ceramic)
	_box("HatchHandle", Vector3(0.09, 0.024, 0.027), Vector3(0, 1.265, 0.30), frame)
	_box("ForwardLocator", Vector3(0.062, 0.025, 0.17), Vector3(0, 0.979, -0.824), amber).rotation_degrees.x = -24.0


func _shell(node_name: String, front: float, front_radius: float, back: float, back_radius: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for index in SEGMENTS:
		var next := index + 1
		var a := _ring(front, front_radius, index)
		var b := _ring(front, front_radius, next)
		var c := _ring(back, back_radius, next)
		var d := _ring(back, back_radius, index)
		for point in [a, c, b, a, d, c]:
			surface.add_vertex(point)
	surface.generate_normals()
	_mesh(node_name, surface.commit(), Vector3.ZERO, material)


func _face(node_name: String, depth: float, radius: float, material: Material, front: bool) -> void:
	var points := PackedVector3Array()
	for index in SEGMENTS:
		var ordered := SEGMENTS - index if front else index
		points.append(_ring(depth, radius, ordered))
	_patch(node_name, points, material)


func _ring(depth: float, radius: float, index: int) -> Vector3:
	var angle := (float(index) + 0.5) * TAU / SEGMENTS
	return Vector3(sin(angle) * radius, BODY_Y + cos(angle) * radius * VERTICAL_SCALE, depth)


func _patch(node_name: String, points: PackedVector3Array, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for index in range(1, points.size() - 1):
		for point in [points[0], points[index], points[index + 1]]:
			surface.add_vertex(point)
		for point in [points[0], points[index + 1], points[index]]:
			surface.add_vertex(point)
	surface.generate_normals()
	_mesh(node_name, surface.commit(), Vector3.ZERO, material)


func _box(node_name: String, size: Vector3, offset: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(node_name, mesh, offset, material)


func _mesh(node_name: String, mesh: Mesh, offset: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	add_child(instance)
	return instance
