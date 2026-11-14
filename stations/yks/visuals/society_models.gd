extends Node3D
## Small, legible 3D mechanisms for the social-science and language YKS stages.

const INK := Color("#142630")
const PAPER := Color("#d7e5e5")
const MUTED := Color("#69818b")
const MINT := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const CORAL := Color("#e5645a")
const BLUE := Color("#72b7d2")

var _theme: StringName = &""
var _phase := 0.0
var _progress := 0.0
var _opening_progress := 0.0
var _result := 0
var _evidence_text := ""
var _parts: Dictionary = {}
var _marker_path: Array[Vector3] = []
var _evidence_label: Label3D


func build(theme_id: StringName) -> void:
	_theme = theme_id
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_parts.clear()
	_marker_path.clear()
	_evidence_label = null
	_phase = 0.0
	_progress = 0.0
	_opening_progress = 0.0
	_result = 0
	_evidence_text = ""
	match _theme:
		&"philosophy": _build_philosophy()
		&"religion": _build_religion()
		&"psychology": _build_psychology()
		&"sociology": _build_sociology()
		&"logic": _build_logic()
		&"english": _build_english()
		_: _build_philosophy()
	_apply_state()


func update_stage(state: Dictionary) -> void:
	if state.has("progress"):
		_progress = clampf(float(state.progress), 0.0, 1.0)
	if state.has("phase"):
		_phase = float(state.phase)
	if state.has("opening_progress"):
		_opening_progress = clampf(float(state.opening_progress), 0.0, 1.0)
	if state.has("result"):
		_result = int(state.result)
	if state.has("evidence_text"):
		_evidence_text = str(state.evidence_text)
	if _evidence_label != null:
		_evidence_label.text = _evidence_text.left(52)
		_evidence_label.visible = not _evidence_text.is_empty()
	_apply_state()


func set_result(result: int, progress: float) -> void:
	_result = result
	_progress = clampf(progress, 0.0, 1.0)
	_apply_state()


func _process(delta: float) -> void:
	_phase += delta
	_apply_state()


func _build_philosophy() -> void:
	_title("FELSEFE · İDDİA VE GEREKÇE")
	_floor(6.5, 4.2)
	# Three premises travel along a shared beam; the counterweight makes support visible.
	_box("Fulcrum", Vector3(0, 0.72, 0), Vector3(0.48, 1.35, 0.48), MUTED)
	_box("Base", Vector3(0, 0.12, 0), Vector3(2.1, 0.22, 1.0), INK)
	_parts["beam"] = _box("ReasoningBeam", Vector3(0, 1.55, 0), Vector3(4.6, 0.16, 0.28), AMBER)
	var premise_nodes: Array[MeshInstance3D] = []
	for i in 3:
		var x := -1.65 + float(i) * 1.65
		premise_nodes.append(_box("Premise%d" % i, Vector3(x, 1.89, 0), Vector3(1.12, 0.46, 0.62), BLUE if i < 2 else MINT))
		_label("P%d" % (i + 1), Vector3(x - 0.18, 2.16, 0.01), PAPER, 0.48)
		_link("Reason%d" % i, Vector3(x, 1.33, 0), Vector3(x, 1.0, 0), MUTED, 0.08)
	_parts["premises"] = premise_nodes
	_box("Conclusion", Vector3(0, 0.58, -1.3), Vector3(1.5, 0.38, 0.48), MINT)
	_label("SONUÇ", Vector3(-0.82, 0.84, -1.3), PAPER, 0.34)
	_link("InferencePath", Vector3(0, 1.1, -0.9), Vector3(0, 0.82, -0.9), AMBER, 0.1)
	_label("ÖNCÜLLER  →  ÇIKARIM  →  İDDİA", Vector3(-2.45, 2.65, 0), PAPER, 0.36)


func _build_religion() -> void:
	_title("DİN KÜLTÜRÜ · KARŞILAŞTIRMA")
	_floor(6.7, 4.2)
	# Neutral exhibit: compare two descriptions against the same evidence rail.
	_box("ExhibitTable", Vector3(0, 0.46, 0), Vector3(5.4, 0.16, 1.45), MUTED)
	for i in 2:
		var x := -1.45 + float(i) * 2.9
		_box("ArtifactPanel%d" % i, Vector3(x, 1.55, -0.1), Vector3(1.45, 1.7, 0.16), BLUE if i == 0 else AMBER)
		_box("PanelInset%d" % i, Vector3(x, 1.55, 0.0), Vector3(1.16, 1.38, 0.08), INK)
		_label("GÖRÜŞ A" if i == 0 else "GÖRÜŞ B", Vector3(x - 0.42, 2.08, 0.06), PAPER, 0.4)
		_link("EvidenceLink%d" % i, Vector3(x, 0.8, 0.55), Vector3(0, 0.8, 0.55), MUTED, 0.07)
	_box("CommonEvidence", Vector3(0, 0.82, 0.76), Vector3(2.0, 0.15, 0.25), MINT)
	_label("ORTAK METİN / BAĞLAM", Vector3(-1.0, 1.03, 0.92), PAPER, 0.32)
	_parts["comparison_slider"] = _sphere("ComparisonMarker", Vector3(-1.4, 0.96, 1.0), 0.12, AMBER)
	_link("ScaleRail", Vector3(-1.5, 0.95, 1), Vector3(1.5, 0.95, 1), PAPER, 0.045)
	_label("AYNI KANITLA İDDİALARI KARŞILAŞTIR", Vector3(-2.45, 2.8, 0), PAPER, 0.33)


func _build_psychology() -> void:
	_title("PSİKOLOJİ · ALGI LABİRENTİ")
	_floor(6.1, 4.4)
	# A single path turns the same stimulus into different interpretations at the fork.
	var walls := [
		[Vector3(-2.2, 0.48, -1.45), Vector3(2.0, 0.75, 0.16)],
		[Vector3(-2.2, 0.48, 1.45), Vector3(2.0, 0.75, 0.16)],
		[Vector3(-1.15, 0.48, -0.7), Vector3(0.16, 1.0, 1.5)],
		[Vector3(-0.15, 0.48, -0.72), Vector3(0.16, 0.86, 1.48)],
		[Vector3(0.9, 0.48, -0.72), Vector3(0.16, 0.86, 1.48)],
		[Vector3(0.05, 0.48, -0.73), Vector3(1.0, 0.7, 0.16)],
		[Vector3(0.05, 0.48, 0.0), Vector3(1.0, 0.7, 0.16)],
		[Vector3(0.05, 0.48, 0.73), Vector3(1.0, 0.7, 0.16)],
		[Vector3(1.52, 0.48, -0.92), Vector3(0.16, 0.86, 1.05)],
		[Vector3(1.52, 0.48, 0.92), Vector3(0.16, 0.86, 1.05)],
	]
	for i in walls.size():
		_box("MazeWall%d" % i, walls[i][0], walls[i][1], MUTED)
	_sphere("Stimulus", Vector3(-2.45, 0.35, 0), 0.23, AMBER)
	_label("AYNI UYARAN", Vector3(-2.55, 0.8, 0), PAPER, 0.32)
	_label("BAĞLAM A", Vector3(0.1, 1.0, -1.05), BLUE, 0.34)
	_label("BAĞLAM B", Vector3(0.1, 1.0, 0.9), MINT, 0.34)
	_marker_path = [Vector3(-2.45, 0.3, 0), Vector3(-1.5, 0.3, 0), Vector3(-0.4, 0.3, 0), Vector3(0.65, 0.3, -0.78), Vector3(1.95, 0.3, -0.78)]
	_parts["perception_marker"] = _sphere("PerceptionMarker", _marker_path[0], 0.15, CORAL)
	_label("ALGI BAĞLAMA BAĞLIDIR", Vector3(-2.1, 2.0, 0), PAPER, 0.34)


func _build_sociology() -> void:
	_title("SOSYOLOJİ · GRUP VE İLİŞKİLER")
	_floor(6.5, 4.3)
	# Nodes sit in meaningful groups; one bridge shows how roles connect groups.
	var centers := [Vector3(-1.55, 0.85, -0.6), Vector3(1.55, 0.85, -0.6), Vector3(-1.55, 0.85, 0.8), Vector3(1.55, 0.85, 0.8)]
	for group in 2:
		var z := -0.6 if group == 0 else 0.8
		_box("GroupFrame%d" % group, Vector3(0, 0.1, z), Vector3(5.4, 0.08, 1.18), INK)
		_label("GRUP A · ORTAK UYGULAMA" if group == 0 else "GRUP B · KURUM", Vector3(-2.45, 1.45, z - 0.42), BLUE if group == 0 else AMBER, 0.3)
	for i in centers.size():
		_sphere("Member%d" % i, centers[i], 0.22, BLUE if i < 2 else AMBER)
		_label("ROL %d" % (i + 1), centers[i] + Vector3(-0.32, 0.35, 0), PAPER, 0.26)
	for i in 2:
		_link("GroupTie%d" % i, centers[i * 2], centers[i * 2 + 1], MUTED, 0.055)
	_parts["bridge"] = _link("IntergroupRelation", centers[0], centers[2], MINT, 0.1)
	_parts["bridge2"] = _link("IntergroupRelation2", centers[1], centers[3], MINT, 0.1)
	_label("ROL + KONUM ETKİLEŞİMİ ŞEKİLLENDİRİR", Vector3(-2.0, 2.4, 0), PAPER, 0.34)


