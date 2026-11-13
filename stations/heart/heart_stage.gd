extends Control
## Kalp sahnesi: gerçek 3B kalp, akciğer ve vücut modelleri ve üstünde oyuncunun etkileştiği katman
## (kapakçıklar, akış parçacıkları, damar hatları, tıklanabilir bölgeler).
## Koordinatlar kalp karesine (0–1) göre. Kare dışı değerler (akciğer, vücut) de kullanılabilir.

signal spot_pressed(id: StringName)
signal valve_dropped(slot: int, valve: int)
signal ports_connected(from_port: StringName, to_port: StringName)
signal port_cleared(from_port: StringName)

const Model = preload("res://stations/heart/heart_model.gd")
const HEART_VIEW = preload("res://stations/heart/heart_view.tscn")
const LUNGS = preload("res://assets/models/human-lungs.glb")
const BODY = preload("res://assets/models/human-muscles.glb")

const INK := Color("#e9f1ee")
const MUTED := Color("#8fa6b3")
const JADE := Color("#8ff0d4")
const GOLD := Color("#ffc082")
const RED := Color("#ff6b5e")
const BLOOD_RICH := Color("#ff5a4d")
const BLOOD_POOR := Color("#5f8bff")
const BACK := Color("#070d16")

## Model karesinde ölçülmüş noktalar (viewport içinde normalize).
const SPOTS := {
	&"svc": Vector2(0.372, 0.236),
	&"right_atrium": Vector2(0.368, 0.472),
	&"right_ventricle": Vector2(0.417, 0.694),
	&"pulmonary_artery": Vector2(0.611, 0.299),
	&"pulmonary_veins": Vector2(0.708, 0.364),
	&"left_atrium": Vector2(0.625, 0.431),
	&"left_ventricle": Vector2(0.625, 0.722),
	&"aorta": Vector2(0.514, 0.18),
	&"lungs": Vector2(0.93, 0.30),
	&"body": Vector2(-0.04, 0.64),
}
## Etiket ucu kaymaları (nokta → metin).
const LABEL_OFFSET := {
	&"svc": Vector2(-0.14, -0.02), &"right_atrium": Vector2(-0.20, 0.0),
	&"right_ventricle": Vector2(-0.19, 0.06), &"pulmonary_artery": Vector2(0.17, -0.07),
	&"pulmonary_veins": Vector2(0.14, 0.09), &"left_atrium": Vector2(0.17, 0.0),
	&"left_ventricle": Vector2(0.19, 0.06), &"aorta": Vector2(0.14, -0.04),
	&"lungs": Vector2(0.0, 0.20), &"body": Vector2(0.12, 0.22),
}
const VALVE_POS := {
	Model.Valve.TRICUSPID: Vector2(0.375, 0.556),
	Model.Valve.MITRAL: Vector2(0.614, 0.542),
	Model.Valve.AORTIC: Vector2(0.449, 0.354),
	Model.Valve.PULMONARY: Vector2(0.511, 0.4375),
}
const VALVE_WIDTH := {
	Model.Valve.TRICUSPID: 0.13,
	Model.Valve.MITRAL: 0.12,
	Model.Valve.AORTIC: 0.055,
	Model.Valve.PULMONARY: 0.055,
}
## Akış hatları (kalbin içi). Dış damarlar `connections` ile çizilir.
## Sağ yarı oksijensiz (mavi), sol yarı oksijenli (kırmızı).
const FLOWS := {
	&"ven_in": [Vector2(0.372, 0.17), Vector2(0.372, 0.33), Vector2(0.368, 0.45)],
	&"r_av": [Vector2(0.368, 0.45), Vector2(0.375, 0.556), Vector2(0.41, 0.66)],
	&"r_out": [Vector2(0.46, 0.62), Vector2(0.511, 0.4375), Vector2(0.611, 0.3), Vector2(0.74, 0.292)],
	&"l_in": [Vector2(0.77, 0.364), Vector2(0.66, 0.40), Vector2(0.625, 0.45)],
	&"l_av": [Vector2(0.625, 0.45), Vector2(0.614, 0.542), Vector2(0.625, 0.65)],
	&"l_out": [Vector2(0.6, 0.62), Vector2(0.53, 0.5), Vector2(0.449, 0.354), Vector2(0.5, 0.25), Vector2(0.514, 0.10)],
}
## Dış damar uçları. Çıkışlar (kan bırakır) ve girişler (kan alır). Doğru bağlantılar CORRECT_LINKS.
const OUT_PORTS := {
	&"body_out": Vector2(0.0, 0.47),
	&"pa_out": Vector2(0.74, 0.292),
	&"lungs_out": Vector2(0.965, 0.50),
	&"aorta_out": Vector2(0.514, 0.10),
}
const IN_PORTS := {
	&"svc_in": Vector2(0.372, 0.17),
	&"lungs_in": Vector2(0.965, 0.115),
	&"pv_in": Vector2(0.77, 0.364),
	&"body_in": Vector2(-0.05, 0.40),
}
const PORT_NAMES := {
	&"body_out": "Vücuttan dönen kan", &"pa_out": "Akciğer atardamarı ucu",
	&"lungs_out": "Akciğerden çıkan kan", &"aorta_out": "Aort ucu",
	&"svc_in": "Üst ana toplardamar", &"lungs_in": "Akciğere giriş",
	&"pv_in": "Akciğer toplardamarı", &"body_in": "Vücuda giriş",
}
const PORT_LABEL_OFFSET := {
	&"body_out": Vector2(62, 14), &"pa_out": Vector2(-8, -26), &"lungs_out": Vector2(0, 26), &"aorta_out": Vector2(0, -24),
	&"svc_in": Vector2(-70, -4), &"lungs_in": Vector2(0, -24), &"pv_in": Vector2(-8, 24), &"body_in": Vector2(-8, -24),
}
const PORT_RICH := {&"body_out": false, &"pa_out": false, &"lungs_out": true, &"aorta_out": true}
const CORRECT_LINKS := {&"body_out": &"svc_in", &"pa_out": &"lungs_in", &"lungs_out": &"pv_in", &"aorta_out": &"body_in"}
const FLOW_RICH := [&"l_in", &"l_av", &"l_out"]
const HIT_RADIUS := 0.05

