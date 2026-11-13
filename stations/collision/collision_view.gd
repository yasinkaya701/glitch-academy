extends "res://scripts/physics/bench_view.gd"
## Çarpışma Hattı sahnesi: gerçek 3B laboratuvar. PBR metal ray ve arabalar, kütleyi gösteren pirinç silindirler, cam arşiv kapısı,
## Newton beşiği. 2B katman okuma kartlarını, momentum oklarını ve etiketleri 3B konumlara bağlar.
## Hesap collision_sim.gd'den gelir. Hareket ve kartlar aynı hızları kullanır.

signal collided
signal intro_finished

const Coll = preload("res://stations/collision/collision_sim.gd")
const Kit = preload("res://scripts/physics/stage_kit.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const RED := Color("#ff6a5e")
const CYAN := Color("#35f0ff")
const MAGENTA := Color("#ff3df0")
const UNIT := 0.1                    ## dünya birimi / m
const CART_H := 0.085
const CART_D := 0.17
const CONTACT_T := 1.6                ## s, çarpışmanın gerçekleştiği an
const AFTER_T := 2.2                  ## s, çarpışmadan sonra izlenen süre
const DOOR_X := 1.02
const INTRO_LEN := 7.0
const INTRO_SPEED := 0.95             ## dünya birimi / s, cihazın yanlış hızıyla savrulan çift

var m1 := 2.0
var v1 := 3.0
var m2 := 1.0
var v2 := -3.0
var elastic := false
var show_arrows := true               ## Gör: momentum okları
var heat_limit := -1.0                ## >= 0: kapı ısı sınırı (J) göstergesi
var faulty := false                   ## kapı çatlak
var slow_motion := false
var time := 0.0
var running := false
var intro_t := -1.0

var _vf1 := 0.0
var _vf2 := 0.0
var _hit := false
var _sparks_age := -1.0
var _overlay: Control
var _stage: Stage:
	get:
		return stage
var _carts: Array[Node3D] = []
var _cart_mass: Array[float] = [-1.0, -1.0]
var _glass: MeshInstance3D
var _shards: Array[Dictionary] = []
var _shattered := false
var _shake := 0.0
var _clock := 0.0
var _camera_home := Vector3.ZERO


func _camera_position() -> Vector3:
	return Vector3(0.0, 0.95, 3.5)


func _camera_target() -> Vector3:
	return Vector3(0.0, 0.3, 0.2)


func _screen_size() -> Vector2:
	return Vector2(1.5, 0.84)


func _screen_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)), Vector3(0.35, 0.66, -0.8))


func _ready() -> void:
	super._ready()
	_camera_home = stage.camera.position
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _build_set() -> void:
	var plate := Stage.pbr(Stage.PLATE_DIR, Vector3(1.5, 1.5, 1.5), Color(0.5, 0.52, 0.56), 1.0)
	var aluminium := Stage.pbr(Stage.METAL_DIR, Vector3(2.0, 2.0, 2.0), Color(0.8, 0.83, 0.88), 1.0)
	# Tezgâh levhası, ray ve hava yastığı şeridi
	_stage.box(Vector3(2.9, 0.06, 0.62), plate, Vector3(0, -0.04, 0))
	_stage.box(Vector3(2.8, 0.02, 0.22), aluminium, Vector3(0, 0.01, 0))
	for x in [-1.2, -0.6, 0.0, 0.6, 1.2]:
		_stage.box(Vector3(0.05, 0.07, 0.5), aluminium, Vector3(x, -0.085, 0))
	# Uç tamponları
	for side in [-1.0, 1.0]:
		_stage.box(Vector3(0.05, 0.07, 0.12), aluminium, Vector3(side * 1.4, 0.05, 0))
		_stage.box(Vector3(0.02, 0.05, 0.09), Stage.glow_material(Color(RED), 0.3), Vector3(side * 1.37, 0.05, 0))
	# Araba gövdeleri
	for i in 2:
		var cart := Node3D.new()
		_stage.world.add_child(cart)
		_carts.append(cart)
	# Arşiv kapısı: metal çerçeve ve cam panel
	var frame := Node3D.new()
	frame.position = Vector3(DOOR_X, 0.0, 0.0)
	_stage.world.add_child(frame)
	for z in [-0.17, 0.17]:
		_stage.box(Vector3(0.035, 0.62, 0.035), aluminium, Vector3(0, 0.31, z), frame)
	_stage.box(Vector3(0.035, 0.035, 0.38), aluminium, Vector3(0, 0.63, 0), frame)
	_glass = _stage.box(Vector3(0.012, 0.58, 0.31), Stage.glass_material(Color("#9fe8ff"), 0.30), Vector3(0, 0.31, 0), frame)
	_stage.box(Vector3(0.02, 0.58, 0.012), Stage.glow_material(Color("#6fe3c1"), 0.25), Vector3(0, 0.31, 0.15), frame)
	# Dekor: Newton beşiği (esnek çarpışmayı hatırlatır)
	var cradle := _stage.model("res://assets/models/newtons-cradle.glb", 0.42)
	cradle.position = Vector3(-1.0, 0.2, -0.3)
	cradle.rotation_degrees = Vector3(0, 24, 0)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 0.9, 0.6)
	lamp.light_energy = 0.4
	lamp.light_color = Color("#ffd9b0")
	lamp.omni_range = 4.0
	_stage.world.add_child(lamp)


