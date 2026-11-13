extends Control
## Dalga Girişimi sahnesi: GPU gölgelendiriciyle canlı girişim alanı, iki kaynak, A ve B sensörleri ve genlik göstergeleri.
## Hesap wave_sim.gd'den gelir.

const Wave = preload("res://stations/waves/wave_sim.gd")
const Model3D = preload("res://stations/waves/wave_3d.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const BG := Color("#070b12")
const FIELD := Vector2(40.0, 28.0)          ## cm
const AREA := Rect2(40.0, 110.0, 1000.0, 700.0)   ## 1600×900 düzleminde alan

var frequency := 4.0
var two_sources := true
var faulty_display := false

var _field: SubViewportContainer
var _overlay: Control
var _model: Node3D
var _clock := 0.0


func _ready() -> void:
	_field = SubViewportContainer.new()
	_field.stretch = true
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(900, 630)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_field.add_child(viewport)
	add_child(_field)
	var world := Node3D.new()
	viewport.add_child(world)
	_model = Model3D.new()
	world.add_child(_model)
	var camera := Camera3D.new()
	camera.position = Vector3(15, 13, 21)
	world.add_child(camera)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	camera.fov = 48.0
	camera.current = true
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -32, 0)
	key.light_energy = 1.35
	world.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-8, 7, 4)
	fill.light_energy = 0.7
	fill.omni_range = 25.0
	world.add_child(fill)
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


func _cm(point: Vector2) -> Vector2:
	return _p(AREA.position.x + point.x / FIELD.x * AREA.size.x, AREA.position.y + point.y / FIELD.y * AREA.size.y)


func _process(delta: float) -> void:
	_clock += delta
	var wavelength := Wave.wavelength(frequency)
	if _model != null:
		_model.frequency = frequency
		_model.two_sources = two_sources
		_model.clock = _clock
	var top_left := _p(AREA.position.x, AREA.position.y)
	_field.position = top_left
	_field.size = AREA.size * _scale()
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
	var amp_a := Wave.amplitude(Wave.SENSOR_A, frequency, two_sources)
	var amp_b := Wave.amplitude(Wave.SENSOR_B, frequency, two_sources)
	_draw_board(s, amp_a, amp_b)


func _draw_sensor(point: Vector2, name: String, amplitude: float, s: float, sensitive: bool) -> void:
	var c := _cm(point)
	var colour := INK
	if sensitive and amplitude > 1.6:
		colour = DANGER
	elif sensitive and amplitude < 0.3:
		colour = ACCENT
	elif not sensitive and amplitude > 1.7:
		colour = ACCENT
	_overlay.draw_arc(c, 17.0 * s, 0.0, TAU, 32, colour, 2.5 * s)
	_overlay.draw_circle(c, 3.5 * s, colour)
	_t(c + Vector2(22.0, -14.0) * s, name, 26.0 * s, colour)


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
