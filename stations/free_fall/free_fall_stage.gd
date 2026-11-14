extends Control

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const CYAN := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const DANGER := Color("#e5645a")

var pressure_kpa: float = 101.3
var drop_progress: float = 0.0 # 0.0 at top, 1.0 at impact
var is_dropping: bool = false
var ball_y: float = 0.0
var feather_y: float = 0.0
var impact_flash: float = 0.0


func _process(delta: float) -> void:
	if is_dropping:
		drop_progress = minf(drop_progress + delta * 1.0, 1.0)
		# Physics: in vacuum (pressure ~ 0), both fall with h = 0.5 * g * t^2 -> quadratic progress
		var t := drop_progress
		ball_y = t * t # Heavy ball drops quadratically
		if pressure_kpa > 10.0:
			# High air drag for feather: linear terminal velocity
			feather_y = t * 0.45
		else:
			# Pure vacuum: exact same acceleration
			feather_y = t * t
			
		if drop_progress >= 1.0:
			is_dropping = false
			impact_flash = 1.0
	elif impact_flash > 0.0:
		impact_flash = maxf(0.0, impact_flash - delta * 2.0)
	queue_redraw()


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return
		
	var cx := size.x * 0.5
	var top_y := 80.0
	var bot_y := size.y - 100.0
	var tube_h := bot_y - top_y
	var tube_w := minf(180.0, size.x * 0.35)
	
	# Vacuum tube glass cylinder
	var tube_rect := Rect2(cx - tube_w * 0.5, top_y, tube_w, tube_h)
	draw_rect(tube_rect, Color(0.08, 0.14, 0.22, 0.65))
	draw_rect(tube_rect, Color(CYAN, 0.5), false, 2.0)
	
	# Top mount & vacuum seal
	draw_rect(Rect2(cx - tube_w * 0.5 - 12, top_y - 18, tube_w + 24, 18), Color("#1b2c3f"))
	draw_line(Vector2(cx - tube_w * 0.5 - 12, top_y), Vector2(cx + tube_w * 0.5 + 12, top_y), CYAN, 2.0)
	
	# Bottom sensor base
	var base_col := CYAN if impact_flash > 0.1 else Color("#22374e")
	draw_rect(Rect2(cx - tube_w * 0.5 - 16, bot_y, tube_w + 32, 24), base_col)
	if impact_flash > 0.0:
		draw_circle(Vector2(cx, bot_y), tube_w * 0.6 * impact_flash, Color(CYAN, impact_flash * 0.35))

	# Height measurement ticks on tube edge
	var tick_count := 5
	for i in range(tick_count + 1):
		var ty := top_y + float(i) / float(tick_count) * tube_h
		var meter_val := (tick_count - i) * 1.0
		draw_line(Vector2(cx - tube_w * 0.5, ty), Vector2(cx - tube_w * 0.5 + 12, ty), MUTED, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(cx - tube_w * 0.5 - 34, ty + 5), "%.0fm" % meter_val, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, MUTED)

	# Falling objects
	var left_x := cx - tube_w * 0.25
	var right_x := cx + tube_w * 0.25
	var by := top_y + 20.0 + ball_y * (tube_h - 40.0)
	var fy := top_y + 20.0 + feather_y * (tube_h - 40.0)
	
	# Object 1: Heavy Lead/Brass Sphere (Left)
	draw_circle(Vector2(left_x, by), 12.0, AMBER)
	draw_circle(Vector2(left_x - 3, by - 3), 4.0, Color("#ffffff"))
	draw_string(ThemeDB.fallback_font, Vector2(left_x - 30, by - 16), "Kurşun Bilye (1 kg)", HORIZONTAL_ALIGNMENT_CENTER, 80, 10, AMBER)
	
	# Object 2: Light Feather / Aluminum Flake (Right)
	var feather_col := INK if pressure_kpa < 10.0 else Color("#ffb093")
	draw_line(Vector2(right_x, fy - 14), Vector2(right_x, fy + 14), feather_col, 2.0)
	for fo in [-8, -4, 0, 4, 8]:
		draw_line(Vector2(right_x, fy + fo), Vector2(right_x + 8, fy + fo - 4), feather_col, 1.2)
		draw_line(Vector2(right_x, fy + fo), Vector2(right_x - 8, fy + fo - 4), feather_col, 1.2)
	draw_string(ThemeDB.fallback_font, Vector2(right_x - 30, fy - 16), "Hafif Tüy (2 g)", HORIZONTAL_ALIGNMENT_CENTER, 80, 10, feather_col)

	# Pressure indicator badge
	var p_text := "Basınç: %.1f kPa (HAVA)" % pressure_kpa if pressure_kpa > 10.0 else "Basınç: 0.0 kPa (TAM VAKUM)"
	var p_col := DANGER if pressure_kpa > 10.0 else CYAN
	draw_string(ThemeDB.fallback_font, Vector2(cx - 100, top_y - 28), p_text, HORIZONTAL_ALIGNMENT_CENTER, 200, 12, p_col)