func _width(mass: float) -> float:
	return 1.5 * 0.24 + 0.0 * mass


func widths() -> Vector2:
	return Vector2(_width(m1), _width(m2)) / UNIT


func _centres0() -> Vector2:
	var d := (widths().x + widths().y) * 0.5
	return Vector2(-v1 * CONTACT_T - d * 0.5, -v2 * CONTACT_T + d * 0.5)


func closing() -> bool:
	return v1 > v2


func final_velocities() -> Vector2:
	if not closing():
		return Vector2(v1, v2)
	if elastic:
		return Coll.elastic(m1, v1, m2, v2)
	var v := Coll.stick_speed(m1, v1, m2, v2)
	return Vector2(v, v)


func heat() -> float:
	if not closing() or elastic:
		return 0.0
	return Coll.heat_stick(m1, v1, m2, v2)


func launch() -> void:
	time = 0.0
	running = true
	_hit = false
	_sparks_age = -1.0
	var f := final_velocities()
	_vf1 = f.x
	_vf2 = f.y


func reset() -> void:
	time = 0.0
	running = false
	_hit = false
	_sparks_age = -1.0
	_restore_door()


func play_intro() -> void:
	intro_t = 0.0
	reset()


func skip_intro() -> void:
	if intro_t >= 0.0:
		intro_t = INTRO_LEN


func finished() -> bool:
	return _hit and not running


func _centres_at(t: float) -> Vector2:
	var c := _centres0()
	if t <= CONTACT_T or not closing():
		return c + Vector2(v1, v2) * t
	var contact := c + Vector2(v1, v2) * CONTACT_T
	return contact + Vector2(_vf1, _vf2) * (t - CONTACT_T)


func _cart_colour(index: int) -> Color:
	return ACCENT if index == 0 else WARM


## Arabayı kütleye göre yeniden kurar: gövde, renk şeridi, kütle sayısı kadar pirinç silindir.
func _rebuild_cart(index: int, mass: float) -> void:
	var cart := _carts[index]
	for child in cart.get_children():
		child.queue_free()
	var count := int(roundf(mass))
	var width := _width(mass)
	_stage.build_car(cart, _cart_colour(index), count, 1.0 if index == 0 else -1.0)
	cart.scale = Vector3.ONE * 1.5
	cart.set_meta("width", width)
	_cart_mass[index] = mass


