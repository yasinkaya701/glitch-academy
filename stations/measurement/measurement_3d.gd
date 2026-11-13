extends Node3D
## 3D measurement bench. The stage and animation progress come directly from
## the mission's measured/input state, so the ruler, balance, timer and cart
## show the same values as the 2D instruction panel.

const MINT := Color("7ae2bf")
const AMBER := Color("ffad81")
const STEEL := Color("577371")
var kind: StringName = &"fault"
var measured := false
var progress := 0.0
var state: StringName = &"fault"
var cart: Node3D
var coupling: MeshInstance3D
var rail_part: MeshInstance3D
var readout: Label3D
var ruler_part: MeshInstance3D
var scale_weight: Node3D
var timer_hand: MeshInstance3D


func _ready() -> void:
	_build_bench()
	_apply_state()


func set_state(next_kind: StringName, has_reading: bool, motion: float, next_state: StringName) -> void:
	kind = next_kind
	measured = has_reading
	progress = clampf(motion, 0.0, 1.0)
	state = next_state
	_apply_state()


func _apply_state() -> void:
	if cart == null:
		return
	var is_connected := state == &"connected" or state == &"complete"
	var bad := state == &"fault" or state == &"too_long" or state == &"too_short"
	coupling.material_override.albedo_color = Color("214b43") if is_connected else (Color("57362b") if bad else Color("263d3e"))
	coupling.scale.x = 1.7 if state == &"too_long" else (0.62 if state == &"too_short" else 1.0)
	if state == &"fault":
		coupling.position.y = 0.45 - progress * 0.5
	else:
		coupling.position.y = 0.45 if is_connected else 0.18
	rail_part.material_override.albedo_color = MINT if measured else STEEL
	rail_part.position.x = -2.15 if measured else -1.75
	var cart_progress := 0.12 + progress * (0.27 if state == &"fault" else 0.73)
	if kind == &"speed":
		cart_progress = 1.0
	elif kind == &"complete":
		cart_progress = 1.0
	cart.position.x = lerpf(-2.55, 2.55, cart_progress)
	if ruler_part != null:
		ruler_part.visible = kind == &"length" or kind == &"convert"
		ruler_part.position.x = -1.4 if measured else -1.15
	if scale_weight != null:
		scale_weight.visible = kind == &"mass"
	if timer_hand != null:
		timer_hand.visible = kind == &"time"
		timer_hand.rotation.z = -progress * TAU * 0.75
	if readout != null:
		match kind:
			&"fault": readout.text = "240 cm → 240 m  ·  Uymadı"
			&"length", &"convert": readout.text = "240 cm" if kind == &"convert" else ("180 cm" if measured else "Cetveli ölçülecek parçaya hizala")
			&"mass": readout.text = "1,2 kg" if measured else "Yükü kefeye koy"
			&"time": readout.text = "%.1f s" % (1.5 * progress) if measured else "Başlat → durdur"
			&"guided": readout.text = "%.1f m   /   %.1f s" % [3.0 * progress, 2.0 * progress]
			&"speed": readout.text = "6 m   /   3 s"
			&"running", &"complete": readout.text = "2 m/s   ·   6 m tamamlandı"
			_: readout.text = "Ölçüm düzeneği"
		if kind == &"guided" and measured:
			readout.text += "\n1,5 m/s  →  doğu"


func _build_bench() -> void:
	var floor := _box(Vector3(7.8, 0.14, 3.4), Color("17262c"))
	floor.position.y = -0.76
	add_child(floor)
	var deck := _box(Vector3(7.1, 0.12, 1.45), Color("2c4447"))
	deck.position = Vector3(0, -0.34, 0)
	add_child(deck)
	for x in [-2.55, 2.55]:
		var leg := _box(Vector3(0.18, 0.7, 0.18), Color("203338"))
		leg.position = Vector3(x, -0.7, 0)
		add_child(leg)
	for z in [-0.39, 0.39]:
		var track := _box(Vector3(5.8, 0.12, 0.11), STEEL)
		track.position = Vector3(0, -0.19, z)
		add_child(track)
	coupling = _box(Vector3(0.52, 0.2, 0.55), Color("263d3e"))
	coupling.name = "RailCoupler"
	coupling.position = Vector3(0.0, 0.18, 0)
	add_child(coupling)
	rail_part = _box(Vector3(2.35, 0.12, 0.5), STEEL)
	rail_part.name = "MeasuredRail"
	rail_part.position = Vector3(-1.75, 0.2, 0)
	add_child(rail_part)
	cart = Node3D.new()
	cart.name = "Carrier"
	cart.position = Vector3(-2.2, 0.05, 0.55)
	add_child(cart)
	var cart_body := _box(Vector3(0.92, 0.46, 0.78), Color("4c6b68"))
	cart.add_child(cart_body)
	var cart_top := _box(Vector3(0.56, 0.12, 0.55), Color("6f9385"))
	cart_top.position.y = 0.28
	cart.add_child(cart_top)
	for x in [-0.29, 0.29]:
		for z in [-0.34, 0.34]:
			var wheel := _cylinder(0.12, 0.09, Color("131f24"))
			wheel.position = Vector3(x, -0.28, z)
			cart.add_child(wheel)
	# Measuring tools sit behind the rail and are switched by mission stage.
	var ruler := _box(Vector3(3.0, 0.08, 0.26), Color("314b45"))
	ruler.position = Vector3(0, 0.15, -0.78)
	add_child(ruler)
	ruler_part = _box(Vector3(2.25, 0.1, 0.32), MINT)
	ruler_part.name = "RulerSegment"
	ruler_part.position = Vector3(-1.15, 0.27, -0.78)
	add_child(ruler_part)
	for tick in range(13):
		var mark := _box(Vector3(0.018, 0.035, 0.22 if tick % 3 == 0 else 0.12), Color("a0dfbc"))
		mark.position = Vector3(-1.5 + tick * 0.25, 0.23, -0.78)
		add_child(mark)
	var balance := _box(Vector3(1.1, 0.12, 0.65), Color("263f40"))
	balance.name = "Balance"
	balance.position = Vector3(2.2, 0.08, -0.85)
	add_child(balance)
	var pan := _box(Vector3(0.94, 0.08, 0.56), STEEL)
	pan.position = Vector3(2.2, 0.22, -0.85)
	add_child(pan)
	scale_weight = Node3D.new()
	scale_weight.name = "MassWeight"
	add_child(scale_weight)
	var mass := _cylinder(0.2, 0.45, Color("b78356"))
	mass.position = Vector3(2.2, 0.48, -0.85)
	scale_weight.add_child(mass)
	var timer := _cylinder(0.38, 0.1, Color("243b3f"))
	timer.position = Vector3(2.15, 0.12, -0.85)
	add_child(timer)
	timer_hand = _box(Vector3(0.035, 0.08, 0.3), MINT)
	timer_hand.position = Vector3(2.15, 0.22, -0.85)
	timer_hand.visible = false
	add_child(timer_hand)
	readout = Label3D.new()
	readout.name = "InstrumentReadout"
	readout.text = "240 cm → 240 m  ·  Uymadı"
	readout.font_size = 48
	readout.pixel_size = 0.003
	readout.position = Vector3(0, 1.05, -0.2)
	readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	readout.modulate = Color("c8dbd6")
	add_child(readout)


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, color)


func _cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _mesh(mesh, color)


func _mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	node.material_override = mat
	return node
