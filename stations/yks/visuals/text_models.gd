extends Node3D
## Small 3D evidence models for YKS reading and social-science stages.

const INK := Color("#172936")
const PAPER := Color("#e7d9b7")
const MINT := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const CORAL := Color("#e5645a")
const STONE := Color("#8ba3a3")

var _theme: StringName = &"reading"
var _result := 0
var _progress := 0.0
var _opening_progress := 0.0
var _evidence_reveal := 0.0
var _evidence_text := ""
var _moving: Array[Node3D] = []
var _evidence_cards: Array[Node3D] = []
var _route_parts: Array[Node3D] = []
var _book_left: Node3D
var _book_right: Node3D
var _reading_line: MeshInstance3D
var _history_markers: Array[MeshInstance3D] = []
var _reading_note: Label3D
var _literature_note: Label3D
var _result_note: Label3D


func build(theme_id: StringName) -> void:
	_theme = theme_id
	_result = 0
	_progress = 0.0
	_opening_progress = 0.0
	_evidence_reveal = 0.0
	_evidence_text = ""
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_moving.clear()
	_evidence_cards.clear()
	_route_parts.clear()
	_history_markers.clear()
	_book_left = null
	_book_right = null
	_reading_line = null
	_reading_note = null
	_literature_note = null
	_result_note = null
	_add_box("Plinth", Vector3(0, -0.16, 0), Vector3(3.9, 0.24, 2.55), Color("#263a43"), 0.08)
	match _theme:
		&"reading": _build_reading()
		&"literature": _build_literature()
		&"history": _build_history()
		&"geography": _build_geography()
		_: _build_reading()
	_result_note = _add_label("ModelResult", "", Vector3(0, 0.33, 1.18), 0.105, PAPER)
	_apply_state()


func update_stage(state: Dictionary) -> void:
	if state.has("result"):
		_result = int(state["result"])
	if state.has("progress"):
		_progress = clampf(float(state["progress"]), 0.0, 1.0)
	if state.has("opening_progress"):
		_opening_progress = clampf(float(state["opening_progress"]), 0.0, 1.0)
	if state.has("evidence_reveal"):
		_evidence_reveal = clampf(float(state["evidence_reveal"]), 0.0, 1.0)
	if state.has("evidence_text"):
		_evidence_text = str(state["evidence_text"])
	if state.has("phase"):
		for index in _moving.size():
			_moving[index].rotation.y = float(state["phase"]) * (0.025 if index % 2 == 0 else -0.025)
	_apply_state()


func set_result(result: int, progress: float) -> void:
	_result = result
	_progress = clampf(progress, 0.0, 1.0)
	_apply_state()


func _build_reading() -> void:
	# Four source cards lead to a single inference card. The highlighted source and
	# connector move with evidence_reveal/progress so the deduction is legible.
	_add_box("RecordStand", Vector3(0, 0.08, -0.44), Vector3(3.3, 0.07, 1.15), Color("#66533d"), 0.04)
	for i in 4:
		var x := -1.18 + float(i) * 0.78
		var card := _add_box("EvidenceCard%d" % i, Vector3(x, 0.57, -0.37), Vector3(0.62, 0.82, 0.055), PAPER, 0.035)
		card.rotation_degrees.x = -5.0
		_evidence_cards.append(card)
		_add_label("Source%d" % i, ["SÖZ", "ZAMAN", "NEDEN", "İSTEK"][i], Vector3(x, 0.57, -0.33), 0.12, INK)
		for line in 2:
			_add_box("InkLine%d_%d" % [i, line], Vector3(x, 0.43 - line * 0.12, -0.325), Vector3(0.38 - line * 0.06, 0.018, 0.008), STONE, 0.005)
	_reading_line = _add_box("EvidenceToInference", Vector3(0.0, 0.31, 0.44), Vector3(0.08, 0.035, 0.72), STONE, 0.01)
	_reading_line.rotation_degrees.x = 90.0
	var inference := _add_box("InferenceCard", Vector3(0, 0.76, 0.98), Vector3(1.28, 0.9, 0.06), Color("#344a45"), 0.04)
	_add_label("InferenceHeading", "ÇIKARIM", Vector3(0, 0.78, 1.02), 0.15, PAPER)
	_reading_note = _add_label("EvidenceNote", "KANIT → ÇIKARIM", Vector3(0, 0.29, 1.03), 0.105, MINT)
	_moving.append(inference)


