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
const Circ = preload("res://scripts/physio/circulation.gd")
const PerfusionStage = preload("res://stations/heart/perfusion_stage.gd")
const HEART = preload("res://stations/heart/assets/model/heart_cutaway.glb")
const LUNGS = preload("res://assets/models/human-lungs.glb")
const BODY = preload("res://assets/models/human-muscles.glb")

const BLOOD_RICH := Color("#ff4a3d")
const BLOOD_POOR := Color("#6d2c3d")
const SAGE := Color("#a5ad84")
const AMBER := Color("#d4a15f")

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
## Akış hattı → motorda ona karşılık gelen bağ ve kanın geldiği odacık (oksijen rengi için).
const FLOW_LINK := {
	&"ven_in": Circ.CAVAL, &"r_av": Circ.TRICUSPID, &"r_out": Circ.PULMONARY,
	&"l_in": Circ.PULM_VEIN, &"l_av": Circ.MITRAL, &"l_out": Circ.AORTIC,
}
const FLOW_NODE := {
	&"ven_in": Circ.VC, &"r_av": Circ.RA, &"r_out": Circ.RV,
	&"l_in": Circ.PV, &"l_av": Circ.LA, &"l_out": Circ.LV,
}
## Dış hortum → motor bağı.
const PORT_LINK := {&"body_out": Circ.CAVAL, &"pa_out": Circ.LUNGS, &"lungs_out": Circ.PULM_VEIN, &"aorta_out": Circ.BODY}
const PORT_NODE := {&"body_out": Circ.VC, &"pa_out": Circ.PA, &"lungs_out": Circ.PV, &"aorta_out": Circ.AO}
## Kelepçe konumları: damar → ölçülmüş nokta, yarıçap.
const CLAMP_SPOT := {
	Circ.CAVAL: [&"svc", 0.0070], Circ.LUNGS: [&"pulmonary_artery", 0.0058],
	Circ.PULM_VEIN: [&"pulmonary_veins", 0.0070], Circ.BODY: [&"aorta", 0.0060],
}
## 1 mL/s debinin yol üzerinde ilerletmesi (yol uzunluğu / s). 150 mL/s ≈ 0,5 yol/s.
const FLOW_PHASE_RATE := 0.0033
const FLOW_FULL := 40.0
## Odacık kan hacmi: motor düğümü, ölçülmüş nokta, boş ve dolu yarıçap (model birimi).
const CHAMBER_BLOOD := {
	&"right_atrium": [Circ.RA, 0.0075, 0.0125], &"right_ventricle": [Circ.RV, 0.0085, 0.0145],
	&"left_atrium": [Circ.LA, 0.0070, 0.0115], &"left_ventricle": [Circ.LV, 0.0090, 0.0150],
}
const BLOOD_SHADER = preload("res://scripts/anatomy/blood_tube.gdshader")

## Dış damar uçları. Kalp uçları dünya koordinatında (model × ölçek + kaydırma).
const LUNGS_POS := Vector3(1.12, -0.215, 0.05)
const BODY_POS := Vector3(-1.2, -0.10, 0.0)
var PORT_WORLD := {
	&"svc_in": Vector3(-0.0210, 0.1190, 0.0140) * S + HEART_SHIFT,
	&"aorta_out": Vector3(0.0023, 0.1305, 0.0145) * S + HEART_SHIFT,
	&"pa_out": Vector3(0.0390, 0.0985, 0.0180) * S + HEART_SHIFT,
	&"pv_in": Vector3(0.0450, 0.0878, 0.0095) * S + HEART_SHIFT,
	&"lungs_in": Vector3.ZERO,
	&"lungs_out": Vector3.ZERO,
	&"body_out": Vector3.ZERO,
	&"body_in": Vector3.ZERO,
}
## Hortumun porttan çıkış yönü.
const PORT_OUT_DIR := {
	&"svc_in": Vector3(0, 1, 0), &"aorta_out": Vector3(0, 1, 0), &"pa_out": Vector3(1, 0.2, 0),
	&"pv_in": Vector3(1, 0, 0), &"lungs_in": Vector3(-1, 0, 0.12), &"lungs_out": Vector3(-1, 0, 0.12),
	&"body_out": Vector3(1, 0.08, 0.12), &"body_in": Vector3(1, 0.08, 0.12),
}
const OUT_PORTS := Network.OUT_PORTS
const IN_PORTS := Network.IN_PORTS
const CORRECT_LINKS := Network.CORRECT_LINKS
const PORT_NAMES := {
	&"body_out": "Vücuttan dönen kan", &"pa_out": "Akciğer atardamarı", &"lungs_out": "Akciğerden çıkan kan", &"aorta_out": "Aort",
	&"svc_in": "Ana toplardamar → sağ kulakçık", &"lungs_in": "Akciğere giriş", &"pv_in": "Akciğer toplardamarı → sol kulakçık", &"body_in": "Vücuda giriş",
}
const PORT_RICH := {&"body_out": false, &"pa_out": false, &"lungs_out": true, &"aorta_out": true}

