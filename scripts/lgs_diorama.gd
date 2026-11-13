extends SubViewportContainer
## Procedural miniature sets for the six LGS missions. Each shape is part of the lesson model.

const LABEL_FONT = preload("res://assets/fonts/IBMPlexSans.ttf")
const CHALK_FONT = preload("res://assets/fonts/Kalam-Regular.ttf")

signal proof_animation_finished

@export var mission_id: StringName = &"seasons"

const ColorSet := {
	"seasons": [Color("#f6b94a"), Color("#55d7c4"), Color("#284e72")],
	"bridge": [Color("#edb45c"), Color("#53c7bd"), Color("#546d82")],
	"turkish": [Color("#6ea8ff"), Color("#ff7e67"), Color("#8ba7b7")],
	"history": [Color("#ca9af6"), Color("#f2bf69"), Color("#68839a")],
	"english": [Color("#68c9f0"), Color("#f4c86a"), Color("#537890")],
	"religion": [Color("#efcb77"), Color("#5fc7a9"), Color("#617687")],
}

var _set: Node3D
var _stage := 0
var _solved := false
var _fault_visible := false
var _spin := 0.0
var _proof_focus := -1
var _proof_repaired := false
var proof_animation_done := false
var _proof_animation_started := false
var _proof_labels: Array[Label3D] = []
var _chalk_tip: MeshInstance3D
var _meridyen_core: MeshInstance3D


