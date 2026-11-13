extends Node3D

const PLANET_SHADER = preload("res://scenes/world/planet.gdshader")
const DECK_CENTER := Vector3(0, 0, 3.5)
const WINDOW_RADIUS := 15.0
const STATION_RADIUS := 11.4
const STATION_ANGLES := [-53.0, -33.0, -12.0, 12.0, 33.0, 53.0]
const JADE := Color(0.39, 0.85, 0.72)
const AMBER := Color(0.94, 0.57, 0.28)

@onready var _deck: Node3D = $Deck
@onready var _exterior: Node3D = $Exterior
@onready var _stations: Node3D = $Stations

var _operational_count := 0
var _alarm := 0.0
var _signal_materials: Array[StandardMaterial3D] = []
var _guide: StandardMaterial3D
var _planet: MeshInstance3D

var _structure := _surface(Color("#243341"), 0.37, 0.66)
var _slate := _surface(Color("#354956"), 0.29, 0.61)
var _decking := _surface(Color("#1e303d"), 0.29, 0.77)
var _insert := _surface(Color("#111e2b"), 0.28, 0.63)
var _trim := _surface(Color("#526674"), 0.56, 0.51)
var _screen := _surface(Color("#081720"), 0.15, 0.38)
var _mark := _surface(Color("#455560"), 0.18, 0.62)


func _ready() -> void:
	_guide = _signal(Color("#38786f"))
	_build_exterior()
	_build_deck()
	_build_window()
	_build_stations()
	_refresh_signals()


func _process(delta: float) -> void:
	_planet.rotate_y(delta * 0.007)


func set_operational_count(count: int) -> void:
	_operational_count = clampi(count, 0, STATION_ANGLES.size())
	_refresh_signals()


func set_alarm(strength: float) -> void:
	_alarm = clampf(strength, 0.0, 1.0)
	_refresh_signals()


func _refresh_signals() -> void:
	for index in _signal_materials.size():
		var material := _signal_materials[index]
		var operational := index < _operational_count
		var color := JADE if operational else AMBER
		material.albedo_color = color.darkened(0.20 if operational else 0.27)
		material.emission = color
		material.emission_energy_multiplier = 0.84 if operational else 0.50 + 0.62 * _alarm
	if _guide != null:
		_guide.emission = Color("#38786f").lerp(AMBER, _alarm * 0.46)
		_guide.emission_energy_multiplier = 0.61 + _alarm * 0.42


func _build_exterior() -> void:
	var planet_material := ShaderMaterial.new()
	planet_material.shader = PLANET_SHADER
	var sphere := SphereMesh.new()
	sphere.radius = 13.9
	sphere.height = sphere.radius * 2.0
	sphere.radial_segments = 80
	sphere.rings = 40
	_planet = _piece(_exterior, sphere, planet_material, Vector3(13.0, 8.0, -45.0))
	_planet.rotation_degrees = Vector3(-12, 18, 16)

	var moon_material := ShaderMaterial.new()
	moon_material.shader = PLANET_SHADER
	moon_material.set_shader_parameter("ocean_color", Color("#c1c0a5"))
	moon_material.set_shader_parameter("relief", 0.0)
	var moon := SphereMesh.new()
	moon.radius = 0.64
	moon.height = 1.28
	moon.radial_segments = 24
	moon.rings = 12
	_piece(_exterior, moon, moon_material, Vector3(-19.6, 12.4, -51.0))


