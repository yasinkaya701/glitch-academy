extends Node3D
## Small, self-contained 3D teaching models for the quantitative and science tracks.

const INK := Color("#122431")
const PAPER := Color("#d9e8e8")
const MINT := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const CORAL := Color("#ef7466")
const BLUE := Color("#70b9e5")

var theme_id: StringName = &""
var _built := false
var _phase := 0.0
var _result := 0
var _progress := 0.0
var _opening_progress := 0.0
var _evidence_reveal := 0.0
var _life_protocol := false
var _evidence_text := ""
var _model_root: Node3D
var _focus_part: Node3D
var _result_material: StandardMaterial3D
var _evidence_label: Label3D
var _progress_marker: Node3D


func build(requested_theme: StringName) -> void:
	if _built:
		return
	_built = true
	theme_id = requested_theme
	_model_root = Node3D.new()
	_model_root.name = "ScienceModel"
	add_child(_model_root)
	match theme_id:
		&"math": _build_function_graph()
		&"geometry": _build_geometry()
		&"chemistry": _build_chemistry()
		&"biology": _build_cell()
		_: _build_function_graph()
	_add_evidence_label()
	_apply_state()


func update_stage(state: Dictionary) -> void:
	if not _built:
		return
	_phase = float(state.get("phase", _phase))
	_result = int(state.get("result", _result))
	_progress = clampf(float(state.get("progress", _progress)), 0.0, 1.0)
	_opening_progress = clampf(float(state.get("opening_progress", _opening_progress)), 0.0, 1.0)
	_evidence_reveal = clampf(float(state.get("evidence_reveal", _evidence_reveal)), 0.0, 1.0)
	_life_protocol = bool(state.get("life_protocol", _life_protocol))
	_evidence_text = str(state.get("evidence_text", _evidence_text))
	_apply_state()


func set_result(result: int, progress: float) -> void:
	_result = result
	_progress = clampf(progress, 0.0, 1.0)
	_apply_state()


func _apply_state() -> void:
	if not _built:
		return
	if _model_root != null:
		_model_root.rotation.y = sin(_phase * 0.28) * 0.08
		_model_root.scale = Vector3.ONE * lerpf(0.92, 1.0, _opening_progress)
	if _focus_part != null:
		_focus_part.rotation.y = _phase * 0.32
		_focus_part.scale = Vector3.ONE * (1.0 + sin(_phase * 2.0) * 0.025)
	if _progress_marker != null:
		var x := lerpf(-2.1, 2.1, _progress)
		_progress_marker.position = Vector3(x, 0.34 * x * x - 0.72, 0.13)
	if _result_material != null:
		_result_material.emission = MINT if _result > 0 else CORAL if _result < 0 else Color.BLACK
		_result_material.emission_energy_multiplier = 0.7 if _result != 0 else 0.0
	if _evidence_label != null:
		_evidence_label.text = _evidence_text if _evidence_reveal > 0.05 else ""
		_evidence_label.modulate.a = _evidence_reveal
		_evidence_label.visible = _evidence_reveal > 0.05 and not _evidence_text.is_empty()
	if theme_id == &"biology" and _focus_part != null and _life_protocol:
		_focus_part.scale = Vector3(1.0, 1.0, 1.0) * (1.0 + 0.08 * (0.5 + 0.5 * sin(_phase * 5.0)))


