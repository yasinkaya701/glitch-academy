extends "res://scripts/physics/bench_view.gd"
## Atış Alanı sahnesi (3B): 45 m kule, ölçekli zemin, çelik toplar, parlayan nokta izi, hedef halkası, ölçü ekranı, konsol.
## Hesap projectile_sim.gd'den gelir. İki top aynı saati kullanır.

signal landed(ball: StringName, x: float, time: float)

const Proj = preload("res://stations/projectile/projectile_sim.gd")
const Kit = preload("res://scripts/physics/stage_kit.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const SCALE := 0.026                  ## dünya birimi / m
const ORIGIN_X := -1.55               ## kulenin x konumu
const STROBE := 0.5                   ## s
const DOT := 0.1                      ## s

var height := 45.0
var speed := 20.0                     ## atılan topun yatay hızı
var use_drop_ball := true             ## bırakılan top de görünsün
var target_range := -1.0              ## < 0: hedef yok
var target_radius := 3.0
var faulty_display := false           ## cihaz yatay hıza bağlı süre yazar
var slow_motion := false
var time := 0.0
var running := false

var _landed := {}
var _hit := false
var _balls: Array[MeshInstance3D] = []
var _dots: Array[Node3D] = []
var _next_dot := 0
var _ring_material: StandardMaterial3D
var _ring: Node3D
var _tower: MeshInstance3D


func _camera_position() -> Vector3:
	return Vector3(0.0, 0.95, 5.3)


func _camera_target() -> Vector3:
	return Vector3(0.0, 0.5, 0.2)


func _screen_size() -> Vector2:
	return Vector2(1.6, 0.9)


func _screen_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)), Vector3(0.95, 1.12, -0.9))


func _build_set() -> void:
	var wood := Stage.pbr_ph("wood_table_001", Vector3(0.7, 0.7, 0.7), Color(0.95, 0.92, 0.88), 0.0)
	var concrete := Stage.pbr_ph("concrete_floor_painted", Vector3(0.6, 0.6, 0.6), Color(0.8, 0.8, 0.82), 0.0)
	var steel := Stage.pbr(Stage.METAL_DIR, Vector3(1.5, 1.5, 1.5), Color(0.92, 0.94, 0.97), 1.0)
	stage.box(Vector3(4.4, 0.06, 1.0), wood, Vector3(0.0, -0.04, 0.0))
	# Kule ve fırlatıcı
	_tower = stage.box(Vector3(0.24, height * SCALE, 0.5), concrete, Vector3(ORIGIN_X - 0.12, height * SCALE * 0.5, 0.0))
	stage.box(Vector3(0.4, 0.03, 0.56), steel, Vector3(ORIGIN_X - 0.04, height * SCALE + 0.015, 0.0))
	stage.cylinder(0.026, 0.12, steel, Vector3(ORIGIN_X + 0.1, height * SCALE + 0.05, 0.05), Vector3(0, 0, 90))
	# Yükseklik çentikleri (kule yüzünde) ve zemin cetveli
	for m in range(0, int(height) + 1, 15):
		_label("%d m" % m, Vector3(ORIGIN_X + 0.02, m * SCALE + 0.01, 0.275), 0.045, Vector3(0, 0, 0))
		stage.box(Vector3(0.03, 0.004, 0.006), steel, Vector3(ORIGIN_X + 0.0, m * SCALE, 0.255))
	for m in range(0, 111, 10):
		var x := ORIGIN_X + m * SCALE
		stage.box(Vector3(0.006, 0.004, 0.05), steel, Vector3(x, 0.0, 0.46))
		_label("%d m" % m, Vector3(x, 0.002, 0.52), 0.05, Vector3(-90, 0, 0))
	# Toplar (0: atılan, 1: bırakılan)
	for i in 2:
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.034
		sphere.height = 0.068
		ball.mesh = sphere
		var material := Stage.pbr(Stage.METAL_DIR, Vector3(1, 1, 1), WARM if i == 0 else ACCENT, 1.0)
		ball.material_override = material
		stage.world.add_child(ball)
		_balls.append(ball)
	# Hedef halkası
	_ring = Node3D.new()
	stage.world.add_child(_ring)
	_ring_material = Stage.glow_material(DANGER, 0.9)
	var torus := MeshInstance3D.new()
	var torus_mesh := TorusMesh.new()
	torus_mesh.outer_radius = 0.1
	torus_mesh.inner_radius = 0.086
	torus.mesh = torus_mesh
	torus.material_override = _ring_material
	torus.position.y = 0.004
	_ring.add_child(torus)
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.086
	disc_mesh.bottom_radius = 0.086
	disc_mesh.height = 0.002
	disc.mesh = disc_mesh
	var disc_material := StandardMaterial3D.new()
	disc_material.albedo_color = Color(DANGER, 0.25)
	disc_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override = disc_material
	disc.position.y = 0.003
	_ring.add_child(disc)
	_label("HEDEF", Vector3(0.0, 0.002, 0.16), 0.045, Vector3(-90, 0, 0), _ring)
	reset()


func _label(text: String, at: Vector3, size_m: float, rotation_deg: Vector3, parent: Node3D = null) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = FONT_REGULAR
	label.font_size = 48
	label.pixel_size = size_m / 48.0
	label.modulate = Color("#dbe4ec")
	label.rotation_degrees = rotation_deg
	label.position = at
	label.shaded = false
	(parent if parent != null else stage.world).add_child(label)


func launch(horizontal_speed: float) -> void:
	speed = horizontal_speed
	time = 0.0
	running = true
	_landed.clear()
	_hit = false
	_clear_dots()


func reset() -> void:
	time = 0.0
	running = false
	_landed.clear()
	_hit = false
	_clear_dots()
	_place()


