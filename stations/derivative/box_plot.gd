extends Control
## Depo Atölyesi çizimi: levha, katlanmış kutu ve V(x) grafiği aynı x değerinden beslenir.
## Hacim ve eğim hesabı çizimden bağımsız, `volume()` ve `slope()` içinde.

const INK := Color("#e9f1ee")
const MUTED := Color("#b1ac9e")
const JADE := Color("#8fbea0")
const SKY := Color("#dfae63")
const GOLD := Color("#e8c986")
const RED := Color("#d98e78")
const GRID := Color("#242520")
const GRID_MAJOR := Color("#3b3d35")
const BACK := Color("#10110f")

## Levha kenarı (dm).
var side := 12.0
## Kesilen köşe karesinin kenarı (dm).
var cut := 2.0
var show_point := true
var show_tangent := false
var show_optimum := false
var show_waste := false
var title_hint := ""
## Yalnızca grafik: levha ve kutu 3B tezgâhta gösterilir.
var graph_only := true
## Oyuncunun ölçtüğü (x, V) noktaları.
var measured: Array[Vector2] = []
var show_curve := false


static func volume(a: float, x: float) -> float:
	return x * pow(a - 2.0 * x, 2.0)


static func slope(a: float, x: float) -> float:
	return (a - 2.0 * x) * (a - 6.0 * x)


func _draw() -> void:
	if size.x < 150 or size.y < 110:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	if graph_only:
		_draw_graph(Rect2(14, 34, size.x - 28, size.y - 56))
		return
	var left := Rect2(18, 18, size.x * 0.44, size.y - 36)
	var graph := Rect2(size.x * 0.5, 40, size.x * 0.47, size.y - 112)
	_draw_sheet(Rect2(left.position, Vector2(left.size.x, left.size.y * 0.42)))
	_draw_box(Rect2(left.position + Vector2(0, left.size.y * 0.44), Vector2(left.size.x, left.size.y * 0.56)))
	_draw_graph(graph)


func _draw_sheet(area: Rect2) -> void:
	var px := minf(area.size.x, area.size.y) * 0.92
	var s := px / side
	var origin := area.position + Vector2((area.size.x - px) * 0.5, (area.size.y - px) * 0.5)
	var c := cut * s
	draw_rect(Rect2(origin, Vector2(px, px)), Color("#292a25"))
	draw_rect(Rect2(origin, Vector2(px, px)), MUTED, false, 1.5, true)
	for corner in [Vector2.ZERO, Vector2(px - c, 0), Vector2(0, px - c), Vector2(px - c, px - c)]:
		var r := Rect2(origin + corner, Vector2(c, c))
		draw_rect(r, Color(RED, 0.30))
		draw_rect(r, RED, false, 1.5, true)
	# Katlama çizgileri
	var fold := Color(INK, 0.55)
	_dash(origin + Vector2(c, 0), origin + Vector2(c, px), fold)
	_dash(origin + Vector2(px - c, 0), origin + Vector2(px - c, px), fold)
	_dash(origin + Vector2(0, c), origin + Vector2(px, c), fold)
	_dash(origin + Vector2(0, px - c), origin + Vector2(px, px - c), fold)
	_chip(origin + Vector2(c * 0.5, c * 0.5), "x", RED)
	_chip(origin + Vector2(px * 0.5, px * 0.5), "a = %s dm" % _num(side), SKY)


func _draw_box(area: Rect2) -> void:
	var b := side - 2.0 * cut
	if b <= 0.0:
		return
	var s := minf(area.size.y * 0.80 / side, area.size.x * 0.88 / (1.732 * side))
	var ox := area.position.x + area.size.x * 0.5
	var baseline := area.position.y + area.size.y - 6.0
	var oy := baseline - b * s
	var p := func(u: float, v: float, w: float) -> Vector2:
		return Vector2(ox + (u - v) * 0.866 * s, oy + (u + v) * 0.5 * s - w * s)
	var floor_poly := PackedVector2Array([p.call(0, 0, 0), p.call(b, 0, 0), p.call(b, b, 0), p.call(0, b, 0)])
	var wall_l := PackedVector2Array([p.call(0, 0, 0), p.call(0, b, 0), p.call(0, b, cut), p.call(0, 0, cut)])
	var wall_r := PackedVector2Array([p.call(0, 0, 0), p.call(b, 0, 0), p.call(b, 0, cut), p.call(0, 0, cut)])
	var front_r := PackedVector2Array([p.call(b, 0, 0), p.call(b, b, 0), p.call(b, b, cut), p.call(b, 0, cut)])
	var front_l := PackedVector2Array([p.call(0, b, 0), p.call(b, b, 0), p.call(b, b, cut), p.call(0, b, cut)])
	# Yer gölgesi
	draw_colored_polygon(PackedVector2Array([
		p.call(-0.4, -0.4, 0) + Vector2(0, 5), p.call(b + 0.4, -0.4, 0) + Vector2(0, 5),
		p.call(b + 0.4, b + 0.4, 0) + Vector2(0, 5), p.call(-0.4, b + 0.4, 0) + Vector2(0, 5)]), Color(0, 0, 0, 0.35))
	draw_colored_polygon(floor_poly, Color("#242520"))
	draw_colored_polygon(wall_l, Color("#30312b"))
	draw_colored_polygon(wall_r, Color("#3a3b33"))
	draw_colored_polygon(front_r, Color("#615b50"))
	draw_colored_polygon(front_l, Color("#857b68"))
	for poly in [floor_poly, wall_l, wall_r, front_r, front_l]:
		var outline: PackedVector2Array = poly.duplicate()
		outline.append(outline[0])
		draw_polyline(outline, Color(INK, 0.55), 1.4, true)
	var v := volume(side, cut)
	_chip(Vector2(ox, area.position.y + 12.0), "V = %s dm³" % _num(v), JADE)
	if show_waste:
		_chip(Vector2(ox, area.position.y + 44.0), "kayıp hacim", RED)