func _ready() -> void:
	_set = get_node("Viewport/World/Setpiece")
	if mission_id == &"bridge":
		var camera := get_node("Viewport/World/Camera3D") as Camera3D
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 7.8
		camera.position = Vector3(-0.15, 1.85, 13.0)
		camera.look_at(Vector3(-0.15, 1.85, 0.0), Vector3.UP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild()


func set_lesson_state(stage: int, solved: bool, fault_visible := false, proof_focus := -1, proof_repaired := false) -> void:
	_stage = stage
	_solved = solved
	_fault_visible = fault_visible
	_proof_focus = proof_focus
	_proof_repaired = proof_repaired
	if is_node_ready():
		_rebuild()


func _process(delta: float) -> void:
	_spin += delta
	if mission_id == &"seasons":
		var sun := _set.get_node_or_null("Sun")
		if sun:
			sun.rotation.y = _spin * 0.18
	if mission_id == &"bridge":
		var orb := _set.get_node_or_null("MeridyenOrb") as Node3D
		if orb:
			orb.position.y = 1.78 + sin(_spin * 1.25) * 0.075
			orb.rotation.y = sin(_spin * 0.42) * 0.16
			var orbit_a := orb.get_node_or_null("OrbitA") as Node3D
			var orbit_b := orb.get_node_or_null("OrbitB") as Node3D
			if orbit_a:
				orbit_a.rotation.y = _spin * 0.92
			if orbit_b:
				orbit_b.rotation.x = 0.72 + sin(_spin * 0.6) * 0.12
			if _meridyen_core:
				var pulse := 1.0 + sin(_spin * 2.4) * 0.035
				_meridyen_core.scale = Vector3.ONE * pulse
	var beacon := _set.get_node_or_null("SignalBeacon")
	if beacon:
		beacon.scale.y = 0.92 + 0.08 * sin(_spin * 2.2)


func _rebuild() -> void:
	for child in _set.get_children():
		child.queue_free()
	var colors: Array = ColorSet.get(String(mission_id), ColorSet["seasons"])
	var accent: Color = colors[0]
	var active: Color = Color("#74e2cf") if _solved else Color("#ff806f") if _fault_visible else accent
	_add_stage(accent)
	match mission_id:
		&"seasons": _make_seasons(active, colors)
		&"bridge": _make_identity_proof(active, colors)
		&"turkish": _make_safety_door(active, colors)
		&"history": _make_archive(active, colors)
		&"english": _make_supply_station(active, colors)
		&"religion": _make_community_archive(active, colors)
	if mission_id == &"bridge" and not proof_animation_done and not _proof_animation_started:
		_proof_animation_started = true
		_animate_proof.call_deferred()


func _add_stage(accent: Color) -> void:
	var deck_width := 11.6 if mission_id == &"bridge" else 5.4
	var floor_width := 11.0 if mission_id == &"bridge" else 4.85
	_box("Deck", Vector3(0, -0.13, 0), Vector3(deck_width, 0.22, 4.4), Color("#10283a"), _set)
	_box("FloorInset", Vector3(0, 0.0, 0), Vector3(floor_width, 0.035, 3.85), Color("#18384b"), _set)
	if mission_id != &"bridge":
		_torus("Rim", Vector3(0, 0.05, 0), 2.15, 2.2, 0.026, accent.darkened(0.36), _set)
	if mission_id != &"bridge":
		var label := _label("SceneTitle", _title_for(mission_id), Vector3(-2.25, 1.8, -1.45), accent, 31)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _make_seasons(active: Color, colors: Array) -> void:
	# Orbit ring and four season locations make revolution and fixed axial direction visible.
	var sun_pos := Vector3(0.0, 0.55, 0.0)
	var earth_pos := Vector3(-1.5, 0.48, 0.0) if _stage >= 2 else Vector3(1.5, 0.48, 0.0)
	_sphere("Sun", sun_pos, Vector3(0.48, 0.48, 0.48), Color("#ffd16c"), _set, true)
	_torus("SunCorona", sun_pos, 0.58, 0.62, 0.035, Color("#ed9e42"), _set)
	_torus("Orbit", Vector3(0, 0.48, 0), 1.48, 1.52, 0.018, Color("#7594a7"), _set)
	var active_marker := 2 if _stage >= 2 else 0
	for i in 4:
		var angle := TAU * float(i) / 4.0
		var pos := Vector3(cos(angle) * 1.5, 0.48, sin(angle) * 1.5)
		var color := active if i == active_marker else Color("#7895a9")
		_torus("SeasonMarker%d" % i, pos, 0.11, 0.15, 0.022, color, _set)
		if i == 0 or i == 2:
			_label("SeasonLabel%d" % i, ["HAZİRAN", "ARALIK"][i / 2], pos + Vector3(0.0, 0.3, 0.0), color, 20)
	_sphere("Earth", earth_pos, Vector3(0.42, 0.42, 0.42), Color("#2686a9"), _set)
	var tilt_x := 0.0 if _stage == 0 and not _solved else 0.18
	var axis_offset := Vector3(tilt_x, -0.39, 0.0)
	_sphere("NorthCap", earth_pos - axis_offset, Vector3(0.11, 0.055, 0.12), Color("#c6eef0"), _set)
	_sphere("SouthCap", earth_pos + axis_offset, Vector3(0.11, 0.055, 0.12), Color("#c6eef0"), _set)
	_rod("Axis", earth_pos + axis_offset, earth_pos - axis_offset, 0.025, active, _set)
	_label("TiltLabel", "0°" if tilt_x == 0.0 else "23,5°", earth_pos + Vector3(-0.16, 0.63, 0.14), active, 25)
	# Recessed half-sphere light bands show unequal illumination.
	for i in 3:
		var ray_x: float = lerp(signf(earth_pos.x) * 0.3, earth_pos.x - signf(earth_pos.x) * 0.36, (float(i) + 0.5) / 3.0)
		_box("Ray%d" % i, Vector3(ray_x, 0.49, 0.02), Vector3(0.36, 0.018, 0.04), Color("#ffe6a0"), _set, Vector3(0, 0, deg_to_rad(-8 + i * 8)), true)


func _make_identity_proof(active: Color, colors: Array) -> void:
	_make_proof_board()
	var x_left := 1.2
	var y_bottom := 0.34
	var a := 1.4
	var b := 1.0
	var z := 0.62
	var square_center := Vector3(x_left + (a + b) * 0.5, y_bottom + (a + b) * 0.5, 0.48)
	_box("AreaSquareBase", square_center, Vector3(a + b + 0.08, a + b + 0.08, 0.18), Color("#263d55"), _set)
	_box("AreaSquareOutline", square_center + Vector3(0, 0, 0.13), Vector3(a + b + 0.04, a + b + 0.04, 0.06), Color("#bed0dc"), _set)
	var a_square := _box("AreaA2", Vector3(x_left + a * 0.5, y_bottom + a * 0.5, z), Vector3(a, a, 0.2), Color("#4a91c9"), _set)
	var b_square := _box("AreaB2", Vector3(x_left + a + b * 0.5, y_bottom + a + b * 0.5, z), Vector3(b, b, 0.2), Color("#e8a34e"), _set)
	_label("AreaLabelA2", "a²", a_square.position + Vector3(0, 0, 0.14), Color("#f2f8fb"), 32).pixel_size = 0.011
	_label("AreaLabelB2", "b²", b_square.position + Vector3(0, 0, 0.14), Color("#fff5df"), 27).pixel_size = 0.011
	var ab_color := Color("#e5645a") if not _proof_repaired else Color("#55cbb3")
	var ab_top_target := Vector3(x_left + a * 0.5, y_bottom + a + b * 0.5, z)
	var ab_side_target := Vector3(x_left + a + b * 0.5, y_bottom + a * 0.5, z)
	var ab_top_start := Vector3(4.5, y_bottom + a + b * 0.5 + 0.28, z + 0.15)
	var ab_side_start := Vector3(5.65, y_bottom + a * 0.5 - 0.14, z + 0.15)
	var ab_top := _box("AreaAB1", ab_top_start, Vector3(a, b, 0.2), ab_color, _set)
	var ab_side := _box("AreaAB2", ab_side_start, Vector3(b, a, 0.2), ab_color, _set)
	var ab_top_label := _label("AreaLabelAB1", "ab", ab_top.position + Vector3(0, 0, 0.14), Color("#fff1ef"), 25)
	var ab_side_label := _label("AreaLabelAB2", "ab", ab_side.position + Vector3(0, 0, 0.14), Color("#fff1ef"), 25)
	ab_top_label.pixel_size = 0.011
	ab_side_label.pixel_size = 0.011
	if _proof_repaired:
		var snap_tween := create_tween().set_parallel(true)
		snap_tween.tween_property(ab_top, "position", ab_top_target, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		snap_tween.tween_property(ab_side, "position", ab_side_target, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		snap_tween.tween_property(ab_top_label, "position", ab_top_target + Vector3(0, 0, 0.14), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		snap_tween.tween_property(ab_side_label, "position", ab_side_target + Vector3(0, 0, 0.14), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var dimension := _label("SquareDimension", "a + b", Vector3(2.4, 0.18, 0.72), active, 19)
	dimension.pixel_size = 0.010
	_make_meridyen_orb()


func _make_meridyen_orb() -> void:
	var orb := Node3D.new()
	orb.name = "MeridyenOrb"
	orb.position = Vector3(0.1, 1.78, 1.15)
	_set.add_child(orb)
	var shell_material := StandardMaterial3D.new()
	shell_material.albedo_color = Color("#123449")
	shell_material.metallic = 0.78
	shell_material.roughness = 0.2
	shell_material.emission_enabled = true
	shell_material.emission = Color("#176c7a")
	shell_material.emission_energy_multiplier = 0.48
	_meridyen_core = _sphere("Core", Vector3.ZERO, Vector3(0.45, 0.45, 0.45), Color("#123449"), orb)
	_meridyen_core.material_override = shell_material
	var lens := _sphere("Lens", Vector3(0.0, 0.015, 0.355), Vector3(0.245, 0.245, 0.13), Color("#54dcd0"), orb, true)
	lens.material_override = _mat(Color("#64e9dc"), true)
	var pupil := _sphere("Pupil", Vector3(0.0, 0.015, 0.468), Vector3(0.11, 0.11, 0.06), Color("#082d37"), orb)
	pupil.material_override = shell_material.duplicate()
	_sphere("LensGlint", Vector3(-0.045, 0.07, 0.518), Vector3(0.038, 0.038, 0.028), Color("#f3fff6"), orb, true)
	var orbit_a := Node3D.new()
	orbit_a.name = "OrbitA"
	orbit_a.rotation = Vector3(deg_to_rad(58), 0.0, deg_to_rad(24))
	orb.add_child(orbit_a)
	_torus("OrbitRingA", Vector3.ZERO, 0.56, 0.61, 0.026, Color("#49d5ca"), orbit_a)
	_sphere("OrbitSparkA", Vector3(0.59, 0.0, 0.0), Vector3(0.065, 0.065, 0.065), Color("#f5c476"), orbit_a, true)
	var orbit_b := Node3D.new()
	orbit_b.name = "OrbitB"
	orbit_b.rotation = Vector3(0.72, deg_to_rad(52), deg_to_rad(-34))
	orb.add_child(orbit_b)
	_torus("OrbitRingB", Vector3.ZERO, 0.65, 0.69, 0.018, Color("#edb45c"), orbit_b)
	_sphere("OrbitSparkB", Vector3(-0.67, 0.0, 0.0), Vector3(0.045, 0.045, 0.045), Color("#fff5d8"), orbit_b, true)
	var halo := _torus("Halo", Vector3.ZERO, 0.48, 0.50, 0.008, Color("#83f4e7"), orb)
	halo.rotation.x = PI * 0.5
	var glow := OmniLight3D.new()
	glow.name = "CoreGlow"
	glow.light_color = Color("#54dcd0")
	glow.light_energy = 0.72
	glow.omni_range = 3.2
	orb.add_child(glow)


func _make_proof_board() -> void:
	_proof_labels.clear()
	var board_center := Vector3(-3.25, 1.85, -1.08)
	_box("ProofBoardFrame", board_center + Vector3(0, 0, -0.10), Vector3(4.95, 3.88, 0.14), Color("#594333"), _set)
	_box("ProofBoardFace", board_center, Vector3(4.75, 3.68, 0.12), Color("#182b25"), _set)
	_box("ChalkTray", Vector3(-3.25, -0.04, -0.76), Vector3(4.82, 0.11, 0.28), Color("#725438"), _set)
	_box("ChalkStick", Vector3(-5.0, 0.055, -0.58), Vector3(0.36, 0.045, 0.07), Color("#f0eee2"), _set)
	var heading := _chalk_label("ProofBoardHeading", "MERİDYEN  ·  İSPAT", Vector3(-3.25, 3.18, -0.88), Color("#fffdf5"), 28)
	heading.pixel_size = 0.015
	var lines := [
		"01  Kenar: a+b",
		"02  Alan: (a+b)²",
		"03  Alanlar: a², ab, ab, b²",
		"04  Toplam: a²+ab+ab+b²",
		"05  (a+b)² = a²+b²"
	]
	for i in lines.size():
		var y := 2.62 - i * 0.54
		if _proof_focus == i:
			var focus_color := Color("#6fe3c1") if _proof_repaired else Color("#e5645a") if i == 4 else Color("#f2a65a")
			_box("ProofFocus%d" % i, Vector3(-3.25, y + 0.015, -0.91), Vector3(4.45, 0.43, 0.035), focus_color.darkened(0.58), _set, Vector3.ZERO, true)
		var is_corrected_line := i == 4 and _proof_repaired
		var displayed_text: String = "05  (a+b)² = a²+2ab+b²" if is_corrected_line else lines[i]
		var line_label := _chalk_label("ProofLine%d" % i, "" if not proof_animation_done else displayed_text, Vector3(-3.25, y, -0.80), Color("#fffef8"), 24)
		line_label.pixel_size = 0.014
		line_label.set_meta("chalk_text", displayed_text)
		_proof_labels.append(line_label)
	_chalk_tip = _sphere("ChalkWritingTip", Vector3(-3.25, 2.62, -0.67), Vector3(0.046, 0.046, 0.046), Color("#fffdf4"), _set, true)
	_chalk_tip.visible = false


func _animate_proof() -> void:
	if proof_animation_done or _proof_labels.is_empty():
		proof_animation_done = true
		proof_animation_finished.emit()
		return
	_chalk_tip.visible = true
	for line_label in _proof_labels:
		var chalk_text: String = line_label.get_meta("chalk_text")
		line_label.text = ""
		var text_width := line_label.pixel_size * float(line_label.font_size) * 0.47 * float(chalk_text.length())
		_chalk_tip.position = line_label.position + Vector3(-text_width * 0.5, 0.0, 0.13)
		var width_per_character := line_label.pixel_size * float(line_label.font_size) * 0.47
		for character_index in chalk_text.length():
			line_label.text = chalk_text.substr(0, character_index + 1)
			_chalk_tip.position.x = line_label.position.x - text_width * 0.5 + width_per_character * float(character_index + 1)
			await get_tree().create_timer(0.026).timeout
		await get_tree().create_timer(0.28).timeout
	_chalk_tip.visible = false
	proof_animation_done = true
	proof_animation_finished.emit()


func _chalk_label(id: String, text: String, position: Vector3, color: Color, font_size: int) -> Label3D:
	var label := _label(id, text, position, color, font_size)
	label.font = CHALK_FONT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.outline_size = 2
	label.outline_modulate = Color("#09130f", 0.75)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return label


func _make_safety_door(active: Color, colors: Array) -> void:
	_box("DoorFrame", Vector3(0, 0.9, 0), Vector3(1.6, 1.8, 0.18), Color("#8199a8"), _set)
	_box("DoorLeaf", Vector3(0.0 if _solved or _stage > 0 else -0.35, 0.88, 0.12), Vector3(0.9, 1.68, 0.12), colors[0], _set, Vector3(0, 0, deg_to_rad(-7 if _solved or _stage > 0 else 0)))
	_sphere("Handle", Vector3(0.31, 0.9, 0.22), Vector3(0.075, 0.075, 0.04), Color("#d5e6ea"), _set)
	_box("ExitSign", Vector3(0, 1.98, -0.08), Vector3(0.85, 0.22, 0.08), active, _set, Vector3.ZERO, true)
	_label("ExitText", "ÇIKIŞ", Vector3(0, 1.98, 0.16), Color("#eff9f8"), 20)
	for side in [-1, 1]:
		_box("WallPanel%d" % side, Vector3(side * 1.35, 0.95, -0.05), Vector3(0.65, 1.9, 0.16), Color("#27465a"), _set)
		for i in 3:
			_box("PanelLine%d_%d" % [side, i], Vector3(side * 1.35, 0.38 + i * 0.38, 0.055), Vector3(0.38, 0.035, 0.022), colors[2], _set)
	_label("Instruction", "AÇIK TUT", Vector3(0, 0.25, 0.58), active, 23)
	_box("Walkway", Vector3(0, 0.02, 1.05), Vector3(1.3, 0.04, 1.5), Color("#284c5d"), _set)
	for i in 4:
		_box("WalkMark%d" % i, Vector3(0, 0.05, 0.5 + i * 0.32), Vector3(0.45, 0.018, 0.08), active, _set, Vector3.ZERO, true)
	_sphere("SignalBeacon", Vector3(1.42, 1.45, 0.1), Vector3(0.16, 0.2, 0.16), active, _set, true)


func _make_archive(active: Color, colors: Array) -> void:
	for i in 3:
		var x := -1.25 + i * 1.25
		var height := 0.68 + i * 0.22
		var tint: Color = active if (_solved or i <= _stage) else colors[2]
		_box("ArchiveFile%d" % i, Vector3(x, height * 0.5, 0), Vector3(0.82, height, 0.72), tint, _set, Vector3(0, 0, deg_to_rad(-4 + i * 3)))
		_box("FileSpine%d" % i, Vector3(x - 0.31, height * 0.5, 0.38), Vector3(0.08, height * 0.92, 0.03), colors[0], _set)
		for line in 3:
			_box("FileRule%d_%d" % [i, line], Vector3(x + 0.05, 0.18 + height * 0.26 + line * 0.11, 0.38), Vector3(0.34, 0.025, 0.02), Color("#e7edf1"), _set)
		_label("DocumentDate%d" % i, ["22 HAZ 1919", "04 EYL 1919", "23 NİS 1920"][i], Vector3(x, height + 0.26, 0.04), active, 17)
	for i in 2:
		_rod("ChronologyArrow%d" % i, Vector3(-0.65 + i * 1.25, 0.3, 0.6), Vector3(-0.2 + i * 1.25, 0.3, 0.6), 0.022, active, _set)
	_box("ArchiveTable", Vector3(0, 0.12, 0), Vector3(3.9, 0.14, 1.7), Color("#344c5b"), _set)
	for x in [-1.55, 1.55]:
		_box("TableLeg", Vector3(x, -0.22, 0), Vector3(0.12, 0.58, 0.12), Color("#344c5b"), _set)
	_label("ArchiveTitle", "MİLLÎ MÜCADELE  ·  BELGE SIRASI", Vector3(0, 1.55, -0.7), active, 19)


func _make_supply_station(active: Color, colors: Array) -> void:
	# Water tank, radio and supply crates form a spatial vocabulary for the incoming message.
	_cylinder("WaterTank", Vector3(-0.92, 0.73, -0.1), 0.52, 1.35, Color("#287ba0"), _set, 28)
	_torus("TankBandA", Vector3(-0.92, 0.43, -0.1), 0.54, 0.57, 0.035, Color("#a4cbd5"), _set)
	_torus("TankBandB", Vector3(-0.92, 1.04, -0.1), 0.54, 0.57, 0.035, Color("#a4cbd5"), _set)
	_cylinder("TankCap", Vector3(-0.92, 1.45, -0.1), 0.5, 0.1, Color("#59b4d1"), _set, 28)
	_box("RadioBase", Vector3(0.72, 0.42, -0.1), Vector3(0.88, 0.7, 0.65), Color("#34546a"), _set)
	_box("RadioScreen", Vector3(0.72, 0.55, 0.25), Vector3(0.53, 0.26, 0.035), active, _set, Vector3.ZERO, true)
	for i in 3:
		_sphere("RadioKnob%d" % i, Vector3(0.47 + i * 0.22, 0.25, 0.25), Vector3(0.05, 0.05, 0.04), Color("#e2d6b3"), _set)
	_rod("Antenna", Vector3(1.0, 0.8, -0.1), Vector3(1.22, 1.6, -0.1), 0.025, colors[0], _set)
	_torus("Signal", Vector3(1.22, 1.6, -0.1), 0.32, 0.39, 0.025, active, _set)
	for i in 3:
		var z := -0.55 + i * 0.6
		_box("SupplyCrate%d" % i, Vector3(0.65, 0.16, z), Vector3(0.55, 0.32, 0.48), colors[1], _set)
		_box("CrateStripe%d" % i, Vector3(0.65, 0.16, z + 0.25), Vector3(0.08, 0.28, 0.025), Color("#f6e1a2"), _set)
	_label("NeedWater", "NEED: CLEAN WATER", Vector3(-0.8, 1.72, 0.1), active, 20)
	_label("Reply", "SUPPLY LINE  ·  READY", Vector3(0.65, 1.25, 0.1), colors[1], 17)


func _make_community_archive(active: Color, colors: Array) -> void:
	_box("CommonTable", Vector3(0, 0.48, 0), Vector3(2.55, 0.12, 1.55), Color("#896944"), _set)
	for x in [-0.95, 0.95]:
		for z in [-0.5, 0.5]:
			_box("TableLeg", Vector3(x, 0.2, z), Vector3(0.12, 0.55, 0.12), Color("#896944"), _set)
	# Three abstract neighbors stand around a shared resource; no facial or anatomical claims.
	for i in 3:
		var angle := TAU * float(i) / 3.0
		var pos := Vector3(cos(angle) * 1.52, 0, sin(angle) * 1.25)
		var coat: Color = [Color("#4f87aa"), Color("#b5725f"), Color("#67977b")][i]
		_cylinder("NeighborBody%d" % i, pos + Vector3(0, 0.43, 0), 0.22, 0.68, coat, _set, 16)
		_sphere("NeighborHead%d" % i, pos + Vector3(0, 0.9, 0), Vector3(0.24, 0.25, 0.24), Color("#d5ad86"), _set, false)
		_rod("Offer%d" % i, pos + Vector3(0.12, 0.58, 0.06), Vector3(cos(angle) * 0.3, 0.55, sin(angle) * 0.3), 0.035, active, _set)
	for i in 3:
		_box("SharedSupply%d" % i, Vector3(-0.62 + i * 0.62, 0.62, 0), Vector3(0.42, 0.24, 0.42), colors[1], _set)
		_box("SupplyRibbon%d" % i, Vector3(-0.62 + i * 0.62, 0.75, 0.22), Vector3(0.07, 0.03, 0.03), Color("#f5e6ba"), _set)
	_torus("SolidarityRing", Vector3(0, 0.04, 0), 1.85, 1.9, 0.025, active, _set)
	_label("Share", "ORTAK YARAR", Vector3(0, 1.72, 0), active, 22)
	_label("Need", "İHTİYAÇ  →  DESTEK", Vector3(0, 1.35, 0.03), Color("#d7e3e9"), 17)


func _title_for(id: StringName) -> String:
	return {
		"seasons": "MEVSİM GÖZLEMEVİ", "bridge": "İSPAT LABORATUVARI",
		"turkish": "GÜVENLİK TALİMATI", "history": "BELGE ARŞİVİ",
		"english": "YARDIM İSTASYONU", "religion": "DAYANIŞMA ARŞİVİ"
	}.get(String(id), "LGS DENEY DÜZENEĞİ")


func _mat(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.43
	material.metallic = 0.14
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.45
	return material


func _box(id: String, position: Vector3, size: Vector3, color: Color, parent: Node3D, rotation := Vector3.ZERO, glow := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(id, mesh, position, color, parent, rotation, glow)


func _sphere(id: String, position: Vector3, scale: Vector3, color: Color, parent: Node3D, glow := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 24
	mesh.rings = 16
	var instance := _mesh(id, mesh, position, color, parent, Vector3.ZERO, glow)
	instance.scale = scale
	return instance


func _cylinder(id: String, position: Vector3, radius: float, height: float, color: Color, parent: Node3D, segments := 20) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return _mesh(id, mesh, position, color, parent)


func _torus(id: String, position: Vector3, inner_radius: float, outer_radius: float, tube_radius: float, color: Color, parent: Node3D) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 48
	mesh.ring_segments = 8
	var instance := _mesh(id, mesh, position, color, parent)
	instance.scale.y = tube_radius / maxf((outer_radius - inner_radius) * 0.5, 0.01)
	return instance


func _rod(id: String, start: Vector3, finish: Vector3, radius: float, color: Color, parent: Node3D) -> void:
	var delta := finish - start
	var rod := _cylinder(id, (start + finish) * 0.5, radius, delta.length(), color, parent, 12)
	rod.quaternion = Quaternion(Vector3.UP, delta.normalized())


func _mesh(id: String, mesh: PrimitiveMesh, position: Vector3, color: Color, parent: Node3D, rotation := Vector3.ZERO, glow := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = _mat(color, glow)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func _label(id: String, text: String, position: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.name = id
	label.text = text
	label.position = position
	label.font = LABEL_FONT
	label.font_size = font_size
	label.pixel_size = 0.015
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("#06121c")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_set.add_child(label)
	return label
