extends Control

const INK := Color("#e9f1ee")
const MUTED := Color("#a0b5bf")
const JADE := Color("#77dfba")
const SKY := Color("#80b8e5")
const GOLD := Color("#ffc082")
const GRID := Color("#182a39")
const GRID_MAJOR := Color("#27404f")
const BACK := Color("#101f30")

var HARBOR_TEX: Texture2D = load("res://stations/vectors/assets/harbor_top.png")
var CAPSULE_TEX: Texture2D = load("res://stations/vectors/assets/capsule_top.png")
var CAPSULE_THRUST_TEX: Texture2D = load("res://stations/vectors/assets/capsule_thrust.png")
var DOCK_OFF_TEX: Texture2D = load("res://stations/vectors/assets/dock_ring_off.png")
var DOCK_ON_TEX: Texture2D = load("res://stations/vectors/assets/dock_ring_on.png")

var route_stage := 0
var method := 0
var capsule := Vector2.ZERO
var route_draw := 0.0
var revealed := false
var attempted := false
var attempt := Vector2.ZERO
var docked := false
var in_motion := false

var _origin: Vector2
var _unit: float


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	if HARBOR_TEX != null:
		draw_texture_rect(HARBOR_TEX, Rect2(Vector2.ZERO, size), false)
	_draw_deck_outline()

	var inspecting := route_stage == 1
	var target := Vector2(5, -12) if route_stage == 2 else Vector2(3, 4)
	var east := Vector2(target.x, 0)
	var grid_vertical_extent := 7 if route_stage < 2 else 15
	_unit = minf((size.x - 88) / 23.0, (size.y - 80) / (2.0 * grid_vertical_extent))
	_origin = size * 0.5 + Vector2(-8, 8)

	var x_extent := int((size.x * 0.5 - 26) / _unit)
	var y_extent := int((size.y * 0.5 - 30) / _unit)
	_draw_grid(x_extent, y_extent, 1 if route_stage < 2 else 3)

	var start := _point(Vector2.ZERO)
	var end := _point(target)
	_draw_dock(end, docked)

	if route_stage == 0:
		_dashed(start, end, JADE.darkened(0.49))
		_arrow(start, _point(Vector2(7, 0)), GOLD, 3.0)
		_chip(_point(Vector2(3.5, 0)) + Vector2(0, 30), "7 birim doğu", GOLD)
	elif inspecting:
		if method == 0:
			_arrow(start, _point(east), JADE, 3.0)
			_arrow(_point(east), end, SKY, 3.0)
			_right_angle(_point(east), Vector2(-1, 0), Vector2(0, -1), MUTED)
			_chip(_point(east * 0.5) + Vector2(0, 30), "3 doğu", JADE)
			_chip(_point(Vector2(3, 2)) + Vector2(48, 0), "4 kuzey", SKY)
		else:
			var north := Vector2(0, target.y)
			_arrow(start, _point(east), JADE, 3.0)
			_arrow(start, _point(north), SKY, 3.0)
			_dashed(_point(east), end, SKY.darkened(0.19))
			_dashed(_point(north), end, JADE.darkened(0.19))
			_chip(_point(east * 0.5) + Vector2(0, 30), "3 doğu", JADE)
			_chip(_point(north * 0.5) + Vector2(-48, 0), "4 kuzey", SKY)
		if route_draw > 0.0:
			_arrow(start, _point(target * route_draw), GOLD, 3.4)
		if revealed:
			_chip(_point(target * 0.5) + Vector2(-44, -14), "5 birim", GOLD)
			_chip(end + Vector2(46, -22), "(3, 4)", GOLD)
	elif attempted:
		_arrow(start, _point(attempt), JADE if docked else GOLD, 3.2)

	_draw_capsule(_point(capsule), docked)


func _draw_deck_outline() -> void:
	var edge := Color("#263b4a")
	var shell := PackedVector2Array([
		Vector2(13, size.y * 0.30), Vector2(13, 32), Vector2(32, 13),
		Vector2(size.x - 32, 13), Vector2(size.x - 13, 32), Vector2(size.x - 13, size.y * 0.30)
	])
	draw_polyline(shell, edge, 1.2, true)
	draw_line(Vector2(13, size.y - 13), Vector2(size.x - 13, size.y - 13), edge, 1.2, true)
	for index in 5:
		var x := size.x - 31 - float(index) * 8.0
		draw_line(Vector2(x, size.y - 18), Vector2(x, size.y - 24), edge, 1.0, true)


func _draw_grid(x_extent: int, y_extent: int, label_step: int) -> void:
	for x in range(-x_extent, x_extent + 1):
		if x == 0:
			continue
		var top := _point(Vector2(x, y_extent))
		var bottom := _point(Vector2(x, -y_extent))
		draw_line(top, bottom, GRID_MAJOR if x % label_step == 0 else GRID, 1.0, true)
		if x % label_step == 0:
			_label(_point(Vector2(x, 0)) + Vector2(-7, 18), str(x), MUTED.darkened(0.23), 11)

	for y in range(-y_extent, y_extent + 1):
		if y == 0:
			continue
		var left := _point(Vector2(-x_extent, y))
		var right := _point(Vector2(x_extent, y))
		draw_line(left, right, GRID_MAJOR if y % label_step == 0 else GRID, 1.0, true)
		if y % label_step == 0:
			_label(_point(Vector2(0, y)) + Vector2(-25, 4), str(y), MUTED.darkened(0.23), 11)

	_arrow(_point(Vector2(-x_extent, 0)), _point(Vector2(x_extent, 0)), MUTED.darkened(0.22), 1.3)
	_arrow(_point(Vector2(0, -y_extent)), _point(Vector2(0, y_extent)), MUTED.darkened(0.22), 1.3)
	_label(_point(Vector2(x_extent, 0)) + Vector2(-42, -12), "Doğu", INK, 12)
	_label(_point(Vector2(0, y_extent)) + Vector2(11, 8), "Kuzey", INK, 12)
	_label(_point(Vector2(0, -y_extent)) + Vector2(11, 4), "Güney", INK, 12)