var heart_viewport: SubViewport
var lungs_viewport: SubViewport
var body_viewport: SubViewport
var heart_node: Node3D
var heart_rect := Rect2()

## Görünüm durumu (görev tarafından ayarlanır).
var valve_present: Dictionary = {}
var valve_amount: Dictionary = {}
var valve_target: Dictionary = {}
var valve_marked: Dictionary = {}
var flow_dir: Dictionary = {}
var flow_color_override: Dictionary = {}
var labels: Dictionary = {}
var spots_active: Dictionary = {}
var highlight: StringName = &""
var show_flow := true
var beat := 0.0
## Akış hızı çarpanı (kalp hızına bağlı).
var flow_speed := 1.0
## Dış damar bağlantıları (çıkış → giriş). Varsayılan doğru bağlantı.
var connections: Dictionary = CORRECT_LINKS.duplicate()
var connection_flow := true
var ports_active := false
var port_warning: Dictionary = {}
var _drag_from: StringName = &""
var _drag_pos := Vector2.ZERO
## Doku oksijeni 0–1. Vücut modelinin rengini ve göstergesini belirler.
var body_oxygen := 1.0
var _time := 0.0
var _dust: Array[Vector3] = []
var _glow: GradientTexture2D


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	heart_viewport = _viewport(Vector2i(1080, 1080))
	var view := HEART_VIEW.instantiate()
	heart_viewport.add_child(view)
	heart_node = view.get_node("Heart")
	lungs_viewport = _model_viewport(LUNGS, Vector2i(560, 560), Vector3(0, 8, 0))
	body_viewport = _model_viewport(BODY, Vector2i(640, 900), Vector3.ZERO)
	for valve in Model.VALVE_NAMES:
		valve_present[valve] = true
		valve_amount[valve] = 0.0
		valve_target[valve] = 0.0
	_glow = GradientTexture2D.new()
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.48)
	_glow.fill_to = Vector2(1.0, 0.48)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#1b3149"), Color("#0d1a2a"), BACK])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	_glow.gradient = gradient
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		_dust.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.2, 1.0)))


func _viewport(pixels: Vector2i) -> SubViewport:
	var v := SubViewport.new()
	v.size = pixels
	v.transparent_bg = true
	v.own_world_3d = true
	v.msaa_3d = Viewport.MSAA_4X
	add_child(v)
	return v


