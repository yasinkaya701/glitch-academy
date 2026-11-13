extends Control

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const CYAN := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const DANGER := Color("#e5645a")

var density: float = 1.0 # g/cm3 (Su: 1.0, Yağ: 0.8, Yoğun Çözelti: 1.5)
var liquid_name: String = "Su (d = 1.0 g/cm³)"
var depth_cm: float = 10.0 # 0 to 40 cm
var target_pressure: float = 2000.0 # Pa
var valve_unlocked: bool = false


func get_pressure_pa() -> float:
	# P = h (m) * d (kg/m3) * g (m/s2)
	# h_m = depth_cm * 0.01, d_si = density * 1000, g = 10
	return (depth_cm * 0.01) * (density * 1000.0) * 10.0


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return
		
	var cx := size.x * 0.5 - 40.0
	var cy := size.y * 0.55
	
	# 1. Main Liquid Tank (left side, 220x280)
	var tw := 220.0
	var th := 280.0
	var t_left := cx - tw - 20.0
	var t_top := cy - th * 0.5
	var t_bot := cy + th * 0.5
	
	# Liquid fill
	var liquid_col := Color(0.2, 0.55, 0.8, 0.65)
	if density < 0.9:
		liquid_col = Color(0.85, 0.75, 0.3, 0.65) # Oil golden
	elif density > 1.2:
		liquid_col = Color(0.2, 0.75, 0.65, 0.65) # Brine teal
		
	var liquid_top := t_top + 30.0
	draw_rect(Rect2(t_left + 4, liquid_top, tw - 8, t_bot - liquid_top - 4), liquid_col)
	draw_line(Vector2(t_left + 4, liquid_top), Vector2(t_left + tw - 4, liquid_top), Color(liquid_col, 1.0), 2.0)
	
	# Tank glass border
	draw_line(Vector2(t_left, t_top), Vector2(t_left, t_bot), CYAN, 2.0)
	draw_line(Vector2(t_left, t_bot), Vector2(t_left + tw, t_bot), CYAN, 2.0)
	draw_line(Vector2(t_left + tw, t_bot), Vector2(t_left + tw, t_top), CYAN, 2.0)
	
	# Depth ruler on tank edge (0 cm at surface, 40 cm at bottom)
	var max_depth := 40.0
	var depth_scale := (t_bot - liquid_top) / max_depth
	for cm in range(0, 41, 10):
		var ry := liquid_top + cm * depth_scale
		draw_line(Vector2(t_left + 6, ry), Vector2(t_left + 20, ry), MUTED, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(t_left + 24, ry + 4), "%d cm" % cm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)

	# 2. Submerged Funnel Sensor & Hose
	var probe_depth_y := liquid_top + depth_cm * depth_scale
	var probe_x := t_left + tw * 0.6
	
	# Metal probe arm & funnel
	draw_line(Vector2(probe_x, t_top - 40.0), Vector2(probe_x, probe_depth_y), Color("#41627f"), 4.0)
	# Funnel mouth
	var f_pts := PackedVector2Array([
		Vector2(probe_x - 14, probe_depth_y),
		Vector2(probe_x + 14, probe_depth_y),
		Vector2(probe_x + 8, probe_depth_y - 12),
		Vector2(probe_x - 8, probe_depth_y - 12)
	])
	draw_colored_polygon(f_pts, AMBER)
	# Flexible membrane on bottom of funnel
	draw_line(Vector2(probe_x - 14, probe_depth_y), Vector2(probe_x + 14, probe_depth_y), Color("#ffffff"), 2.0)

	# 3. Flexible Hose connecting Probe to U-Tube
	var u_left := cx + 60.0
	var u_mid_y := cy
	var hose_pts := PackedVector2Array([
		Vector2(probe_x, t_top - 40.0),
		Vector2(probe_x + 30.0, t_top - 60.0),
		Vector2(u_left - 30.0, t_top - 60.0),
		Vector2(u_left, t_top + 20.0)
	])
	draw_polyline(hose_pts, Color("#f2a65a", 0.7), 3.0)

	# 4. U-Tube Manometer (right side)
	var uw := 50.0
	var uh := 200.0
	var u_bot := t_bot - 20.0
	var u_top := u_bot - uh
	
	# U-tube glass lines
	draw_line(Vector2(u_left, u_top), Vector2(u_left, u_bot), CYAN, 2.0)
	draw_line(Vector2(u_left, u_bot), Vector2(u_left + uw, u_bot), CYAN, 2.0)
	draw_line(Vector2(u_left + uw, u_bot), Vector2(u_left + uw, u_top), CYAN, 2.0)
	
	# Manometer liquid columns (U-tube height difference Delta h)
	var p_ratio := clampf(get_pressure_pa() / 4000.0, 0.0, 1.0)
	var delta_h_px := p_ratio * 70.0
	var base_level := u_bot - 60.0
	var col_left_top := base_level + delta_h_px * 0.5
	var col_right_top := base_level - delta_h_px * 0.5
	
	# Red dye indicator in U-tube
	draw_line(Vector2(u_left, u_bot), Vector2(u_left, col_left_top), DANGER, 8.0)
	draw_line(Vector2(u_left, u_bot - 4), Vector2(u_left + uw, u_bot - 4), DANGER, 8.0)
	draw_line(Vector2(u_left + uw, u_bot), Vector2(u_left + uw, col_right_top), DANGER, 8.0)

	# Delta h height difference indicator arrows
	draw_line(Vector2(u_left + uw + 10, col_left_top), Vector2(u_left + uw + 24, col_left_top), MUTED, 1.0)
	draw_line(Vector2(u_left + uw + 10, col_right_top), Vector2(u_left + uw + 24, col_right_top), MUTED, 1.0)
	draw_line(Vector2(u_left + uw + 17, col_left_top), Vector2(u_left + uw + 17, col_right_top), AMBER, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(u_left + uw + 30, (col_left_top + col_right_top) * 0.5 + 4), "Δh", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, AMBER)

	# 5. Live Pressure Readout Box
	var cur_p := get_pressure_pa()
	var p_box := Rect2(cx - 30.0, t_top - 100.0, 150.0, 42.0)
	draw_rect(p_box, Color("#0c1520"))
	draw_rect(p_box, CYAN, false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(p_box.position.x + 8, p_box.position.y + 26), "P = %.0f Pa" % cur_p, HORIZONTAL_ALIGNMENT_CENTER, 134, 17, AMBER)
