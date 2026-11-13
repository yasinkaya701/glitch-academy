extends Control

const INK := Color("#c8dbd6")
const MINT := Color("#7ae2bf")
const AMBER := Color("#ffad81")
const STEEL := Color("#2c4447")
const RAIL := Color("#577371")
const DRAW_SIZE := Vector2(620, 412)

var instrument := &"fault"
var measured := false
var motion := 0.0
var test_state := &"fault"


func show_state(kind: StringName, reading: bool, progress: float, state: StringName) -> void:
	instrument = kind
	measured = reading
	motion = progress
	test_state = state
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var factor := minf(size.x / DRAW_SIZE.x, size.y / DRAW_SIZE.y)
	if factor <= 0.0:
		return
	draw_set_transform((size - DRAW_SIZE * factor) * 0.5, 0.0, Vector2.ONE * factor)
	var rail_start := Vector2(96, 286)
	var rail_end := Vector2(524, 286)
	_draw_grid()
	_draw_rail(rail_start, rail_end)
	_draw_coupler(rail_start, rail_end)
	var cart_range := 0.27 if test_state == &"fault" else 0.73
	_draw_cart(rail_start.lerp(rail_end, 0.12 + motion * cart_range))
	_draw_console()
	match instrument:
		&"length":
			_draw_ruler(180)
		&"mass":
			_draw_scale()
		&"time":
			_draw_timer()
		&"guided", &"speed", &"running", &"complete":
			_draw_speed()


func _draw_grid() -> void:
	var faint := Color(0.56, 0.78, 0.73, 0.1)
	for x in range(28, 613, 18):
		for y in range(25, 390, 18):
			draw_circle(Vector2(x, y), 0.9, faint)
	var top := Color("#203237")
	var edge := Color("#14242a")
	_draw_polygon(PackedVector2Array([Vector2(52, 250), Vector2(568, 250), Vector2(595, 330), Vector2(25, 330)]), top)
	_draw_polygon(PackedVector2Array([Vector2(25, 330), Vector2(595, 330), Vector2(595, 349), Vector2(25, 349)]), edge)
	draw_line(Vector2(25, 330), Vector2(595, 330), STEEL, 2.0, true)


func _draw_rail(start: Vector2, end: Vector2) -> void:
	for x in range(int(start.x), int(end.x) + 1, 19):
		draw_line(Vector2(x, 270), Vector2(x, 309), Color("#30474a"), 4.0, true)
	for y in [279.0, 300.0]:
		draw_line(Vector2(start.x, y + 3), Vector2(end.x, y + 3), Color("#15252a"), 7.0, true)
		draw_line(Vector2(start.x, y), Vector2(end.x, y), RAIL, 4.0, true)
		for cap in [start.x, end.x]:
			draw_line(Vector2(cap, y - 6), Vector2(cap, y + 7), INK, 2.0, true)


func _draw_coupler(start: Vector2, end: Vector2) -> void:
	var middle := start.lerp(end, 0.52)
	var connector := Rect2(middle.x - 18, 276, 36, 27)
	draw_rect(connector, Color("#101c20"))
	var connected := test_state == &"connected" or test_state == &"complete"
	if connected:
		draw_rect(connector.grow(-3), Color("#214b43"))
		draw_line(Vector2(connector.position.x, 279), Vector2(connector.end.x, 279), MINT, 3.0, true)
		draw_line(Vector2(connector.position.x, 300), Vector2(connector.end.x, 300), MINT, 3.0, true)
		return
	var too_long := test_state == &"fault" or test_state == &"too_long"
	var too_short := test_state == &"too_short"
	var bad := too_long or too_short
	var shift := -44.0 + 35.0 * motion if test_state == &"fault" else -42.0
	var part := connector
	part.position.y += shift
	if too_long:
		part.position.x -= 30.0
		part.size.x += 60.0
	elif too_short:
		part.position.x += 8.0
		part.size.x -= 16.0
	draw_rect(part, Color("#57362b") if bad else Color("#345650"))
	draw_rect(part, AMBER if bad else MINT, false, 1.5)
	for x in [part.position.x + 7, part.end.x - 7]:
		draw_circle(Vector2(x, part.get_center().y), 2.0, AMBER if bad else MINT)
	if bad:
		draw_line(Vector2(middle.x - 5, 284), Vector2(middle.x + 5, 295), AMBER, 2.0, true)
		draw_line(Vector2(middle.x + 5, 284), Vector2(middle.x - 5, 295), AMBER, 2.0, true)


