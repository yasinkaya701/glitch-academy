extends Control
## Kalp sahnesi (3B). Gerçek kalp, akciğer ve vücut modelleri; serbest kamera; oyuncunun takıp çevirdiği
## kapak protezleri; bağladığı damar hortumları; akış parçacıkları. Kurallar heart_model / heart_network'te.
## Eski 2D sahnenin kullandığı alan ve sinyal adları korunmuştur.

signal spot_pressed(id: StringName)
signal valve_dropped(slot: int, valve: int)
signal ports_connected(from_port: StringName, to_port: StringName)
signal port_cleared(from_port: StringName)

const Model = preload("res://stations/heart/heart_model.gd")
const Network = preload("res://stations/heart/heart_network.gd")
const Rig = preload("res://stations/heart/orbit_rig.gd")
const Prosthesis = preload("res://stations/heart/valve_prosthesis.gd")
const HEART = preload("res://stations/heart/assets/model/heart_cutaway_light.glb")
const LUNGS = preload("res://assets/models/human-lungs.glb")
const BODY = preload("res://assets/models/human-muscles.glb")

const INK := Color("#e9f1ee")
const JADE := Color("#8ff0d4")
const GOLD := Color("#ffc082")
const RED := Color("#ff6b5e")
const BLOOD_RICH := Color("#ff4a3d")
const BLOOD_POOR := Color("#4f7bff")
const BACK := Color("#05080e")

## Kalp modeli ölçeği (modelin yerel birimi 1 = 1 m, kalp yaklaşık 0,13).
const S := 7.5
const HEART_CENTER := Vector3(0.0, 0.065, 0.0)
const HEART_SHIFT := Vector3(0.0, -0.4875, 0.0)

## Model koordinatında ölçülmüş noktalar (derinlik haritasından).
const SPOT_POS := {
	&"svc": Vector3(-0.0210, 0.1085, 0.0139),
	&"right_atrium": Vector3(-0.0223, 0.0697, 0.0076),
	&"right_ventricle": Vector3(-0.0133, 0.0339, 0.0198),
	&"pulmonary_artery": Vector3(0.0178, 0.0973, 0.0194),
	&"pulmonary_veins": Vector3(0.0349, 0.0878, 0.0095),
	&"left_atrium": Vector3(0.0211, 0.0767, 0.0080),
	&"left_ventricle": Vector3(0.0198, 0.0298, 0.0221),
	&"aorta": Vector3(0.0023, 0.1177, 0.0139),
}
const SPOTS := SPOT_POS
const VALVE_POS := {
	Model.Valve.TRICUSPID: Vector3(-0.0204, 0.0559, 0.0159),
	Model.Valve.MITRAL: Vector3(0.0184, 0.0582, 0.0189),
	Model.Valve.AORTIC: Vector3(-0.0083, 0.0888, 0.0165),
	Model.Valve.PULMONARY: Vector3(0.0018, 0.0752, 0.0160),
}
## Akış yönü (kapağın izin verdiği). Protezin +Y ekseni buraya bakar.
const VALVE_DIR := {
	Model.Valve.TRICUSPID: Vector3(0.12, -1.0, 0.18),
	Model.Valve.MITRAL: Vector3(0.10, -1.0, 0.14),
	Model.Valve.AORTIC: Vector3(0.44, 0.9, 0.0),
	Model.Valve.PULMONARY: Vector3(0.6, 0.8, 0.0),
}
const VALVE_RADIUS := {
	Model.Valve.TRICUSPID: 0.0092,
	Model.Valve.MITRAL: 0.0085,
	Model.Valve.AORTIC: 0.0058,
	Model.Valve.PULMONARY: 0.0056,
}
## Kalp içi akış hatları (model koordinatı).
const FLOWS := {
	&"ven_in": [Vector3(-0.0210, 0.1190, 0.0140), Vector3(-0.0210, 0.1085, 0.0139), Vector3(-0.0223, 0.0697, 0.0076)],
	&"r_av": [Vector3(-0.0223, 0.0697, 0.0076), Vector3(-0.0204, 0.0559, 0.0159), Vector3(-0.0133, 0.0339, 0.0198)],
	&"r_out": [Vector3(-0.0080, 0.0450, 0.0200), Vector3(0.0018, 0.0752, 0.0160), Vector3(0.0178, 0.0973, 0.0194), Vector3(0.0390, 0.0985, 0.0180)],
	&"l_in": [Vector3(0.0450, 0.0878, 0.0095), Vector3(0.0211, 0.0767, 0.0080)],
	&"l_av": [Vector3(0.0211, 0.0767, 0.0080), Vector3(0.0184, 0.0582, 0.0189), Vector3(0.0198, 0.0298, 0.0221)],
	&"l_out": [Vector3(0.0122, 0.0450, 0.0200), Vector3(-0.0083, 0.0888, 0.0165), Vector3(0.0023, 0.1177, 0.0139), Vector3(0.0023, 0.1305, 0.0145)],
}
const FLOW_RICH := [&"l_in", &"l_av", &"l_out"]

