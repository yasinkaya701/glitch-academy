extends "res://scripts/physics/bench_view.gd"
## Newton Kızağı sahnesi (3B): iki hava yastıklı ray, pirinç ağırlıklı kızaklar, varış kapısı, arkada ölçü ekranı, önde konsol.
## Hesap newton_sim.gd'den gelir. Kızak konumu ve ekrandaki grafik aynı ivmeyi kullanır.

signal arrived(index: int, time: float)

const Newton = preload("res://stations/newton/newton_sim.gd")
const Kit = preload("res://scripts/physics/stage_kit.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const RAIL_START := -1.6
const UNIT := 0.08                    ## dünya birimi / m
const LANES := [0.2, -0.22]           ## ray z konumları
const GATE_X := 1.64

var rail_length := 40.0              ## m
var sleds: Array[Dictionary] = []    ## {"mass", "force", "name", "color"}
var slow_motion := false
var faulty_display := false          ## cihaz a = F sanıyor
var gate_open := false
var show_slopes := true              ## ölç ve kurtar adımlarında eğim yazısı gizlenir
var time := 0.0
var running := false

var _arrived: Array[float] = []
var _trail: Array = []               ## sled başına Vector2(t, v)
var _nodes: Array[Node3D] = []
var _flames: Array[CPUParticles3D] = []
var _built_mass: Array[float] = [-1.0, -1.0]
var _lamps: Array[StandardMaterial3D] = []


func _camera_position() -> Vector3:
	return Vector3(0.0, 0.95, 3.7)


func _camera_target() -> Vector3:
	return Vector3(0.0, 0.34, 0.25)


func _screen_size() -> Vector2:
	return Vector2(1.5, 0.84)


func _screen_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-8.0)), Vector3(0.62, 0.74, -0.8))


func _build_set() -> void:
	var wood := Stage.pbr_ph("wood_table_001", Vector3(0.7, 0.7, 0.7), Color(0.95, 0.92, 0.88), 0.0)
	var aluminium := Stage.pbr(Stage.METAL_DIR, Vector3(2.0, 2.0, 2.0), Color(0.92, 0.94, 0.97), 1.0)
	stage.box(Vector3(3.9, 0.06, 0.9), wood, Vector3(0, -0.04, -0.01))
	_dress_set()
	for lane in LANES:
		stage.box(Vector3(3.5, 0.02, 0.2), aluminium, Vector3(0, 0.01, lane))
		# Ray cetveli: her 5 m'de çentik ve sayı
		var m := 0
		while m <= 40:
			var x := RAIL_START + m * UNIT
			stage.box(Vector3(0.006, 0.004, 0.02), aluminium, Vector3(x, 0.017, lane + 0.065))
			if m % 10 == 0:
				var label := Label3D.new()
				label.text = "%d m" % m
				label.font = FONT_REGULAR
				label.font_size = 48
				label.pixel_size = 0.018 / 48.0
				label.modulate = Color("#c9d3dc")
				label.rotation_degrees = Vector3(-90, 0, 0)
				label.position = Vector3(x, 0.018, lane + 0.105)
				label.shaded = false
				stage.world.add_child(label)
			m += 5
		_build_gate(lane, aluminium)
	for i in 2:
		var sled := Node3D.new()
		stage.world.add_child(sled)
		_nodes.append(sled)
		var flame := CPUParticles3D.new()
		flame.emitting = false
		flame.amount = 14
		flame.lifetime = 0.22
		flame.direction = Vector3(-1, 0, 0)
		flame.spread = 8.0
		flame.initial_velocity_min = 0.3
		flame.initial_velocity_max = 0.6
		flame.gravity = Vector3.ZERO
		var mesh := SphereMesh.new()
		mesh.radius = 0.006
		mesh.height = 0.012
		mesh.material = Stage.glow_material(Color(1.0, 0.7, 0.35), 2.0)
		flame.mesh = mesh
		flame.position = Vector3(-0.14, 0.05, 0.0)
		sled.add_child(flame)
		_flames.append(flame)


