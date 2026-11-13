extends Control
## Dalga Girişimi sahnesi: GPU gölgelendiriciyle canlı girişim alanı, iki kaynak, A ve B sensörleri ve genlik göstergeleri.
## Hesap wave_sim.gd'den gelir.

const Wave = preload("res://stations/waves/wave_sim.gd")
const Experiment3D = preload("res://scenes/experiment_3d.tscn")
const Tank = preload("res://stations/waves/wave_tank.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const BG := Color("#070b12")
const AREA := Rect2(40.0, 110.0, 1000.0, 700.0)   ## 1600×900 düzleminde alan

var frequency := 4.0
var two_sources := true
var faulty_display := false

var _stage_3d: SubViewportContainer
var _overlay: Control
var _tank


func _ready() -> void:
	_stage_3d = Experiment3D.instantiate() as SubViewportContainer
	_stage_3d.position = _p(AREA.position.x, AREA.position.y)
	_stage_3d.size = AREA.size * _scale()
	_stage_3d.stretch = false
	_stage_3d.clip_contents = true
	_stage_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_3d)
	var viewport := _stage_3d.get_node("Viewport") as SubViewport
	viewport.size = Vector2i(1000, 700)
	_stage_3d.stretch = true
	var camera := _stage_3d.get_node("Viewport/World/Camera3D") as Camera3D
	camera.position = Vector3(0.0, 7.3, 8.5)
	camera.rotation_degrees = Vector3(-40.0, 0.0, 0.0)
	camera.size = 7.0
	var model := _stage_3d.get_node("Viewport/World/Model") as Node3D
	_tank = Tank.new()
	model.add_child(_tank)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _scale() -> float:
	return minf(size.x / 1600.0, size.y / 900.0)


func _origin() -> Vector2:
	return (size - Vector2(1600, 900) * _scale()) * 0.5


func _p(x: float, y: float) -> Vector2:
	return _origin() + Vector2(x, y) * _scale()


func _process(_delta: float) -> void:
	var top_left := _p(AREA.position.x, AREA.position.y)
	_stage_3d.position = top_left
	_stage_3d.size = AREA.size * _scale()
	_tank.set_wave_state(frequency, two_sources, faulty_display)
	queue_redraw()
	_overlay.queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)


func _font() -> Font:
	return get_theme_default_font()


func _t(position: Vector2, text: String, size_px: float, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	_overlay.draw_string(_font(), position, text, align, width, int(size_px), color)


func _draw_overlay() -> void:
	var s := _scale()
	var canvas := _overlay
	canvas.draw_rect(Rect2(_p(AREA.position.x, AREA.position.y), AREA.size * s), Color(1, 1, 1, 0.18), false, 1.5)
	_t(_p(58.0, 150.0), "3D DALGA HAVUZU  ·  ÜSTTEN / EĞİK GÖZLEM", 16.0 * s, ACCENT)
	_t(_p(58.0, 184.0), "Turkuaz: tepe   ·   Amber: çukur   ·   İnce çizgi: düğüm", 14.0 * s, MUTED)
	var amp_a := Wave.amplitude(Wave.SENSOR_A, frequency, two_sources)
	var amp_b := Wave.amplitude(Wave.SENSOR_B, frequency, two_sources)
	_draw_board(s, amp_a, amp_b)


func _draw_board(s: float, amp_a: float, amp_b: float) -> void:
	var x := 1100.0
	var y := 130.0
	var wavelength := Wave.wavelength(frequency)
	var rows := [
		["FREKANS", "%s Hz" % str(snappedf(frequency, 0.1)).replace(".", ",")],
		["DALGA BOYU", "%s cm" % str(snappedf(wavelength, 0.01)).replace(".", ",")],
		["A · YOL FARKI / λ", str(snappedf(Wave.path_ratio(Wave.SENSOR_A, frequency), 0.01)).replace(".", ",")],
		["B · YOL FARKI / λ", str(snappedf(Wave.path_ratio(Wave.SENSOR_B, frequency), 0.01)).replace(".", ",")],
	]
	for row in rows:
		_t(_p(x, y), row[0], 15.0 * s, MUTED)
		_t(_p(x + 200.0, y + 6.0), row[1], 26.0 * s, INK, HORIZONTAL_ALIGNMENT_RIGHT, 250.0 * s)
		y += 54.0
	y += 24.0
	_draw_bar(x, y, s, "A · HASSAS SENSÖR", amp_a, DANGER if amp_a > 1.6 else (ACCENT if amp_a < 0.3 else WARM), 1.6, true)
	y += 110.0
	_draw_bar(x, y, s, "B · VERİ ALICISI", amp_b, ACCENT if amp_b >= 1.7 else WARM, 1.7, false)
	if faulty_display:
		y += 120.0
		_t(_p(x, y), "CİHAZ BEKLENTİSİ  her noktada 2,0", 18.0 * s, WARM)


func _draw_bar(x: float, y: float, s: float, title: String, value: float, colour: Color, limit: float, overload: bool) -> void:
	_t(_p(x, y), title, 15.0 * s, MUTED)
	var track := Rect2(_p(x, y + 14.0), Vector2(440.0, 26.0) * s)
	_overlay.draw_rect(track, Color(1, 1, 1, 0.07))
	_overlay.draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(value / 2.0, 0.0, 1.0), track.size.y)), colour)
	var limit_x := track.position.x + track.size.x * limit / 2.0
	_overlay.draw_line(Vector2(limit_x, track.position.y - 6.0 * s), Vector2(limit_x, track.end.y + 6.0 * s), DANGER if overload else ACCENT, 2.0 * s)
	_t(_p(x + 440.0, y + 62.0), "%s" % str(snappedf(value, 0.01)).replace(".", ","), 22.0 * s, colour, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
