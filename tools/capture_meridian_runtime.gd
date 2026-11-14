extends SceneTree

const SCENE := "res://scenes/control_center.tscn"
const OUTPUTS := [
	"res://docs/review/meridian_control_center.png",
	"res://docs/review/meridian_control_center_selected.png",
	"res://docs/review/meridian_intro_title.png",
]


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var control: Node = load(SCENE).instantiate()
	root.add_child(control)
	await process_frame
	await process_frame
	var intro: Node = control.get_node_or_null("Intro")
	if intro:
		intro.set("elapsed", 11.0)
		intro.call("_update_frame")
		await process_frame
		var intro_error: int = root.get_texture().get_image().save_png(OUTPUTS[2])
		print("Saved Meridian intro-title capture; error=", intro_error)
		intro.call("_finish")
	await process_frame
	await process_frame
	var error: int = root.get_texture().get_image().save_png(OUTPUTS[0])
	print("Saved Meridian control-center capture; error=", error)
	control.call("_select_mission", 0)
	await process_frame
	var selected_error: int = root.get_texture().get_image().save_png(OUTPUTS[1])
	print("Saved selected-mission capture; error=", selected_error)
	quit()
