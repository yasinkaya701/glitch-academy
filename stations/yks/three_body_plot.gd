extends Control
var _baseline: Array[PackedVector2Array] = []
var _perturbed: Array[PackedVector2Array] = []
func set_paths(baseline: Array[PackedVector2Array], perturbed: Array[PackedVector2Array]) -> void:
	_baseline = baseline
	_perturbed = perturbed
	queue_redraw()
func _draw() -> void:
	var bounds := Rect2(Vector2(24, 22), size - Vector2(48, 44))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#08131d"), true)
	draw_rect(bounds, Color("#526674", 0.55), false, 1.0)
	var center := bounds.get_center()
	for tick in range(-4, 5):
		var x := center.x + tick * bounds.size.x / 9.0
		var y := center.y + tick * bounds.size.y / 9.0
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), Color("#263b4a", 0.42), 1.0)
		draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), Color("#263b4a", 0.42), 1.0)
	var world_radius := 1.0
	for path_group in [_baseline, _perturbed]:
		for path in path_group:
			for point in path:
				world_radius = maxf(world_radius, point.length())
	_draw_paths(_baseline, bounds, Color("#6fe3c1"), 1.8, world_radius)
	_draw_paths(_perturbed, bounds, Color("#f2a65a"), 2.0, world_radius)
	_draw_key()
func _draw_paths(paths: Array[PackedVector2Array], bounds: Rect2, color: Color, width: float, world_radius: float) -> void:
	for body_index in paths.size():
		var points := paths[body_index]
		if points.size() < 2: continue
		var transformed := PackedVector2Array()
		for point in points: transformed.append(_to_screen(point, bounds, world_radius))
		draw_polyline(transformed, color.darkened(float(body_index) * 0.10), width, true)
		draw_circle(transformed[0], 4.0, Color("#e8f1f2"))
		draw_circle(transformed[-1], 5.0, color)
func _to_screen(point: Vector2, bounds: Rect2, world_radius: float) -> Vector2:
	var scale := minf(bounds.size.x, bounds.size.y) / (world_radius * 2.25)
	return bounds.get_center() + Vector2(point.x, -point.y) * scale
func _draw_key() -> void:
	var y := size.y - 14.0
	draw_line(Vector2(34, y - 4), Vector2(58, y - 4), Color("#6fe3c1"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(66, y), "Başlangıç", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c8d6d7"))
	draw_line(Vector2(166, y - 4), Vector2(190, y - 4), Color("#f2a65a"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(198, y), "Küçük ilk hız farkı", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c8d6d7"))
