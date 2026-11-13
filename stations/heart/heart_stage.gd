extends "res://scripts/anatomy/anatomy_view.gd"
## Kalp sahnesi (3B). Gerçek kalp, akciğer ve vücut modelleri; serbest kamera; oyuncunun takıp çevirdiği
## kapak protezleri; bağladığı damar hortumları; akış parçacıkları. Kurallar heart_model / heart_network'te.
## Eski 2D sahnenin kullandığı alan ve sinyal adları korunmuştur.

signal spot_pressed(id: StringName)
signal valve_dropped(slot: int, valve: int)
signal ports_connected(from_port: StringName, to_port: StringName)
signal port_cleared(from_port: StringName)

const Model = preload("res://stations/heart/heart_model.gd")
const Network = preload("res://stations/heart/heart_network.gd")
const Prosthesis = preload("res://stations/heart/valve_prosthesis.gd")
const Waveform = preload("res://scripts/anatomy/waveform_monitor.gd")
const HEART = preload("res://stations/heart/assets/model/heart_cutaway.glb")
const LUNGS = preload("res://assets/models/human-lungs.glb")
const BODY = preload("res://assets/models/human-muscles.glb")

const BLOOD_RICH := Color("#ff4a3d")
const BLOOD_POOR := Color("#4f7bff")

