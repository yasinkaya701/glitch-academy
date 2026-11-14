extends Control
## Anatomi motoru: 3B deney sahnesi tabanı. SubViewport, yörünge kamerası, aydınlatma, zemin, model yerleştirme,
## seçilebilir noktalar (tıklama, sürükle-bırak), 3B etiketler ve vurgu işareti.
## Her deney (kalp, kas...) bu sınıfı genişletir, kendi nesnelerini ve etkileşimini ekler.

const Rig = preload("res://stations/heart/orbit_rig.gd")
const Util = preload("res://scripts/anatomy/anatomy_util.gd")

signal picked(id: Variant)
signal dropped(id: Variant, data: Variant)

const INK := Color("#e9f1ee")
const JADE := Color("#8ff0d4")
const GOLD := Color("#ffc082")
const RED := Color("#ff6b5e")
const BACK := Color("#05080e")

var viewport: SubViewport
var rig: Rig
var world: Node3D
var default_target := Vector3.ZERO
var default_distance := 3.3
var default_pitch := 0.08

## id -> {position: Callable, radius: float}
var pickables: Dictionary = {}
var active_pickables: Dictionary = {}
var labels: Dictionary = {}
var highlight_id: Variant = null

var _time := 0.0
var _label_nodes: Dictionary = {}
var _highlight_marker: MeshInstance3D
var _orbiting := false
var _press_position := Vector2.ZERO
var _press_moved := false
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
	world = Node3D.new()
	viewport.add_child(world)
	_build_base()
	_build()


func _floor_height() -> float:
	return -0.8


## Alt sınıflar nesnelerini burada kurar.
func _build() -> void:
	pass


func _build_base() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#060a11")
	sky_material.sky_horizon_color = Color("#1a2431")
	sky_material.ground_horizon_color = Color("#10161e")
	sky_material.ground_bottom_color = Color("#06090e")
	sky_material.sky_energy_multiplier = 0.7
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#04070c")
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.9
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 6.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.32
	environment.glow_strength = 0.9
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 1.6
	environment.ssao_enabled = true
	environment.ssao_radius = 0.6
	environment.ssao_intensity = 2.2
	environment.ssil_enabled = true
	environment.ssr_enabled = false
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.003
	environment.volumetric_fog_albedo = Color("#4a5d78")
	environment.volumetric_fog_emission = Color("#070d16")
	environment.volumetric_fog_anisotropy = 0.55
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.08
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	world.add_child(env_node)

	rig = Rig.new()
	rig.target = default_target
	rig.distance = default_distance
	rig.pitch = default_pitch
	rig.min_distance = 0.05
	world.add_child(rig)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 28, 0)
	key.light_color = Color(1.0, 0.92, 0.82)
	key.light_energy = 2.2
	key.shadow_enabled = true
	key.light_volumetric_fog_energy = 1.4
	world.add_child(key)
	_add_softbox(Vector3(-2.2, 2.6, 2.4), Vector3(-0.25, 0.6, 0.0), Color(1.0, 0.9, 0.78), 2.2, Vector2(2.2, 1.4))
	_add_softbox(Vector3(2.6, 1.4, -1.6), Vector3(0.0, 0.2, 0.0), Color(0.55, 0.78, 1.0), 1.6, Vector2(1.8, 1.0))
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, 205, 0)
	rim.light_color = Color(0.55, 0.78, 1.0)
	rim.light_energy = 1.2
	world.add_child(rim)

	_floor_material = StandardMaterial3D.new()
	_floor_material.albedo_color = Color("#060a10")
	_floor_material.metallic = 0.0
	_floor_material.roughness = 0.9
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	floor_mesh.mesh = plane
	floor_mesh.material_override = _floor_material
	floor_mesh.position = Vector3(0, _floor_height(), 0)
	world.add_child(floor_mesh)

	_highlight_marker = MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.05
	marker_mesh.height = 0.1
	_highlight_marker.mesh = marker_mesh
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(JADE.r, JADE.g, JADE.b, 0.5)
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.no_depth_test = true
	_highlight_marker.material_override = marker_material
	_highlight_marker.hide()
	world.add_child(_highlight_marker)


func _add_softbox(position: Vector3, look_at_point: Vector3, color: Color, energy: float, panel_size: Vector2) -> void:
	var panel := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	panel.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	panel.material_override = material
	panel.position = position
	world.add_child(panel)
	panel.look_at(look_at_point, Vector3.UP)


func place_model(scene: PackedScene, position: Vector3, scale_factor: float, rotation_degrees: Vector3 = Vector3.ZERO) -> Node3D:
	var holder := Node3D.new()
	var model: Node3D = scene.instantiate()
	var box := Util.bounds(model)
	model.scale = Vector3.ONE * scale_factor
	model.rotation_degrees = rotation_degrees
	model.position = -box.get_center() * scale_factor
	holder.position = position
	holder.add_child(model)
	world.add_child(holder)
	return holder


func make_label(text: String, color: Color = JADE, font_size: int = 14) -> Label3D:
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


# --- Seçilebilir noktalar ----------------------------------------------

func add_pickable(id: Variant, position: Callable, radius: float) -> void:
	pickables[id] = {"position": position, "radius": radius}


