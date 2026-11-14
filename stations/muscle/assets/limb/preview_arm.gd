extends SceneTree

const MODEL := "res://stations/muscle/assets/limb/arm_biceps.glb"
const OUT := "res://stations/muscle/assets/limb/previews/"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 960)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#09121b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#52616c")
	environment.ambient_light_energy = 0.42
	env.environment = environment
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-26, -26, 0)
	key.light_energy = 1.35
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-6, 140, 0)
	fill.light_color = Color("#73b2cb")
	fill.light_energy = 0.28
	stage.add_child(fill)
	var model: Node3D = load(MODEL).instantiate()
	stage.add_child(model)
	var elbow := model.find_child("Elbow", true, false) as Node3D
	if elbow == null:
		push_error("The imported arm is missing its Elbow pivot.")
		quit(1)
		return
	for state in ["biceps_flexion", "triceps_extension"]:
		elbow.rotation_degrees.z = 65.0 if state == "biceps_flexion" else -22.0
		await process_frame
		await process_frame
		var camera := Camera3D.new()
		# The extension study presents the posterior side so the working triceps is legible.
		camera.position = Vector3(0.45, 0.26, 0.70 if state == "biceps_flexion" else -0.70)
		camera.fov = 38
		stage.add_child(camera)
		camera.look_at(Vector3(0.08, 0.15, 0.0), Vector3.UP)
		camera.current = true
		await process_frame
		await process_frame
		vp.get_texture().get_image().save_png(OUT + state + ".png")
		camera.queue_free()
		await process_frame
	print("Rendered biceps flexion and triceps extension previews.")
	quit()
