extends Node3D
## Optional look-dev viewer for the segmented teaching model; the mission keeps its legacy anchor map.

const CENTER := Vector3(0.0, 0.066, 0.0)
const HEART_MODELS: Array[PackedScene] = [
	preload("res://stations/heart/assets/segmented/heart_segmented.glb"),
	preload("res://stations/heart/assets/segmented/heart_segmented_tricuspid_leaky.glb"),
	preload("res://stations/heart/assets/segmented/heart_segmented_mitral_leaky.glb"),
	preload("res://stations/heart/assets/segmented/heart_segmented_aortic_leaky.glb"),
	preload("res://stations/heart/assets/segmented/heart_segmented_pulmonary_leaky.glb"),
]
const MODEL_NAMES := ["Healthy", "Tricuspid leak", "Mitral leak", "Aortic leak", "Pulmonary leak"]
const CLAMP_SCENE := preload("res://stations/heart/assets/tools/clamp_vessel.glb")

@onready var orbit: Node3D = $Orbit
@onready var camera: Camera3D = $Camera

var model_index := 0
var active_model: Node3D
var clamp_visible := false
var dragging := false
var _variant_label: Label
var _clamp_button: Button


func _ready() -> void:
	camera.look_at(CENTER, Vector3.UP)
	orbit.position = CENTER
	_install_variant()
	_build_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = maxf(0.18, camera.position.z - 0.025)
			camera.look_at(CENTER, Vector3.UP)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = minf(0.62, camera.position.z + 0.025)
			camera.look_at(CENTER, Vector3.UP)
	elif event is InputEventMouseMotion and dragging:
		orbit.rotate_y(-event.relative.x * 0.008)
		orbit.rotation.x = clampf(orbit.rotation.x - event.relative.y * 0.006, -0.85, 0.85)


func show_variant(index: int) -> void:
	model_index = posmod(index, HEART_MODELS.size())
	_install_variant()
	_refresh_hud()


func set_clamp_visible(value: bool) -> void:
	clamp_visible = value
	if active_model:
		var existing := active_model.find_child("InspectorClamp", true, false)
		if existing:
			existing.queue_free()
		if clamp_visible:
			_add_aortic_clamp()
	_refresh_hud()


func _install_variant() -> void:
	if active_model:
		active_model.queue_free()
	active_model = HEART_MODELS[model_index].instantiate() as Node3D
	active_model.position = -CENTER
	orbit.add_child(active_model)
	if clamp_visible:
		_add_aortic_clamp()


func _add_aortic_clamp() -> void:
	var aorta := active_model.find_child("Aorta", true, false) as Node3D
	if aorta == null:
		push_warning("Inspector model is missing its Aorta vessel node.")
		return
	var point := aorta.get_node_or_null("ClampPoint") as Node3D
	if point == null:
		push_warning("Inspector model is missing Aorta/ClampPoint.")
		return
	var clamp := CLAMP_SCENE.instantiate() as Node3D
	clamp.name = "InspectorClamp"
	clamp.position = point.position
	# Aorta's final segment runs approximately (+X, -Y); clamp local +Z follows that axis.
	var vessel_axis := Vector3(0.005, -0.002, 0.0).normalized()
	clamp.basis = Basis(Quaternion(Vector3.BACK, vessel_axis))
	aorta.add_child(clamp)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(28, 28)
	panel.custom_minimum_size = Vector2(350, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101d29")
	panel_style.border_color = Color("#3f5966")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "SEGMENTED HEART  /  LOOK-DEV"
	title.add_theme_color_override("font_color", Color("#91e4c4"))
	title.add_theme_font_size_override("font_size", 16)
	stack.add_child(title)
	_variant_label = Label.new()
	_variant_label.add_theme_font_size_override("font_size", 22)
	stack.add_child(_variant_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	stack.add_child(buttons)
	var previous := Button.new()
	previous.text = "‹"
	previous.custom_minimum_size = Vector2(42, 38)
	previous.pressed.connect(func() -> void: show_variant(model_index - 1))
	buttons.add_child(previous)
	var next := Button.new()
	next.text = "›"
	next.custom_minimum_size = Vector2(42, 38)
	next.pressed.connect(func() -> void: show_variant(model_index + 1))
	buttons.add_child(next)
	_clamp_button = Button.new()
	_clamp_button.custom_minimum_size = Vector2(204, 38)
	_clamp_button.pressed.connect(func() -> void: set_clamp_visible(not clamp_visible))
	buttons.add_child(_clamp_button)
	var help := Label.new()
	help.text = "Drag to orbit · wheel to zoom"
	help.add_theme_color_override("font_color", Color("#a5b6bc"))
	stack.add_child(help)
	_refresh_hud()


func _refresh_hud() -> void:
	if _variant_label:
		_variant_label.text = MODEL_NAMES[model_index]
	if _clamp_button:
		_clamp_button.text = "Hide aortic clamp" if clamp_visible else "Place clamp on aorta"