func _build_literature() -> void:
	# A visible central gutter and hinged leaves make opening the text an action.
	_add_box("BookCover", Vector3(0, 0.1, 0), Vector3(2.65, 0.09, 1.72), Color("#49342f"), 0.07)
	_add_box("PageBlock", Vector3(0, 0.19, 0), Vector3(2.48, 0.045, 1.57), PAPER, 0.025)
	_book_left = _new_node("LeftPageHinge", Vector3(-0.035, 0.225, 0))
	_book_right = _new_node("RightPageHinge", Vector3(0.035, 0.225, 0))
	var left_page := _add_box("LeftPage", Vector3(-0.61, 0.0, 0), Vector3(1.18, 0.035, 1.45), Color("#f0e5c9"), 0.018, _book_left)
	var right_page := _add_box("RightPage", Vector3(0.61, 0.0, 0), Vector3(1.18, 0.035, 1.45), Color("#f0e5c9"), 0.018, _book_right)
	left_page.position.y = 0.025
	right_page.position.y = 0.025
	for i in 4:
		_add_box("TextLineLeft%d" % i, Vector3(-0.63, 0.047, -0.38 + i * 0.17), Vector3(0.76 - i % 2 * 0.12, 0.012, 0.012), Color("#887c64"), 0.002, _book_left)
		_add_box("TextLineRight%d" % i, Vector3(0.63, 0.047, -0.38 + i * 0.17), Vector3(0.76 - i % 2 * 0.1, 0.012, 0.012), Color("#887c64"), 0.002, _book_right)
	_add_box("InterpretationLeft", Vector3(-0.67, 0.07, 0.44), Vector3(0.72, 0.045, 0.31), Color("#374a4c"), 0.035)
	_add_box("InterpretationRight", Vector3(0.67, 0.07, 0.44), Vector3(0.72, 0.045, 0.31), Color("#4b4033"), 0.035)
	_add_label("ReadingOne", "ANLATICI", Vector3(-0.67, 0.105, 0.44), 0.12, MINT)
	_add_label("ReadingTwo", "ZAMAN", Vector3(0.67, 0.105, 0.44), 0.12, AMBER)
	_literature_note = _add_label("InterpretationEvidence", "AYNI İPUCU · İKİ OKUMA", Vector3(0, 0.65, 0.98), 0.12, PAPER)
	_book_left.rotation.y = -0.02
	_book_right.rotation.y = 0.02
	_moving.append(_book_left)
	_moving.append(_book_right)


func _build_history() -> void:
	# The dated primary source, later recollection, and undated claim sit on one
	# chronological rail; only sourced milestones can become evidence.
	_add_box("TimelineRail", Vector3(0, 0.29, -0.25), Vector3(3.28, 0.09, 0.16), Color("#846d50"), 0.04)
	var xs := [-1.22, 0.0, 1.22]
	var dates := ["1919", "ANILAR", "? TARİHSİZ"]
	var titles := ["GENELGE", "HATIRAT", "SÖYLENTİ"]
	for i in 3:
		var marker := _add_cylinder("TimelineMarker%d" % i, Vector3(xs[i], 0.45, -0.25), 0.13, 0.13, [MINT, AMBER, CORAL][i])
		_history_markers.append(marker)
		_add_box("ArchiveArtifact%d" % i, Vector3(xs[i], 0.78, 0.38), Vector3(0.78, 0.62, 0.075), [Color("#d9cba9"), Color("#b7a488"), Color("#504b46")][i], 0.025)
		_add_box("ArtifactSeal%d" % i, Vector3(xs[i], 0.79, 0.43), Vector3(0.16, 0.16, 0.025), [MINT, AMBER, CORAL][i], 0.07)
		_add_label("Date%d" % i, dates[i], Vector3(xs[i], 0.52, -0.12), 0.105, PAPER)
		_add_label("ArtifactTitle%d" % i, titles[i], Vector3(xs[i], 0.55, 0.44), 0.105, INK)
		for line in 2:
			_add_box("ArchiveLine%d_%d" % [i, line], Vector3(xs[i], 0.77 - line * 0.12, 0.43), Vector3(0.38, 0.016, 0.008), Color("#756b5c"), 0.003)
	_add_label("Chronology", "KAYNAK + TARİH SIRASI", Vector3(0, 1.18, 0.92), 0.13, PAPER)