func _model_viewport(scene: PackedScene, pixels: Vector2i, rotation_degrees: Vector3) -> SubViewport:
	var v := _viewport(pixels)
	var root := Node3D.new()
	v.add_child(root)
	var model: Node3D = scene.instantiate()
	root.add_child(model)
	var box := _bounds(model)
	var scale_factor := 1.0 / maxf(box.size.y, box.size.x * 0.8)
	model.scale = Vector3.ONE * scale_factor
	model.rotation_degrees = rotation_degrees
	model.position = -box.get_center() * scale_factor
	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0, 0, 2.4)
	root.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 28, 0)
	key.light_color = Color(1, 0.93, 0.84)
	key.light_energy = 1.3
	root.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_color = Color(0.55, 0.78, 1)
	rim.light_energy = 0.9
	root.add_child(rim)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.36, 0.43, 0.55)
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	return v


func _bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if current is MeshInstance3D:
			var local: AABB = (current as MeshInstance3D).get_aabb()
			box = local if first else box.merge(local)
			first = false
	return box


func _process(delta: float) -> void:
	_time += delta
	for valve in valve_amount:
		valve_amount[valve] = move_toward(valve_amount[valve], valve_target[valve], delta * 5.0)
	if heart_node != null:
		var s := 1.0 + 0.022 * beat
		heart_node.scale = Vector3.ONE * s
		heart_node.position = Vector3(0, 0.065 * (1.0 - s), 0)
	queue_redraw()


func _layout() -> void:
	## Kompozisyon (vücut, kalp, akciğer) u = -0.30 … 1.13 aralığını kaplar, tamamı sahneye sığar.
	var side := minf(size.x / 1.50, size.y * 0.98)
	heart_rect = Rect2(Vector2(size.x * 0.5 - 0.415 * side, (size.y - side) * 0.5), Vector2(side, side))


func to_px(normalized: Vector2) -> Vector2:
	return heart_rect.position + normalized * heart_rect.size


func _draw() -> void:
	_layout()
	_draw_backdrop()
	_draw_pipes()
	_draw_model_panels()
	draw_texture_rect(heart_viewport.get_texture(), heart_rect, false)
	if show_flow:
		_draw_flows()
		if connection_flow:
			_draw_connection_flows()
	if ports_active:
		_draw_ports()
	for valve in VALVE_POS:
		if valve_present.get(valve, false):
			_draw_valve(valve)
		else:
			_draw_socket(valve)
	for id in spots_active:
		if spots_active[id] and SPOTS.has(id):
			_draw_spot(id)
	for id in labels:
		_draw_label(id, labels[id])
	_draw_vignette()


func _draw_backdrop() -> void:
	draw_texture_rect(_glow, Rect2(Vector2.ZERO, size), false)
	var center := to_px(Vector2(0.5, 0.48))
	for i in 3:
		var radius := heart_rect.size.x * (0.40 + 0.14 * i)
		draw_arc(center, radius, 0.0, TAU, 96, Color("#2a4a66", 0.30 - 0.07 * i), 1.2, true)
	for i in 72:
		var angle := float(i) / 72.0 * TAU
		var inner := heart_rect.size.x * 0.54
		var outer := inner + heart_rect.size.x * (0.026 if i % 6 == 0 else 0.012)
		draw_line(center + Vector2.from_angle(angle) * inner, center + Vector2.from_angle(angle) * outer, Color("#2a4a66", 0.5), 1.0, true)
	for d in _dust:
		var x := fposmod(d.x + _time * 0.006 * d.z, 1.0) * size.x
		var y := fposmod(d.y - _time * 0.012 * d.z, 1.0) * size.y
		draw_circle(Vector2(x, y), 1.0 + d.z * 1.2, Color("#9fc4e8", 0.10 + 0.18 * d.z), true, -1.0, true)


func _draw_vignette() -> void:
	var edge := Color(BACK, 0.0)
	var dark := Color(BACK, 0.85)
	var band := size.x * 0.10
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(band, 0), Vector2(band, size.y), Vector2(0, size.y)]),
		PackedColorArray([dark, edge, edge, dark]))
	draw_polygon(PackedVector2Array([Vector2(size.x, 0), Vector2(size.x - band, 0), Vector2(size.x - band, size.y), Vector2(size.x, size.y)]),
		PackedColorArray([dark, edge, edge, dark]))
	var top := size.y * 0.12
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, top), Vector2(0, top)]),
		PackedColorArray([dark, dark, edge, edge]))
	draw_polygon(PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y), Vector2(size.x, size.y - top), Vector2(0, size.y - top)]),
		PackedColorArray([dark, dark, edge, edge]))


