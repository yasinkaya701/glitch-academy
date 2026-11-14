extends Node3D
## Anatomik kapak modeli (3B). GLB parçalardaki yaprakçıklar açılma animasyonunu alır.
## Yön oku (+Y), kapağın izin verdiği akış yönünü gösterir. Ters takılırsa kan geri akar.

const Model = preload("res://stations/heart/heart_model.gd")
const VALVE_SCENES := {
	Model.Valve.TRICUSPID: preload("res://stations/heart/assets/segmented/valves/tricuspid.glb"),
	Model.Valve.MITRAL: preload("res://stations/heart/assets/segmented/valves/mitral.glb"),
	Model.Valve.AORTIC: preload("res://stations/heart/assets/segmented/valves/aortic.glb"),
	Model.Valve.PULMONARY: preload("res://stations/heart/assets/segmented/valves/pulmonary.glb"),
}

var open_amount := 0.0:
	set(value):
		open_amount = value
		_apply_open()
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
var _leaflets: Array[Node3D] = []
var _annuli: Array[MeshInstance3D] = []
var _leaflet_rest: Array[Basis] = []
var _leaflet_axes: Array[Vector3] = []
var _arrow_material: StandardMaterial3D

func setup(for_valve: int, ring_radius: float) -> void:
	valve = for_valve
	radius = ring_radius
	_body = Node3D.new()
	_body.scale = Vector3.ONE * (radius / 0.88)
	add_child(_body)
	_body.add_child(VALVE_SCENES[valve].instantiate())
	_collect_parts(_body)
	_arrow_material = StandardMaterial3D.new()
	_arrow_material.albedo_color = Color("#a5ad84")
	_arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arrow_material.emission_enabled = true
	_arrow_material.emission = Color("#a5ad84")
	_arrow_material.emission_energy_multiplier = 2.0
	var arrow := Node3D.new()
	arrow.position = Vector3(radius * 1.45, 0.0, 0.0)
	_body.add_child(arrow)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = radius * 0.06
	shaft_mesh.bottom_radius = radius * 0.06
	shaft_mesh.height = radius * 0.8
	shaft.mesh = shaft_mesh
	shaft.material_override = _arrow_material
	shaft.position.y = radius * 0.4
	arrow.add_child(shaft)
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = radius * 0.2
	head_mesh.height = radius * 0.36
	head.mesh = head_mesh
	head.material_override = _arrow_material
	head.position.y = radius * 0.98
	arrow.add_child(head)
	_apply_open()
	_update_glow()

func _collect_parts(node: Node) -> void:
	if node is Node3D and String(node.name).begins_with("PivotLeaflet"):
		var pivot := node as Node3D
		_leaflets.append(pivot)
		_leaflet_rest.append(pivot.basis)
		_leaflet_axes.append(Vector3(-pivot.position.z, 0.0, pivot.position.x).normalized())
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var part_name := String(node.name)
		if part_name.begins_with("Annulus"):
			var source := mesh_instance.get_active_material(0)
			if source is StandardMaterial3D:
				mesh_instance.material_override = (source as StandardMaterial3D).duplicate()
			_annuli.append(mesh_instance)
	for child in node.get_children():
		_collect_parts(child)

func _apply_open() -> void:
	var semilunar := valve == Model.Valve.AORTIC or valve == Model.Valve.PULMONARY
	var direction := -1.0 if semilunar else 1.0
	for index in _leaflets.size():
		var angle := direction * deg_to_rad(58.0) * open_amount
		_leaflets[index].basis = Basis(_leaflet_axes[index], angle) * _leaflet_rest[index]

func _update_glow() -> void:
	for annulus in _annuli:
		var material := annulus.material_override as StandardMaterial3D
		if material != null:
			material.emission_enabled = marked
			material.emission = Color("#e5645a")
			material.emission_energy_multiplier = 1.2
