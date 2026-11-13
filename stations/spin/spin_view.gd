extends "res://scripts/physics/bench_view.gd"
## Stern–Gerlach sahnesi (3B): fırın, cam vakum tüpü, en fazla üç süzgeç mıknatısı (gerçek nal mıknatısı), dedektör (X-ışını tüpü),
## ölçü ekranı (iki iz birikir) ve konsol. Atomlar tek tek örneklenir (spin_sim.gd). Spin dönen küre olarak çizilmez:
## durum yalnızca yukarı/aşağı kanalıdır (docs/EXPERIMENTS.md).

signal hits_changed
signal intro_finished

const Spin = preload("res://stations/spin/spin_sim.gd")
const Kit = preload("res://scripts/physics/stage_kit.gd")

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const BEAM_Y := 450.0
const OVEN_X := 150.0
const STAGE_X := [430.0, 700.0, 970.0]
const DETECTOR_X := 1190.0
const SCREEN_X := 1380.0
const CHANNEL := 62.0              ## kanalların eksenden sapması
const SPOT := 95.0                 ## ekranda iz sapması
const INTRO_LEN := 4.6
const TUBE_Y := 0.36

var stages: Array = [{}, {}, {}]
var detector_axis: StringName = &"z"
var running := true
var show_classical := false
var rate := 22.0                   ## atom/s

var up_hits := 0
var down_hits := 0
var emitted := 0

var gradient := 1.0               ## alan eğimi çarpanı (iki iz arası açılma)
var oven_temp := 1000.0          ## K, gümüş atom demeti
var faulty := false                ## arıza: tüp camında çatlak
var intro_t := -1.0                ## >= 0 iken açılış oynuyor
var repair_t := -1.0               ## onarım parlaması

var _atoms: Array[Dictionary] = []
var _marks: Array[Dictionary] = []
var _spawn := 0.0
var _clock := 0.0
var _rng := RandomNumberGenerator.new()
var _magnets: Array[Node3D] = []
var _station_labels: Array[Label3D] = []
var _crack: Node3D
var _field_lines: Array[Node3D] = []
var _atom_mesh: SphereMesh
var _atom_material: StandardMaterial3D
var _dead_material: StandardMaterial3D


func _camera_position() -> Vector3:
	return Vector3(0.0, 1.2, 4.7)


func _camera_target() -> Vector3:
	return Vector3(0.0, 0.66, 0.2)


func _screen_size() -> Vector2:
	return Vector2(1.5, 0.84)


func _screen_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)), Vector3(1.22, 1.0, -0.9))


func wx(x_ref: float) -> float:
	return -1.55 + (x_ref - OVEN_X) / (SCREEN_X - OVEN_X) * 3.1


func wy(y_ref: float) -> float:
	return TUBE_Y + (BEAM_Y - y_ref) / CHANNEL * 0.1


func _ready() -> void:
	_rng.randomize()
	super._ready()


