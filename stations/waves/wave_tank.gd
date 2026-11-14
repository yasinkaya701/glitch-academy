extends Node3D
## Physical-scale 3D tank for the two-source interference model.

const Wave = preload("res://stations/waves/wave_sim.gd")
const SURFACE = preload("res://stations/waves/wave_field.gdshader")
const TANK_WIDTH := 8.0
const TANK_DEPTH := 5.6
const FIELD_CM := Vector2(40.0, 28.0)
const AQUA := Color("#69dfd3")
const AMBER := Color("#f2ac64")
const METAL := Color("#698397")

var frequency := 4.0
var two_sources := true
var faulty_display := false

var _water_material: ShaderMaterial
var _source_two: Node3D
var _beacon_a: MeshInstance3D
var _beacon_b: MeshInstance3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _clock := 0.0
var _applied_frequency := -1.0
var _applied_two_sources := false
var _applied_faulty := false


func _ready() -> void:
	_build_tank()
	_build_sources()
	_build_sensors()


func set_wave_state(next_frequency: float, has_two_sources: bool, is_faulty: bool) -> void:
	frequency = next_frequency
	two_sources = has_two_sources
	faulty_display = is_faulty
	if not is_node_ready():
		return
	if is_equal_approx(frequency, _applied_frequency) and two_sources == _applied_two_sources and faulty_display == _applied_faulty:
		return
	_applied_frequency = frequency
	_applied_two_sources = two_sources
	_applied_faulty = faulty_display
	_update_surface()


func _process(delta: float) -> void:
	_clock += delta
	if _water_material:
		_water_material.set_shader_parameter("t", _clock)
	if _beacon_a:
		_beacon_a.scale.y = 0.94 + 0.06 * sin(_clock * 2.2)
	if _beacon_b:
		_beacon_b.scale.y = 0.94 + 0.06 * sin(_clock * 2.2 + PI)


func _build_tank() -> void:
	var base_material := _material(Color("#263d50"), 0.7, 0.34)
	var lip_material := _material(Color("#7894a8"), 0.36, 0.5)
	var water_material := _material(Color("#0d3140"), 0.25, 0.18)
	_box("TankChassis", Vector3(0, -0.18, 0), Vector3(TANK_WIDTH + 0.5, 0.32, TANK_DEPTH + 0.5), base_material)
	_box("TankShadowLine", Vector3(0, -0.35, 0), Vector3(TANK_WIDTH + 0.72, 0.07, TANK_DEPTH + 0.72), water_material)
	_box("WaterBed", Vector3(0, 0.01, 0), Vector3(TANK_WIDTH, 0.12, TANK_DEPTH), water_material)
	# Rigid rim makes the shallow water surface read as a purpose-built lab tank.
	_box("RimNorth", Vector3(0, 0.17, -TANK_DEPTH * 0.5 - 0.08), Vector3(TANK_WIDTH + 0.2, 0.16, 0.16), lip_material)
	_box("RimSouth", Vector3(0, 0.17, TANK_DEPTH * 0.5 + 0.08), Vector3(TANK_WIDTH + 0.2, 0.16, 0.16), lip_material)
	_box("RimWest", Vector3(-TANK_WIDTH * 0.5 - 0.08, 0.17, 0), Vector3(0.16, 0.16, TANK_DEPTH), lip_material)
	_box("RimEast", Vector3(TANK_WIDTH * 0.5 + 0.08, 0.17, 0), Vector3(0.16, 0.16, TANK_DEPTH), lip_material)
	_add_measure_ticks()
	var plane := PlaneMesh.new()
	plane.size = Vector2(TANK_WIDTH, TANK_DEPTH)
	plane.subdivide_width = 96
	plane.subdivide_depth = 68
	_water_material = ShaderMaterial.new()
	_water_material.shader = SURFACE
	_water_material.set_shader_parameter("field_cm", FIELD_CM)
	_water_material.set_shader_parameter("s1_cm", Wave.S1)
	_water_material.set_shader_parameter("s2_cm", Wave.S2)
	var water := MeshInstance3D.new()
	water.name = "WaveSurface"
	water.mesh = plane
	water.position.y = 0.16
	water.material_override = _water_material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _add_measure_ticks() -> void:
	var tick_mat := _material(Color("#a4bac3"), 0.48, 0.12)
	for i in 11:
		var x := -TANK_WIDTH * 0.5 + TANK_WIDTH * float(i) / 10.0
		_box("XTick%02d" % i, Vector3(x, 0.27, TANK_DEPTH * 0.5 + 0.04), Vector3(0.018, 0.025, 0.08 if i % 5 == 0 else 0.045), tick_mat)
	for i in 8:
		var z := -TANK_DEPTH * 0.5 + TANK_DEPTH * float(i) / 7.0
		_box("ZTick%02d" % i, Vector3(TANK_WIDTH * 0.5 + 0.04, 0.27, z), Vector3(0.08 if i % 2 == 0 else 0.045, 0.025, 0.018), tick_mat)
	_label("ScaleTitle", "DALGA HAVUZU  ·  40 × 28 cm", Vector3(0, 0.42, -TANK_DEPTH * 0.5 - 0.12), Color("#dbe8ed"), 28)


func _build_sources() -> void:
	var first := _make_source("SourceOne", Wave.S1, "KAYNAK 1")
	_source_two = _make_source("SourceTwo", Wave.S2, "KAYNAK 2")
	first.name = "SourceOne"
	_source_two.name = "SourceTwo"