func _dress_set() -> void:
	var lamp := stage.model("res://assets/polyhaven/models/desk_lamp_arm_01/desk_lamp_arm_01.gltf", 0.55, null, true)
	lamp.position = Vector3(-1.72, 0.01, -0.28)
	lamp.rotation_degrees = Vector3(0, 35, 0)
	var toolbox := stage.model("res://assets/polyhaven/models/metal_toolbox/metal_toolbox.gltf", 0.38, null, true)
	toolbox.position = Vector3(1.72, 0.01, 0.3)
	toolbox.rotation_degrees = Vector3(0, -25, 0)


func _build_gate(lane: float, metal: Material) -> void:
	for z in [-0.07, 0.07]:
		stage.box(Vector3(0.025, 0.2, 0.025), metal, Vector3(GATE_X, 0.1, lane + z))
	stage.box(Vector3(0.025, 0.025, 0.16), metal, Vector3(GATE_X, 0.2, lane))
	var lamp_material := Stage.glow_material(DANGER, 1.4)
	var lamp := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.022
	sphere.height = 0.044
	lamp.mesh = sphere
	lamp.material_override = lamp_material
	lamp.position = Vector3(GATE_X, 0.235, lane)
	stage.world.add_child(lamp)
	_lamps.append(lamp_material)


func _rebuild_sled(index: int) -> void:
	var node := _nodes[index]
	for child in node.get_children():
		if child is CPUParticles3D:
			continue
		child.queue_free()
	var sled := sleds[index]
	var mass: float = sled["mass"]
	var colour: Color = sled["color"]
	stage.build_car(node, colour, int(roundf(mass)), 1.0)
	node.scale = Vector3.ONE * 1.5
	var label := Label3D.new()
	label.text = "%s · %s kg" % [String(sled["name"]).replace("Kızak ", ""), str(mass).replace(".", ",")]
	label.font = FONT
	label.font_size = 56
	label.pixel_size = 0.03 / 56.0
	label.modulate = colour
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.2, 0)
	label.shaded = false
	node.add_child(label)
	_built_mass[index] = mass


func set_sleds(list: Array[Dictionary]) -> void:
	sleds = list
	for i in 2:
		_nodes[i].visible = i < sleds.size()
		if i < sleds.size():
			_rebuild_sled(i)
	reset()


func reset() -> void:
	time = 0.0
	running = false
	gate_open = false
	_arrived.clear()
	_trail.clear()
	for sled in sleds:
		_arrived.append(-1.0)
		_trail.append([])
	_update_lamps()


func launch() -> void:
	reset()
	running = true


func accel(index: int) -> float:
	var sled := sleds[index]
	return Newton.acceleration(sled["force"], sled["mass"])


func position_of(index: int) -> float:
	if _arrived[index] >= 0.0:
		return rail_length
	return minf(0.5 * accel(index) * time * time, rail_length)


## Cihazın yanlış kuralı (a = F): kapıyı, kızağın gerçekten varmasından önce açar.
func faulty_arrival(index: int) -> float:
	var sled := sleds[index]
	return Newton.time_to_cover(rail_length, Newton.faulty_acceleration(sled["force"], sled["mass"]))


func gate_opened_early(index: int) -> bool:
	return faulty_display and index < sleds.size() and time >= faulty_arrival(index) and (index >= _arrived.size() or _arrived[index] < 0.0 or _arrived[index] > faulty_arrival(index) + 0.05)


func _update_lamps() -> void:
	for i in _lamps.size():
		var open := gate_open or (i < _arrived.size() and _arrived[i] >= 0.0) or (running and gate_opened_early(i))
		_lamps[i].albedo_color = ACCENT if open else DANGER
		_lamps[i].emission = ACCENT if open else DANGER


func _process(delta: float) -> void:
	super._process(delta)
	if _nodes.is_empty():
		return
	if running:
		time += delta * (0.25 if slow_motion else 1.0)
		for i in sleds.size():
			if _arrived[i] < 0.0:
				var a := accel(i)
				(_trail[i] as Array).append(Vector2(time, a * time))
				if 0.5 * a * time * time >= rail_length:
					_arrived[i] = Newton.time_to_cover(rail_length, a)
					arrived.emit(i, _arrived[i])
					_update_lamps()
		var all_done := true
		for t in _arrived:
			all_done = all_done and t >= 0.0
		if all_done:
			running = false
			gate_open = true
			_update_lamps()
	if faulty_display:
		_update_lamps()
	for i in sleds.size():
		var x := RAIL_START + position_of(i) * UNIT + 0.27
		_nodes[i].position = Vector3(x, 0.0, LANES[i] if sleds.size() > 1 else LANES[0])
		_flames[i].emitting = running and _arrived[i] < 0.0