## Hedef halkaları, port işaretleri ve uyarılar 3B görünümün üstünde çizilir (üst Control'ün _draw'ı kabın altında kalır).
class Overlay extends Control:
	var stage

	func _draw() -> void:
		if stage != null:
			stage._paint(self)

var _overlay: Overlay
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
## Kapak arızası sonucu: kan biriken odacıklar (spot kimliği → true) ve sonucun pompa durduktan sonra görünür kalma süresi.
var pooled: Dictionary = {}
var consequence_hold := 0.0
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
## Fizyoloji motoru. Verilirse akış, kapaklar, odacık şişmesi ve monitör ondan okunur.
var circ: Circ = null
var sim_active := false
var clamp_amount: Dictionary = {}
var _flow_phase: Dictionary = {}
var _clamps: Dictionary = {}
var _chamber_blood: Dictionary = {}


func _build() -> void:
	_overlay = Overlay.new()
	_overlay.stage = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tune_heart_palette()
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
	_apply_lung_tissue_material(lungs_node)
	body_node = place_model(BODY, BODY_POS, 0.6, Vector3.ZERO)
	_position_organ_ports()
	_setup_oxygen_visuals()
	_register_pickables()
	_build_ports()
	_build_slots()
	_tubes = Node3D.new()
	world.add_child(_tubes)
	_build_flow_particles()
	_build_equipment()
	_build_clamps()
	_build_chamber_blood()
	_rebuild_tubes()


