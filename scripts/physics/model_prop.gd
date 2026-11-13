extends SubViewportContainer
## 2D sahneye gömülen 3B model: kendi dünyası, kamerası ve ışığı olan şeffaf SubViewport.
## Model sınır kutusuna göre ortalanır ve kameraya sığdırılır. `spin_speed` ile yavaşça döner.
## Kullanım: var prop := ModelProp.new(); prop.setup("res://assets/models/horseshoe-magnet.glb"); add_child(prop)

var spin_speed := 0.0          ## rad/s, Y ekseni
var tint := Color(1, 1, 1, 1)

var _holder: Node3D
var _viewport: SubViewport


func setup(model_path: String, pitch_deg: float = -18.0, yaw_deg: float = 30.0, roll_deg: float = 0.0) -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.size = Vector2i(512, 512)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var world := Node3D.new()
	_viewport.add_child(world)

	_holder = Node3D.new()
	world.add_child(_holder)
	var scene: PackedScene = load(model_path)
	var model: Node3D = scene.instantiate()
	_holder.add_child(model)
	var box := _bounds(model)
	var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	model.position = -(box.position + box.size * 0.5)
	_holder.scale = Vector3.ONE * (2.0 / maxf(longest, 0.0001))
	_holder.rotation_degrees = Vector3(-pitch_deg, yaw_deg, roll_deg)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.0
	camera.position = Vector3(0, 0, 6)
	world.add_child(camera)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -30, 0)
	key.light_energy = 1.6
	world.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_color = Color("#6fb8ff")
	rim.light_energy = 1.1
	world.add_child(rim)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.8, 1.0)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	world.add_child(env)


func _process(delta: float) -> void:
	if _holder != null and spin_speed != 0.0:
		_holder.rotate_y(spin_speed * delta)


static func _bounds(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var local := mesh.get_aabb()
		var transformed := (mesh.global_transform if mesh.is_inside_tree() else _chain(mesh, node)) * local
		result = transformed if first else result.merge(transformed)
		first = false
	return result


static func _chain(node: Node3D, root: Node) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root.get_parent():
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform
