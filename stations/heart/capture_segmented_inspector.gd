extends SceneTree

const SCENE := "res://stations/heart/heart_segmented_inspector.tscn"
const OUT := "res://docs/review/"


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var inspector: Node = load(SCENE).instantiate()
	viewport.add_child(inspector)
	await process_frame
	await process_frame
	inspector.call("set_clamp_visible", true)
	await process_frame
	await process_frame
	_save(viewport, "heart008_inspector_healthy_clamp.png")
	inspector.call("show_variant", 3)
	(inspector.get_node("Orbit") as Node3D).rotation_degrees.y = 18.0
	await process_frame
	await process_frame
	_save(viewport, "heart008_inspector_aortic_leak.png")
	quit()


func _save(viewport: SubViewport, filename: String) -> void:
	var error := viewport.get_texture().get_image().save_png(OUT + filename)
	print("Saved ", filename, "; error=", error)
