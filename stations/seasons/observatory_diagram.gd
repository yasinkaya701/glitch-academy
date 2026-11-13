extends Control
## Purpose-built orbital observatory model for the seasons lesson.
## The lesson's measured values still come from seasons_model.gd; this script only
## makes the geometry and the greenhouse failure legible in 3D.

const Model = preload("res://stations/seasons/seasons_model.gd")
const INK := Color("e6f1ef")
const MUTED := Color("a3b9bf")
const AQUA := Color("77d2bd")
const GOLD := Color("f0aa70")
const ORBIT := Color("557386")

var december := false
var tilt := Model.AXIAL_TILT
var greenhouse := true
var repaired := false
var incident_time := 0.0

var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var earths: Array[Node3D] = []
var earth_surfaces: Array[MeshInstance3D] = []
var summer_markers: Array[MeshInstance3D] = []
var winter_markers: Array[MeshInstance3D] = []
var solar_spheres: Array[MeshInstance3D] = []
var solar_light: OmniLight3D
var orbit_material: StandardMaterial3D
var greenhouse_root: Node3D
var greenhouse_glass: MeshInstance3D
var greenhouse_vent: Node3D
var plants: Array[Node3D] = []
var readout := ""


func _ready() -> void:
	clip_contents = true
	var viewport_box := SubViewportContainer.new()
	viewport_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_box.stretch = true
	viewport_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_box)
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_box.add_child(viewport)
	world = Node3D.new()
	world.name = "ObservatoryWorld"
	viewport.add_child(world)
	_build_world()


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
	_build_greenhouse()


func _build_orbit() -> void:
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
	world.add_child(path)
	# Four brass station pins mark the solstices and equinoxes on the orbit.
	for i in 4:
		var angle := TAU * float(i) / 4.0
		var pin := _sphere(0.055, _material(Color("f1bd7a"), 0.34, 0.35, 0.18))
		pin.position = Vector3(cos(angle) * 3.78, 1.58, sin(angle) * 1.97)
		pin.name = "SeasonalOrbitMarker_%02d" % i
		world.add_child(pin)
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
	world.add_child(deck)
	for radius in [4.2, 4.45]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.008
		torus.outer_radius = radius + 0.008
		ring.mesh = torus
		ring.position.y = 0.012
		ring.material_override = _material(Color("345467"), 0.4, 0.0, 0.35)
		world.add_child(ring)


func _build_sun() -> void:
	var sun := _sphere(0.66, _material(Color("ffd98c"), 0.24, 0.0, 0.12))
	sun.name = "SunCore"
	sun.position = Vector3(0.0, 1.55, 0.0)
	var sun_mat := sun.material_override as StandardMaterial3D
	sun_mat.emission_enabled = true
	sun_mat.emission = Color("ff9d48")
	sun_mat.emission_energy_multiplier = 3.5
	world.add_child(sun)
	for radius in [0.78, 0.9]:
		var corona := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		corona.mesh = mesh
		var material := _material(Color("ffb45f", 0.15 if radius < 0.85 else 0.065), 0.45, 0.0, 0.0)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = Color("fa8e36")
		material.emission_energy_multiplier = 0.45
		corona.material_override = material
		corona.position = sun.position
		corona.name = "SolarCorona_%.2f" % radius
		world.add_child(corona)
	solar_light = OmniLight3D.new()
	solar_light.position = sun.position
	solar_light.light_color = Color("ffc875")
	solar_light.light_energy = 2.0
	solar_light.omni_range = 11.0
	solar_light.omni_attenuation = 1.1
	world.add_child(solar_light)


