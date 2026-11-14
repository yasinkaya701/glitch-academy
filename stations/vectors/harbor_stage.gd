extends "res://scripts/physics/lab_stage_3d.gd"
## Vektör Limanı 3B sahnesi: betonarme rıhtım, koyu su, yanaşma halkası, kapsül ve rıhtıma uzanan ok vektörleri.
## Konum birimi "birim"dir: x doğu, y kuzey. Sahne dünyasında 1 birim = UNIT metre, kuzey -Z yönündedir.
## Hesap mission.gd'de; burası yalnızca çizer ve kapsülü uçurur.

signal flight_finished

const UNIT := 0.55
const AMBER := Color("#dfae63")
const SAGE := Color("#8fbea0")
const PAPER := Color("#eeeae0")
const CYAN := Color("#6fe3c1")
const RED := Color("#d9695f")
const QUAY_CENTER := Vector3(2.9, 0.0, -2.05)
const CAMERA_TARGET := Vector3(2.9, 0.0, -1.7)
const CAMERA_OFFSET := Vector3(0.0, 6.6, 6.7)
const GRID_COLUMNS := 12
const GRID_ROWS := 9

var dock: Vector2 = Vector2(5, 12)
var capsule_position := Vector2.ZERO

var _capsule: Node3D
var _exhaust: MeshInstance3D
var _dock_ring: MeshInstance3D
var _dock_material: StandardMaterial3D
var _arrows: Dictionary = {}
var _arrow_labels: Dictionary = {}
var _dock_label: Label3D
var _flight: Tween
var _clock := 0.0


func _ready() -> void:
	build(AMBER)


func build(accent: Color) -> void:
	setup(accent, 34.0, Vector3(2.9, 6.6, 5.0), Vector3(2.9, 0.0, -1.7))
	key_light.rotation_degrees = Vector3(-62, -24, 0)
	key_light.light_energy = 1.1
	_build_water()
	_build_quay()
	_build_grid()
	_build_dock()
	_build_capsule()
	for name_text in ["A", "B", "R"]:
		_make_arrow(name_text)


func world_of(unit_position: Vector2) -> Vector3:
	return Vector3(unit_position.x * UNIT, 0.0, -unit_position.y * UNIT)


func _build_water() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 24)
	water.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#1b2421")
	material.metallic = 0.4
	material.roughness = 0.18
	water.material_override = material
	water.position = Vector3(0, -0.04, -4.0)
	world.add_child(water)


func _build_quay() -> void:
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color("#3a3c37")
	concrete.roughness = 0.88
	box(Vector3(7.6, 0.3, 5.9), concrete, QUAY_CENTER + Vector3(0, -0.15, 0))
	var kerb := pbr_ph("metal_plate", Vector3(1.5, 1.5, 1.5), Color(0.5, 0.52, 0.5), 1.0)
	var half := Vector3(3.8, 0.0, 2.95)
	box(Vector3(7.6, 0.07, 0.07), kerb, QUAY_CENTER + Vector3(0, 0.02, half.z))
	box(Vector3(7.6, 0.07, 0.07), kerb, QUAY_CENTER + Vector3(0, 0.02, -half.z))
	box(Vector3(0.07, 0.07, 5.9), kerb, QUAY_CENTER + Vector3(half.x, 0.02, 0))
	box(Vector3(0.07, 0.07, 5.9), kerb, QUAY_CENTER + Vector3(-half.x, 0.02, 0))
	# Bağlama babaları köşelerde: rıhtımın ölçeğini ve yönünü okutur.
	var iron := glow_material(Color("#2b2c28"), 0.0)
	for corner in [Vector3(-half.x + 0.25, 0, half.z - 0.25), Vector3(half.x - 0.25, 0, half.z - 0.25), Vector3(-half.x + 0.25, 0, -half.z + 0.25), Vector3(half.x - 0.25, 0, -half.z + 0.25)]:
		cylinder(0.07, 0.14, iron, QUAY_CENTER + corner + Vector3(0, 0.07, 0))


