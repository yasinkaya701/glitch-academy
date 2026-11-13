extends Node3D
## 3D pH bench: solution identity, indicator response and flow valves are visible on the apparatus.

var tyt := false
var tested_red := false
var tested_blue := false
var measured: Array[bool] = [false, false]
var open_valve := -1
var _liquids: Array[MeshInstance3D] = []
var _strips: Array[MeshInstance3D] = []
var _valve_handles: Array[Node3D] = []
var _clock := 0.0


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	_clock += delta
	for i in _liquids.size():
		_liquids[i].position.y = -0.12 + sin(_clock * 1.5 + i) * 0.018
	if _strips.size() >= 2:
		(_strips[0].mesh as BoxMesh).material.albedo_color = Color("#e5645a")
		(_strips[1].mesh as BoxMesh).material.albedo_color = Color("#e5645a") if tested_blue else Color("#4c8dff")
	for i in _valve_handles.size():
		_valve_handles[i].rotation.z = PI * 0.5 if open_valve == i else 0.0


func _build() -> void:
	_add_box(Vector3(0, -0.7, 0), Vector3(6.4, 0.18, 2.8), _mat(Color("#17313a"), 0.25, 0.58))
	for i in 2:
		var x := -1.15 + float(i) * 2.3
		var liquid_color := Color("#48c5d2", 0.8) if i == 0 else Color("#b98ce8", 0.82)
		if not tyt:
			liquid_color = Color("#cfb35e", 0.84)
		var beaker := _add_cylinder(Vector3(x, 0.0, 0), Vector3(0.95, 1.6, 0.95), _mat(Color(0.62, 0.83, 0.84, 0.25), 0.0, 0.08, true), 48)
		beaker.name = "SampleVessel_%s" % ("A" if i == 0 else "B")
		var liquid := _add_cylinder(Vector3(x, -0.12, 0), Vector3(0.78, 0.84, 0.78), _mat(liquid_color, 0.0, 0.14, true), 40)
		liquid.name = "SampleSolution_%s" % ("A" if i == 0 else "B")
		_liquids.append(liquid)
		_add_torus(Vector3(x, 0.79, 0), 0.49, 0.035, _mat(Color("#b9d7d4"), 0.25, 0.3))
		if tyt:
			var meter := _add_cylinder(Vector3(x, 1.2, 0.15), Vector3(0.78, 0.14, 0.78), _mat(Color("#18343b"), 0.5, 0.3), 40)
			meter.name = "pHMeter_%s" % ("A" if i == 0 else "B")
			_add_box(Vector3(x, 1.28, 0.15), Vector3(0.34, 0.025, 0.15), _mat(Color("#82e0c5"), 0.0, 0.2))
			var tube := _add_cylinder(Vector3(x, 0.88, 0), Vector3(0.05, 0.85, 0.05), _mat(Color("#e8f2ef"), 0.1, 0.22), 12)
			tube.name = "pHElectrode"
			var valve := Node3D.new()
			valve.position = Vector3(x, -0.55, 0.66)
			add_child(valve)
			_add_cylinder(Vector3(x, -0.55, 0.53), Vector3(0.12, 0.3, 0.12), _mat(Color("#82979a"), 0.7, 0.3), 20)
			var handle := _add_box(Vector3(x, -0.38, 0.53), Vector3(0.48, 0.07, 0.07), _mat(Color("#f0c77d"), 0.4, 0.27))
			_valve_handles.append(handle)
		else:
			for strip_index in 2:
				var sx := x + (-0.19 if strip_index == 0 else 0.19)
				var strip := _add_box(Vector3(sx, 1.0, 0.38), Vector3(0.13, 0.95, 0.055), _mat(Color("#e8f2ef"), 0.0, 0.35))
				strip.name = "LitmusStrip_Red" if strip_index == 0 else "LitmusStrip_Blue"
				var patch := _add_box(Vector3(sx, 0.72, 0.415), Vector3(0.11, 0.38, 0.018), _mat(Color("#e5645a") if strip_index == 0 else Color("#4c8dff"), 0.0, 0.3))
				patch.name = "IndicatorResult_Red" if strip_index == 0 else "IndicatorResult_Blue"
				_strips.append(patch)
	var source := _add_box(Vector3(0, -0.45, -1.0), Vector3(5.1, 0.15, 0.16), _mat(Color("#24434b"), 0.45, 0.32))
	source.name = "SampleDrainManifold"


func _add_box(pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node


func _add_cylinder(pos: Vector3, dimensions: Vector3, material: Material, sides: int) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = sides
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	add_child(node)
	return node


func _add_torus(pos: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node


func _mat(color: Color, metallic: float, roughness: float, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return material
