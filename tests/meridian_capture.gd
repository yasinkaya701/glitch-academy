extends SceneTree
var output := "/tmp/meridian-review"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	for kind in ["newton", "projectile", "collision", "free_fall", "waves", "photoelectric", "turkish", "bridge"]:
		var mission = load("res://stations/%s/mission.tscn" % kind).instantiate()
		mission.theme = root.theme
		root.add_child(mission)
		await process_frame
		await process_frame
		if kind in ["newton", "projectile", "collision"]:
			mission._on_skip()
			mission._on_action()
			mission._elapsed = 2.8
			mission._process(0.0)
		elif kind == "turkish":
			mission._begin_test()
			mission._advance_phase()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/" + kind + ".png")
		mission.queue_free()
		await process_frame
	quit()