## Dış damar uçları. Kalp uçları dünya koordinatında (model × ölçek + kaydırma).
const LUNGS_POS := Vector3(1.12, 0.10, 0.05)
const BODY_POS := Vector3(-1.28, -0.22, 0.0)
const PORT_WORLD := {
	&"svc_in": Vector3(-0.0210, 0.1190, 0.0140) * S + HEART_SHIFT,
	&"aorta_out": Vector3(0.0023, 0.1305, 0.0145) * S + HEART_SHIFT,
	&"pa_out": Vector3(0.0390, 0.0985, 0.0180) * S + HEART_SHIFT,
	&"pv_in": Vector3(0.0450, 0.0878, 0.0095) * S + HEART_SHIFT,
	&"lungs_in": LUNGS_POS + Vector3(-0.34, 0.26, 0.0),
	&"lungs_out": LUNGS_POS + Vector3(-0.34, -0.08, 0.0),
	&"body_out": BODY_POS + Vector3(0.30, 0.46, 0.0),
	&"body_in": BODY_POS + Vector3(0.14, 0.66, 0.0),
}
## Hortumun porttan çıkış yönü.
const PORT_OUT_DIR := {
	&"svc_in": Vector3(0, 1, 0), &"aorta_out": Vector3(0, 1, 0), &"pa_out": Vector3(1, 0.2, 0),
	&"pv_in": Vector3(1, 0, 0), &"lungs_in": Vector3(-1, 0, 0), &"lungs_out": Vector3(-1, 0, 0),
	&"body_out": Vector3(1, 0.1, 0), &"body_in": Vector3(1, 0.4, 0),
}
const OUT_PORTS := Network.OUT_PORTS
const IN_PORTS := Network.IN_PORTS
const CORRECT_LINKS := Network.CORRECT_LINKS
const PORT_NAMES := {
	&"body_out": "Vücuttan dönen kan", &"pa_out": "Akciğer atardamarı", &"lungs_out": "Akciğerden çıkan kan", &"aorta_out": "Aort",
	&"svc_in": "Üst ana toplardamar", &"lungs_in": "Akciğere giriş", &"pv_in": "Akciğer toplardamarı", &"body_in": "Vücuda giriş",
}
const PORT_RICH := {&"body_out": false, &"pa_out": false, &"lungs_out": true, &"aorta_out": true}

var viewport: SubViewport
var rig: Rig
var heart_root: Node3D
var body_node: Node3D
var lungs_node: Node3D

## Görünüm durumu (görev ayarlar).
var valve_present: Dictionary = {}
var valve_amount: Dictionary = {}
var valve_target: Dictionary = {}
var valve_marked: Dictionary = {}
var valve_flipped: Dictionary = {}
var flow_dir: Dictionary = {}
var flow_color_override: Dictionary = {}
var labels: Dictionary = {}
var spots_active: Dictionary = {}
var highlight: StringName = &""
var show_flow := true
var beat := 0.0
var flow_speed := 1.0
var body_oxygen := 1.0
var connections: Dictionary = CORRECT_LINKS.duplicate()
var connection_flow := true
var ports_active := false
var port_warning: Dictionary = {}

