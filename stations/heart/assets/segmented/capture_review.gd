extends SceneTree

const BASE := "res://stations/heart/assets/segmented/heart_segmented.glb"
const LEAKY := "res://stations/heart/assets/segmented/heart_segmented_aortic_leaky.glb"
const CLAMP := "res://stations/heart/assets/tools/clamp_vessel.glb"
const OUT := "res://docs/review/"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 1200)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var stage := Node3D.new()
	stage.rotation_degrees.y = -4.0
	vp.add_child(stage)

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#07111a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#7b8892")
	environment.ambient_light_energy = 0.38
	world.environment = environment
	stage.add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28.0, -28.0, 0.0)
	key.light_color = Color("#ffd0a1")
	key.light_energy = 1.55
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-8.0, 142.0, 0.0)
	fill.light_color = Color("#82bfd2")
	fill.light_energy = 0.48
	stage.add_child(fill)

	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0.035, 0.067, 0.39)
	camera.current = true
	stage.add_child(camera)
	camera.look_at(Vector3(0.0, 0.066, 0.0), Vector3.UP)

	for entry in [[BASE, "heart008_segmented_front.png"], [LEAKY, "heart008_aortic_leaky_front.png"]]:
		var packed: PackedScene = load(entry[0])
		var model := packed.instantiate() as Node3D
		stage.add_child(model)
		await process_frame
		await process_frame
		var image := vp.get_texture().get_image()
		var error := image.save_png(OUT + entry[1])
		print("Saved ", entry[1], "; error=", error)
		if entry[0] == BASE:
			var base_body := model.find_child("HeartBody", true, false) as Node3D
			if base_body:
				base_body.visible = false
				await process_frame
				await process_frame
				var components_image := vp.get_texture().get_image()
				var components_error := components_image.save_png(OUT + "heart008_components_debug.png")
				print("Saved isolated component review; error=", components_error)
		model.queue_free()
		await process_frame

	stage.rotation_degrees.y = 0.0
	camera.position = Vector3(0.20, 0.24, 0.34)
	camera.look_at(Vector3(0.0, 0.066, 0.0), Vector3.UP)
	var oblique_scene: PackedScene = load(BASE)
	var oblique_model := oblique_scene.instantiate() as Node3D
	stage.add_child(oblique_model)
	await process_frame
	await process_frame
	var oblique_error := vp.get_texture().get_image().save_png(OUT + "heart008_segmented_oblique.png")
	print("Saved oblique valve-plane review; error=", oblique_error)
	oblique_model.queue_free()
	await process_frame

	stage.rotation_degrees.y = 0.0
	camera.fov = 36.0
	camera.position = Vector3(0.0, -0.010, 0.105)
	camera.look_at(Vector3(0.0, -0.005, 0.0), Vector3.UP)
	var clamp_scene: PackedScene = load(CLAMP)
	var clamp_model := clamp_scene.instantiate() as Node3D
	stage.add_child(clamp_model)
	await process_frame
	await process_frame
	var clamp_error := vp.get_texture().get_image().save_png(OUT + "heart008_clamp_vessel.png")
	print("Saved vessel clamp review; error=", clamp_error)
	clamp_model.queue_free()
	quit()
