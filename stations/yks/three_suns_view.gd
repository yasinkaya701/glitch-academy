extends Node3D

const BODY_COLORS: Array[Color] = [
	Color("#ffd166"),
	Color("#69c9ff"),
	Color("#ee8f83"),
]
const SCALE := 1.0
const PLAYBACK_SAMPLES_PER_SECOND := 280.0

var _baseline: Array[PackedVector2Array] = []
var _perturbed: Array[PackedVector2Array] = []
var _baseline_bodies: Array[MeshInstance3D] = []
var _perturbed_bodies: Array[MeshInstance3D] = []
var _track_nodes: Array[MeshInstance3D] = []
var _sample_index := 0.0


func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		camera.position = Vector3(0.0, 5.1, 10.8)
		camera.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
		camera.size = 10.2
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.current = true
	for body_index in BODY_COLORS.size():
		_baseline_bodies.append(_make_body("BaselineBody%d" % body_index, BODY_COLORS[body_index], 0.19, 1.0))
		_perturbed_bodies.append(_make_body("PerturbedBody%d" % body_index, BODY_COLORS[body_index], 0.12, 0.72))
	for body in _baseline_bodies + _perturbed_bodies:
		body.visible = false


func set_paths(baseline: Array[PackedVector2Array], perturbed: Array[PackedVector2Array]) -> void:
	_baseline = baseline
	_perturbed = perturbed
	_sample_index = 0.0
	_clear_tracks()
	_add_tracks(_baseline, false)
	_add_tracks(_perturbed, true)
	_set_group_visible(_baseline_bodies, not _baseline.is_empty())
	_set_group_visible(_perturbed_bodies, not _perturbed.is_empty())
	_update_body_positions(0)


func _process(delta: float) -> void:
	var sample_count := maxi(_longest_path(_baseline), _longest_path(_perturbed))
	if sample_count < 1:
		return
	_sample_index = minf(_sample_index + delta * PLAYBACK_SAMPLES_PER_SECOND, sample_count - 1)
	_update_body_positions(int(_sample_index))


func _make_body(body_name: String, color: Color, radius: float, alpha: float) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.metallic = 0.28
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.55 if alpha > 0.9 else 0.22
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var body := MeshInstance3D.new()
	body.name = body_name
	body.mesh = sphere
	body.material_override = material
	add_child(body)
	return body


func _add_tracks(paths: Array[PackedVector2Array], is_perturbed: bool) -> void:
	for body_index in paths.size():
		var points := paths[body_index]
		if points.size() < 2:
			continue
		var track_color := Color("#f2a65a") if is_perturbed else Color("#6fe3c1")
		track_color = track_color.darkened(float(body_index) * 0.14)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(track_color.r, track_color.g, track_color.b, 0.82)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var line_mesh := ImmediateMesh.new()
		line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
		for point in points:
			line_mesh.surface_add_vertex(_to_world(point))
		line_mesh.surface_end()
		var line := MeshInstance3D.new()
		line.name = ("Perturbed" if is_perturbed else "Baseline") + "Orbit%d" % body_index
		line.mesh = line_mesh
		add_child(line)
		_track_nodes.append(line)


func _update_body_positions(index: int) -> void:
	_update_group(_baseline_bodies, _baseline, index)
	_update_group(_perturbed_bodies, _perturbed, index)


func _update_group(bodies: Array[MeshInstance3D], paths: Array[PackedVector2Array], index: int) -> void:
	for body_index in bodies.size():
		if body_index >= paths.size() or paths[body_index].is_empty():
			bodies[body_index].visible = false
			continue
		var path := paths[body_index]
		bodies[body_index].visible = true
		bodies[body_index].position = _to_world(path[mini(index, path.size() - 1)])


func _to_world(point: Vector2) -> Vector3:
	return Vector3(point.x * SCALE, 0.0, -point.y * SCALE)


func _longest_path(paths: Array[PackedVector2Array]) -> int:
	var longest := 0
	for path in paths:
		longest = maxi(longest, path.size())
	return longest


func _set_group_visible(bodies: Array[MeshInstance3D], is_visible: bool) -> void:
	for body in bodies:
		body.visible = is_visible


func _clear_tracks() -> void:
	for track in _track_nodes:
		track.queue_free()
	_track_nodes.clear()