var _time := 0.0
var _prostheses: Dictionary = {}
var _slot_rings: Dictionary = {}
var _port_markers: Dictionary = {}
var _tubes: Node3D
var _tube_signature := ""
var _label_nodes: Dictionary = {}
var _flow_meshes: Dictionary = {}
var _link_particles: Dictionary = {}
var _highlight_marker: MeshInstance3D
var _drag_from: StringName = &""
var _drag_world := Vector3.ZERO
var _drag_tube: MeshInstance3D
var _orbiting := false
var _press_position := Vector2.ZERO
var _press_moved := false
var _oxygen_overlay: StandardMaterial3D
var _oxygen_bar: MeshInstance3D
var _oxygen_label: Label3D
var _floor_material: StandardMaterial3D


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	container.add_child(viewport)
	for valve in Model.VALVE_NAMES:
		valve_present[valve] = true
		valve_amount[valve] = 0.0
		valve_target[valve] = 0.0
		valve_flipped[valve] = false
	_build_world()


func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.36, 0.43, 0.56)
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.12
	environment.glow_bloom = 0.0
	environment.fog_enabled = true
	environment.fog_light_color = Color("#070d16")
	environment.fog_density = 0.09
	environment.ssao_enabled = true
	var world := WorldEnvironment.new()
	world.environment = environment
	viewport.add_child(world)

	rig = Rig.new()
	rig.target = Vector3(0.0, 0.05, 0.0)
	rig.distance = 3.3
	rig.pitch = 0.08
	rig.min_distance = 0.12
	viewport.add_child(rig)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 28, 0)
	key.light_color = Color(1.0, 0.92, 0.82)
	key.light_energy = 1.5
	key.shadow_enabled = true
	viewport.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, 205, 0)
	rim.light_color = Color(0.55, 0.78, 1.0)
	rim.light_energy = 0.9
	viewport.add_child(rim)

	_floor_material = StandardMaterial3D.new()
	_floor_material.albedo_color = Color("#070b11")
	_floor_material.metallic = 0.0
	_floor_material.roughness = 1.0
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	floor_mesh.mesh = plane
	floor_mesh.material_override = _floor_material
	floor_mesh.position = Vector3(0, -0.8, 0)
	viewport.add_child(floor_mesh)

	heart_root = Node3D.new()
	heart_root.scale = Vector3.ONE * S
	heart_root.position = -HEART_CENTER * S
	viewport.add_child(heart_root)
	heart_root.add_child(HEART.instantiate())

	lungs_node = _place_model(LUNGS, LUNGS_POS, 2.7, Vector3(0, 8, 0))
	body_node = _place_model(BODY, BODY_POS, 0.62, Vector3.ZERO)
	_setup_oxygen_visuals()
	_build_ports()
	_build_slots()
	_tubes = Node3D.new()
	viewport.add_child(_tubes)
	_build_flow_particles()
	_highlight_marker = MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.05
	marker_mesh.height = 0.1
	_highlight_marker.mesh = marker_mesh
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(JADE, 0.28)
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_marker.material_override = marker_material
	_highlight_marker.hide()
	viewport.add_child(_highlight_marker)
	_rebuild_tubes()


func _place_model(scene: PackedScene, position: Vector3, scale_factor: float, rotation_degrees: Vector3) -> Node3D:
	var holder := Node3D.new()
	var model: Node3D = scene.instantiate()
	var box := _bounds(model)
	model.scale = Vector3.ONE * scale_factor
	model.rotation_degrees = rotation_degrees
	model.position = -box.get_center() * scale_factor
	holder.position = position
	holder.add_child(model)
	viewport.add_child(holder)
	return holder


func _bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if current is MeshInstance3D:
			var local: AABB = (current as MeshInstance3D).get_aabb()
			box = local if first else box.merge(local)
			first = false
	return box


func _setup_oxygen_visuals() -> void:
	_oxygen_overlay = StandardMaterial3D.new()
	_oxygen_overlay.albedo_color = Color(0.25, 0.35, 0.8, 0.0)
	_oxygen_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_oxygen_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var stack: Array[Node] = [body_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if current is MeshInstance3D:
			(current as MeshInstance3D).material_overlay = _oxygen_overlay
	_oxygen_bar = MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.5, 0.025, 0.025)
	_oxygen_bar.mesh = bar_mesh
	var bar_material := StandardMaterial3D.new()
	bar_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bar_material.albedo_color = JADE
	_oxygen_bar.material_override = bar_material
	_oxygen_bar.position = BODY_POS + Vector3(0, 0.80, 0.1)
	viewport.add_child(_oxygen_bar)
	_oxygen_label = _label3d("Doku oksijeni", INK, 13)
	_oxygen_label.position = BODY_POS + Vector3(0, 0.88, 0.1)
	viewport.add_child(_oxygen_label)