func _process(delta: float) -> void:
	_clock += delta
	var dt := delta * (0.25 if slow_motion else 1.0)
	if intro_t >= 0.0:
		intro_t += delta
		if intro_t >= INTRO_LEN:
			intro_t = -1.0
			_restore_door()
			intro_finished.emit()
	if running:
		time += dt
		if not _hit and time >= CONTACT_T and closing():
			_hit = true
			_burst(Vector3(_centres_at(CONTACT_T).x * UNIT + _width(m1) * 0.5, CART_H, 0.0))
			_shake = 1.0
			collided.emit()
		if time >= CONTACT_T + AFTER_T or (not closing() and time >= CONTACT_T + 0.8):
			running = false
			if not closing():
				_hit = true
	if _cart_mass[0] != m1:
		_rebuild_cart(0, m1)
	if _cart_mass[1] != m2:
		_rebuild_cart(1, m2)
	if intro_t >= 0.0:
		_pose_intro()
	else:
		var c := _centres_at(time)
		_carts[0].position = Vector3(c.x * UNIT, 0.0, 0.0)
		_carts[1].position = Vector3(c.y * UNIT, 0.0, 0.0)
	_update_shards(delta)
	_shake = maxf(_shake - delta * 2.2, 0.0)
	_stage.camera.position = _camera_home + Vector3(sin(_clock * 71.0), cos(_clock * 63.0), 0.0) * 0.012 * _shake
	if _sparks_age >= 0.0:
		_sparks_age += delta
	_overlay.queue_redraw()


func _restore_door() -> void:
	_shattered = false
	_shards.clear()
	for child in _stage.world.get_children():
		if child.has_meta("shard"):
			child.queue_free()
	if _glass != null:
		_glass.visible = true