func _tune_heart_palette() -> void:
	## AnatomyView is shared; this station uses graphite, warm neutrals and sage.
	var environment_node := world.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if environment_node != null and environment_node.environment != null:
		var environment := environment_node.environment.duplicate() as Environment
		environment.background_color = Color("#10110f")
		environment.ambient_light_color = Color("#c5bda9")
		environment.ambient_light_energy = 0.75
		environment.volumetric_fog_albedo = Color("#46443b")
		environment.volumetric_fog_emission = Color("#10110f")
		if environment.sky != null and environment.sky.sky_material is ProceduralSkyMaterial:
			var sky_material := (environment.sky.sky_material as ProceduralSkyMaterial).duplicate() as ProceduralSkyMaterial
			sky_material.sky_top_color = Color("#10110f")
			sky_material.sky_horizon_color = Color("#282923")
			sky_material.ground_horizon_color = Color("#1d1e19")
			sky_material.ground_bottom_color = Color("#10110f")
			var sky := environment.sky.duplicate() as Sky
			sky.sky_material = sky_material
			environment.sky = sky
		environment_node.environment = environment
	if _floor_material != null:
		_floor_material.albedo_color = Color("#191a17")
	var stack: Array[Node] = world.get_children()
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is DirectionalLight3D:
			var light := node as DirectionalLight3D
			if light.light_color.b > light.light_color.r * 1.15:
				light.light_color = Color("#c7bda7")
		elif node is MeshInstance3D and (node as MeshInstance3D).mesh is QuadMesh:
			var surface := (node as MeshInstance3D).material_override as StandardMaterial3D
			if surface != null and surface.albedo_color.b > surface.albedo_color.r * 1.15:
				surface.albedo_color = Color("#c7bda7")
				if surface.emission_enabled:
					surface.emission = Color("#c7bda7")


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
	var glow := _glow_material(SAGE, 1.25)
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
		_waveform.add_channel("EKG", SAGE, -0.4, 1.1),
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
	# Give the waveform a readable instrument housing and physical control details.
	var bezel := MeshInstance3D.new()
	var bezel_mesh := BoxMesh.new()
	bezel_mesh.size = Vector3(2.78, 0.96, 0.12)
	bezel.mesh = bezel_mesh
	bezel.material_override = dark
	bezel.position = Vector3(0.0, 1.35, -1.64)
	world.add_child(bezel)
	# Keep the screen surface in front of its case.
	screen.position.z = -1.565
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color("#6fe3c1")
	trim.metallic = 0.42
	trim.roughness = 0.28
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.025, 0.84, 0.02)
		rail.mesh = rail_mesh
		rail.material_override = trim
		rail.position = Vector3(side * 1.38, 1.35, -1.56)
		world.add_child(rail)
	for index in 4:
		var led := MeshInstance3D.new()
		var led_mesh := SphereMesh.new()
		led_mesh.radius = 0.018
		led_mesh.height = 0.036
		led.mesh = led_mesh
		var led_material := _glow_material(Color("#6fe3c1") if index < 3 else Color("#f2a65a"), 1.4)
		led.material_override = led_material
		led.position = Vector3(-0.95 + index * 0.12, 1.84, -1.55)
		world.add_child(led)
	# A dedicated gantry frames the specimen and makes the circulation workbench read as one instrument.
	var perfusion_stage := PerfusionStage.new()
	world.add_child(perfusion_stage)


func _wave_step(delta: float) -> void:
	if _waveform == null:
		return
	_wave_clock += delta
	if not running and circ == null:
		for index in _wave_ids:
			_waveform.push(index, _wave_clock, 0.0)
		return
	if circ != null:
		var u := circ.cycle_time / circ.period()
		var ecg_sim := 0.12 * exp(-pow((u - 0.02) / 0.04, 2.0)) + 1.0 * exp(-pow((u - 0.17) / 0.012, 2.0)) \
			- 0.2 * exp(-pow((u - 0.19) / 0.013, 2.0)) + 0.26 * exp(-pow((u - 0.42) / 0.06, 2.0))
		_waveform.push(_wave_ids[0], _wave_clock, ecg_sim)
		_waveform.push(_wave_ids[1], _wave_clock, circ.pressure(Circ.LV))
		_waveform.push(_wave_ids[2], _wave_clock, circ.pressure(Circ.AO))
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


func _apply_lung_tissue_material(model: Node) -> void:
	## Its packed color atlas maps as vivid patches in this scene; use a nonmetallic tissue surface.
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.mesh.surface_get_material(surface)
				if source is StandardMaterial3D:
					var tissue := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
					tissue.albedo_texture = null
					tissue.albedo_color = Color("#a55e61")
					tissue.metallic = 0.0
					tissue.metallic_texture = null
					tissue.roughness = 0.72
					tissue.roughness_texture = null
					tissue.clearcoat_enabled = true
					tissue.clearcoat = 0.08
					tissue.clearcoat_roughness = 0.35
					tissue.subsurf_scatter_enabled = true
					tissue.subsurf_scatter_strength = 0.22
					mesh_instance.set_surface_override_material(surface, tissue)


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
	bar_material.albedo_color = SAGE
	_oxygen_bar.material_override = bar_material
	_oxygen_bar.position = BODY_POS + Vector3(0, -0.62, 0.28)
	world.add_child(_oxygen_bar)
	_oxygen_label = make_label("Doku oksijeni", INK, 13)
	_oxygen_label.position = BODY_POS + Vector3(0, -0.45, 0.28)
	world.add_child(_oxygen_label)


