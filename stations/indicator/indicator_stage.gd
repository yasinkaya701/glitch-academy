extends Control

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const CYAN := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const DANGER := Color("#e5645a")

var current_ph: float = 2.5 # Initial strong acid
var target_ph: float = 7.0
var litmus_inserted: bool = false
var litmus_color: Color = Color("#41627f") # Blue litmus initially
var is_neutralized: bool = false


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return
		
	var cx := size.x * 0.5
	var cy := size.y * 0.55
	
	# Liquid color based on pH
	var liquid_col: Color
	if current_ph < 6.5:
		liquid_col = Color(0.9, 0.35, 0.3, 0.75) # Acidic Red/Orange
	elif current_ph > 7.5:
		liquid_col = Color(0.25, 0.45, 0.85, 0.75) # Basic Blue
	else:
		liquid_col = Color(0.3, 0.85, 0.6, 0.75) # Neutral Emerald
		
	# 1. Glass Beaker (200x260)
	var bw := 200.0
	var bh := 240.0
	var b_top := cy - bh * 0.5
	var b_bot := cy + bh * 0.5
	var beaker_rect := Rect2(cx - bw * 0.5, b_top, bw, bh)
	
	# Liquid inside
	var liquid_top := b_top + bh * 0.35
	var liquid_rect := Rect2(cx - bw * 0.5 + 4, liquid_top, bw - 8, b_bot - liquid_top - 4)
	draw_rect(liquid_rect, liquid_col)
	# Liquid surface meniscus line
	draw_line(Vector2(cx - bw * 0.5 + 4, liquid_top), Vector2(cx + bw * 0.5 - 4, liquid_top), Color(liquid_col, 1.0), 2.5)

	# Beaker glass outline
	draw_line(Vector2(cx - bw * 0.5 - 8, b_top), Vector2(cx - bw * 0.5, b_top + 16), CYAN, 2.0)
	draw_line(Vector2(cx - bw * 0.5, b_top + 16), Vector2(cx - bw * 0.5, b_bot), CYAN, 2.0)
	draw_line(Vector2(cx - bw * 0.5, b_bot), Vector2(cx + bw * 0.5, b_bot), CYAN, 2.0)
	draw_line(Vector2(cx + bw * 0.5, b_bot), Vector2(cx + bw * 0.5, b_top), CYAN, 2.0)
	draw_line(Vector2(cx + bw * 0.5, b_top), Vector2(cx + bw * 0.5 + 8, b_top), CYAN, 2.0)
	
	# Measurement graduation marks on beaker
	for i in range(1, 5):
		var my := b_bot - float(i) * 45.0
		draw_line(Vector2(cx - bw * 0.5 + 6, my), Vector2(cx - bw * 0.5 + 24, my), MUTED, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(cx - bw * 0.5 + 28, my + 4), "%d ml" % (i * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)

	# 2. Litmus Paper Strip
	var strip_x := cx - 35.0
	var strip_top := b_top - 30.0 if not litmus_inserted else liquid_top - 30.0
	var strip_bot := strip_top + 100.0
	var strip_w := 18.0
	
	# Litmus dry handle
	draw_rect(Rect2(strip_x, strip_top, strip_w, 40.0), Color("#d0dbe2"))
	# Litmus chemical zone
	var active_litmus_col := litmus_color
	if litmus_inserted:
		if current_ph < 6.5:
			active_litmus_col = Color("#e5645a") # Red in acid
		elif current_ph > 7.5:
			active_litmus_col = Color("#5a8fe5") # Blue in base
		else:
			active_litmus_col = Color("#77dfba") # Light turquoise in neutral
	draw_rect(Rect2(strip_x, strip_top + 40.0, strip_w, 60.0), active_litmus_col)
	draw_rect(Rect2(strip_x, strip_top, strip_w, 100.0), Color("#101824"), false, 1.2)

	# 3. Digital pH Meter Probe (Right side)
	var probe_x := cx + 45.0
	var probe_y := liquid_top - 20.0
	draw_line(Vector2(probe_x, b_top - 50.0), Vector2(probe_x, probe_y + 80.0), Color("#55728a"), 5.0)
	draw_circle(Vector2(probe_x, probe_y + 80.0), 6.0, Color("#304252"))
	
	# Digital pH Screen readout box
	var screen_rect := Rect2(probe_x - 45.0, b_top - 90.0, 90.0, 36.0)
	draw_rect(screen_rect, Color("#0b141e"))
	draw_rect(screen_rect, CYAN, false, 1.5)
	var ph_text := "pH: %.1f" % current_ph
	draw_string(ThemeDB.fallback_font, Vector2(screen_rect.position.x + 8, screen_rect.position.y + 24), ph_text, HORIZONTAL_ALIGNMENT_CENTER, 74, 16, AMBER)
