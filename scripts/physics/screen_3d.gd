extends Node3D
## Sahnede duran cihaz ekranı: içinde 2B çizim yapılan bir SubViewport, 3B bir levhaya doku olarak kaplanır.
## `draw_callable(canvas: Control, size: Vector2)` her karede çağrılır.

var _viewport: SubViewport
var _canvas: Control
var _draw_callable: Callable
var _pixels := Vector2i(1280, 720)


func setup(pixels: Vector2i, world_size: Vector2, draw_callable: Callable) -> void:
	_pixels = pixels
	_draw_callable = draw_callable
	_viewport = SubViewport.new()
	_viewport.size = pixels
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.disable_3d = true
	add_child(_viewport)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0b1119")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(backdrop)
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(func() -> void: _draw_callable.call(_canvas, Vector2(_pixels)))
	_viewport.add_child(_canvas)
	# Çerçeve (bezel) ve ekran yüzeyi
	var bezel := MeshInstance3D.new()
	var bezel_mesh := BoxMesh.new()
	bezel_mesh.size = Vector3(world_size.x + 0.08, world_size.y + 0.08, 0.04)
	bezel.mesh = bezel_mesh
	var bezel_material := StandardMaterial3D.new()
	bezel_material.albedo_color = Color("#1b2027")
	bezel_material.metallic = 0.6
	bezel_material.roughness = 0.45
	bezel.material_override = bezel_material
	bezel.position.z = -0.025
	add_child(bezel)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = world_size
	face.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_texture = _viewport.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face.material_override = material
	add_child(face)


func refresh() -> void:
	if _canvas != null:
		_canvas.queue_redraw()