# --- Portlar, yuvalar --------------------------------------------------

func _build_ports() -> void:
	for id in PORT_WORLD:
		var marker := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.018
		mesh.height = 0.036
		marker.mesh = mesh
		var material := StandardMaterial3D.new()
		var out := OUT_PORTS.has(id)
		var rich: bool = PORT_RICH.get(id, false)
		material.albedo_color = (BLOOD_RICH if rich else BLOOD_POOR) if out else SAGE
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
		# Kapakçıklar tek parça kalp modelinin dış yüzünde kalıp gömülmesin.
		prosthesis.position = VALVE_POS[slot] + Vector3(0.0, 0.0, 0.0025)
		prosthesis.quaternion = orientation
		_prostheses[slot] = prosthesis


func _build_flow_particles() -> void:
	for key in FLOWS:
		_flow_meshes[key] = Util.make_particles(heart_root, 0.0007, 40)


# --- Her kare -----------------------------------------------------------

func _update(delta: float) -> void:
	consequence_hold = maxf(consequence_hold - delta, 0.0)
	for valve in valve_amount:
		valve_amount[valve] = move_toward(valve_amount[valve], valve_target[valve], delta * 5.0)
	var s := 1.0 + 0.02 * beat
	heart_root.scale = Vector3.ONE * S * s
	heart_root.position = -HEART_CENTER * S * s
	_update_slots_and_valves()
	_update_ports()
	_update_flows()
	_update_clamps()
	_update_chamber_blood()
	_update_oxygen()
	_sync_tubes()
	_wave_step(delta)
	if _overlay != null:
		_overlay.queue_redraw()


func _paint(canvas: Control) -> void:
	## Keep active hit targets legible over the detailed 3D model.
	if rig == null or rig.camera == null:
		return
	var camera := rig.camera
	for id in pickables:
		if not active_pickables.get(id, false):
			continue
		var point: Vector3 = pickable_position(id)
		if camera.is_position_behind(point):
			continue
		var screen := camera.unproject_position(point)
		if not Rect2(Vector2.ZERO, canvas.size).has_point(screen):
			continue
		var is_target: bool = id == highlight_id
		var color := AMBER if is_target else SAGE
		var pulse := 1.0 + 0.08 * sin(_time * 4.0)
		var radius := (23.0 if is_target else 15.0) * pulse
		var is_valve := String(id).begins_with("valve_")
		# Açık ve ayrıntılı model üstünde kaybolmaması için koyu zemin, beyaz ayraç ve renkli halo.
		# Şekil de anlam taşır: kapak yuvaları kare, odacık ve damar bölgeleri daire.
		if is_valve:
			var half := maxf(radius * 0.62, 12.0)
			canvas.draw_rect(Rect2(screen - Vector2.ONE * (half + 5.0), Vector2.ONE * (half + 5.0) * 2.0), Color("#ffffff", 0.88))
			canvas.draw_rect(Rect2(screen - Vector2.ONE * half, Vector2.ONE * half * 2.0), Color("#191a17", 0.92))
			canvas.draw_rect(Rect2(screen - Vector2.ONE * half, Vector2.ONE * half * 2.0), color, false, 4.0 if is_target else 3.0)
			canvas.draw_line(screen - Vector2(half * 0.55, 0.0), screen + Vector2(half * 0.55, 0.0), color, 3.0)
			canvas.draw_colored_polygon(PackedVector2Array([screen + Vector2(half * 0.55, 0.0), screen + Vector2(half * 0.15, -half * 0.3), screen + Vector2(half * 0.15, half * 0.3)]), color)
		else:
			canvas.draw_circle(screen, radius + 3.0, Color("#ffffff", 0.85))
			canvas.draw_circle(screen, radius, Color("#191a17", 0.92))
			canvas.draw_circle(screen, radius - 5.0, Color(color, 0.28))
			canvas.draw_arc(screen, radius - 1.5, 0.0, TAU, 48, color, 3.5 if is_target else 2.5, true)
			canvas.draw_circle(screen, 4.0 if is_target else 3.0, color)
	_draw_pooled_warnings(canvas, camera)
	_draw_port_targets(canvas, camera)