func _build_grid() -> void:
	var line := glow_material(Color(PAPER, 0.16), 0.0)
	line.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var origin := world_of(Vector2.ZERO)
	for column in range(0, GRID_COLUMNS + 1):
		var strong := column % 5 == 0
		box(Vector3(0.01 if not strong else 0.022, 0.004, GRID_ROWS * UNIT), line, origin + Vector3(column * UNIT, 0.004, -GRID_ROWS * UNIT * 0.5))
	for row in range(0, GRID_ROWS + 1):
		var strong := row % 5 == 0
		box(Vector3(GRID_COLUMNS * UNIT, 0.004, 0.01 if not strong else 0.022), line, origin + Vector3(GRID_COLUMNS * UNIT * 0.5, 0.004, -row * UNIT))
	for tick in [5, 10]:
		_label(str(tick), origin + Vector3(tick * UNIT, 0.01, 0.22), 0.1, PAPER)
	for tick in [5]:
		_label(str(tick), origin + Vector3(-0.22, 0.01, -tick * UNIT), 0.1, PAPER)
	_label("başlangıç", origin + Vector3(-0.05, 0.01, 0.34), 0.08, Color(PAPER, 0.85))
	_label("doğu →", origin + Vector3(GRID_COLUMNS * UNIT - 0.1, 0.01, 0.24), 0.09, Color(PAPER, 0.8))
	_label("kuzey ↑", origin + Vector3(-0.1, 0.01, -GRID_ROWS * UNIT - 0.2), 0.09, Color(PAPER, 0.8))