func _build_earth(position: Vector3, marker: String, winter_side: bool) -> void:
	var pivot := Node3D.new()
	pivot.position = position
	pivot.rotation.z = -deg_to_rad(Model.AXIAL_TILT)
	pivot.name = "AxialTiltRig_%s" % marker.replace(" ", "_")
	world.add_child(pivot)
	earths.append(pivot)
	var globe := _sphere(0.77, _material(Color("174763"), 0.3, 0.18, 0.12))
	globe.name = "BlueOceanGlobe"
	pivot.add_child(globe)
	earth_surfaces.append(globe)
	# Raised stylized continental plates on the camera-facing hemisphere.
	var land_mat := _material(Color("77a877"), 0.68, 0.0, 0.0)
	for spec in [
		Vector3(-0.24, 0.32, 0.63), Vector3(-0.35, 0.13, 0.65), Vector3(-0.14, -0.02, 0.7),
		Vector3(0.12, 0.26, 0.66), Vector3(0.29, 0.12, 0.65), Vector3(0.23, -0.13, 0.69),
		Vector3(-0.16, -0.3, 0.62), Vector3(0.08, -0.39, 0.62), Vector3(0.38, -0.31, 0.53),
	]:
		var plate := _sphere(0.15, land_mat)
		plate.position = spec
		plate.scale = Vector3(1.0, 1.18, 0.24)
		plate.name = "RaisedContinentalPlate"
		pivot.add_child(plate)
	# Polar caps and a metallic axial rod move with the globe's 23.4-degree axis.
	for sign in [-1.0, 1.0]:
		var cap := _sphere(0.105, _material(Color("d7e7df"), 0.44, 0.0, 0.0))
		cap.position.y = sign * 0.74
		cap.name = "PolarIceCap"
		pivot.add_child(cap)
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
	greenhouse_root.name = "SouthGreenhouseFailureSet"
	world.add_child(greenhouse_root)
	# Foundation and raised steel base.
	var slab := _box(Vector3(5.8, 0.18, 3.2), Color("263943"), 0.65, 0.18)
	slab.position = Vector3(0.0, 0.05, 0.0)
	greenhouse_root.add_child(slab)
	var soil := _box(Vector3(5.0, 0.17, 2.35), Color("765b3d"), 0.92, 0.0)
	soil.position = Vector3(0.0, 0.22, 0.0)
	greenhouse_root.add_child(soil)
	# Glass panes are separate so they can glow under the stuck-vent heat warning.
	greenhouse_glass = _box(Vector3(5.05, 2.35, 2.5), Color("a9ced0", 0.14), 0.18, 0.0)
	greenhouse_glass.position = Vector3(0.0, 1.5, 0.0)
	greenhouse_glass.name = "TemperedGlassEnclosure"
	var glass_material := greenhouse_glass.material_override as StandardMaterial3D
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	greenhouse_root.add_child(greenhouse_glass)
	for x in [-2.58, -1.7, -0.85, 0.0, 0.85, 1.7, 2.58]:
		var post := _cylinder(0.042, 2.7, Color("97b5b6"), 0.42, 0.35)
		post.position = Vector3(x, 1.42, 0.0)
		greenhouse_root.add_child(post)
	for z in [-1.28, 1.28]:
		var beam := _box(Vector3(5.3, 0.08, 0.08), Color("a3bfc0"), 0.4, 0.25)
		beam.position = Vector3(0.0, 2.64, z)
		greenhouse_root.add_child(beam)
	# Gabled roof beams; each is a visible part of the enclosure frame.
	for x in [-2.6, 0.0, 2.6]:
		for side in [-1.0, 1.0]:
			var roof := _beam(Vector3(x, 2.65, 0.0), Vector3(x, 3.42, side * 1.32), 0.055, Color("b6c7bf"))
			greenhouse_root.add_child(roof)
	var ridge := _beam(Vector3(-2.7, 3.42, 0.0), Vector3(2.7, 3.42, 0.0), 0.055, Color("b6c7bf"))
	greenhouse_root.add_child(ridge)
	greenhouse_vent = Node3D.new()
	greenhouse_vent.position = Vector3(0.0, 3.43, 0.0)
	greenhouse_vent.name = "RoofVentHinge"
	greenhouse_root.add_child(greenhouse_vent)
	var vent := _box(Vector3(1.5, 0.08, 0.8), Color("d0dbd3"), 0.4, 0.35)
	vent.position = Vector3(0.0, 0.0, 0.4)
	vent.name = "RoofVentPanel"
	greenhouse_vent.add_child(vent)
	# Six individually articulated plants are the visible casualty of the bad warning.
	for i in 6:
		var plant := Node3D.new()
		plant.position = Vector3(-2.1 + float(i) * 0.84, 0.34, 0.0)
		plant.name = "GreenhousePlant_%02d" % i
		greenhouse_root.add_child(plant)
		plants.append(plant)
		var stem := _cylinder(0.022, 0.54 + float(i % 3) * 0.12, Color("79ae73"), 0.75, 0.0)
		stem.position.y = 0.36
		plant.add_child(stem)
		for side in [-1.0, 1.0]:
			var leaf := _sphere(0.16, _material(Color("5cb986"), 0.68, 0.0, 0.0))
			leaf.scale = Vector3(1.45, 0.38, 0.65)
			leaf.position = Vector3(side * 0.16, 0.5 + float(i % 3) * 0.04, 0.0)
			leaf.rotation.z = side * -0.4
			plant.add_child(leaf)
		var planter := _box(Vector3(0.62, 0.28, 0.7), Color("9a7754"), 0.92, 0.0)
		planter.position.y = 0.21
		plant.add_child(planter)
	# Inspection lamp and simple analog thermometer communicate the failure without text clutter.
	var lamp := _sphere(0.14, _emissive_material(Color("ff8b62"), 1.6))
	lamp.position = Vector3(2.95, 2.85, 0.0)
	lamp.name = "HeatAlarmLamp"
	greenhouse_root.add_child(lamp)
	var thermometer := _cylinder(0.05, 0.92, Color("e1e7df"), 0.3, 0.2)
	thermometer.position = Vector3(2.95, 1.55, 0.45)
	greenhouse_root.add_child(thermometer)
	var mercury := _cylinder(0.022, 0.58, Color("ff8061"), 0.28, 0.0)
	mercury.position = Vector3(2.95, 1.62, 0.49)
	mercury.name = "ThermometerMercury"
	greenhouse_root.add_child(mercury)