func _build_deck() -> void:
	_box(_deck, Vector3(40, 0.32, 31), Vector3(0, -0.27, 4.0), _insert)
	_arc(_deck, 3.6, 15.2, -75, 75, 0.07, 0.11, _decking, 52)
	_arc(_deck, 9.68, 9.89, -66, 66, 0.136, 0.075, _insert, 48)
	_arc(_deck, 9.76, 9.79, -64, 64, 0.177, 0.018, _guide, 48)
	_arc(_deck, 11.97, 12.02, -65, 65, 0.134, 0.015, _trim, 48)
	_arc(_deck, 13.63, 13.68, -66, 66, 0.134, 0.015, _mark, 48)
	_arc(_deck, 14.09, 15.32, -69, 69, 0.27, 0.38, _structure, 48)
	_arc(_deck, 14.08, 14.16, -69, 69, 0.48, 0.075, _trim, 48)
	_arc(_deck, 14.47, 15.37, -70, 70, 0.45, 0.18, _slate, 48)
	_arc(_deck, 14.24, 14.29, -70, 70, 0.42, 0.035, _guide, 48)
	_arc(_deck, 7.94, 8.00, -76, 76, 0.134, 0.012, _mark, 48)
	_arc(_deck, 8.05, 8.07, -76, 76, 0.134, 0.012, _insert, 48)

	for angle in [-65.0, -43.0, -23.0, 0.0, 23.0, 43.0, 65.0]:
		_radial_box(_deck, 12.08, angle, 0.136, Vector3(0.027, 0.017, 4.35), _insert)

	for side in [-1.0, 1.0]:
		var approach := Vector3(side * 2.12, 0.011, 8.05)
		_box(_deck, Vector3(0.11, 0.015, 9.8), approach, _insert)
		_box(_deck, Vector3(0.025, 0.015, 9.8), approach + Vector3(side * 0.067, 0, 0), _mark)
		for marking in range(5):
			var tick := approach + Vector3(side * 0.23, 0.014, 1.1 + marking * 0.69)
			_box(_deck, Vector3(0.23, 0.014, 0.035), tick, _trim)
		for seam in range(5):
			var offset := Vector3(side * 4.7, 0.012, 1.13 + seam * 1.96)
			_box(_deck, Vector3(4.86, 0.015, 0.025), offset, _mark)

		var console := Node3D.new()
		console.position = Vector3(side * 8.10, 0, 3.15)
		console.rotation_degrees.y = side * 18.0
		_deck.add_child(console)
		_box(console, Vector3(2.0, 0.14, 3.1), Vector3(0, 0.05, 0), _trim)
		_box(console, Vector3(1.83, 1.08, 2.89), Vector3(0, 0.65, 0), _structure)
		_box(console, Vector3(2.02, 0.18, 3.02), Vector3(0, 1.28, 0), _slate)
		_box(console, Vector3(1.54, 0.025, 2.45), Vector3(0, 1.38, 0), _screen)
		_box(console, Vector3(0.045, 0.025, 2.04), Vector3(-side * 0.57, 1.40, 0), _guide)
		for row in range(5):
			var depth := -0.68 + row * 0.30
			_box(console, Vector3(0.64 - 0.07 * row, 0.025, 0.028), Vector3(-side * 0.05, 1.40, depth), _guide)

	_arc(_deck, 3.47, 3.52, -73, 73, 0.143, 0.018, _mark, 42)
	_arc(_deck, 3.51, 3.58, -42, 42, 0.145, 0.017, _trim, 24)


func _build_window() -> void:
	_arc(_deck, 13.70, 15.44, -74, 74, 12.72, 0.72, _structure, 44)
	_arc(_deck, 14.15, 15.34, -74, 74, 12.31, 0.17, _slate, 44)
	_arc(_deck, 14.08, 14.19, -74, 74, 12.22, 0.055, _trim, 44)
	_arc(_deck, 14.07, 14.12, -69, 69, 12.18, 0.028, _guide, 44)
	_arc(_deck, 15.18, 15.32, -74, 74, 1.49, 0.105, _structure, 44)

	for angle in [-70.0, -49.0, -29.0, 29.0, 49.0, 70.0]:
		var width := 0.12 if absf(angle) < 60 else 0.55
		var depth := 0.24 if absf(angle) < 60 else 0.75
		_radial_box(_deck, WINDOW_RADIUS, angle, 6.41, Vector3(width, 11.98, depth), _structure)
		_radial_box(_deck, WINDOW_RADIUS - depth * 0.50, angle, 6.40, Vector3(width * 0.49, 11.88, 0.024), _trim)

	for side in [-1.0, 1.0]:
		var angle: float = side * 70.0
		_radial_box(_deck, WINDOW_RADIUS - 0.16, angle, 4.47, Vector3(0.48, 5.95, 0.63), _slate)
		_radial_box(_deck, WINDOW_RADIUS - 0.51, angle, 4.43, Vector3(0.055, 5.28, 0.028), _guide)