func _draw_cart(position: Vector2) -> void:
	var shadow := Rect2(position.x - 35, 276, 70, 25)
	draw_rect(shadow, Color("#0a1318"))
	for side in [-1, 1]:
		for row in [277.0, 299.0]:
			draw_circle(Vector2(position.x + side * 23, row), 5.0, Color("#131f24"))
	var corners := PackedVector2Array([Vector2(-32, -16), Vector2(31, -16), Vector2(34, 2), Vector2(-29, 2)])
	for index in range(corners.size()):
		corners[index] += position
	_draw_polygon(corners, Color("#4c6b68"))
	draw_line(position + Vector2(-28, -15), position + Vector2(25, -15), INK, 1.0, true)
	draw_rect(Rect2(position.x - 15, position.y - 12, 27, 9), Color("#243b3f"))
	var status_color := MINT if test_state == &"connected" or test_state == &"complete" else AMBER
	draw_circle(position + Vector2(26, -6), 2.7, status_color, true, -1.0, true)


func _draw_console() -> void:
	var console := Rect2(131, 58, 358, 139)
	draw_rect(console, Color("#101f26"))
	draw_rect(console, STEEL, false, 1.5)
	for x in [console.position.x + 8, console.end.x - 8]:
		for y in [console.position.y + 8, console.end.y - 8]:
			draw_circle(Vector2(x, y), 1.6, RAIL)
	if instrument == &"fault":
		_center_text("240 cm → 240 m", 112.0, 27, AMBER)
		_center_text("Ray bağlantısı sığmadı", 155.0, 16, INK)
	elif instrument == &"convert":
		_center_text("240 cm", 131.0, 27, MINT)


func _draw_ruler(length_cm: int) -> void:
	var left := 176.0
	var extent := 268.0
	var part_length := extent * length_cm / 240.0
	var part_left := left if measured else left + 13.0
	var part := Rect2(part_left, 84, part_length, 8)
	draw_rect(part, STEEL)
	draw_rect(part, MINT if measured else RAIL, false, 1.0)
	draw_rect(Rect2(left, 98, extent, 40), Color("#314b45"))
	for index in range(13):
		var x := left + index * extent / 12.0
		var tick := 18 if index % 3 == 0 else 8
		draw_line(Vector2(x, 98), Vector2(x, 98 + tick), MINT, 1.5, true)
		if index % 3 == 0:
			_text(str(index * 20), Vector2(x - 7, 130), 12, INK)
	if measured:
		draw_line(Vector2(part.end.x, 92), Vector2(part.end.x, 113), INK, 1.0, true)
	var display := "%d cm" % length_cm if measured else "cm"
	_center_text(display, 169.0, 21, MINT)


func _draw_scale() -> void:
	var plate := Rect2(244, 116, 132, 10)
	draw_rect(plate, RAIL)
	draw_rect(Rect2(277 if measured else 371, 92, 66, 22), Color("#43645e"))
	draw_rect(Rect2(259, 132, 102, 41), Color("#263f40"))
	_center_text("1,2 kg" if measured else "— kg", 158.0, 19, MINT)


func _draw_timer() -> void:
	draw_arc(Vector2(310, 125), 39, 0, TAU, 64, RAIL, 2.0, true)
	draw_line(Vector2(310, 86), Vector2(310, 96), MINT, 2.0, true)
	var needle := Vector2(310, 125) + Vector2.UP.rotated(motion * TAU * 0.75) * 27.0
	draw_line(Vector2(310, 125), needle, MINT, 2.0, true)
	var reading := ("%.1f" % (1.5 * motion)).replace(".", ",")
	_center_text("%s s" % reading, 178.0, 18, MINT)


func _draw_speed() -> void:
	var path_m := 3.0 if instrument == &"guided" else 6.0
	var time_s := 2.0 if instrument == &"guided" else 3.0
	var visible_progress := 1.0 if instrument == &"speed" else motion
	var distance := ("%.1f" % (path_m * visible_progress)).replace(".", ",")
	var duration := ("%.1f" % (time_s * visible_progress)).replace(".", ",")
	_center_text("%s m     /     %s s" % [distance, duration], 117.0, 26, MINT)
	if instrument == &"guided" and measured:
		_center_text("1,5 m/s     → 1,5 m/s doğu", 155.0, 15, INK)
	elif instrument == &"complete":
		_center_text("2 m/s     6 m tamamlandı", 155.0, 15, INK)
	var start := Vector2(184, 184)
	var end := Vector2(435, 184)
	draw_line(start, end, STEEL, 2.0, true)
	var marker := start.lerp(end, visible_progress)
	draw_line(start, marker, MINT, 2.0, true)
	if instrument == &"guided" and visible_progress > 0.0:
		draw_line(marker, marker + Vector2(-7, -4), MINT, 2.0, true)
		draw_line(marker, marker + Vector2(-7, 4), MINT, 2.0, true)


func _draw_polygon(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)


func _center_text(value: String, y: float, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(value, Vector2((DRAW_SIZE.x - width) * 0.5, y), font_size, color)


func _text(value: String, position: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