func set_active(id: Variant, active: bool) -> void:
	active_pickables[id] = active


func is_active(id: Variant) -> bool:
	return active_pickables.get(id, false)


func ray(position: Vector2) -> Array:
	var viewport_position := position * Vector2(viewport.size) / size if size.x > 0.0 else position
	return rig.ray(viewport_position)


func world_on_ray(position: Vector2, reference: Vector3) -> Vector3:
	var r: Array = ray(position)
	var plane := Plane(rig.camera.global_transform.basis.z, reference)
	var hit: Variant = plane.intersects_ray(r[0], r[1])
	return hit if hit != null else reference


## Işına en yakın küre. `only_active` verilirse yalnızca etkin noktalar sayılır.
func pick(position: Vector2, only_active: bool = true, radius_scale: float = 1.0, filter: Callable = Callable()) -> Variant:
	var r: Array = ray(position)
	var origin: Vector3 = r[0]
	var direction: Vector3 = r[1]
	var best: Variant = null
	var best_distance := INF
	for id in pickables:
		if only_active and not active_pickables.get(id, false):
			continue
		if filter.is_valid() and not filter.call(id):
			continue
		var data: Dictionary = pickables[id]
		var center: Vector3 = (data["position"] as Callable).call()
		var to_center := center - origin
		var along := to_center.dot(direction)
		if along <= 0.0:
			continue
		var miss := (to_center - direction * along).length()
		if miss <= float(data["radius"]) * radius_scale and along < best_distance:
			best_distance = along
			best = id
	return best


func pickable_position(id: Variant) -> Vector3:
	return (pickables[id]["position"] as Callable).call()


# --- Girdi ----------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		rig.zoom(1.0 / maxf((event as InputEventMagnifyGesture).factor, 0.2))
		return
	if event is InputEventPanGesture:
		rig.orbit((event as InputEventPanGesture).delta * 6.0)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_HOME:
				wide_view()
			KEY_EQUAL, KEY_KP_ADD:
				rig.zoom(0.8)
			KEY_MINUS, KEY_KP_SUBTRACT:
				rig.zoom(1.25)
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			rig.zoom(0.9)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			rig.zoom(1.1)
		elif button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_press_position = button.position
				_press_moved = false
				if on_press(button.position, button.double_click):
					return
				if button.double_click:
					on_double_click(button.position)
					return
				_orbiting = true
			else:
				if on_release(button.position):
					return
				var was_orbit := _orbiting
				_orbiting = false
				if was_orbit and not _press_moved:
					on_click(button.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if on_motion(motion.position):
			return
		if _orbiting:
			if motion.position.distance_to(_press_position) > 4.0:
				_press_moved = true
			rig.orbit(motion.relative)


## Alt sınıflar geçersiz kılar. true dönerse temel sınıf olayı işlenmiş sayar.
func on_press(_position: Vector2, _double: bool) -> bool:
	return false


func on_release(_position: Vector2) -> bool:
	return false


func on_motion(_position: Vector2) -> bool:
	return false


func on_click(position: Vector2) -> void:
	var hit: Variant = pick(position)
	if hit != null:
		picked.emit(hit)


func on_double_click(position: Vector2) -> void:
	var hit: Variant = pick(position, false, 1.4)
	if hit != null:
		focus_on(hit)
	else:
		reset_view()


func focus_on(id: Variant, distance: float = 0.3) -> void:
	rig.focus(pickable_position(id), distance)


## Tüm organların ve sahnenin göründüğü geniş kadraj.
func wide_view() -> void:
	rig.focus(default_target, default_distance * 1.45, 0.0, default_pitch)


func reset_view() -> void:
	rig.focus(default_target, default_distance, 0.0, default_pitch)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return can_drop(at_position, data)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop(at_position, data)


func can_drop(_position: Vector2, _data: Variant) -> bool:
	return false


func drop(_position: Vector2, _data: Variant) -> void:
	pass


# --- Her kare ---------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	_update(delta)
	_update_labels()
	_update_highlight()


## Alt sınıflar her kare çağrılır.
func _update(_delta: float) -> void:
	pass


## Etiket dünyadaki yeri. Alt sınıf geçersiz kılar.
func label_world(id: Variant) -> Vector3:
	if pickables.has(id):
		return pickable_position(id) + Vector3(0, 0.12, 0.18)
	return Vector3.ZERO


func _update_labels() -> void:
	for id in labels:
		if not _label_nodes.has(id):
			var label := make_label(String(labels[id]))
			world.add_child(label)
			_label_nodes[id] = label
		var node: Label3D = _label_nodes[id]
		node.text = String(labels[id])
		node.global_position = label_world(id)
	for id in _label_nodes.keys():
		if not labels.has(id):
			(_label_nodes[id] as Node).queue_free()
			_label_nodes.erase(id)


func _update_highlight() -> void:
	if highlight_id != null and pickables.has(highlight_id):
		_highlight_marker.show()
		_highlight_marker.global_position = pickable_position(highlight_id)
		_highlight_marker.scale = Vector3.ONE * (0.8 + 0.3 * sin(_time * 4.0))
	else:
		_highlight_marker.hide()
