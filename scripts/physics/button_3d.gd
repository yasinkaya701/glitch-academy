extends Node3D
## Tezgâhta duran basma düğmesi. Normal: basınca tetiklenir. Geçişli: basılı kalır, üstündeki ışık yanar.

signal pressed
signal toggled(on: bool)

const FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")

var toggle_mode := false
var on := false

var _cap: MeshInstance3D
var _cap_material: StandardMaterial3D
var _light: MeshInstance3D
var _light_material: StandardMaterial3D
var _accent := Color("#f2a65a")
var _rest_y := 0.022


func setup(label: String, accent: Color, toggle: bool) -> void:
	toggle_mode = toggle
	_accent = accent
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#8d949c")
	metal.metallic = 0.9
	metal.roughness = 0.35
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.17, 0.02, 0.11)
	body.mesh = body_mesh
	body.material_override = metal
	body.position.y = 0.01
	add_child(body)
	_cap = MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(0.14, 0.026, 0.08)
	_cap.mesh = cap_mesh
	_cap_material = StandardMaterial3D.new()
	_cap_material.albedo_color = Color("#2c323a")
	_cap_material.metallic = 0.3
	_cap_material.roughness = 0.55
	_cap.material_override = _cap_material
	_cap.position.y = _rest_y + 0.013
	add_child(_cap)
	_light = MeshInstance3D.new()
	var light_mesh := BoxMesh.new()
	light_mesh.size = Vector3(0.1, 0.004, 0.008)
	_light.mesh = light_mesh
	_light_material = StandardMaterial3D.new()
	_light_material.albedo_color = Color("#3a3f46")
	_light_material.emission_enabled = true
	_light_material.emission = _accent
	_light_material.emission_energy_multiplier = 0.0
	_light.material_override = _light_material
	_light.position = Vector3(0, 0.028, -0.03)
	_cap.add_child(_light)
	var text := Label3D.new()
	text.text = label.to_upper()
	text.font = FONT
	text.font_size = 64
	text.pixel_size = 0.034 / 64.0
	text.modulate = Color("#e8eef2")
	text.rotation_degrees = Vector3(-90, 0, 0)
	text.position = Vector3(0, 0.029, 0.012)
	text.shaded = false
	_cap.add_child(text)
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.17, 0.06, 0.11)
	shape.shape = box
	shape.position.y = 0.03
	area.add_child(shape)
	area.set_meta("handler", self)
	add_child(area)
	_refresh()


func pick_hover(on: bool) -> void:
	_cap_material.albedo_color = Color("#3a414b") if on else Color("#2c323a")


func pick_press(event: InputEventMouseButton) -> void:
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activate()


func activate() -> void:
	var tween := create_tween()
	tween.tween_property(_cap, "position:y", _rest_y + 0.004, 0.05)
	tween.tween_property(_cap, "position:y", _rest_y + 0.013, 0.08)
	if toggle_mode:
		on = not on
		_refresh()
		toggled.emit(on)
	else:
		pressed.emit()


func set_on(value: bool) -> void:
	on = value
	_refresh()


func _refresh() -> void:
	_light_material.emission_energy_multiplier = 2.2 if on else 0.0
	_light_material.albedo_color = _accent if on else Color("#3a3f46")
