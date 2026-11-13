extends Node3D
## Oyuncunun yuvaya taktığı kapak protezi (3B).
## Kulakçık–karıncık kapakları (triküspit, mitral): mekanik çift yaprakçıklı kapak (metal halka, karbon yaprakçıklar).
## Yarım ay kapakları (pulmoner, aort): biyoprotez üç yaprakçıklı kapak (destek direkleri, doku yaprakçıkları).
## Yön oku (+Y), kapağın izin verdiği akış yönünü gösterir. Ters takılırsa kan geri akar.

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
var _mechanical := true
var _leaflets: Array[Node3D] = []
var _ring_material: StandardMaterial3D
var _arrow_material: StandardMaterial3D


func setup(for_valve: int, ring_radius: float) -> void:
	valve = for_valve
	radius = ring_radius
	_mechanical = valve == Model.Valve.TRICUSPID or valve == Model.Valve.MITRAL
	_body = Node3D.new()
	add_child(_body)

	_ring_material = StandardMaterial3D.new()
	_ring_material.albedo_color = Color("#d4dbe0")
	_ring_material.metallic = 1.0
	_ring_material.roughness = 0.16
	_ring_material.emission = Color("#e5645a")
	var cuff_material := StandardMaterial3D.new()
	cuff_material.albedo_color = Color("#efe7d6")
	cuff_material.roughness = 0.95
	var carbon := StandardMaterial3D.new()
	carbon.albedo_color = Color("#15171c")
	carbon.metallic = 0.25
	carbon.roughness = 0.14
	carbon.clearcoat_enabled = true
	carbon.clearcoat = 1.0
	carbon.clearcoat_roughness = 0.08
	carbon.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tissue := StandardMaterial3D.new()
	tissue.albedo_color = Color("#d9c3a4")
	tissue.roughness = 0.5
	tissue.cull_mode = BaseMaterial3D.CULL_DISABLED
	tissue.subsurf_scatter_enabled = true
	tissue.subsurf_scatter_strength = 0.5
	_arrow_material = StandardMaterial3D.new()
	_arrow_material.albedo_color = Color("#6fe3c1")
	_arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arrow_material.emission_enabled = true
	_arrow_material.emission = Color("#6fe3c1")
	_arrow_material.emission_energy_multiplier = 2.0

	# Metal halka ve dikiş manşeti
	_add_torus(radius * 1.0, radius * 0.86, _ring_material, Vector3.ZERO)
	_add_torus(radius * 1.22, radius * 1.0, cuff_material, Vector3(0, -radius * 0.08, 0))
	# Manşet üzerinde dikiş izleri
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var stitch := MeshInstance3D.new()
		var stitch_mesh := BoxMesh.new()
		stitch_mesh.size = Vector3(radius * 0.012, radius * 0.012, radius * 0.07)
		stitch.mesh = stitch_mesh
		stitch.material_override = _ring_material
		stitch.position = Vector3(cos(angle), 0.0, sin(angle)) * radius * 1.11 + Vector3(0, radius * 0.07, 0)
		stitch.rotation = Vector3(0, -angle, 0)
		_body.add_child(stitch)

	if _mechanical:
		_build_mechanical(carbon)
	else:
		_build_bioprosthesis(tissue, cuff_material)

	# Yön oku: manşetin dışında, akışa bakan
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


func _add_torus(outer: float, inner: float, material: Material, position: Vector3) -> void:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.outer_radius = outer
	mesh.inner_radius = inner
	mesh.rings = 56
	mesh.ring_segments = 16
	node.mesh = mesh
	node.material_override = material
	node.position = position
	_body.add_child(node)