func _link_points(from_port: StringName, to_port: StringName) -> PackedVector2Array:
	var p0 := to_px(OUT_PORTS[from_port])
	var p1 := to_px(IN_PORTS[to_port])
	var lift := heart_rect.size.x * 0.16
	var c0 := p0 + Vector2(0, -lift)
	var c1 := p1 + Vector2(0, -lift)
	var points := PackedVector2Array()
	for i in 41:
		var t := float(i) / 40.0
		var q := p0 * pow(1 - t, 3) + c0 * 3 * pow(1 - t, 2) * t + c1 * 3 * (1 - t) * t * t + p1 * pow(t, 3)
		points.append(q)
	return points


func _draw_pipes() -> void:
	for from_port in connections:
		var to_port: StringName = connections[from_port]
		var points := _link_points(from_port, to_port)
		var rich: bool = PORT_RICH[from_port]
		var warn: bool = port_warning.get(from_port, false)
		var color: Color = (BLOOD_RICH if rich else BLOOD_POOR)
		if warn:
			color = GOLD
		draw_polyline(points, Color(color, 0.10), heart_rect.size.x * 0.032, true)
		draw_polyline(points, Color(color, 0.24), heart_rect.size.x * 0.017, true)
		draw_polyline(points, Color(INK, 0.12), 1.2, true)
	if _drag_from != &"":
		var p0 := to_px(OUT_PORTS[_drag_from])
		draw_line(p0, _drag_pos, Color(GOLD, 0.35), 8.0, true)
		draw_line(p0, _drag_pos, GOLD, 2.4, true)


func _draw_ports() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	for id in OUT_PORTS:
		var rich: bool = PORT_RICH[id]
		var c := BLOOD_RICH if rich else BLOOD_POOR
		var center := to_px(OUT_PORTS[id])
		draw_circle(center, 13.0 + 2.0 * pulse, Color(c, 0.18), true, -1.0, true)
		draw_arc(center, 10.0, 0.0, TAU, 24, c, 2.4, true)
		draw_circle(center, 4.0, c, true, -1.0, true)
	for id in IN_PORTS:
		var center := to_px(IN_PORTS[id])
		var taken := connections.values().has(id)
		draw_arc(center, 10.0, 0.0, TAU, 24, Color(JADE, 0.9 if not taken else 0.4), 2.4, true)
		draw_circle(center, 3.5, Color(JADE, 0.9 if not taken else 0.4), true, -1.0, true)
	for id in OUT_PORTS:
		_port_pill(to_px(OUT_PORTS[id]) + PORT_LABEL_OFFSET[id], PORT_NAMES[id], INK)
	for id in IN_PORTS:
		_port_pill(to_px(IN_PORTS[id]) + PORT_LABEL_OFFSET[id], PORT_NAMES[id], JADE)


