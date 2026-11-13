extends Node3D
## Hand-authored low-poly/PBR scene painter for range_bg.png.
## Uses only native Godot meshes, procedural materials, and local lighting.

const W := 1920
const H := 1080
const OUT_PATH := "res://stations/projectile/assets/range_bg.png"

func _ready() -> void:
	call_deferred("_render")

func _render() -> void:
	var viewport := get_viewport()
	viewport.size = Vector2i(W, H)
	var stage: Node3D = self
	_build_environment(stage)
	_build_room(stage)
	_build_window(stage)
	_build_platform(stage)
	_build_floor(stage)
	_build_lighting(stage)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.35
	camera.position = Vector3(0.0, 8.3, 24.0)
	camera.current = true
	stage.add_child(camera)
	camera.look_at(Vector3(0.0, 5.05, 0.0), Vector3.UP)
	for _i in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var err := image.save_png(ProjectSettings.globalize_path(OUT_PATH))
	if err != OK:
		push_error("Failed to save projectile background: %s" % err)
	get_tree().quit(err)

func _noise_image(seed_value: int, frequency: float, contrast: float = 20.0) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = frequency
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(256):
			var n := noise.get_noise_2d(float(x), float(y))
			var value := clampf(0.86 + n * contrast / 255.0, 0.60, 1.0)
			image.set_pixel(x, y, Color(value, value, value, 1.0))
	return ImageTexture.create_from_image(image)

func _mat(color: Color, metallic: float, roughness: float, seed_value: int, freq: float, contrast: float = 20.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.albedo_texture = _noise_image(seed_value, freq, contrast)
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 2.5
	return mat

func _solid(color: Color, metallic: float = 0.0, roughness: float = 0.5, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
	return mat

func _box(parent: Node3D, name: String, size: Vector3, at: Vector3, material: Material, bevel_hint: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.position = at
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	return node

func _beam(parent: Node3D, name: String, a: Vector3, b: Vector3, thickness: float, depth: float, material: Material) -> MeshInstance3D:
	var direction := b - a
	var length := direction.length()
	var y_axis := direction.normalized()
	var x_axis := Vector3.FORWARD.cross(y_axis).normalized()
	if x_axis.length_squared() < 0.1:
		x_axis = Vector3.RIGHT
	var z_axis := x_axis.cross(y_axis).normalized()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, length, depth)
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.position = (a + b) * 0.5
	node.basis = Basis(x_axis, y_axis, z_axis)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	return node

func _cylinder(parent: Node3D, name: String, radius: float, height: float, at: Vector3, material: Material, segments: int = 20) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.position = at
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	return node

func _bolt(parent: Node3D, at: Vector3, steel: Material, count: int = 1) -> void:
	for i in range(count):
		var offset := Vector3(0.0, 0.0, 0.0)
		if count > 1:
			offset = Vector3(0.0, 0.0, (float(i) - float(count - 1) / 2.0) * 0.34)
		var head := _cylinder(parent, "Counterbored deck bolt", 0.055, 0.025, at + offset, steel, 16)
		var slot := _box(parent, "Bolt slot", Vector3(0.050, 0.009, 0.008), head.position + Vector3(0.0, 0.015, 0.0), _solid(Color(0.055, 0.067, 0.072), 0.35, 0.48))
		slot.rotation.y = 0.35

func _build_environment(stage: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.014, 0.022, 0.036)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.46, 0.56)
	env.ambient_light_energy = 2.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12
	env.tonemap_white = 5.3
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.92
	env.glow_enabled = true
	env.glow_intensity = 0.07
	env.glow_bloom = 0.02
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)

func _build_room(stage: Node3D) -> void:
	var wall := _mat(Color(0.075, 0.105, 0.14), 0.08, 0.76, 704, 0.035, 15.0)
	var wall_trim := _solid(Color(0.038, 0.058, 0.076), 0.25, 0.66)
	var seam := _solid(Color(0.12, 0.17, 0.20), 0.1, 0.72)
	# Deep wall behind the shot, split only at the far left to leave a true window opening.
	_box(stage, "Rear wall broad clean measurement bay", Vector3(16.6, 12.0, 0.28), Vector3(3.1, 5.7, -4.2), wall)
	_box(stage, "Rear wall left return", Vector3(1.8, 12.0, 0.28), Vector3(-10.4, 5.7, -4.2), wall)
	_box(stage, "Wall above window", Vector3(4.5, 1.6, 0.28), Vector3(-7.25, 10.9, -4.2), wall)
	_box(stage, "Wall below window", Vector3(4.5, 2.4, 0.28), Vector3(-7.25, 1.2, -4.2), wall)
	# Sparse acoustic panel joints on the right are almost lost in shadow.
	for x in [1.2, 5.5, 9.5]:
		_box(stage, "Wall seam shadow", Vector3(0.018, 9.8, 0.012), Vector3(x, 5.9, -4.04), wall_trim)
		_box(stage, "Wall seam edge", Vector3(0.009, 9.8, 0.012), Vector3(x + 0.035, 5.9, -4.025), seam)
	_box(stage, "Low wall base reveal", Vector3(16.8, 0.05, 0.035), Vector3(3.0, 0.62, -4.01), seam)

