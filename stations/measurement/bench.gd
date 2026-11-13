extends Control
## Asset-based work surface for the Measurement Workshop. Mission owns the prompts;
## this view owns the photographic bench and movable rail component.

const DESIGN_SIZE := Vector2(1125.0, 1080.0)
const BACKGROUND := preload("res://stations/measurement/assets/bench_bg.png")
const RULER := preload("res://stations/measurement/assets/ruler.png")
const BALANCE := preload("res://stations/measurement/assets/balance.png")
const STOPWATCH := preload("res://stations/measurement/assets/stopwatch.png")
const RAIL_PIECE := preload("res://stations/measurement/assets/rail_piece.png")
const RAIL_SLOT := preload("res://stations/measurement/assets/rail_slot.png")

const INK := Color("#d8e4df")
const MINT := Color("#91e4c4")
const AMBER := Color("#ffb57e")
const GLASS := Color(0.025, 0.055, 0.085, 0.60)

var instrument := &"fault"
var measured := false
var motion := 0.0
var test_state := &"fault"


func show_state(kind: StringName, reading: bool, progress: float, state: StringName) -> void:
	instrument = kind
	measured = reading
	motion = clampf(progress, 0.0, 1.0)
	test_state = state
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := Vector2(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	draw_set_transform(Vector2.ZERO, 0.0, scale)
	# Show the photographic left-side workbench as a deliberate crop. The source
	# image is 16:9; this crop keeps its lamp, physical instruments, and table in
	# the mission's narrower left work panel without stretching them.
	draw_texture_rect_region(BACKGROUND, Rect2(Vector2.ZERO, DESIGN_SIZE), Rect2(Vector2.ZERO, DESIGN_SIZE))
	_draw_instrument_projection()
	_draw_rail_repair()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_instrument_projection() -> void:
	var panel := Rect2(650, 286, 408, 236)
	draw_rect(panel, GLASS)
	draw_rect(panel, Color(0.47, 0.70, 0.70, 0.28), false, 2.0, true)
	var accent := MINT if measured else (AMBER if test_state == &"fault" or test_state == &"too_long" or test_state == &"too_short" else INK)
	var indicator_center := Vector2(panel.end.x - 25, panel.position.y + 24)
	draw_circle(indicator_center, 6.0, accent)
	draw_circle(indicator_center, 10.0, Color(accent, 0.16))
	var texture: Texture2D
	var target := Rect2()
	match instrument:
		&"length", &"convert", &"fault":
			texture = RULER
			target = Rect2(690, 355, 325, 65)
		&"mass":
			texture = BALANCE
			target = Rect2(756, 310, 190, 190)
		&"time", &"guided", &"running", &"speed", &"complete":
			texture = STOPWATCH
			target = Rect2(780, 324, 150, 150)
		_:
			texture = RULER
			target = Rect2(690, 355, 325, 65)
	draw_texture_rect(texture, target, false, accent)


func _draw_rail_repair() -> void:
	var slot := Rect2(696, 726, 294, 147)
	var piece := Rect2(366, 726, 294, 147)
	var tint := INK
	if test_state == &"too_long":
		piece = Rect2(674, 711, 338, 169)
		tint = AMBER
	elif test_state == &"too_short":
		piece = Rect2(785, 749, 210, 105)
		tint = AMBER
	elif test_state == &"connected" or test_state == &"complete":
		piece.position = slot.position
		tint = MINT
	elif test_state == &"fault":
		piece.position = Vector2(354.0 + 326.0 * motion, 656.0 + 70.0 * motion)
		tint = AMBER
	else:
		piece.position.x = 366.0 + 46.0 * motion
	if test_state == &"connected" or test_state == &"complete":
		draw_rect(slot.grow(8), Color(MINT, 0.12))
	draw_texture_rect(RAIL_SLOT, slot, false, INK)
	draw_texture_rect(RAIL_PIECE, piece, false, tint)
