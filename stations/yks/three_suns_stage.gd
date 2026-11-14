extends Control
## Üç Güneş sahnesi (3B). İki mod: iki cisimde Kepler yörüngesi, üç cisimde iki iz karşılaştırması.
## Hesap three_body_model.gd'de; burası yalnız çizer ve ölçü cihazını gösterir.

signal playback_finished
signal kepler_finished

const Model = preload("res://stations/yks/three_body_model.gd")

const BODY_COLORS: Array[Color] = [Color("#ffd166"), Color("#69c9ff"), Color("#ee8f83")]
const TRACK_A := Color("#6fe3c1")
const TRACK_B := Color("#f2a65a")
const ALERT := Color("#e5645a")
const PAPER := Color("#eeeae0")
const MUTED := Color("#b1ac9e")
const THREE_SCALE := 1.9
const KEPLER_SCALE := 0.74
const TRAIL_SAMPLES := 150

enum Mode { NONE, KEPLER, THREE }

var time_scale := 1.0
var mode := Mode.NONE
var epsilon := Model.SEPARATION_EPSILON
var meridyen_horizon := -1.0  ## >0 ise ölçü cihazında MERİDYEN'in "öngörü ufku" gösterilir

var _viewport: SubViewport
var _world: Node3D
var _environment: Environment
var _ambient_boost := 0.0
var _paths_a: Array[PackedVector2Array] = []
var _paths_b: Array[PackedVector2Array] = []
var _bodies_a: Array[MeshInstance3D] = []
var _bodies_b: Array[MeshInstance3D] = []
var _ghost_tracks := Node3D.new()
var _trails: Array[MeshInstance3D] = []
var _gap_lines: Array[MeshInstance3D] = []
var _time := 0.0
var _playing := false
var _finished_emitted := false
var _repaired := false

var _kepler_root := Node3D.new()
var _kepler_planet: MeshInstance3D
var _kepler_ring: MeshInstance3D
var _kepler_marker: MeshInstance3D
var _kepler_snapshot: MeshInstance3D
var _kepler_label: Label3D
var _kepler_a := 4.0
var _kepler_true_period := 8.0
var _kepler_counter_period := 8.0
var _kepler_running := false
var _kepler_clock := 0.0
var _kepler_snap_done := false
var _kepler_end := 0.0

var _panel: PanelContainer
var _label_time: Label
var _label_main: Label
var _label_limit: Label
var _label_state: Label
var _label_title: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()
	_build_stars()
	_build_bodies()
	_build_kepler()
	_build_readout()
	set_process(true)
	show_nothing()


# --- Dış arayüz -----------------------------------------------------------------------

func show_nothing() -> void:
	mode = Mode.NONE
	_playing = false
	_kepler_running = false
	_kepler_root.visible = false
	_set_three_visible(false)
	_panel.visible = false


func show_three(a: Array[PackedVector2Array], b: Array[PackedVector2Array], horizon: float = -1.0) -> void:
	mode = Mode.THREE
	_kepler_root.visible = false
	_paths_a = a
	_paths_b = b
	meridyen_horizon = horizon
	_build_ghost_tracks()
	_set_three_visible(true)
	for body in _bodies_b:
		body.visible = not b.is_empty()
	rewind()
	_panel.visible = true
	_label_title.text = "ÖLÇÜ CİHAZI · İKİ İZ"


func play() -> void:
	if mode != Mode.THREE:
		return
	if _time >= Model.duration() - 0.001:
		rewind()
	_playing = true
	_finished_emitted = false


func rewind() -> void:
	_time = 0.0
	_playing = false
	_finished_emitted = false
	_update_three(0)
	_update_readout_three(0)


func is_playing() -> bool:
	return _playing


func clock() -> float:
	return _time


func show_kepler(semi_major_axis: float, counter_period: float = -1.0) -> void:
	mode = Mode.KEPLER
	_playing = false
	_set_three_visible(false)
	_kepler_root.visible = true
	_kepler_a = semi_major_axis
	_kepler_true_period = Model.kepler_period(semi_major_axis)
	_kepler_counter_period = counter_period
	_kepler_running = false
	_kepler_clock = 0.0
	_kepler_snap_done = false
	var radius := semi_major_axis * KEPLER_SCALE
	(_kepler_ring.mesh as TorusMesh).inner_radius = radius - 0.014
	(_kepler_ring.mesh as TorusMesh).outer_radius = radius + 0.014
	_kepler_marker.position = Vector3(radius, 0.0, 0.0)
	_kepler_planet.position = Vector3(radius, 0.0, 0.0)
	_kepler_snapshot.visible = false
	_kepler_label.text = "a = %s" % _num(semi_major_axis)
	_kepler_label.position = Vector3(radius * 0.7, 0.34, radius * 0.7)
	_panel.visible = true
	_label_title.text = "ÖLÇÜ CİHAZI · DÖNEM SAYACI"
	_update_readout_kepler()