func _label3d(text: String, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size * 4
	label.pixel_size = 0.0012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.outline_size = 12
	label.outline_modulate = Color(BACK, 0.95)
	return label


# --- Portlar, yuvalar --------------------------------------------------

func _build_ports() -> void:
	for id in PORT_WORLD:
		var marker := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.035
		mesh.height = 0.07
		marker.mesh = mesh
		var material := StandardMaterial3D.new()
		var out := OUT_PORTS.has(id)
		var rich: bool = PORT_RICH.get(id, false)
		material.albedo_color = (BLOOD_RICH if rich else BLOOD_POOR) if out else JADE
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.4
		marker.material_override = material
		marker.position = PORT_WORLD[id]
		marker.visible = false
		viewport.add_child(marker)
		_port_markers[id] = marker


func _build_slots() -> void:
	for slot in VALVE_POS:
		var radius: float = VALVE_RADIUS[slot]
		var orientation := Quaternion(Vector3.UP, (VALVE_DIR[slot] as Vector3).normalized())
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.outer_radius = radius * 1.45
		mesh.inner_radius = radius * 1.2
		ring.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = GOLD
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = material
		ring.position = VALVE_POS[slot]
		ring.quaternion = orientation
		heart_root.add_child(ring)
		_slot_rings[slot] = ring
		var prosthesis := Prosthesis.new()
		heart_root.add_child(prosthesis)
		prosthesis.setup(slot, radius)
		prosthesis.position = VALVE_POS[slot]
		prosthesis.quaternion = orientation
		_prostheses[slot] = prosthesis


func _build_flow_particles() -> void:
	for key in FLOWS:
		var mesh_instance := MultiMeshInstance3D.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		var sphere := SphereMesh.new()
		sphere.radius = 0.0009
		sphere.height = 0.0018
		sphere.radial_segments = 8
		sphere.rings = 4
		multi.mesh = sphere
		multi.instance_count = 22
		multi.visible_instance_count = 0
		mesh_instance.multimesh = multi
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		mesh_instance.material_override = material
		heart_root.add_child(mesh_instance)
		_flow_meshes[key] = mesh_instance


# --- Her kare -----------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	for valve in valve_amount:
		valve_amount[valve] = move_toward(valve_amount[valve], valve_target[valve], delta * 5.0)
	var s := 1.0 + 0.02 * beat
	heart_root.scale = Vector3.ONE * S * s
	heart_root.position = -HEART_CENTER * S * s
	_update_slots_and_valves()
	_update_ports()
	_update_flows()
	_update_labels()
	_update_oxygen()
	_update_highlight()
	_sync_tubes()


func _update_slots_and_valves() -> void:
	var pulse := 0.6 + 0.4 * sin(_time * 4.0)
	for slot in VALVE_POS:
		var present: bool = valve_present.get(slot, false)
		var prosthesis: Prosthesis = _prostheses[slot]
		prosthesis.visible = present
		prosthesis.open_amount = valve_amount.get(slot, 0.0)
		prosthesis.flipped = valve_flipped.get(slot, false)
		prosthesis.marked = valve_marked.get(slot, false)
		var ring: MeshInstance3D = _slot_rings[slot]
		ring.visible = not present
		ring.scale = Vector3.ONE * (1.0 + 0.1 * pulse)


func _update_ports() -> void:
	for id in _port_markers:
		var marker: MeshInstance3D = _port_markers[id]
		marker.visible = ports_active
		if ports_active:
			var taken: bool = connections.values().has(id) or connections.has(id)
			marker.scale = Vector3.ONE * (0.75 if taken else 1.0 + 0.18 * sin(_time * 4.0))


func _update_flows() -> void:
	for key in _flow_meshes:
		var mesh_instance: MultiMeshInstance3D = _flow_meshes[key]
		var multi := mesh_instance.multimesh
		var direction: float = flow_dir.get(key, 0.0) if show_flow else 0.0
		if direction == 0.0:
			multi.visible_instance_count = 0
			continue
		var points: Array = FLOWS[key]
		var color: Color = flow_color_override.get(key, BLOOD_RICH if key in FLOW_RICH else BLOOD_POOR)
		var length := _path_length(points)
		var count := 22
		multi.visible_instance_count = count
		for i in count:
			var t := fposmod(float(i) / count + _time * 0.35 * direction * flow_speed, 1.0)
			var position := _point_on_path(points, t * length)
			var fade := sin(t * PI)
			multi.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * (0.6 + 0.8 * fade)), position))
			multi.set_instance_color(i, Color(color, 0.95))