func _build_window(stage: Node3D) -> void:
	var frame := _mat(Color(0.055, 0.075, 0.088), 0.62, 0.34, 88, 0.3, 7.0)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.11, 0.22, 0.33, 0.28)
	glass.metallic = 0.22
	glass.roughness = 0.12
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Night sky behind the glass and a low, soft city profile with sparse window points.
	var skyline := _solid(Color(0.012, 0.028, 0.052), 0.05, 0.95)
	_box(stage, "Window night sky", Vector3(4.15, 4.0, 0.05), Vector3(-7.25, 8.4, -5.05), skyline)
	var city := _solid(Color(0.022, 0.043, 0.066), 0.0, 0.95)
	for item in [[-9.2, 1.0, 2.0], [-8.2, 1.45, 2.6], [-6.85, 0.95, 1.9], [-5.55, 1.5, 2.8]]:
		_box(stage, "Distant city silhouette", Vector3(item[2], item[1], 0.06), Vector3(item[0], 6.15 + item[1] * 0.5, -4.98), city)
	var city_light := _solid(Color(0.8, 0.58, 0.32), 0.0, 0.45, Color(0.5, 0.24, 0.07))
	for i in range(12):
		var xx := -9.95 + float((i * 19) % 42) * 0.1
		var yy := 6.15 + float((i * 13) % 19) * 0.1
		_box(stage, "Distant amber window", Vector3(0.055, 0.08, 0.02), Vector3(xx, yy, -4.91), city_light)
	# Four panes with slight blue reflection, encased in deep steel mullions.
	_box(stage, "Window glazing", Vector3(4.1, 4.05, 0.045), Vector3(-7.25, 8.35, -4.68), glass)
	var reflection := _solid(Color(0.32, 0.48, 0.61, 0.19), 0.18, 0.16)
	reflection.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var refl1 := _box(stage, "Window reflected cool softbox", Vector3(0.16, 3.4, 0.014), Vector3(-8.57, 8.3, -4.64), reflection)
	refl1.rotation.z = -0.16
	var refl2 := _box(stage, "Window reflected soft edge", Vector3(0.07, 3.0, 0.012), Vector3(-6.1, 8.35, -4.645), reflection)
	refl2.rotation.z = -0.16
	var mullion := _solid(Color(0.027, 0.042, 0.054), 0.58, 0.39)
	for x in [-9.35, -8.3, -7.25, -6.2, -5.15]:
		_box(stage, "Window vertical mullion", Vector3(0.085, 4.42, 0.24), Vector3(x, 8.35, -4.52), frame)
	for y in [6.12, 8.35, 10.58]:
		_box(stage, "Window horizontal mullion", Vector3(4.42, 0.09, 0.24), Vector3(-7.25, y, -4.52), frame)
	# Inner stainless bead catches the cool window fill on the left edge.
	_box(stage, "Window interior glint", Vector3(0.018, 4.12, 0.01), Vector3(-9.31, 8.35, -4.38), _solid(Color(0.36, 0.49, 0.53), 0.45, 0.22))

