extends "res://scripts/physics/lab_stage_3d.gd"
## Vektör Limanı 3B sahnesi: çelik iskeleli yanaşma kafesi, yerde ızgara, dikey z direği, havada yanaşma halkası ve kargo drone'u.
## Konum birimi "birim"dir: x doğu, y kuzey, z yukarı. Sahne dünyasında 1 birim = UNIT metre, kuzey -Z yönündedir.
## Fare ile sürükle: kamerayı çevir, tekerlek: yakınlaştır. Hesap mission.gd'de; burası yalnızca çizer ve drone'u uçurur.

signal flight_finished

const UNIT := 0.45
const EXTENT := 8
const AMBER := Color("#dfae63")
const SAGE := Color("#8fbea0")
const PAPER := Color("#eeeae0")
const CYAN := Color("#6fe3c1")
const RED := Color("#d9695f")
const CAMERA_TARGET := Vector3(1.7, 1.9, -1.7)
const CAMERA_OFFSET := Vector3(5.6, 4.2, 6.6)
const METAL := "res://assets/materials/Metal009/Metal009_2K-JPG_"

var dock: Vector3 = Vector3(2, 3, 6)
var capsule_position := Vector3.ZERO

var _capsule: Node3D
var _drone_body: Node3D
var _rotors: Array[Node3D] = []
var _exhaust: MeshInstance3D
var _dock_root: Node3D
var _dock_material: StandardMaterial3D
var _dock_label: Label3D
var _guides: Node3D
var _arrows: Dictionary = {}
var _arrow_labels: Dictionary = {}
var _flight: Tween
var _clock := 0.0
var _yaw := 0.0
var _zoom := 1.0
var _dragging := false
## Dar kutuda yönerge solda yer kaplar: kamera hedefi kaydırılır, kafes sağa ve aşağı oturur.
var view_shift := Vector3.ZERO


func _ready() -> void:
	build(AMBER)
	gui_input.connect(_orbit_input)


func build(accent: Color) -> void:
	setup(accent, 34.0, CAMERA_TARGET + CAMERA_OFFSET, CAMERA_TARGET)
	key_light.rotation_degrees = Vector3(-58, -34, 0)
	key_light.light_energy = 1.15
	_build_floor()
	_build_gantry()
	_build_grid()
	_build_axes()
	_build_dock()
	_build_drone()
	for name_text in ["A", "B", "C", "R"]:
		_make_arrow(name_text)


func world_of(unit_position: Vector3) -> Vector3:
	return Vector3(unit_position.x * UNIT, unit_position.z * UNIT, -unit_position.y * UNIT)


func _orbit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = button.pressed
		elif button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			_zoom = clampf(_zoom * 0.92, 0.6, 1.4)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			_zoom = clampf(_zoom * 1.08, 0.6, 1.4)
	elif event is InputEventMouseMotion and _dragging:
		_yaw = clampf(_yaw - (event as InputEventMouseMotion).relative.x * 0.006, -1.1, 1.1)
	elif event is InputEventMagnifyGesture:
		_zoom = clampf(_zoom / (event as InputEventMagnifyGesture).factor, 0.6, 1.4)


# --- Sahne kurulumu ---

func _build_floor() -> void:
	var plate := pbr_ph("metal_plate", Vector3(2.0, 2.0, 2.0), Color(0.34, 0.35, 0.33), 1.0)
	var span := EXTENT * UNIT
	box(Vector3(span + 1.2, 0.16, span + 1.2), plate, Vector3(span * 0.5, -0.09, -span * 0.5))
	var edge := glow_material(Color("#26271f"), 0.0)
	for side in [-1.0, 1.0]:
		box(Vector3(span + 1.2, 0.08, 0.1), edge, Vector3(span * 0.5, 0.0, -span * 0.5 + side * (span * 0.5 + 0.6)))
		box(Vector3(0.1, 0.08, span + 1.2), edge, Vector3(span * 0.5 + side * (span * 0.5 + 0.6), 0.0, -span * 0.5))


