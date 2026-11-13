extends Control

const Model = preload("res://stations/seasons/seasons_model.gd")
const PAPER := Color("e6f1ef")
const MUTED := Color("a3b9bf")
const LINE := Color("354e60")
const AQUA := Color("77d2bd")
const GOLD := Color("f0aa70")

var december := false
var tilt := Model.AXIAL_TILT
var greenhouse := true
var repaired := false
var incident_time := 0.0


func _draw() -> void:
	var scale_factor := minf(size.x / 720.0, size.y / 190.0)
	var offset := (size - Vector2(720.0, 190.0) * scale_factor) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	_draw_readings()


func _draw_orbit() -> void:
	var sun := Vector2(360, 153)
	var june_earth := Vector2(132, 153)
	var december_earth := Vector2(588, 153)
	var orbit_points := PackedVector2Array()
	for step in range(129):
		var angle := TAU * float(step) / 128.0
		orbit_points.append(sun + Vector2(cos(angle) * 228.0, sin(angle) * 65.0))
	draw_polyline(orbit_points, LINE, 1.0, true)
	for radius in range(64, 29, -4):
		draw_circle(sun, float(radius), Color(1.0, 0.56, 0.23, 0.027), true, -1.0, true)
	draw_circle(sun, 29.0, Color("e89d50"), true, -1.0, true)
	draw_circle(sun - Vector2(4.0, 3.0), 22.0, Color("ffc46e"), true, -1.0, true)
	draw_circle(sun - Vector2(8.0, 8.0), 14.0, Color("ffdd9c"), true, -1.0, true)
	_center_label("Güneş", sun + Vector2(0, 49), 14, GOLD)
	for height in [-14.0, 0.0, 14.0]:
		_arrow(Vector2(319, sun.y + height), Vector2(191, sun.y + height), Color("8c6d4c"))
		_arrow(Vector2(401, sun.y + height), Vector2(529, sun.y + height), Color("8c6d4c"))
	_draw_earth(june_earth, false, not december)
	_draw_earth(december_earth, true, december)
	_center_label("21 HAZİRAN", june_earth + Vector2(0, 82), 16, AQUA if not december else MUTED)
	_center_label("21 ARALIK", december_earth + Vector2(0, 82), 16, AQUA if december else MUTED)
	_center_label("Eksenin yönü yörünge boyunca sabit  ·  Ölçekli değildir", Vector2(360, 272), 13, MUTED)


func _draw_earth(center: Vector2, is_december: bool, active: bool) -> void:
	var radius := 43.0
	var axis := Vector2(sin(deg_to_rad(tilt)), -cos(deg_to_rad(tilt)))
	var outline := AQUA if active else LINE
	var ocean_dark := Color("142a43")
	var ocean_light := Color("2f6983")
	var sun_direction := -1.0 if is_december else 1.0
	draw_circle(center, radius + 5.0, Color(outline, 0.10), true, -1.0, true)
	draw_circle(center, radius, ocean_dark, true, -1.0, true)
	var lit := PackedVector2Array()
	for step in range(33):
		var angle := -PI * 0.5 + PI * float(step) / 32.0
		lit.append(center + Vector2(cos(angle) * sun_direction, sin(angle)) * radius)
	draw_colored_polygon(lit, ocean_light)
	var land := PackedVector2Array([
		Vector2(-25, -27), Vector2(-14, -34), Vector2(2, -29), Vector2(9, -21),
		Vector2(1, -12), Vector2(-4, -6), Vector2(-16, -9), Vector2(-23, -17),
	])
	_draw_land(center, land, sun_direction)
	land = PackedVector2Array([
		Vector2(4, -6), Vector2(15, -9), Vector2(29, -4), Vector2(32, 8),
		Vector2(22, 16), Vector2(19, 29), Vector2(12, 34), Vector2(8, 21),
		Vector2(5, 13), Vector2(-2, 5),
	])
	_draw_land(center, land, sun_direction)
	var equator := Vector2(-axis.y, axis.x)
	draw_line(center - equator * 42.0, center + equator * 42.0, Color("a5bac3"), 1.0, true)
	draw_dashed_line(center + Vector2(0, 53), center - Vector2(0, 56), Color("547185"), 1.0, 4.0)
	_arrow(center - axis * 55.0, center + axis * 67.0, Color("eff3e6"))
	draw_arc(center, radius, 0, TAU, 84, outline, 1.5, true)
	_center_label("K", center + axis * 73.0 + Vector2(10, 3), 13, PAPER)
	_center_label("G", center - axis * 59.0 - Vector2(9, 0), 13, PAPER)


func _draw_land(center: Vector2, shape: PackedVector2Array, sun_direction: float) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for point in shape:
		points.append(center + point)
		colors.append(Color("558e79") if point.x * sun_direction >= 0.0 else Color("294d53"))
	draw_polygon(points, colors)


func _draw_readings() -> void:
	draw_line(Vector2(20, 16), Vector2(700, 16), LINE, 1.0, true)
	_label("ÖĞLE GÜNEŞİ  ·  EKVATORA EŞİT UZAKLIK", Vector2(20, 40), 14, PAPER)
	_draw_latitude(Vector2(26, 52), 40.0, "40° KUZEY", AQUA)
	_draw_latitude(Vector2(374, 52), -40.0, "40° GÜNEY", GOLD)
	draw_line(Vector2(360, 56), Vector2(360, 176), LINE, 1.0, true)


