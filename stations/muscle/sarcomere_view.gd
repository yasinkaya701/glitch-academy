extends Node3D
## Sarkomerin 3B modeli: Z çizgileri, kalın (miyozin) ve ince (aktin) iplikler, çapraz köprü başları.
## 1 µm = UNIT dünya birimi. İplik konumları sarkomer uzunluğundan hesaplanır, A bandı sabit kalır.

const Sim = preload("res://stations/muscle/muscle_sim.gd")
const Util = preload("res://scripts/anatomy/anatomy_util.gd")

const UNIT := 0.55
const SARCOMERES := 2
const SPACING := 0.23

var length_um := 2.2
var activation := 0.0
var rigor := false
var show_bands := false

var _thick_positions: Array[Vector2] = []
var _thin_positions: Array[Vector2] = []
var _thick: MultiMeshInstance3D
var _thin: MultiMeshInstance3D
var _heads: MultiMeshInstance3D
var _zdiscs: Array[MeshInstance3D] = []
var _mline: Array[MeshInstance3D] = []
var _time := 0.0
var _head_seed: Array[float] = []
var _head_dir: Array[Vector2] = []
var _head_rest: Array[float] = []
var _band_lines: Node3D
var _band_labels: Dictionary = {}


func _ready() -> void:
	_layout_lattice()
	_build_meshes()


func _layout_lattice() -> void:
	## Üçgen kafes: 7 kalın iplik (merkez + 6). İnce iplikler komşu kalın iplik üçlülerinin merkezlerinde.
	_thick_positions.append(Vector2.ZERO)
	for k in 6:
		_thick_positions.append(Vector2.from_angle(TAU * float(k) / 6.0) * SPACING)
	for k in 6:
		var a := Vector2.from_angle(TAU * float(k) / 6.0) * SPACING
		var b := Vector2.from_angle(TAU * float(k + 1) / 6.0) * SPACING
		_thin_positions.append((a + b) / 3.0)
		_thin_positions.append((a + b) * 0.5 + (a + b).normalized() * SPACING * 0.5)


func _build_meshes() -> void:
	var thick_material := StandardMaterial3D.new()
	thick_material.albedo_color = Color("#ff8a5c")
	thick_material.roughness = 0.35
	thick_material.metallic = 0.0
	thick_material.emission_enabled = true
	thick_material.emission = Color("#8a2f12")
	thick_material.emission_energy_multiplier = 0.5
	var thin_material := StandardMaterial3D.new()
	thin_material.albedo_color = Color("#6fb3ff")
	thin_material.roughness = 0.3
	thin_material.emission_enabled = true
	thin_material.emission = Color("#173a6b")
	thin_material.emission_energy_multiplier = 0.6
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color("#ffd27a")
	head_material.roughness = 0.25
	head_material.emission_enabled = true
	head_material.emission = Color("#ffb84a")
	head_material.emission_energy_multiplier = 0.8
	head_material.vertex_color_use_as_albedo = true

	var thick_count := _thick_positions.size() * SARCOMERES
	_thick = _multi(CapsuleMesh.new(), thick_material, thick_count)
	var thick_mesh := _thick.multimesh.mesh as CapsuleMesh
	thick_mesh.radius = 0.034
	thick_mesh.height = Sim.THICK_LENGTH * UNIT
	thick_mesh.radial_segments = 12
	thick_mesh.rings = 4
	var thin_count := _thin_positions.size() * 2 * SARCOMERES
	_thin = _multi(CapsuleMesh.new(), thin_material, thin_count)
	var thin_mesh := _thin.multimesh.mesh as CapsuleMesh
	thin_mesh.radius = 0.011
	thin_mesh.height = Sim.THIN_LENGTH * UNIT
	thin_mesh.radial_segments = 8
	thin_mesh.rings = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var head_count := 0
	for thick_i in _thick_positions.size():
		for half in 2:
			for index in 6:
				for dir_i in 2:
					head_count += 1
	head_count *= SARCOMERES
	_heads = _multi(CapsuleMesh.new(), head_material, head_count)
	var head_mesh := _heads.multimesh.mesh as CapsuleMesh
	head_mesh.radius = 0.011
	head_mesh.height = 0.075
	head_mesh.radial_segments = 6
	head_mesh.rings = 2
	for i in head_count:
		_head_seed.append(rng.randf() * TAU)
		_head_dir.append(Vector2.from_angle(rng.randf() * TAU))
		_head_rest.append(rng.randf())

	var z_material := StandardMaterial3D.new()
	z_material.albedo_color = Color("#2b3340")
	z_material.metallic = 0.6
	z_material.roughness = 0.35
	for i in SARCOMERES + 1:
		var plate := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.035, 0.82, 0.82)
		plate.mesh = box
		plate.material_override = z_material
		add_child(plate)
		_zdiscs.append(plate)
	var m_material := StandardMaterial3D.new()
	m_material.albedo_color = Color(1.0, 0.8, 0.6, 0.25)
	m_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in SARCOMERES:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.006, 0.5, 0.5)
		m.mesh = box
		m.material_override = m_material
		add_child(m)
		_mline.append(m)
	_band_lines = Node3D.new()
	add_child(_band_lines)
	_apply()