func _build_gantry() -> void:
	# Kafesin köşe direkleri ve üst çerçevesi: üçüncü boyutu (yüksekliği) okutur.
	var steel := pbr(METAL, Vector3(0.5, 3.0, 0.5), Color(0.62, 0.64, 0.66), 1.0)
	var span := EXTENT * UNIT
	var height := EXTENT * UNIT + 0.35
	for corner in [Vector2(span, 0), Vector2(span, span), Vector2(0, span)]:
		box(Vector3(0.07, height, 0.07), steel, Vector3(corner.x, height * 0.5, -corner.y))
		cylinder(0.1, 0.06, steel, Vector3(corner.x, 0.03, -corner.y))
	for pair in [[Vector2(span, 0), Vector2(span, span)], [Vector2(span, span), Vector2(0, span)]]:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		var along_x: bool = absf(a.y - b.y) < 0.01
		box(Vector3(length if along_x else 0.05, 0.05, 0.05 if along_x else length), steel, Vector3(mid.x, height, -mid.y))
	var brace := glow_material(Color(PAPER, 0.18), 0.0)
	brace.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for level in range(2, EXTENT + 1, 2):
		var y := level * UNIT
		box(Vector3(span, 0.012, 0.012), brace, Vector3(span * 0.5, y, -span))
		box(Vector3(0.012, 0.012, span), brace, Vector3(span, y, -span * 0.5))


func _build_grid() -> void:
	var line := glow_material(Color(PAPER, 0.18), 0.0)
	line.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var span := EXTENT * UNIT
	for index in range(0, EXTENT + 1):
		var strong := index % 4 == 0
		var width := 0.022 if strong else 0.01
		box(Vector3(width, 0.006, span), line, Vector3(index * UNIT, 0.005, -span * 0.5))
		box(Vector3(span, 0.006, width), line, Vector3(span * 0.5, 0.005, -index * UNIT))


func _build_axes() -> void:
	var origin := world_of(Vector3.ZERO)
	var length := EXTENT * UNIT
	box(Vector3(length, 0.025, 0.025), glow_material(AMBER, 1.0), origin + Vector3(length * 0.5, 0.02, 0.0))
	box(Vector3(0.025, 0.025, length), glow_material(SAGE, 1.0), origin + Vector3(0.0, 0.02, -length * 0.5))
	box(Vector3(0.025, length, 0.025), glow_material(CYAN, 1.0), origin + Vector3(0.0, length * 0.5, 0.0))
	for tick in [2, 4, 6, 8]:
		_flat_label(str(tick), origin + Vector3(tick * UNIT, 0.02, 0.2), 0.16, AMBER)
		_flat_label(str(tick), origin + Vector3(-0.28, 0.02, -tick * UNIT), 0.16, SAGE)
		_billboard(str(tick), origin + Vector3(-0.28, tick * UNIT, 0.0), 0.16, CYAN)
	_flat_label("doğu (x)", origin + Vector3(length - 0.3, 0.02, 0.5), 0.15, AMBER)
	_flat_label("kuzey (y)", origin + Vector3(-0.2, 0.02, -length - 0.3), 0.15, SAGE)
	_billboard("yukarı (z)", origin + Vector3(0.0, length + 0.3, 0.0), 0.16, CYAN)


func _billboard(text: String, at: Vector3, size_value: float, colour: Color) -> Label3D:
	var label := _flat_label(text, at, size_value, colour)
	label.rotation = Vector3.ZERO
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label


func _flat_label(text: String, at: Vector3, size_value: float, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = size_value / 48.0
	label.modulate = colour
	label.outline_size = 8
	label.outline_modulate = Color("#10110f")
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.position = at
	label.no_depth_test = true
	world.add_child(label)
	return label


func _build_dock() -> void:
	_dock_root = Node3D.new()
	world.add_child(_dock_root)
	_dock_material = glow_material(AMBER, 1.6)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26
	torus.outer_radius = 0.33
	ring.mesh = torus
	ring.material_override = _dock_material
	_dock_root.add_child(ring)
	var metal := glow_material(Color("#2b2c28"), 0.0)
	cylinder(0.24, 0.02, metal, Vector3.ZERO, Vector3.ZERO, _dock_root)
	for index in 4:
		var angle := index * PI * 0.5 + PI * 0.25
		var latch := box(Vector3(0.1, 0.05, 0.05), metal, Vector3(cos(angle) * 0.3, 0.0, sin(angle) * 0.3), _dock_root)
		latch.rotation.y = -angle
	_dock_label = _billboard("yanaşma halkası", Vector3.ZERO, 0.13, AMBER)
	_guides = Node3D.new()
	world.add_child(_guides)
	place_dock(dock)


## Halkanın yerini ve ona inen izdüşüm çizgilerini (x, y, z okumak için) koyar. x < -10 halkayı gizler.
func place_dock(unit_position: Vector3, show_guides: bool = true) -> void:
	dock = unit_position
	_dock_root.visible = unit_position.x > -10.0
	_dock_label.visible = _dock_root.visible
	_dock_root.position = world_of(unit_position)
	_dock_label.position = world_of(unit_position) + Vector3(0, 0.5, 0)
	for child in _guides.get_children():
		child.queue_free()
	if not _dock_root.visible or not show_guides:
		return
	var dash := glow_material(Color(AMBER, 0.55), 0.6)
	dash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var top := world_of(unit_position)
	var floor_point := Vector3(top.x, 0.01, top.z)
	_guide_line(top, floor_point, dash)
	_guide_line(floor_point, Vector3(top.x, 0.01, 0.0), dash)
	_guide_line(floor_point, Vector3(0.0, 0.01, top.z), dash)
	var dot := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	dot.mesh = sphere
	dot.material_override = dash
	dot.position = floor_point
	_guides.add_child(dot)


func _guide_line(from: Vector3, to: Vector3, material: Material) -> void:
	var length := from.distance_to(to)
	if length < 0.02:
		return
	var count := maxi(int(length / 0.09), 1)
	var direction := (to - from).normalized()
	for index in count:
		var mark := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.014, 0.014, 0.05)
		mark.mesh = mesh
		mark.material_override = material
		_guides.add_child(mark)
		var point := from.lerp(to, (float(index) + 0.5) / float(count))
		mark.look_at_from_position(point, point + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)