func _burst(at: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 60
	particles.lifetime = 0.7
	particles.explosiveness = 1.0
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 2.2
	particles.gravity = Vector3(0, -4.0, 0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.007
	mesh.height = 0.014
	mesh.material = Stage.glow_material(Color(1.0, 0.75, 0.3), 2.5)
	particles.mesh = mesh
	particles.position = at
	particles.set_meta("shard", true)
	_stage.world.add_child(particles)
	get_tree().create_timer(1.4).timeout.connect(particles.queue_free)
	_sparks_age = 0.0


func _pose_intro() -> void:
	var w1 := _width(2.0)
	var w2 := _width(1.0)
	if _cart_mass[0] != 2.0:
		_rebuild_cart(0, 2.0)
	if _cart_mass[1] != 1.0:
		_rebuild_cart(1, 1.0)
	var t := intro_t
	var before := minf(t, CONTACT_T)
	var approach := (CONTACT_T - before) * 3.0 * UNIT * 1.6
	var after := maxf(t - CONTACT_T, 0.0)
	var front_limit := DOOR_X - 0.045 - w2 * 0.5
	var drift := minf(after * INTRO_SPEED, front_limit - (w1 + w2) * 0.25)
	var base := -(w1 + w2) * 0.25 + drift
	_carts[0].position = Vector3(base - approach - w1 * 0.0, 0.0, 0.0) if t < CONTACT_T else Vector3(base - (w2) * 0.0 - (w1 + w2) * 0.0, 0.0, 0.0)
	_carts[1].position = Vector3(base + (w1 + w2) * 0.5 + approach, 0.0, 0.0)
	if t >= CONTACT_T:
		_carts[0].position = Vector3(base, 0.0, 0.0)
		_carts[1].position = Vector3(base + (w1 + w2) * 0.5, 0.0, 0.0)
	if t > CONTACT_T and t < CONTACT_T + 0.05 and _sparks_age < 0.0:
		_burst(Vector3(base + w1 * 0.5, CART_H, 0.0))
		_shake = 0.6
	var hit_t := CONTACT_T + (front_limit - (w1 + w2) * 0.25) / INTRO_SPEED
	if t >= hit_t and not _shattered:
		_shatter()
		_shake = 1.4


func _shatter() -> void:
	_shattered = true
	_glass.visible = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in 46:
		var shard := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.012, rng.randf_range(0.03, 0.09), rng.randf_range(0.03, 0.08))
		shard.mesh = mesh
		shard.material_override = Stage.glass_material(Color("#9fe8ff"), 0.55)
		shard.position = Vector3(DOOR_X, rng.randf_range(0.05, 0.58), rng.randf_range(-0.15, 0.15))
		shard.set_meta("shard", true)
		_stage.world.add_child(shard)
		_shards.append({"node": shard, "v": Vector3(rng.randf_range(0.2, 1.4), rng.randf_range(0.2, 1.6), rng.randf_range(-0.8, 0.8)), "w": Vector3(rng.randf_range(-8, 8), rng.randf_range(-8, 8), rng.randf_range(-8, 8))})


func _update_shards(delta: float) -> void:
	for shard in _shards:
		var node: MeshInstance3D = shard["node"]
		if not is_instance_valid(node):
			continue
		shard["v"] += Vector3(0, -3.6, 0) * delta
		node.position += (shard["v"] as Vector3) * delta
		node.rotation += (shard["w"] as Vector3) * delta
		if node.position.y < 0.01:
			node.position.y = 0.01
			shard["v"] = Vector3.ZERO
			shard["w"] = Vector3.ZERO


func _font() -> Font:
	return get_theme_default_font()


func _signed(value: float) -> String:
	var text := str(snappedf(value, 0.01)).replace(".", ",")
	return ("+" + text) if value > 0.0 else text


func _scale() -> float:
	return minf(size.x / 1600.0, size.y / 900.0)


func _draw_overlay() -> void:
	var s := _scale()
	var c := _overlay
	if intro_t >= 0.0:
		_draw_intro_overlay(s)
		return
	var centres := _centres_at(time)
	var cart_pos := [centres.x, centres.y]
	var masses := [m1, m2]
	var velocities := [v1, v2] if time < CONTACT_T or not closing() else [_vf1, _vf2]
	for i in 2:
		var top := _stage.project(Vector3(cart_pos[i] * UNIT, 0.2, 0.0))
		var foot := _stage.project(Vector3(cart_pos[i] * UNIT, -0.12, 0.2))
		var colour := _cart_colour(i)
		c.draw_string(_font(), top + Vector2(-60.0, -6.0) * s, "%s  %s kg" % ["A" if i == 0 else "B", str(masses[i]).replace(".", ",")], HORIZONTAL_ALIGNMENT_CENTER, 120.0 * s, int(16.0 * s), INK)
		c.draw_string(_font(), foot + Vector2(-70.0, 14.0) * s, "v = %s m/s" % _signed(velocities[i]), HORIZONTAL_ALIGNMENT_CENTER, 140.0 * s, int(15.0 * s), colour)
		if show_arrows:
			var p: float = masses[i] * velocities[i]
			_arrow(top + Vector2(0.0, -34.0 * s), Vector2(p * 11.0 * s, 0.0), colour, s)
	_draw_door_overlay(s)
	if faulty:
		c.draw_string(_font(), Vector2(40.0, 420.0) * s, "CİHAZ: ortak hız = (|p₁| + |p₂|) / (m₁ + m₂)", HORIZONTAL_ALIGNMENT_LEFT, -1, int(17.0 * s), WARM)


func _draw_ruler(s: float) -> void:
	for m in range(-10, 11, 2):
		var at := _stage.project(Vector3(m * UNIT, -0.075, 0.33))
		_overlay.draw_string(_font(), at + Vector2(-20.0, 0.0) * s, "%d" % m, HORIZONTAL_ALIGNMENT_CENTER, 40.0 * s, int(13.0 * s), Color(MUTED, 0.8))
	_overlay.draw_string(_font(), _stage.project(Vector3(11.0 * UNIT, -0.075, 0.33)) + Vector2(-6.0, 0.0) * s, "m", HORIZONTAL_ALIGNMENT_LEFT, -1, int(13.0 * s), Color(MUTED, 0.8))


func _draw_door_overlay(s: float) -> void:
	var top := _stage.project(Vector3(DOOR_X, 0.68, 0.0))
	_overlay.draw_string(_font(), top + Vector2(-70.0, -10.0) * s, "ARŞİV KAPISI", HORIZONTAL_ALIGNMENT_CENTER, 140.0 * s, int(14.0 * s), MUTED)
	var over := heat_limit >= 0.0 and heat() > heat_limit and _hit
	if faulty or over:
		var a := _stage.project(Vector3(DOOR_X, 0.6, 0.0))
		var points := PackedVector2Array([a, a + Vector2(-10, 70) * s, a + Vector2(14, 130) * s, a + Vector2(-12, 200) * s, a + Vector2(8, 270) * s])
		_overlay.draw_polyline(points, Color(MAGENTA, 0.35), 8.0 * s, true)
		_overlay.draw_polyline(points, Color(1, 1, 1, 0.9), 2.0 * s, true)
	if heat_limit >= 0.0:
		var gauge := Rect2(top + Vector2(-60.0, -52.0) * s, Vector2(120.0, 12.0) * s)
		var q := heat() if _hit else 0.0
		_overlay.draw_rect(gauge, Color(0, 0, 0, 0.55))
		_overlay.draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * clampf(q / (heat_limit * 2.0), 0.0, 1.0), gauge.size.y)), RED if q > heat_limit else ACCENT)
		_overlay.draw_line(gauge.position + Vector2(gauge.size.x * 0.5, -4.0 * s), gauge.position + Vector2(gauge.size.x * 0.5, gauge.size.y + 4.0 * s), WARM, 2.0 * s)
		_overlay.draw_string(_font(), gauge.position + Vector2(-20.0, -10.0 * s), "ISI SINIRI  %d J" % int(heat_limit), HORIZONTAL_ALIGNMENT_LEFT, -1, int(13.0 * s), WARM)