func _clear_dots() -> void:
	for dot in _dots:
		if is_instance_valid(dot):
			dot.queue_free()
	_dots.clear()
	_next_dot = 0


func fall_time() -> float:
	return Proj.fall_time(height)


func is_hit() -> bool:
	return _hit


func landing_x() -> float:
	return Proj.range_for(height, speed)


func _world_at(x_m: float, drop_m: float) -> Vector3:
	return Vector3(ORIGIN_X + 0.1 + x_m * SCALE, (height - drop_m) * SCALE + 0.034, 0.05)


func _place() -> void:
	if _balls.is_empty():
		return
	var t := minf(time, fall_time())
	var thrown := Proj.state_at(speed, t)
	_balls[0].position = _world_at(thrown["x"], thrown["drop"])
	var dropped := Proj.state_at(0.0, t)
	_balls[1].position = _world_at(0.0, dropped["drop"]) + Vector3(0, 0, -0.1)
	_balls[1].visible = use_drop_ball
	_ring.visible = target_range >= 0.0
	if target_range >= 0.0:
		_ring.position = Vector3(ORIGIN_X + 0.1 + target_range * SCALE, 0.0, 0.05)
		var colour := ACCENT if _hit else DANGER
		_ring_material.albedo_color = colour
		_ring_material.emission = colour


func _process(delta: float) -> void:
	super._process(delta)
	if _balls.is_empty():
		return
	if running:
		time += delta * (0.25 if slow_motion else 1.0)
		var t_fall := fall_time()
		while _next_dot * DOT <= minf(time, t_fall):
			_drop_dot(_next_dot * DOT)
			_next_dot += 1
		if time >= t_fall:
			time = t_fall
			running = false
			_landed[&"thrown"] = t_fall
			landed.emit(&"thrown", landing_x(), t_fall)
			if use_drop_ball:
				_landed[&"dropped"] = t_fall
				landed.emit(&"dropped", 0.0, t_fall)
			if target_range >= 0.0:
				_hit = absf(landing_x() - target_range) <= target_radius
			_dust(_balls[0].position)
	_place()


func _drop_dot(t: float) -> void:
	var big := is_equal_approx(fposmod(t, STROBE), 0.0) or fposmod(t, STROBE) > STROBE - 0.001
	for i in (2 if use_drop_ball else 1):
		var state := Proj.state_at(speed if i == 0 else 0.0, t)
		var dot := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.013 if big else 0.006
		sphere.height = sphere.radius * 2.0
		dot.mesh = sphere
		dot.material_override = Stage.glow_material(WARM if i == 0 else ACCENT, 1.0 if big else 0.7)
		dot.position = _world_at(state["x"], state["drop"]) + (Vector3(0, 0, -0.1) if i == 1 else Vector3.ZERO)
		stage.world.add_child(dot)
		_dots.append(dot)


func _dust(at: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 24
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 70.0
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.6
	particles.gravity = Vector3(0, -1.5, 0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.006
	mesh.height = 0.012
	mesh.material = Stage.glow_material(Color(1.0, 0.8, 0.5), 1.0)
	particles.mesh = mesh
	particles.position = Vector3(at.x, 0.01, at.z)
	stage.world.add_child(particles)
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)


func _draw_screen(canvas: Control, size_px: Vector2) -> void:
	var s := size_px.x / 1600.0
	var state := Proj.state_at(speed, minf(time, fall_time()))
	canvas.draw_string(FONT_REGULAR, Vector2(40, 54) * s, "ATIŞ  ·  YATAY VE DÜŞEY HAREKET", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * s), MUTED)
	var cards: Array = [
		["SÜRE", str(snappedf(time, 0.01)).replace(".", ","), "s", INK],
		["YATAY HIZ", str(snappedf(state["vx"], 0.1)).replace(".", ","), "m/s", WARM],
		["DÜŞEY HIZ", str(snappedf(state["vy"], 0.1)).replace(".", ","), "m/s", INK],
		["MENZİL", str(snappedf(state["x"], 0.1)).replace(".", ","), "m", WARM],
	]
	for k in cards.size():
		var card: Array = cards[k]
		Kit.readout(canvas, Rect2(Vector2(40.0 + 370.0 * k, 110.0) * s, Vector2(350.0, 170.0) * s), card[0], card[1], card[2], FONT_REGULAR, s * 2.0, card[3])
	if target_range >= 0.0:
		canvas.draw_string(FONT, Vector2(40, 360) * s, "HEDEF  %d m  ±%d m" % [int(target_range), int(target_radius)], HORIZONTAL_ALIGNMENT_LEFT, -1, int(36 * s), ACCENT if _hit else DANGER)
	if faulty_display:
		var predicted := Proj.faulty_fall_time(height, speed)
		canvas.draw_string(FONT, Vector2(40, 420) * s, "CİHAZ: atılan top %s s'de düşecek" % str(snappedf(predicted, 0.1)).replace(".", ","), HORIZONTAL_ALIGNMENT_LEFT, -1, int(36 * s), WARM)
		if _landed.has(&"thrown"):
			canvas.draw_string(FONT, Vector2(40, 480) * s, "Kapak %s s'de açılacaktı, kapsül %s s'de indi: ıskaladı" % [str(snappedf(predicted, 0.1)).replace(".", ","), str(snappedf(fall_time(), 0.1)).replace(".", ",")], HORIZONTAL_ALIGNMENT_LEFT, -1, int(30 * s), DANGER)
	if slow_motion:
		canvas.draw_string(FONT_REGULAR, Vector2(40, 480) * s, "¼ hız", HORIZONTAL_ALIGNMENT_LEFT, -1, int(30 * s), MUTED)