func _build_set() -> void:
	var wood := Stage.pbr_ph("wood_table_001", Vector3(0.7, 0.7, 0.7), Color(0.95, 0.92, 0.88), 0.0)
	var steel := Stage.pbr(Stage.METAL_DIR, Vector3(1.5, 1.5, 1.5), Color(0.92, 0.94, 0.97), 1.0)
	stage.box(Vector3(4.2, 0.06, 0.9), wood, Vector3(0, -0.04, 0))
	# Vakum tüpü: cam gövde, uç kapakları, iç ışın çizgisi, tezgâh ayakları
	var glass := Stage.glass_material(Color("#cfe6f2"), 0.16)
	stage.cylinder(0.14, 3.2, glass, Vector3(0, TUBE_Y, 0), Vector3(0, 0, 90))
	for end in [-1.0, 1.0]:
		stage.cylinder(0.148, 0.05, steel, Vector3(end * 1.6, TUBE_Y, 0), Vector3(0, 0, 90))
	stage.cylinder(0.0035, 3.0, Stage.glow_material(Color("#8fdcc8"), 0.5), Vector3(0, TUBE_Y, 0), Vector3(0, 0, 90))
	for x in [-1.1, 0.0, 1.1]:
		stage.box(Vector3(0.12, TUBE_Y - 0.12, 0.16), steel, Vector3(x, (TUBE_Y - 0.12) * 0.5, 0.0))
	# Fırın
	stage.box(Vector3(0.34, 0.36, 0.36), steel, Vector3(-1.82, 0.18, 0.0))
	stage.box(Vector3(0.012, 0.03, 0.2), Stage.glow_material(Color("#ff8a3d"), 1.6), Vector3(-1.64, TUBE_Y, 0.0))
	# Süzgeç mıknatısları (gerçek nal mıknatısı) ve etiketleri
	for i in 3:
		var holder := stage.model("res://assets/models/horseshoe-magnet.glb", 0.48)
		holder.rotation_degrees = Vector3(80, 0, 0)
		holder.position = Vector3(wx(STAGE_X[i]), TUBE_Y + 0.2, 0.0)
		_magnets.append(holder)
		var label := Label3D.new()
		label.font = FONT
		label.font_size = 64
		label.pixel_size = 0.09 / 64.0
		label.rotation_degrees = Vector3(-90, 0, 0)
		label.shaded = false
		label.position = Vector3(wx(STAGE_X[i]), 0.004, 0.36)
		stage.world.add_child(label)
		_station_labels.append(label)
	# Dedektör (X-ışını tüpü)
	var detector := stage.model("res://assets/models/x-ray-tube.glb", 0.5)
	detector.position = Vector3(wx(DETECTOR_X), TUBE_Y + 0.05, 0.0)
	detector.rotation_degrees = Vector3(0, 20, 0)
	var detector_label := Label3D.new()
	detector_label.text = "DEDEKTÖR"
	detector_label.font = FONT_REGULAR
	detector_label.font_size = 48
	detector_label.pixel_size = 0.045 / 48.0
	detector_label.modulate = WARM
	detector_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	detector_label.shaded = false
	detector_label.position = Vector3(wx(DETECTOR_X), TUBE_Y + 0.42, 0.0)
	stage.world.add_child(detector_label)
	# Eşit olmayan manyetik alan çizgileri: üst kutba doğru sıklaşır (Stern–Gerlach'ın kilit koşulu)
	var field_material := Stage.glow_material(Color("#7fb8ff"), 0.9)
	for i in 3:
		var group := Node3D.new()
		group.position = Vector3(wx(STAGE_X[i]), TUBE_Y, 0.0)
		stage.world.add_child(group)
		for k in 9:
			var u := float(k) / 8.0 - 0.5
			var line := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.003, 0.3, 0.003)
			line.mesh = mesh
			line.material_override = field_material
			line.position = Vector3(u * 0.17, 0.02, 0.15)
			line.rotation.z = -u * 0.5
			group.add_child(line)
		group.visible = false
		_field_lines.append(group)
	# Tezgâh dekoru: vakum göstergesi ve mikroskop (CC0, Poly Haven)
	var gauge := stage.model("res://assets/polyhaven/models/vintage_spacecraft_instrument/vintage_spacecraft_instrument.gltf", 0.3, null, true)
	gauge.position = Vector3(-1.55, 0.0, 0.4)
	gauge.rotation_degrees = Vector3(0, 25, 0)
	var microscope := stage.model("res://assets/polyhaven/models/industrial_microscope/industrial_microscope.gltf", 0.42, null, true)
	microscope.position = Vector3(1.6, 0.0, 0.38)
	microscope.rotation_degrees = Vector3(0, -30, 0)
	# Çatlak: arıza sırasında tüp camında
	_crack = Node3D.new()
	_crack.position = Vector3(0.1, TUBE_Y, 0.14)
	stage.world.add_child(_crack)
	var crack_material := Stage.glow_material(Color(1, 1, 1), 1.2)
	var points := [Vector3(0, 0.13, 0), Vector3(-0.04, 0.07, 0.0), Vector3(0.03, 0.01, 0.0), Vector3(-0.03, -0.06, 0.0), Vector3(0.04, -0.13, 0.0)]
	for k in 4:
		var a: Vector3 = points[k]
		var b: Vector3 = points[k + 1]
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.003, a.distance_to(b), 0.003)
		segment.mesh = mesh
		segment.material_override = crack_material
		segment.position = (a + b) * 0.5
		segment.rotation.z = atan2(b.x - a.x, b.y - a.y) * -1.0
		_crack.add_child(segment)
	_crack.visible = false
	_atom_mesh = SphereMesh.new()
	_atom_mesh.radius = 0.018
	_atom_mesh.height = 0.036
	_atom_material = Stage.glow_material(ACCENT, 1.6)
	_dead_material = Stage.glow_material(Color("#8a96a0"), 0.3)
	_update_stations()


func _update_stations() -> void:
	for i in 3:
		var active: bool = not (stages[i] as Dictionary).is_empty()
		_magnets[i].visible = active
		_field_lines[i].visible = active
		var label := _station_labels[i]
		if active:
			var stage_info: Dictionary = stages[i]
			label.text = "%d · %s %s" % [i + 1, String(stage_info["axis"]).to_upper(), "↑" if stage_info["sign"] > 0 else "↓"]
			label.modulate = ACCENT
		else:
			label.text = "%d · yok" % (i + 1)
			label.modulate = Color(MUTED, 0.6)