func _build_function_graph() -> void:
	_add_line(Vector3(-2.35, -1.2, 0), Vector3(2.35, -1.2, 0), PAPER, 0.025)
	_add_line(Vector3(-1.8, -1.65, 0), Vector3(-1.8, 1.7, 0), PAPER, 0.025)
	for index in range(1, 9):
		var x := -1.8 + float(index) * 0.45
		_add_line(Vector3(x, -1.24, 0), Vector3(x, -1.16, 0), Color(PAPER, 0.55), 0.012)
	for index in range(1, 6):
		var y := -1.2 + float(index) * 0.45
		_add_line(Vector3(-1.84, y, 0), Vector3(-1.76, y, 0), Color(PAPER, 0.55), 0.012)
	var points := PackedVector3Array()
	for index in range(49):
		var x := -2.1 + float(index) * 0.0875
		var y := 0.34 * x * x - 0.72
		points.append(Vector3(x, y, 0.04))
	_add_curve(points, MINT, 0.035)
	var vertex := _add_sphere("FunctionVertex", Vector3(0, -0.72, 0.08), 0.11, AMBER)
	_focus_part = vertex
	_result_material = vertex.material_override
	_progress_marker = _add_sphere("ProgressMarker", Vector3(-2.1, 0.78, 0.13), 0.075, CORAL)
	_add_text("y = x² − 0.72", Vector3(0.0, 1.55, 0.06), 30, AMBER)
	_add_text("x", Vector3(2.18, -1.48, 0.04), 26, PAPER)
	_add_text("y", Vector3(-2.04, 1.55, 0.04), 26, PAPER)


func _build_geometry() -> void:
	var center := Vector3(0, 0, 0)
	var size := 1.65
	var vertices := [
		Vector3(-size, -size, -size), Vector3(size, -size, -size),
		Vector3(size, size, -size), Vector3(-size, size, -size),
		Vector3(-size, -size, size), Vector3(size, -size, size),
		Vector3(size, size, size), Vector3(-size, size, size)
	]
	var edge_material := _material(BLUE, 0.0)
	var edge_pairs := [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]]
	for pair in edge_pairs:
		_add_cylinder_between(vertices[pair[0]], vertices[pair[1]], 0.022, edge_material)
	_add_cylinder_between(vertices[0], vertices[6], 0.018, _material(AMBER, 0.0))
	_add_cylinder_between(vertices[1], vertices[7], 0.018, _material(MINT, 0.0))
	var solid := MeshInstance3D.new()
	solid.name = "InscribedSphere"
	var sphere := SphereMesh.new()
	sphere.radius = 1.48
	sphere.height = 2.96
	solid.mesh = sphere
	solid.material_override = _material(Color(BLUE, 0.12), 0.0, true)
	_model_root.add_child(solid)
	var orb := _add_sphere("SphereCenter", center, 0.09, AMBER)
	_focus_part = orb
	_result_material = orb.material_override
	_add_text("KÜP · köşegen · küre", Vector3(0, 2.05, 0), 24, PAPER)
	_add_text("düzlem ve uzay ilişkisi", Vector3(0, -2.0, 0), 18, MINT)


func _build_chemistry() -> void:
	# Cylindrical vessel walls, a clear liquid column, and a transfer pipette.
	var glass := _material(Color("#8fcde2", 0.22), 0.0, true)
	var vessel := _add_cylinder("Beaker", Vector3(-0.55, -0.28, 0), 0.78, 1.72, glass)
	vessel.rotation.x = PI
	_add_cylinder("AcidSolution", Vector3(-0.55, -0.72, 0), 0.64, 0.66, _material(Color("#c75b71", 0.82), 0.1))
	_add_cylinder("BaseSolution", Vector3(1.12, -0.62, 0), 0.57, 0.84, _material(Color("#4a9cc2", 0.78), 0.1))
	var second := _add_cylinder("ComparisonVessel", Vector3(1.12, -0.28, 0), 0.7, 1.72, glass)
	second.rotation.x = PI
	for mark in range(1, 4):
		var y := -0.78 + float(mark) * 0.34
		_add_line(Vector3(-1.29, y, 0.05), Vector3(-1.0, y, 0.05), PAPER, 0.018)
	_add_cylinder_between(Vector3(0.3, 1.75, 0), Vector3(0.05, -0.25, 0), 0.045, _material(PAPER, 0.0))
	_add_cylinder_between(Vector3(0.05, -0.25, 0), Vector3(-0.05, -0.55, 0), 0.018, _material(AMBER, 0.0))
	var drop := _add_sphere("IndicatorDrop", Vector3(-0.05, -0.55, 0.02), 0.11, AMBER)
	_focus_part = drop
	_result_material = drop.material_override
	_add_text("ASİT", Vector3(-0.55, 1.0, 0), 24, CORAL)
	_add_text("BAZ", Vector3(1.12, 1.0, 0), 24, BLUE)
	_add_text("gösterge damlası", Vector3(0.0, 2.15, 0), 19, PAPER)


