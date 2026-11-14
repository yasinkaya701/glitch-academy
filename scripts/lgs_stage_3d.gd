extends Control
## Isolated 3D experiment with an orbit camera and screen-space measurements.

const EXPERIMENT = preload("res://scenes/experiment_3d.tscn")
var viewport: SubViewport
var world: Node3D
var model: Node3D
var camera: Camera3D
var camera_target := Vector3(0, 1.6, 0)
var view_size := 7.0
var yaw := 0.35
var pitch := 0.22
var _dragging := false
var _annotations: Array[Dictionary] = []
var _readout: Label


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var experiment := EXPERIMENT.instantiate()
	experiment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	experiment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(experiment)
	viewport = experiment.get_node("Viewport")
	viewport.msaa_3d = Viewport.MSAA_4X
	world = experiment.get_node("Viewport/World")
	model = world.get_node("Model")
	camera = world.get_node("Camera3D")
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	var light := OmniLight3D.new()
	light.position = Vector3(-3, 5, 5)
	light.light_energy = 1.4
	light.omni_range = 18.0
	world.add_child(light)
	box("Bench", Vector3(0, -0.18, 0), Vector3(10, 0.25, 6), UITheme.PANEL_RAISED)
	_readout = Label.new()
	_readout.position = Vector2(210, 24)
	_readout.add_theme_font_size_override("font_size", 18)
	_readout.add_theme_color_override("font_color", UITheme.INK)
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_readout)
	var toolbar := HBoxContainer.new()
	toolbar.name = "CameraControls"
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	toolbar.position = Vector2(24, -54)
	toolbar.add_theme_constant_override("separation", 8)
	add_child(toolbar)
	for item in [["Sola çevir", -0.2], ["Sağa çevir", 0.2], ["Görünümü sıfırla", 0.0]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_turn.bind(float(item[1])))
		toolbar.add_child(button)
	_build_model()
	_update_camera()
	_sync_model(0.0)


func _build_model() -> void:
	pass


func _sync_model(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	_sync_model(delta)
	for annotation in _annotations:
		var point: Vector3 = annotation.node.to_global(annotation.offset)
		var label: Label = annotation.label
		label.visible = not camera.is_position_behind(point) and annotation.node.is_visible_in_tree()
		label.position = camera.unproject_position(point) * size / Vector2(viewport.size) - label.size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			camera.size = clampf(camera.size + (-0.4 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.4), view_size * 0.7, view_size * 1.5)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch + event.relative.y * 0.004, 0.08, 0.7)
		_update_camera(false)
		accept_event()
	elif event is InputEventScreenDrag:
		yaw -= event.relative.x * 0.006
		_update_camera(false)
		accept_event()


func _turn(amount: float) -> void:
	if is_zero_approx(amount):
		yaw = 0.35
		pitch = 0.22
	else:
		yaw += amount
	_update_camera()


func _update_camera(reset_zoom := true) -> void:
	camera.position = camera_target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 13.0
	camera.look_at(camera_target)
	if reset_zoom:
		camera.size = view_size


func material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.4
	result.metallic = metallic
	if color.a < 1.0:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result


func shape(node_name: String, mesh: Mesh, at: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material(color)
	node.position = at
	(parent if parent != null else model).add_child(node)
	return node


func box(node_name: String, at: Vector3, dimensions: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return shape(node_name, mesh, at, color, parent)


func cylinder(node_name: String, at: Vector3, radius: float, height: float, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	return shape(node_name, mesh, at, color, parent)


func beam(node_name: String, start: Vector3, end: Vector3, radius: float, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var node := cylinder(node_name, (start + end) * 0.5, radius, start.distance_to(end), color, parent)
	node.quaternion = Quaternion(Vector3.UP, start.direction_to(end))
	return node


func annotate(node: Node3D, text: String, offset := Vector3.ZERO) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", UITheme.INK)
	label.add_theme_color_override("font_shadow_color", UITheme.BG)
	label.add_theme_constant_override("shadow_outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	_annotations.append({"node": node, "label": label, "offset": offset})
	return label