func _process(_delta: float) -> void:
	if not is_instance_valid(world):
		return
	for node in [world.get_node_or_null("EclipticOrbit"), world.get_node_or_null("CalibrationDeck")]:
		if node != null:
			node.visible = not greenhouse
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
	greenhouse_root.visible = greenhouse
	if greenhouse_root.visible:
		var recovery := smoothstep(0.0, 3.0, incident_time) if repaired else 0.0
		var heat := (1.0 - exp(-maxf(incident_time, 0.0) * 0.55)) * (1.0 - recovery)
		greenhouse_vent.rotation.x = lerpf(0.0, -0.85, recovery)
		for i in plants.size():
			plants[i].rotation.z = lerpf(0.0, 0.42 + float(i % 2) * 0.14, heat)
		if solar_light != null:
			solar_light.light_energy = 1.25 + heat * 0.85
		var glass_mat := greenhouse_glass.material_override as StandardMaterial3D
		glass_mat.albedo_color = Color("ff9771", 0.10 + heat * 0.10) if not repaired else Color("9bd7c4", 0.08)
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
	_center_label("Eksenin yönü yörünge boyunca sabit", Vector2(360, 106), 13, MUTED)
	var badge := "EKEN EĞİKLİĞİ  %s°" % _decimal(tilt)
	_draw_pill(badge, Vector2(248, 121), AQUA)


func _draw_greenhouse_labels() -> void:
	_draw_pill("GÜNEY SERASI", Vector2(26, 82), AQUA if repaired else GOLD)
	var warning := "Havalandırma açık" if repaired else "Havalandırma kapalı  ·  ısı birikiyor"
	_label(warning, Vector2(26, 109), 16, AQUA if repaired else Color("ff9b7e"))
	var gauge := Rect2(220, 455, 278, 7)
	draw_rect(gauge, Color("59707b", 0.78))
	var recovery := smoothstep(0.0, 3.0, incident_time) if repaired else 0.0
	var heat := (1.0 - exp(-maxf(incident_time, 0.0) * 0.55)) * (1.0 - recovery)
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * lerpf(0.92, 0.24, recovery), gauge.size.y)), Color("ff906d") if not repaired else AQUA)
	_center_label("SERA SICAKLIĞI YÜKSEK" if not repaired else "SICAKLIK NORMAL ARALIĞA DÖNÜYOR", Vector2(359, 484), 14, INK)


func _draw_readings() -> void:
	draw_rect(Rect2(18, 332, 684, 156), Color("091522", 0.82))
	draw_rect(Rect2(18, 332, 684, 156), Color("7192a0", 0.38), false, 1.0, true)
	_center_label("ÖĞLE GÜNEŞİ  ·  EKVATORA EŞİT UZAKLIK", Vector2(360, 356), 13, MUTED)
	_draw_reading(Vector2(36, 370), 40.0, "40° KUZEY", AQUA)
	_draw_reading(Vector2(382, 370), -40.0, "40° GÜNEY", GOLD)


func _draw_reading(origin: Vector2, latitude: float, title: String, color: Color) -> void:
	var sample := Model.sample(latitude, december, tilt)
	var angle := deg_to_rad(sample.x)
	var daylight_fraction := sample.y / 24.0
	draw_circle(origin + Vector2(32, 52), 23.0, Color(color, 0.11), true, -1.0, true)
	draw_arc(origin + Vector2(32, 52), 23.0, PI, PI + TAU * daylight_fraction, 42, color, 3.0, true)
	draw_line(origin + Vector2(9, 52), origin + Vector2(55, 52), Color("7e9aa7"), 1.0, true)
	draw_line(origin + Vector2(32, 29), origin + Vector2(32, 75), Color("7e9aa7"), 1.0, true)
	var ray_end := origin + Vector2(32, 52) + Vector2(-cos(angle), -sin(angle)) * 25.0
	draw_line(origin + Vector2(32, 52), ray_end, color, 2.4, true)
	_label(title, origin + Vector2(68, 14), 13, color)
	_label("%s° ışın açısı" % _decimal(sample.x), origin + Vector2(68, 39), 15, INK)
	_label("%s saat gündüz" % _decimal(sample.y), origin + Vector2(68, 62), 15, INK)
	_label("%s yüzey izi" % ("dar" if sample.z > 0.75 else "geniş"), origin + Vector2(224, 62), 13, MUTED)
	draw_rect(Rect2(origin + Vector2(68, 80), Vector2(230, 3)), Color("405767"))
	draw_rect(Rect2(origin + Vector2(68, 80), Vector2(230.0 * sample.y / 24.0, 3)), color)


func _draw_pill(value: String, point: Vector2, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 24.0
	draw_rect(Rect2(point, Vector2(width, 25)), Color(color, 0.13))
	draw_rect(Rect2(point, Vector2(width, 25)), Color(color, 0.46), false, 1.0, true)
	_label(value, point + Vector2(12, 17), 12, color)


func _sphere(radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 20
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
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _center_label(value: String, point: Vector2, font_size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_label(value, point - Vector2(width / 2.0, 0), font_size, color)


func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")