func reset_counts() -> void:
	up_hits = 0
	down_hits = 0
	emitted = 0
	for atom in _atoms:
		if atom.has("node") and is_instance_valid(atom["node"]):
			atom["node"].queue_free()
	_atoms.clear()
	_marks.clear()
	_update_stations()
	hits_changed.emit()


func play_intro() -> void:
	intro_t = 0.0
	reset_counts()


func skip_intro() -> void:
	if intro_t >= 0.0:
		intro_t = INTRO_LEN


func play_repair() -> void:
	faulty = false
	repair_t = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	if _magnets.is_empty():
		return
	_clock += delta
	var frozen := false
	if intro_t >= 0.0:
		intro_t += delta
		frozen = intro_t > 2.4
		var flicker := smoothstep(1.6, 2.4, intro_t) * (1.0 - smoothstep(2.4, 3.2, intro_t))
		stage.key_light.light_energy = 0.9 * (1.0 - 0.7 * flicker * (0.5 + 0.5 * sin(_clock * 40.0)))
		if intro_t >= INTRO_LEN:
			intro_t = -1.0
			frozen = false
			stage.key_light.light_energy = 0.9
			intro_finished.emit()
	_crack.visible = faulty and intro_t < 0.0 or (intro_t > 2.6)
	if repair_t >= 0.0:
		repair_t += delta
		var k := 1.0 - repair_t / 1.8
		stage.key_light.light_color = Color("#fff1de").lerp(Color("#ffb060"), clampf(k, 0.0, 1.0))
		stage.key_light.light_energy = 0.9 + 1.2 * clampf(k, 0.0, 1.0) * clampf(k, 0.0, 1.0)
		if repair_t > 1.8:
			repair_t = -1.0
			stage.key_light.light_color = Color("#fff1de")
			stage.key_light.light_energy = 0.9
	if not frozen:
		if running:
			_spawn += delta * rate * sqrt(oven_temp / 1000.0)
			while _spawn >= 1.0:
				_spawn -= 1.0
				_emit()
		for atom in _atoms:
			atom["t"] += delta * 0.42 * sqrt(oven_temp / 1000.0)
		for atom in _atoms.filter(func(a: Dictionary) -> bool: return a["t"] >= 1.0):
			if atom["result"] != 0:
				_marks.append({"u": -float(atom["result"]) * gradient + _rng.randfn(0.0, 0.07), "dx": _rng.randf_range(-6.0, 6.0), "age": 0.0})
				if atom["result"] > 0:
					up_hits += 1
				else:
					down_hits += 1
				hits_changed.emit()
			if atom.has("node") and is_instance_valid(atom["node"]):
				atom["node"].queue_free()
		_atoms = _atoms.filter(func(a: Dictionary) -> bool: return a["t"] < 1.0)
		if _marks.size() > 500:
			_marks = _marks.slice(_marks.size() - 500)
	for atom in _atoms:
		if not atom.has("node"):
			var node := MeshInstance3D.new()
			node.mesh = _atom_mesh
			stage.world.add_child(node)
			atom["node"] = node
		var pos := _atom_position(atom)
		var absorbed: bool = atom["absorbed_at"] != -1
		(atom["node"] as MeshInstance3D).material_override = _dead_material if absorbed else _atom_material
		(atom["node"] as MeshInstance3D).position = Vector3(wx(pos.x), wy(pos.y), 0.0)


func _emit() -> void:
	emitted += 1
	var outcome := Spin.sample_atom(_rng, stages, detector_axis)
	_atoms.append({"t": 0.0, "absorbed_at": outcome["absorbed_at"], "result": outcome["result"], "jitter": _rng.randf_range(-5.0, 5.0)})