func _build_logic() -> void:
	_title("MANTIK · ÇIKARIM KAPISI")
	_floor(6.4, 4.2)
	# Two premise sliders feed a mechanical AND gate; the output shutter opens only together.
	for i in 2:
		var z := -0.78 + float(i) * 1.56
		_box("InputTrack%d" % i, Vector3(-1.15, 0.42, z), Vector3(2.55, 0.12, 0.28), MUTED)
		_label("P" if i == 0 else "Q", Vector3(-2.35, 0.85, z), PAPER, 0.48)
		_parts["input%d" % i] = _box("InputToken%d" % i, Vector3(-2.05, 0.68, z), Vector3(0.46, 0.34, 0.38), BLUE)
		_link("InputRod%d" % i, Vector3(0.08, 0.67, z), Vector3(0.62, 0.67, 0), AMBER, 0.1)
	_box("GateHousing", Vector3(0.65, 1.0, 0), Vector3(1.0, 0.82, 1.15), INK)
	_box("GateFace", Vector3(0.65, 1.0, 0.6), Vector3(0.72, 0.6, 0.08), MUTED)
	_label("VE", Vector3(0.28, 1.12, 0.66), PAPER, 0.42)
	_box("OutputTrack", Vector3(1.82, 0.42, 0), Vector3(1.8, 0.12, 0.28), MUTED)
	_parts["gate_shutter"] = _box("OutputShutter", Vector3(1.4, 0.75, 0), Vector3(0.16, 0.82, 0.48), CORAL)
	_parts["output"] = _sphere("InferenceOutput", Vector3(2.65, 0.68, 0), 0.22, CORAL)
	_label("P ∧ Q  →  SONUÇ", Vector3(-1.7, 2.1, 0), PAPER, 0.36)


func _build_english() -> void:
	_title("İNGİLİZCE · CÜMLE YAPISI")
	_floor(6.5, 4.2)
	# Word blocks form a sentence; elevated arcs show grammatical dependency.
	var xs := [-1.8, 0.0, 1.8]
	var words := ["SUBJECT", "VERB", "OBJECT"]
	var colors := [BLUE, AMBER, MINT]
	for i in xs.size():
		_box("WordBlock%d" % i, Vector3(xs[i], 0.58, 0), Vector3(1.38, 0.72, 0.72), colors[i])
		_box("WordFace%d" % i, Vector3(xs[i], 0.58, 0.39), Vector3(1.2, 0.5, 0.06), INK)
		_label(words[i], Vector3(xs[i] - 0.48, 0.72, 0.44), PAPER, 0.28)
	_parts["subject_arc"] = _arch("SubjectVerbArc", Vector3(-1.8, 1.0, 0.08), Vector3(0, 1.0, 0.08), 0.9, BLUE)
	_parts["object_arc"] = _arch("VerbObjectArc", Vector3(0, 1.0, 0.08), Vector3(1.8, 1.0, 0.08), 0.65, MINT)
	_link("SentenceBaseline", Vector3(-2.5, 0.18, 0.2), Vector3(2.5, 0.18, 0.2), MUTED, 0.06)
	_label("KİM  →  NE YAPAR  →  KİME / NEYİ", Vector3(-2.35, 2.55, 0), PAPER, 0.32)
	_label("UYUM + SÖZCÜK SIRASI ANLAM TAŞIR", Vector3(-2.2, 2.2, 0), AMBER, 0.3)