func _path_length(points: Array) -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += (points[i] as Vector3).distance_to(points[i + 1])
	return total


func _point_on_path(points: Array, distance: float) -> Vector3:
	var remaining := distance
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var seg := a.distance_to(b)
		if remaining <= seg:
			return a.lerp(b, remaining / maxf(seg, 0.00001))
		remaining -= seg
	return points[points.size() - 1]


func _update_labels() -> void:
	for id in labels:
		if not _label_nodes.has(id):
			var label := _label3d(String(labels[id]), JADE, 14)
			viewport.add_child(label)
			_label_nodes[id] = label
		var node: Label3D = _label_nodes[id]
		node.text = String(labels[id])
		node.global_position = _label_world(id)
	for id in _label_nodes.keys():
		if not labels.has(id):
			(_label_nodes[id] as Node).queue_free()
			_label_nodes.erase(id)


func _label_world(id: Variant) -> Vector3:
	if id is StringName and SPOT_POS.has(id):
		return heart_root.to_global(SPOT_POS[id]) + Vector3(0, 0.12, 0.18)
	if id is int and VALVE_POS.has(id):
		var side := {Model.Valve.TRICUSPID: Vector3(-0.28, 0.1, 0.2), Model.Valve.MITRAL: Vector3(0.3, 0.1, 0.2),
			Model.Valve.AORTIC: Vector3(-0.2, 0.3, 0.2), Model.Valve.PULMONARY: Vector3(0.22, 0.34, 0.2)}
		return heart_root.to_global(VALVE_POS[id]) + side[id]
	return Vector3.ZERO


func _update_oxygen() -> void:
	var o := clampf(body_oxygen, 0.0, 1.0)
	_oxygen_overlay.albedo_color = Color(0.2, 0.3, 0.9, (1.0 - o) * 0.45)
	var bar_mesh := _oxygen_bar.mesh as BoxMesh
	bar_mesh.size = Vector3(maxf(0.5 * o, 0.002), 0.025, 0.025)
	_oxygen_bar.position.x = BODY_POS.x - 0.25 + 0.25 * o
	(_oxygen_bar.material_override as StandardMaterial3D).albedo_color = (JADE if o > 0.66 else (GOLD if o > 0.33 else RED)) * 0.85
	_oxygen_label.text = "Doku oksijeni  %d%%" % roundi(o * 100.0)


func _update_highlight() -> void:
	if highlight != &"" and SPOT_POS.has(highlight):
		_highlight_marker.show()
		_highlight_marker.global_position = heart_root.to_global(SPOT_POS[highlight])
		_highlight_marker.scale = Vector3.ONE * (0.8 + 0.3 * sin(_time * 4.0))
	else:
		_highlight_marker.hide()


# --- Damar hortumları ---------------------------------------------------

func _tube_curve(from_port: StringName, to_port: StringName) -> PackedVector3Array:
	var p0: Vector3 = PORT_WORLD[from_port]
	var p1: Vector3 = PORT_WORLD[to_port]
	var reach := clampf(p0.distance_to(p1) * 0.45, 0.2, 1.0)
	var c0 := p0 + (PORT_OUT_DIR[from_port] as Vector3).normalized() * reach
	var c1 := p1 + (PORT_OUT_DIR[to_port] as Vector3).normalized() * reach
	var points := PackedVector3Array()
	for i in 49:
		var t := float(i) / 48.0
		points.append(p0 * pow(1 - t, 3) + c0 * 3 * pow(1 - t, 2) * t + c1 * 3 * (1 - t) * t * t + p1 * pow(t, 3))
	return points