func _build_mechanical(carbon: Material) -> void:
	# İki yarım disk; menteşe ekseni X'e paralel, merkez çizgisinden ±0.32R ötede.
	for side in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(0, 0, side * radius * 0.32)
		hinge.set_meta("side", side)
		_body.add_child(hinge)
		var leaflet := MeshInstance3D.new()
		leaflet.mesh = _half_disc(radius * 0.86, side)
		leaflet.material_override = carbon
		# Mesh merkez çizgisinden başlar, menteşeye göre ofsetle
		leaflet.position = Vector3(0, 0, -side * radius * 0.32)
		hinge.add_child(leaflet)
		_leaflets.append(hinge)
		# Menteşe pimleri
		for end in [-1.0, 1.0]:
			var pin := MeshInstance3D.new()
			var pin_mesh := CylinderMesh.new()
			pin_mesh.top_radius = radius * 0.04
			pin_mesh.bottom_radius = radius * 0.04
			pin_mesh.height = radius * 0.16
			pin.mesh = pin_mesh
			pin.material_override = _ring_material
			pin.rotation = Vector3(0, 0, PI / 2.0)
			var x: float = float(end) * sqrt(maxf(pow(radius * 0.86, 2.0) - pow(radius * 0.32, 2.0), 0.0))
			pin.position = Vector3(x, 0, 0)
			hinge.add_child(pin)


func _half_disc(r: float, side: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var steps := 20
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	for i in steps + 1:
		var angle := PI * float(i) / float(steps) - PI / 2.0
		# Yarım disk: x ∈ [-r, r], z ≥ 0 (side yönünde)
		vertices.append(Vector3(sin(angle) * r, 0.0, cos(angle) * r * side * 0.0 + side * absf(cos(angle)) * r * 0.9))
		normals.append(Vector3.UP)
	for i in steps:
		indices.append_array([0, i + 1, i + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_bioprosthesis(tissue: Material, cloth: Material) -> void:
	# Üç destek direği ve üç yaprakçık
	for i in 3:
		var angle := TAU * float(i) / 3.0 + 0.5
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = radius * 0.07
		post_mesh.bottom_radius = radius * 0.09
		post_mesh.height = radius * 0.9
		post.mesh = post_mesh
		post.material_override = cloth
		post.position = Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.93 + Vector3(0, radius * 0.4, 0)
		_body.add_child(post)
	for i in 3:
		var angle := TAU * float(i) / 3.0 + 0.5 + TAU / 6.0
		var hinge := Node3D.new()
		hinge.position = Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.88
		var inward := -Vector3(cos(angle), 0.0, sin(angle))
		var tangent := Vector3(-sin(angle), 0.0, cos(angle))
		hinge.basis = Basis(inward, Vector3.UP, tangent)
		hinge.set_meta("rest", hinge.basis)
		_body.add_child(hinge)
		var leaflet := MeshInstance3D.new()
		leaflet.mesh = _tissue_leaflet(radius * 0.86, radius * 1.05)
		leaflet.material_override = tissue
		hinge.add_child(leaflet)
		_leaflets.append(hinge)


func _tissue_leaflet(length: float, half_width: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var rows := 8
	var cols := 9
	for r in rows + 1:
		var u := float(r) / float(rows)
		for c in cols:
			var v := float(c) / float(cols - 1) * 2.0 - 1.0
			var width := half_width * (1.0 - 0.35 * u) * (1.0 - u * u * 0.4)
			var x := length * u
			var z := v * width * (1.0 - 0.15 * u)
			var y := -0.08 * length * (1.0 - v * v) * sin(u * PI)
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3.UP)
	for r in rows:
		for c in cols - 1:
			var a := r * cols + c
			var b := a + 1
			var d := a + cols
			var e := d + 1
			indices.append_array([a, d, b, b, d, e])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_open() -> void:
	for hinge in _leaflets:
		if _mechanical:
			var side: float = hinge.get_meta("side")
			hinge.rotation = Vector3(side * deg_to_rad(78.0) * open_amount * -1.0, 0.0, 0.0)
		else:
			var rest: Basis = hinge.get_meta("rest")
			var angle := deg_to_rad(70.0) * open_amount
			hinge.basis = Basis(rest.z.normalized(), angle) * rest


func _update_glow() -> void:
	if _ring_material == null:
		return
	_ring_material.emission_enabled = marked
	_ring_material.emission_energy_multiplier = 2.0
