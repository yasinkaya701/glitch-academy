extends Control
## Fotoelektrik Kapısı sahnesi: lamba, vakum tüpü, metal plaka, fotonlar, sökülen elektronlar, ampermetre ve K_max–f grafiği.
## Hesaplar photo_sim.gd'den gelir, çizim süreleri ya da akımı uydurmaz.

const Photo = preload("res://stations/photoelectric/photo_sim.gd")
const Model3D = preload("res://stations/photoelectric/photo_3d.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const BG := Color("#070b12")

var metal: StringName = &"cesium"
var frequency := 4.3e14          ## Hz
var intensity := 1.0             ## 0–1, foton sayısı/s
var faulty_display := false      ## kayma: cihaz şiddeti akım sanıyor
var door_open := false
var door_burned := false

var _clock := 0.0
var _electrons: Array[Dictionary] = []
var _photon_phase := 0.0
var _viewport_container: SubViewportContainer
var _model: Node3D


func _ready() -> void:
	_viewport_container = SubViewportContainer.new()
	_viewport_container.stretch = true
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var viewport := SubViewport.new()
	viewport.size = Vector2i(875, 390)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(viewport)
	add_child(_viewport_container)
	var world := Node3D.new()
	viewport.add_child(world)
	world.add_child(Model3D.new())
	_model = world.get_child(0)
	var camera := Camera3D.new()
	camera.position = Vector3(-0.25, 3.1, 8.8)
	world.add_child(camera)
	camera.look_at(Vector3(-0.45, 0, 0), Vector3.UP)
	camera.fov = 43.0
	camera.current = true
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_energy = 1.2
	world.add_child(key)


func _process(delta: float) -> void:
	_clock += delta
	_photon_phase += delta
	var phi: float = Photo.METALS[metal]["phi"]
	var rate := 14.0 * intensity if Photo.photon_energy(frequency) > phi else 0.0
	if rate > 0.0 and randf() < rate * delta:
		var k := Photo.k_max(frequency, phi)
		_electrons.append({"x": 0.0, "y": randf_range(-0.9, 0.9), "speed": 0.2 + 0.55 * sqrt(k), "life": 0.0, "dy": randf_range(-0.15, 0.15)})
	for e in _electrons:
		e["x"] += e["speed"] * delta
		e["y"] += e["dy"] * delta
		e["life"] += delta
	_electrons = _electrons.filter(func(e: Dictionary) -> bool: return e["x"] < 1.15)
	queue_redraw()
	if _model != null:
		_model.frequency = frequency
		_model.intensity = intensity
		_model.electric_field = Photo.stopping_potential(frequency, float(Photo.METALS[metal]["phi"]))
		_model.metal = metal
		_layout_3d()


func _layout_3d() -> void:
	if _viewport_container == null:
		return
	var scale_factor := minf(size.x / 1600.0, size.y / 900.0)
	var origin := (size - Vector2(1600, 900) * scale_factor) * 0.5
	_viewport_container.position = origin + Vector2(42, 205) * scale_factor
	_viewport_container.size = Vector2(875, 395) * scale_factor


func _font() -> Font:
	return get_theme_default_font()


func _t(position: Vector2, text: String, size_px: float, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(_font(), position, text, align, width, int(size_px), color)


func _draw() -> void:
	var s := minf(size.x / 1600.0, size.y / 900.0)
	var o := (size - Vector2(1600, 900) * s) * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	# İnce zemin ızgarası
	for i in range(0, 17):
		draw_line(o + Vector2(i * 100.0, 0.0) * s, o + Vector2(i * 100.0, 900.0) * s, Color(1, 1, 1, 0.025), 1.0)
	for j in range(0, 10):
		draw_line(o + Vector2(0.0, j * 100.0) * s, o + Vector2(1600.0, j * 100.0) * s, Color(1, 1, 1, 0.025), 1.0)
	var phi: float = Photo.METALS[metal]["phi"]
	var k := Photo.k_max(frequency, phi)
	var colour := Photo.light_color(frequency)
	var current := Photo.faulty_current(frequency, intensity, phi) if faulty_display else Photo.photocurrent(frequency, intensity, phi)
	_layout_3d()
	_t(o + Vector2(350, 194) * s, String(Photo.METALS[metal]["name"]).to_upper() + "   φ = %s eV" % str(phi).replace(".", ","), 18.0 * s, MUTED)
	_draw_meter(o, s, current)
	_draw_board(o, s, phi, k, current)
	_draw_graph(o, s, phi, k)
	_draw_gate(o, s)


func _draw_meter(o: Vector2, s: float, current: float) -> void:
	var c := o + Vector2(600, 700) * s
	var r := 105.0 * s
	draw_arc(c, r, PI * 1.1, PI * 1.9, 48, Color(MUTED, 0.6), 3.0 * s)
	for i in 9:
		var a := lerpf(PI * 1.1, PI * 1.9, float(i) / 8.0)
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.88, c + Vector2(cos(a), sin(a)) * r, Color(MUTED, 0.8), 2.0 * s)
	var needle := lerpf(PI * 1.1, PI * 1.9, clampf(current / 8.0, 0.0, 1.0))
	draw_line(c, c + Vector2(cos(needle), sin(needle)) * r * 0.9, WARM, 3.0 * s)
	draw_circle(c, 6.0 * s, WARM)
	_t(c + Vector2(-80, 50) * s, "AKIM  %s µA" % str(snappedf(current, 0.1)).replace(".", ","), 22.0 * s, INK, HORIZONTAL_ALIGNMENT_CENTER, 160.0 * s)


func _draw_board(o: Vector2, s: float, phi: float, k: float, current: float) -> void:
	var x := 1030.0
	var y := 120.0
	var rows := [
		["FREKANS", "%s ×10¹⁴ Hz" % str(snappedf(frequency / 1e14, 0.01)).replace(".", ",")],
		["DALGA BOYU", "%d nm" % roundi(Photo.wavelength_nm(frequency))],
		["FOTON ENERJİSİ", "%s eV" % str(snappedf(Photo.photon_energy(frequency), 0.01)).replace(".", ",")],
		["EN FAZLA ENERJİ", "%s eV" % str(snappedf(k, 0.01)).replace(".", ",")],
		["DURDURMA GERİLİMİ", "%s V" % str(snappedf(k, 0.01)).replace(".", ",")],
	]
	for row in rows:
		_t(o + Vector2(x, y) * s, row[0], 15.0 * s, MUTED)
		_t(o + Vector2(x + 230.0, y + 6.0) * s, row[1], 26.0 * s, ACCENT if row[0] == "EN FAZLA ENERJİ" and k > 0.0 else INK, HORIZONTAL_ALIGNMENT_RIGHT, 280.0 * s)
		y += 54.0
	if faulty_display:
		_t(o + Vector2(x, y + 6.0) * s, "CİHAZ AKIM BEKLENTİSİ  %s µA" % str(snappedf(Photo.faulty_current(frequency, intensity, phi), 0.1)).replace(".", ","), 18.0 * s, WARM)


func _draw_graph(o: Vector2, s: float, phi: float, k: float) -> void:
	var gx := 1030.0
	var gy := 470.0
	var gw := 460.0
	var gh := 290.0
	var origin := o + Vector2(gx, gy + gh) * s
	draw_line(origin, origin + Vector2(gw, 0) * s, Color(MUTED, 0.7), 1.5 * s)
	draw_line(origin, origin + Vector2(0, -gh) * s, Color(MUTED, 0.7), 1.5 * s)
	_t(origin + Vector2(gw - 190, 38) * s, "frekans (×10¹⁴ Hz)", 14.0 * s, MUTED)
	_t(origin + Vector2(8, -gh - 8) * s, "K_max (eV)", 14.0 * s, MUTED)
	var f_max := 14e14
	var k_max := 6.0
	var f0 := Photo.threshold_frequency(phi)
	var p0 := origin + Vector2(f0 / f_max * gw, 0.0) * s
	var p1 := origin + Vector2(gw, -Photo.k_max(f_max, phi) / k_max * gh) * s
	draw_line(p0, p1, Color(ACCENT, 0.8), 2.5 * s)
	draw_line(origin, p0, Color(MUTED, 0.5), 2.0 * s)
	draw_line(p0 + Vector2(0, -8 * s), p0 + Vector2(0, 8 * s), WARM, 2.0 * s)
	_t(p0 + Vector2(-34, 30) * s, "f₀", 15.0 * s, WARM)
	var point := origin + Vector2(clampf(frequency / f_max, 0.0, 1.0) * gw, -clampf(k / k_max, 0.0, 1.0) * gh) * s
	draw_circle(point, 7.0 * s, Color(WARM, 0.3))
	draw_circle(point, 4.0 * s, WARM)


func _draw_gate(o: Vector2, s: float) -> void:
	var c := o + Vector2(160, 760) * s
	var state := "KAPI KAPALI"
	var colour := DANGER
	if door_burned:
		state = "KAPI YANDI"
	elif door_open:
		state = "KAPI AÇIK"
		colour = ACCENT
	draw_rect(Rect2(c + Vector2(-90, -30) * s, Vector2(180, 60) * s), Color(colour, 0.12))
	draw_rect(Rect2(c + Vector2(-90, -30) * s, Vector2(180, 60) * s), Color(colour, 0.8), false, 2.0 * s)
	_t(c + Vector2(-90, 8) * s, state, 22.0 * s, colour, HORIZONTAL_ALIGNMENT_CENTER, 180.0 * s)
