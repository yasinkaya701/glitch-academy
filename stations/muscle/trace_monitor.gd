extends Control
## Kayıt cihazı ekranı (SubViewport içinde çizilir, 3B quad'a doku olur): kuvvet ve kalsiyum izleri, ATP göstergesi.

const WINDOW := 8.0        ## s
const MAX_FORCE := 9.0     ## N
const GREEN := Color("#6fe3c1")
const CYAN := Color("#7fb6f5")
const AMBER := Color("#f2a65a")
const GRID := Color("#10303a")
const BG := Color("#041016")

var samples: Array[Vector3] = []   ## (zaman, kuvvet, kalsiyum)
var atp := 1.0
var load_line := 0.0
var _clock := 0.0


func push(time_s: float, force: float, calcium: float, atp_level: float) -> void:
	_clock = time_s
	atp = atp_level
	samples.append(Vector3(time_s, force, calcium))
	while samples.size() > 0 and samples[0].x < time_s - WINDOW:
		samples.pop_front()
	queue_redraw()


func clear_trace() -> void:
	samples.clear()
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG)
	var plot := Rect2(70, 30, size.x - 150, size.y - 80)
	draw_rect(plot, Color("#06151c"))
	for i in 9:
		var x := plot.position.x + plot.size.x * float(i) / 8.0
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), GRID, 1.0)
	for i in 10:
		var y := plot.end.y - plot.size.y * float(i) / 9.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(14, y + 5), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#5c9aa6"))
	draw_string(ThemeDB.fallback_font, Vector2(14, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, GREEN)
	# Yük çizgisi
	if load_line > 0.0:
		var ly := plot.end.y - plot.size.y * clampf(load_line / MAX_FORCE, 0.0, 1.0)
		for i in 40:
			draw_line(Vector2(plot.position.x + i * (plot.size.x / 40.0), ly), Vector2(plot.position.x + (i + 0.5) * (plot.size.x / 40.0), ly), AMBER, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(plot.end.x - 90, ly - 6), "yük %.0f N" % load_line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, AMBER)
	# İz
	var force_points := PackedVector2Array()
	var ca_points := PackedVector2Array()
	for sample in samples:
		var x := plot.position.x + plot.size.x * (sample.x - (_clock - WINDOW)) / WINDOW
		force_points.append(Vector2(x, plot.end.y - plot.size.y * clampf(sample.y / MAX_FORCE, 0.0, 1.0)))
		ca_points.append(Vector2(x, plot.end.y - plot.size.y * 0.35 * clampf(sample.z, 0.0, 1.0)))
	if ca_points.size() > 1:
		draw_polyline(ca_points, Color(CYAN, 0.7), 2.0, true)
	if force_points.size() > 1:
		draw_polyline(force_points, Color(GREEN, 0.25), 9.0, true)
		draw_polyline(force_points, GREEN, 3.0, true)
	# ATP göstergesi
	var bar := Rect2(size.x - 62, plot.position.y, 26, plot.size.y)
	draw_rect(bar, Color("#0b2229"))
	var fill_color := GREEN if atp > 0.5 else (AMBER if atp > 0.15 else Color("#e5645a"))
	var h := bar.size.y * clampf(atp, 0.0, 1.0)
	draw_rect(Rect2(bar.position.x, bar.end.y - h, bar.size.x, h), fill_color)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 70, plot.end.y + 26), "ATP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, fill_color)
	draw_string(ThemeDB.fallback_font, Vector2(plot.position.x, size.y - 12), "Ca²⁺", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(plot.position.x + 70, size.y - 12), "Kuvvet", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, GREEN)
