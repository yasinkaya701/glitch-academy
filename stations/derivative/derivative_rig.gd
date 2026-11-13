extends SubViewportContainer
## 3D volume curve inset. Geometry is sampled from the same volume/slope functions as the lesson.

const BoxPlot = preload("res://stations/derivative/box_plot.gd")
const X_SPAN := 5.0
const Y_SPAN := 3.05
const X_MIN := -X_SPAN * 0.5
const Z_FRONT := 0.09
const CURVE_SAMPLES := 96

var _model: Node3D
var _camera: Camera3D
var _curve_mesh: ImmediateMesh
var _tangent_mesh: ImmediateMesh
var _run_mesh: ImmediateMesh
var _rise_mesh: ImmediateMesh
var _point: MeshInstance3D
var _optimum: MeshInstance3D
var _sample_root: Node3D
var _curve_material: StandardMaterial3D
var _tangent_material: StandardMaterial3D
var _run_material: StandardMaterial3D
var _rise_material: StandardMaterial3D
var _side := 12.0
var _x := 1.0
var _show_curve := false
var _show_tangent := false
var _show_optimum := false


func _ready() -> void:
	_model = get_node("Viewport/World/Model")
	_camera = get_node("Viewport/World/Camera3D")
	_camera.look_at(Vector3(0.0, 1.15, 0.0), Vector3.UP)
	_build_rig()
	_update_geometry()


func set_experiment_state(side: float, x: float, show_curve: bool, show_tangent: bool, show_optimum: bool, samples: Array) -> void:
	_side = side
	_x = clampf(x, 0.0, side * 0.5)
	_show_curve = show_curve
	_show_tangent = show_tangent
	_show_optimum = show_optimum
	if is_node_ready():
		_update_geometry(samples)


func _build_rig() -> void:
	_curve_material = _line_material(Color("#86c6f3"), 0.12)
	_tangent_material = _line_material(Color("#ffc082"), 0.18)
	_run_material = _line_material(Color("#8de0c4"), 0.1)
	_rise_material = _line_material(Color("#efad79"), 0.1)
	_add_box("ChartDeck", Vector3(5.55, 0.1, 2.2), Vector3(0, -0.13, -0.05), Color("#102739"))
	_add_line_node("Curve", _curve_material, _curve_mesh)
	_add_line_node("Tangent", _tangent_material, _tangent_mesh)
	_add_line_node("Run", _run_material, _run_mesh)
	_add_line_node("Rise", _rise_material, _rise_mesh)
	_point = _sphere("SamplePoint", Vector3(0, 0, Z_FRONT), 0.105, Color("#ff8c76"), true)
	_optimum = _sphere("OptimumPoint", Vector3.ZERO, 0.092, Color("#8de0c4"), true)
	_sample_root = Node3D.new()
	_sample_root.name = "MeasuredSamples"
	_model.add_child(_sample_root)
	_draw_grid()


func _draw_grid() -> void:
	var grid_material := _line_material(Color("#345267"), 0.025)
	var axis_material := _line_material(Color("#a8c0ce"), 0.045)
	var grid := ImmediateMesh.new()
	grid.surface_begin(Mesh.PRIMITIVE_LINES, grid_material)
	for i in range(1, 8):
		var x := X_MIN + X_SPAN * float(i) / 8.0
		grid.surface_add_vertex(Vector3(x, 0.01, Z_FRONT - 0.01))
		grid.surface_add_vertex(Vector3(x, Y_SPAN, Z_FRONT - 0.01))
	for i in range(1, 5):
		var y := Y_SPAN * float(i) / 5.0
		grid.surface_add_vertex(Vector3(X_MIN, y, Z_FRONT - 0.01))
		grid.surface_add_vertex(Vector3(X_MIN + X_SPAN, y, Z_FRONT - 0.01))
	grid.surface_end()
	var grid_instance := MeshInstance3D.new()
	grid_instance.name = "Grid"
	grid_instance.mesh = grid
	_model.add_child(grid_instance)
	var axes := ImmediateMesh.new()
	axes.surface_begin(Mesh.PRIMITIVE_LINES, axis_material)
	axes.surface_add_vertex(Vector3(X_MIN, 0.015, Z_FRONT))
	axes.surface_add_vertex(Vector3(X_MIN + X_SPAN, 0.015, Z_FRONT))
	axes.surface_add_vertex(Vector3(X_MIN, 0.015, Z_FRONT))
	axes.surface_add_vertex(Vector3(X_MIN, Y_SPAN, Z_FRONT))
	axes.surface_end()
	var axis_instance := MeshInstance3D.new()
	axis_instance.name = "Axes"
	axis_instance.mesh = axes
	_model.add_child(axis_instance)
	for i in 6:
		var x := X_MIN + X_SPAN * float(i) / 5.0
		_add_box("XTick%d" % i, Vector3(0.028, 0.045, 0.035), Vector3(x, 0.035, Z_FRONT), Color("#9fb4c1"))
	for i in 4:
		var y := Y_SPAN * float(i + 1) / 5.0
		_add_box("YTick%d" % i, Vector3(0.05, 0.028, 0.035), Vector3(X_MIN + 0.025, y, Z_FRONT), Color("#9fb4c1"))
	_add_axis_label("VolumeAxisLabel", "V (L)", Vector3(X_MIN + 0.1, Y_SPAN - 0.08, Z_FRONT + 0.02))
	_add_axis_label("CutAxisLabel", "x (dm)", Vector3(X_MIN + X_SPAN - 0.68, 0.17, Z_FRONT + 0.02))


