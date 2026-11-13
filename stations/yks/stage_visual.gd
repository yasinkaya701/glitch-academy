extends Control
## Low-cost, topic-specific diagrams keep the interaction anchored in a model or evidence trail.

const PAPER := Color("#d4e2e3")
const FAINT := Color("#78909b")
const MINT := Color("#72dfc4")
const AMBER := Color("#efb468")
const CORAL := Color("#ff9d79")

var diagram_id: StringName = &"reading"
var _phase := 0.0
var _result := 0
var life_protocol := false


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_phase += delta
	if diagram_id == &"biology" and life_protocol:
		queue_redraw()


func mark_result(correct: bool) -> void:
	_result = 1 if correct else -1
	if correct:
		life_protocol = false
	queue_redraw()


func clear_result() -> void:
	_result = 0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0c1721"), true)
	var diagram_scale := minf(size.x / 575.0, size.y / 397.0)
	var diagram_offset := (size - Vector2(575, 397) * diagram_scale) * 0.5
	draw_set_transform(diagram_offset, 0.0, Vector2.ONE * diagram_scale)
	match diagram_id:
		&"reading": _draw_reading()
		&"literature": _draw_literature()
		&"math": _draw_math()
		&"geometry": _draw_geometry()
		&"chemistry": _draw_chemistry()
		&"biology": _draw_biology()
		&"history": _draw_history()
		&"geography": _draw_geography()
		&"philosophy": _draw_philosophy()
		&"religion": _draw_religion()
		&"psychology": _draw_psychology()
		&"sociology": _draw_sociology()
		&"logic": _draw_logic()
		&"english": _draw_english()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _result != 0:
		var result_color := MINT if _result > 0 else CORAL
		draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), result_color, false, 2.0)
		var badge := Rect2(Vector2(size.x - 156, 12), Vector2(142, 34))
		draw_rect(badge, Color("#0c1721"), true)
		draw_rect(badge, result_color, false, 1.0)
		draw_string(get_theme_default_font(), badge.position + Vector2(12, 23), "ONARILDI" if _result > 0 else "TEKRAR DENE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, result_color)


func _draw_reading() -> void:
	_caption("YENİ KANIT / İLK ÇIKARIM", Vector2(23, 30))
	for index in range(7):
		var y := 95 + index * 31
		var width: float = [390.0, 430.0, 372.0, 410.0, 350.0, 425.0, 275.0][index]
		draw_line(Vector2(35, y), Vector2(35 + width, y), PAPER.darkened(0.24), 5.0)
	draw_line(Vector2(35, 188), Vector2(428, 188), MINT, 7.0)
	draw_circle(Vector2(449, 188), 7.0 + sin(_phase * 2.4) * 1.2, MINT)
	_caption("kanıt cümlesi", Vector2(37, 318), MINT)
	_caption("çıkarım", Vector2(431, 318), AMBER)
	_arrow(Vector2(169, 302), Vector2(419, 302), AMBER)


func _draw_literature() -> void:
	_caption("KAYIP GÜNLÜK / METİN İZLERİ", Vector2(23, 30))
	for index in 5:
		var y := 105 + index * 39
		draw_line(Vector2(42, y), Vector2(426 - index * 22, y), PAPER.darkened(0.25), 4.0)
	_caption("“Bugün yine kıyıya indim...”", Vector2(54, 173), MINT)
	draw_rect(Rect2(Vector2(58, 234), Vector2(160, 67)), Color("#182d37"), true)
	draw_rect(Rect2(Vector2(58, 234), Vector2(160, 67)), AMBER, false, 2.0)
	draw_rect(Rect2(Vector2(338, 234), Vector2(160, 67)), Color("#182d37"), true)
	draw_rect(Rect2(Vector2(338, 234), Vector2(160, 67)), MINT, false, 2.0)
	_caption("“indim”", Vector2(101, 273), PAPER)
	_caption("14 MAYIS", Vector2(368, 273), PAPER)
	_arrow(Vector2(228, 266), Vector2(324, 266), AMBER)
	_caption("KAYIT İPUÇLARI", Vector2(208, 356), MINT)


func _draw_math() -> void:
	_caption("YÜZDE ZİNCİRİ / YENİ DEĞER", Vector2(23, 30))
	var boxes := [Rect2(Vector2(58, 150), Vector2(118, 84)), Rect2(Vector2(222, 150), Vector2(118, 84)), Rect2(Vector2(386, 150), Vector2(118, 84))]
	var values := ["800", "600", "660"] if _result > 0 else ["800", "?", "?"]
	var colors := [PAPER, MINT, AMBER]
	for index in boxes.size():
		draw_rect(boxes[index], Color("#172833"), true)
		draw_rect(boxes[index], colors[index], false, 2.0)
		_caption(values[index], boxes[index].position + Vector2(39, 49), colors[index])
	_arrow(Vector2(177, 192), Vector2(215, 192), AMBER)
	_arrow(Vector2(341, 192), Vector2(379, 192), AMBER)
	_caption("− %25", Vector2(170, 245), CORAL)
	_caption("+ %10", Vector2(334, 245), MINT)
	if _result > 0:
		_caption("800 × 0,75 = 600", Vector2(132, 322), PAPER)
		_caption("600 × 1,10 = 660", Vector2(132, 354), PAPER)
	else:
		_caption("HER ADIMDA YENİ DEĞERİ KULLAN", Vector2(112, 330), PAPER)


func _draw_geometry() -> void:
	_caption("YÖRÜNGE HARİTASI / KOORDİNAT", Vector2(23, 30))
	draw_line(Vector2(84, 348), Vector2(505, 348), FAINT, 2.0)
	draw_line(Vector2(132, 383), Vector2(132, 94), FAINT, 2.0)
	for x in range(132, 469, 48):
		draw_line(Vector2(x, 343), Vector2(x, 353), FAINT, 2.0)
	for y in range(118, 350, 46):
		draw_line(Vector2(127, y), Vector2(137, y), FAINT, 2.0)
	var a := Vector2(180, 256)
	var b := Vector2(468, 256)
	var wrong := Vector2(180, 112)
	draw_circle(a, 11, MINT)
	draw_circle(b, 11, AMBER)
	if _result > 0:
		draw_line(a, b, MINT, 4.0)
		draw_circle(wrong, 8, FAINT.darkened(0.2))
		_caption("ONARILAN ROTA", Vector2(175, 92), MINT)
	else:
		draw_circle(wrong, 11, CORAL)
		draw_line(a, wrong, CORAL, 2.0)
		_caption("KAYITLI ROTA", Vector2(164, 92), CORAL)
	_caption("A (1,2)", Vector2(143, 278), MINT)
	_caption("B (7,2)", Vector2(438, 278), AMBER)


func _draw_chemistry() -> void:
	_caption("GÖSTERGE LABORATUVARI / ASİT-BAZ", Vector2(23, 30))
	for index in 2:
		var x := 96.0 + index * 252.0
		var is_acid := index == 0
		var liquid := Color("#552e3a") if is_acid else Color("#244955")
		var result_color := CORAL if is_acid else Color("#8fcde2")
		var beaker := PackedVector2Array([Vector2(x, 124), Vector2(x + 18, 303), Vector2(x + 144, 303), Vector2(x + 162, 124)])
		draw_rect(Rect2(Vector2(x + 13, 235), Vector2(136, 65)), liquid, true)
		draw_polyline(beaker, PAPER, 4.0)
		draw_line(Vector2(x + 14, 235), Vector2(x + 150, 235), result_color, 3.0)
		draw_rect(Rect2(Vector2(x + 70, 169), Vector2(18, 72)), Color("#477f9a") if is_acid else Color("#d27064"), true)
		draw_rect(Rect2(Vector2(x + 70, 205), Vector2(18, 36)), result_color, true)
		_caption("NUMUNE X" if is_acid else "NUMUNE Y", Vector2(x + 43, 144), result_color)
		_caption("mavi → kırmızı" if is_acid else "kırmızı → mavi", Vector2(x + 20, 330), PAPER)
	_caption("GÖZLENEN RENK DEĞİŞİMİ", Vector2(150, 372), MINT)


func _draw_biology() -> void:
	_caption("HÜCRE / ORGANEL GÖREVİ", Vector2(23, 30))
	draw_colored_polygon(_ellipse_points(Vector2(294, 222), Vector2(205, 117)), Color("#458779").darkened(0.78))
	_ellipse(Vector2(294, 222), Vector2(205, 117), Color("#458779"), 3.0)
	_ellipse(Vector2(294, 222), Vector2(183, 96), Color("#6eb9a8").darkened(0.72), 2.0)
	draw_circle(Vector2(234, 206), 37, Color("#6076a0"))
	draw_circle(Vector2(234, 206), 8, AMBER)
	for index in 4:
		var angle := TAU * float(index) / 4.0 + _phase * 0.25
		var center := Vector2(345, 208) + Vector2(cos(angle) * 62, sin(angle) * 32)
		draw_colored_polygon(_ellipse_points(center, Vector2(31, 14)), Color("#d38b70").darkened(0.35))
		_ellipse(center, Vector2(31, 14), Color("#d38b70"), 2.0)
		draw_line(center + Vector2(-16, 0), center + Vector2(16, 0), AMBER, 2.0)
	_caption("çekirdek", Vector2(188, 271), PAPER)
	if life_protocol:
		var pulse := 0.55 + 0.35 * (0.5 + 0.5 * sin(_phase * 5.0))
		var monitor := Rect2(Vector2(374, 76), Vector2(165, 62))
		draw_rect(monitor, Color("#281c22"), true)
		draw_rect(monitor, Color(CORAL, pulse), false, 2.0)
		_caption("ATP ÇIKIŞI", Vector2(386, 99), Color(CORAL, pulse))
		draw_rect(Rect2(Vector2(386, 111), Vector2(138, 9)), Color("#493037"), true)
		draw_rect(Rect2(Vector2(386, 111), Vector2(31, 9)), Color(CORAL, pulse), true)
		_caption("DÜŞÜK", Vector2(477, 132), Color(CORAL, pulse))


func _draw_history() -> void:
	_caption("AMASYA GENELGESİ / ARŞİV MASASI", Vector2(23, 30))
	var ys := [139.0, 238.0, 337.0]
	var names := ["Genelge metni", "Yıllar sonra anı", "Tarihsiz söylenti"]
	var dates := ["22 HAZ 1919", "SONRADAN", "TARİH YOK"]
	for index in ys.size():
		var color := FAINT
		draw_rect(Rect2(Vector2(76, ys[index] - 27), Vector2(426, 60)), Color("#172833"), true)
		draw_rect(Rect2(Vector2(76, ys[index] - 27), Vector2(426, 60)), color, false, 2.0)
		_caption(dates[index], Vector2(91, ys[index] - 5), color)
		_caption(names[index], Vector2(245, ys[index] - 5), PAPER)


func _draw_geography() -> void:
	_caption("KIRIK HARİTA / KOORDİNAT AĞI", Vector2(23, 30))
	for row in 5:
		var y := 111.0 + row * 52
		draw_line(Vector2(91, y), Vector2(488, y), Color("#70968e"), 2.0)
	for column in 6:
		var x := 91.0 + column * 79
		draw_line(Vector2(x, 104), Vector2(x, 320), Color("#70968e"), 2.0)
	draw_line(Vector2(170, 216), Vector2(407, 216), MINT, 4.0)
	draw_circle(Vector2(170, 216), 10, MINT)
	draw_circle(Vector2(407, 216), 10, CORAL)
	_caption("P 38°K 27°D", Vector2(98, 248), MINT)
	_caption("Q 38°K 30°D", Vector2(343, 248), CORAL)
	_caption("P ve Q koordinat kayıtları", Vector2(158, 365), PAPER)


func _draw_philosophy() -> void:
	_caption("KESİNLİK İDDİASI / AKIL YÜRÜTME", Vector2(23, 30))
	var boxes := [Rect2(Vector2(54, 112), Vector2(468, 58)), Rect2(Vector2(54, 204), Vector2(468, 58)), Rect2(Vector2(54, 296), Vector2(468, 58))]
	var labels := ["İDDİA A  ·  metal / genleşme", "İDDİA B  ·  kuş / uçuş", "İDDİA C  ·  ıslak zemin / yağmur"]
	for index in boxes.size():
		draw_rect(boxes[index], Color("#172d38"), true)
		draw_rect(boxes[index], FAINT, false, 2.0)
		_caption(labels[index], Vector2(70, boxes[index].position.y + 35), PAPER)
	_caption("ÜÇ GEREKÇE, ÜÇ SONUÇ", Vector2(180, 383), MINT)


func _draw_religion() -> void:
	_caption("DEĞER / EYLEM BAĞI", Vector2(23, 30))
	var centers := [Vector2(115, 218), Vector2(292, 218), Vector2(469, 218)]
	var labels := ["değer", "tercih", "eylem"]
	for index in centers.size():
		draw_circle(centers[index], 51, Color("#183b3d") if index == 0 else Color("#493c29"))
		_caption(labels[index], centers[index] + Vector2(-29, -5), PAPER)
		if index < centers.size() - 1:
			_arrow(centers[index] + Vector2(53, 0), centers[index + 1] - Vector2(53, 0), MINT)
	_caption("niyet + sorumluluk", Vector2(189, 322), AMBER)
	_caption("olay metninden kanıt ara", Vector2(172, 363), PAPER)


func _draw_psychology() -> void:
	_caption("ALGI HATASI / AYNI UYARAN", Vector2(23, 30))
	draw_rect(Rect2(Vector2(72, 107), Vector2(418, 207)), Color("#172833"), true)
	draw_line(Vector2(145, 172), Vector2(225, 172), FAINT, 5.0)
	draw_line(Vector2(225, 172), Vector2(250, 245), FAINT, 5.0)
	draw_line(Vector2(250, 245), Vector2(340, 245), FAINT, 5.0)
	draw_line(Vector2(340, 245), Vector2(368, 172), FAINT, 5.0)
	_caption("gölge", Vector2(230, 151), MINT)
	_caption("kayıt 01: “askılık”", Vector2(68, 354), PAPER)
	_caption("kayıt 02: “biri izliyor”", Vector2(300, 354), AMBER)


func _draw_sociology() -> void:
	_caption("SOSYOLOJİ / ALAN NOTLARI", Vector2(23, 30))
	var rows := ["KAYIT 01   ·   ÖĞRETMEN", "KAYIT 02   ·   DERS ANLATMA", "KAYIT 03   ·   KLİNİK: DOKTOR / HASTA"]
	for index in rows.size():
		var y := 126.0 + index * 82.0
		draw_line(Vector2(48, y + 22), Vector2(526, y + 22), FAINT, 1.0)
		_caption(rows[index], Vector2(60, y), PAPER)
	_caption("KONUMU VE DAVRANIŞI AYRI SINIFLA", Vector2(142, 382), AMBER)


func _draw_logic() -> void:
	_caption("KOŞULLU KURAL / MODUS TOLLENS", Vector2(23, 30))
	var boxes := [Rect2(Vector2(82, 107), Vector2(196, 78)), Rect2(Vector2(82, 232), Vector2(196, 78)), Rect2(Vector2(355, 169), Vector2(182, 78))]
	for index in boxes.size():
		draw_rect(boxes[index], Color("#172d38"), true)
		draw_rect(boxes[index], AMBER if index == 2 else FAINT, false, 2.0)
	_caption("p → q", Vector2(143, 136), PAPER)
	_caption("¬q", Vector2(158, 260), PAPER)
	_caption("?", Vector2(439, 220), AMBER)
	_arrow(Vector2(280, 146), Vector2(349, 196), AMBER)
	_arrow(Vector2(280, 270), Vector2(349, 220), AMBER)
	_caption("KURAL + KAPI KAYDI", Vector2(198, 345), PAPER)


func _draw_english() -> void:
	_caption("YDT ENGLISH / CUT FREQUENCY", Vector2(23, 30))
	draw_arc(Vector2(294, 221), 111, PI, TAU, 48, MINT, 3.0)
	draw_arc(Vector2(294, 221), 77, PI, TAU, 48, AMBER, 3.0)
	draw_line(Vector2(122, 220), Vector2(193, 220), CORAL, 4.0)
	draw_line(Vector2(396, 220), Vector2(480, 220), CORAL, 4.0)
	draw_circle(Vector2(207, 220), 9, MINT)
	draw_circle(Vector2(383, 220), 9, AMBER)
	_caption("signal fades", Vector2(98, 260), CORAL)
	_caption("move higher", Vector2(339, 158), AMBER)
	_caption("retry transmitter", Vector2(227, 356), PAPER)
	_caption("text clue → supported inference", Vector2(151, 390), MINT)


func _triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	draw_line(a, b, color, 3.0)
	draw_line(b, c, color, 3.0)
	draw_line(c, a, color, 3.0)


func _ellipse(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	draw_polyline(_ellipse_points(center, radii), color, width)


func _ellipse_points(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 49:
		var angle := TAU * float(index) / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _arrow(from: Vector2, to: Vector2, color: Color) -> void:
	draw_line(from, to, color, 2.5)
	var direction := (to - from).normalized()
	var side := Vector2(-direction.y, direction.x) * 6.0
	draw_line(to, to - direction * 13.0 + side, color, 2.5)
	draw_line(to, to - direction * 13.0 - side, color, 2.5)


func _caption(text_value: String, at: Vector2, color: Color = PAPER) -> void:
	draw_string(get_theme_default_font(), at, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
