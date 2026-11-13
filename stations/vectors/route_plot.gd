extends Control

const INK := Color("#e9f1ee")
const MUTED := Color("#a0b5bf")
const JADE := Color("#77dfba")
const SKY := Color("#80b8e5")
const GOLD := Color("#ffc082")
const GRID := Color("#22394a")
const GRID_MAJOR := Color("#344d5f")
const BACK := Color("#101f30")

var route_stage := 0
var method := 0
var capsule := Vector2.ZERO
var route_draw := 0.0
var revealed := false
var attempted := false
var attempt := Vector2.ZERO
var docked := false

var _origin: Vector2
var _unit: float


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
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
		_arrow(start, _point(Vector2(7, 0)), GOLD, 2.6)
		_label(_point(Vector2(7, 0)) + Vector2(-15, 26), "7 birim doğu", GOLD)
	elif inspecting:
		if method == 0:
			_arrow(start, _point(east), JADE, 3.0)
			_arrow(_point(east), end, SKY, 3.0)
			_label(_point(east * 0.48) + Vector2(-17, 35), "3 doğu", JADE)
			_label(_point(Vector2(3, 2)) + Vector2(13, 5), "4 kuzey", SKY)
		else:
			var north := Vector2(0, target.y)
			_arrow(start, _point(east), JADE, 3.0)
			_arrow(start, _point(north), SKY, 3.0)
			_dashed(_point(east), end, SKY.darkened(0.19))
			_dashed(_point(north), end, JADE.darkened(0.19))
			_label(_point(east * 0.48) + Vector2(-17, 35), "3 doğu", JADE)
			_label(_point(north * 0.50) + Vector2(14, -6), "4 kuzey", SKY)
		if route_draw > 0.0:
			_arrow(start, _point(target * route_draw), GOLD, 3.0)
		if revealed:
			_label(end + Vector2(15, -11), "(3, 4)", GOLD)
	elif attempted:
		_arrow(start, _point(attempt), JADE if docked else GOLD, 2.4)

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
	var color := JADE if active else MUTED
	draw_circle(center, 20.0, color.darkened(0.86), true, -1.0, true)
	draw_arc(center, 18.0, 0.0, TAU, 32, color.darkened(0.23), 1.2, true)
	for quarter in 4:
		var start := float(quarter) * TAU / 4.0 + 0.13
		draw_arc(center, 23.5, start, start + 0.39, 8, color, 1.5, true)
	_label(center + Vector2(28, 6), "Yanaşma", color, 12)


func _draw_capsule(center: Vector2, active: bool) -> void:
	var color := JADE if active else INK
	var body := PackedVector2Array([
		center + Vector2(14, 0), center + Vector2(4, -7), center + Vector2(-9, -7),
		center + Vector2(-13, -3), center + Vector2(-13, 3), center + Vector2(-9, 7),
		center + Vector2(4, 7)
	])
	draw_colored_polygon(body, Color("#364d5e"))
	body.append(body[0])
	draw_polyline(body, color, 1.5, true)
	draw_circle(center + Vector2(2, 0), 2.0, color, true, -1.0, true)
	draw_line(center + Vector2(-16, -2), center + Vector2(-21, -2), SKY, 1.4, true)
	draw_line(center + Vector2(-16, 2), center + Vector2(-21, 2), SKY, 1.4, true)


func _point(point: Vector2) -> Vector2:
	return _origin + Vector2(point.x, -point.y) * _unit


func _arrow(start: Vector2, end: Vector2, color: Color, width: float) -> void:
	if start.distance_squared_to(end) < 4.0:
		return
	var direction := (end - start).normalized()
	var head_length := minf(9.0, start.distance_to(end) * 0.30)
	var base := end - direction * head_length
	draw_line(start, base, color, width, true)
	var normal := direction.orthogonal() * head_length * 0.42
	draw_colored_polygon(PackedVector2Array([end, base + normal, base - normal]), color)


func _dashed(start: Vector2, end: Vector2, color: Color) -> void:
	var distance := start.distance_to(end)
	var direction := start.direction_to(end)
	for offset in range(0, int(distance), 10):
		draw_line(start + direction * offset, start + direction * minf(offset + 5, distance), color, 1.5, true)


func _label(position: Vector2, value: String, color: Color, font_size: int = 14) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
