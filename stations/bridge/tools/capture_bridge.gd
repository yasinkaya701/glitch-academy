extends SceneTree

func _init() -> void:
	var root_node = root
	var scene_res = load("res://stations/bridge/mission.tscn")
	var scene = scene_res.instantiate()
	root_node.add_child(scene)
	
	create_timer(0.2).timeout.connect(func():
		var img = root_node.get_texture().get_image()
		img.save_png("res://test_bridge_render.png")
		print("BRIDGE_SCREENSHOT_SAVED")
		quit()
	)
