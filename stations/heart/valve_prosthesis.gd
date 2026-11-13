extends Node3D
## Oyuncunun yuvaya taktığı kapak protezi (3B). Metal halka, dikiş manşeti ve menteşeli yaprakçıklar.
## Yön oku, kapağın izin verdiği akış yönünü gösterir (+Y). Ters takılırsa kan geri akar.

const Model = preload("res://stations/heart/heart_model.gd")

## 0 = yaprakçıklar kapalı, 1 = tam açık.
var open_amount := 0.0:
	set(value):
		open_amount = value
		_apply_open()
## Kapak ters takıldı mı (akış oku akışın tersine bakıyor)?
var flipped := false:
	set(value):
		flipped = value
		if _body != null:
			_body.rotation = Vector3(PI if flipped else 0.0, 0.0, 0.0)
var valve: int = Model.Valve.TRICUSPID
var radius := 0.05
var marked := false:
	set(value):
		marked = value
		_update_glow()

var _body: Node3D
var _hinges: Array[Node3D] = []
var _ring_material: StandardMaterial3D
var _arrow_material: StandardMaterial3D


func setup(for_valve: int, ring_radius: float) -> void:
	valve = for_valve
	radius = ring_radius
	_body = Node3D.new()
	add_child(_body)

	_ring_material = StandardMaterial3D.new()
	_ring_material.albedo_color = Color("#c9d3da")
	_ring_material.metallic = 1.0
	_ring_material.roughness = 0.22
	var cuff_material := StandardMaterial3D.new()
	cuff_material.albedo_color = Color("#e9dfc9")
	cuff_material.roughness = 0.85
	var leaflet_material := StandardMaterial3D.new()
	leaflet_material.albedo_color = Color("#f1e7d3")
	leaflet_material.roughness = 0.55
	leaflet_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaflet_material.emission_enabled = true
	leaflet_material.emission = Color("#6a5a3f")
	leaflet_material.emission_energy_multiplier = 0.25
	_arrow_material = StandardMaterial3D.new()
	_arrow_material.albedo_color = Color("#6fe3c1")
	_arrow_material.emission_enabled = true
	_arrow_material.emission = Color("#6fe3c1")
	_arrow_material.emission_energy_multiplier = 1.6

	# Metal halka ve manşet
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.outer_radius = radius * 1.0
	ring_mesh.inner_radius = radius * 0.86
	ring_mesh.rings = 48
	ring_mesh.ring_segments = 16
	ring.mesh = ring_mesh
	ring.material_override = _ring_material
	_body.add_child(ring)
	var cuff := MeshInstance3D.new()
	var cuff_mesh := TorusMesh.new()
	cuff_mesh.outer_radius = radius * 1.18
	cuff_mesh.inner_radius = radius * 1.02
	cuff_mesh.rings = 40
	cuff_mesh.ring_segments = 12
	cuff.mesh = cuff_mesh
	cuff.material_override = cuff_material
	cuff.position.y = -radius * 0.06
	_body.add_child(cuff)

	# Yaprakçıklar
	var count := 2 if valve == Model.Valve.MITRAL else 3
	for i in count:
		var angle := TAU * float(i) / float(count) + 0.4
		var hinge := Node3D.new()
		hinge.position = Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.88
		# Taban: X içeri, Y yukarı (akış), Z teğet.
		var inward := -Vector3(cos(angle), 0.0, sin(angle))
		var tangent := Vector3(-sin(angle), 0.0, cos(angle))
		hinge.basis = Basis(inward, Vector3.UP, tangent)
		_body.add_child(hinge)
		var leaflet := MeshInstance3D.new()
		leaflet.mesh = _leaflet_mesh(radius * 0.84, radius * (1.15 if count == 3 else 1.5) * 0.9)
		leaflet.material_override = leaflet_material
		hinge.add_child(leaflet)
		_hinges.append(hinge)

	# Yön oku (halkanın dışında küçük işaret)
	var arrow := Node3D.new()
	arrow.position = Vector3(radius * 1.35, 0.0, 0.0)
	_body.add_child(arrow)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = radius * 0.05
	shaft_mesh.bottom_radius = radius * 0.05
	shaft_mesh.height = radius * 0.7
	shaft.mesh = shaft_mesh
	shaft.material_override = _arrow_material
	shaft.position.y = radius * 0.35
	arrow.add_child(shaft)
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = radius * 0.16
	head_mesh.height = radius * 0.32
	head.mesh = head_mesh
	head.material_override = _arrow_material
	head.position.y = radius * 0.86
	arrow.add_child(head)
	_apply_open()


func _leaflet_mesh(length: float, half_width: float) -> ArrayMesh:
	var points := [
		Vector2(0.0, -half_width), Vector2(length * 0.55, -half_width * 0.82), Vector2(length * 0.95, -half_width * 0.35),
		Vector2(length, 0.0), Vector2(length * 0.95, half_width * 0.35), Vector2(length * 0.55, half_width * 0.82),
		Vector2(0.0, half_width),
	]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3(length * 0.45, 0.0, 0.0))
	normals.append(Vector3.UP)
	for point in points:
		vertices.append(Vector3(point.x, 0.0, point.y))
		normals.append(Vector3.UP)
	for i in points.size() - 1:
		indices.append_array([0, i + 1, i + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_open() -> void:
	for hinge in _hinges:
		var rest: Basis = _hinge_rest(hinge)
		var angle := deg_to_rad(72.0) * open_amount
		hinge.basis = Basis(rest.z.normalized(), angle) * rest


func _hinge_rest(hinge: Node3D) -> Basis:
	if not hinge.has_meta("rest"):
		hinge.set_meta("rest", hinge.basis)
	return hinge.get_meta("rest")


func _update_glow() -> void:
	if _ring_material == null:
		return
	_ring_material.emission_enabled = marked
	_ring_material.emission = Color("#e5645a")
	_ring_material.emission_energy_multiplier = 2.0
