extends Control
## Düşüş Odası sahnesi. Codex'in laboratuvar görseli (chamber_bg.png) üstünde cam odanın içinde düşen cisimler,
## yükseklik şeridi, zemin sensörü ve sağ duvarda ölçü yazıları. Hareket fall_sim.gd'den gelir, çizim süreleri uydurmaz.
## Ölçek: camın üstü bırakma yüksekliği, tabanı sensör (0 m). Toplar görünürlük için ölçeksiz çizilir.

signal landed(results: Dictionary)

const Fall = preload("res://stations/free_fall/fall_sim.gd")
const BACKDROP = preload("res://stations/free_fall/assets/chamber_bg.png")
const SENSOR_OFF = preload("res://stations/free_fall/assets/sensor_plate_off.png")
const SENSOR_ON = preload("res://stations/free_fall/assets/sensor_plate_on.png")

const MAX_RELEASE := 58.0
const PUMP_RATE := 28.0           ## kPa/s
const EXPECTED_TIME := 2.0        ## s, cihazın 20 m için beklediği süre (hava yok varsayımı)

## Görselin piksel koordinatları (1920×1080). Cam içi: x 488–648, tavan 252, sensör üstü 836.
const IMAGE := Vector2(1920, 1080)
const GLASS_LEFT := 488.0
const GLASS_RIGHT := 648.0
const GLASS_TOP := 252.0
const FLOOR_Y := 836.0
const SLOT_X := {&"steel": 531.0, &"foam": 606.0, &"capsule": 568.0}
const BALL_RADIUS := {&"steel": 14.0, &"foam": 19.0, &"capsule": 12.0}
const PUMP_GAUGE := Vector2(190.0, 700.0)
const BOARD := Vector2(1130.0, 330.0)

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")

var release_height := 20.0
var pressure := Fall.ATMOSPHERE
var pressure_target := Fall.ATMOSPHERE
var falling := false
var show_expectation := false     ## cihazın beklentisi ve Misafir imzası (kayma) açık
var time_scale := 1.0
var log_rows: Array[String] = []
var visible_ids: Array = [&"steel", &"foam"]
## Veri kapsülü krizi: sensör kapağı `door_time` ± `door_window` saniyede açıktır. Kaçıran kapsül kaybolur.
var gravity := Fall.G                ## yerel çekim ivmesi (Misafirler bozar, dengeleyici onarır)
var gravity_label := ""             ## panoda "ÇEKİM" satırı; boşsa gösterilmez
var gravity_fixed := false          ## onarıldıysa sahne ışığı sıcaklaşır
var door_enabled := false
var door_time := 3.0
var door_window := 0.05
var capsules := 3
var outcome: StringName = &""       ## &"saved" | &"lost" | &""
var _outcome_clock := 0.0

var _bodies: Dictionary = {}      ## id -> {state, active, landed, result}
var _elapsed := 0.0
var _flash := 0.0
var _clock := 0.0
var _release_countdown := -1.0
var _pending: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	for id in Fall.BODIES:
		_bodies[id] = {"state": Fall.State.new(), "active": false, "landed": false, "result": {}}


# --- Dışarıya açık ---------------------------------------------------------------

func set_bodies(ids: Array) -> void:
	visible_ids = ids


func set_release_height(height: float) -> void:
	release_height = clampf(height, 1.0, MAX_RELEASE)


func set_pressure_target(kpa: float) -> void:
	pressure_target = clampf(kpa, 0.0, Fall.ATMOSPHERE)


func is_pumping() -> bool:
	return absf(pressure - pressure_target) > 0.05


func seconds_text(value: float) -> String:
	return ("%.2f s" % value).replace(".", ",")


## Mıknatıslar bırakır, düşüş başlar. Süreler `landed` ile bildirilir.
func release(ids: Array) -> void:
	if falling or _release_countdown >= 0.0:
		return
	_pending = ids
	_release_countdown = 0.7


## Sar: cisimleri bırakma anına geri götürür.
func rewind() -> void:
	falling = false
	_release_countdown = -1.0
	for id in _bodies:
		_bodies[id]["active"] = false
		_bodies[id]["landed"] = false
		_bodies[id]["state"] = Fall.State.new()
	_elapsed = 0.0


func reset_bodies() -> void:
	rewind()


# --- Dönüşüm ---------------------------------------------------------------------

