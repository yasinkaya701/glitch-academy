extends SubViewportContainer
## Fizik deneyleri için gerçek 3B laboratuvar sahnesi: PBR metal zemin, gölgeli ana ışık, renkli kenar ışığı, bloom, sis,
## gökyüzü yansıması. İstasyonlar `world` altına kendi 3B nesnelerini koyar; 2B katman `project()` ile 3B noktaları ekrana taşır.

const METAL_DIR := "res://assets/materials/Metal009/Metal009_2K-JPG_"
const PLATE_DIR := "res://assets/materials/DiamondPlate008C/DiamondPlate008C_2K-JPG_"
const HDRI := "res://assets/polyhaven/hdri/aerodynamics_workshop/aerodynamics_workshop_2k.hdr"

var world: Node3D
var camera: Camera3D
var viewport: SubViewport
var key_light: DirectionalLight3D
var rim_light: DirectionalLight3D
var active_drag: Node  ## sürüklenen düğme


func setup(accent: Color, fov: float = 30.0, camera_position: Vector3 = Vector3(0, 0.72, 3.4), look_at: Vector3 = Vector3(0, 0.12, 0)) -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_handle_gui)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.physics_object_picking = true
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)

	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = load(HDRI)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.sky_rotation = Vector3(0, deg_to_rad(20.0), 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 1.0
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.4
	environment.ssao_enabled = true
	environment.ssao_intensity = 1.6
	var holder := WorldEnvironment.new()
	holder.environment = environment
	world.add_child(holder)

	camera = Camera3D.new()
	camera.fov = fov
	world.add_child(camera)
	camera.look_at_from_position(camera_position, look_at)

	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48, -28, 0)
	key_light.light_energy = 0.9
	key_light.light_color = Color("#fff1de")
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 12.0
	world.add_child(key_light)
	rim_light = DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-18, 155, 0)
	rim_light.light_energy = 0.2
	rim_light.light_color = Color("#cfe0f5")
	world.add_child(rim_light)

	# Zemin: koyu PBR metal levha, sisle birlikte ufka doğru kaybolur
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 24)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#23262b")
	floor_material.roughness = 0.9
	floor_mesh.material_override = floor_material
	floor_mesh.position = Vector3(0, -0.06, -4.0)
	world.add_child(floor_mesh)


