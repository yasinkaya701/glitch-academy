extends Node3D
## Small, procedural observatory model. Date and tilt controls update the globe,
## its fixed-in-space axis, incident greenhouse, and recovery animation.

const TILT := 23.44
const EARTH_RADIUS := 0.82
var december := false
var tilt_degrees := TILT
var greenhouse := false
var repaired := false
var incident_time := 0.0
var sun: MeshInstance3D
var earth: Node3D
var axis: Node3D
var greenhouse_node: Node3D
var light: DirectionalLight3D
var _globe_material: StandardMaterial3D
var _glass: MeshInstance3D
var _vent: Node3D
var _rays: Node3D
var _june_label: Label3D
var _december_label: Label3D
var _globe_mesh: MeshInstance3D


func _ready() -> void:
	_build_scene()
	_apply_state()


func set_state(is_december: bool, axial_tilt: float, show_greenhouse: bool, is_repaired: bool, time: float) -> void:
	december = is_december
	tilt_degrees = axial_tilt
	greenhouse = show_greenhouse
	repaired = is_repaired
	incident_time = time
	_apply_state()


func _process(_delta: float) -> void:
	if greenhouse_node != null:
		_apply_state()


func _apply_state() -> void:
	if earth == null:
		return
	greenhouse_node.visible = greenhouse
	earth.visible = not greenhouse
	axis.visible = not greenhouse
	sun.visible = not greenhouse
	_rays.visible = not greenhouse
	_june_label.visible = not greenhouse
	_december_label.visible = not greenhouse
	if greenhouse:
		var recovery := smoothstep(0.0, 2.0, incident_time) if repaired else 0.0
		var heat := 1.0 - recovery if repaired else 1.0 - exp(-incident_time * 0.55)
		_glass.material_override.albedo_color = Color(1.0, 0.45 + 0.3 * heat, 0.3, 0.22 + 0.17 * heat)
		_vent.rotation.z = lerpf(0.0, deg_to_rad(-30.0), recovery)
		for plant in greenhouse_node.get_node("Plants").get_children():
			plant.rotation.z = sin(float(plant.get_index()) * 1.7) * 0.05 * heat
		return
	var orbit_angle := 0.0 if december else PI
	earth.position = Vector3(cos(orbit_angle) * 2.65, 0.0, sin(orbit_angle) * 1.45)
	# The axle points in one fixed world direction at both orbital positions.
	var axis_dir := Vector3(sin(deg_to_rad(tilt_degrees)), cos(deg_to_rad(tilt_degrees)), 0.0).normalized()
	# Keep the pole fixed in world space: rotate the globe and all its surface marks,
	# then draw the pole through the globe's local origin exactly once.
	earth.quaternion = Quaternion(Vector3.UP, axis_dir)
	axis.position = Vector3.ZERO
	axis.quaternion = Quaternion.IDENTITY
	# Light arrives from the sun at the selected Earth position; opposite the
	# Earth's radial position means the illuminated side faces the star.
	var toward_sun := -earth.position.normalized()
	light.rotation = Vector3.ZERO
	light.look_at(toward_sun, Vector3.UP)
	_globe_material.albedo_color = Color("567d6b")
	_june_label.modulate = Color("dfae63") if not december else Color("b1ac9e")
	_december_label.modulate = Color("dfae63") if december else Color("b1ac9e")
	_rays.rotation.y = 0.0


func _build_scene() -> void:
	var star := SphereMesh.new()
	star.radius = 0.45
	star.height = 0.90
	sun = _mesh(star, Color("dfae63"), "Sun")
	sun.position = Vector3.ZERO
	var corona := _torus(0.66, 0.018, Color("b77c3f"))
	corona.name = "SolarCorona"
	corona.rotation.x = PI / 2.0
	sun.add_child(corona)
	var glow := OmniLight3D.new()
	glow.light_color = Color("dfae63")
	glow.light_energy = 1.2
	glow.omni_range = 10.0
	sun.add_child(glow)
	light = DirectionalLight3D.new()
	light.light_energy = 1.5
	light.rotation_degrees = Vector3(-30, -45, 0)
	add_child(light)
	_build_observatory()
	earth = Node3D.new()
	earth.name = "Earth"
	add_child(earth)
	var globe := SphereMesh.new()
	globe.radius = EARTH_RADIUS
	globe.height = EARTH_RADIUS * 2.0
	_globe_material = StandardMaterial3D.new()
	_globe_material.albedo_color = Color("286987")
	_globe_material.roughness = 0.8
	_globe_mesh = MeshInstance3D.new()
	_globe_mesh.name = "Globe"
	_globe_mesh.mesh = globe
	_globe_mesh.material_override = _globe_material
	earth.add_child(_globe_mesh)
	var equator := _torus(0.84, 0.012, Color("e9e5db"))
	equator.name = "Equator"
	equator.rotation_degrees.x = 90
	earth.add_child(equator)
	for sign in [-1.0, 1.0]:
		var latitude := _torus(0.72, 0.014, Color("8fbea0") if sign > 0 else Color("dfae63"))
		latitude.name = "Latitude_%s" % str(sign)
		latitude.position.y = sign * 0.39
		latitude.scale = Vector3(0.83, 1.0, 0.83)
		earth.add_child(latitude)
	axis = Node3D.new()
	axis.name = "TiltAxis"
	earth.add_child(axis)
	var pole_line := _cylinder(0.018, 2.55, Color("e9e5db"))
	pole_line.position.y = 0.0
	axis.add_child(pole_line)
	for sign in [-1.0, 1.0]:
		var pole := _sphere(0.075, Color("e9e5db"))
		pole.position.y = sign * 1.28
		axis.add_child(pole)
	# Two half-orbit rails retain the visible seasonal pair as the active date changes.
	var orbit := _torus(3.0, 0.018, Color("3b3d35"))
	orbit.name = "Orbit"
	orbit.scale = Vector3(1.0, 1.0, 0.57)
	add_child(orbit)
	_rays = Node3D.new()
	_rays.name = "SolarRays"
	add_child(_rays)
	_build_solar_rays()
	_june_label = _date_label("21 HAZİRAN  ·  KUZEY YAZI", Color("dfae63"))
	_june_label.position = Vector3(-2.65, -1.17, 0)
	add_child(_june_label)
	_december_label = _date_label("21 ARALIK  ·  KUZEY KIŞI", Color("b1ac9e"))
	_december_label.position = Vector3(2.65, -1.17, 0)
	add_child(_december_label)
	greenhouse_node = Node3D.new()
	greenhouse_node.name = "Greenhouse"
	add_child(greenhouse_node)
	_build_greenhouse()
	_apply_state()