func _draw_dock(center: Vector2, active: bool) -> void:
	var tex: Texture2D = DOCK_ON_TEX if active else DOCK_OFF_TEX
	if tex != null:
		var d_size := Vector2(56, 56)
		draw_texture_rect(tex, Rect2(center - d_size * 0.5, d_size), false)
	else:
		var color := JADE if active else MUTED
		draw_circle(center, 20.0, color.darkened(0.86), true, -1.0, true)
		draw_arc(center, 18.0, 0.0, TAU, 32, color.darkened(0.23), 1.2, true)
		for quarter in 4:
			var start := float(quarter) * TAU / 4.0 + 0.13
			draw_arc(center, 23.5, start, start + 0.39, 8, color, 1.5, true)
	var label_color: Color = JADE if active else MUTED
	_label(center + Vector2(32, 6), "Yanaşma", label_color, 12)


func _draw_capsule(center: Vector2, active: bool) -> void:
	var tex: Texture2D = CAPSULE_THRUST_TEX if in_motion else CAPSULE_TEX
	if tex != null:
		var c_size := Vector2(64, 64)
		draw_texture_rect(tex, Rect2(center - c_size * 0.5, c_size), false)
	else:
		var color := JADE if active else INK
		var k := 1.9
		var body := PackedVector2Array([
			center + Vector2(14, 0) * k, center + Vector2(4, -7) * k, center + Vector2(-9, -7) * k,
			center + Vector2(-13, -3) * k, center + Vector2(-13, 3) * k, center + Vector2(-9, 7) * k,
			center + Vector2(4, 7) * k
		])
		draw_circle(center, 22.0 * k, Color(color, 0.08), true, -1.0, true)
		draw_colored_polygon(body, Color("#4a6477"))
		# Üst yarı aydınlık, alt yarı gölge: gövdeye hacim verir.
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(14, 0) * k, center + Vector2(4, -7) * k, center + Vector2(-9, -7) * k,
			center + Vector2(-13, -3) * k, center + Vector2(-13, 0) * k,
		]), Color("#6f8ba0"))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-13, 0) * k, center + Vector2(-13, 3) * k, center + Vector2(-9, 7) * k,
			center + Vector2(4, 7) * k, center + Vector2(14, 0) * k,
		]), Color("#2b3f4f"))
		body.append(body[0])
		draw_polyline(body, color, 1.8, true)
		draw_line(center + Vector2(-3, -7) * k, center + Vector2(-3, 7) * k, Color("#1b2a36"), 1.4, true)
		draw_circle(center + Vector2(5, 0) * k, 2.6 * k, Color("#0c1520"), true, -1.0, true)
		draw_circle(center + Vector2(5, 0) * k, 1.5 * k, color, true, -1.0, true)
		for side in [-1.0, 1.0]:
			draw_line(center + Vector2(-16, 3.2 * side) * k, center + Vector2(-26, 3.2 * side) * k, Color(GOLD, 0.35), 5.0, true)
			draw_line(center + Vector2(-16, 3.2 * side) * k, center + Vector2(-26, 3.2 * side) * k, GOLD, 1.8, true)


func _point(point: Vector2) -> Vector2:
	return _origin + Vector2(point.x, -point.y) * _unit


func _arrow(start: Vector2, end: Vector2, color: Color, width: float) -> void:
	if start.distance_squared_to(end) < 4.0:
		return
	var thin := width < 2.0
	var line_width := width if thin else width * 1.7
	var direction := (end - start).normalized()
	var head_length := minf(8.0 if thin else 18.0, start.distance_to(end) * 0.45)
	var base := end - direction * head_length * 0.85
	if not thin:
		draw_line(start, base, Color(color, 0.16), line_width * 3.4, true)
		draw_line(start, base, Color(color, 0.30), line_width * 1.9, true)
	draw_line(start, base, color, line_width, true)
	var normal := direction.orthogonal() * head_length * 0.46
	draw_colored_polygon(PackedVector2Array([end, base + normal, base - normal]), color)
	if not thin:
		draw_circle(start, line_width * 0.95, color, true, -1.0, true)


func _dashed(start: Vector2, end: Vector2, color: Color) -> void:
	var distance := start.distance_to(end)
	var direction := start.direction_to(end)
	for offset in range(0, int(distance), 12):
		draw_line(start + direction * offset, start + direction * minf(offset + 6, distance), color, 1.8, true)


func _label(position: Vector2, value: String, color: Color, font_size: int = 14) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


## Değer etiketi: koyu zeminli, renkli kenarlı kutucuk. `center` kutunun merkezidir.
func _chip(center: Vector2, value: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(BACK, 0.94)
	box.border_color = color
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	var rect := Rect2(center - Vector2(text_size.x * 0.5 + 9.0, 14.0), Vector2(text_size.x + 18.0, 28.0))
	draw_style_box(box, rect)
	draw_string(font, Vector2(rect.position.x + 9.0, rect.position.y + 20.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, color)


func _right_angle(corner: Vector2, along: Vector2, up: Vector2, color: Color) -> void:
	var a := corner + along.normalized() * 12.0
	var c := corner + up.normalized() * 12.0
	draw_polyline(PackedVector2Array([a, a + (c - corner), c]), color, 1.6, true)