func _fit() -> Dictionary:
	var factor := maxf(size.x / IMAGE.x, size.y / IMAGE.y)
	var shown := IMAGE * factor
	return {"scale": factor, "offset": (size - shown) * 0.5}


func _p(x: float, y: float) -> Vector2:
	var fit := _fit()
	return Vector2(x, y) * float(fit["scale"]) + (fit["offset"] as Vector2)


func _pixels_per_meter() -> float:
	return (FLOOR_Y - GLASS_TOP) / release_height


## Cismin merkezinin görseldeki y konumu. `depth` bırakma noktasından aşağı katedilen yol (m).
func _ball_y(id: StringName, depth: float) -> float:
	var bottom := FLOOR_Y - (release_height - minf(depth, release_height)) * _pixels_per_meter()
	return bottom - float(BALL_RADIUS[id])


# --- Her kare --------------------------------------------------------------------

func _process(delta: float) -> void:
	_clock += delta
	pressure = move_toward(pressure, pressure_target, PUMP_RATE * delta)
	_flash = maxf(_flash - delta * 2.2, 0.0)
	_outcome_clock += delta
	if _release_countdown >= 0.0:
		_release_countdown -= delta
		if _release_countdown < 0.0:
			_start_fall()
	if falling:
		_step_fall(delta * time_scale)
	queue_redraw()


func _start_fall() -> void:
	for id in _bodies:
		var data: Dictionary = _bodies[id]
		data["active"] = _pending.has(id)
		data["state"] = Fall.State.new()
		data["landed"] = false
		data["result"] = Fall.fall(id, release_height, pressure, gravity) if _pending.has(id) else {}
	_elapsed = 0.0
	outcome = &""
	falling = true
	Sfx.play(&"click", -10.0)


func _step_fall(delta: float) -> void:
	_elapsed += delta
	var dt := 1.0 / 240.0
	var remaining := delta
	while remaining > 0.0:
		var slice := minf(remaining, dt)
		for id in _bodies:
			var data: Dictionary = _bodies[id]
			if data["active"] and not data["landed"]:
				Fall.step(data["state"], id, pressure, slice, gravity)
		remaining -= slice
	var all_done := true
	for id in _bodies:
		var data: Dictionary = _bodies[id]
		if not data["active"]:
			continue
		if not data["landed"] and (data["state"] as Fall.State).depth >= release_height:
			data["landed"] = true
			_flash = 1.0
			Sfx.play(&"snap", -8.0)
			if id == &"capsule" and door_enabled:
				var arrival: float = data["result"]["time"]
				outcome = &"saved" if absf(arrival - door_time) <= door_window else &"lost"
				_outcome_clock = 0.0
				if outcome == &"lost":
					capsules = maxi(capsules - 1, 0)
					Sfx.play(&"buzz", -8.0)
				else:
					Sfx.play(&"chime", -8.0)
		if not data["landed"]:
			all_done = false
	if all_done:
		falling = false
		var results := {}
		for id in _bodies:
			if _bodies[id]["active"]:
				results[id] = _bodies[id]["result"]
		await get_tree().create_timer(0.7).timeout
		landed.emit(results)


# --- Çizim -----------------------------------------------------------------------

func _draw() -> void:
	var fit := _fit()
	var factor: float = fit["scale"]
	var offset: Vector2 = fit["offset"]
	draw_texture_rect(BACKDROP, Rect2(offset, IMAGE * factor), false)
	_draw_ruler(factor)
	_draw_sensor(factor)
	_draw_rack(factor)
	for id in [&"steel", &"foam", &"capsule"]:
		if visible_ids.has(id):
			_draw_body(id, factor)
	_draw_signature(factor)
	_draw_board(factor)
	_draw_gauge(factor)
	if gravity_fixed:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.72, 0.4, 0.07))


func _font() -> Font:
	return get_theme_default_font()