## Sayaç `counter_period` değerine kurulur; gezegen gerçek dönemiyle döner, sayaç dolunca konum işaretlenir.
func run_kepler(counter_period: float) -> void:
	if mode != Mode.KEPLER:
		return
	_kepler_counter_period = counter_period
	_kepler_clock = 0.0
	_kepler_snap_done = false
	_kepler_snapshot.visible = false
	_kepler_end = maxf(_kepler_true_period, counter_period) + 0.4
	_kepler_running = true
	_update_readout_kepler()


func play_repair() -> void:
	_repaired = true
	_ambient_boost = 0.35
	if _environment != null:
		_environment.ambient_light_energy = 0.55 + _ambient_boost


# --- Kurulum --------------------------------------------------------------------------

func _build_viewport() -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_4X
	container.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("#070b12")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("#9fb4c8")
	_environment.ambient_light_energy = 0.55
	_environment.glow_enabled = true
	_environment.glow_intensity = 0.5
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	_world.add_child(world_environment)
	var camera := Camera3D.new()
	camera.fov = 42.0
	camera.position = Vector3(0.0, 9.0, 7.6)
	camera.current = true
	_world.add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.1), Vector3.UP)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-60.0, 20.0, 0.0)
	_world.add_child(fill)


func _build_stars() -> void:
	var stars := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04
	mesh.radial_segments = 6
	mesh.rings = 3
	multi.mesh = mesh
	multi.instance_count = 170
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for index in multi.instance_count:
		var position := Vector3(rng.randf_range(-13.0, 13.0), rng.randf_range(-3.0, -1.2), rng.randf_range(-9.0, 7.0))
		multi.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.6, 1.5)), position))
	stars.multimesh = multi
	stars.material_override = _unshaded(Color("#cfdce6"), 0.7)
	_world.add_child(stars)


func _build_bodies() -> void:
	_world.add_child(_ghost_tracks)
	for index in 3:
		_bodies_a.append(_star(BODY_COLORS[index], 0.2, 1.0))
		_bodies_b.append(_star(BODY_COLORS[index], 0.13, 0.7))
		_trails.append(_trail_node())
		_trails.append(_trail_node())
		_gap_lines.append(_trail_node())


func _star(color: Color, radius: float, alpha: float) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5 if alpha > 0.9 else 0.8
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	if alpha > 0.9:
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 0.9
		light.omni_range = 5.0
		node.add_child(light)
	_world.add_child(node)
	return node


func _trail_node() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = ImmediateMesh.new()
	_world.add_child(node)
	return node