func _build_cell() -> void:
	var membrane := _add_sphere("CellMembrane", Vector3.ZERO, 1.8, Color("#4c9b86"))
	membrane.scale = Vector3(1.55, 1.05, 0.82)
	membrane.material_override = _material(Color("#4c9b86", 0.24), 0.0, true)
	var cytoplasm := _add_sphere("Cytoplasm", Vector3.ZERO, 1.62, Color("#357368"))
	cytoplasm.scale = Vector3(1.48, 0.99, 0.76)
	cytoplasm.material_override = _material(Color("#357368", 0.3), 0.0, true)
	var nucleus := _add_sphere("Nucleus", Vector3(-0.55, 0.14, 0.52), 0.58, Color("#657ab2"))
	nucleus.material_override = _material(Color("#657ab2", 0.92), 0.15)
	_add_sphere("Nucleolus", Vector3(-0.55, 0.14, 1.0), 0.14, AMBER)
	for index in range(5):
		var angle := TAU * float(index) / 5.0
		var position := Vector3(0.52 + cos(angle) * 0.54, sin(angle) * 0.42, 0.54)
		var mitochondrion := _add_sphere("Mitochondrion_%d" % index, position, 0.26, Color("#dc8b6b"))
		mitochondrion.scale = Vector3(1.55, 0.68, 0.6)
		_add_line(position + Vector3(-0.26, 0, 0.06), position + Vector3(0.26, 0, 0.06), AMBER, 0.025)
	for index in range(7):
		var position := Vector3(-1.25 + float(index % 4) * 0.7, -0.45 + float(index / 4) * 0.68, 0.45)
		_add_sphere("Ribosome_%d" % index, position, 0.065, MINT)
	_focus_part = nucleus
	_result_material = nucleus.material_override
	_add_text("HÜCRE", Vector3(0, 1.7, 0.4), 28, PAPER)
	_add_text("çekirdek", Vector3(-0.55, -0.62, 0.72), 19, AMBER)
	_add_text("mitokondri", Vector3(1.0, -1.28, 0.55), 19, CORAL)


func _add_evidence_label() -> void:
	_evidence_label = Label3D.new()
	_evidence_label.name = "EvidenceText"
	_evidence_label.position = Vector3(0, -2.5, 0.1)
	_evidence_label.font_size = 28
	_evidence_label.pixel_size = 0.006
	_evidence_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_evidence_label.modulate = MINT
	_evidence_label.visible = false
	_model_root.add_child(_evidence_label)


func _add_sphere(node_name: String, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.position = position
	node.material_override = _material(color, 0.0)
	_model_root.add_child(node)
	return node


func _add_cylinder(node_name: String, position: Vector3, radius: float, height: float, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	node.mesh = mesh
	node.position = position
	node.material_override = material
	_model_root.add_child(node)
	return node


func _add_line(from: Vector3, to: Vector3, color: Color, radius: float) -> MeshInstance3D:
	return _add_cylinder_between(from, to, radius, _material(color, 0.0))


func _add_cylinder_between(from: Vector3, to: Vector3, radius: float, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 8
	node.mesh = mesh
	node.position = (from + to) * 0.5
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	node.material_override = material
	_model_root.add_child(node)
	return node


func _add_curve(points: PackedVector3Array, color: Color, radius: float) -> void:
	var material := _material(color, 0.15)
	for index in range(points.size() - 1):
		_add_cylinder_between(points[index], points[index + 1], radius, material)


func _add_text(value: String, position: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = position
	label.font_size = size
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	_model_root.add_child(label)


func _material(color: Color, emission_energy: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34
	material.metallic = 0.08
	if transparent or color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.emission_enabled = emission_energy > 0.0
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material