func _build_stations() -> void:
	for index in STATION_ANGLES.size():
		var angle: float = STATION_ANGLES[index]
		var station := Node3D.new()
		station.name = "Station%02d" % (index + 1)
		station.position = _radial_position(STATION_RADIUS, angle, 0.0)
		station.rotation_degrees.y = -angle
		_stations.add_child(station)
		var lamp := _signal(AMBER)
		_signal_materials.append(lamp)
		_build_station(station, lamp, index)


func _build_station(station: Node3D, lamp: StandardMaterial3D, index: int) -> void:
	_box(station, Vector3(1.67, 0.17, 1.44), Vector3(0, 0.2, 0), _insert)
	_box(station, Vector3(1.53, 0.07, 1.30), Vector3(0, 0.31, 0), _trim)
	_box(station, Vector3(1.39, 0.68, 1.11), Vector3(0, 0.67, 0), _structure)
	_box(station, Vector3(1.52, 0.15, 1.20), Vector3(0, 1.09, 0.02), _slate)
	_box(station, Vector3(1.22, 0.04, 0.76), Vector3(0, 1.177, -0.07), _screen)
	_box(station, Vector3(1.08, 0.21, 0.033), Vector3(0, 0.72, 0.571), _screen)
	_box(station, Vector3(0.76, 0.025, 0.032), Vector3(-0.07, 0.71, 0.594), lamp)
	_box(station, Vector3(0.035, 0.035, 0.032), Vector3(0.455, 0.71, 0.594), lamp)
	for rib in range(3):
		var x := -0.23 + rib * 0.23
		_box(station, Vector3(0.15, 0.018, 0.035), Vector3(x, 0.47, 0.563), _trim)

	var beacon := Node3D.new()
	beacon.position = Vector3(0, 1.71, -0.055)
	station.add_child(beacon)
	_box(station, Vector3(0.62, 0.06, 0.48), Vector3(0, 1.22, -0.075), _trim)
	_box(station, Vector3(0.10, 0.28, 0.10), Vector3(0, 1.36, -0.075), _structure)
	_build_beacon(beacon, lamp, index)


func _build_beacon(beacon: Node3D, lamp: StandardMaterial3D, index: int) -> void:
	match index:
		0:
			var points := PackedVector3Array([
				Vector3(-0.38, -0.23, 0), Vector3(-0.38, 0.28, 0),
				Vector3(0.39, -0.23, 0), Vector3(-0.38, -0.23, 0)
			])
			_outline(beacon, points, 0.030, lamp)
		1:
			var cube := _box(beacon, Vector3(0.48, 0.48, 0.48), Vector3.ZERO, _slate)
			cube.rotation_degrees = Vector3(19, 36, -8)
			_box(cube, Vector3(0.49, 0.026, 0.49), Vector3(0, 0.045, 0), lamp)
			_box(cube, Vector3(0.49, 0.026, 0.49), Vector3(0, -0.105, 0), lamp)
		2:
			_box(beacon, Vector3(0.68, 0.045, 0.05), Vector3(0, 0.24, 0), _trim)
			_box(beacon, Vector3(0.68, 0.045, 0.05), Vector3(0, -0.23, 0), _trim)
			for x in [-0.22, 0.22]:
				_box(beacon, Vector3(0.028, 0.42, 0.032), Vector3(x, 0, 0), lamp)
			var mass := SphereMesh.new()
			mass.radius = 0.096
			mass.height = 0.192
			_piece(beacon, mass, lamp, Vector3(-0.22, 0.10, 0.06))
			_piece(beacon, mass, lamp, Vector3(0.22, -0.10, 0.06))
		3:
			var flask := CylinderMesh.new()
			flask.top_radius = 0.084
			flask.bottom_radius = 0.22
			flask.height = 0.30
			_piece(beacon, flask, lamp, Vector3(0, -0.10, 0))
			_box(beacon, Vector3(0.158, 0.22, 0.15), Vector3(0, 0.155, 0), _slate)
			_box(beacon, Vector3(0.24, 0.036, 0.20), Vector3(0, 0.275, 0), lamp)
		4:
			var points := PackedVector3Array([
				Vector3(-0.39, -0.015, 0), Vector3(-0.20, -0.015, 0),
				Vector3(-0.08, 0.22, 0), Vector3(0.02, -0.20, 0),
				Vector3(0.15, 0.08, 0), Vector3(0.22, -0.015, 0),
				Vector3(0.39, -0.015, 0)
			])
			_outline(beacon, points, 0.030, lamp)
		5:
			var gauge := TorusMesh.new()
			gauge.inner_radius = 0.228
			gauge.outer_radius = 0.268
			gauge.rings = 32
			gauge.ring_segments = 16
			var dial := _piece(beacon, gauge, lamp, Vector3.ZERO)
			dial.rotation_degrees.x = 90
			_bar(beacon, Vector3.ZERO, Vector3(0.16, 0.12, 0.025), 0.032, lamp)