func _draw_graph(r: Rect2) -> void:
	var xmax := side * 0.5
	var vmax := volume(side, side / 6.0) * 1.18
	var o := Vector2(r.position.x + 44.0, r.position.y + r.size.y - 30.0)
	var w := r.size.x - 66.0
	var h := r.size.y - 50.0
	var px := func(x: float, v: float) -> Vector2:
		return o + Vector2(x / xmax * w, -v / vmax * h)
	# Izgara
	var xstep := 1.0 if side <= 12.0 else 1.5
	var x := 0.0
	while x <= xmax + 0.001:
		draw_line(px.call(x, 0), px.call(x, vmax), GRID_MAJOR, 1.0, true)
		draw_string(ThemeDB.fallback_font, px.call(x, 0) + Vector2(-6, 18), _num(x), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)
		x += xstep
	var vstep := _nice_step(vmax / 5.0)
	var vy := 0.0
	while vy <= vmax:
		draw_line(px.call(0, vy), px.call(xmax, vy), GRID, 1.0, true)
		draw_string(ThemeDB.fallback_font, px.call(0, vy) + Vector2(-38, 4), _num(vy), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)
		vy += vstep
	draw_line(o, o + Vector2(w + 8, 0), MUTED, 1.6, true)
	draw_line(o, o + Vector2(0, -h - 8), MUTED, 1.6, true)
	draw_string(ThemeDB.fallback_font, o + Vector2(w - 46, 34), "x (dm)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, INK)
	draw_string(ThemeDB.fallback_font, o + Vector2(-38, -h - 14), "V (dm³)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, INK)
	# Eğri
	var pts := PackedVector2Array()
	for i in 161:
		var xx := xmax * float(i) / 160.0
		pts.append(px.call(xx, volume(side, xx)))
	var area_poly := PackedVector2Array([o])
	area_poly.append_array(pts)
	area_poly.append(o + Vector2(w, 0))
	if show_curve or not graph_only:
		draw_colored_polygon(area_poly, Color(SKY, 0.07))
		draw_polyline(pts, Color(SKY, 0.25), 7.0, true)
		draw_polyline(pts, SKY, 2.6, true)
	for m in measured:
		var mp: Vector2 = px.call(m.x, m.y)
		draw_circle(mp, 8.0, Color(JADE, 0.22), true, -1.0, true)
		draw_circle(mp, 4.5, JADE, true, -1.0, true)
	var best := side / 6.0
	if show_optimum:
		var tip: Vector2 = px.call(best, volume(side, best))
		draw_line(tip, px.call(best, 0), Color(JADE, 0.7), 1.6, true)
		draw_circle(tip, 7.0, Color(JADE, 0.25), true, -1.0, true)
		draw_circle(tip, 4.0, JADE, true, -1.0, true)
		_chip(tip + Vector2(0, -26), "en büyük hacim", JADE)
	if show_point:
		var pv := volume(side, cut)
		var pt: Vector2 = px.call(cut, pv)
		draw_line(pt, px.call(cut, 0), Color(RED, 0.8), 1.4, true)
		draw_line(pt, px.call(0, pv), Color(RED, 0.5), 1.0, true)
		if show_tangent:
			var m := slope(side, cut)
			var span := xmax * 0.24
			var a_pt: Vector2 = px.call(cut - span, pv - m * span)
			var b_pt: Vector2 = px.call(cut + span, pv + m * span)
			draw_line(a_pt, b_pt, Color(GOLD, 0.25), 8.0, true)
			draw_line(a_pt, b_pt, GOLD, 2.4, true)
		draw_circle(pt, 9.0, Color(RED, 0.25), true, -1.0, true)
		draw_circle(pt, 5.0, RED, true, -1.0, true)
		draw_circle(pt, 2.0, BACK, true, -1.0, true)
	var hint := title_hint
	if hint != "":
		_chip(Vector2(r.position.x + r.size.x * 0.5, r.position.y - 16.0), hint, GOLD)


func _nice_step(raw: float) -> float:
	var mag := pow(10.0, floorf(log(raw) / log(10.0)))
	for m in [1.0, 2.0, 5.0, 10.0]:
		if raw <= m * mag:
			return m * mag
	return 10.0 * mag


func _num(value: float) -> String:
	if absf(value - roundf(value)) < 0.005:
		return str(int(roundf(value)))
	return ("%.1f" % value).replace(".", ",")


func _dash(from: Vector2, to: Vector2, color: Color) -> void:
	var distance := from.distance_to(to)
	var direction := from.direction_to(to)
	for offset in range(0, int(distance), 12):
		draw_line(from + direction * offset, from + direction * minf(offset + 6, distance), color, 1.4, true)


func _chip(center: Vector2, value: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(BACK, 0.94)
	box.border_color = color
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	var rect := Rect2(center - Vector2(text_size.x * 0.5 + 8.0, 12.0), Vector2(text_size.x + 16.0, 24.0))
	draw_style_box(box, rect)
	draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 17.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, color)
