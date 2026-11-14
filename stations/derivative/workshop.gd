extends Node3D
## Depo Atölyesi 3B tezgâhı. 1 birim = 1 dm. Levha, kesilen köşe kareleri, katlanan kutu ve ölçü silindiri.
## Sayısal kurallar box_plot.gd içinde (volume), bu dosya yalnızca görüntü ve hareket.

const SHEET_THICKNESS := 0.12
const CYLINDER_X := 10.5
const CYLINDER_HEIGHT := 9.0
const CYLINDER_RADIUS := 2.2

var side := 12.0
var cut := 2.0
## 0 = levha düz ve köşeleri yerinde, 1 = köşeler ayrılmış.
var cut_amount := 1.0
## 0 = düz, 1 = kutu katlanmış.
var fold_amount := 1.0
## Ölçü silindirindeki seviye 0–1 (kapasiteye oranı).
var level := 0.0
var capacity := 140.0

var _camera: Camera3D
var _box_root: Node3D
var _cutoffs: Node3D
var _liquid: MeshInstance3D
var _metal: StandardMaterial3D
var _metal_dark: StandardMaterial3D
var _glass: StandardMaterial3D
var _water: StandardMaterial3D


func _ready() -> void:
	_build_environment()
	_build_bench()
	_build_cylinder()
	_box_root = Node3D.new()
	add_child(_box_root)
	_cutoffs = Node3D.new()
	add_child(_cutoffs)
	rebuild()


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#171815")
	sky_material.sky_horizon_color = Color("#34332e")
	sky_material.ground_horizon_color = Color("#292923")
	sky_material.ground_bottom_color = Color("#10110f")
	sky_material.sky_energy_multiplier = 0.8
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.08
	environment.ssao_enabled = true
	environment.ssao_radius = 1.2
	environment.ssao_intensity = 2.0
	environment.ssr_enabled = true
	environment.ssr_max_steps = 48
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	_camera = Camera3D.new()
	_camera.fov = 34.0
	add_child(_camera)
	frame()

	var key := SpotLight3D.new()
	key.position = Vector3(-6, 22, 12)
	key.light_color = Color(1.0, 0.86, 0.68)
	key.light_energy = 3.2
	key.spot_range = 60.0
	key.spot_angle = 42.0
	key.shadow_enabled = true
	add_child(key)
	key.look_at(Vector3(2, 0, 0), Vector3.UP)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-25, 160, 0)
	rim.light_color = Color(0.85, 0.9, 1.0)
	rim.light_energy = 0.35
	add_child(rim)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-14, 10, 10)
	fill.light_color = Color(1.0, 0.92, 0.82)
	fill.light_energy = 2.2
	fill.omni_range = 60.0
	add_child(fill)


func _pbr(folder: String, id: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var base := "res://assets/materials/%s/%s_2K-JPG_" % [folder, id]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(base + "Color.jpg")
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load(base + "NormalGL.jpg")
	material.roughness_texture = load(base + "Roughness.jpg")
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.roughness = 1.0
	material.metallic_texture = load(base + "Metalness.jpg")
	material.metallic = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * scale
	return material


func _build_bench() -> void:
	var top := _pbr("Metal009", "Metal009", 0.12, Color(0.24, 0.23, 0.20))
	top.normal_scale = 0.5
	top.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(220, 220)
	plane.mesh = mesh
	plane.material_override = top
	add_child(plane)

	_metal = _pbr("Metal009", "Metal009", 0.30, Color(0.96, 0.91, 0.80))
	_metal_dark = _pbr("Metal009", "Metal009", 0.30, Color(0.43, 0.41, 0.36))
	_glass = StandardMaterial3D.new()
	_glass.albedo_color = Color(0.90, 0.84, 0.72, 0.12)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.roughness = 0.03
	_glass.metallic = 0.0
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_water = StandardMaterial3D.new()
	_water.albedo_color = Color(0.49, 0.72, 0.59, 0.78)
	_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water.roughness = 0.08
	_water.emission_enabled = true
	_water.emission = Color(0.10, 0.22, 0.14)
	_water.emission_energy_multiplier = 0.25


func _grid_texture() -> ImageTexture:
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGB8)
	image.fill(Color("#211f1a"))
	for i in size:
		for k in 2:
			image.set_pixel(i, k, Color("#514737"))
			image.set_pixel(k, i, Color("#514737"))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _build_cylinder() -> void:
	var glass := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = CYLINDER_RADIUS
	mesh.bottom_radius = CYLINDER_RADIUS
	mesh.height = CYLINDER_HEIGHT
	glass.mesh = mesh
	glass.material_override = _glass
	glass.position = Vector3(CYLINDER_X, CYLINDER_HEIGHT * 0.5 + 0.1, 0)
	add_child(glass)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = CYLINDER_RADIUS + 0.8
	base_mesh.bottom_radius = CYLINDER_RADIUS + 1.0
	base_mesh.height = 0.3
	base.mesh = base_mesh
	base.material_override = _metal_dark
	base.position = Vector3(CYLINDER_X, 0.15, 0)
	add_child(base)
	for i in range(1, 6):
		var tick := MeshInstance3D.new()
		var tick_mesh := BoxMesh.new()
		tick_mesh.size = Vector3(0.7 if i % 2 == 0 else 0.4, 0.06, 0.06)
		tick.mesh = tick_mesh
		tick.material_override = _metal
		tick.position = Vector3(CYLINDER_X + CYLINDER_RADIUS + 0.05, 0.3 + float(i) * (CYLINDER_HEIGHT - 0.8) / 6.0, 0)
		add_child(tick)
	_liquid = MeshInstance3D.new()
	var liquid_mesh := CylinderMesh.new()
	liquid_mesh.top_radius = CYLINDER_RADIUS - 0.1
	liquid_mesh.bottom_radius = CYLINDER_RADIUS - 0.1
	liquid_mesh.height = 0.01
	_liquid.mesh = liquid_mesh
	_liquid.material_override = _water
	_liquid.position = Vector3(CYLINDER_X, 0.3, 0)
	add_child(_liquid)


