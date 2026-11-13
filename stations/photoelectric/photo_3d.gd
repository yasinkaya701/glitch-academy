extends Node3D
## Procedural vacuum phototube. The photon stream and electron emission follow the live lamp settings.

const Photo = preload("res://stations/photoelectric/photo_sim.gd")

var frequency := 4.3e14
var intensity := 1.0
var electric_field := 0.0
var metal: StringName = &"cesium"

var _cathode: MeshInstance3D
var _beam: MeshInstance3D
var _field_material: StandardMaterial3D
var _photons: Array[MeshInstance3D] = []
var _electrons: Array[MeshInstance3D] = []
var _clock := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build()


func _process(delta: float) -> void:
	_clock += delta
	var phi: float = float(Photo.METALS[metal]["phi"])
	var active := frequency * 4.14e-15 > phi
	var tint: Color = Photo.light_color(frequency)
	(_beam.mesh as CylinderMesh).material.albedo_color = Color(tint, 0.22 + intensity * 0.2)
	var metal_colors := {&"cesium": Color("#c5a16d"), &"sodium": Color("#cfb56d"), &"zinc": Color("#9aa7b3"), &"copper": Color("#bd795b")}
	(_cathode.mesh as BoxMesh).material.albedo_color = metal_colors.get(metal, Color("#c5a16d"))
	_field_material.albedo_color = Color(0.32, 0.78, 0.72, 0.16 + clampf(electric_field / 4.0, 0.0, 0.6))
	_field_material.emission_energy_multiplier = 0.15 + clampf(electric_field / 4.0, 0.0, 1.0) * 0.8
	for i in _photons.size():
		var photon := _photons[i]
		photon.visible = float(i) < 4.0 + 16.0 * intensity
		photon.position.x = -2.45 + fposmod(_clock * (1.4 + intensity) + float(i) * 0.24, 2.25)
		photon.position.y = sin(_clock * 5.0 + i) * 0.045
		(photon.mesh as SphereMesh).material.albedo_color = tint
	var rate := 12.0 * intensity if active else 0.0
	if rate > 0.0 and _rng.randf() < rate * delta:
		for electron in _electrons:
			if not electron.visible:
				electron.visible = true
			electron.position = Vector3(-0.15, _rng.randf_range(-0.35, 0.35), _rng.randf_range(-0.28, 0.28))
			electron.set_meta("age", 0.0)
			break
	for electron in _electrons:
		if electron.visible:
			var age := float(electron.get_meta("age", 0.0)) + delta
			electron.set_meta("age", age)
			electron.position.x += delta * (0.75 + minf(1.5, maxf(0.0, frequency * 4.14e-15 - phi)))
			if age > 1.45 or electron.position.x > 1.65:
				electron.visible = false


func _build() -> void:
	var lamp := _mat(Color("#253342"), 0.15, 0.5)
	var glass := _mat(Color(0.32, 0.68, 0.83, 0.14), 0.05, 0.08, true)
	var metal_mat := _mat(Color("#c5a16d"), 0.7, 0.25)
	var dark_mat := _mat(Color("#8595a1"), 0.6, 0.3)
	var bulb := _sphere(Vector3(-3.05, 0, 0), Vector3(0.78, 0.78, 0.78), Color("#f2a65a"), 0.05, 0.45)
	bulb.name = "FrequencyLamp"
	var lamp_stem := _box(Vector3(-2.98, -0.75, 0), Vector3(0.5, 0.24, 0.6), lamp)
	lamp_stem.name = "LampBase"
	var tube := _cylinder(Vector3(0.55, 0, 0), Vector3(1.12, 2.5, 1.12), glass, 48, 0.56)
	tube.name = "VacuumGlass"
	tube.rotation.z = PI * 0.5
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.32
	beam_mesh.bottom_radius = 0.10
	beam_mesh.height = 2.85
	beam_mesh.material = _mat(Color(0.5, 0.8, 1, 0.25), 0.0, 0.0, true)
	_beam = MeshInstance3D.new()
	_beam.mesh = beam_mesh
	_beam.position = Vector3(-1.15, 0, 0)
	_beam.rotation.z = PI * 0.5
	add_child(_beam)
	_cathode = _box(Vector3(-0.12, 0, 0), Vector3(0.12, 0.84, 0.52), metal_mat)
	_cathode.name = "Photocathode"
	var anode := _box(Vector3(1.55, 0, 0), Vector3(0.1, 0.84, 0.52), dark_mat)
	anode.name = "CollectorAnode"
	_field_material = _mat(Color(0.32, 0.78, 0.72, 0.24), 0.0, 0.2, true)
	_field_material.emission_enabled = true
	_field_material.emission = Color("#6fe3c1")
	for i in 5:
		var z := -0.32 + float(i) * 0.16
		var line := _cylinder(Vector3(0.68, 0, z), Vector3(0.018, 1.25, 0.018), _field_material, 10, 0.0)
		line.rotation.z = PI * 0.5
		line.name = "StoppingFieldLine"
		var tip_mesh := CylinderMesh.new()
		tip_mesh.top_radius = 0.0
		tip_mesh.bottom_radius = 0.055
		tip_mesh.height = 0.15
		tip_mesh.material = _field_material
		var tip := MeshInstance3D.new()
		tip.mesh = tip_mesh
		tip.position = Vector3(0.08, 0, z)
		tip.rotation.z = PI * 0.5
		add_child(tip)
	for i in 20:
		var p := _sphere(Vector3.ZERO, Vector3.ONE * 0.09, Color.WHITE, 0.1, 0.25)
		p.visible = false
		_photons.append(p)
	for i in 26:
		var e := _sphere(Vector3.ZERO, Vector3.ONE * 0.075, Color("#6fe3c1"), 0.2, 0.2)
		e.visible = false
		_electrons.append(e)
	var floor := _box(Vector3(0, -1.02, 0), Vector3(6.8, 0.12, 2.0), _mat(Color("#12212b"), 0.15, 0.75))
	floor.name = "OpticalBench"
	for pos in [Vector3(-3.05, 0, 0), Vector3(-0.12, 0, 0), Vector3(1.55, 0, 0)]:
		var light := OmniLight3D.new()
		light.position = pos + Vector3(0, 1.5, 0)
		light.light_energy = 0.35
		light.omni_range = 3.0
		add_child(light)


func _sphere(pos: Vector3, scale3: Vector3, color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.material = _mat(color, metallic, roughness)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale3
	add_child(node)
	return node


func _box(pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node


func _cylinder(pos: Vector3, dimensions: Vector3, material: Material, sides: int, alpha: float) -> MeshInstance3D:
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


func _mat(color: Color, metallic: float, roughness: float, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return material