func _update_geometry(samples: Array = []) -> void:
	var xmax := maxf(_side * 0.5, 0.001)
	var vmax := BoxPlot.volume(_side, _side / 6.0) * 1.16
	var curve := ImmediateMesh.new()
	if _show_curve:
		curve.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _curve_material)
		for i in CURVE_SAMPLES + 1:
			var x := xmax * float(i) / float(CURVE_SAMPLES)
			curve.surface_add_vertex(_point_for(x, BoxPlot.volume(_side, x), xmax, vmax))
		curve.surface_end()
	_curve_mesh = curve
	get_node("Viewport/World/Model/Curve").mesh = _curve_mesh
	var px := _point_for(_x, BoxPlot.volume(_side, _x), xmax, vmax)
	_point.position = px
	_point.visible = _show_curve
	_tangent_mesh = _line_mesh()
	_run_mesh = _line_mesh()
	_rise_mesh = _line_mesh()
	var tangent_node := get_node("Viewport/World/Model/Tangent") as MeshInstance3D
	var run_node := get_node("Viewport/World/Model/Run") as MeshInstance3D
	var rise_node := get_node("Viewport/World/Model/Rise") as MeshInstance3D
	tangent_node.mesh = _tangent_mesh
	run_node.mesh = _run_mesh
	rise_node.mesh = _rise_mesh
	tangent_node.visible = _show_curve and _show_tangent
	run_node.visible = tangent_node.visible
	rise_node.visible = tangent_node.visible
	if tangent_node.visible:
		var run_dx := minf(0.8, xmax * 0.14)
		var x0 := maxf(0.0, _x - run_dx)
		var x1 := minf(xmax, _x + run_dx)
		if is_equal_approx(x0, x1):
			x0 = maxf(0.0, _x - run_dx * 2.0)
			x1 = minf(xmax, _x + run_dx * 2.0)
		var slope := BoxPlot.slope(_side, _x)
		var y0 := BoxPlot.volume(_side, _x) + slope * (x0 - _x)
		var y1 := BoxPlot.volume(_side, _x) + slope * (x1 - _x)
		var p0 := _point_for(x0, y0, xmax, vmax)
		var p1 := _point_for(x1, y1, xmax, vmax)
		_add_segment(_tangent_mesh, p0, p1)
		var rise_edge := _point_for(x1, BoxPlot.volume(_side, _x), xmax, vmax)
		_add_segment(_run_mesh, _point_for(x0, BoxPlot.volume(_side, _x), xmax, vmax), rise_edge)
		_add_segment(_rise_mesh, rise_edge, _point_for(x1, y1, xmax, vmax))
	var optimum_x := _side / 6.0
	_optimum.position = _point_for(optimum_x, BoxPlot.volume(_side, optimum_x), xmax, vmax)
	_optimum.visible = _show_curve and _show_optimum
	for child in _sample_root.get_children():
		child.queue_free()
	for item in samples:
		if item is Vector2:
			var sample_x := _sphere("MeasuredPoint", _point_for(item.x, item.y, xmax, vmax), 0.065, Color("#8de0c4"), false)
			sample_x.get_parent().remove_child(sample_x)
			_sample_root.add_child(sample_x)
	_sample_root.visible = _show_curve


func _point_for(x: float, volume: float, xmax: float, vmax: float) -> Vector3:
	var clamped_volume := clampf(volume, 0.0, vmax)
	return Vector3(X_MIN + clampf(x / xmax, 0.0, 1.0) * X_SPAN, clamped_volume / vmax * Y_SPAN, Z_FRONT)


func _line_mesh() -> ImmediateMesh:
	return ImmediateMesh.new()


func _add_segment(mesh: ImmediateMesh, a: Vector3, b: Vector3) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_end()


func _add_line_node(id: String, material: Material, mesh: ImmediateMesh) -> void:
	var node := MeshInstance3D.new()
	node.name = id
	node.material_override = material
	node.mesh = mesh
	_model.add_child(node)


func _line_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material


func _add_box(id: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = id
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.5
	node.material_override = material
	_model.add_child(node)
	return node


func _sphere(id: String, position: Vector3, radius: float, color: Color, glow: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = id
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	node.mesh = mesh
	node.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.38
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	node.material_override = material
	_model.add_child(node)
	return node


func _add_axis_label(id: String, value: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.name = id
	label.text = value
	label.position = position
	label.font_size = 22
	label.pixel_size = 0.01
	label.modulate = Color("#d8e5ec")
	label.outline_size = 5
	label.outline_modulate = Color("#081620")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_model.add_child(label)