func _build_observatory() -> void:
	var plinth := _cylinder(3.65, 0.16, Color("191a17"))
	plinth.name = "ObservatoryPlinth"
	plinth.position.y = -1.48
	add_child(plinth)
	var trim := _torus(3.56, 0.025, Color("8fbea0"))
	trim.name = "PlinthInlay"
	trim.rotation.x = PI / 2.0
	trim.position.y = -1.38
	add_child(trim)
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		var marker := _sphere(0.035, Color("b1ac9e"))
		marker.name = "OrbitMarker_%02d" % index
		marker.position = Vector3(cos(angle) * 3.0, -1.30, sin(angle) * 1.72)
		add_child(marker)
	for index in range(28):
		var azimuth := fposmod(float(index) * 2.39996, TAU)
		var elevation := 0.3 + float((index * 17) % 13) * 0.105
		var radius := 6.0 + float((index * 7) % 11) * 0.34
		var star := _sphere(0.018 + float(index % 3) * 0.009, Color("e9e5db"))
		star.name = "Star_%02d" % index
		star.position = Vector3(cos(azimuth) * radius, elevation * 2.4, sin(azimuth) * radius)
		add_child(star)
	var axis_tag := _date_label("EKEN YÖNÜ SABİT", Color("8fbea0"))
	axis_tag.position = Vector3(0, 2.05, -0.4)
	axis_tag.font_size = 32
	add_child(axis_tag)


func _build_solar_rays() -> void:
	for side in [-1.0, 1.0]:
		for index in range(3):
			var z := (float(index) - 1.0) * 0.34
			var ray := _cylinder(0.012, 1.85, Color("dfae63"))
			ray.name = "SunRay_%s_%d" % [str(side), index]
			ray.rotation.z = PI / 2.0
			ray.position = Vector3(side * 1.38, 0.0, z)
			_rays.add_child(ray)


func _date_label(value: String, tint: Color) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.font_size = 40
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint
	label.outline_size = 8
	label.outline_modulate = Color("10110f")
	return label


func _build_greenhouse() -> void:
	var floor := _box(Vector3(3.6, 0.12, 2.2), Color("253e49"), "Floor")
	floor.position = Vector3(0, -0.65, 0)
	greenhouse_node.add_child(floor)
	_glass = _box(Vector3(3.3, 1.7, 1.9), Color(1.0, 0.59, 0.38, 0.28), "GlassHouse")
	_glass.position.y = 0.25
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.59, 0.38, 0.3)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glass.material_override = glass_mat
	greenhouse_node.add_child(_glass)
	var roof := _box(Vector3(3.7, 0.12, 2.2), Color("9eb8bd"), "Roof")
	roof.position.y = 1.16
	greenhouse_node.add_child(roof)
	_vent = Node3D.new()
	_vent.name = "VentHinge"
	_vent.position = Vector3(0, 1.23, -0.3)
	greenhouse_node.add_child(_vent)
	var vent := _box(Vector3(1.1, 0.07, 0.55), Color("77d2bd"), "Vent")
	vent.position = Vector3(0, 0.0, 0.28)
	_vent.add_child(vent)
	var plants := Node3D.new()
	plants.name = "Plants"
	greenhouse_node.add_child(plants)
	for i in range(5):
		var stem := _cylinder(0.035, 0.62 + float(i % 2) * 0.16, Color("5cc6a2"))
		stem.position = Vector3(-1.25 + float(i) * 0.62, -0.25, 0)
		plants.add_child(stem)
		var crown := _sphere(0.2, Color("5cc6a2"))
		crown.position = stem.position + Vector3(0, 0.4, 0)
		plants.add_child(crown)
	var sun_disc := _sphere(0.33, Color("e89d50"))
	sun_disc.position = Vector3(2.8, 2.2, 0)
	greenhouse_node.add_child(sun_disc)


func _box(dimensions: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	return node


func _sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _mesh(mesh, color, "Sphere")


func _cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var node := _mesh(mesh, color, "Cylinder")
	return node


func _torus(radius: float, thickness: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	return _mesh(mesh, color, "Torus")


func _mesh(mesh: Mesh, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	node.material_override = mat
	return node
