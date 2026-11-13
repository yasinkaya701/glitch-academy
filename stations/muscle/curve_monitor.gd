extends Control
## Uzunluk–kuvvet grafik cihazı. Oyuncunun ölçtüğü noktalar çizilir, yeterli ölçümden sonra eğri görünür.

const Sim = preload("res://stations/muscle/muscle_sim.gd")
const GREEN := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const BLUE := Color("#7fb6f5")
const GRID := Color("#10303a")

var points: Array[Vector2] = []
var show_curve := false
var current_length := -1.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#041016"))
	var plot := Rect2(74, 30, size.x - 110, size.y - 90)
	draw_rect(plot, Color("#06151c"))
	var lmin := 1.2
	var lmax := 3.8
	var fmax := 9.0
	for i in 7:
		var x := plot.position.x + plot.size.x * float(i) / 6.0
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), GRID, 1.0)
		var value := lmin + (lmax - lmin) * float(i) / 6.0
		draw_string(ThemeDB.fallback_font, Vector2(x - 14, plot.end.y + 22), "%.1f" % value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#5c9aa6"))
	for i in 10:
		var y := plot.end.y - plot.size.y * float(i) / 9.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(40, y + 5), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#5c9aa6"))
	draw_string(ThemeDB.fallback_font, Vector2(14, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, GREEN)
	draw_string(ThemeDB.fallback_font, Vector2(plot.end.x - 60, size.y - 8), "µm", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, GREEN)
	var to_px := func(l: float, f: float) -> Vector2:
		return Vector2(plot.position.x + plot.size.x * (l - lmin) / (lmax - lmin), plot.end.y - plot.size.y * f / fmax)
	if show_curve:
		var curve := PackedVector2Array()
		for i in 121:
			var l := lmin + (lmax - lmin) * float(i) / 120.0
			curve.append(to_px.call(l, Sim.tetanic_force(l)))
		draw_polyline(curve, Color(BLUE, 0.25), 8.0, true)
		draw_polyline(curve, BLUE, 2.4, true)
	if current_length > 0.0:
		var p0: Vector2 = to_px.call(current_length, 0.0)
		draw_line(p0, Vector2(p0.x, plot.position.y), Color(AMBER, 0.6), 1.5)
	for point in points:
		var p: Vector2 = to_px.call(point.x, point.y)
		draw_circle(p, 10.0, Color(GREEN, 0.25))
		draw_circle(p, 5.5, GREEN)
