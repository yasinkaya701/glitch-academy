extends Control
## Purpose-built orbital observatory model for the seasons lesson.
## The lesson's measured values still come from seasons_model.gd; this script only
## makes the geometry and the greenhouse failure legible in 3D.

const Model = preload("res://stations/seasons/seasons_model.gd")
const INK := UITheme.INK
const MUTED := UITheme.MUTED
const AQUA := UITheme.ACCENT
const GOLD := UITheme.WARM
const ORBIT := UITheme.EDGE_STRONG
const EARTH_ALBEDO := preload("res://stations/seasons/assets/earth_albedo_4k.jpg")
const GREENHOUSE_INTERIOR := preload("res://stations/seasons/assets/grab3d/greenhouse-interior.glb")

var december := false
var tilt := Model.AXIAL_TILT
var greenhouse := true
var repaired := false
var guides_visible := false
var incident_time := 0.0

var viewport: SubViewport
var world: Node3D
var system_rig: Node3D
var orbit_rig: Node3D
var camera: Camera3D
var earths: Array[Node3D] = []
var earth_surfaces: Array[MeshInstance3D] = []
var summer_markers: Array[MeshInstance3D] = []
var winter_markers: Array[MeshInstance3D] = []
var solar_spheres: Array[MeshInstance3D] = []
var solar_rays: Array[MeshInstance3D] = []
var solar_visuals: Array[MeshInstance3D] = []
var starfield: MultiMeshInstance3D
var solar_light: OmniLight3D
var orbit_material: StandardMaterial3D
var greenhouse_root: Node3D
var readout := ""
var dragging_system := false
var last_pointer := Vector2.ZERO


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	var viewport_box := SubViewportContainer.new()
	viewport_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_box.stretch = true
	viewport_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_box)
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_box.add_child(viewport)
	world = Node3D.new()
	world.name = "ObservatoryWorld"
	viewport.add_child(world)
	system_rig = Node3D.new()
	system_rig.name = "RotatableSolarSystem"
	world.add_child(system_rig)
	_build_world()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.double_click:
				_reset_system_view()
				dragging_system = false
				accept_event()
				return
			dragging_system = mouse_button.pressed
			last_pointer = mouse_button.position
			accept_event()
			return
		if mouse_button.pressed and mouse_button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			camera.size = clampf(camera.size + (-0.45 if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP else 0.45), 5.3, 10.0)
			accept_event()
			return
	if event is InputEventMouseMotion and dragging_system:
		var motion := event as InputEventMouseMotion
		var delta := motion.position - last_pointer
		last_pointer = motion.position
		_rotate_system(delta)
		accept_event()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		dragging_system = touch.pressed
		last_pointer = touch.position
		accept_event()
		return
	if event is InputEventScreenDrag and dragging_system:
		var drag := event as InputEventScreenDrag
		_rotate_system(drag.relative)
		accept_event()


func _rotate_system(pointer_delta: Vector2) -> void:
	system_rig.rotation.y -= pointer_delta.x * 0.007
	system_rig.rotation.x = clampf(system_rig.rotation.x - pointer_delta.y * 0.006, -0.9, 0.9)


func _reset_system_view() -> void:
	system_rig.rotation = Vector3.ZERO
	camera.size = 8.0


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("071426")
	sky_material.sky_horizon_color = Color("203850")
	sky_material.ground_bottom_color = Color("08101c")
	sky_material.ground_horizon_color = Color("142537")
	sky_material.sun_angle_max = 0.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9ab9d4")
	env.ambient_light_energy = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	var environment := WorldEnvironment.new()
	environment.environment = env
	world.add_child(environment)

	camera = Camera3D.new()
	camera.name = "ObservatoryCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.position = Vector3(0.0, 5.25, 16.0)
	camera.current = true
	world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.45, 0.0), Vector3.UP)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -24.0, -12.0)
	key.light_color = Color("b9d9ff")
	key.light_energy = 0.72
	key.shadow_enabled = true
	world.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 4.0, 7.0)
	fill.light_color = Color("6d9ab4")
	fill.light_energy = 0.8
	fill.omni_range = 16.0
	world.add_child(fill)

	_build_orbit()
	_build_sun()
	_build_earth(Vector3(-3.55, 1.55, 0.0), "21 HAZİRAN", false)
	_build_earth(Vector3(3.55, 1.55, 0.0), "21 ARALIK", true)
	_build_starfield()
	_build_solar_rays()
	_build_greenhouse()