func _build_geography() -> void:
	# Height-coded relief and a route that grows from a known coordinate to its
	# destination. The graticule stays fixed as a spatial reference.
	_add_box("MapLand", Vector3(0, 0.04, 0), Vector3(3.28, 0.12, 2.02), Color("#537b6c"), 0.06)
	for i in 4:
		var x := -1.18 + i * 0.76
		_add_box("Longitude%d" % i, Vector3(x, 0.108, 0), Vector3(0.018, 0.012, 1.78), Color("#acc2a0"), 0.004)
	for i in 3:
		var z := -0.58 + i * 0.58
		_add_box("Latitude%d" % i, Vector3(0, 0.108, z), Vector3(2.94, 0.012, 0.018), Color("#acc2a0"), 0.004)
	var hills := [Vector3(-0.93, 0.28, -0.3), Vector3(-0.57, 0.36, -0.35), Vector3(-0.2, 0.24, -0.28), Vector3(0.42, 0.22, 0.35), Vector3(0.83, 0.33, 0.39)]
	for i in hills.size():
		var hill := _add_box("Relief%d" % i, hills[i], Vector3(0.5, hills[i].y * 1.7, 0.44), [Color("#789079"), Color("#a6a27a"), Color("#6c8b79")][i % 3], 0.09)
		hill.rotation_degrees.y = float(i * 17 - 20)
	var path_points: Array[Vector3] = [Vector3(-1.18, 0.67, 0.61), Vector3(-0.7, 0.7, 0.54), Vector3(-0.22, 0.76, 0.27), Vector3(0.36, 0.76, -0.05), Vector3(0.88, 0.7, -0.42), Vector3(1.23, 0.67, -0.58)]
	for i in path_points.size() - 1:
		var part := _add_box("RouteSegment%d" % i, (path_points[i] + path_points[i + 1]) * 0.5, Vector3(path_points[i].distance_to(path_points[i + 1]), 0.035, 0.045), AMBER, 0.018)
		part.rotation.y = atan2(path_points[i + 1].z - path_points[i].z, path_points[i + 1].x - path_points[i].x)
		_route_parts.append(part)
		part.visible = false
	_add_cylinder("OriginMarker", path_points[0], 0.15, 0.12, MINT)
	_add_cylinder("DestinationMarker", path_points[-1], 0.15, 0.12, CORAL)
	_add_label("OriginLabel", "P · BAŞLANGIÇ", Vector3(-1.08, 0.44, 0.72), 0.09, PAPER)
	_add_label("DestinationLabel", "Q · HEDEF", Vector3(1.08, 0.42, -0.73), 0.09, PAPER)
	_add_label("MapKey", "YÜKSELTİ + KOORDİNAT", Vector3(0, 0.87, 0.93), 0.12, PAPER)


func _apply_state() -> void:
	if _book_left != null:
		var opening := _opening_progress if _opening_progress > 0.0 else _progress
		_book_left.rotation.y = lerpf(-0.02, 0.24, opening)
		_book_right.rotation.y = lerpf(0.02, -0.24, opening)
	if _theme == &"reading":
		var reveal := maxf(_evidence_reveal, _progress)
		for index in _evidence_cards.size():
			var selected := index == mini(3, int(reveal * 4.0))
			var card := _evidence_cards[index]
			card.position.y = 0.57 + (0.18 if selected and reveal > 0.0 else 0.0)
			_set_color(card, MINT if selected and reveal > 0.0 else PAPER)
			card.scale = Vector3.ONE * (1.0 + (0.08 if selected and reveal > 0.0 else 0.0))
		if _reading_line != null:
			_set_color(_reading_line, AMBER if reveal > 0.0 else STONE)
		if _reading_note != null and _evidence_text != "":
			_reading_note.text = _evidence_text
	if _literature_note != null and _evidence_text != "":
		_literature_note.text = _evidence_text
	if _theme == &"history":
		var count := clampi(int(ceil(maxf(_progress, _evidence_reveal) * 3.0)), 0, 3)
		for index in _history_markers.size():
			_set_color(_history_markers[index], MINT if index < count else ([MINT, AMBER, CORAL][index]).darkened(0.48))
	if _theme == &"geography":
		var route_progress := maxf(_progress, _evidence_reveal)
		var visible_count := int(ceil(route_progress * _route_parts.size()))
		for index in _route_parts.size():
			_route_parts[index].visible = index < visible_count
			if index < visible_count:
				_set_color(_route_parts[index], CORAL if _result < 0 else AMBER if _result == 0 else MINT)
	if _result_note != null:
		_result_note.text = "" if _result == 0 else ("KANIT DOĞRULANDI" if _result > 0 else "YENİDEN İNCELE")
		_result_note.modulate = MINT if _result > 0 else CORAL if _result < 0 else PAPER


func _new_node(node_name: String, at: Vector3, parent: Node = self) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = at
	parent.add_child(node)
	return node


func _add_box(node_name: String, at: Vector3, dimensions: Vector3, color: Color, bevel: float = 0.02, parent: Node = self) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.subdivide_width = 1
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_cylinder(node_name: String, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color)
	add_child(instance)
	return instance


func _add_label(node_name: String, value: String, at: Vector3, text_size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = at
	label.font_size = 32
	label.pixel_size = text_size / 32.0
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("#10202a")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.08
	material.roughness = 0.7
	return material


func _set_color(instance: MeshInstance3D, color: Color) -> void:
	if instance.material_override is StandardMaterial3D:
		(instance.material_override as StandardMaterial3D).albedo_color = color