func _arrow(tail: Vector2, vec: Vector2, colour: Color, s: float) -> void:
	if absf(vec.x) < 2.0:
		return
	var tip := tail + vec
	var dir := signf(vec.x)
	_overlay.draw_line(tail, tip, Color(colour, 0.3), 9.0 * s, true)
	_overlay.draw_line(tail, tip, colour, 3.0 * s, true)
	_overlay.draw_colored_polygon(PackedVector2Array([tip + Vector2(dir * 12.0, 0.0) * s, tip + Vector2(0.0, -8.0) * s, tip + Vector2(0.0, 8.0) * s]), colour)


func _draw_screen(canvas: Control, size_px: Vector2) -> void:
	var s := size_px.x / 1600.0
	canvas.draw_string(FONT_REGULAR, Vector2(40, 54) * s, "ARABALAR  ·  MOMENTUM VE ENERJİ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * s), MUTED)
	var before := Coll.momentum(m1, v1, m2, v2)
	var f := final_velocities()
	var after := Coll.momentum(m1, f.x, m2, f.y)
	var ke0 := Coll.kinetic(m1, v1) + Coll.kinetic(m2, v2)
	var ke1 := Coll.kinetic(m1, f.x) + Coll.kinetic(m2, f.y)
	var done := _hit and time >= CONTACT_T
	var cards: Array = [
		["p ÖNCE", _signed(before), "kg·m/s", INK],
		["p SONRA", _signed(after) if done else "—", "kg·m/s" if done else "", INK],
		["Ek ÖNCE", str(snappedf(ke0, 0.1)).replace(".", ","), "J", WARM],
		["Ek SONRA", str(snappedf(ke1, 0.1)).replace(".", ",") if done else "—", "J" if done else "", WARM],
		["ISIYA GİDEN", str(snappedf(ke0 - ke1, 0.1)).replace(".", ",") if done else "—", "J" if done else "", RED],
	]
	for k in cards.size():
		var card: Array = cards[k]
		Kit.readout(canvas, Rect2(Vector2(40.0 + 300.0 * (k % 5), 110.0) * s, Vector2(280.0, 150.0) * s), card[0], card[1], card[2], FONT_REGULAR, s * 1.8, card[3])


func _draw_intro_overlay(_s: float) -> void:
	if intro_t > 0.4 and intro_t < CONTACT_T + 1.0:
		_overlay.draw_string(_font(), Vector2(60.0, 430.0) * _scale(), "CİHAZ: ortak hız = 3 m/s", HORIZONTAL_ALIGNMENT_LEFT, -1, int(20.0 * _scale()), WARM)