func _process(_delta: float) -> void:
	var usable := CYLINDER_HEIGHT - 0.8
	var height := maxf(level * usable, 0.01)
	(_liquid.mesh as CylinderMesh).height = height
	_liquid.position.y = 0.3 + height * 0.5


func rebuild() -> void:
	for child in _box_root.get_children():
		child.queue_free()
	for child in _cutoffs.get_children():
		child.queue_free()
	var b := side - 2.0 * cut
	if b <= 0.0 or cut <= 0.0:
		_flat_sheet()
		return
	var half := b * 0.5
	# Taban
	_add_box(_box_root, Vector3(b, SHEET_THICKNESS, b), Vector3(0, SHEET_THICKNESS * 0.5, 0), _metal)
	# Dört kenar: menteşede döner.
	var walls := [
		{"pivot": Vector3(half, SHEET_THICKNESS, 0), "offset": Vector3(cut * 0.5, 0, 0), "size": Vector3(cut, SHEET_THICKNESS, b), "axis": Vector3(0, 0, 1), "sign": 1.0},
		{"pivot": Vector3(-half, SHEET_THICKNESS, 0), "offset": Vector3(-cut * 0.5, 0, 0), "size": Vector3(cut, SHEET_THICKNESS, b), "axis": Vector3(0, 0, 1), "sign": -1.0},
		{"pivot": Vector3(0, SHEET_THICKNESS, -half), "offset": Vector3(0, 0, -cut * 0.5), "size": Vector3(b, SHEET_THICKNESS, cut), "axis": Vector3(1, 0, 0), "sign": 1.0},
		{"pivot": Vector3(0, SHEET_THICKNESS, half), "offset": Vector3(0, 0, cut * 0.5), "size": Vector3(b, SHEET_THICKNESS, cut), "axis": Vector3(1, 0, 0), "sign": -1.0},
	]
	for wall in walls:
		var pivot := Node3D.new()
		pivot.position = wall["pivot"]
		_box_root.add_child(pivot)
		pivot.rotate(wall["axis"], deg_to_rad(90.0) * fold_amount * wall["sign"])
		_add_box(pivot, wall["size"], wall["offset"], _metal)
	# Kesilen köşe kareleri: yan yana dizilir (cut_amount 0 iken köşelerde durur).
	for i in 4:
		var corner_x := (half + cut * 0.5) * (1.0 if i % 2 == 0 else -1.0)
		var corner_z := (half + cut * 0.5) * (1.0 if i < 2 else -1.0)
		var home := Vector3(corner_x, SHEET_THICKNESS * 0.5, corner_z)
		var away := Vector3(-side * 0.5 - 3.5 - float(i) * (cut + 0.4), SHEET_THICKNESS * 0.5, 6.0)
		_add_box(_cutoffs, Vector3(cut, SHEET_THICKNESS, cut), home.lerp(away, cut_amount), _metal_dark)


func _flat_sheet() -> void:
	_add_box(_box_root, Vector3(side, SHEET_THICKNESS, side), Vector3(0, SHEET_THICKNESS * 0.5, 0), _metal)


func _add_box(parent: Node3D, dimensions: Vector3, position: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.material_override = material
	node.position = position
	parent.add_child(node)


func frame() -> void:
	var k := side / 12.0
	_camera.position = Vector3(2.0 * k, 12.0 * k, 19.5 * k)
	_camera.look_at(Vector3(2.0 * k, 2.4 * k, 0.0), Vector3.UP)


func set_cut(value: float) -> void:
	cut = value
	rebuild()


func set_side(value: float, new_capacity: float) -> void:
	side = value
	capacity = new_capacity
	level = 0.0
	frame()
	rebuild()


func animate_pour(volume: float, seconds: float = 1.1) -> Tween:
	var tween := create_tween()
	level = 0.0
	tween.tween_property(self, "level", clampf(volume / capacity, 0.0, 1.0), seconds).set_trans(Tween.TRANS_SINE)
	return tween
