@tool
extends Node3D

@export var structure: Material
@export var deck: Material
@export var ivory: Material
@export var navigation: StandardMaterial3D
@export var rubber: Material


func _ready() -> void:
	if structure == null or deck == null or ivory == null or navigation == null or rubber == null:
		return
	_cylinder("Footing", 1.17, 1.25, 0.10, 0.05, 8, rubber)
	_cylinder("Hull", 1.27, 1.17, 0.145, 0.166, 8, structure)
	_cylinder("TopDeck", 1.27, 1.26, 0.054, 0.269, 8, deck)
	_cylinder("Berth", 0.86, 0.86, 0.014, 0.30, 48, rubber)
	for index in 8:
		var yaw := (float(index) + 0.5) * TAU / 8.0
		var fixture := Node3D.new()
		fixture.name = "EdgeBay%02d" % index
		fixture.rotation.y = yaw
		add_child(fixture)
		_box(fixture, "RimPlate", Vector3(0.44, 0.043, 0.115), Vector3(0, 0.284, -1.112), ivory)
		_box(fixture, "LightRecess", Vector3(0.247, 0.039, 0.062), Vector3(0, 0.317, -1.106), structure)
		_box(fixture, "Navigation", Vector3(0.169, 0.025, 0.034), Vector3(0, 0.336, -1.106), navigation)
		for x in [-0.15, 0.15]:
			_box(fixture, "Rivet", Vector3(0.044, 0.027, 0.045), Vector3(x, 0.314, -0.978), structure)
	for index in 4:
		_arc("BerthMark%02d" % index, float(index) * PI * 0.5 + 0.09, PI * 0.5 - 0.18)
	for side in [-1.0, 1.0]:
		var x := float(side) * 0.425
		_box(self, "CaptureRail", Vector3(0.098, 0.035, 0.94), Vector3(x, 0.323, 0.07), structure)
		for depth in [-0.33, 0.46]:
			_box(self, "Guide", Vector3(0.16, 0.056, 0.15), Vector3(x, 0.334, depth), ivory)
	for index in 3:
		var depth := -0.57 - float(index) * 0.084
		_box(self, "ApproachMark", Vector3(0.071 + float(index) * 0.057, 0.009, 0.035), Vector3(0, 0.311, depth), ivory)


func set_docked(docked: bool) -> void:
	navigation.emission_energy_multiplier = 1.35 if docked else 0.8


func _arc(node_name: String, start: float, extent: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 16:
		var a := start + float(segment) * extent / 16.0
		var b := start + float(segment + 1) * extent / 16.0
		var p := Vector3(sin(a) * 0.846, 0.317, cos(a) * 0.846)
		var q := Vector3(sin(a) * 0.925, 0.317, cos(a) * 0.925)
		var r := Vector3(sin(b) * 0.925, 0.317, cos(b) * 0.925)
		var s := Vector3(sin(b) * 0.846, 0.317, cos(b) * 0.846)
		for point in [p, r, q, p, s, r]:
			surface.add_vertex(point)
	surface.generate_normals()
	_mesh(self, node_name, surface.commit(), Vector3.ZERO, ivory)


func _cylinder(node_name: String, top: float, bottom: float, height: float, y: float, sides: int, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	_mesh(self, node_name, mesh, Vector3(0, y, 0), material)


func _box(parent: Node3D, node_name: String, size: Vector3, offset: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(parent, node_name, mesh, offset, material)


func _mesh(parent: Node3D, node_name: String, mesh: Mesh, offset: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	parent.add_child(instance)