func _build_starfield() -> void:
	var points := MultiMesh.new()
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.018
	star_mesh.height = 0.036
	star_mesh.radial_segments = 8
	star_mesh.rings = 4
	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color("d7e8ff")
	star_material.emission_enabled = true
	star_material.emission = Color("7faad8")
	star_material.emission_energy_multiplier = 0.75
	star_mesh.material = star_material
	points.transform_format = MultiMesh.TRANSFORM_3D
	points.mesh = star_mesh
	points.instance_count = 108
	var rng := RandomNumberGenerator.new()
	rng.seed = 23062026
	for i in points.instance_count:
		var scale := rng.randf_range(0.55, 1.7)
		var position := Vector3(rng.randf_range(-6.2, 6.2), rng.randf_range(-2.4, 6.2), -11.0)
		points.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * scale), position))
	starfield = MultiMeshInstance3D.new()
	starfield.name = "DistantStars"
	starfield.multimesh = points
	world.add_child(starfield)


func _build_solar_rays() -> void:
	var ray_material := StandardMaterial3D.new()
	ray_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_material.albedo_color = Color("ffd88f", 0.28)
	ray_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_material.emission_enabled = true
	ray_material.emission = Color("ffc86e")
	ray_material.emission_energy_multiplier = 0.55
	for side in [-1.0, 1.0]:
		for offset in [-0.26, 0.0, 0.26]:
			var start := Vector3(side * 0.61, 1.55 + offset, 0.0)
			var finish := Vector3(side * 2.79, 1.55 + offset, 0.0)
			var ray := _beam(start, finish, 0.012, Color("ffd88f"))
			ray.material_override = ray_material
			ray.name = "SolarRay_%s_%s" % ["L" if side < 0.0 else "R", str(offset)]
			system_rig.add_child(ray)
			solar_rays.append(ray)


func _build_orbit() -> void:
	orbit_rig = Node3D.new()
	orbit_rig.name = "OrbitalModel"
	system_rig.add_child(orbit_rig)
	orbit_material = _material(Color("74a9bc"), 0.56, 0.0, 0.25)
	orbit_material.emission_enabled = true
	orbit_material.emission = Color("183849")
	var path := MeshInstance3D.new()
	var path_mesh := TorusMesh.new()
	path_mesh.inner_radius = 3.77
	path_mesh.outer_radius = 3.79
	path.mesh = path_mesh
	path.material_override = orbit_material
	path.position = Vector3(0.0, 1.55, 0.0)
	path.scale = Vector3(1.0, 0.01, 0.52)
	path.name = "EclipticOrbit"
	orbit_rig.add_child(path)
	# Four brass station pins mark the solstices and equinoxes on the orbit.
	for i in 4:
		var angle := TAU * float(i) / 4.0
		var pin := _sphere(0.055, _material(Color("f1bd7a"), 0.34, 0.35, 0.18))
		pin.position = Vector3(cos(angle) * 3.78, 1.58, sin(angle) * 1.97)
		pin.name = "SeasonalOrbitMarker_%02d" % i
		orbit_rig.add_child(pin)
	# A fine circular calibration deck under the orbit gives the display a measured instrument feel.
	var deck := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = 4.7
	disk.bottom_radius = 4.7
	disk.height = 0.08
	deck.mesh = disk
	deck.position = Vector3(0.0, -0.04, 0.0)
	deck.material_override = _material(Color("122333"), 0.7, 0.22, 0.22)
	deck.name = "CalibrationDeck"
	orbit_rig.add_child(deck)
	for radius in [4.2, 4.45]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.008
		torus.outer_radius = radius + 0.008
		ring.mesh = torus
		ring.position.y = 0.012
		ring.material_override = _material(Color("345467"), 0.4, 0.0, 0.35)
		orbit_rig.add_child(ring)