func _sync_tubes() -> void:
	var signature := "%s|%s" % [str(connections), str(port_warning)]
	if signature != _tube_signature:
		_rebuild_tubes()
	for from_port in connections:
		if not _link_particles.has(from_port):
			continue
		var data: Dictionary = _link_particles[from_port]
		var multi: MultiMesh = data["multi"]
		var points: PackedVector3Array = data["points"]
		if not connection_flow or not show_flow:
			multi.visible_instance_count = 0
			continue
		var length := 0.0
		for i in points.size() - 1:
			length += points[i].distance_to(points[i + 1])
		var warn: bool = port_warning.get(from_port, false)
		var rich: bool = PORT_RICH[from_port]
		var color := GOLD if warn else (BLOOD_RICH if rich else BLOOD_POOR)
		var count: int = multi.instance_count
		multi.visible_instance_count = count
		for i in count:
			var t := fposmod(float(i) / count + _time * 0.3 * flow_speed, 1.0)
			var position := _point_on_path(Array(points), t * length)
			multi.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * (0.7 + 0.6 * sin(t * PI))), position))
			multi.set_instance_color(i, Color(color, 0.95))
	if _drag_from != &"":
		_draw_drag_tube()


func _rebuild_tubes() -> void:
	_tube_signature = "%s|%s" % [str(connections), str(port_warning)]
	for child in _tubes.get_children():
		child.queue_free()
	_drag_tube = null
	_link_particles.clear()
	for from_port in connections:
		var to_port: StringName = connections[from_port]
		var points := _tube_curve(from_port, to_port)
		var warn: bool = port_warning.get(from_port, false)
		var rich: bool = PORT_RICH[from_port]
		var color := GOLD if warn else (BLOOD_RICH if rich else BLOOD_POOR)
		_tubes.add_child(_tube_mesh(points, color, 0.022))
		var multi_instance := MultiMeshInstance3D.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		var sphere := SphereMesh.new()
		sphere.radius = 0.012
		sphere.height = 0.024
		sphere.radial_segments = 8
		sphere.rings = 4
		multi.mesh = sphere
		multi.instance_count = 26
		multi_instance.multimesh = multi
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		multi_instance.material_override = material
		_tubes.add_child(multi_instance)
		_link_particles[from_port] = {"multi": multi, "points": points}


func _tube_mesh(points: PackedVector3Array, color: Color, radius: float) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var sides := 12
	for i in points.size():
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - points[0]
		elif i == points.size() - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		tangent = tangent.normalized()
		var helper := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var side := tangent.cross(helper).normalized()
		var up := side.cross(tangent).normalized()
		for j in sides:
			var angle := TAU * float(j) / float(sides)
			var normal := side * cos(angle) + up * sin(angle)
			vertices.append(points[i] + normal * radius)
			normals.append(normal)
	for i in points.size() - 1:
		for j in sides:
			var a := i * sides + j
			var b := i * sides + (j + 1) % sides
			var c := (i + 1) * sides + j
			var d := (i + 1) * sides + (j + 1) % sides
			indices.append_array([a, c, b, b, c, d])
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.28)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.08
	material.metallic = 0.1
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.25
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _draw_drag_tube() -> void:
	if _drag_tube != null:
		_drag_tube.queue_free()
	var start: Vector3 = PORT_WORLD[_drag_from]
	var points := PackedVector3Array()
	for i in 17:
		var t := float(i) / 16.0
		var mid := start.lerp(_drag_world, t)
		mid.y += sin(t * PI) * 0.12
		points.append(mid)
	_drag_tube = _tube_mesh(points, GOLD, 0.02)
	_tubes.add_child(_drag_tube)


