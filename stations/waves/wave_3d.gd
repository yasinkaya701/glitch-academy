extends Node3D
## Live 3D water surface whose height is the superposition of the two point sources.

const Wave = preload("res://stations/waves/wave_sim.gd")
const FIELD_CM := Vector2(40.0, 28.0)
const FIELD_WORLD := Vector2(24.0, 16.0)

var frequency := 4.0
var two_sources := true
var clock := 0.0
var _surface: MeshInstance3D
var _second_source: MeshInstance3D
var _source_nodes: Array[MeshInstance3D] = []
var _sensors: Array[MeshInstance3D] = []
const NX := 57
const NZ := 39


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	clock += delta
	_second_source.visible = two_sources
	_update_surface()


func _build() -> void:
	var base := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(FIELD_WORLD.x, FIELD_WORLD.y)
	base.mesh = plane
	base.position = Vector3(0, -0.62, 0)
	base.material_override = _mat(Color("#102c3a"), 0.22, 0.28)
	add_child(base)
	_surface = MeshInstance3D.new()
	_surface.name = "InterferenceSurface"
	_surface.mesh = ArrayMesh.new()
	var surface_mat := _mat(Color.WHITE, 0.08, 0.38)
	surface_mat.vertex_color_use_as_albedo = true
	surface_mat.emission_enabled = true
	surface_mat.emission = Color("#36b6df")
	surface_mat.emission_energy_multiplier = 0.38
	_surface.material_override = surface_mat
	add_child(_surface)
	var source_positions := [_to_world(Wave.S1), _to_world(Wave.S2)]
	for i in 2:
		var source := _sphere(source_positions[i] + Vector3(0, 0.12, 0), 0.3, Color("#f2a65a"))
		source.name = "WaveSource_%d" % (i + 1)
		_source_nodes.append(source)
	_second_source = _source_nodes[1]
	for point in [Wave.SENSOR_A, Wave.SENSOR_B]:
		var sensor := _cylinder(_to_world(point) + Vector3(0, 0.05, 0), 0.48, 0.08, Color("#6fe3c1"))
		sensor.name = "Sensor_A" if point == Wave.SENSOR_A else "Sensor_B"
		_sensors.append(sensor)
	_update_surface()


func _to_world(point: Vector2) -> Vector3:
	return Vector3(point.x / FIELD_CM.x * FIELD_WORLD.x - FIELD_WORLD.x * 0.5, 0, point.y / FIELD_CM.y * FIELD_WORLD.y - FIELD_WORLD.y * 0.5)


func _update_surface() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var wavelength := Wave.wavelength(frequency)
	var k := TAU / wavelength
	var omega := TAU * frequency
	for iz in NZ:
		for ix in NX:
			var u := float(ix) / float(NX - 1)
			var v := float(iz) / float(NZ - 1)
			var x := (u - 0.5) * FIELD_WORLD.x
			var z := (v - 0.5) * FIELD_WORLD.y
			var world := Vector3(x, 0, z)
			var cm := Vector2(u * FIELD_CM.x, v * FIELD_CM.y)
			var d1 := cm.distance_to(Wave.S1)
			var d2 := cm.distance_to(Wave.S2)
			var value := sin(k * d1 - omega * clock)
			if two_sources:
				value += sin(k * d2 - omega * clock)
			vertices.append(Vector3(x, value * 0.55, z))
			normals.append(Vector3.UP)
			var crest := clampf(absf(value) * 0.55, 0.0, 1.0)
			colors.append(Color(0.08 + 0.14 * crest, 0.28 + 0.52 * crest, 0.42 + 0.5 * crest, 0.96))
	for iz in NZ - 1:
		for ix in NX - 1:
			var a := iz * NX + ix
			var b := a + 1
			var c := a + NX
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := _surface.mesh as ArrayMesh
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _sphere(pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = _mat(color, 0.22, 0.25)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node


func _cylinder(pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _mat(color, 0.4, 0.25)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node


func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material