func _build_sun() -> void:
	var sun := _sphere(0.66, _material(Color("ffbf6a"), 0.5, 0.0, 0.12))
	sun.name = "SunCore"
	sun.position = Vector3(0.0, 1.55, 0.0)
	var sun_mat := sun.material_override as StandardMaterial3D
	sun_mat.emission_enabled = true
	sun_mat.emission = Color("ff9d48")
	sun_mat.emission_energy_multiplier = 0.72
	system_rig.add_child(sun)
	solar_visuals.append(sun)
	for radius in [0.78, 0.9]:
		var corona := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		corona.mesh = mesh
		var material := _material(Color("ffb45f", 0.15 if radius < 0.85 else 0.065), 0.45, 0.0, 0.0)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color("fa8e36")
		material.emission_energy_multiplier = 0.45
		corona.material_override = material
		corona.position = sun.position
		corona.name = "SolarCorona_%.2f" % radius
		system_rig.add_child(corona)
		solar_visuals.append(corona)
	solar_light = OmniLight3D.new()
	solar_light.position = sun.position
	solar_light.light_color = Color("ffc875")
	solar_light.light_energy = 2.0
	solar_light.omni_range = 11.0
	solar_light.omni_attenuation = 1.1
	system_rig.add_child(solar_light)


func _build_earth(position: Vector3, marker: String, winter_side: bool) -> void:
	var pivot := Node3D.new()
	pivot.position = position
	pivot.rotation.z = -deg_to_rad(Model.AXIAL_TILT)
	pivot.name = "AxialTiltRig_%s" % marker.replace(" ", "_")
	system_rig.add_child(pivot)
	earths.append(pivot)
	var globe := _sphere(0.77, _material(Color.WHITE, 0.3, 0.0, 0.12))
	globe.name = "BlueOceanGlobe"
	var globe_material := globe.material_override as StandardMaterial3D
	globe_material.albedo_texture = EARTH_ALBEDO
	globe_material.roughness = 0.78
	globe_material.metallic = 0.0
	pivot.add_child(globe)
	earth_surfaces.append(globe)
	# Dense sphere tessellation keeps the high-resolution surface smooth at close range.
	var earth_mesh := globe.mesh as SphereMesh
	earth_mesh.radial_segments = 96
	earth_mesh.rings = 64
	var atmosphere := _sphere(0.815, ShaderMaterial.new())
	atmosphere.name = "BlueAtmosphereRim"
	var atmosphere_shader := Shader.new()
	atmosphere_shader.code = """
	shader_type spatial;
	render_mode unshaded, blend_add, cull_front, depth_draw_never;
	uniform vec3 atmosphere_tint = vec3(0.16, 0.54, 1.0);
	void fragment() {
		float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.4);
		ALBEDO = atmosphere_tint;
		EMISSION = atmosphere_tint * rim * 0.9;
		ALPHA = rim * 0.48;
	}
	"""
	var atmosphere_material := atmosphere.material_override as ShaderMaterial
	atmosphere_material.shader = atmosphere_shader
	var atmosphere_mesh := atmosphere.mesh as SphereMesh
	atmosphere_mesh.radial_segments = 96
	atmosphere_mesh.rings = 64
	pivot.add_child(atmosphere)
	var axis := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.018
	rod.bottom_radius = 0.018
	rod.height = 2.45
	axis.mesh = rod
	axis.material_override = _material(Color("ecf2dd"), 0.32, 0.44, 0.08)
	axis.name = "FixedAxialRod"
	pivot.add_child(axis)
	var equator := MeshInstance3D.new()
	var band := TorusMesh.new()
	band.inner_radius = 0.775
	band.outer_radius = 0.79
	equator.mesh = band
	equator.rotation.x = PI * 0.5
	equator.material_override = _material(Color("9db9c3", 0.78), 0.36, 0.25, 0.14)
	equator.name = "EquatorBand"
	pivot.add_child(equator)
	# Repeated latitude arcs make the sphere a measuring instrument, not a decorative globe.
	for latitude in [-45.0, 45.0]:
		var parallel := MeshInstance3D.new()
		var torus := TorusMesh.new()
		var r := cos(deg_to_rad(latitude)) * 0.78
		torus.inner_radius = r - 0.006
		torus.outer_radius = r + 0.006
		parallel.mesh = torus
		parallel.position.y = sin(deg_to_rad(latitude)) * 0.78
		parallel.rotation.x = PI * 0.5
		parallel.material_override = _material(Color("91aebc", 0.46), 0.5, 0.0, 0.0)
		parallel.name = "Latitude_%.0f" % latitude
		pivot.add_child(parallel)
	# A tiny marker lies on the hemisphere facing the Sun in each date view.
	var marker_mesh := _sphere(0.08, _material(Color("f4d18c"), 0.32, 0.25, 0.18))
	marker_mesh.name = "SunFacingLatitudeMarker"
	marker_mesh.position = Vector3(0.0, -0.33 if winter_side else 0.33, 0.73)
	pivot.add_child(marker_mesh)
	if winter_side:
		winter_markers.append(marker_mesh)
	else:
		summer_markers.append(marker_mesh)