func set_dock_state(state: StringName) -> void:
	var colour := AMBER if state == &"idle" else CYAN if state == &"ok" else RED
	_dock_material.albedo_color = colour
	_dock_material.emission = colour


func _build_drone() -> void:
	_capsule = Node3D.new()
	world.add_child(_capsule)
	_drone_body = Node3D.new()
	_capsule.add_child(_drone_body)
	var shell := pbr(METAL, Vector3(0.6, 0.6, 0.6), Color(0.74, 0.76, 0.78), 1.0)
	var dark := glow_material(Color("#1c1d1a"), 0.0)
	dark.roughness = 0.5
	box(Vector3(0.34, 0.1, 0.34), shell, Vector3.ZERO, _drone_body)
	box(Vector3(0.28, 0.035, 0.28), dark, Vector3(0, 0.065, 0), _drone_body)
	var eye := MeshInstance3D.new()
	var lens := SphereMesh.new()
	lens.radius = 0.045
	lens.height = 0.09
	eye.mesh = lens
	eye.material_override = glow_material(AMBER, 2.2)
	eye.position = Vector3(0.17, 0.0, 0)
	_drone_body.add_child(eye)
	box(Vector3(0.012, 0.012, 0.3), glow_material(AMBER, 1.4), Vector3(0.0, 0.085, 0), _drone_body)
	for index in 4:
		var angle := PI * 0.25 + index * PI * 0.5
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var arm := box(Vector3(0.36, 0.035, 0.04), shell, direction * 0.26 + Vector3(0, 0.01, 0), _drone_body)
		arm.rotation.y = -angle
		cylinder(0.05, 0.07, dark, direction * 0.43 + Vector3(0, 0.03, 0), Vector3.ZERO, _drone_body)
		var rotor := Node3D.new()
		rotor.position = direction * 0.43 + Vector3(0, 0.08, 0)
		_drone_body.add_child(rotor)
		cylinder(0.2, 0.004, glass_material(Color(0.8, 0.9, 0.95), 0.12), Vector3.ZERO, Vector3.ZERO, rotor)
		for blade in 2:
			var plate := box(Vector3(0.4, 0.006, 0.035), dark, Vector3.ZERO, rotor)
			plate.rotation.y = blade * PI * 0.5
		_rotors.append(rotor)
	box(Vector3(0.22, 0.12, 0.22), shell, Vector3(0, -0.11, 0), _drone_body)
	box(Vector3(0.24, 0.02, 0.24), dark, Vector3(0, -0.04, 0), _drone_body)
	box(Vector3(0.2, 0.012, 0.012), glow_material(CYAN, 1.2), Vector3(0, -0.11, 0.115), _drone_body)
	for side in [-1.0, 1.0]:
		box(Vector3(0.34, 0.015, 0.015), dark, Vector3(0, -0.2, side * 0.14), _drone_body)
		for end in [-1.0, 1.0]:
			box(Vector3(0.012, 0.1, 0.012), dark, Vector3(end * 0.15, -0.15, side * 0.14), _drone_body)
	_exhaust = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.11
	cone.height = 0.3
	_exhaust.mesh = cone
	_exhaust.material_override = glow_material(Color(CYAN, 0.5), 1.6)
	_exhaust.position = Vector3(0, -0.38, 0)
	_exhaust.rotation_degrees = Vector3(180, 0, 0)
	_exhaust.visible = false
	_drone_body.add_child(_exhaust)
	_capsule.scale = Vector3.ONE * 1.8
	reset_capsule()