func _text(position: Vector2, text: String, font_size: float, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(_font(), position, text, align, width, int(font_size), color)


func _nice_step() -> float:
	var steps := [1.0, 2.0, 5.0, 10.0, 20.0]
	for step in steps:
		if release_height / step <= 8.5:
			return step
	return 20.0


func _draw_ruler(factor: float) -> void:
	var step := _nice_step()
	var ppm := _pixels_per_meter()
	var m := 0.0
	while m <= release_height + 0.001:
		var y := FLOOR_Y - m * ppm
		var long := is_equal_approx(fmod(m, step * 2.0), 0.0) or m == 0.0
		draw_line(_p(GLASS_LEFT - 2.0, y), _p(GLASS_LEFT + (14.0 if long else 8.0), y), Color(0.78, 0.9, 0.96, 0.75), 1.5 * factor)
		if long:
			var label := ("%d m" % roundi(m)) if is_equal_approx(m, roundf(m)) else ("%s m" % str(snappedf(m, 0.1)).replace(".", ","))
			_text(_p(GLASS_LEFT - 108.0, y + 6.0), label, 19.0 * factor, Color(0.86, 0.94, 0.98, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 70.0 * factor)
		m += step
	draw_line(_p(GLASS_LEFT - 2.0, GLASS_TOP), _p(GLASS_RIGHT, GLASS_TOP), Color(WARM, 0.35), 1.0 * factor)


func _draw_sensor(factor: float) -> void:
	var texture: Texture2D = SENSOR_ON if _flash > 0.05 else SENSOR_OFF
	var width := (GLASS_RIGHT - GLASS_LEFT) * 0.98
	var rect := Rect2(_p((GLASS_LEFT + GLASS_RIGHT) * 0.5 - width * 0.5, FLOOR_Y - 12.0), Vector2(width, 26.0) * factor)
	var tint := Color(1, 1, 1, 0.55 + 0.45 * _flash)
	if outcome == &"saved" and _outcome_clock < 2.5:
		tint = Color(0.5, 1.0, 0.8, 0.9)
	elif outcome == &"lost" and _outcome_clock < 2.5:
		tint = Color(1.0, 0.4, 0.35, 0.95)
	draw_texture_rect(texture, rect, false, tint)
	_draw_outcome(factor)


func _draw_outcome(factor: float) -> void:
	if outcome == &"" or _outcome_clock > 2.6:
		return
	var centre := _p((GLASS_LEFT + GLASS_RIGHT) * 0.5, FLOOR_Y - 8.0)
	var t := _outcome_clock
	if outcome == &"saved":
		draw_arc(centre, (20.0 + 150.0 * t) * factor, 0.0, TAU, 48, Color(ACCENT, clampf(1.0 - t / 1.6, 0.0, 1.0)), 2.5 * factor)
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 16:
			var angle := rng.randf_range(PI * 1.05, PI * 1.95)
			var speed := rng.randf_range(60.0, 170.0)
			var pos := centre + Vector2(cos(angle), sin(angle)) * speed * t * factor + Vector2(0.0, 220.0 * t * t * factor)
			draw_rect(Rect2(pos, Vector2(rng.randf_range(3.0, 7.0), rng.randf_range(2.0, 4.0)) * factor), Color("#e58a42", clampf(1.0 - t / 2.0, 0.0, 1.0)))


func _draw_rack(factor: float) -> void:
	var y := GLASS_TOP - 8.0
	draw_rect(Rect2(_p(GLASS_LEFT + 6.0, y), Vector2(GLASS_RIGHT - GLASS_LEFT - 12.0, 6.0) * factor), Color("#4b535c"))
	for id in visible_ids:
		var bx: float = SLOT_X[id]
		var holding: bool = not (_bodies[id]["active"] and falling) and not _bodies[id]["landed"]
		draw_rect(Rect2(_p(bx - 7.0, y + 4.0), Vector2(14.0, 6.0) * factor), Color("#2b3138"))
		if holding:
			draw_circle(_p(bx, y + 11.0), 3.2 * factor, Color(WARM, 0.55 + 0.25 * sin(_clock * 4.0)))


func _draw_body(id: StringName, factor: float) -> void:
	var data: Dictionary = _bodies[id]
	var depth := (data["state"] as Fall.State).depth if data["active"] else 0.0
	var radius: float = BALL_RADIUS[id]
	var centre := _p(SLOT_X[id], _ball_y(id, depth))
	var r := radius * factor
	if data["active"] and falling and not data["landed"]:
		var speed := (data["state"] as Fall.State).speed
		var streak := clampf(speed * 0.9, 0.0, 70.0) * factor
		draw_rect(Rect2(centre + Vector2(-r * 0.6, -streak - r * 0.5), Vector2(r * 1.2, streak)), Color(0.8, 0.9, 1.0, 0.08))
	var shadow_y := _p(SLOT_X[id], FLOOR_Y + 2.0)
	var height_ratio := 1.0 - clampf((FLOOR_Y - (_ball_y(id, depth) + radius)) / maxf(FLOOR_Y - GLASS_TOP, 1.0), 0.0, 1.0)
	draw_set_transform(shadow_y, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, r * (0.5 + 0.7 * height_ratio), Color(0, 0, 0, 0.12 + 0.28 * height_ratio))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if id == &"capsule":
		_draw_capsule(centre, r)
	elif id == &"steel":
		_draw_sphere(centre, r, Color("#3c434b"), Color("#9aa3ad"), Color("#eef3f7"))
	else:
		_draw_sphere(centre, r, Color("#a88a3d"), Color("#e6c777"), Color("#fff1c4"))
	if data["active"]:
		var done: bool = data["landed"]
		var label := seconds_text(data["result"]["time"] if done else _elapsed)
		_text(centre + Vector2(r + 8.0 * factor, 5.0 * factor), label, 18.0 * factor, ACCENT if done else INK)


func _draw_sphere(centre: Vector2, r: float, dark: Color, mid: Color, light: Color) -> void:
	draw_circle(centre, r, dark)
	var steps := 9
	for i in steps:
		var t := float(i) / float(steps - 1)
		var colour := mid.lerp(light, t * t)
		var shift := Vector2(-0.34, -0.38) * r * t * 0.9
		draw_circle(centre + shift, r * lerpf(0.96, 0.2, t), colour)
	draw_circle(centre + Vector2(-0.38, -0.42) * r, r * 0.12, Color(1, 1, 1, 0.9))
	draw_arc(centre, r, 0.0, TAU, 40, Color(0, 0, 0, 0.35), 1.2)


func _draw_capsule(centre: Vector2, r: float) -> void:
	var body := Rect2(centre - Vector2(r, r * 1.7), Vector2(r * 2.0, r * 3.4))
	draw_rect(body, Color("#b86a2e"))
	draw_rect(Rect2(body.position, Vector2(r * 0.7, body.size.y)), Color("#e58a42"))
	draw_circle(centre + Vector2(0.0, -r * 1.7), r, Color("#d17a38"))
	draw_circle(centre + Vector2(0.0, r * 1.7), r, Color("#8e4f22"))
	draw_rect(Rect2(centre + Vector2(-r, -r * 0.2), Vector2(r * 2.0, r * 0.4)), ACCENT)


## Misafir imzası: kayma açıkken cisimlerde renk ayrışması ve camda kısa yırtık çizgileri.
func _draw_signature(factor: float) -> void:
	if not show_expectation:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = floori(_clock * 9.0)
	for i in 3:
		if rng.randf() < 0.55:
			continue
		var y := rng.randf_range(GLASS_TOP + 30.0, FLOOR_Y - 20.0)
		var x := rng.randf_range(GLASS_LEFT + 4.0, GLASS_RIGHT - 60.0)
		var w := rng.randf_range(24.0, 70.0)
		draw_rect(Rect2(_p(x, y), Vector2(w, 1.8) * factor), Color("#6fe3f2", 0.55))
		draw_rect(Rect2(_p(x + 4.0, y + 3.0), Vector2(w, 1.4) * factor), Color("#f26fb8", 0.4))
	for id in visible_ids:
		var data: Dictionary = _bodies[id]
		if not data["active"] or data["landed"]:
			continue
		var depth := (data["state"] as Fall.State).depth
		var centre := _p(SLOT_X[id], _ball_y(id, depth))
		var r: float = BALL_RADIUS[id] * factor
		draw_arc(centre + Vector2(2.5, 0.0) * factor, r, 0.0, TAU, 32, Color("#6fe3f2", 0.5), 1.5)
		draw_arc(centre + Vector2(-2.5, 0.0) * factor, r, 0.0, TAU, 32, Color("#f26fb8", 0.4), 1.5)


func _draw_board(factor: float) -> void:
	var x := BOARD.x - 40.0
	var y := BOARD.y - 40.0
	_text(_p(x, y), "SÜRE", 18.0 * factor, MUTED)
	var row := y + 62.0
	for id in [&"steel", &"foam", &"capsule"]:
		if not visible_ids.has(id):
			continue
		var data: Dictionary = _bodies[id]
		var name: String = Fall.BODIES[id]["name"].to_upper()
		var value := "—"
		var colour := MUTED
		if data["landed"]:
			value = seconds_text(data["result"]["time"])
			colour = ACCENT
		elif data["active"]:
			value = seconds_text(_elapsed)
			colour = INK
		_text(_p(x, row), name, 26.0 * factor, INK)
		_text(_p(x + 380.0, row), value, 40.0 * factor, colour, HORIZONTAL_ALIGNMENT_RIGHT, 260.0 * factor)
		row += 68.0
	if show_expectation:
		draw_line(_p(x, row - 28.0), _p(x + 640.0, row - 28.0), Color(WARM, 0.5), 1.0 * factor)
		_text(_p(x, row + 6.0), "CİHAZ BEKLENTİSİ", 20.0 * factor, WARM)
		_text(_p(x + 380.0, row + 6.0), seconds_text(EXPECTED_TIME if not door_enabled else door_time), 34.0 * factor, WARM, HORIZONTAL_ALIGNMENT_RIGHT, 260.0 * factor)
		row += 68.0
	if gravity_label != "":
		draw_line(_p(x, row - 28.0), _p(x + 640.0, row - 28.0), Color(MUTED, 0.35), 1.0 * factor)
		_text(_p(x, row + 6.0), "ÇEKİM", 20.0 * factor, MUTED)
		_text(_p(x + 380.0, row + 6.0), gravity_label, 34.0 * factor, ACCENT if gravity_fixed else WARM, HORIZONTAL_ALIGNMENT_RIGHT, 260.0 * factor)
		row += 68.0
	if door_enabled:
		_draw_door(x, row, factor)
		row += 150.0
	if not log_rows.is_empty():
		_text(_p(x, row), "KAYIT", 17.0 * factor, MUTED)
		row += 34.0
		for line in log_rows.slice(maxi(log_rows.size() - 6, 0)):
			_text(_p(x, row), line, 20.0 * factor, Color(MUTED, 0.95))
			row += 31.0


## Sensör kapağı: zaman çizelgesi üzerinde açık pencere ve kapsülün ilerleyişi, kalan kapsül sayısı, sonuç.
func _draw_door(x: float, row: float, factor: float) -> void:
	var span := door_time * 1.35
	var width := 640.0
	var left := _p(x, row + 12.0)
	draw_line(left, _p(x + width, row + 12.0), Color(MUTED, 0.5), 2.0 * factor)
	var win_a := x + width * (door_time - door_window) / span
	var win_b := x + width * (door_time + door_window) / span
	draw_rect(Rect2(_p(win_a, row - 4.0), Vector2(maxf(win_b - win_a, 8.0), 32.0) * factor), Color(ACCENT, 0.85))
	_text(_p(win_a - 80.0, row - 14.0), "KAPAK AÇIK  %s" % seconds_text(door_time), 17.0 * factor, ACCENT)
	if falling or _elapsed > 0.0:
		var marker := x + width * clampf(_elapsed / span, 0.0, 1.0)
		var shown: bool = _bodies[&"capsule"]["landed"] and _bodies[&"capsule"]["active"]
		if shown:
			marker = x + width * clampf(float(_bodies[&"capsule"]["result"]["time"]) / span, 0.0, 1.0)
		draw_rect(Rect2(_p(marker - 3.0, row - 12.0), Vector2(6.0, 48.0) * factor), WARM if not shown else (ACCENT if outcome == &"saved" else DANGER))
	var stock := ""
	for i in 3:
		stock += "●  " if i < capsules else "○  "
	_text(_p(x, row + 76.0), "KAPSÜL  " + stock.strip_edges(), 24.0 * factor, INK)
	if outcome == &"saved" and _outcome_clock < 6.0:
		_text(_p(x + 300.0, row + 76.0), "VERİ KURTARILDI", 26.0 * factor, ACCENT)
	elif outcome == &"lost" and _outcome_clock < 6.0:
		_text(_p(x + 300.0, row + 76.0), "VERİ KAYBI", 26.0 * factor, DANGER)


func _draw_gauge(factor: float) -> void:
	var text := ("%d kPa" % roundi(pressure)) if pressure >= 1.0 else ("%.1f kPa" % pressure).replace(".", ",")
	_text(_p(PUMP_GAUGE.x - 60.0, PUMP_GAUGE.y - 30.0), "BASINÇ", 17.0 * factor, MUTED)
	var colour := ACCENT if pressure < 3.0 else (WARM if is_pumping() else INK)
	_text(_p(PUMP_GAUGE.x - 60.0, PUMP_GAUGE.y + 14.0), text, 38.0 * factor, colour)