func _build_greenhouse() -> void:
	greenhouse_root = Node3D.new()
	greenhouse_root.name = "Grab3DGreenhouseInterior"
	system_rig.add_child(greenhouse_root)
	var interior := GREENHOUSE_INTERIOR.instantiate() as Node3D
	interior.name = "OpenCC0GreenhouseInterior"
	interior.scale = Vector3.ONE * 1.25
	greenhouse_root.add_child(interior)
	# Inspection lamp and thermometer sit on the model's right interior wall.
	var lamp := _sphere(0.14, _emissive_material(Color("ff8b62"), 1.6))
	lamp.position = Vector3(1.7, 2.65, 1.8)
	lamp.name = "HeatAlarmLamp"
	greenhouse_root.add_child(lamp)
	var thermometer := _cylinder(0.05, 0.92, Color("e1e7df"), 0.3, 0.2)
	thermometer.position = Vector3(1.7, 1.5, 1.8)
	greenhouse_root.add_child(thermometer)
	var mercury := _cylinder(0.022, 0.58, Color("ff8061"), 0.28, 0.0)
	mercury.position = Vector3(1.7, 1.57, 1.84)
	mercury.name = "ThermometerMercury"
	greenhouse_root.add_child(mercury)

func _process(_delta: float) -> void:
	if not is_instance_valid(world):
		return
	if orbit_rig != null:
		orbit_rig.visible = not greenhouse
	if starfield != null:
		starfield.visible = not greenhouse
	for visual in solar_visuals:
		visual.visible = not greenhouse
	for earth in earths:
		earth.visible = not greenhouse
		earth.rotation.z = -deg_to_rad(tilt)
		# The fixed axis points consistently in space, while the globe turns beneath it.
		var globe := earth.get_node_or_null("BlueOceanGlobe") as Node3D
		if globe != null:
			globe.rotation.y = fposmod(incident_time * 0.22, TAU)
	for marker in summer_markers:
		marker.visible = not greenhouse and not december
	for marker in winter_markers:
		marker.visible = not greenhouse and december
	for ray in solar_rays:
		ray.visible = not greenhouse
	greenhouse_root.visible = greenhouse
	if greenhouse_root.visible:
		var recovery := smoothstep(0.0, 3.0, incident_time) if repaired else 0.0
		var heat := (1.0 - exp(-maxf(incident_time, 0.0) * 0.55)) * (1.0 - recovery)
		if solar_light != null:
			solar_light.light_energy = 1.25 + heat * 0.85
		var lamp := greenhouse_root.get_node("HeatAlarmLamp") as MeshInstance3D
		var lamp_mat := lamp.material_override as StandardMaterial3D
		lamp_mat.emission_energy_multiplier = 0.5 + heat * 3.0 if not repaired else 0.3
		var mercury := greenhouse_root.get_node("ThermometerMercury") as MeshInstance3D
		mercury.scale.y = lerpf(0.55, 1.15, heat)
		mercury.position.y = 1.25 + mercury.scale.y * 0.2
	readout = _current_readout()
	queue_redraw()