## Atomın yolu üzerinde konum (referans düzlemi). Süzgeç sırasında kanala sapar, absorbe olacaksa durdurucuda biter.
func _atom_position(atom: Dictionary) -> Vector2:
	var active: Array[int] = []
	for i in 3:
		if not (stages[i] as Dictionary).is_empty():
			active.append(i)
	var x := lerpf(OVEN_X + 70.0, SCREEN_X - 20.0, atom["t"])
	var y: float = BEAM_Y + atom["jitter"] * 0.3
	var absorbed: int = atom["absorbed_at"]
	for index in active:
		var centre: float = STAGE_X[index]
		var sign: int = (stages[index] as Dictionary)["sign"]
		var deflect := CHANNEL * gradient * smoothstep(centre - 70.0, centre + 10.0, x) * (1.0 - smoothstep(centre + 60.0, centre + 130.0, x))
		if absorbed == index:
			var kill_sign := -sign
			y = BEAM_Y - kill_sign * deflect * 1.0
			if x > centre + 40.0:
				return Vector2(centre + 40.0, BEAM_Y - kill_sign * CHANNEL * gradient)
		else:
			y += -sign * deflect
	if absorbed == -1 and x > DETECTOR_X - 70.0:
		var amount := smoothstep(DETECTOR_X - 70.0, DETECTOR_X + 90.0, x)
		y = BEAM_Y - atom["result"] * SPOT * gradient * amount
	return Vector2(x, y)


func _draw_screen(canvas: Control, size_px: Vector2) -> void:
	var s := size_px.x / 1600.0
	canvas.draw_string(FONT_REGULAR, Vector2(40, 54) * s, "EKRAN  ·  ATOM İZLERİ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * s), MUTED)
	# Ekran: iki kanal çizgisi, biriken izler, (kriz) cihazın beklediği tek leke
	var plate := Rect2(Vector2(60, 100) * s, Vector2(760, 540) * s)
	canvas.draw_rect(plate, Color("#0a111b"))
	canvas.draw_rect(plate, Color(MUTED, 0.35), false, 2.0)
	var centre_y := plate.position.y + plate.size.y * 0.5
	canvas.draw_line(Vector2(plate.position.x, centre_y), Vector2(plate.end.x, centre_y), Color(MUTED, 0.2), 1.0)
	if show_classical:
		for i in 40:
			var u := float(i) / 39.0
			var yy := centre_y - 180.0 * s + u * 360.0 * s
			var alpha := exp(-pow((u - 0.5) / 0.28, 2.0)) * 0.16
			canvas.draw_circle(Vector2(plate.position.x + plate.size.x * 0.5, yy), 60.0 * s, Color(WARM, alpha))
		canvas.draw_string(FONT, Vector2(plate.position.x + 20.0, plate.position.y + 40.0 * s), "CİHAZ BEKLENTİSİ: tek leke", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * s), WARM)
	for mark in _marks:
		var yy: float = centre_y + float(mark["u"]) * 150.0 * s
		canvas.draw_circle(Vector2(plate.position.x + plate.size.x * 0.5 + mark["dx"] * 3.0 * s, yy), 9.0 * s, Color(ACCENT, 0.85))
	canvas.draw_string(FONT_REGULAR, Vector2(plate.end.x - 120.0 * s, centre_y - 150.0 * s), "yukarı", HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * s), MUTED)
	canvas.draw_string(FONT_REGULAR, Vector2(plate.end.x - 120.0 * s, centre_y + 160.0 * s), "aşağı", HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * s), MUTED)
	# Sayaçlar
	var total := up_hits + down_hits
	var up_pct := 100.0 * float(up_hits) / maxf(float(total), 1.0)
	var down_pct := 100.0 * float(down_hits) / maxf(float(total), 1.0)
	Kit.readout(canvas, Rect2(Vector2(870, 110) * s, Vector2(300, 150) * s), "YUKARI", "%d" % up_hits, "%%%d" % roundi(up_pct), FONT_REGULAR, s * 1.8, ACCENT)
	Kit.readout(canvas, Rect2(Vector2(1190, 110) * s, Vector2(300, 150) * s), "AŞAĞI", "%d" % down_hits, "%%%d" % roundi(down_pct), FONT_REGULAR, s * 1.8, ACCENT)
	Kit.readout(canvas, Rect2(Vector2(870, 290) * s, Vector2(300, 150) * s), "FIRINDAN ÇIKAN", "%d" % emitted, "", FONT_REGULAR, s * 1.8, INK)
	Kit.readout(canvas, Rect2(Vector2(1190, 290) * s, Vector2(300, 150) * s), "DEDEKTÖR EKSENİ", String(detector_axis).to_upper(), "", FONT_REGULAR, s * 1.8, WARM)
	Kit.readout(canvas, Rect2(Vector2(870, 470) * s, Vector2(300, 150) * s), "İKİ İZ ARASI", str(snappedf(3.0 * gradient, 0.1)).replace(".", ","), "mm", FONT_REGULAR, s * 1.8, ACCENT)
	Kit.readout(canvas, Rect2(Vector2(1190, 470) * s, Vector2(300, 150) * s), "FIRIN (Ag)", "%d" % int(oven_temp), "K", FONT_REGULAR, s * 1.8, WARM)