# --- Girdi ---------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			rig.zoom(0.9)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			rig.zoom(1.1)
		elif button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_on_press(button.position, button.double_click)
			else:
				_on_release(button.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _drag_from != &"":
			_drag_world = _world_on_ray(motion.position, PORT_WORLD[_drag_from])
		elif _orbiting:
			if motion.position.distance_to(_press_position) > 4.0:
				_press_moved = true
			rig.orbit(motion.relative)


func _ray(position: Vector2) -> Array:
	var viewport_position := position * Vector2(viewport.size) / size if size.x > 0.0 else position
	return rig.ray(viewport_position)


func _world_on_ray(position: Vector2, reference: Vector3) -> Vector3:
	var ray: Array = _ray(position)
	var plane := Plane(rig.camera.global_transform.basis.z, reference)
	var hit: Variant = plane.intersects_ray(ray[0], ray[1])
	return hit if hit != null else reference


func _nearest_sphere(position: Vector2, candidates: Dictionary, radius: float) -> Variant:
	var ray: Array = _ray(position)
	var origin: Vector3 = ray[0]
	var direction: Vector3 = ray[1]
	var best: Variant = null
	var best_distance := INF
	for id in candidates:
		var center: Vector3 = candidates[id]
		var to_center := center - origin
		var along := to_center.dot(direction)
		if along <= 0.0:
			continue
		var miss := (to_center - direction * along).length()
		if miss <= radius and along < best_distance:
			best_distance = along
			best = id
	return best


func _spot_centers() -> Dictionary:
	var centers := {}
	for id in SPOT_POS:
		if spots_active.get(id, false):
			centers[id] = heart_root.to_global(SPOT_POS[id])
	if spots_active.get(&"lungs", false):
		centers[&"lungs"] = lungs_node.global_position
	if spots_active.get(&"body", false):
		centers[&"body"] = body_node.global_position
	return centers


func _slot_centers() -> Dictionary:
	var centers := {}
	for slot in VALVE_POS:
		centers[slot] = heart_root.to_global(VALVE_POS[slot])
	return centers


func _on_press(position: Vector2, double: bool) -> void:
	_press_position = position
	_press_moved = false
	if ports_active:
		var ports := {}
		for id in OUT_PORTS:
			ports[id] = PORT_WORLD[id]
		var hit: Variant = _nearest_sphere(position, ports, 0.09)
		if hit != null:
			if connections.has(hit):
				connections.erase(hit)
				port_cleared.emit(hit)
			_drag_from = hit
			_drag_world = PORT_WORLD[hit]
			return
	if double:
		var slot_hit: Variant = _nearest_sphere(position, _slot_centers(), 0.12)
		if slot_hit != null:
			rig.focus(heart_root.to_global(VALVE_POS[slot_hit]), 0.28)
		else:
			rig.focus(Vector3(0.0, 0.05, 0.0), 3.3, 0.0, 0.08)
		return
	_orbiting = true


func _on_release(position: Vector2) -> void:
	if _drag_from != &"":
		var inputs := {}
		for id in IN_PORTS:
			inputs[id] = PORT_WORLD[id]
		var source := _drag_from
		_drag_from = &""
		if _drag_tube != null:
			_drag_tube.queue_free()
			_drag_tube = null
		var hit: Variant = _nearest_sphere(position, inputs, 0.11)
		if hit != null:
			ports_connected.emit(source, hit)
		return
	var was_orbit := _orbiting
	_orbiting = false
	if was_orbit and not _press_moved:
		_on_click(position)


func _on_click(position: Vector2) -> void:
	var slot_hit: Variant = _nearest_sphere(position, _slot_centers(), 0.07)
	if slot_hit != null and spots_active.get(StringName("valve_%d" % slot_hit), false):
		if Input.is_key_pressed(KEY_SHIFT):
			spot_pressed.emit(StringName("valve_remove_%d" % slot_hit))
		else:
			spot_pressed.emit(StringName("valve_%d" % slot_hit))
		return
	var spot_hit: Variant = _nearest_sphere(position, _spot_centers(), 0.1)
	if spot_hit != null:
		spot_pressed.emit(spot_hit)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("valve") and _nearest_sphere(at_position, _slot_centers(), 0.12) != null


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var slot_hit: Variant = _nearest_sphere(at_position, _slot_centers(), 0.12)
	if slot_hit != null:
		valve_dropped.emit(slot_hit, data["valve"])


func set_valves_for_phase(phase: int) -> void:
	for valve in Model.VALVE_NAMES:
		valve_target[valve] = 1.0 if Model.is_open(valve, phase) else 0.0