func _current_readout() -> String:
	var northern := Model.sample(40.0, december, tilt)
	var southern := Model.sample(-40.0, december, tilt)
	return "KUZEY  %s°  ·  %s saat" % [_decimal(northern.x), _decimal(northern.y)] + "\n" + "GÜNEY   %s°  ·  %s saat" % [_decimal(southern.x), _decimal(southern.y)]


func _draw() -> void:
	var scale_factor := minf(size.x / 720.0, size.y / 510.0)
	var offset := (size - Vector2(720.0, 510.0) * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	_draw_topline()
	if greenhouse:
		_draw_greenhouse_labels()
	else:
		_draw_orbit_labels()
		draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
		_draw_readings()


func _draw_topline() -> void:
	var caption := "SERA SİSTEMİ  /  ARIZA KAYDI" if greenhouse and not repaired else "SERA SİSTEMİ  /  NORMAL AKIŞ" if greenhouse else "ORBITAL GÖZLEMEVİ  /  GÜNEŞ SİSTEMİ"
	_label(caption, Vector2(26, 34), 13, AQUA if repaired else MUTED)
	var status := "Kuzey ve güney yarımküre ölçüm noktaları" if not greenhouse else "Güney istasyonunda sera sıcaklığı yükseliyor" if not repaired else "Güney istasyonu havalandırması yeniden açık"
	_label(status, Vector2(26, 59), 15, INK)


func _draw_orbit_labels() -> void:
	_center_label("21 HAZİRAN", Vector2(132, 87), 13, AQUA if not december else MUTED)
	_center_label("21 ARALIK", Vector2(588, 87), 13, AQUA if december else MUTED)
	_center_label("Eksen yönü yörünge boyunca sabit", Vector2(360, 106), 13, MUTED)
	_center_label("İki konum Güneş'e eşit uzaklıkta", Vector2(360, 126), 13, MUTED)
	var badge := "EKSEN EĞİMİ  %s°" % _decimal(tilt)
	_draw_pill(badge, Vector2(248, 148), AQUA)


func _draw_greenhouse_labels() -> void:
	_draw_pill("GÜNEY SERASI", Vector2(26, 82), AQUA if repaired else GOLD)
	var warning := "Havalandırma açık" if repaired else "Havalandırma kapalı  ·  ısı birikiyor"
	_label(warning, Vector2(26, 109), 16, AQUA if repaired else UITheme.DANGER)
	var gauge := Rect2(220, 455, 278, 7)
	draw_rect(gauge, Color(UITheme.EDGE_STRONG, 0.78))
	var recovery := smoothstep(0.0, 3.0, incident_time) if repaired else 0.0
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * lerpf(0.92, 0.24, recovery), gauge.size.y)), UITheme.DANGER if not repaired else AQUA)
	_center_label("SERA SICAKLIĞI YÜKSEK" if not repaired else "SICAKLIK NORMAL ARALIĞA DÖNÜYOR", Vector2(359, 484), 14, INK)


func _draw_readings() -> void:
	draw_rect(Rect2(18, 332, 684, 156), Color(UITheme.BG, 0.82))
	draw_rect(Rect2(18, 332, 684, 156), Color(UITheme.EDGE, 0.38), false, 1.0, true)
	_center_label("ÖĞLE GÜNEŞİ  ·  EKVATORA EŞİT UZAKLIK", Vector2(360, 356), 13, MUTED)
	_draw_reading(Vector2(36, 370), 40.0, "40° KUZEY", AQUA)
	_draw_reading(Vector2(382, 370), -40.0, "40° GÜNEY", GOLD)