func _multi(mesh: Mesh, material: Material, count: int) -> MultiMeshInstance3D:
	var holder := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = count
	holder.multimesh = multi
	holder.material_override = material
	add_child(holder)
	return holder


func set_state(new_length: float, new_activation: float, new_rigor: bool) -> void:
	length_um = new_length
	activation = new_activation
	rigor = new_rigor


func _process(delta: float) -> void:
	_time += delta
	_apply()


func _apply() -> void:
	if _thick == null:
		return
	var total := length_um * SARCOMERES * UNIT
	var x0 := -total * 0.5
	var l := length_um * UNIT
	var thick_len := Sim.THICK_LENGTH * UNIT
	var thin_len := Sim.THIN_LENGTH * UNIT
	var overlap_active := clampf((activation - 0.12) / 0.5, 0.0, 1.0) if not rigor else 1.0
	for i in _zdiscs.size():
		_zdiscs[i].position = Vector3(x0 + l * i, 0, 0)
	var thick_index := 0
	var thin_index := 0
	var head_index := 0
	for s in SARCOMERES:
		var z_left := x0 + l * s
		var z_right := z_left + l
		var center := z_left + l * 0.5
		_mline[s].position = Vector3(center, 0, 0)
		for p in _thick_positions:
			_thick.multimesh.set_instance_transform(thick_index, Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(center, p.x, p.y)))
			_thick.multimesh.set_instance_color(thick_index, Color.WHITE)
			thick_index += 1
		for p in _thin_positions:
			# Sol Z'den sağa, sağ Z'den sola
			var left_center := Vector3(z_left + thin_len * 0.5, p.x, p.y)
			var right_center := Vector3(z_right - thin_len * 0.5, p.x, p.y)
			_thin.multimesh.set_instance_transform(thin_index, Transform3D(Basis(Vector3.BACK, PI / 2.0), left_center))
			thin_index += 1
			_thin.multimesh.set_instance_transform(thin_index, Transform3D(Basis(Vector3.BACK, PI / 2.0), right_center + Vector3(0, 0.0, 0.0)))
			thin_index += 1
		# Çapraz köprü başları: kalın ipliğin iki yarısında, çıplak bölge dışında
		for thick_p in _thick_positions:
			for half in 2:
				var sign_h := -1.0 if half == 0 else 1.0
				for index in 6:
					var x := center + sign_h * (0.08 + 0.066 * float(index))  # çıplak bölge dışında
					# Bu x, ince iplikle örtüşüyor mu?
					var in_left_overlap := x <= z_left + thin_len
					var in_right_overlap := x >= z_right - thin_len
					var overlapping := in_left_overlap or in_right_overlap
					for dir_i in 2:
						if head_index >= _heads.multimesh.instance_count:
							break
						var angle_base := float(index) * 2.09 + float(dir_i) * PI + (0.0 if half == 0 else 1.05)
						var radial := Vector3(0.0, cos(angle_base), sin(angle_base))
						var attached := overlapping and overlap_active > 0.2
						var phase := 0.5 + 0.5 * sin(_time * 7.0 + _head_seed[head_index] * 3.0)
						var tilt: float
						var color := Color("#ffd27a")
						if rigor and overlapping:
							tilt = 0.5
							color = Color("#ff6b5e")
						elif attached:
							tilt = lerpf(0.75, 0.35, phase * overlap_active)
							color = Color("#9affc9")
						else:
							tilt = 0.28
						var surface := Vector3(x, thick_p.x, thick_p.y) + radial * 0.034
						var head_dir := (radial * cos(tilt) + Vector3(-sign_h, 0, 0) * sin(tilt)).normalized()
						var basis := Basis(Quaternion(Vector3.UP, head_dir))
						_heads.multimesh.set_instance_transform(head_index, Transform3D(basis, surface + head_dir * 0.035))
						_heads.multimesh.set_instance_color(head_index, color)
						head_index += 1
	_update_bands(x0, l)


func _update_bands(x0: float, l: float) -> void:
	for child in _band_lines.get_children():
		child.queue_free()
	_band_lines.visible = show_bands
	if not show_bands:
		return
	var bands := Sim.bands(length_um)
	var y := -0.62
	_band_line(Vector3(x0, y, 0), Vector3(x0 + l, y, 0), Color("#8ff0d4"))
	var center := x0 + l * 0.5
	var a_half := Sim.THICK_LENGTH * UNIT * 0.5
	_band_line(Vector3(center - a_half, y - 0.08, 0), Vector3(center + a_half, y - 0.08, 0), Color("#ff8a5c"))
	var h_half := float(bands["H"]) * UNIT * 0.5
	if h_half > 0.01:
		_band_line(Vector3(center - h_half, y - 0.16, 0), Vector3(center + h_half, y - 0.16, 0), Color("#ffcf9e"))


func _band_line(from: Vector3, to: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(from.distance_to(to), 0.012, 0.012)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = (from + to) * 0.5
	_band_lines.add_child(mesh)