## Kalp modeli ölçeği (modelin yerel birimi 1 = 1 m, kalp yaklaşık 0,13).
const S := 9.0
const HEART_CENTER := Vector3(0.0, 0.065, 0.0)
const HEART_SHIFT := -HEART_CENTER * S

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
const LUNGS_POS := Vector3(1.12, -0.215, 0.05)
const BODY_POS := Vector3(-1.2, -0.10, 0.0)
const PORT_WORLD := {
	&"svc_in": Vector3(-0.0210, 0.1190, 0.0140) * S + HEART_SHIFT,
	&"aorta_out": Vector3(0.0023, 0.1305, 0.0145) * S + HEART_SHIFT,
	&"pa_out": Vector3(0.0390, 0.0985, 0.0180) * S + HEART_SHIFT,
	&"pv_in": Vector3(0.0450, 0.0878, 0.0095) * S + HEART_SHIFT,
	&"lungs_in": LUNGS_POS + Vector3(-0.34, 0.26, 0.0),
	&"lungs_out": LUNGS_POS + Vector3(-0.34, -0.08, 0.0),
	&"body_out": BODY_POS + Vector3(0.32, 0.16, 0.0),
	&"body_in": BODY_POS + Vector3(0.16, 0.36, 0.0),
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
var spots_active: Dictionary = {}
var highlight: StringName = &"":
	set(value):
		highlight = value
		highlight_id = value if value != &"" else null
var show_flow := true
var beat := 0.0
var flow_speed := 1.0
var body_oxygen := 1.0
var connections: Dictionary = CORRECT_LINKS.duplicate()
var connection_flow := true
var ports_active := false
var port_warning: Dictionary = {}

var _prostheses: Dictionary = {}
var _slot_rings: Dictionary = {}
var _port_markers: Dictionary = {}
var _tubes: Node3D
var _tube_signature := ""
var _flow_meshes: Dictionary = {}
var _link_particles: Dictionary = {}
var _drag_from: StringName = &""
var _drag_world := Vector3.ZERO
var _drag_tube: MeshInstance3D
var _oxygen_overlay: StandardMaterial3D
var _oxygen_bar: MeshInstance3D
var _oxygen_label: Label3D
var _waveform: Waveform
var _wave_ids: Array[int] = []
var _wave_clock := 0.0
var _metal: StandardMaterial3D
## Görev tarafından beslenir: döngü içi konum 0–1, geri akış 0–1 (sızıntı), kalp hızı.
var cycle_t := 0.0
var backflow := 0.0
var rate_hz := 1.2
var running := false


func _build() -> void:
	spots_active = active_pickables
	default_target = Vector3(0.0, 0.2, 0.0)
	default_distance = 3.5
	rig.target = default_target
	rig.distance = default_distance
	for valve in Model.VALVE_NAMES:
		valve_present[valve] = true
		valve_amount[valve] = 0.0
		valve_target[valve] = 0.0
		valve_flipped[valve] = false
	heart_root = Node3D.new()
	heart_root.scale = Vector3.ONE * S
	heart_root.position = -HEART_CENTER * S
	world.add_child(heart_root)
	var heart_model: Node3D = HEART.instantiate()
	heart_root.add_child(heart_model)
	_wet_tissue(heart_model)
	lungs_node = place_model(LUNGS, LUNGS_POS, 2.7, Vector3(0, 8, 0))
	body_node = place_model(BODY, BODY_POS, 0.6, Vector3.ZERO)
	_setup_oxygen_visuals()
	_register_pickables()
	_build_ports()
	_build_slots()
	_tubes = Node3D.new()
	world.add_child(_tubes)
	_build_flow_particles()
	_build_equipment()
	_rebuild_tubes()


func _pbr(id: String, scale: float, tint: Color) -> StandardMaterial3D:
	var base := "res://assets/materials/%s/%s_2K-JPG_" % [id, id]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(base + "Color.jpg")
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load(base + "NormalGL.jpg")
	material.roughness_texture = load(base + "Roughness.jpg")
	material.roughness = 1.0
	material.metallic_texture = load(base + "Metalness.jpg")
	material.metallic = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * scale
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _cylinder(radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	node.mesh = mesh
	node.material_override = material
	node.position = position
	world.add_child(node)
	return node


func _ring(radius: float, thickness: float, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.outer_radius = radius + thickness
	mesh.inner_radius = radius
	mesh.rings = 64
	mesh.ring_segments = 8
	node.mesh = mesh
	node.material_override = material
	node.position = position
	world.add_child(node)
	return node


func _build_equipment() -> void:
	## Fiziksel düzenek: kaideler, bağlantı kolyeleri ve canlı dalga monitörü.
	_metal = _pbr("Metal009", 0.4, Color(0.55, 0.58, 0.62))
	var dark := _pbr("Metal009", 0.4, Color(0.22, 0.24, 0.27))
	var glow := _glow_material(Color("#3fd9c0"), 1.6)
	var floor_y := -0.9
	_cylinder(2.7, 0.06, Vector3(0, floor_y + 0.03, 0), dark)
	_ring(2.7, 0.012, Vector3(0, floor_y + 0.065, 0), glow)
	# Kalp kaidesi: üst yüzey kalbin altında (kalp tabanı -0.585)
	_cylinder(0.7, 0.26, Vector3(0, -0.74, 0), _metal)
	_cylinder(0.56, 0.04, Vector3(0, -0.61, 0), dark)
	_ring(0.56, 0.008, Vector3(0, -0.59, 0), glow)
	# Akciğer ve vücut kaideleri
	_cylinder(0.48, 0.22, Vector3(LUNGS_POS.x, -0.73, LUNGS_POS.z), _metal)
	_ring(0.48, 0.007, Vector3(LUNGS_POS.x, -0.62, LUNGS_POS.z), glow)
	_cylinder(0.44, 0.2, Vector3(BODY_POS.x, -0.74, BODY_POS.z), _metal)
	_ring(0.44, 0.007, Vector3(BODY_POS.x, -0.64, BODY_POS.z), glow)
	# Arka panel: monitör
	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(2.7, 0.9, 0.06)
	panel.mesh = panel_mesh
	panel.material_override = dark
	panel.position = Vector3(0.0, 1.35, -1.6)
	world.add_child(panel)
	_waveform = Waveform.new()
	_waveform.size = Vector2(1280, 390)
	_wave_ids = [
		_waveform.add_channel("EKG", Color("#6fe3c1"), -0.4, 1.1),
		_waveform.add_channel("Sol karıncık basıncı", Color("#f2a65a"), 0.0, 130.0),
		_waveform.add_channel("Aort basıncı", Color("#ff6b5e"), 0.0, 130.0),
	]
	var monitor_viewport := SubViewport.new()
	monitor_viewport.size = Vector2i(1280, 390)
	monitor_viewport.transparent_bg = false
	monitor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	monitor_viewport.add_child(_waveform)
	add_child(monitor_viewport)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.56, 0.78)
	screen.mesh = quad
	var screen_material := StandardMaterial3D.new()
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_material.albedo_texture = monitor_viewport.get_texture()
	screen_material.emission_enabled = true
	screen_material.emission_texture = monitor_viewport.get_texture()
	screen_material.emission_energy_multiplier = 1.1
	screen.material_override = screen_material
	screen.position = Vector3(0.0, 1.35, -1.565)
	world.add_child(screen)


func _wave_step(delta: float) -> void:
	if _waveform == null:
		return
	_wave_clock += delta
	if not running:
		for index in _wave_ids:
			_waveform.push(index, _wave_clock, 0.0)
		return
	var t := cycle_t
	# Döngü evreleri: dolum 0–0.385, basınç yükselişi –0.538, atım –0.846, basınç düşüşü –1.
	var ecg := 0.12 * exp(-pow((t - 0.24) / 0.035, 2.0)) - 0.12 * exp(-pow((t - 0.365) / 0.010, 2.0)) \
		+ 1.0 * exp(-pow((t - 0.385) / 0.012, 2.0)) - 0.2 * exp(-pow((t - 0.41) / 0.013, 2.0)) \
		+ 0.26 * exp(-pow((t - 0.72) / 0.07, 2.0))
	var ventricle := 6.0
	if t >= 0.385 and t < 0.9:
		var u := (t - 0.385) / 0.515
		ventricle = 6.0 + 104.0 * pow(sin(u * PI), 0.8)
	var diastolic := 80.0 - 38.0 * backflow
	var aorta := diastolic
	if t >= 0.538 and t < 0.846:
		var u := (t - 0.538) / 0.308
		aorta = diastolic + (112.0 - diastolic) * sin(u * PI * 0.5 + 0.0) * (1.0 - 0.12 * u)
	elif t >= 0.846:
		aorta = lerpf(104.0, diastolic + 6.0, clampf((t - 0.846) / 0.154, 0.0, 1.0))
	else:
		aorta = lerpf(diastolic + 6.0, diastolic, clampf(t / 0.538, 0.0, 1.0))
	_waveform.push(_wave_ids[0], _wave_clock, ecg)
	_waveform.push(_wave_ids[1], _wave_clock, ventricle)
	_waveform.push(_wave_ids[2], _wave_clock, aorta)


func _wet_tissue(model: Node) -> void:
	## Yaş doku görünümü: parlak yansıma, cilalı katman, hafif ışık saçılımı.
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			var source := mesh_instance.mesh.surface_get_material(0)
			if source is StandardMaterial3D:
				var material := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
				material.roughness = 0.6
				material.clearcoat_enabled = true
				material.clearcoat = 0.3
				material.clearcoat_roughness = 0.3
				material.rim_enabled = true
				material.rim = 0.35
				material.rim_tint = 0.4
				material.subsurf_scatter_enabled = true
				material.subsurf_scatter_strength = 0.35
				mesh_instance.material_override = material


func _register_pickables() -> void:
	for id in SPOT_POS:
		add_pickable(id, func() -> Vector3: return heart_root.to_global(SPOT_POS[id]), 0.1)
	add_pickable(&"lungs", func() -> Vector3: return lungs_node.global_position, 0.3)
	add_pickable(&"body", func() -> Vector3: return body_node.global_position, 0.4)
	for slot in VALVE_POS:
		add_pickable(StringName("valve_%d" % slot), func() -> Vector3: return heart_root.to_global(VALVE_POS[slot]), 0.07)


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
	_oxygen_bar.position = BODY_POS + Vector3(0, 0.66, 0.1)
	world.add_child(_oxygen_bar)
	_oxygen_label = make_label("Doku oksijeni", INK, 13)
	_oxygen_label.position = BODY_POS + Vector3(0, 0.74, 0.1)
	world.add_child(_oxygen_label)


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
		world.add_child(marker)
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
		_flow_meshes[key] = Util.make_particles(heart_root, 0.00055, 24)


# --- Her kare -----------------------------------------------------------

func _update(delta: float) -> void:
	for valve in valve_amount:
		valve_amount[valve] = move_toward(valve_amount[valve], valve_target[valve], delta * 5.0)
	var s := 1.0 + 0.02 * beat
	heart_root.scale = Vector3.ONE * S * s
	heart_root.position = -HEART_CENTER * S * s
	_update_slots_and_valves()
	_update_ports()
	_update_flows()
	_update_oxygen()
	_sync_tubes()
	_wave_step(delta)


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
		var direction: float = flow_dir.get(key, 0.0) if show_flow else 0.0
		var color: Color = flow_color_override.get(key, BLOOD_RICH if key in FLOW_RICH else BLOOD_POOR)
		Util.flow_particles(_flow_meshes[key], FLOWS[key], color, _time, flow_speed, direction)


func _update_oxygen() -> void:
	var o := clampf(body_oxygen, 0.0, 1.0)
	_oxygen_overlay.albedo_color = Color(0.2, 0.3, 0.9, (1.0 - o) * 0.45)
	var bar_mesh := _oxygen_bar.mesh as BoxMesh
	bar_mesh.size = Vector3(maxf(0.5 * o, 0.002), 0.025, 0.025)
	_oxygen_bar.position.x = BODY_POS.x - 0.25 + 0.25 * o
	(_oxygen_bar.material_override as StandardMaterial3D).albedo_color = (JADE if o > 0.66 else (GOLD if o > 0.33 else RED)) * 0.85
	_oxygen_label.text = "Doku oksijeni  %d%%" % roundi(o * 100.0)


func _floor_height() -> float:
	return -0.9


const LABEL_OFFSET := {
	&"svc": Vector3(-0.55, 0.28, 0.25), &"right_atrium": Vector3(-0.62, 0.12, 0.3), &"right_ventricle": Vector3(-0.62, -0.1, 0.3),
	&"pulmonary_artery": Vector3(0.45, 0.32, 0.25), &"pulmonary_veins": Vector3(0.62, 0.05, 0.25), &"left_atrium": Vector3(0.66, 0.2, 0.3),
	&"left_ventricle": Vector3(0.66, -0.12, 0.3), &"aorta": Vector3(-0.15, 0.4, 0.25),
}


func label_world(id: Variant) -> Vector3:
	if id is StringName and SPOT_POS.has(id):
		return heart_root.to_global(SPOT_POS[id]) + LABEL_OFFSET.get(id, Vector3(0, 0.15, 0.2))
	if id is int and VALVE_POS.has(id):
		var side := {Model.Valve.TRICUSPID: Vector3(-0.5, 0.0, 0.25), Model.Valve.MITRAL: Vector3(0.55, 0.0, 0.25),
			Model.Valve.AORTIC: Vector3(-0.35, 0.38, 0.25), Model.Valve.PULMONARY: Vector3(0.32, 0.4, 0.25)}
		return heart_root.to_global(VALVE_POS[id]) + side[id]
	return Vector3.ZERO


# --- Damar hortumları ---------------------------------------------------

func _tube_curve(from_port: StringName, to_port: StringName) -> PackedVector3Array:
	var p0: Vector3 = PORT_WORLD[from_port]
	var p1: Vector3 = PORT_WORLD[to_port]
	var reach := clampf(p0.distance_to(p1) * 0.45, 0.2, 1.0)
	var c0 := p0 + (PORT_OUT_DIR[from_port] as Vector3).normalized() * reach
	var c1 := p1 + (PORT_OUT_DIR[to_port] as Vector3).normalized() * reach
	return Util.bezier(p0, c0, c1, p1)


func _sync_tubes() -> void:
	var signature := "%s|%s" % [str(connections), str(port_warning)]
	if signature != _tube_signature:
		_rebuild_tubes()
	for from_port in connections:
		if not _link_particles.has(from_port):
			continue
		var data: Dictionary = _link_particles[from_port]
		var warn: bool = port_warning.get(from_port, false)
		var rich: bool = PORT_RICH[from_port]
		var color := GOLD if warn else (BLOOD_RICH if rich else BLOOD_POOR)
		var active := connection_flow and show_flow
		Util.flow_particles(data["holder"], Array(data["points"]), color, _time, flow_speed * 0.9, 1.0 if active else 0.0)
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
		_tubes.add_child(Util.tube_mesh(points, color, 0.022))
		_add_collar(points[0], points[1] - points[0])
		_add_collar(points[points.size() - 1], points[points.size() - 1] - points[points.size() - 2])
		var holder := Util.make_particles(_tubes, 0.012, 26)
		_link_particles[from_port] = {"holder": holder, "points": points}


func _add_collar(position: Vector3, direction: Vector3) -> void:
	## Hortum ucundaki metal konnektör kolyesi ve kauçuk halka.
	var tangent := direction.normalized()
	var collar := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.034
	mesh.bottom_radius = 0.034
	mesh.height = 0.07
	collar.mesh = mesh
	collar.material_override = _metal
	collar.position = position
	collar.quaternion = Quaternion(Vector3.UP, tangent)
	_tubes.add_child(collar)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.outer_radius = 0.04
	ring_mesh.inner_radius = 0.031
	ring.mesh = ring_mesh
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("#14181d")
	rubber.roughness = 0.7
	ring.material_override = rubber
	ring.position = position + tangent * 0.03
	ring.quaternion = Quaternion(Vector3.UP, tangent)
	_tubes.add_child(ring)


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
	_drag_tube = Util.tube_mesh(points, GOLD, 0.02)
	_tubes.add_child(_drag_tube)


# --- Girdi ---------------------------------------------------------------

func on_press(position: Vector2, _double: bool) -> bool:
	if not ports_active:
		return false
	var best: Variant = null
	var best_distance := INF
	var r: Array = ray(position)
	for id in OUT_PORTS:
		var to_center: Vector3 = (PORT_WORLD[id] as Vector3) - (r[0] as Vector3)
		var along := to_center.dot(r[1])
		if along <= 0.0:
			continue
		var miss := (to_center - (r[1] as Vector3) * along).length()
		if miss <= 0.09 and along < best_distance:
			best_distance = along
			best = id
	if best == null:
		return false
	if connections.has(best):
		connections.erase(best)
		port_cleared.emit(best)
	_drag_from = best
	_drag_world = PORT_WORLD[best]
	return true


func on_motion(position: Vector2) -> bool:
	if _drag_from == &"":
		return false
	_drag_world = world_on_ray(position, PORT_WORLD[_drag_from])
	return true


func on_release(position: Vector2) -> bool:
	if _drag_from == &"":
		return false
	var source := _drag_from
	_drag_from = &""
	if _drag_tube != null:
		_drag_tube.queue_free()
		_drag_tube = null
	var r: Array = ray(position)
	var best: Variant = null
	var best_distance := INF
	for id in IN_PORTS:
		var to_center: Vector3 = (PORT_WORLD[id] as Vector3) - (r[0] as Vector3)
		var along := to_center.dot(r[1])
		if along <= 0.0:
			continue
		var miss := (to_center - (r[1] as Vector3) * along).length()
		if miss <= 0.11 and along < best_distance:
			best_distance = along
			best = id
	if best != null:
		ports_connected.emit(source, best)
	return true


func on_click(position: Vector2) -> void:
	var hit: Variant = pick(position)
	if hit == null:
		return
	var text := String(hit)
	if text.begins_with("valve_") and Input.is_key_pressed(KEY_SHIFT):
		spot_pressed.emit(StringName("valve_remove_" + text.trim_prefix("valve_")))
		return
	spot_pressed.emit(hit)


func _nearest_slot(position: Vector2) -> int:
	var hit: Variant = pick(position, false, 1.7, func(id: Variant) -> bool: return String(id).begins_with("valve_"))
	if hit == null:
		return -1
	return int(String(hit).trim_prefix("valve_"))


func can_drop(position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("valve") and _nearest_slot(position) >= 0


func drop(position: Vector2, data: Variant) -> void:
	var slot := _nearest_slot(position)
	if slot >= 0:
		valve_dropped.emit(slot, data["valve"])


func set_valves_for_phase(phase: int) -> void:
	for valve in Model.VALVE_NAMES:
		valve_target[valve] = 1.0 if Model.is_open(valve, phase) else 0.0