func _draw_pooled_warnings(canvas: Control, camera: Camera3D) -> void:
	var font := canvas.get_theme_default_font()
	for spot in pooled:
		if not pooled[spot] or not SPOT_POS.has(spot):
			continue
		var point: Vector3 = heart_root.to_global(SPOT_POS[spot])
		if camera.is_position_behind(point):
			continue
		var screen := camera.unproject_position(point)
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		var radius := 34.0 + 6.0 * pulse
		canvas.draw_arc(screen, radius, 0.0, TAU, 40, Color(RED, 0.55 + 0.4 * pulse), 4.0, true)
		canvas.draw_arc(screen, radius + 8.0, -0.6, 0.6, 12, Color(RED, 0.8), 3.0, true)
		var text := "Kan birikti"
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		# Sağ odacıklar ekranın solundadır: etiket odacığın dış yanına konur, kapak işaretlerine binmez.
		var outward := -1.0 if spot in [&"right_atrium", &"right_ventricle"] else 1.0
		var box_x := screen.x - radius - width - 28.0 if outward < 0.0 else screen.x + radius + 8.0
		var box := Rect2(Vector2(box_x, screen.y - 12.0), Vector2(width + 16.0, 24.0))
		canvas.draw_rect(box, Color("#191a17", 0.92))
		canvas.draw_rect(box, RED, false, 2.0)
		canvas.draw_string(font, box.position + Vector2(8.0, 17.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f1ede3"))


## Damar uçları: çıkışlar baklava, girişler çerçeve + nokta. Şekil, yönü renkten bağımsız anlatır.
func _draw_port_targets(canvas: Control, camera: Camera3D) -> void:
	if not ports_active:
		return
	var pulse := 1.0 + 0.1 * sin(_time * 4.0)
	for id in _port_markers:
		var marker: MeshInstance3D = _port_markers[id]
		var point := marker.global_position
		if camera.is_position_behind(point):
			continue
		var screen := camera.unproject_position(point)
		var taken: bool = connections.values().has(id) or connections.has(id)
		var warned: bool = port_warning.get(id, false)
		var color: Color = AMBER if warned else (SAGE if taken else Color("#f1ede3"))
		var r := (9.0 if taken else 13.0) * pulse
		if OUT_PORTS.has(id):
			var diamond := PackedVector2Array([screen + Vector2(0, -r), screen + Vector2(r, 0), screen + Vector2(0, r), screen + Vector2(-r, 0)])
			canvas.draw_colored_polygon(diamond, Color("#191a17", 0.9))
			diamond.append(diamond[0])
			canvas.draw_polyline(diamond, color, 3.0, true)
		else:
			canvas.draw_rect(Rect2(screen - Vector2.ONE * r, Vector2.ONE * r * 2.0), Color("#191a17", 0.9))
			canvas.draw_rect(Rect2(screen - Vector2.ONE * r, Vector2.ONE * r * 2.0), color, false, 3.0)
			canvas.draw_circle(screen, 3.5, color)


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
			var warned: bool = port_warning.get(id, false)
			for source in port_warning:
				if connections.get(source) == id:
					warned = true
					break
			var material := marker.material_override as StandardMaterial3D
			if material != null:
				var color: Color = AMBER if warned else (BLOOD_RICH if PORT_RICH.get(id, false) else BLOOD_POOR if OUT_PORTS.has(id) else SAGE)
				material.albedo_color = color
				material.emission = color


func _blood_color(o2: float) -> Color:
	return BLOOD_POOR.lerp(BLOOD_RICH, clampf((o2 - 0.62) / 0.34, 0.0, 1.0))


func _update_flows() -> void:
	if circ != null:
		_update_sim_flows()
		return
	for key in _flow_meshes:
		var direction: float = flow_dir.get(key, 0.0) if show_flow else 0.0
		var color: Color = flow_color_override.get(key, BLOOD_RICH if key in FLOW_RICH else BLOOD_POOR)
		Util.flow_particles(_flow_meshes[key], FLOWS[key], color, _time, flow_speed, direction)


func _update_sim_flows() -> void:
	var delta := get_process_delta_time()
	var live := sim_active and show_flow
	for key in _flow_meshes:
		var q: float = circ.flow(FLOW_LINK[key]) if live else 0.0
		var link: Circ.Net.Conduit = circ.link(FLOW_LINK[key])
		# Ters takılı kapakta yol yönü, kanın fiziksel yönüne göredir.
		var color := _blood_color(circ.oxygen(FLOW_NODE[key]))
		var backwards := q < -4.0 and not link.reversed or q > 4.0 and link.reversed
		if backwards:
			color = AMBER
		_flow_phase[key] = fposmod(_flow_phase.get(key, 0.0) + q * delta * FLOW_PHASE_RATE, 1.0)
		Util.flow_dots(_flow_meshes[key], FLOWS[key], color, _flow_phase[key], absf(q) / FLOW_FULL)


func _build_chamber_blood() -> void:
	for spot in CHAMBER_BLOOD:
		var node := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		mesh.radial_segments = 56
		mesh.rings = 28
		node.mesh = mesh
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(BLOOD_POOR, 0.72)
		material.roughness = 0.22
		material.clearcoat_enabled = true
		material.clearcoat = 0.4
		material.clearcoat_roughness = 0.18
		material.subsurf_scatter_enabled = true
		material.subsurf_scatter_strength = 0.18
		node.material_override = material
		node.position = SPOT_POS[spot]
		node.visible = false
		heart_root.add_child(node)
		_chamber_blood[spot] = node


func _update_chamber_blood() -> void:
	for spot in _chamber_blood:
		var node: MeshInstance3D = _chamber_blood[spot]
		node.visible = circ != null and (sim_active or consequence_hold > 0.0 or pooled.has(spot))
		if not node.visible:
			continue
		var data: Array = CHAMBER_BLOOD[spot]
		var fill := circ.fullness(data[0])
		var scale_amount := lerpf(data[1], data[2], fill)
		if pooled.get(spot, false):
			# Biriken kan: odacık şişer ve nabız gibi atar.
			scale_amount = data[2] * (1.12 + 0.05 * sin(_time * 5.0))
		node.scale = Vector3.ONE * scale_amount
		var color := _blood_color(circ.oxygen(data[0]))
		var material := node.material_override as StandardMaterial3D
		material.albedo_color = Color(color, 0.72)
		material.emission = color


func _build_clamps() -> void:
	var steel := _pbr("Metal009", 0.4, Color(0.7, 0.72, 0.76))
	for vessel in CLAMP_SPOT:
		var radius: float = CLAMP_SPOT[vessel][1]
		var holder := Node3D.new()
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.outer_radius = radius * 1.7
		mesh.inner_radius = radius * 1.15
		ring.mesh = mesh
		ring.material_override = steel
		holder.add_child(ring)
		for side in [-1.0, 1.0]:
			var jaw := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(radius * 0.5, radius * 3.6, radius * 1.0)
			jaw.mesh = box
			jaw.material_override = steel
			jaw.position = Vector3(side * radius * 1.45, 0.0, 0.0)
			holder.add_child(jaw)
		holder.position = SPOT_POS[CLAMP_SPOT[vessel][0]]
		holder.visible = false
		heart_root.add_child(holder)
		_clamps[vessel] = holder


func _update_clamps() -> void:
	for vessel in _clamps:
		var amount: float = clamp_amount.get(vessel, 0.0)
		var holder: Node3D = _clamps[vessel]
		holder.visible = amount > 0.01
		holder.scale = Vector3.ONE * (1.0 - 0.45 * amount)


func _update_oxygen() -> void:
	var o := clampf(body_oxygen, 0.0, 1.0)
	_oxygen_overlay.albedo_color = Color(0.2, 0.3, 0.9, (1.0 - o) * 0.45)
	var bar_mesh := _oxygen_bar.mesh as BoxMesh
	bar_mesh.size = Vector3(maxf(0.5 * o, 0.002), 0.025, 0.025)
	_oxygen_bar.position.x = BODY_POS.x - 0.25 + 0.25 * o
	(_oxygen_bar.material_override as StandardMaterial3D).albedo_color = (SAGE if o > 0.66 else (AMBER if o > 0.33 else RED)) * 0.85
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

func _position_organ_ports() -> void:
	## Yaklaşık anatomik bölgeleri seç, ardından GLB üçgen yüzeyine tam oturt.
	var body_model := body_node.get_child(0) as Node3D
	var lungs_model := lungs_node.get_child(0) as Node3D
	PORT_WORLD[&"body_out"] = _organ_contact(body_model, Vector3(0.68, 0.84, 0.60))
	PORT_WORLD[&"body_in"] = _organ_contact(body_model, Vector3(0.66, 0.72, 0.79))
	PORT_WORLD[&"lungs_in"] = _organ_contact(lungs_model, Vector3(0.08, 0.57, 0.94))
	PORT_WORLD[&"lungs_out"] = _organ_contact(lungs_model, Vector3(0.08, 0.43, 0.94))


func _organ_contact(model: Node3D, normalized: Vector3) -> Vector3:
	var box := _model_local_bounds(model)
	var query := model.to_global(box.position + box.size * normalized)
	var surface := _nearest_surface(model, query, model.to_global(box.get_center()))
	return surface["point"] + surface["normal"] * 0.002


func _model_local_bounds(model: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var root_inverse := model.global_transform.affine_inverse()
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D:
			var instance := node as MeshInstance3D
			if instance.mesh == null:
				continue
			var to_model := root_inverse * instance.global_transform
			var transformed := instance.get_aabb() * to_model
			bounds = transformed if first else bounds.merge(transformed)
			first = false
	return bounds


func _nearest_surface(model: Node3D, query: Vector3, model_center: Vector3) -> Dictionary:
	var best_distance := INF
	var best_point := query
	var best_normal := Vector3.ZERO
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if not node is MeshInstance3D:
			continue
		var instance := node as MeshInstance3D
		if instance.mesh == null:
			continue
		var faces := instance.mesh.get_faces()
		for i in range(0, faces.size(), 3):
			var a := instance.to_global(faces[i])
			var b := instance.to_global(faces[i + 1])
			var c := instance.to_global(faces[i + 2])
			var point := _closest_point_on_triangle(query, a, b, c)
			var distance := query.distance_squared_to(point)
			if distance >= best_distance:
				continue
			best_distance = distance
			best_point = point
			best_normal = (b - a).cross(c - a).normalized()
	var outward := (best_point - model_center).normalized()
	if outward.is_zero_approx():
		outward = Vector3.FORWARD
	if best_normal.is_zero_approx():
		best_normal = outward
	elif best_normal.dot(outward) < 0.0:
		best_normal = -best_normal
	return {"point": best_point, "normal": best_normal}


func _closest_point_on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and d4 - d3 >= 0.0 and d5 - d6 >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var inverse := 1.0 / (va + vb + vc)
	return a + ab * (vb * inverse) + ac * (vc * inverse)


func _tube_curve(from_port: StringName, to_port: StringName) -> PackedVector3Array:
	var p0: Vector3 = PORT_WORLD[from_port]
	var p1: Vector3 = PORT_WORLD[to_port]
	var reach := clampf(p0.distance_to(p1) * 0.3, 0.12, 0.62)
	var c0 := p0 + (PORT_OUT_DIR[from_port] as Vector3).normalized() * reach
	var c1 := p1 + (PORT_OUT_DIR[to_port] as Vector3).normalized() * reach
	## Torso bağlantılarını ayrı yüksekliklerde dolaştır; aort dönüşü VCS hattını kesmesin.
	if from_port == &"aorta_out":
		c0 += Vector3(-0.04, -0.50, 0.0)
		c1 += Vector3(0.02, -0.10, 0.0)
	elif from_port == &"body_out":
		c0 += Vector3(0.0, 0.12, 0.0)
		c1 += Vector3(0.04, 0.06, 0.0)
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
		if circ != null:
			var q: float = circ.flow(PORT_LINK[from_port]) if (active and sim_active) else 0.0
			color = _blood_color(circ.oxygen(PORT_NODE[from_port]))
			# A wrong hose shows a short, source-colored route preview. The circulation
			# motor still clamps the canonical vessel, so this preview is not counted as flow.
			if warn and active and q <= 0.0:
				q = FLOW_FULL * 0.28
			var phase := fposmod(_flow_phase.get(from_port, 0.0) + q * get_process_delta_time() * FLOW_PHASE_RATE, 1.0)
			_flow_phase[from_port] = phase
			var blood_material: ShaderMaterial = data["material"]
			blood_material.set_shader_parameter("blood_color", color)
			blood_material.set_shader_parameter("phase", phase)
			blood_material.set_shader_parameter("amount", clampf(absf(q) / FLOW_FULL, 0.0, 1.0))
		else:
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
		var blood_material: ShaderMaterial = null
		if circ != null:
			blood_material = ShaderMaterial.new()
			blood_material.shader = BLOOD_SHADER
			blood_material.set_shader_parameter("blood_color", color)
			blood_material.set_shader_parameter("cycles", float(maxi(roundi(Util.path_length(Array(points)) * 14.0), 2)))
		var wall_material: Material = blood_material if blood_material != null else _vessel_wall_material(color)
		const END_SCALE := 0.58
		_tubes.add_child(Util.tube_mesh(points, color, 0.022, wall_material, END_SCALE, END_SCALE))
		_add_vessel_rim(points[0], points[1] - points[0], 0.022 * END_SCALE)
		_add_vessel_rim(points[points.size() - 1], points[points.size() - 2] - points[points.size() - 1], 0.022 * END_SCALE)
		var holder: MultiMeshInstance3D = null if circ != null else Util.make_particles(_tubes, 0.0035, 26)
		_link_particles[from_port] = {"holder": holder, "points": points, "material": blood_material}


func _vessel_wall_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r * 0.72, color.g * 0.58, color.b * 0.68, 0.62)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.34
	material.metallic = 0.0
	material.clearcoat_enabled = true
	material.clearcoat = 0.24
	material.clearcoat_roughness = 0.28
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _add_vessel_rim(position: Vector3, direction: Vector3, radius: float) -> void:
	## Damarın dokuya girdiği yerde dar, dokuyla uyumlu bir sınır.
	var tangent := direction.normalized()
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.outer_radius = radius * 1.12
	ring_mesh.inner_radius = radius * 0.78
	ring.mesh = ring_mesh
	var tissue := StandardMaterial3D.new()
	tissue.albedo_color = Color("#85464d")
	tissue.roughness = 0.42
	tissue.clearcoat_enabled = true
	tissue.clearcoat = 0.16
	ring.material_override = tissue
	ring.position = position + tangent * 0.003
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
	if Input.is_key_pressed(KEY_SHIFT):
		disconnect_port(best)
		_drag_from = &""
		return true
	_drag_from = best
	_drag_world = PORT_WORLD[best]
	return true


func disconnect_port(from_port: StringName) -> bool:
	if not OUT_PORTS.has(from_port) or not connections.has(from_port):
		return false
	connections.erase(from_port)
	port_cleared.emit(from_port)
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