func _port_pill(center: Vector2, value: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(BACK, 0.9)
	box.border_color = Color(color, 0.5)
	box.set_border_width_all(1)
	box.set_corner_radius_all(9)
	var rect := Rect2(center - Vector2(text_size.x * 0.5 + 7.0, 9.0), Vector2(text_size.x + 14.0, 18.0))
	draw_style_box(box, rect)
	draw_string(font, Vector2(rect.position.x + 7.0, rect.position.y + 13.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)


func _draw_model_panels() -> void:
	var s := heart_rect.size.x
	var lungs_rect := Rect2(to_px(Vector2(0.80, 0.14)), Vector2(s * 0.33, s * 0.33))
	var body_rect := Rect2(to_px(Vector2(-0.30, 0.28)), Vector2(s * 0.47, s * 0.66))
	var tint := Color(0.55, 0.62, 0.95).lerp(Color.WHITE, clampf(body_oxygen, 0.0, 1.0))
	tint = tint.darkened((1.0 - body_oxygen) * 0.35)
	draw_texture_rect(lungs_viewport.get_texture(), lungs_rect, false)
	draw_texture_rect(body_viewport.get_texture(), body_rect, false, tint)
	# Oksijen göstergesi
	var gauge := Rect2(body_rect.position + Vector2(body_rect.size.x * 0.22, body_rect.size.y * 0.03), Vector2(body_rect.size.x * 0.56, 7.0))
	draw_rect(gauge, Color("#1b2c3f"))
	var fill_color := JADE if body_oxygen > 0.66 else (GOLD if body_oxygen > 0.33 else RED)
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * clampf(body_oxygen, 0.0, 1.0), gauge.size.y)), fill_color)
	var f := ThemeDB.fallback_font
	draw_string(f, gauge.position + Vector2(0, 22), "Doku oksijeni  %d%%" % roundi(body_oxygen * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, INK)


func _draw_flows() -> void:
	var unit := heart_rect.size.x
	for key in FLOWS:
		var direction: float = flow_dir.get(key, 0.0)
		if direction == 0.0:
			continue
		var points := PackedVector2Array()
		for p in FLOWS[key]:
			points.append(to_px(p))
		var color: Color = flow_color_override.get(key, BLOOD_RICH if key in FLOW_RICH else BLOOD_POOR)
		var length := _polyline_length(points)
		var count := int(length / (unit * 0.05)) + 2
		for i in count:
			var t := fposmod(float(i) / count + _time * 0.5 * direction * flow_speed, 1.0)
			var point := _point_along(points, t * length)
			var fade := sin(t * PI)
			draw_circle(point, unit * 0.022, Color(color, 0.20 * fade), true, -1.0, true)
			draw_circle(point, unit * 0.011, Color(color, 0.95 * fade), true, -1.0, true)
			draw_circle(point, unit * 0.0045, Color(1, 1, 1, 0.9 * fade), true, -1.0, true)


func _draw_connection_flows() -> void:
	var unit := heart_rect.size.x
	for from_port in connections:
		var to_port: StringName = connections[from_port]
		var points := _link_points(from_port, to_port)
		var rich: bool = PORT_RICH[from_port]
		var color := GOLD if port_warning.get(from_port, false) else (BLOOD_RICH if rich else BLOOD_POOR)
		var length := _polyline_length(points)
		var count := int(length / (unit * 0.05)) + 2
		for i in count:
			var t := fposmod(float(i) / count + _time * 0.45 * flow_speed, 1.0)
			var point := _point_along(points, t * length)
			var fade := sin(t * PI)
			draw_circle(point, unit * 0.020, Color(color, 0.20 * fade), true, -1.0, true)
			draw_circle(point, unit * 0.010, Color(color, 0.95 * fade), true, -1.0, true)
			draw_circle(point, unit * 0.004, Color(1, 1, 1, 0.9 * fade), true, -1.0, true)


func _polyline_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	return total


func _point_along(points: PackedVector2Array, distance: float) -> Vector2:
	var remaining := distance
	for i in points.size() - 1:
		var seg := points[i].distance_to(points[i + 1])
		if remaining <= seg:
			return points[i].lerp(points[i + 1], remaining / maxf(seg, 0.001))
		remaining -= seg
	return points[points.size() - 1]


func _draw_valve(valve: int) -> void:
	var center := to_px(VALVE_POS[valve])
	var half: float = VALVE_WIDTH[valve] * heart_rect.size.x * 0.5
	var amount: float = valve_amount.get(valve, 0.0)
	var downstream := Vector2(0, 1)
	var across := Vector2(1, 0)
	if valve == Model.Valve.AORTIC:
		downstream = Vector2(0.55, -0.83)
		across = Vector2(0.83, 0.55)
	elif valve == Model.Valve.PULMONARY:
		downstream = Vector2(0.45, -0.89)
		across = Vector2(0.89, 0.45)
	elif valve == Model.Valve.MITRAL or valve == Model.Valve.TRICUSPID:
		downstream = Vector2(0, 1)
	var marked: bool = valve_marked.get(valve, false)
	var color := RED if marked else JADE
	for side in [-1.0, 1.0]:
		var root: Vector2 = center + across * half * side
		var tip: Vector2 = center + across * half * side * (0.06 + amount * 0.78) + downstream * half * (0.05 + amount * 1.0)
		var mid: Vector2 = (root + tip) * 0.5 + downstream * half * 0.22
		var curve := PackedVector2Array([root, root.lerp(mid, 0.6), mid, mid.lerp(tip, 0.6), tip])
		draw_polyline(curve, Color(BACK, 0.75), 9.0, true)
		draw_polyline(curve, Color(color, 0.28), 12.0, true)
		draw_polyline(curve, color, 4.0, true)
		draw_circle(root, 4.5, color, true, -1.0, true)
		draw_circle(root, 2.0, BACK, true, -1.0, true)
	if marked:
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		draw_arc(center, half * (1.5 + 0.15 * pulse), 0.0, TAU, 48, Color(RED, 0.9), 2.4, true)


func _draw_socket(valve: int) -> void:
	var center := to_px(VALVE_POS[valve])
	var radius: float = VALVE_WIDTH[valve] * heart_rect.size.x * 0.62
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(center, radius, Color(GOLD, 0.06 + 0.06 * pulse), true, -1.0, true)
	draw_arc(center, radius, 0.0, TAU, 40, Color(GOLD, 0.55 + 0.4 * pulse), 2.4, true)
	for i in 8:
		var a := float(i) * TAU / 8.0 + _time * 0.4
		draw_arc(center, radius * 1.2, a, a + 0.22, 6, Color(GOLD, 0.6), 2.0, true)


func _draw_spot(id: StringName) -> void:
	var center := to_px(SPOTS[id])
	var radius := HIT_RADIUS * heart_rect.size.x
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var active := highlight == id
	var color := JADE if active else MUTED
	draw_arc(center, radius * (0.88 + 0.12 * pulse), 0.0, TAU, 40, Color(color, (0.4 + 0.5 * pulse) if active else 0.28), 2.0, true)
	if active:
		draw_circle(center, radius * 0.9, Color(JADE, 0.05 + 0.05 * pulse), true, -1.0, true)


func _draw_label(id: Variant, text: String) -> void:
	var anchor: Vector2
	var offset := Vector2(0.14, -0.04)
	if id is StringName and SPOTS.has(id):
		anchor = to_px(SPOTS[id])
		offset = LABEL_OFFSET.get(id, offset)
	elif id is int and VALVE_POS.has(id):
		anchor = to_px(VALVE_POS[id])
		offset = Vector2(0.0, -0.09)
	else:
		return
	var end := anchor + offset * heart_rect.size.x
	draw_line(anchor, end, Color(JADE, 0.35), 3.0, true)
	draw_line(anchor, end, JADE, 1.2, true)
	draw_circle(anchor, 4.0, JADE, true, -1.0, true)
	draw_circle(anchor, 7.0, Color(JADE, 0.25), true, -1.0, true)
	_pill(end, text, JADE)


func _gui_input(event: InputEvent) -> void:
	if ports_active:
		_ports_input(event)
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var position: Vector2 = (event as InputEventMouseButton).position
	var best: StringName = &""
	var best_distance := HIT_RADIUS * heart_rect.size.x
	for id in SPOTS:
		if not spots_active.get(id, false):
			continue
		var d := to_px(SPOTS[id]).distance_to(position)
		if d < best_distance:
			best_distance = d
			best = id
	for valve in VALVE_POS:
		var key := StringName("valve_%d" % valve)
		if not spots_active.get(key, false):
			continue
		var d := to_px(VALVE_POS[valve]).distance_to(position)
		if d < best_distance:
			best_distance = d
			best = key
	if best != &"":
		spot_pressed.emit(best)


func _ports_input(event: InputEvent) -> void:
	var reach := 22.0
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var position: Vector2 = (event as InputEventMouseButton).position
		if event.pressed:
			for id in OUT_PORTS:
				if to_px(OUT_PORTS[id]).distance_to(position) <= reach:
					if connections.has(id):
						connections.erase(id)
						port_cleared.emit(id)
					_drag_from = id
					_drag_pos = position
					return
		elif _drag_from != &"":
			var target: StringName = &""
			var best := reach * 1.6
			for id in IN_PORTS:
				var d := to_px(IN_PORTS[id]).distance_to(position)
				if d < best:
					best = d
					target = id
			var source := _drag_from
			_drag_from = &""
			if target != &"":
				ports_connected.emit(source, target)
	elif event is InputEventMouseMotion and _drag_from != &"":
		_drag_pos = (event as InputEventMouseMotion).position


func _slot_at(position: Vector2) -> int:
	var best := -1
	var best_distance := heart_rect.size.x * 0.09
	for valve in VALVE_POS:
		var d := to_px(VALVE_POS[valve]).distance_to(position)
		if d < best_distance:
			best_distance = d
			best = valve
	return best


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("valve") and _slot_at(at_position) >= 0


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var slot := _slot_at(at_position)
	if slot >= 0:
		valve_dropped.emit(slot, data["valve"])


func set_valves_for_phase(phase: int) -> void:
	for valve in Model.VALVE_NAMES:
		valve_target[valve] = 1.0 if Model.is_open(valve, phase) else 0.0


func _pill(center: Vector2, value: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(BACK, 0.92)
	box.border_color = color
	box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	var rect := Rect2(center - Vector2(text_size.x * 0.5 + 10.0, 12.0), Vector2(text_size.x + 20.0, 24.0))
	draw_style_box(box, rect)
	draw_string(font, Vector2(rect.position.x + 10.0, rect.position.y + 17.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, INK)
