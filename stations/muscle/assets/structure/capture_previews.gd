extends Node3D

var asset_root := "res://stations/muscle/assets/structure/"

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture_pair("muscle_belly.glb", "fascicle.glb", "preview_belly_fascicle.png", false)
	await _capture_pair("fiber.glb", "myofibril.glb", "preview_fiber_myofibril.png", true)
	get_tree().quit()

func _capture_pair(left_file: String, right_file: String, output: String, micro: bool) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101c29")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce8ed")
	env.ambient_light_energy = 0.28
	world.environment = env
	add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.088 if not micro else 0.088
	camera.position = Vector3(0.120, 0.020, 0.205)
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-22, -18, 0)
	key.light_color = Color("ffe0c0")
	key.light_energy = 0.85
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(18, 160, 0)
	fill.light_color = Color("9cc5ed")
	fill.light_energy = 0.6
	add_child(fill)
	var left := load(asset_root + left_file).instantiate() as Node3D
	var right := load(asset_root + right_file).instantiate() as Node3D
	left.position.x = -0.027
	right.position.x = 0.027
	if left_file == "fascicle.glb":
		left.scale = Vector3(0.000007, 0.000001, 0.000007)
	if right_file == "fascicle.glb":
		right.scale = Vector3(0.000007, 0.000001, 0.000007)
	if left_file == "fiber.glb":
		left.scale = Vector3(0.000080, 0.000001, 0.000080)
	if right_file == "myofibril.glb":
		# The 6 µm contractile repeat is intentionally magnified for legible review.
		right.scale = Vector3(0.0080, 0.0080, 0.0080)
	add_child(left)
	add_child(right)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(asset_root + output)
	print("Saved Godot viewport capture: ", output)