func _label(text: String, at: Vector3, size: float, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = size / 48.0
	label.modulate = colour
	label.outline_size = 8
	label.outline_modulate = Color("#10110f")
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.position = at
	label.no_depth_test = true
	world.add_child(label)
	return label


func _build_dock() -> void:
	_dock_material = glow_material(AMBER, 1.6)
	_dock_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.27
	_dock_ring.mesh = torus
	_dock_ring.material_override = _dock_material
	world.add_child(_dock_ring)
	var pad := cylinder(0.2, 0.02, glow_material(Color("#26271f"), 0.0), Vector3.ZERO, Vector3.ZERO, _dock_ring)
	pad.position.y = 0.0
	_dock_label = _label("yanaşma noktası", Vector3.ZERO, 0.085, AMBER)
	place_dock(dock)


func place_dock(unit_position: Vector2) -> void:
	dock = unit_position
	_dock_ring.position = world_of(unit_position) + Vector3(0, 0.02, 0)
	_dock_label.position = world_of(unit_position) + Vector3(0, 0.02, 0.42)


func set_dock_state(state: StringName) -> void:
	var colour := AMBER if state == &"idle" else CYAN if state == &"ok" else RED
	_dock_material.albedo_color = colour
	_dock_material.emission = colour


func _build_capsule() -> void:
	_capsule = Node3D.new()
	_capsule.scale = Vector3.ONE * 1.5
	world.add_child(_capsule)
	var hull_material := pbr("res://assets/materials/Metal009/Metal009_2K-JPG_", Vector3(0.6, 0.6, 0.6), Color(0.78, 0.8, 0.82), 1.0)
	var body := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.1
	capsule_mesh.height = 0.38
	body.mesh = capsule_mesh
	body.material_override = hull_material
	body.rotation_degrees = Vector3(0, 0, 90)
	body.position.y = 0.11
	_capsule.add_child(body)
	var window := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.05
	window.mesh = sphere
	window.material_override = glow_material(AMBER, 1.2)
	window.position = Vector3(0.1, 0.18, 0)
	_capsule.add_child(window)
	for side in [-1.0, 1.0]:
		box(Vector3(0.12, 0.012, 0.09), hull_material, Vector3(-0.1, 0.1, side * 0.115), _capsule).rotation_degrees.y = side * 18.0
	_exhaust = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.06
	cone.height = 0.22
	_exhaust.mesh = cone
	_exhaust.material_override = glow_material(CYAN, 3.0)
	_exhaust.rotation_degrees = Vector3(0, 0, 90)
	_exhaust.position = Vector3(-0.3, 0.11, 0)
	_exhaust.visible = false
	_capsule.add_child(_exhaust)
	reset_capsule()


func reset_capsule() -> void:
	if _flight != null:
		_flight.kill()
	capsule_position = Vector2.ZERO
	_capsule.position = world_of(Vector2.ZERO)
	_capsule.rotation = Vector3.ZERO
	_exhaust.visible = false
	set_dock_state(&"idle")


func _make_arrow(key: String) -> void:
	var colour := AMBER if key == "A" else SAGE if key == "B" else PAPER
	var arrow := Node3D.new()
	var material := glow_material(colour, 0.9)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.04 if key != "R" else 0.05
	shaft_mesh.bottom_radius = shaft_mesh.top_radius
	shaft_mesh.height = 1.0
	shaft_mesh.radial_segments = 12
	shaft.mesh = shaft_mesh
	shaft.material_override = material
	shaft.name = "Shaft"
	arrow.add_child(shaft)
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.11
	head_mesh.height = 0.22
	head_mesh.radial_segments = 12
	head.mesh = head_mesh
	head.material_override = material
	head.name = "Head"
	arrow.add_child(head)
	arrow.visible = false
	world.add_child(arrow)
	_arrows[key] = arrow
	var label := _label(key, Vector3.ZERO, 0.17, colour)
	label.visible = false
	_arrow_labels[key] = label


## Oku `from` noktasından `to` noktasına (birim cinsinden) çizer; çok kısa vektörde gizler.
func set_arrow(key: String, from: Vector2, to: Vector2, visible_now: bool = true) -> void:
	var arrow: Node3D = _arrows[key]
	var label: Label3D = _arrow_labels[key]
	var start := world_of(from) + Vector3(0, 0.03 + (0.02 if key == "R" else 0.0), 0)
	var finish := world_of(to) + Vector3(0, 0.03 + (0.02 if key == "R" else 0.0), 0)
	var length := start.distance_to(finish)
	var show := visible_now and length > 0.12
	arrow.visible = show
	label.visible = show
	if not show:
		return
	var direction := (finish - start) / length
	var shaft_length := length - 0.22
	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")
	var basis := Basis(Quaternion(Vector3.UP, direction))
	shaft.transform = Transform3D(basis.scaled(Vector3(1, shaft_length, 1)), start + direction * shaft_length * 0.5)
	head.transform = Transform3D(basis, start + direction * (shaft_length + 0.11))
	var side := Vector3(-direction.z, 0, direction.x) * (0.22 if key != "R" else -0.22)
	label.position = (start + finish) * 0.5 + side + Vector3(0, 0.02, 0)


func hide_arrows() -> void:
	for key in _arrows:
		set_arrow(key, Vector2.ZERO, Vector2.ZERO, false)


## Kapsül noktalar boyunca uçar (birim cinsinden). Son noktada `flight_finished` yayılır.
func fly(points: Array, seconds: float) -> void:
	if _flight != null:
		_flight.kill()
	_exhaust.visible = true
	Audio.play_sfx("capsule_thruster_dock", -10.0)
	_flight = create_tween()
	var total := 0.0
	var last: Vector2 = capsule_position
	for point in points:
		total += last.distance_to(point)
		last = point
	var from: Vector2 = capsule_position
	for point in points:
		var target: Vector2 = point
		var leg := from.distance_to(target)
		if leg > 0.01:
			_flight.tween_callback(_face.bind(target - from))
			_flight.tween_method(_move_capsule, from, target, seconds * leg / maxf(total, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		from = target
	_flight.tween_callback(func() -> void:
		_exhaust.visible = false
		flight_finished.emit())


func _face(direction: Vector2) -> void:
	_capsule.rotation.y = atan2(direction.y, direction.x)


func _move_capsule(unit_position: Vector2) -> void:
	capsule_position = unit_position
	_capsule.position = world_of(unit_position)


func _process(delta: float) -> void:
	_clock += delta
	if size.y > 1.0:
		# Kutu 2:1'den darsa kamera geri çekilir: rıhtım iki yandan kesilmesin.
		var pull := maxf(1.0, 2.0 / (size.x / size.y))
		camera.look_at_from_position(CAMERA_TARGET + CAMERA_OFFSET * pull, CAMERA_TARGET)
	if _dock_ring != null:
		_dock_ring.scale = Vector3.ONE * (1.0 + 0.04 * sin(_clock * 3.0))
