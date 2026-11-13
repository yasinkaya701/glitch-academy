extends Control

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const CYAN := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const DANGER := Color("#e5645a")

var leg_a: float = 6.0 # m (vertical)
var leg_b: float = 8.0 # m (horizontal)
var hypotenuse_installed: bool = false
var bridge_closed: bool = false


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return
		
	var origin := Vector2(100.0, size.y - 140.0)
	var scale_m := minf((size.x - 220.0) / 10.0, (size.y - 240.0) / 8.0)
	
	var p_corner := origin
	var p_top := origin + Vector2(0, -leg_a * scale_m)
	var p_right := origin + Vector2(leg_b * scale_m, 0)
	
	# 1. Base abutments & ground piers
	draw_rect(Rect2(origin.x - 40, origin.y, 60, 80), Color("#182736"))
	draw_rect(Rect2(p_right.x - 20, origin.y, 60, 80), Color("#182736"))
	
	# 2. Horizontal bridge deck (leg b = 8m)
	draw_line(p_corner - Vector2(30, 0), p_right + Vector2(30, 0), Color("#2a425a"), 8.0)
	draw_line(p_corner, p_right, CYAN, 4.0)
	
	# 3. Vertical support tower (leg a = 6m)
	draw_line(p_corner, p_top, AMBER, 4.0)
	draw_circle(p_top, 6.0, AMBER)
	draw_circle(p_corner, 6.0, Color("#ffffff"))
	draw_circle(p_right, 6.0, CYAN)
	
	# 4. Right Angle Symbol (90 degrees)
	var sq := 20.0
	draw_line(p_corner + Vector2(sq, 0), p_corner + Vector2(sq, -sq), MUTED, 1.5)
	draw_line(p_corner + Vector2(sq, -sq), p_corner + Vector2(0, -sq), MUTED, 1.5)
	draw_circle(p_corner + Vector2(sq * 0.5, -sq * 0.5), 2.5, MUTED)
	
	# 5. Dimension Labels
	# Vertical leg a
	draw_string(ThemeDB.fallback_font, (p_corner + p_top) * 0.5 + Vector2(-54, 6), "a = %.0f m" % leg_a, HORIZONTAL_ALIGNMENT_RIGHT, -1, 15, AMBER)
	# Horizontal leg b
	draw_string(ThemeDB.fallback_font, (p_corner + p_right) * 0.5 + Vector2(-30, 30), "b = %.0f m" % leg_b, HORIZONTAL_ALIGNMENT_CENTER, 80, 15, CYAN)

	# 6. Diagonal Truss Beam (Hypotenuse c)
	if hypotenuse_installed:
		draw_line(p_top, p_right, Color(CYAN, 0.4), 10.0)
		draw_line(p_top, p_right, CYAN, 4.0)
		draw_string(ThemeDB.fallback_font, (p_top + p_right) * 0.5 + Vector2(16, -12), "c = 10 m (ONARILDI)", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CYAN)
	else:
		# Dashed missing beam with alert color
		var dist := p_top.distance_to(p_right)
		var dir := p_top.direction_to(p_right)
		for off in range(0, int(dist), 16):
			draw_line(p_top + dir * off, p_top + dir * minf(off + 8, dist), DANGER, 2.5)
		draw_string(ThemeDB.fallback_font, (p_top + p_right) * 0.5 + Vector2(16, -12), "c = ? (EKSİK KİRİŞ)", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, DANGER)