func _make_source(node_name: String, point: Vector2, title: String) -> Node3D:
	var source := Node3D.new()
	source.name = node_name
	source.position = _tank_point(point, 0.22)
	add_child(source)
	var base := _cylinder("EmitterBase", Vector3.ZERO, 0.22, 0.1, _material(Color("#d28a49"), 0.36, 0.54))
	source.add_child(base)
	var body := _cylinder("EmitterBody", Vector3(0, 0.12, 0), 0.135, 0.22, _material(Color("#f0b26a"), 0.28, 0.62))
	source.add_child(body)
	var crown := _sphere("EmitterHead", Vector3(0, 0.25, 0), Vector3(0.09, 0.065, 0.09), _material(Color("#fff0bd"), 0.2, 0.7, Color("#f1b45e"), 0.65))
	source.add_child(crown)
	var label := _label("SourceLabel", title, Vector3(0, 0.48, 0), Color("#ffd99e"), 21)
	source.add_child(label)
	return source


func _build_sensors() -> void:
	_beacon_a = _make_sensor("SensitiveSensorA", Wave.SENSOR_A, "A  ·  HASSAS", true)
	_ring_a = _make_sensor_ring("PathRingA", Wave.SENSOR_A)
	_beacon_b = _make_sensor("DataReceiverB", Wave.SENSOR_B, "B  ·  ALICI", false)
	_ring_b = _make_sensor_ring("PathRingB", Wave.SENSOR_B)
	_update_sensor_indicators()


func _make_sensor(node_name: String, point: Vector2, title: String, is_a: bool) -> MeshInstance3D:
	var sensor := Node3D.new()
	sensor.name = node_name
	sensor.position = _tank_point(point, 0.22)
	add_child(sensor)
	var base := _cylinder("SensorFoot", Vector3.ZERO, 0.19, 0.1, _material(Color("#496777"), 0.4, 0.35))
	sensor.add_child(base)
	var post := _cylinder("SensorPost", Vector3(0, 0.21, 0), 0.065, 0.34, _material(Color("#a9c3cd"), 0.35, 0.45))
	sensor.add_child(post)
	var lamp := _sphere("SensorBeacon", Vector3(0, 0.43, 0), Vector3(0.12, 0.12, 0.12), _material(Color("#f2ba66"), 0.24, 0.58, Color("#f2ba66"), 0.25))
	sensor.add_child(lamp)
	var tag := _label("SensorLabel", title, Vector3(0, 0.74, 0), Color("#e6f2f4"), 20)
	sensor.add_child(tag)
	return lamp


func _make_sensor_ring(node_name: String, point: Vector2) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	ring.name = node_name
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.15
	mesh.outer_radius = 0.19
	mesh.rings = 32
	mesh.ring_segments = 6
	ring.mesh = mesh
	ring.position = _tank_point(point, 0.175)
	ring.material_override = _material(Color("#e7bf73"), 0.25, 0.22, Color("#e7bf73"), 0.2)
	add_child(ring)
	return ring


func _update_surface() -> void:
	if not _water_material:
		return
	_water_material.set_shader_parameter("k", TAU / Wave.wavelength(frequency))
	_water_material.set_shader_parameter("omega", TAU * frequency)
	_water_material.set_shader_parameter("two", 1.0 if two_sources else 0.0)
	_water_material.set_shader_parameter("t", _clock)
	if _source_two:
		_source_two.visible = two_sources
	_update_sensor_indicators()


func _update_sensor_indicators() -> void:
	if not _beacon_a or not _beacon_b:
		return
	var amplitude_a := Wave.amplitude(Wave.SENSOR_A, frequency, two_sources)
	var amplitude_b := Wave.amplitude(Wave.SENSOR_B, frequency, two_sources)
	var color_a := Color("#ef7168") if amplitude_a > 1.6 else (AQUA if amplitude_a <= 0.3 else AMBER)
	var color_b := AQUA if amplitude_b >= 1.7 else AMBER
	if not two_sources:
		color_a = AMBER
		color_b = AMBER
	if faulty_display:
		color_a = Color("#ef7168")
		color_b = Color("#ef7168")
	_apply_beacon_color(_beacon_a, color_a)
	_apply_beacon_color(_beacon_b, color_b)
	_ring_a.material_override = _material(color_a, 0.22, 0.25, color_a, 0.14)
	_ring_b.material_override = _material(color_b, 0.22, 0.25, color_b, 0.14)


func _apply_beacon_color(beacon: MeshInstance3D, color: Color) -> void:
	var material := _material(color, 0.22, 0.58, color, 0.42)
	beacon.material_override = material


func _tank_point(point: Vector2, y: float) -> Vector3:
	return Vector3((point.x / 40.0 - 0.5) * TANK_WIDTH, y, (point.y / 28.0 - 0.5) * TANK_DEPTH)


func _box(node_name: String, position: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = dimensions
	var item := MeshInstance3D.new()
	item.name = node_name
	item.mesh = box
	item.position = position
	item.material_override = material
	add_child(item)
	return item


func _cylinder(node_name: String, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 24
	var item := MeshInstance3D.new()
	item.name = node_name
	item.mesh = cylinder
	item.position = position
	item.material_override = material
	return item


func _sphere(node_name: String, position: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 24
	sphere.rings = 16
	var item := MeshInstance3D.new()
	item.name = node_name
	item.mesh = sphere
	item.position = position
	item.scale = scale
	item.material_override = material
	return item


func _label(node_name: String, value: String, position: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = position
	label.font_size = font_size
	label.pixel_size = 0.007
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("#06121c")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label


func _material(color: Color, metallic: float, roughness: float, emissive: Color = Color.BLACK, emission_energy := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	if emission_energy > 0.0:
		result.emission_enabled = true
		result.emission = emissive
		result.emission_energy_multiplier = emission_energy
	return result