func reset_capsule() -> void:
	if _flight != null:
		_flight.kill()
	capsule_position = Vector3.ZERO
	_capsule.position = world_of(Vector3.ZERO) + Vector3(0, 0.3, 0)
	_capsule.rotation = Vector3.ZERO
	_exhaust.visible = false
	set_dock_state(&"idle")


func _make_arrow(key: String) -> void:
	var colour := AMBER if key == "A" else SAGE if key == "B" else CYAN if key == "C" else PAPER
	var arrow := Node3D.new()
	var material := glow_material(colour, 0.9)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.03 if key != "R" else 0.04
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
	head_mesh.bottom_radius = 0.085
	head_mesh.height = 0.2
	head_mesh.radial_segments = 12
	head.mesh = head_mesh
	head.material_override = material
	head.name = "Head"
	arrow.add_child(head)
	arrow.visible = false
	world.add_child(arrow)
	_arrows[key] = arrow
	var label := _billboard(key, Vector3.ZERO, 0.24, colour)
	label.visible = false
	_arrow_labels[key] = label


## Oku `from` noktasından `to` noktasına (birim cinsinden, üç boyutlu) çizer; çok kısa vektörde gizler.
func set_arrow(key: String, from: Vector3, to: Vector3, visible_now: bool = true) -> void:
	var arrow: Node3D = _arrows[key]
	var label: Label3D = _arrow_labels[key]
	var start := world_of(from)
	var finish := world_of(to)
	var length := start.distance_to(finish)
	var show := visible_now and length > 0.14
	arrow.visible = show
	label.visible = show
	if not show:
		return
	var direction := (finish - start) / length
	var shaft_length := length - 0.2
	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")
	var basis := Basis(Quaternion(Vector3.UP, direction))
	shaft.transform = Transform3D(basis.scaled(Vector3(1, shaft_length, 1)), start + direction * shaft_length * 0.5)
	head.transform = Transform3D(basis, start + direction * (shaft_length + 0.1))
	label.position = (start + finish) * 0.5 + Vector3(0.0, 0.18, 0.0)


func hide_arrows() -> void:
	for key in _arrows:
		set_arrow(key, Vector3.ZERO, Vector3.ZERO, false)


## Drone noktalar boyunca uçar (birim cinsinden, üç boyutlu). Son noktada `flight_finished` yayılır.
func fly(points: Array, seconds: float) -> void:
	if _flight != null:
		_flight.kill()
	_exhaust.visible = true
	Audio.play_sfx("capsule_thruster_dock", -10.0)
	_flight = create_tween()
	var total := 0.0
	var last: Vector3 = capsule_position
	for point in points:
		total += last.distance_to(point)
		last = point
	var from: Vector3 = capsule_position
	for point in points:
		var target: Vector3 = point
		var leg := from.distance_to(target)
		if leg > 0.01:
			_flight.tween_method(_move_capsule, from, target, seconds * leg / maxf(total, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		from = target
	_flight.tween_callback(func() -> void:
		_exhaust.visible = false
		flight_finished.emit())


func _move_capsule(unit_position: Vector3) -> void:
	capsule_position = unit_position
	_capsule.position = world_of(unit_position) + Vector3(0, 0.3, 0)


func _process(delta: float) -> void:
	_clock += delta
	for rotor in _rotors:
		rotor.rotation.y += delta * 55.0
	if _drone_body != null:
		_drone_body.position.y = sin(_clock * 2.2) * 0.012
	if _dock_root != null:
		_dock_root.scale = Vector3.ONE * (1.0 + 0.04 * sin(_clock * 3.0))
	if size.y > 1.0 and camera != null:
		# Kutu 2:1'den darsa kamera geri çekilir; kullanıcı kamerayı sürükleyerek çevirebilir.
		var pull := maxf(1.0, 2.0 / (size.x / size.y)) * _zoom * (1.14 if size.x < 760.0 else 1.0)
		var offset := CAMERA_OFFSET.rotated(Vector3.UP, _yaw) * pull
		camera.look_at_from_position(CAMERA_TARGET + view_shift + offset, CAMERA_TARGET + view_shift)