func _draw_latitude(origin: Vector2, latitude: float, title: String, color: Color) -> void:
	var sample := Model.sample(latitude, december, tilt)
	var panel := Rect2(origin, Vector2(318, 112))
	draw_rect(panel, Color("142334"))
	draw_rect(panel, LINE, false, 1.0)
	_label(title, origin + Vector2(12, 22), 13, color)
	_label("%s° ışın açısı" % _decimal(sample.x), origin + Vector2(12, 47), 16, PAPER)
	_label("%s saat gündüz" % _decimal(sample.y), origin + Vector2(12, 70), 16, PAPER)
	var bar := Rect2(origin + Vector2(12, 86), Vector2(285, 9))
	draw_rect(bar, LINE)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * sample.z, bar.size.y)), color)
	_label("Birim alana enerji", origin + Vector2(12, 108), 12, MUTED)


func _draw_greenhouse() -> void:
	var alarm := 1.0 - exp(-maxf(0.0, incident_time) * 0.55)
	var recovery := smoothstep(0.0, 2.0, incident_time) if repaired else 0.0
	var heat := 1.0 - recovery if repaired else alarm
	var warning := Color("ff886f") if not repaired else AQUA
	var chamber := Rect2(90, 214, 540, 192)
	var corners := PackedVector2Array([
		Vector2(90, 406), Vector2(90, 215), Vector2(179, 154), Vector2(541, 154),
		Vector2(630, 215), Vector2(630, 406),
	])
	draw_circle(Vector2(544, 92), 41, Color("df964b"), true, -1.0, true)
	draw_circle(Vector2(544, 92), 58, Color(0.94, 0.57, 0.24, 0.11), true, -1.0, true)
	draw_colored_polygon(corners, Color("15283a"))
	draw_rect(chamber, Color("ff886f", 0.085 * heat))
	draw_polyline(corners, Color("9eb8bd"), 2.0, true)
	draw_line(Vector2(90, 215), Vector2(630, 215), LINE, 1.0, true)
	draw_line(Vector2(179, 154), Vector2(179, 406), LINE, 1.0, true)
	draw_line(Vector2(541, 154), Vector2(541, 406), LINE, 1.0, true)
	draw_rect(Rect2(52, 406, 616, 19), Color("253e49"))
	for index in range(6):
		_draw_plant(Vector2(205.0 + float(index) * 62.0, 385.0), index, heat)
	var vent_y := lerpf(154.0, 134.0, recovery)
	draw_line(Vector2(274, 154), Vector2(341, vent_y), AQUA if repaired else Color("b1c5c4"), 3, true)
	draw_line(Vector2(446, 154), Vector2(379, vent_y), AQUA if repaired else Color("b1c5c4"), 3, true)
	for index in range(3):
		var x := 300.0 + float(index) * 61.0
		if repaired:
			var float_up := fmod(incident_time * 22.0 + float(index) * 17.0, 42.0)
			_arrow(Vector2(x, 139.0 - float_up), Vector2(x, 120.0 - float_up), Color(AQUA, 0.9 * recovery))
		elif alarm > 0.26:
			var points := PackedVector2Array()
			for step in range(21):
				points.append(Vector2(x + sin(float(step) * 0.52 + incident_time * 3.0 + index) * 3.0, 276 - step * 2.4))
			draw_polyline(points, Color(warning, 0.6), 2.0, true)
	_label("GÜNEY SERASI", Vector2(90, 107), 18, PAPER)
	_label("Havalandırma açık" if repaired else "Havalandırma kapalı", Vector2(90, 136), 16, warning)
	var gauge := Rect2(228, 456, 264, 6)
	draw_rect(gauge, LINE)
	var gauge_fill := lerpf(0.34, 0.92, heat)
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * gauge_fill, gauge.size.y)), warning)
	var temperature := "Sera sıcaklığı yükseliyor"
	if repaired:
		temperature = "Sıcaklık normal aralıkta" if is_equal_approx(recovery, 1.0) else "Sıcaklık normale dönüyor"
	_center_label(temperature, Vector2(360, 486), 16, PAPER)


func _draw_plant(base: Vector2, index: int, heat: float) -> void:
	var height := 36.0 + float(index % 3) * 7.0
	var lean := heat * 14.0
	var top := base + Vector2(lean, -height)
	var leaf := Color("5cc6a2").lerp(Color("ac9472"), heat * 0.86)
	draw_rect(Rect2(base + Vector2(-17, -2), Vector2(34, 18)), Color("80644c"))
	draw_line(base, top, leaf, 2.0, true)
	for side in [-1, 1]:
		var anchor := top.lerp(base, 0.34 if side > 0 else 0.56)
		var tip := anchor + Vector2(float(side) * 17.0, -10.0 + lean * 0.56)
		var bend := anchor.lerp(tip, 0.58)
		draw_colored_polygon(PackedVector2Array([anchor, bend + Vector2(0, -6), tip, bend + Vector2(0, 4)]), leaf)
	draw_circle(top, 4.0, Color(leaf, 0.95), true, -1.0, true)


func _arrow(from: Vector2, to: Vector2, color: Color) -> void:
	var backwards := (from - to).normalized()
	draw_line(from, to, color, 1.5, true)
	draw_colored_polygon(PackedVector2Array([to, to + backwards.rotated(0.48) * 8.0, to + backwards.rotated(-0.48) * 8.0]), color)


func _label(value: String, point: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _center_label(value: String, point: Vector2, font_size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_label(value, point - Vector2(width / 2.0, 0), font_size, color)


func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")