func _draw_screen(canvas: Control, size: Vector2) -> void:
	var s := size.x / 1600.0
	canvas.draw_string(FONT_REGULAR, Vector2(40, 54) * s, "KIZAK  ·  HIZ – ZAMAN", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * s), MUTED)
	# Okuma kartları
	var cards: Array = [["SÜRE", str(snappedf(time, 0.01)).replace(".", ","), "s", INK]]
	for i in sleds.size():
		var v := accel(i) * time if _arrived[i] < 0.0 else accel(i) * _arrived[i]
		cards.append(["%s HIZ" % String(sleds[i]["name"]).to_upper(), str(snappedf(v, 0.1)).replace(".", ","), "m/s", sleds[i]["color"]])
	if show_slopes:
		for i in sleds.size():
			cards.append(["%s İVME" % String(sleds[i]["name"]).to_upper(), str(snappedf(accel(i), 0.01)).replace(".", ","), "m/s²", sleds[i]["color"]])
	for k in cards.size():
		var card: Array = cards[k]
		Kit.readout(canvas, Rect2(Vector2(40.0 + 300.0 * (k % 5), 80.0) * s, Vector2(280.0, 140.0) * s), card[0], card[1], card[2], FONT_REGULAR, s * 1.7, card[3])
	# Grafik
	var graph := Rect2(Vector2(130.0, 290.0) * s, Vector2(1380.0, 450.0) * s)
	canvas.draw_rect(graph, Color("#0a111b"))
	canvas.draw_rect(graph, Color(MUTED, 0.35), false, 2.0)
	var t_max := 8.0
	var v_max := 50.0
	for tick in range(0, int(t_max) + 1, 2):
		var gx := graph.position.x + graph.size.x * float(tick) / t_max
		canvas.draw_line(Vector2(gx, graph.position.y), Vector2(gx, graph.end.y), Color(1, 1, 1, 0.07), 1.0)
		canvas.draw_string(FONT_REGULAR, Vector2(gx - 14.0, graph.end.y + 34.0), "%d s" % tick, HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * s), MUTED)
	for tick in range(0, int(v_max) + 1, 10):
		var gy := graph.position.y + graph.size.y * (1.0 - float(tick) / v_max)
		canvas.draw_line(Vector2(graph.position.x, gy), Vector2(graph.end.x, gy), Color(1, 1, 1, 0.07), 1.0)
		canvas.draw_string(FONT_REGULAR, Vector2(graph.position.x - 60.0, gy + 8.0), "%d" % tick, HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * s), MUTED)
	canvas.draw_string(FONT_REGULAR, Vector2(40, graph.position.y - 10.0), "m/s", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * s), MUTED)
	for i in sleds.size():
		var colour: Color = sleds[i]["color"]
		var points := PackedVector2Array()
		for sample in _trail[i]:
			var v: Vector2 = sample
			points.append(Vector2(graph.position.x + graph.size.x * v.x / t_max, graph.position.y + graph.size.y * (1.0 - v.y / v_max)))
		if points.size() >= 2:
			canvas.draw_polyline(points, colour, 5.0, true)
	if faulty_display and not sleds.is_empty():
		canvas.draw_string(FONT, Vector2(140, 330) * s, "CİHAZ: a = F → ikisi de %s m/s²" % str(snappedf(sleds[0]["force"], 0.1)).replace(".", ","), HORIZONTAL_ALIGNMENT_LEFT, -1, int(32 * s), WARM)
		for i in sleds.size():
			if time >= faulty_arrival(i) and gate_opened_early(i):
				canvas.draw_string(FONT, Vector2(140, 380 + 44 * i) * s, "%s: kapı %s s'de açıldı, kızak henüz varmadı" % [String(sleds[i]["name"]), str(snappedf(faulty_arrival(i), 0.1)).replace(".", ",")], HORIZONTAL_ALIGNMENT_LEFT, -1, int(28 * s), DANGER)