func _draw_reading(origin: Vector2, latitude: float, title: String, color: Color) -> void:
	var sample := Model.sample(latitude, december, tilt)
	var angle := deg_to_rad(sample.x)
	var daylight_fraction := sample.y / 24.0
	draw_circle(origin + Vector2(32, 52), 23.0, Color(color, 0.11), true, -1.0, true)
	draw_arc(origin + Vector2(32, 52), 23.0, PI, PI + TAU * daylight_fraction, 42, color, 3.0, true)
	draw_line(origin + Vector2(9, 52), origin + Vector2(55, 52), UITheme.MUTED, 1.0, true)
	draw_line(origin + Vector2(32, 29), origin + Vector2(32, 75), UITheme.MUTED, 1.0, true)
	var ray_end := origin + Vector2(32, 52) + Vector2(-cos(angle), -sin(angle)) * 25.0
	draw_line(origin + Vector2(32, 52), ray_end, color, 2.4, true)
	if guides_visible:
		draw_line(ray_end, ray_end + Vector2(7.0, 3.0), color, 1.8, true)
		draw_line(ray_end, ray_end + Vector2(3.0, 7.0), color, 1.8, true)
	_label(title, origin + Vector2(68, 14), 13, color)
	_label("%s° ışın açısı" % _decimal(sample.x), origin + Vector2(68, 39), 15, INK)
	_label("%s saat gündüz" % _decimal(sample.y), origin + Vector2(68, 62), 15, INK)
	_label("%s yüzey izi" % ("dar" if sample.z > 0.75 else "geniş"), origin + Vector2(224, 62), 13, MUTED)
	if guides_visible:
		_label("R  ·  ışın açısı", origin + Vector2(224, 14), 12, AQUA)
	draw_rect(Rect2(origin + Vector2(68, 80), Vector2(230, 3)), UITheme.EDGE)
	draw_rect(Rect2(origin + Vector2(68, 80), Vector2(230.0 * sample.y / 24.0, 3)), color)


func _draw_pill(value: String, point: Vector2, color: Color) -> void:
	var width := _draw_font().get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 24.0
	draw_rect(Rect2(point, Vector2(width, 25)), Color(color, 0.13))
	draw_rect(Rect2(point, Vector2(width, 25)), Color(color, 0.46), false, 1.0, true)
	_label(value, point + Vector2(12, 17), 12, color)


func _sphere(radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 48
	mesh.rings = 32
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _box(extents: Vector3, color: Color, roughness: float, metallic: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = extents
	instance.mesh = mesh
	instance.material_override = _material(color, roughness, metallic, 0.08)
	return instance


func _cylinder(radius: float, height: float, color: Color, roughness: float, metallic: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	instance.mesh = mesh
	instance.material_override = _material(color, roughness, metallic, 0.08)
	return instance


func _beam(from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var beam := _cylinder(radius, from.distance_to(to), color, 0.42, 0.34)
	beam.position = (from + to) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return beam


func _material(color: Color, roughness: float, metallic: float, specular: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive_material(color: Color, strength: float) -> StandardMaterial3D:
	var material := _material(color, 0.3, 0.0, 0.0)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = strength
	return material


func _label(value: String, point: Vector2, font_size: int, color: Color) -> void:
	draw_string(_draw_font(), point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _center_label(value: String, point: Vector2, font_size: int, color: Color) -> void:
	var width := _draw_font().get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_label(value, point - Vector2(width / 2.0, 0), font_size, color)


func _draw_font() -> Font:
	var project_theme := get_tree().root.theme
	if project_theme != null and project_theme.default_font != null:
		return project_theme.default_font
	return UITheme.build().default_font


func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")