func _build_platform(stage: Node3D) -> void:
	var concrete := _mat(Color(0.13, 0.16, 0.17), 0.08, 0.86, 256, 0.055, 31.0)
	var steel := _mat(Color(0.22, 0.27, 0.28), 0.76, 0.37, 512, 0.36, 11.0)
	var bright_steel := _mat(Color(0.50, 0.52, 0.48), 0.82, 0.23, 912, 0.3, 8.0)
	var painted := _mat(Color(0.16, 0.18, 0.18), 0.48, 0.56, 171, 0.08, 18.0)
	var bolt_mat := _solid(Color(0.46, 0.48, 0.43), 0.86, 0.22)
	var dark_slot := _solid(Color(0.035, 0.047, 0.051), 0.52, 0.44)
	# The long left deck is scaled as a raised launch platform, with no labels or hardware clutter.
	_box(stage, "Raised platform concrete core", Vector3(4.85, 0.34, 1.68), Vector3(-6.76, 7.45, 0.0), concrete)
	_box(stage, "Machined lower fascia", Vector3(5.15, 0.18, 1.78), Vector3(-6.75, 7.18, 0.0), painted)
	_box(stage, "Front fascia bright bevel", Vector3(5.07, 0.025, 0.035), Vector3(-6.75, 7.26, 0.905), bright_steel)
	_box(stage, "Top steel skin", Vector3(5.0, 0.06, 1.72), Vector3(-6.75, 7.66, 0.0), steel)
	_box(stage, "Launch guide rail near side", Vector3(4.5, 0.08, 0.11), Vector3(-6.74, 7.74, 0.54), bright_steel)
	_box(stage, "Launch guide rail far side", Vector3(4.5, 0.08, 0.11), Vector3(-6.74, 7.74, -0.54), bright_steel)
	_box(stage, "Launch rail black channel", Vector3(4.45, 0.025, 0.14), Vector3(-6.74, 7.73, 0.0), dark_slot)
	# Ticks: fine unlabelled length divisions on a 45 m platform; no decorative text.
	var tick_mat := _solid(Color(0.73, 0.67, 0.52), 0.58, 0.32)
	for i in range(31):
		var x := -9.05 + float(i) * 0.153
		var length := 0.16 if i % 5 == 0 else 0.08
		_box(stage, "Etched length graduation", Vector3(0.012, 0.008, length), Vector3(x, 7.699, -0.36 + length * 0.5), tick_mat)
	# Deck bolts down the side plate and at both support rail mounts.
	for x in [-9.08, -8.22, -7.36, -6.5, -5.64, -4.78]:
		for z in [-0.72, 0.72]:
			_bolt(stage, Vector3(x, 7.78, z), bolt_mat)
	# Deep spatial bracing: box beams have chamfer-like stacked edges and actual cast shadow.
	var brace_front := Vector3(0.0, 0.0, 0.52)
	var brace_back := Vector3(0.0, 0.0, -0.52)
	for zoff in [brace_front, brace_back]:
		var a := Vector3(-8.14, 0.1, zoff.z)
		var b := Vector3(-5.44, 7.18, zoff.z)
		var c := Vector3(-5.44, 0.1, zoff.z)
		var e := Vector3(-8.14, 7.18, zoff.z)
		_beam(stage, "Outer tower column", Vector3(-8.14, 0.12, zoff.z), e, 0.21, 0.20, painted)
		_beam(stage, "Inner tower column", Vector3(-5.44, 0.12, zoff.z), b, 0.21, 0.20, steel)
		for y in range(1, 7):
			var left := Vector3(-8.12, float(y), zoff.z)
			var right := Vector3(-5.46, float(y), zoff.z)
			_beam(stage, "Cross tie", left, right, 0.13, 0.17, painted)
			_beam(stage, "Diagonal truss", Vector3(-8.1, float(y - 1), zoff.z), Vector3(-5.48, float(y), zoff.z), 0.095, 0.15, steel)
			_beam(stage, "Return diagonal truss", Vector3(-5.48, float(y - 1), zoff.z), Vector3(-8.1, float(y), zoff.z), 0.075, 0.14, painted)
			for bx in [-8.07, -5.52]:
				_cylinder(stage, "Truss gusset bolt", 0.052, 0.035, Vector3(bx, float(y) - 0.5, zoff.z + 0.112), bolt_mat, 16)
	# Pier footings and anchor plates are in contact with the ground.
	for x in [-8.14, -5.44]:
		_box(stage, "Truss baseplate", Vector3(0.58, 0.10, 0.68), Vector3(x, 0.055, 0.0), steel)
		for z in [-0.23, 0.23]:
			_bolt(stage, Vector3(x, 0.116, z), bolt_mat)
	# Back guard only; leave open sky and the right half clear for projectile trajectory.
	for x in [-8.95, -4.65]:
		_beam(stage, "Guard upright", Vector3(x, 7.78, -0.65), Vector3(x, 8.42, -0.65), 0.055, 0.06, bright_steel)
	_beam(stage, "Guard top tube", Vector3(-8.95, 8.42, -0.65), Vector3(-4.65, 8.42, -0.65), 0.055, 0.06, bright_steel)