func _build_kepler() -> void:
	_world.add_child(_kepler_root)
	var center := _star(Color("#ffd166"), 0.3, 1.0)
	center.get_parent().remove_child(center)
	_kepler_root.add_child(center)
	var reference := MeshInstance3D.new()
	var reference_mesh := TorusMesh.new()
	reference_mesh.inner_radius = KEPLER_SCALE - 0.01
	reference_mesh.outer_radius = KEPLER_SCALE + 0.01
	reference_mesh.rings = 96
	reference_mesh.ring_segments = 6
	reference.mesh = reference_mesh
	reference.material_override = _unshaded(Color("#7d8a86"), 0.55)
	_kepler_root.add_child(reference)
	var reference_label := _label("a = 1 · T₀", 24, MUTED)
	reference_label.position = Vector3(KEPLER_SCALE * 0.7, 0.28, -KEPLER_SCALE * 0.7)
	_kepler_root.add_child(reference_label)
	_kepler_ring = MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.rings = 120
	ring_mesh.ring_segments = 6
	ring_mesh.inner_radius = 2.9
	ring_mesh.outer_radius = 3.0
	_kepler_ring.mesh = ring_mesh
	_kepler_ring.material_override = _unshaded(TRACK_A, 0.8)
	_kepler_root.add_child(_kepler_ring)
	var planet_mesh := SphereMesh.new()
	planet_mesh.radius = 0.15
	planet_mesh.height = 0.3
	_kepler_planet = MeshInstance3D.new()
	_kepler_planet.mesh = planet_mesh
	var planet_material := StandardMaterial3D.new()
	planet_material.albedo_color = Color("#69c9ff")
	planet_material.emission_enabled = true
	planet_material.emission = Color("#69c9ff")
	planet_material.emission_energy_multiplier = 0.9
	_kepler_planet.material_override = planet_material
	_kepler_root.add_child(_kepler_planet)
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.045
	marker_mesh.bottom_radius = 0.045
	marker_mesh.height = 0.9
	_kepler_marker = MeshInstance3D.new()
	_kepler_marker.mesh = marker_mesh
	_kepler_marker.material_override = _unshaded(PAPER, 0.9)
	_kepler_root.add_child(_kepler_marker)
	var snapshot_mesh := SphereMesh.new()
	snapshot_mesh.radius = 0.22
	snapshot_mesh.height = 0.44
	_kepler_snapshot = MeshInstance3D.new()
	_kepler_snapshot.mesh = snapshot_mesh
	_kepler_snapshot.material_override = _unshaded(TRACK_B, 0.45)
	_kepler_snapshot.visible = false
	_kepler_root.add_child(_kepler_snapshot)
	_kepler_label = _label("", 26, TRACK_A)
	_kepler_root.add_child(_kepler_label)
	var start_label := _label("BAŞLANGIÇ", 22, PAPER)
	start_label.position = Vector3(0.0, 0.8, 0.0)
	_kepler_marker.add_child(start_label)


func _build_readout() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -292.0
	_panel.offset_right = -20.0
	_panel.offset_top = 92.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#10110f", 0.92)
	style.border_color = Color("#3b3d35")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	_label_title = _readout_label(11, MUTED)
	_label_time = _readout_label(20, PAPER)
	_label_main = _readout_label(17, PAPER)
	_label_limit = _readout_label(13, MUTED)
	_label_state = _readout_label(15, TRACK_A)
	for label in [_label_title, _label_time, _label_main, _label_limit, _label_state]:
		box.add_child(label)


func _readout_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# --- Çizim ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if mode == Mode.THREE and _playing:
		_time += delta * time_scale
		var finish := Model.duration() - Model.SAMPLE_EVERY * Model.TIME_STEP
		if _time >= finish:
			_time = finish
			_playing = false
			if not _finished_emitted:
				_finished_emitted = true
				playback_finished.emit()
		var index := int(_time / (Model.SAMPLE_EVERY * Model.TIME_STEP))
		_update_three(index)
		_update_readout_three(index)
	elif mode == Mode.KEPLER and _kepler_running:
		_kepler_clock += delta * time_scale
		var angle := TAU * _kepler_clock / _kepler_true_period
		var radius := _kepler_a * KEPLER_SCALE
		_kepler_planet.position = Vector3(cos(angle) * radius, 0.0, -sin(angle) * radius)
		if not _kepler_snap_done and _kepler_clock >= _kepler_counter_period:
			_kepler_snap_done = true
			_kepler_snapshot.visible = true
			_kepler_snapshot.position = _kepler_planet.position
		if _kepler_clock >= _kepler_end:
			_kepler_running = false
			kepler_finished.emit()
		_update_readout_kepler()


func _update_three(index: int) -> void:
	for body_index in 3:
		_place(_bodies_a[body_index], _paths_a, body_index, index)
		_place(_bodies_b[body_index], _paths_b, body_index, index)
		_draw_trail(_trails[body_index * 2], _paths_a, body_index, index, TRACK_A.darkened(0.12 * body_index))
		_draw_trail(_trails[body_index * 2 + 1], _paths_b, body_index, index, TRACK_B.darkened(0.12 * body_index))
		_draw_gap(_gap_lines[body_index], body_index, index)


func _place(body: MeshInstance3D, paths: Array[PackedVector2Array], body_index: int, index: int) -> void:
	if body_index >= paths.size() or paths[body_index].is_empty():
		body.visible = false
		return
	body.visible = mode == Mode.THREE
	body.position = _to_world(paths[body_index][mini(index, paths[body_index].size() - 1)])


