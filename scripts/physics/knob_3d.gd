extends Node3D
## Tezgâhta duran döner düğme. Tıkla ve yatay sürükle ya da tekerlekle çevir. Değer en yakın adıma oturur.
## Üstte canlı değer, altta etiket (Label3D). Kapak üzerinde işaret çizgisi değerle döner.

signal changed(value: float)

const FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const FONT_REGULAR = preload("res://assets/fonts/IBMPlexSans-Regular.ttf")
const MAX_ANGLE := 135.0

var value := 0.0
var low := 0.0
var high := 1.0
var step := 1.0
var unit := ""
var title := ""
var stage: Node
var value_labels: Array = []  ## doluysa değer yerine bu metinler (indeks = değer)

var _cap: Node3D
var _readout: Label3D
var _cap_material: StandardMaterial3D
var _hover := false


func setup(host: Node, label: String, low_value: float, high_value: float, start: float, step_size: float, unit_text: String) -> void:
	stage = host
	title = label
	low = low_value
	high = high_value
	step = step_size
	unit = unit_text
	value = clampf(start, low, high)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#8d949c")
	metal.metallic = 0.9
	metal.roughness = 0.35
	_cap_material = StandardMaterial3D.new()
	_cap_material.albedo_color = Color("#272c33")
	_cap_material.metallic = 0.5
	_cap_material.roughness = 0.5
	# Taban halkası, kapak, işaret çizgisi
	_cylinder(0.075, 0.012, metal, Vector3(0, 0.006, 0), self)
	_cap = Node3D.new()
	_cap.position = Vector3(0, 0.012, 0)
	add_child(_cap)
	_cylinder(0.058, 0.05, _cap_material, Vector3(0, 0.025, 0), _cap)
	_cylinder(0.05, 0.006, metal, Vector3(0, 0.053, 0), _cap)
	var mark := MeshInstance3D.new()
	var mark_mesh := BoxMesh.new()
	mark_mesh.size = Vector3(0.008, 0.004, 0.034)
	mark.mesh = mark_mesh
	var mark_material := StandardMaterial3D.new()
	mark_material.albedo_color = Color("#f2f2f2")
	mark_material.emission_enabled = true
	mark_material.emission = Color("#f2f2f2")
	mark_material.emission_energy_multiplier = 0.6
	mark.material_override = mark_material
	mark.position = Vector3(0, 0.058, -0.026)
	_cap.add_child(mark)
	# Ölçek çentikleri
	var tick_count := int(round((high - low) / step)) + 1
	for i in tick_count:
		var u := float(i) / float(maxi(tick_count - 1, 1))
		var angle := deg_to_rad(lerpf(-MAX_ANGLE, MAX_ANGLE, u))
		var tick := MeshInstance3D.new()
		var tick_mesh := BoxMesh.new()
		tick_mesh.size = Vector3(0.004, 0.002, 0.012)
		tick.mesh = tick_mesh
		tick.material_override = metal
		tick.position = Vector3(sin(angle), 0.013, -cos(angle)) * 0.095
		tick.rotation.y = -angle
		add_child(tick)
	_readout = _label("", 0.07, Vector3(0, 0.002, 0.16), Color("#9ff3d8"), FONT)
	_label(title.to_upper(), 0.05, Vector3(0, 0.002, 0.235), Color("#d2dbe3"), FONT_REGULAR)
	# Tıklama alanı
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.radius = 0.08
	cylinder_shape.height = 0.12
	shape.shape = cylinder_shape
	shape.position.y = 0.04
	area.add_child(shape)
	area.set_meta("handler", self)
	add_child(area)
	_apply()


func _cylinder(radius: float, height: float, material: Material, at: Vector3, parent: Node3D) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 40
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)


func _label(text: String, size_m: float, at: Vector3, colour: Color, font: Font) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = font
	label.font_size = 64
	label.pixel_size = size_m / 64.0
	label.modulate = colour
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.position = at
	label.shaded = false
	add_child(label)
	return label


func _set_hover(on: bool) -> void:
	_hover = on
	_cap_material.albedo_color = Color("#343a43") if on else Color("#272c33")


func pick_hover(on: bool) -> void:
	_set_hover(on)


func pick_press(event: InputEventMouseButton) -> void:
	if event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			stage.set("active_drag", self)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			nudge(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			nudge(-1)


func drag(relative: Vector2) -> void:
	set_value(value + relative.x * (high - low) / 240.0)


func nudge(direction: int) -> void:
	set_value(value + direction * step)


func set_value(new_value: float) -> void:
	var snapped_value := clampf(snappedf(new_value, step), low, high)
	if is_equal_approx(snapped_value, value):
		return
	value = snapped_value
	_apply()
	changed.emit(value)


func refresh() -> void:
	_apply()


func _apply() -> void:
	var u := 0.0 if high == low else (value - low) / (high - low)
	_cap.rotation.y = -deg_to_rad(lerpf(-MAX_ANGLE, MAX_ANGLE, u))
	var text := str(int(value)) if step >= 1.0 else str(snappedf(value, step)).replace(".", ",")
	if not value_labels.is_empty():
		text = String(value_labels[clampi(int(value), 0, value_labels.size() - 1)])
	_readout.text = ("%s %s" % [text, unit]).strip_edges()