## Klasör ön ekinden Color/Metalness/NormalGL/Roughness haritalarıyla PBR malzeme kurar.
static func pbr(prefix: String, uv_scale: Vector3 = Vector3.ONE, tint: Color = Color.WHITE, metal: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(prefix + "Color.jpg")
	material.albedo_color = tint
	material.metallic = metal
	material.metallic_texture = load(prefix + "Metalness.jpg")
	material.roughness_texture = load(prefix + "Roughness.jpg")
	material.normal_enabled = true
	material.normal_texture = load(prefix + "NormalGL.jpg")
	material.uv1_scale = uv_scale
	material.uv1_triplanar = true
	return material


## Poly Haven PBR (diff, nor_gl, rough) 1k. metal: sabit metaliklik.
static func pbr_ph(asset: String, uv_scale: Vector3 = Vector3.ONE, tint: Color = Color.WHITE, metal: float = 0.0) -> StandardMaterial3D:
	var base := "res://assets/polyhaven/tex/%s/%s_" % [asset, asset]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(base + "diff_1k.jpg")
	material.albedo_color = tint
	material.roughness_texture = load(base + "rough_1k.jpg")
	material.metallic = metal
	material.normal_enabled = true
	material.normal_texture = load(base + "nor_gl_1k.jpg")
	material.normal_scale = 0.5
	material.uv1_scale = uv_scale
	material.uv1_triplanar = true
	return material


static func glow_material(colour: Color, energy: float = 2.5) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	return material


static func glass_material(tint: Color = Color(0.7, 0.9, 1.0), alpha: float = 0.22) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.0
	material.roughness = 0.04
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Kutu mesh: boyut, malzeme ve konum.
func box(size_vec: Vector3, material: Material, position: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_vec
	node.mesh = mesh
	node.material_override = material
	node.position = position
	(parent if parent != null else world).add_child(node)
	return node


## Glb modelini örnekler, sınır kutusunun merkezi origine, uzun kenarı `fit` birime oturur.
func model(path: String, fit: float, parent: Node3D = null, on_ground: bool = false, skip_names: Array = []) -> Node3D:
	var holder := Node3D.new()
	var instance: Node3D = (load(path) as PackedScene).instantiate()
	for extra in instance.find_children("*", "", true, false):
		if extra is Camera3D or extra.name in skip_names:
			extra.get_parent().remove_child(extra)
			extra.queue_free()
	holder.add_child(instance)
	(parent if parent != null else world).add_child(holder)
	var bounds := AABB()
	var first := true
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var local := _chain(mesh, instance) * mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first = false
	var longest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	instance.position = -(bounds.position + bounds.size * 0.5)
	if on_ground:
		instance.position.y = -bounds.position.y
	holder.scale = Vector3.ONE * (fit / maxf(longest, 0.0001))
	return holder


static func _chain(node: Node3D, root: Node) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root.get_parent():
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform


## 3B noktanın bu denetimdeki 2B konumu.
func project(point: Vector3) -> Vector2:
	var raw := camera.unproject_position(point)
	return raw * (size / Vector2(viewport.size))


func _pick(position: Vector2) -> Node:
	var scaled := position * (Vector2(viewport.size) / size)
	var origin := camera.project_ray_origin(scaled)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(scaled) * 30.0)
	query.collide_with_areas = true
	var hit := viewport.find_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Object = hit["collider"]
	return collider.get_meta("handler") if collider.has_meta("handler") else null


var _hover_target: Node


func _handle_gui(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if active_drag != null:
			active_drag.drag((event as InputEventMouseMotion).relative)
			return
		var target := _pick((event as InputEventMouseMotion).position)
		if target != _hover_target:
			if _hover_target != null and is_instance_valid(_hover_target):
				_hover_target.pick_hover(false)
			_hover_target = target
			if target != null:
				target.pick_hover(true)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed:
			var target := _pick(button.position)
			if target != null:
				target.pick_press(button)
		elif button.button_index == MOUSE_BUTTON_LEFT:
			active_drag = null


## Silindir mesh: yarıçap, yükseklik, malzeme, konum, döndürme (derece).
func cylinder(radius: float, height: float, material: Material, position: Vector3, rotation_deg: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	node.mesh = mesh
	node.material_override = material
	node.position = position
	node.rotation_degrees = rotation_deg
	(parent if parent != null else world).add_child(node)
	return node


## Hava yastıklı ray kızağı (glider): rayın üstüne ters U gibi oturur. Üst plaka, iki yan etek, renkli bant, uç tamponları,
## foto kapı bayrağı ve pirinç ağırlıklar. Rayın üst yüzü y = 0.045, kızağın alt kenarı y = 0.021 (hava aralığı).
func build_glider(parent: Node3D, length: float, colour: Color, weights: int, columns: int = 4, thruster: bool = false) -> void:
	var alu := pbr(METAL_DIR, Vector3(3, 3, 3), Color(0.92, 0.94, 0.97), 1.0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour.darkened(0.2)
	paint.roughness = 0.38
	paint.metallic = 0.25
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("#15171a")
	rubber.roughness = 0.85
	box(Vector3(length, 0.012, 0.108), alu, Vector3(0, 0.067, 0), parent)
	for side in [-1.0, 1.0]:
		box(Vector3(length, 0.046, 0.008), alu, Vector3(0, 0.044, side * 0.047), parent)
		box(Vector3(length * 0.84, 0.014, 0.0095), paint, Vector3(0, 0.054, side * 0.0475), parent)
	for end in [-1.0, 1.0]:
		cylinder(0.011, 0.03, alu, Vector3(end * (length * 0.5 + 0.012), 0.067, 0), Vector3(0, 0, 90), parent)
		cylinder(0.014, 0.012, rubber, Vector3(end * (length * 0.5 + 0.03), 0.067, 0), Vector3(0, 0, 90), parent)
	box(Vector3(0.006, 0.07, 0.045), paint, Vector3(0.0, 0.108, 0.0), parent)
	if thruster:
		box(Vector3(0.07, 0.032, 0.06), alu, Vector3(-length * 0.5 + 0.05, 0.089, 0), parent)
		var nozzle := cylinder(0.02, 0.05, alu, Vector3(-length * 0.5 - 0.006, 0.089, 0), Vector3(0, 0, 90), parent)
		(nozzle.mesh as CylinderMesh).top_radius = 0.014
		(nozzle.mesh as CylinderMesh).bottom_radius = 0.026
	var rows := int(ceil(float(weights) / float(columns)))
	for n in weights:
		var column := n % columns
		var row := n / columns
		var x := (-0.5 * float(mini(columns, weights) - 1) + float(column)) * 0.066
		if thruster:
			x += 0.04
		var z := (float(row) - 0.5 * float(rows - 1)) * 0.056
		var load := model("res://stations/shared_assets/lab/mass_heavy.glb", 0.05, parent)
		load.position = Vector3(x, 0.073 + 0.025, z)


const TOY_CAR := "res://assets/models/toy_car/ToyCar.glb"


## Oyuncak araba (CC0 Toy Car): örtüsü atılır, ön yüz +X'e (facing = -1 ise -X'e) bakar, tekerlekler y = base'e oturur.
## Kütle, çatıya dizilen pirinç ağırlıkların sayısıyla gösterilir. `colour` yalnızca ayırt edici bayrağın rengidir.
func build_car(parent: Node3D, colour: Color, weights: int, facing: float = 1.0, base: float = 0.02) -> void:
	var car := model(TOY_CAR, 0.24, parent, true, ["Fabric"])
	car.rotation_degrees = Vector3(0, 90.0 * facing, 0)
	car.position.y = base
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = 0.4
	box(Vector3(0.005, 0.07, 0.05), paint, Vector3(-0.1 * facing, base + 0.1, 0.0), parent)
	for n in weights:
		var load := model("res://stations/shared_assets/lab/mass_heavy.glb", 0.04, parent)
		load.position = Vector3(((n % 3) - 1) * 0.05 * 1.0, base + 0.078 + (n / 6) * 0.04, (float((n / 3) % 2) - 0.5) * 0.045)
