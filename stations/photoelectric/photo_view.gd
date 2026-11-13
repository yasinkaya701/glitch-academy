extends Control
## Fotoelektrik Kapısı sahnesi: lamba, vakum tüpü, metal plaka, fotonlar, sökülen elektronlar, ampermetre ve K_max–f grafiği.
## Hesaplar photo_sim.gd'den gelir, çizim süreleri ya da akımı uydurmaz.

const Photo = preload("res://stations/photoelectric/photo_sim.gd")

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
	var tube := Rect2(o + Vector2(330, 250) * s, Vector2(560, 300) * s)
	var plate_x := tube.position.x + 60.0 * s
	# Lamba
	var lamp := Rect2(o + Vector2(70, 330) * s, Vector2(150, 140) * s)
	draw_rect(lamp, Color("#1b2430"))
	draw_rect(Rect2(lamp.position + Vector2(10, 10) * s, lamp.size - Vector2(20, 20) * s), colour.darkened(0.55))
	draw_rect(Rect2(lamp.position + Vector2(10, 10) * s, lamp.size - Vector2(20, 20) * s), Color(colour, 0.35 + 0.5 * intensity))
	# Işın ve fotonlar
	var beam_a := lamp.position + Vector2(lamp.size.x, lamp.size.y * 0.5)
	var plate_mid := Vector2(plate_x, tube.position.y + tube.size.y * 0.5)
	draw_polygon(PackedVector2Array([beam_a + Vector2(0, -50 * s), plate_mid + Vector2(0, -110 * s), plate_mid + Vector2(0, 110 * s), beam_a + Vector2(0, 50 * s)]),
		PackedColorArray([Color(colour, 0.0), Color(colour, 0.08 * (0.3 + intensity)), Color(colour, 0.08 * (0.3 + intensity)), Color(colour, 0.0)]))
	var photons := int(6 + 22 * intensity)
	var wave := 6.0 + 0.0 * frequency
	for i in photons:
		var u := fposmod(float(i) / float(photons) + _photon_phase * 0.35, 1.0)
		var base := beam_a.lerp(plate_mid, u)
		var lane := (float(i % 5) - 2.0) * 0.28
		base.y += lane * 48.0 * s * (1.0 - u * 0.4)
		var length := 26.0 * s
		var step := Vector2(length / 6.0, 0.0)
		var points := PackedVector2Array()
		var wl := clampf(Photo.wavelength_nm(frequency) / 700.0, 0.35, 1.25)
		for q in 7:
			points.append(base + Vector2(step.x * q, sin((q + _clock * 8.0) * (3.2 / wl)) * wave * s))
		draw_polyline(points, Color(colour, 0.9), 2.0 * s)
	# Vakum tüpü
	draw_rect(tube, Color(0.55, 0.75, 0.9, 0.05))
	draw_rect(tube, Color(0.55, 0.75, 0.9, 0.35), false, 2.0 * s)
	# Plaka (katot) ve anot
	var plate := Rect2(Vector2(plate_x - 12.0 * s, tube.position.y + 40.0 * s), Vector2(24.0 * s, tube.size.y - 80.0 * s))
	draw_rect(plate, Color("#b4895a") if metal != &"zinc" else Color("#9aa7b3"))
	draw_rect(Rect2(plate.position, Vector2(7.0 * s, plate.size.y)), Color(1, 1, 1, 0.25))
	var anode := Rect2(Vector2(tube.end.x - 70.0 * s, tube.position.y + 40.0 * s), Vector2(14.0 * s, tube.size.y - 80.0 * s))
	draw_rect(anode, Color("#8c97a3"))
	# Elektronlar
	var span := (anode.position.x - plate.end.x)
	for e in _electrons:
		var pos := Vector2(plate.end.x + span * e["x"], plate_mid.y + 100.0 * s * e["y"])
		draw_circle(pos, 6.0 * s, Color(ACCENT, 0.25))
		draw_circle(pos, 3.2 * s, ACCENT)
	# Plaka başlığı
	_t(o + Vector2(plate_x / s - 70.0, 224.0) * s, String(Photo.METALS[metal]["name"]).to_upper() + "   φ = %s eV" % str(phi).replace(".", ","), 18.0 * s, MUTED)
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