func _apply_state() -> void:
	var success := _result > 0
	var failure := _result < 0
	var feedback := MINT if success else CORAL if failure else AMBER
	match _theme:
		&"philosophy":
			var beam: Node3D = _parts.get("beam")
			if beam != null:
				var angle := (0.5 - _progress) * 0.3 + sin(_phase * 1.4) * 0.025
				beam.rotation.z = angle
				_set_node_color(beam, feedback if _result != 0 else AMBER)
				var premises: Array = _parts.get("premises", [])
				for i in premises.size():
					var x := -1.65 + float(i) * 1.65
					premises[i].position = Vector3(x * cos(angle), 1.55 + x * sin(angle), 0)
					premises[i].rotation.z = angle
		&"religion":
			var slider: Node3D = _parts.get("comparison_slider")
			if slider != null:
				slider.position.x = lerpf(-1.4, 1.4, _progress)
				slider.scale = Vector3.ONE * (1.0 + 0.12 * sin(_phase * 2.0))
				_set_node_color(slider, feedback if _result != 0 else AMBER)
		&"psychology":
			var marker: Node3D = _parts.get("perception_marker")
			if marker != null and not _marker_path.is_empty():
				marker.position = _path_position(_marker_path, _progress)
				_set_node_color(marker, feedback if _result != 0 else CORAL)
		&"sociology":
			for key in ["bridge", "bridge2"]:
				var bridge: Node3D = _parts.get(key)
				if bridge != null:
					bridge.scale.y = 0.7 + 0.5 * _progress + 0.08 * sin(_phase * 2.3)
					_set_node_color(bridge, feedback if _result != 0 else MINT)
		&"logic":
			var shutter: Node3D = _parts.get("gate_shutter")
			var output: Node3D = _parts.get("output")
			if shutter != null:
				var opened := maxf(_progress, _opening_progress) if not success else 1.0
				shutter.position.y = 0.75 + opened * 0.78
				_set_node_color(shutter, feedback if _result != 0 else AMBER)
			if output != null:
				output.position.x = lerpf(2.65, 3.05, _progress)
				_set_node_color(output, feedback if _result != 0 else CORAL)
		&"english":
			for key in ["subject_arc", "object_arc"]:
				var arc: Node3D = _parts.get(key)
				if arc != null:
					arc.scale.y = 0.55 + 0.75 * _progress
					_set_node_color(arc, feedback if _result != 0 else (BLUE if key == "subject_arc" else MINT))


func _path_position(points: Array[Vector3], amount: float) -> Vector3:
	var scaled := amount * float(points.size() - 1)
	var index := mini(int(scaled), points.size() - 2)
	return points[index].lerp(points[index + 1], scaled - float(index))


func _title(text_value: String) -> void:
	_label(text_value, Vector3(-2.75, 3.15, 0), PAPER, 0.34)
	_evidence_label = _label("", Vector3(-2.7, 2.8, -0.1), BLUE, 0.24)
	_evidence_label.visible = false


func _floor(width: float, depth: float) -> void:
	_box("ModelBase", Vector3(0, -0.08, 0), Vector3(width, 0.12, depth), INK)


func _box(node_name: String, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color)
	add_child(node)
	return node


func _sphere(node_name: String, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color)
	add_child(node)
	return node


func _link(node_name: String, from: Vector3, to: Vector3, color: Color, thickness: float) -> MeshInstance3D:
	var direction := to - from
	var mesh := CylinderMesh.new()
	mesh.top_radius = thickness
	mesh.bottom_radius = thickness
	mesh.height = direction.length()
	mesh.radial_segments = 8
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = (from + to) * 0.5
	node.quaternion = Quaternion(Vector3.UP, direction.normalized())
	node.material_override = _material(color)
	add_child(node)
	return node


func _arch(node_name: String, from: Vector3, to: Vector3, rise: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	add_child(root)
	var previous := from
	for i in 12:
		var t := float(i + 1) / 12.0
		var next := from.lerp(to, t) + Vector3(0, 4.0 * rise * t * (1.0 - t), 0)
		_link("ArcSegment%d" % i, previous, next, color, 0.045).reparent(root)
		previous = next
	return root


func _label(text_value: String, at: Vector3, color: Color, font_size: float) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = at
	label.font_size = roundi(font_size * 64.0)
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.modulate = color
	label.outline_size = 6
	label.outline_modulate = Color("#0b1720")
	add_child(label)
	return label


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	material.metallic = 0.12
	if color == MINT or color == AMBER or color == CORAL:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.28
	return material


func _set_node_color(node: Node3D, color: Color) -> void:
	if node is MeshInstance3D:
		node.material_override = _material(color)