func _build_floor(stage: Node3D) -> void:
	var floor_mat := _mat(Color(0.10, 0.12, 0.13), 0.12, 0.75, 393, 0.09, 34.0)
	var floor_base := _mat(Color(0.035, 0.050, 0.057), 0.18, 0.48, 814, 0.25, 12.0)
	var socket_mat := _mat(Color(0.07, 0.09, 0.095), 0.76, 0.38, 128, 0.26, 9.0)
	var rim_mat := _mat(Color(0.50, 0.52, 0.48), 0.82, 0.23, 912, 0.3, 8.0)
	_box(stage, "Concrete floor slab", Vector3(28.0, 0.28, 16.0), Vector3(0.0, -0.19, 0.0), floor_mat)
	# Floor slab edge and barely visible expansion seams ground the target area.
	for x in [-8.5, -3.0, 2.5, 8.0]:
		_box(stage, "Floor expansion seam", Vector3(0.018, 0.006, 14.0), Vector3(x, -0.045, 0.0), floor_base)
	# Recessed landing plate is the physical mount for the separate target_ring sprite.
	var pad := _cylinder(stage, "Flush landing plate", 0.83, 0.035, Vector3(5.5, -0.03, 0.0), socket_mat, 48)
	pad.rotation.x = 0.0
	var rim := _cylinder(stage, "Target plate outer edge", 0.86, 0.02, Vector3(5.5, -0.006, 0.0), rim_mat, 48)
	rim.scale.y = 0.4
	var dark_center := _cylinder(stage, "Target ring recess", 0.68, 0.018, Vector3(5.5, 0.004, 0.0), floor_base, 48)
	dark_center.scale.y = 0.35
	# Amber lamp reflection and cool glass fill streaks on epoxy remain subtle and fixed.
	var amber_reflection := _solid(Color(0.55, 0.27, 0.11), 0.28, 0.24, Color(0.13, 0.055, 0.016))
	for i in range(7):
		var strip := _box(stage, "Warm floor sheen", Vector3(0.12 + i * 0.055, 0.004, 2.3 - i * 0.17), Vector3(-6.2 + i * 0.28, -0.035, 1.5 + i * 0.08), amber_reflection)
		strip.rotation.y = 0.18

func _build_lighting(stage: Node3D) -> void:
	var lamp_shell := _solid(Color(0.055, 0.075, 0.084), 0.72, 0.32)
	var lamp_inner := _solid(Color(0.78, 0.52, 0.27), 0.18, 0.24, Color(1.0, 0.42, 0.13))
	_cylinder(stage, "Task lamp suspension cable", 0.025, 1.15, Vector3(-6.0, 11.3, 3.0), lamp_shell, 12)
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = 0.22
	shade_mesh.bottom_radius = 0.61
	shade_mesh.height = 0.26
	shade_mesh.radial_segments = 48
	var shade := MeshInstance3D.new()
	shade.name = "Dark enamel task lamp shade"
	shade.mesh = shade_mesh
	shade.position = Vector3(-6.0, 10.58, 3.0)
	shade.material_override = lamp_shell
	stage.add_child(shade)
	_cylinder(stage, "Amber diffuser", 0.39, 0.018, Vector3(-6.0, 10.44, 3.0), lamp_inner, 48)
	var warm := SpotLight3D.new()
	warm.name = "Amber overhead task lamp"
	warm.position = Vector3(-6.0, 11.2, 3.0)
	warm.light_color = Color(1.0, 0.68, 0.36)
	warm.light_energy = 22.0
	warm.spot_range = 10.0
	warm.spot_angle = 44.0
	warm.spot_angle_attenuation = 1.4
	warm.shadow_enabled = true
	warm.shadow_bias = 0.06
	warm.shadow_normal_bias = 1.0
	stage.add_child(warm)
	warm.look_at(Vector3(-6.6, 7.65, 0.0), Vector3.UP)
	var window_fill := OmniLight3D.new()
	window_fill.name = "Cool window fill"
	window_fill.position = Vector3(-10.8, 8.6, 1.8)
	window_fill.light_color = Color(0.32, 0.56, 0.86)
	window_fill.light_energy = 6.5
	window_fill.omni_range = 13.0
	window_fill.shadow_enabled = true
	window_fill.shadow_bias = 0.08
	stage.add_child(window_fill)
	var window_bounce := OmniLight3D.new()
	window_bounce.name = "Soft cool window bounce across truss"
	window_bounce.position = Vector3(-8.0, 5.8, 5.0)
	window_bounce.light_color = Color(0.34, 0.54, 0.82)
	window_bounce.light_energy = 18.0
	window_bounce.omni_range = 14.0
	window_bounce.shadow_enabled = false
	stage.add_child(window_bounce)
	var warm_bounce := OmniLight3D.new()
	warm_bounce.name = "Warm bounce beside launch table"
	warm_bounce.position = Vector3(-6.9, 8.8, 6.0)
	warm_bounce.light_color = Color(1.0, 0.62, 0.32)
	warm_bounce.light_energy = 24.0
	warm_bounce.omni_range = 9.5
	warm_bounce.shadow_enabled = false
	stage.add_child(warm_bounce)
	var room_rim := DirectionalLight3D.new()
	room_rim.name = "Very low cool room fill"
	room_rim.rotation_degrees = Vector3(-31.0, -23.0, 0.0)
	room_rim.light_color = Color(0.38, 0.49, 0.62)
	room_rim.light_energy = 1.2
	room_rim.shadow_enabled = false
	stage.add_child(room_rim)