func _outline(parent: Node3D, points: PackedVector3Array, width: float, material: Material) -> void:
	for index in range(points.size() - 1):
		_bar(parent, points[index], points[index + 1], width, material)


func _bar(parent: Node3D, start: Vector3, finish: Vector3, width: float, material: Material) -> void:
	var direction := finish - start
	var segment := _box(parent, Vector3(width, width, direction.length() + width), (start + finish) * 0.5, material)
	segment.basis = Basis.looking_at(direction.normalized(), Vector3.FORWARD)


func _radial_box(parent: Node3D, radius: float, angle: float, height: float, size: Vector3, material: Material) -> void:
	var item := _box(parent, size, _radial_position(radius, angle, height), material)
	item.rotation_degrees.y = -angle


func _radial_position(radius: float, angle: float, height: float) -> Vector3:
	var radians := deg_to_rad(angle)
	return DECK_CENTER + Vector3(sin(radians) * radius, height, -cos(radians) * radius)


func _arc(parent: Node3D, inner: float, outer: float, start: float, end: float, center_height: float, thickness: float, material: Material, subdivisions: int) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := center_height + thickness * 0.5
	var bottom := center_height - thickness * 0.5
	for index in subdivisions:
		var a := lerpf(start, end, float(index) / subdivisions)
		var b := lerpf(start, end, float(index + 1) / subdivisions)
		var ti_a := _radial_position(inner, a, top)
		var to_a := _radial_position(outer, a, top)
		var bi_a := _radial_position(inner, a, bottom)
		var bo_a := _radial_position(outer, a, bottom)
		var ti_b := _radial_position(inner, b, top)
		var to_b := _radial_position(outer, b, top)
		var bi_b := _radial_position(inner, b, bottom)
		var bo_b := _radial_position(outer, b, bottom)
		_quad(surface, ti_a, ti_b, to_b, to_a)
		_quad(surface, bi_a, bo_a, bo_b, bi_b)
		_quad(surface, ti_a, bi_a, bi_b, ti_b)
		_quad(surface, to_a, to_b, bo_b, bo_a)
		if index == 0:
			_quad(surface, ti_a, to_a, bo_a, bi_a)
		if index == subdivisions - 1:
			_quad(surface, ti_b, bi_b, bo_b, to_b)
	surface.generate_normals()
	_piece(parent, surface.commit(), material, Vector3.ZERO)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point in [a, c, b, a, d, c]:
		surface.add_vertex(point)


func _box(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _piece(parent, mesh, material, position)


func _piece(parent: Node3D, mesh: Mesh, material: Material, position: Vector3) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = material
	item.position = position
	parent.add_child(item)
	return item


func _surface(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _signal(color: Color) -> StandardMaterial3D:
	var material := _surface(color.darkened(0.24), 0.18, 0.53)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.35
	return material