func _draw_trail(node: MeshInstance3D, paths: Array[PackedVector2Array], body_index: int, index: int, color: Color) -> void:
	var mesh := node.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if body_index >= paths.size() or paths[body_index].size() < 2:
		return
	var path := paths[body_index]
	var last := mini(index, path.size() - 1)
	var first := maxi(0, last - TRAIL_SAMPLES)
	if last - first < 1:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _unshaded(color, 0.9))
	for sample in range(first, last + 1):
		mesh.surface_add_vertex(_to_world(path[sample]))
	mesh.surface_end()


func _draw_gap(node: MeshInstance3D, body_index: int, index: int) -> void:
	var mesh := node.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if _paths_b.is_empty() or body_index >= _paths_a.size() or body_index >= _paths_b.size():
		return
	var last := mini(index, mini(_paths_a[body_index].size(), _paths_b[body_index].size()) - 1)
	var a := _paths_a[body_index][last]
	var b := _paths_b[body_index][last]
	if a.distance_to(b) < 0.004:
		return
	var separated := a.distance_to(b) > epsilon
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded(ALERT if separated else PAPER, 0.85))
	mesh.surface_add_vertex(_to_world(a))
	mesh.surface_add_vertex(_to_world(b))
	mesh.surface_end()


func _build_ghost_tracks() -> void:
	for child in _ghost_tracks.get_children():
		child.queue_free()
	for set_index in 2:
		var paths := _paths_a if set_index == 0 else _paths_b
		var color := TRACK_A if set_index == 0 else TRACK_B
		for body_index in paths.size():
			if paths[body_index].size() < 2:
				continue
			var node := MeshInstance3D.new()
			var mesh := ImmediateMesh.new()
			mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _unshaded(color, 0.14))
			for point in paths[body_index]:
				mesh.surface_add_vertex(_to_world(point))
			mesh.surface_end()
			node.mesh = mesh
			_ghost_tracks.add_child(node)


func _set_three_visible(on: bool) -> void:
	for body in _bodies_a + _bodies_b:
		body.visible = on
	for node in _trails + _gap_lines:
		node.visible = on
	_ghost_tracks.visible = on


func _update_readout_three(index: int) -> void:
	var distance := Model.separation_at(_paths_a, _paths_b, index) if not _paths_b.is_empty() else 0.0
	_label_time.text = "t = %s" % _num(_time, 2)
	_label_main.text = "d = %s" % _num(distance, 3)
	var limit := "eşik ε = %s" % _num(epsilon, 2)
	if meridyen_horizon > 0.0:
		limit += "\nMERİDYEN öngörü ufku: %s" % _num(meridyen_horizon, 1)
	_label_limit.text = limit
	if _paths_b.is_empty():
		_label_state.text = "● tek iz"
		_label_state.add_theme_color_override("font_color", TRACK_A)
	elif distance > epsilon:
		_label_state.text = "▲ AYRILDI"
		_label_state.add_theme_color_override("font_color", ALERT)
	else:
		_label_state.text = "● birlikte"
		_label_state.add_theme_color_override("font_color", TRACK_A)


func _update_readout_kepler() -> void:
	_label_time.text = "t = %s T₀" % _num(_kepler_clock, 2)
	_label_main.text = "a = %s" % _num(_kepler_a)
	if _kepler_counter_period > 0.0:
		_label_limit.text = "sayaç ayarı T = %s T₀" % _num(_kepler_counter_period, 2)
	else:
		_label_limit.text = "sayaç ayarı yok"
	if _kepler_snap_done:
		var offset := fposmod(_kepler_counter_period / _kepler_true_period, 1.0)
		var closed := offset < 0.02 or offset > 0.98
		_label_state.text = "✓ tur kapandı" if closed else "▲ sayaç dolunca gezegen başlangıçta değil"
		_label_state.add_theme_color_override("font_color", TRACK_A if closed else ALERT)
	else:
		_label_state.text = "● sayaç işliyor" if _kepler_running else "● hazır"
		_label_state.add_theme_color_override("font_color", MUTED)


# --- Yardımcılar ----------------------------------------------------------------------

func _to_world(point: Vector2) -> Vector3:
	return Vector3(point.x * THREE_SCALE, 0.0, -point.y * THREE_SCALE)


func _unshaded(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _label(text: String, size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.0085
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color("#070b12")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	return label


func _num(value: float, digits: int = 1) -> String:
	var text := String.num(value, digits)
	if digits == 1 and text.ends_with(".0"):
		text = text.substr(0, text.length() - 2)
	return text.replace(".", ",")
